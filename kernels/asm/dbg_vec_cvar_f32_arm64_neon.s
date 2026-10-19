// dbg_vec_cvar_f32: y = x - mean, returns sum(y*y)/n (f64).
	FMOVD	ZR, F15
	MOVW	l0+8(FP), R1
	CMPW	$1, R1
	BLT	cvdone
	MOVW	R1, R5
	MOVD	l1+16(FP), R2
	MOVD	l2+24(FP), R3
	LSL	$2, R1, R26
	ADD	R2, R26, R27
	CMP	R27, R21
	BLO	cvoob
	ADD	R3, R26, R27
	CMP	R27, R21
	BLO	cvoob
	ADD	R20, R2, R2
	ADD	R20, R3, R3
	FMOVS	l3+32(FP), F14
	WORD $0x4e0405ce // dup v14.4s, v14.s[0]
cvloop4:
	CMPW	$4, R1
	BLT	cvtail
	WORD $0x3cc00060 // ldur q0, [x3, #0]
	WORD $0x4eaed400 // fsub v0.4s, v0.4s, v14.4s
	WORD $0x3c800040 // stur q0, [x2, #0]
	WORD $0x6e20dc00 // fmul v0.4s, v0.4s, v0.4s
	WORD $0x6e20d401 // faddp v1.4s, v0.4s, v0.4s
	WORD $0x7e30d821 // faddp s1, v1.2s
	FCVTSD	F1, F1
	FADDD	F1, F15, F15
	ADD	$16, R2, R2
	ADD	$16, R3, R3
	SUBW	$4, R1, R1
	B	cvloop4
cvtail:
	CBZW	R1, cvdone
	FMOVS	(R3), F0
	FSUBS	F14, F0, F0
	FMOVS	F0, (R2)
	FMULS	F0, F0, F0
	FCVTSD	F0, F1
	FADDD	F1, F15, F15
	ADD	$4, R2, R2
	ADD	$4, R3, R3
	SUBW	$1, R1, R1
	B	cvtail
cvdone:
	SCVTFWD	R5, F1
	FDIVD	F1, F15, F15
	FMOVD	F15, r0+40(FP)
	RET
cvoob:
	B	ovr_oob
