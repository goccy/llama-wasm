// dbg_gemv_q8_0_4x4: q8_0x4 repack GEMV, four column groups per pass via by-element SDOT.
	MOVW	l0+8(FP), R1
	LSRW	$5, R1, R1
	MOVD	$136, R8
	MUL	R1, R8, R8
	MOVWU	l6+52(FP), R7
	LSRW	$2, R7, R7
	CBZW	R7, gvdone
	MOVD	l3+32(FP), R4
	MUL	R7, R8, R26
	ADD	R4, R26, R26
	CMP	R26, R21
	BLO	gvoob
	MOVD	l4+40(FP), R5
	MOVD	$34, R26
	MUL	R1, R26, R26
	ADD	R5, R26, R26
	CMP	R26, R21
	BLO	gvoob
	MOVD	l1+16(FP), R2
	LSL	$4, R7, R26
	ADD	R2, R26, R26
	CMP	R26, R21
	BLO	gvoob
	ADD	R20, R2, R2
	ADD	R20, R4, R4
	ADD	R20, R5, R5
	LSL	$2, R8, R9
gv4:
	B	gv1
	CMPW	$4, R7
	BLT	gv1
	WORD $0x4f00041c // movi v28.4s, #0
	WORD $0x4f00041d // movi v29.4s, #0
	WORD $0x4f00041e // movi v30.4s, #0
	WORD $0x4f00041f // movi v31.4s, #0
	MOVD	R4, R13
	ADD	R13, R8, R14
	ADD	R14, R8, R19
	ADD	R19, R8, R23
	MOVD	R5, R17
	MOVW	R1, R15
	CBZW	R15, gv4store
gv4blk:
	WORD $0x4f000418 // movi v24.4s, #0
	WORD $0x4f000419 // movi v25.4s, #0
	WORD $0x4f00041a // movi v26.4s, #0
	WORD $0x4f00041b // movi v27.4s, #0
	WORD $0x3cc02230 // ldur q16, [x17, #2]
	WORD $0x3cc12231 // ldur q17, [x17, #18]
	WORD $0x7c400232 // ldur h18, [x17, #0]
	WORD $0x1ee24252 // fcvt s18, h18
	WORD $0x3cc081a0 // ldur q0, [x13, #8]
	WORD $0x4f90e018 // sdot v24.4s, v0.16b, v16.4b[0]
	WORD $0x3cc081c1 // ldur q1, [x14, #8]
	WORD $0x4f90e039 // sdot v25.4s, v1.16b, v16.4b[0]
	WORD $0x3cc08262 // ldur q2, [x19, #8]
	WORD $0x4f90e05a // sdot v26.4s, v2.16b, v16.4b[0]
	WORD $0x3cc082e3 // ldur q3, [x23, #8]
	WORD $0x4f90e07b // sdot v27.4s, v3.16b, v16.4b[0]
	WORD $0x3cc181a0 // ldur q0, [x13, #24]
	WORD $0x4fb0e018 // sdot v24.4s, v0.16b, v16.4b[1]
	WORD $0x3cc181c1 // ldur q1, [x14, #24]
	WORD $0x4fb0e039 // sdot v25.4s, v1.16b, v16.4b[1]
	WORD $0x3cc18262 // ldur q2, [x19, #24]
	WORD $0x4fb0e05a // sdot v26.4s, v2.16b, v16.4b[1]
	WORD $0x3cc182e3 // ldur q3, [x23, #24]
	WORD $0x4fb0e07b // sdot v27.4s, v3.16b, v16.4b[1]
	WORD $0x3cc281a0 // ldur q0, [x13, #40]
	WORD $0x4f90e818 // sdot v24.4s, v0.16b, v16.4b[2]
	WORD $0x3cc281c1 // ldur q1, [x14, #40]
	WORD $0x4f90e839 // sdot v25.4s, v1.16b, v16.4b[2]
	WORD $0x3cc28262 // ldur q2, [x19, #40]
	WORD $0x4f90e85a // sdot v26.4s, v2.16b, v16.4b[2]
	WORD $0x3cc282e3 // ldur q3, [x23, #40]
	WORD $0x4f90e87b // sdot v27.4s, v3.16b, v16.4b[2]
	WORD $0x3cc381a0 // ldur q0, [x13, #56]
	WORD $0x4fb0e818 // sdot v24.4s, v0.16b, v16.4b[3]
	WORD $0x3cc381c1 // ldur q1, [x14, #56]
	WORD $0x4fb0e839 // sdot v25.4s, v1.16b, v16.4b[3]
	WORD $0x3cc38262 // ldur q2, [x19, #56]
	WORD $0x4fb0e85a // sdot v26.4s, v2.16b, v16.4b[3]
	WORD $0x3cc382e3 // ldur q3, [x23, #56]
	WORD $0x4fb0e87b // sdot v27.4s, v3.16b, v16.4b[3]
	WORD $0x3cc481a0 // ldur q0, [x13, #72]
	WORD $0x4f91e018 // sdot v24.4s, v0.16b, v17.4b[0]
	WORD $0x3cc481c1 // ldur q1, [x14, #72]
	WORD $0x4f91e039 // sdot v25.4s, v1.16b, v17.4b[0]
	WORD $0x3cc48262 // ldur q2, [x19, #72]
	WORD $0x4f91e05a // sdot v26.4s, v2.16b, v17.4b[0]
	WORD $0x3cc482e3 // ldur q3, [x23, #72]
	WORD $0x4f91e07b // sdot v27.4s, v3.16b, v17.4b[0]
	WORD $0x3cc581a0 // ldur q0, [x13, #88]
	WORD $0x4fb1e018 // sdot v24.4s, v0.16b, v17.4b[1]
	WORD $0x3cc581c1 // ldur q1, [x14, #88]
	WORD $0x4fb1e039 // sdot v25.4s, v1.16b, v17.4b[1]
	WORD $0x3cc58262 // ldur q2, [x19, #88]
	WORD $0x4fb1e05a // sdot v26.4s, v2.16b, v17.4b[1]
	WORD $0x3cc582e3 // ldur q3, [x23, #88]
	WORD $0x4fb1e07b // sdot v27.4s, v3.16b, v17.4b[1]
	WORD $0x3cc681a0 // ldur q0, [x13, #104]
	WORD $0x4f91e818 // sdot v24.4s, v0.16b, v17.4b[2]
	WORD $0x3cc681c1 // ldur q1, [x14, #104]
	WORD $0x4f91e839 // sdot v25.4s, v1.16b, v17.4b[2]
	WORD $0x3cc68262 // ldur q2, [x19, #104]
	WORD $0x4f91e85a // sdot v26.4s, v2.16b, v17.4b[2]
	WORD $0x3cc682e3 // ldur q3, [x23, #104]
	WORD $0x4f91e87b // sdot v27.4s, v3.16b, v17.4b[2]
	WORD $0x3cc781a0 // ldur q0, [x13, #120]
	WORD $0x4fb1e818 // sdot v24.4s, v0.16b, v17.4b[3]
	WORD $0x3cc781c1 // ldur q1, [x14, #120]
	WORD $0x4fb1e839 // sdot v25.4s, v1.16b, v17.4b[3]
	WORD $0x3cc78262 // ldur q2, [x19, #120]
	WORD $0x4fb1e85a // sdot v26.4s, v2.16b, v17.4b[3]
	WORD $0x3cc782e3 // ldur q3, [x23, #120]
	WORD $0x4fb1e87b // sdot v27.4s, v3.16b, v17.4b[3]
	WORD $0xfc4001b3 // ldur d19, [x13, #0]
	WORD $0x0e217a73 // fcvtl v19.4s, v19.4h
	WORD $0x4e21db18 // scvtf v24.4s, v24.4s
	WORD $0x6e33df18 // fmul v24.4s, v24.4s, v19.4s
	WORD $0x4f92131c // fmla v28.4s, v24.4s, v18.s[0]
	WORD $0xfc4001d3 // ldur d19, [x14, #0]
	WORD $0x0e217a73 // fcvtl v19.4s, v19.4h
	WORD $0x4e21db39 // scvtf v25.4s, v25.4s
	WORD $0x6e33df39 // fmul v25.4s, v25.4s, v19.4s
	WORD $0x4f92133d // fmla v29.4s, v25.4s, v18.s[0]
	WORD $0xfc400273 // ldur d19, [x19, #0]
	WORD $0x0e217a73 // fcvtl v19.4s, v19.4h
	WORD $0x4e21db5a // scvtf v26.4s, v26.4s
	WORD $0x6e33df5a // fmul v26.4s, v26.4s, v19.4s
	WORD $0x4f92135e // fmla v30.4s, v26.4s, v18.s[0]
	WORD $0xfc4002f3 // ldur d19, [x23, #0]
	WORD $0x0e217a73 // fcvtl v19.4s, v19.4h
	WORD $0x4e21db7b // scvtf v27.4s, v27.4s
	WORD $0x6e33df7b // fmul v27.4s, v27.4s, v19.4s
	WORD $0x4f92137f // fmla v31.4s, v27.4s, v18.s[0]
	ADD	$136, R13, R13
	ADD	$136, R14, R14
	ADD	$136, R19, R19
	ADD	$136, R23, R23
	ADD	$34, R17, R17
	SUBW	$1, R15, R15
	CBNZW	R15, gv4blk
gv4store:
	WORD $0x3c80005c // stur q28, [x2, #0]
	WORD $0x3c81005d // stur q29, [x2, #16]
	WORD $0x3c82005e // stur q30, [x2, #32]
	WORD $0x3c83005f // stur q31, [x2, #48]
	ADD	$64, R2, R2
	ADD	R9, R4, R4
	SUBW	$4, R7, R7
	B	gv4
gv1:
	CBZW	R7, gvdone
	WORD $0x4f00041c // movi v28.4s, #0
	MOVD	R4, R13
	MOVD	R5, R17
	MOVW	R1, R15
	CBZW	R15, gv1store
gv1blk:
	WORD $0x4f000418 // movi v24.4s, #0
	WORD $0x4f000419 // movi v25.4s, #0
	WORD $0x3cc02230 // ldur q16, [x17, #2]
	WORD $0x3cc12231 // ldur q17, [x17, #18]
	WORD $0x7c400232 // ldur h18, [x17, #0]
	WORD $0x1ee24252 // fcvt s18, h18
	WORD $0x3cc081a0 // ldur q0, [x13, #8]
	WORD $0x4f90e018 // sdot v24.4s, v0.16b, v16.4b[0]
	WORD $0x3cc181a1 // ldur q1, [x13, #24]
	WORD $0x4fb0e039 // sdot v25.4s, v1.16b, v16.4b[1]
	WORD $0x3cc281a0 // ldur q0, [x13, #40]
	WORD $0x4f90e818 // sdot v24.4s, v0.16b, v16.4b[2]
	WORD $0x3cc381a1 // ldur q1, [x13, #56]
	WORD $0x4fb0e839 // sdot v25.4s, v1.16b, v16.4b[3]
	WORD $0x3cc481a0 // ldur q0, [x13, #72]
	WORD $0x4f91e018 // sdot v24.4s, v0.16b, v17.4b[0]
	WORD $0x3cc581a1 // ldur q1, [x13, #88]
	WORD $0x4fb1e039 // sdot v25.4s, v1.16b, v17.4b[1]
	WORD $0x3cc681a0 // ldur q0, [x13, #104]
	WORD $0x4f91e818 // sdot v24.4s, v0.16b, v17.4b[2]
	WORD $0x3cc781a1 // ldur q1, [x13, #120]
	WORD $0x4fb1e839 // sdot v25.4s, v1.16b, v17.4b[3]
	WORD $0x4eb98718 // add v24.4s, v24.4s, v25.4s
	WORD $0xfc4001b3 // ldur d19, [x13, #0]
	WORD $0x0e217a73 // fcvtl v19.4s, v19.4h
	WORD $0x4e21db18 // scvtf v24.4s, v24.4s
	WORD $0x6e33df18 // fmul v24.4s, v24.4s, v19.4s
	WORD $0x4f92131c // fmla v28.4s, v24.4s, v18.s[0]
	ADD	$136, R13, R13
	ADD	$34, R17, R17
	SUBW	$1, R15, R15
	CBNZW	R15, gv1blk
gv1store:
	WORD $0x3c80005c // stur q28, [x2, #0]
	ADD	$16, R2, R2
	ADD	R8, R4, R4
	SUBW	$1, R7, R7
	B	gv1
gvdone:
	RET
gvoob:
	B	kov_oob
