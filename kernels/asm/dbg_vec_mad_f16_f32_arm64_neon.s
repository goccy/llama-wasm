// dbg_vec_mad_f16_f32: y += v * x (x f16, y f32).
	MOVW	l0+8(FP), R1
	CMPW	$1, R1
	BLT	vmdone
	MOVD	l1+16(FP), R2
	MOVD	l2+24(FP), R3
	FMOVS	l3+32(FP), F8
	LSL	$2, R1, R26
	ADD	R2, R26, R27
	CMP	R27, R21
	BLO	vmoob
	LSL	$1, R1, R26
	ADD	R3, R26, R27
	CMP	R27, R21
	BLO	vmoob
	ADD	R20, R2, R2
	ADD	R20, R3, R3
vmloop16:
	CMPW	$16, R1
	BLT	vmtail4
	WORD $0x3cc00064 // ldur q4, [x3, #0]
	WORD $0x3cc10065 // ldur q5, [x3, #16]
	WORD $0x0e217890 // fcvtl v16.4s, v4.4h
	WORD $0x4e217891 // fcvtl2 v17.4s, v4.8h
	WORD $0x0e2178b2 // fcvtl v18.4s, v5.4h
	WORD $0x4e2178b3 // fcvtl2 v19.4s, v5.8h
	WORD $0x3cc00054 // ldur q20, [x2, #0]
	WORD $0x3cc10055 // ldur q21, [x2, #16]
	WORD $0x3cc20056 // ldur q22, [x2, #32]
	WORD $0x3cc30057 // ldur q23, [x2, #48]
	WORD $0x4f881214 // fmla v20.4s, v16.4s, v8.s[0]
	WORD $0x4f881235 // fmla v21.4s, v17.4s, v8.s[0]
	WORD $0x4f881256 // fmla v22.4s, v18.4s, v8.s[0]
	WORD $0x4f881277 // fmla v23.4s, v19.4s, v8.s[0]
	WORD $0x3c800054 // stur q20, [x2, #0]
	WORD $0x3c810055 // stur q21, [x2, #16]
	WORD $0x3c820056 // stur q22, [x2, #32]
	WORD $0x3c830057 // stur q23, [x2, #48]
	ADD	$32, R3, R3
	ADD	$64, R2, R2
	SUBW	$16, R1, R1
	B	vmloop16
vmtail4:
	CMPW	$4, R1
	BLT	vmtail1
	WORD $0xfc400064 // ldur d4, [x3, #0]
	WORD $0x0e217890 // fcvtl v16.4s, v4.4h
	WORD $0x3cc00054 // ldur q20, [x2, #0]
	WORD $0x4f881214 // fmla v20.4s, v16.4s, v8.s[0]
	WORD $0x3c800054 // stur q20, [x2, #0]
	ADD	$8, R3, R3
	ADD	$16, R2, R2
	SUBW	$4, R1, R1
	B	vmtail4
vmtail1:
	CBZW	R1, vmdone
	WORD $0x7c400064 // ldur h4, [x3, #0]
	WORD $0x1ee24084 // fcvt s4, h4
	FMOVS	(R2), F5
	WORD $0x1f081485 // fmadd s5, s4, s8, s5
	FMOVS	F5, (R2)
	ADD	$2, R3, R3
	ADD	$4, R2, R2
	SUBW	$1, R1, R1
	B	vmtail1
vmdone:
	RET
vmoob:
	B	ovr_oob
