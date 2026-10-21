// dbg_vec_sum_f32: returns sum(x) (f64).
	FMOVD	ZR, F15
	MOVW	l0+8(FP), R1
	CMPW	$1, R1
	BLT	vsdone
	MOVD	l1+16(FP), R3
	LSL	$2, R1, R26
	ADD	R3, R26, R27
	CMP	R27, R21
	BLO	vsoob
	ADD	R20, R3, R3
vsloop4:
	CMPW	$4, R1
	BLT	vstail
	WORD $0x3cc00060 // ldur q0, [x3, #0]
	WORD $0x6e20d401 // faddp v1.4s, v0.4s, v0.4s
	WORD $0x7e30d821 // faddp s1, v1.2s
	FCVTSD	F1, F1
	FADDD	F1, F15, F15
	ADD	$16, R3, R3
	SUBW	$4, R1, R1
	B	vsloop4
vstail:
	CBZW	R1, vsdone
	FMOVS	(R3), F0
	FCVTSD	F0, F1
	FADDD	F1, F15, F15
	ADD	$4, R3, R3
	SUBW	$1, R1, R1
	B	vstail
vsdone:
	FMOVD	F15, r0+24(FP)
	RET
vsoob:
	B	ovr_oob
