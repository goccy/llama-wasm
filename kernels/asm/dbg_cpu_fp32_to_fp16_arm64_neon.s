// dbg_cpu_fp32_to_fp16: y = (f16) x, n elements.
	MOVD	l2+24(FP), R1
	CMP	$1, R1
	BLT	c3done
	MOVD	l0+8(FP), R3
	MOVD	l1+16(FP), R2
	LSL	$2, R1, R26
	ADD	R3, R26, R27
	CMP	R27, R21
	BLO	c3oob
	LSL	$1, R1, R26
	ADD	R2, R26, R27
	CMP	R27, R21
	BLO	c3oob
	ADD	R20, R3, R3
	ADD	R20, R2, R2
c3loop8:
	CMP	$8, R1
	BLT	c3loop4
	WORD $0x3cc00060 // ldur q0, [x3, #0]
	WORD $0x3cc10061 // ldur q1, [x3, #16]
	WORD $0x0e216802 // fcvtn v2.4h, v0.4s
	WORD $0x4e216822 // fcvtn2 v2.8h, v1.4s
	WORD $0x3c800042 // stur q2, [x2, #0]
	ADD	$32, R3, R3
	ADD	$16, R2, R2
	SUB	$8, R1, R1
	B	c3loop8
c3loop4:
	CMP	$4, R1
	BLT	c3tail
	WORD $0x3cc00060 // ldur q0, [x3, #0]
	WORD $0x0e216802 // fcvtn v2.4h, v0.4s
	FMOVD	F2, (R2)
	ADD	$16, R3, R3
	ADD	$8, R2, R2
	SUB	$4, R1, R1
	B	c3loop4
c3tail:
	CBZ	R1, c3done
	FMOVS	(R3), F0
	WORD $0x1e23c000 // fcvt h0, s0
	WORD $0x7d000040 // str h0, [x2]
	ADD	$4, R3, R3
	ADD	$2, R2, R2
	SUB	$1, R1, R1
	B	c3tail
c3done:
	RET
c3oob:
	B	ovr_oob
