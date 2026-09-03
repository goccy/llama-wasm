// dbg_vec_dot_f16: f16 dot product, f32 accumulate.
	MOVW	l0+8(FP), R1
	MOVD	l1+16(FP), R2
	MOVD	l3+32(FP), R3
	MOVD	l5+48(FP), R4
	ADD	$4, R2, R27
	CMP	R27, R21
	BLO	vdoob
	ADD	R20, R2, R2
	WORD $0x4f000400 // movi v0.4s, #0
	WORD $0x4f000401 // movi v1.4s, #0
	WORD $0x4f000402 // movi v2.4s, #0
	WORD $0x4f000403 // movi v3.4s, #0
	FMOVS	$0.0, F24
	CMPW	$1, R1
	BLT	vdreduce
	LSL	$1, R1, R26
	ADD	R3, R26, R27
	CMP	R27, R21
	BLO	vdoob
	ADD	R4, R26, R27
	CMP	R27, R21
	BLO	vdoob
	ADD	R20, R3, R3
	ADD	R20, R4, R4
vdloop16:
	CMPW	$16, R1
	BLT	vdtail4
	WORD $0x3cc00064 // ldur q4, [x3, #0]
	WORD $0x3cc10065 // ldur q5, [x3, #16]
	WORD $0x3cc00086 // ldur q6, [x4, #0]
	WORD $0x3cc10087 // ldur q7, [x4, #16]
	WORD $0x0e217890 // fcvtl v16.4s, v4.4h
	WORD $0x4e217891 // fcvtl2 v17.4s, v4.8h
	WORD $0x0e2178b2 // fcvtl v18.4s, v5.4h
	WORD $0x4e2178b3 // fcvtl2 v19.4s, v5.8h
	WORD $0x0e2178d4 // fcvtl v20.4s, v6.4h
	WORD $0x4e2178d5 // fcvtl2 v21.4s, v6.8h
	WORD $0x0e2178f6 // fcvtl v22.4s, v7.4h
	WORD $0x4e2178f7 // fcvtl2 v23.4s, v7.8h
	WORD $0x4e34ce00 // fmla v0.4s, v16.4s, v20.4s
	WORD $0x4e35ce21 // fmla v1.4s, v17.4s, v21.4s
	WORD $0x4e36ce42 // fmla v2.4s, v18.4s, v22.4s
	WORD $0x4e37ce63 // fmla v3.4s, v19.4s, v23.4s
	ADD	$32, R3, R3
	ADD	$32, R4, R4
	SUBW	$16, R1, R1
	B	vdloop16
vdtail4:
	CMPW	$4, R1
	BLT	vdtail1
	WORD $0xfc400064 // ldur d4, [x3, #0]
	WORD $0xfc400086 // ldur d6, [x4, #0]
	WORD $0x0e217890 // fcvtl v16.4s, v4.4h
	WORD $0x0e2178d4 // fcvtl v20.4s, v6.4h
	WORD $0x4e34ce00 // fmla v0.4s, v16.4s, v20.4s
	ADD	$8, R3, R3
	ADD	$8, R4, R4
	SUBW	$4, R1, R1
	B	vdtail4
vdtail1:
	CBZW	R1, vdreduce
	WORD $0x7c400064 // ldur h4, [x3, #0]
	WORD $0x7c400086 // ldur h6, [x4, #0]
	WORD $0x1ee24084 // fcvt s4, h4
	WORD $0x1ee240c6 // fcvt s6, h6
	WORD $0x1f066098 // fmadd s24, s4, s6, s24
	ADD	$2, R3, R3
	ADD	$2, R4, R4
	SUBW	$1, R1, R1
	B	vdtail1
vdreduce:
	WORD $0x4e21d400 // fadd v0.4s, v0.4s, v1.4s
	WORD $0x4e23d442 // fadd v2.4s, v2.4s, v3.4s
	WORD $0x4e22d400 // fadd v0.4s, v0.4s, v2.4s
	WORD $0x6e20d400 // faddp v0.4s, v0.4s, v0.4s
	WORD $0x7e30d800 // faddp s0, v0.2s
	FADDS	F24, F0, F0
	FMOVS	F0, (R2)
	RET
vdoob:
	B	ovr_oob
