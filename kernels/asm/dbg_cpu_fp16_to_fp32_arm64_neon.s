// dbg_cpu_fp16_to_fp32: y = (f32) x, n elements.
	MOVD	l2+24(FP), R1
	CMP	$1, R1
	BLT	c1done
	MOVD	l0+8(FP), R3
	MOVD	l1+16(FP), R2
	LSL	$1, R1, R26
	ADD	R3, R26, R27
	CMP	R27, R21
	BLO	c1oob
	LSL	$2, R1, R26
	ADD	R2, R26, R27
	CMP	R27, R21
	BLO	c1oob
	ADD	R20, R3, R3
	ADD	R20, R2, R2
c1loop8:
	CMP	$8, R1
	BLT	c1loop4
	WORD $0x3cc00060 // ldur q0, [x3, #0]
	WORD $0x0e217801 // fcvtl v1.4s, v0.4h
	WORD $0x4e217802 // fcvtl2 v2.4s, v0.8h
	WORD $0x3c800041 // stur q1, [x2, #0]
	WORD $0x3c810042 // stur q2, [x2, #16]
	ADD	$16, R3, R3
	ADD	$32, R2, R2
	SUB	$8, R1, R1
	B	c1loop8
c1loop4:
	CMP	$4, R1
	BLT	c1tail
	FMOVD	(R3), F0
	WORD $0x0e217801 // fcvtl v1.4s, v0.4h
	WORD $0x3c800041 // stur q1, [x2, #0]
	ADD	$8, R3, R3
	ADD	$16, R2, R2
	SUB	$4, R1, R1
	B	c1loop4
c1tail:
	CBZ	R1, c1done
	WORD $0x7d400060 // ldr h0, [x3]
	WORD $0x1ee24000 // fcvt s0, h0
	FMOVS	F0, (R2)
	ADD	$2, R3, R3
	ADD	$4, R2, R2
	SUB	$1, R1, R1
	B	c1tail
c1done:
	RET
c1oob:
	B	ovr_oob
