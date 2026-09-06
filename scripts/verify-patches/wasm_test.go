package main

import "testing"

// leb encodes small unsigned values (< 128) as one LEB128 byte.
func sec(id byte, body ...byte) []byte { return append([]byte{id, byte(len(body))}, body...) }

// tinyModule: three functions. f0 is exported as "live_called" and called by
// f2; f1 is exported as "live_table" and held by the funcref table; f2 is
// exported as "dead" and reached by nothing.
func tinyModule() []byte {
	b := []byte{0, 'a', 's', 'm', 1, 0, 0, 0}
	b = append(b, sec(1, 1, 0x60, 0, 0)...) // type: () -> ()
	b = append(b, sec(3, 3, 0, 0, 0)...)    // 3 functions of type 0
	b = append(b, sec(4, 1, 0x70, 0, 1)...) // table: funcref min 1
	exp := []byte{3}
	for _, e := range []struct {
		name string
		idx  byte
	}{{"live_called", 0}, {"live_table", 1}, {"dead", 2}} {
		exp = append(exp, byte(len(e.name)))
		exp = append(exp, e.name...)
		exp = append(exp, 0, e.idx)
	}
	b = append(b, sec(7, exp...)...)
	b = append(b, sec(9, 1, 0, 0x41, 0, 0x0B, 1, 1)...) // elem: active, offset i32.const 0, [f1]
	f0 := []byte{2, 0, 0x0B}                            // body: no locals, end
	f1 := []byte{2, 0, 0x0B}
	f2 := []byte{4, 0, 0x10, 0, 0x0B} // body: call 0, end
	code := append([]byte{3}, f0...)
	code = append(code, f1...)
	code = append(code, f2...)
	b = append(b, sec(10, code...)...)
	return b
}

func TestReachability(t *testing.T) {
	m, err := parseModule(tinyModule())
	if err != nil {
		t.Fatal(err)
	}
	for _, c := range []struct {
		name string
		want bool
	}{{"live_called", true}, {"live_table", true}, {"dead", false}, {"absent", false}} {
		got, why := m.reachable(c.name)
		if got != c.want {
			t.Errorf("%s: reachable=%v (%s), want %v", c.name, got, why, c.want)
		}
	}
	if err := hasExports("live_called", "live_table")(tinyModule()); err != nil {
		t.Errorf("live exports rejected: %v", err)
	}
	if err := hasExports("dead")(tinyModule()); err == nil {
		t.Errorf("dead export accepted")
	}
}
