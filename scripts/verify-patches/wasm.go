package main

// A minimal WebAssembly binary reader for the checks in this package: it
// walks every function body instruction by instruction, tracking the
// control stack. It understands the opcode set the llama.wasm build uses
// (core, tail calls, legacy exception handling, the 0xFC/SIMD/threads
// prefixes, memory64 immediates) and refuses unknown opcodes instead of
// guessing their length — a mis-skipped immediate would silently
// desynchronise the scan and corrupt every result after it.

import (
	"encoding/binary"
	"fmt"
)

type parseError struct{ msg string }

func (e parseError) Error() string { return e.msg }

type reader struct {
	b   []byte
	off int
}

func (r *reader) fail(format string, args ...any) {
	panic(parseError{fmt.Sprintf("offset 0x%x: %s", r.off, fmt.Sprintf(format, args...))})
}

func (r *reader) u8() byte {
	if r.off >= len(r.b) {
		r.fail("unexpected end of input")
	}
	v := r.b[r.off]
	r.off++
	return v
}

func (r *reader) skip(n int) {
	if r.off+n > len(r.b) {
		r.fail("unexpected end of input")
	}
	r.off += n
}

func (r *reader) uleb() uint64 {
	var v uint64
	var shift uint
	for {
		b := r.u8()
		v |= uint64(b&0x7f) << shift
		if b&0x80 == 0 {
			return v
		}
		shift += 7
		if shift >= 64 {
			r.fail("uleb128 too long")
		}
	}
}

func (r *reader) sleb() int64 {
	var v int64
	var shift uint
	for {
		b := r.u8()
		v |= int64(b&0x7f) << shift
		shift += 7
		if b&0x80 == 0 {
			if shift < 64 && b&0x40 != 0 {
				v |= -1 << shift
			}
			return v
		}
		if shift >= 64 {
			r.fail("sleb128 too long")
		}
	}
}

// memarg reads an alignment + offset pair. Bit 6 of the alignment flags a
// multi-memory index (unused in this build, but read correctly if present).
func (r *reader) memarg() {
	align := r.uleb()
	if align&0x40 != 0 {
		r.uleb() // memidx
	}
	r.uleb() // offset (u64 under memory64)
}

// bareSpin is a loop whose back-branch is reachable after an atomic load
// with no call of any kind in the loop body.
type bareSpin struct {
	Func      int // function index, counting imports, as wasm-objdump numbers them
	LoopOff   int // file offset of the `loop` opcode
	BranchOff int // file offset of the branch that closes the spin
}

func (s bareSpin) String() string {
	return fmt.Sprintf("func[%d] loop@0x%06x back-branch@0x%06x", s.Func, s.LoopOff, s.BranchOff)
}

// scanBareSpins parses the module and returns every bare atomic spin loop.
//
// The check is loop-granular, not path-sensitive: one call anywhere in a
// loop body clears the whole loop, so a call-free spin subpath inside a
// loop that also does calling work would pass. That approximation matches
// the shape ggml emits — its barrier/poll spins are minimal loops — and
// keeps the scan free of false positives.
func scanBareSpins(wasm []byte) (spins []bareSpin, err error) {
	defer func() {
		if p := recover(); p != nil {
			if pe, ok := p.(parseError); ok {
				err = pe
				return
			}
			panic(p)
		}
	}()

	r := &reader{b: wasm}
	if len(wasm) < 8 || string(wasm[0:4]) != "\x00asm" ||
		binary.LittleEndian.Uint32(wasm[4:8]) != 1 {
		return nil, parseError{"not a wasm v1 module"}
	}
	r.off = 8

	importedFuncs := 0
	for r.off < len(r.b) {
		id := r.u8()
		size := int(r.uleb())
		end := r.off + size
		switch id {
		case 2: // import section: count function imports for index reporting
			for n := r.uleb(); n > 0; n-- {
				r.skip(int(r.uleb())) // module name
				r.skip(int(r.uleb())) // field name
				switch kind := r.u8(); kind {
				case 0: // func
					r.uleb()
					importedFuncs++
				case 1: // table: reftype + limits
					r.u8()
					r.limits()
				case 2: // memory: limits
					r.limits()
				case 3: // global: valtype + mutability
					r.u8()
					r.u8()
				case 4: // tag: attribute + typeidx
					r.u8()
					r.uleb()
				default:
					r.fail("unknown import kind %d", kind)
				}
			}
		case 10: // code section
			for n, i := r.uleb(), 0; uint64(i) < n; i++ {
				bodySize := int(r.uleb())
				bodyEnd := r.off + bodySize
				spins = append(spins, r.scanBody(importedFuncs+i, bodyEnd)...)
				if r.off != bodyEnd {
					r.fail("function body length mismatch (func[%d])", importedFuncs+i)
				}
			}
		}
		if r.off > end {
			r.fail("section %d overran its size", id)
		}
		r.off = end
	}
	return spins, nil
}

func (r *reader) limits() {
	flags := r.uleb()
	r.uleb() // min
	if flags&0x01 != 0 {
		r.uleb() // max
	}
}

// frame is one entry of the control stack. Only loops carry state; other
// constructs are placeholders so branch depths resolve correctly.
type frame struct {
	isLoop   bool
	off      int
	atomic   bool
	call     bool
	reported bool
}

func (r *reader) scanBody(funcIndex, bodyEnd int) []bareSpin {
	for n := r.uleb(); n > 0; n-- { // local declarations
		r.uleb() // count
		r.u8()   // valtype
	}

	var spins []bareSpin
	var stack []*frame

	markAtomic := func() {
		for _, f := range stack {
			if f.isLoop {
				f.atomic = true
			}
		}
	}
	markCall := func() {
		for _, f := range stack {
			if f.isLoop {
				f.call = true
			}
		}
	}
	branch := func(depth uint64, at int) {
		idx := len(stack) - 1 - int(depth)
		if idx < 0 || idx >= len(stack) {
			return // targets the function frame
		}
		f := stack[idx]
		if f.isLoop && f.atomic && !f.call && !f.reported {
			f.reported = true
			spins = append(spins, bareSpin{Func: funcIndex, LoopOff: f.off, BranchOff: at})
		}
	}

	for r.off < bodyEnd {
		at := r.off
		op := r.u8()
		switch op {
		case 0x00, 0x01: // unreachable, nop
		case 0x02, 0x04, 0x06: // block, if, try
			r.sleb() // blocktype (s33)
			stack = append(stack, &frame{})
		case 0x03: // loop
			r.sleb()
			stack = append(stack, &frame{isLoop: true, off: at})
		case 0x05, 0x19: // else, catch_all
		case 0x07: // catch
			r.uleb()
		case 0x08, 0x09: // throw, rethrow: reaches the runtime, a preemption point
			r.uleb()
			markCall()
		case 0x18: // delegate: closes a try
			r.uleb()
			if len(stack) > 0 {
				stack = stack[:len(stack)-1]
			}
		case 0x0b: // end
			if len(stack) > 0 {
				stack = stack[:len(stack)-1]
			}
		case 0x0c, 0x0d: // br, br_if
			branch(r.uleb(), at)
		case 0x0e: // br_table
			for n := r.uleb(); n > 0; n-- {
				branch(r.uleb(), at)
			}
			branch(r.uleb(), at) // default target
		case 0x0f: // return
		case 0x10, 0x12: // call, return_call
			r.uleb()
			markCall()
		case 0x11, 0x13: // call_indirect, return_call_indirect
			r.uleb()
			r.uleb()
			markCall()
		case 0x1a, 0x1b: // drop, select
		case 0x1c: // select with types
			for n := r.uleb(); n > 0; n-- {
				r.u8()
			}
		case 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26: // local/global/table get-set
			r.uleb()
		case 0x3f, 0x40: // memory.size, memory.grow
			r.uleb()
		case 0x41: // i32.const
			r.sleb()
		case 0x42: // i64.const
			r.sleb()
		case 0x43: // f32.const
			r.skip(4)
		case 0x44: // f64.const
			r.skip(8)
		case 0xd0: // ref.null
			r.sleb()
		case 0xd1: // ref.is_null
		case 0xd2: // ref.func
			r.uleb()
		case 0xfc:
			r.miscOp()
		case 0xfd:
			r.simdOp()
		case 0xfe:
			r.atomicOp(markAtomic, markCall)
		default:
			switch {
			case op >= 0x28 && op <= 0x3e: // plain loads and stores
				r.memarg()
			case op >= 0x45 && op <= 0xc4: // numeric ops, sign extensions
			default:
				r.fail("unknown opcode 0x%02x in func[%d]", op, funcIndex)
			}
		}
	}
	return spins
}

func (r *reader) miscOp() {
	sub := r.uleb()
	switch {
	case sub <= 7: // i32/i64.trunc_sat_f32/f64_s/u
	case sub == 8, sub == 10, sub == 12, sub == 14: // memory.init/copy, table.init/copy
		r.uleb()
		r.uleb()
	case sub == 9, sub == 11, sub == 13, sub >= 15 && sub <= 17: // data.drop, memory.fill, elem.drop, table.grow/size/fill
		r.uleb()
	default:
		r.fail("unknown 0xFC opcode %d", sub)
	}
}

func (r *reader) simdOp() {
	sub := r.uleb()
	switch {
	case sub <= 11, sub == 92, sub == 93: // v128 loads/stores incl. load*_zero
		r.memarg()
	case sub == 12, sub == 13: // v128.const, i8x16.shuffle
		r.skip(16)
	case sub >= 21 && sub <= 34: // extract/replace lane
		r.skip(1)
	case sub >= 84 && sub <= 91: // load/store lane
		r.memarg()
		r.skip(1)
	case sub <= 0x114: // every other (relaxed) SIMD op carries no immediate
	default:
		r.fail("unknown SIMD opcode %d", sub)
	}
}

func (r *reader) atomicOp(markAtomic, markCall func()) {
	sub := r.uleb()
	switch {
	case sub == 0: // memory.atomic.notify
		r.memarg()
	case sub == 1 || sub == 2: // memory.atomic.wait32/64: parks the thread, a preemption point
		r.memarg()
		markCall()
	case sub == 3: // atomic.fence
		r.u8()
	case sub >= 0x10 && sub <= 0x16: // atomic loads
		r.memarg()
		markAtomic()
	case sub >= 0x17 && sub <= 0x4e: // atomic stores and read-modify-writes
		r.memarg()
	default:
		r.fail("unknown atomic opcode %d", sub)
	}
}
