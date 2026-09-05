package main

import (
	"encoding/binary"
	"fmt"
)

// module is the part of a wasm binary these checks read: which function
// index each export names, which function indices the element segments
// (the funcref tables) hold, and which function indices each defined
// function calls directly. Together they answer the question hasExports
// exists for — not "is this name in the export section" but "does the
// module actually run the exported body": a kernel export that no function
// calls and no dispatch table holds is dead, and a native body substituted
// for it never executes. That is how the q2_K / q3_K / q5_K dot exports
// first shipped: on the generic bodies, while type_traits dispatched to the
// wasm SIMD ones.
type module struct {
	exports    map[string]uint32          // export name -> function index
	numImports uint32                     // imported functions precede the defined ones
	elemFuncs  map[uint32]bool            // function indices held by element segments
	calls      map[uint32]map[uint32]bool // callee -> callers (defined function indices)
}

// parseModule decodes the sections the checks need and walks every
// function body. It fails loudly on anything it cannot decode rather than
// guessing: a check that silently skipped part of the code section could
// report a live export as dead or a dead one as live.
func parseModule(b []byte) (*module, error) {
	r := &reader{b: b}
	if len(b) < 8 || string(b[:4]) != "\x00asm" || binary.LittleEndian.Uint32(b[4:8]) != 1 {
		return nil, fmt.Errorf("not a wasm binary")
	}
	r.pos = 8
	m := &module{exports: map[string]uint32{}, elemFuncs: map[uint32]bool{}, calls: map[uint32]map[uint32]bool{}}
	for r.pos < len(b) {
		id := r.byte()
		size := r.u32()
		end := r.pos + int(size)
		if end > len(b) {
			return nil, fmt.Errorf("section %d overruns the module", id)
		}
		sec := &reader{b: b[r.pos:end]}
		var err error
		switch id {
		case 2:
			err = m.parseImports(sec)
		case 7:
			err = m.parseExports(sec)
		case 9:
			err = m.parseElements(sec)
		case 10:
			err = m.parseCode(sec)
		}
		if err != nil {
			return nil, fmt.Errorf("section %d: %w", id, err)
		}
		if r.err != nil {
			return nil, r.err
		}
		r.pos = end
	}
	return m, nil
}

func (m *module) parseImports(r *reader) error {
	n := r.u32()
	for i := uint32(0); i < n && r.err == nil; i++ {
		r.name() // module
		r.name() // field
		switch kind := r.byte(); kind {
		case 0: // func
			r.u32()
			m.numImports++
		case 1: // table
			r.byte()
			r.limits()
		case 2: // memory
			r.limits()
		case 3: // global
			r.byte()
			r.byte()
		case 4: // tag
			r.byte()
			r.u32()
		default:
			return fmt.Errorf("import kind %d", kind)
		}
	}
	return r.err
}

func (m *module) parseExports(r *reader) error {
	n := r.u32()
	for i := uint32(0); i < n && r.err == nil; i++ {
		name := r.name()
		kind := r.byte()
		idx := r.u32()
		if kind == 0 {
			m.exports[name] = idx
		}
	}
	return r.err
}

// parseElements reads the funcref element segments (the forms LLVM emits:
// flags 0 and 2 with function indices, flags 1/3 with an elemkind, and the
// expression forms 4..7 whose items are ref.func constants).
func (m *module) parseElements(r *reader) error {
	n := r.u32()
	for i := uint32(0); i < n && r.err == nil; i++ {
		flags := r.u32()
		if flags&1 == 0 { // active
			if flags&2 != 0 {
				r.u32() // table index
			}
			r.constExpr() // offset
		}
		exprs := flags&4 != 0
		if flags&3 != 0 {
			if exprs {
				r.byte() // reftype
			} else {
				r.byte() // elemkind
			}
		}
		cnt := r.u32()
		for j := uint32(0); j < cnt && r.err == nil; j++ {
			if exprs {
				// ref.func idx end | ref.null t end
				switch op := r.byte(); op {
				case 0xD2:
					m.elemFuncs[r.u32()] = true
				case 0xD0:
					r.byte()
				default:
					return fmt.Errorf("element expression opcode %#x", op)
				}
				if e := r.byte(); e != 0x0B {
					return fmt.Errorf("element expression not terminated")
				}
			} else {
				m.elemFuncs[r.u32()] = true
			}
		}
	}
	return r.err
}

func (m *module) parseCode(r *reader) error {
	n := r.u32()
	for i := uint32(0); i < n && r.err == nil; i++ {
		size := r.u32()
		end := r.pos + int(size)
		if end > len(r.b) {
			return fmt.Errorf("function body %d overruns the section", i)
		}
		body := &reader{b: r.b[r.pos:end]}
		caller := m.numImports + i
		if err := m.walkBody(body, caller); err != nil {
			return fmt.Errorf("function %d: %w", caller, err)
		}
		r.pos = end
	}
	return r.err
}

// walkBody decodes one function body instruction by instruction, recording
// the targets of direct calls. Every opcode the toolchain can emit for this
// module (core, EH, bulk memory, SIMD, atomics, reference types) is
// decoded; an unknown opcode is an error.
func (m *module) walkBody(r *reader, caller uint32) error {
	locals := r.u32()
	for i := uint32(0); i < locals && r.err == nil; i++ {
		r.u32()
		r.byte()
	}
	depth := 1
	for depth > 0 && r.err == nil {
		op := r.byte()
		switch op {
		case 0x00, 0x01, 0x0F, 0x1A, 0x1B: // unreachable nop return drop select
		case 0x02, 0x03, 0x04, 0x06: // block loop if try
			r.blockType()
			depth++
		case 0x05, 0x19: // else catch_all
		case 0x07: // catch tag
			r.u32()
		case 0x08, 0x09, 0x18: // throw rethrow delegate
			r.u32()
			if op == 0x18 {
				depth-- // delegate ends its try block
			}
		case 0x0A: // throw_ref
		case 0x0B: // end
			depth--
		case 0x0C, 0x0D: // br br_if
			r.u32()
		case 0x0E: // br_table
			cnt := r.u32()
			for j := uint32(0); j <= cnt && r.err == nil; j++ {
				r.u32()
			}
		case 0x10: // call
			callee := r.u32()
			if m.calls[callee] == nil {
				m.calls[callee] = map[uint32]bool{}
			}
			m.calls[callee][caller] = true
		case 0x11: // call_indirect type table
			r.u32()
			r.u32()
		case 0x12, 0x13: // return_call return_call_indirect
			r.u32()
			if op == 0x13 {
				r.u32()
			}
		case 0x1C: // select t*
			cnt := r.u32()
			for j := uint32(0); j < cnt; j++ {
				r.byte()
			}
		case 0x1F: // try_table
			r.blockType()
			cnt := r.u32()
			for j := uint32(0); j < cnt && r.err == nil; j++ {
				switch k := r.byte(); k {
				case 0, 1:
					r.u32()
					r.u32()
				case 2, 3:
					r.u32()
				default:
					return fmt.Errorf("try_table catch kind %d", k)
				}
			}
			depth++
		case 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26: // local/global/table get/set
			r.u32()
		case 0x3F, 0x40: // memory.size memory.grow
			r.u32()
		case 0x41, 0x42: // i32.const i64.const
			r.s64()
		case 0x43:
			r.skip(4)
		case 0x44:
			r.skip(8)
		case 0xD0: // ref.null
			r.byte()
		case 0xD1: // ref.is_null
		case 0xD2: // ref.func
			r.u32()
		case 0xFC:
			if err := r.miscOp(); err != nil {
				return err
			}
		case 0xFD:
			if err := r.simdOp(); err != nil {
				return err
			}
		case 0xFE:
			if err := r.atomicOp(); err != nil {
				return err
			}
		default:
			switch {
			case op >= 0x28 && op <= 0x3E: // loads and stores
				r.memarg()
			case op >= 0x45 && op <= 0xC4: // numeric
			default:
				return fmt.Errorf("opcode %#x at %d", op, r.pos-1)
			}
		}
	}
	if r.err != nil {
		return r.err
	}
	if r.pos != len(r.b) {
		return fmt.Errorf("body has %d trailing bytes", len(r.b)-r.pos)
	}
	return nil
}

// reader is a cursor over a byte slice; the first decode error sticks and
// every later read returns zero, so callers check err once.
type reader struct {
	b   []byte
	pos int
	err error
}

func (r *reader) fail(format string, args ...any) {
	if r.err == nil {
		r.err = fmt.Errorf(format, args...)
	}
}

func (r *reader) byte() byte {
	if r.err != nil || r.pos >= len(r.b) {
		r.fail("unexpected end of data at %d", r.pos)
		return 0
	}
	v := r.b[r.pos]
	r.pos++
	return v
}

func (r *reader) skip(n int) {
	if r.pos+n > len(r.b) {
		r.fail("unexpected end of data at %d", r.pos)
		return
	}
	r.pos += n
}

func (r *reader) u32() uint32 { return uint32(r.u64()) }

func (r *reader) u64() uint64 {
	var v uint64
	for shift := 0; shift < 70; shift += 7 {
		c := r.byte()
		v |= uint64(c&0x7F) << shift
		if c&0x80 == 0 {
			return v
		}
	}
	r.fail("LEB128 too long at %d", r.pos)
	return 0
}

func (r *reader) s64() int64 {
	var v int64
	shift := 0
	for shift < 70 {
		c := r.byte()
		v |= int64(c&0x7F) << shift
		shift += 7
		if c&0x80 == 0 {
			if shift < 64 && c&0x40 != 0 {
				v |= -1 << shift
			}
			return v
		}
	}
	r.fail("LEB128 too long at %d", r.pos)
	return 0
}

func (r *reader) name() string {
	n := r.u32()
	if r.err != nil || r.pos+int(n) > len(r.b) {
		r.fail("name overruns the data at %d", r.pos)
		return ""
	}
	s := string(r.b[r.pos : r.pos+int(n)])
	r.pos += int(n)
	return s
}

func (r *reader) limits() {
	flags := r.byte()
	r.u64()
	if flags&1 != 0 {
		r.u64()
	}
}

// blockType is a value type byte or a type index (s33).
func (r *reader) blockType() {
	if b := r.b[min(r.pos, len(r.b)-1)]; b == 0x40 || (b >= 0x6F && b <= 0x7F) {
		r.byte()
		return
	}
	r.s64()
}

func (r *reader) memarg() {
	flags := r.u32()
	r.u64()
	if flags&0x40 != 0 { // explicit memory index
		r.u32()
	}
}

// constExpr skips an initializer expression up to its end opcode.
func (r *reader) constExpr() {
	for r.err == nil {
		switch op := r.byte(); op {
		case 0x0B:
			return
		case 0x41, 0x42:
			r.s64()
		case 0x43:
			r.skip(4)
		case 0x44:
			r.skip(8)
		case 0x23, 0xD2:
			r.u32()
		case 0xD0:
			r.byte()
		case 0xFD:
			if r.u32() == 12 {
				r.skip(16)
			} else {
				r.fail("SIMD opcode in constant expression")
			}
		default:
			r.fail("opcode %#x in constant expression", op)
		}
	}
}

func (r *reader) miscOp() error {
	sub := r.u32()
	switch {
	case sub <= 7: // saturating truncations
	case sub == 8: // memory.init seg mem
		r.u32()
		r.u32()
	case sub == 9: // data.drop
		r.u32()
	case sub == 10: // memory.copy
		r.u32()
		r.u32()
	case sub == 11: // memory.fill
		r.u32()
	case sub == 12: // table.init
		r.u32()
		r.u32()
	case sub == 13: // elem.drop
		r.u32()
	case sub == 14: // table.copy
		r.u32()
		r.u32()
	case sub >= 15 && sub <= 17: // table.grow size fill
		r.u32()
	default:
		return fmt.Errorf("0xFC opcode %d", sub)
	}
	return nil
}

func (r *reader) simdOp() error {
	sub := r.u32()
	switch {
	case sub <= 11: // loads and stores
		r.memarg()
	case sub == 12: // v128.const
		r.skip(16)
	case sub == 13: // i8x16.shuffle
		r.skip(16)
	case sub >= 21 && sub <= 34: // extract/replace lane
		r.byte()
	case sub >= 84 && sub <= 91: // load/store lane
		r.memarg()
		r.byte()
	case sub == 92 || sub == 93: // v128.load32_zero/load64_zero
		r.memarg()
	case sub > 275:
		return fmt.Errorf("SIMD opcode %d", sub)
	}
	return nil
}

func (r *reader) atomicOp() error {
	sub := r.u32()
	switch {
	case sub == 3: // atomic.fence
		r.byte()
	case sub <= 0x4E:
		r.memarg()
	default:
		return fmt.Errorf("atomic opcode %d", sub)
	}
	return nil
}

// reachable reports how an exported function is reached: a direct call from
// another function or a slot in a funcref table (an indirect call). An
// export with neither is dead code, whatever native body replaces it.
func (m *module) reachable(name string) (bool, string) {
	idx, ok := m.exports[name]
	if !ok {
		return false, "not exported"
	}
	callers := 0
	for c := range m.calls[idx] {
		if c != idx {
			callers++
		}
	}
	switch {
	case callers > 0 && m.elemFuncs[idx]:
		return true, fmt.Sprintf("called from %d functions and held by a funcref table", callers)
	case callers > 0:
		return true, fmt.Sprintf("called from %d functions", callers)
	case m.elemFuncs[idx]:
		return true, "held by a funcref table"
	}
	return false, "exported but no function calls it and no funcref table holds it"
}
