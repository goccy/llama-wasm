// dbg_vec_dot_tq2_0_q8_K: tq2_0 x q8_K dot, 2-bit planes shifted out and SDOTed.
	WORD $0x4f000400 // movi v0.4s, #0
	MOVW	l0+8(FP), R1
	LSRW	$8, R1, R1
	MOVD	l1+16(FP), R2
	ADD	$4, R2, R27
	CMP	R27, R21
	BLO	tq2oob
	ADD	R20, R2, R2
	CBZW	R1, tq2reduce
	MOVD	l3+32(FP), R3
	MOVD	l5+48(FP), R4
	MOVD	$66, R26
	MUL	R1, R26, R26
	ADD	R3, R26, R27
	CMP	R27, R21
	BLO	tq2oob
	MOVD	$292, R26
	MUL	R1, R26, R26
	ADD	R4, R26, R27
	CMP	R27, R21
	BLO	tq2oob
	ADD	R20, R3, R3
	ADD	R20, R4, R4
	WORD $0x4f00e470 // movi v16.16b, #3
	WORD $0x4f00e431 // movi v17.16b, #1
tq2blk:
	WORD $0x4f000414 // movi v20.4s, #0
	WORD $0x3cc00062 // ldur q2, [x3, #0]
	WORD $0x3cc10063 // ldur q3, [x3, #16]
	WORD $0x4e301c44 // and v4.16b, v2.16b, v16.16b
	WORD $0x4e301c65 // and v5.16b, v3.16b, v16.16b
	WORD $0x6e318484 // sub v4.16b, v4.16b, v17.16b
	WORD $0x6e3184a5 // sub v5.16b, v5.16b, v17.16b
	WORD $0x3cc04086 // ldur q6, [x4, #4]
	WORD $0x3cc14087 // ldur q7, [x4, #20]
	WORD $0x4e869494 // sdot v20.4s, v4.16b, v6.16b
	WORD $0x4e8794b4 // sdot v20.4s, v5.16b, v7.16b
	WORD $0x6f0e0444 // ushr v4.16b, v2.16b, #2
	WORD $0x6f0e0465 // ushr v5.16b, v3.16b, #2
	WORD $0x4e301c84 // and v4.16b, v4.16b, v16.16b
	WORD $0x4e301ca5 // and v5.16b, v5.16b, v16.16b
	WORD $0x6e318484 // sub v4.16b, v4.16b, v17.16b
	WORD $0x6e3184a5 // sub v5.16b, v5.16b, v17.16b
	WORD $0x3cc24086 // ldur q6, [x4, #36]
	WORD $0x3cc34087 // ldur q7, [x4, #52]
	WORD $0x4e869494 // sdot v20.4s, v4.16b, v6.16b
	WORD $0x4e8794b4 // sdot v20.4s, v5.16b, v7.16b
	WORD $0x6f0c0444 // ushr v4.16b, v2.16b, #4
	WORD $0x6f0c0465 // ushr v5.16b, v3.16b, #4
	WORD $0x4e301c84 // and v4.16b, v4.16b, v16.16b
	WORD $0x4e301ca5 // and v5.16b, v5.16b, v16.16b
	WORD $0x6e318484 // sub v4.16b, v4.16b, v17.16b
	WORD $0x6e3184a5 // sub v5.16b, v5.16b, v17.16b
	WORD $0x3cc44086 // ldur q6, [x4, #68]
	WORD $0x3cc54087 // ldur q7, [x4, #84]
	WORD $0x4e869494 // sdot v20.4s, v4.16b, v6.16b
	WORD $0x4e8794b4 // sdot v20.4s, v5.16b, v7.16b
	WORD $0x6f0a0444 // ushr v4.16b, v2.16b, #6
	WORD $0x6f0a0465 // ushr v5.16b, v3.16b, #6
	WORD $0x4e301c84 // and v4.16b, v4.16b, v16.16b
	WORD $0x4e301ca5 // and v5.16b, v5.16b, v16.16b
	WORD $0x6e318484 // sub v4.16b, v4.16b, v17.16b
	WORD $0x6e3184a5 // sub v5.16b, v5.16b, v17.16b
	WORD $0x3cc64086 // ldur q6, [x4, #100]
	WORD $0x3cc74087 // ldur q7, [x4, #116]
	WORD $0x4e869494 // sdot v20.4s, v4.16b, v6.16b
	WORD $0x4e8794b4 // sdot v20.4s, v5.16b, v7.16b
	WORD $0x3cc20062 // ldur q2, [x3, #32]
	WORD $0x3cc30063 // ldur q3, [x3, #48]
	WORD $0x4e301c44 // and v4.16b, v2.16b, v16.16b
	WORD $0x4e301c65 // and v5.16b, v3.16b, v16.16b
	WORD $0x6e318484 // sub v4.16b, v4.16b, v17.16b
	WORD $0x6e3184a5 // sub v5.16b, v5.16b, v17.16b
	WORD $0x3cc84086 // ldur q6, [x4, #132]
	WORD $0x3cc94087 // ldur q7, [x4, #148]
	WORD $0x4e869494 // sdot v20.4s, v4.16b, v6.16b
	WORD $0x4e8794b4 // sdot v20.4s, v5.16b, v7.16b
	WORD $0x6f0e0444 // ushr v4.16b, v2.16b, #2
	WORD $0x6f0e0465 // ushr v5.16b, v3.16b, #2
	WORD $0x4e301c84 // and v4.16b, v4.16b, v16.16b
	WORD $0x4e301ca5 // and v5.16b, v5.16b, v16.16b
	WORD $0x6e318484 // sub v4.16b, v4.16b, v17.16b
	WORD $0x6e3184a5 // sub v5.16b, v5.16b, v17.16b
	WORD $0x3cca4086 // ldur q6, [x4, #164]
	WORD $0x3ccb4087 // ldur q7, [x4, #180]
	WORD $0x4e869494 // sdot v20.4s, v4.16b, v6.16b
	WORD $0x4e8794b4 // sdot v20.4s, v5.16b, v7.16b
	WORD $0x6f0c0444 // ushr v4.16b, v2.16b, #4
	WORD $0x6f0c0465 // ushr v5.16b, v3.16b, #4
	WORD $0x4e301c84 // and v4.16b, v4.16b, v16.16b
	WORD $0x4e301ca5 // and v5.16b, v5.16b, v16.16b
	WORD $0x6e318484 // sub v4.16b, v4.16b, v17.16b
	WORD $0x6e3184a5 // sub v5.16b, v5.16b, v17.16b
	WORD $0x3ccc4086 // ldur q6, [x4, #196]
	WORD $0x3ccd4087 // ldur q7, [x4, #212]
	WORD $0x4e869494 // sdot v20.4s, v4.16b, v6.16b
	WORD $0x4e8794b4 // sdot v20.4s, v5.16b, v7.16b
	WORD $0x6f0a0444 // ushr v4.16b, v2.16b, #6
	WORD $0x6f0a0465 // ushr v5.16b, v3.16b, #6
	WORD $0x4e301c84 // and v4.16b, v4.16b, v16.16b
	WORD $0x4e301ca5 // and v5.16b, v5.16b, v16.16b
	WORD $0x6e318484 // sub v4.16b, v4.16b, v17.16b
	WORD $0x6e3184a5 // sub v5.16b, v5.16b, v17.16b
	WORD $0x3cce4086 // ldur q6, [x4, #228]
	WORD $0x3ccf4087 // ldur q7, [x4, #244]
	WORD $0x4e869494 // sdot v20.4s, v4.16b, v6.16b
	WORD $0x4e8794b4 // sdot v20.4s, v5.16b, v7.16b
	WORD $0x4eb1ba94 // addv s20, v20.4s
	WORD $0x4e21da94 // scvtf v20.4s, v20.4s
	WORD $0x7c440076 // ldur h22, [x3, #64]
	WORD $0xbc400097 // ldur s23, [x4, #0]
	WORD $0x1ee242d6 // fcvt s22, h22
	WORD $0x1e370ad6 // fmul s22, s22, s23
	WORD $0x4f961280 // fmla v0.4s, v20.4s, v22.s[0]
	ADD	$66, R3, R3
	ADD	$292, R4, R4
	SUBW	$1, R1, R1
	CBNZW	R1, tq2blk
tq2reduce:
	WORD $0x6e20d400 // faddp v0.4s, v0.4s, v0.4s
	WORD $0x7e30d800 // faddp s0, v0.2s
	FMOVS	F0, (R2)
	RET
tq2oob:
	B	ovr_oob
