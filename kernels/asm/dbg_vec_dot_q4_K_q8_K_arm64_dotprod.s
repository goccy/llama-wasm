// dbg_vec_dot_q4_K_q8_K: q4_K x q8_K dot, SDOT per sub-block with MLA-by-element scales; 2x2 tile for nrc == 2.
	WORD $0x4f000400 // movi v0.4s, #0
	MOVW	l0+8(FP), R1
	LSRW	$8, R1, R1
	MOVW	l7+64(FP), R6
	MOVD	l1+16(FP), R2
	MOVD	l3+32(FP), R3
	MOVD	l5+48(FP), R4
	CMPW	$2, R6
	BEQ	q4ktile_tilepro
	ADD	$4, R2, R27
	CMP	R27, R21
	BLO	q4koob
	ADD	R20, R2, R2
	CBZW	R1, q4kzero
	MOVD	$144, R26
	MUL	R1, R26, R26
	ADD	R3, R26, R27
	CMP	R27, R21
	BLO	q4koob
	MOVD	$292, R26
	MUL	R1, R26, R26
	ADD	R4, R26, R27
	CMP	R27, R21
	BLO	q4koob
	ADD	R20, R3, R3
	ADD	R20, R4, R4
	B	q4ktile_body
q4ktile_tilepro:
	MOVD	l2+24(FP), R8
	LSL	$2, R8, R8
	ADD	R2, R8, R8
	ADD	$8, R8, R27
	CMP	R27, R21
	BLO	q4koob
	MOVD	l4+40(FP), R5
	ADD	R3, R5, R5
	MOVD	l6+56(FP), R7
	ADD	R4, R7, R7
	MOVD	$144, R26
	MUL	R1, R26, R26
	ADD	R5, R26, R27
	CMP	R27, R21
	BLO	q4koob
	MOVD	$292, R26
	MUL	R1, R26, R26
	ADD	R7, R26, R27
	CMP	R27, R21
	BLO	q4koob
	ADD	R20, R2, R2
	ADD	R20, R8, R8
	ADD	R20, R3, R3
	ADD	R20, R4, R4
	ADD	R20, R5, R5
	ADD	R20, R7, R7
	CBZW	R1, q4kzero
	B	q4ktile
q4ktile_body:
	WORD $0x4f00e5f0 // movi v16.16b, #15
q4kblk:
	MOVWU	4(R3), R9
	MOVWU	8(R3), R10
	MOVWU	12(R3), R11
	ANDW	$0x3f3f3f3f, R10, R12
	LSRW	$4, R11, R13
	ANDW	$0x0f0f0f0f, R13, R13
	LSRW	$6, R10, R10
	ANDW	$0x03030303, R10, R10
	ORRW	R10<<4, R13, R13
	ORR	R13<<32, R12, R12
	WORD $0x9e670186 // fmov d6, x12
	ANDW	$0x3f3f3f3f, R9, R12
	ANDW	$0x0f0f0f0f, R11, R13
	LSRW	$6, R9, R10
	ANDW	$0x03030303, R10, R10
	ORRW	R10<<4, R13, R13
	ORR	R13<<32, R12, R12
	WORD $0x9e670182 // fmov d2, x12
	WORD $0x2f08a443 // ushll v3.8h, v2.8b, #0
	WORD $0x2f10a464 // ushll v4.4s, v3.4h, #0
	WORD $0x6f10a465 // ushll2 v5.4s, v3.8h, #0
	ADD	$256, R4, R5
	WORD $0x3cc040a7 // ldur q7, [x5, #4]
	WORD $0x3cc140a8 // ldur q8, [x5, #20]
	WORD $0x4e68bce9 // addp v9.8h, v7.8h, v8.8h
	WORD $0x2f08a4c6 // ushll v6.8h, v6.8b, #0
	WORD $0x0e66c12a // smull v10.4s, v9.4h, v6.4h
	WORD $0x4e66812a // smlal2 v10.4s, v9.8h, v6.8h
	WORD $0xbc40008b // ldur s11, [x4, #0]
	WORD $0x7c40206c // ldur h12, [x3, #2]
	WORD $0x7c40006d // ldur h13, [x3, #0]
	WORD $0x1ee2418c // fcvt s12, h12
	WORD $0x1ee241ad // fcvt s13, h13
	WORD $0x1e2b098c // fmul s12, s12, s11
	WORD $0x1e2b09ad // fmul s13, s13, s11
	WORD $0x4e21d94a // scvtf v10.4s, v10.4s
	WORD $0x4f8c5140 // fmls v0.4s, v10.4s, v12.s[0]
	WORD $0x4f000401 // movi v1.4s, #0
	WORD $0x3cc10074 // ldur q20, [x3, #16]
	WORD $0x3cc20075 // ldur q21, [x3, #32]
	WORD $0x3cc04096 // ldur q22, [x4, #4]
	WORD $0x3cc14097 // ldur q23, [x4, #20]
	WORD $0x3cc24098 // ldur q24, [x4, #36]
	WORD $0x3cc34099 // ldur q25, [x4, #52]
	WORD $0x4e301e9a // and v26.16b, v20.16b, v16.16b
	WORD $0x4e301ebb // and v27.16b, v21.16b, v16.16b
	WORD $0x6f0c069c // ushr v28.16b, v20.16b, #4
	WORD $0x6f0c06bd // ushr v29.16b, v21.16b, #4
	WORD $0x4f00041e // movi v30.4s, #0
	WORD $0x4f00041f // movi v31.4s, #0
	WORD $0x4e96975e // sdot v30.4s, v26.16b, v22.16b
	WORD $0x4e97977e // sdot v30.4s, v27.16b, v23.16b
	WORD $0x4e98979f // sdot v31.4s, v28.16b, v24.16b
	WORD $0x4e9997bf // sdot v31.4s, v29.16b, v25.16b
	WORD $0x6f8403c1 // mla v1.4s, v30.4s, v4.s[0]
	WORD $0x6fa403e1 // mla v1.4s, v31.4s, v4.s[1]
	WORD $0x3cc30074 // ldur q20, [x3, #48]
	WORD $0x3cc40075 // ldur q21, [x3, #64]
	WORD $0x3cc44096 // ldur q22, [x4, #68]
	WORD $0x3cc54097 // ldur q23, [x4, #84]
	WORD $0x3cc64098 // ldur q24, [x4, #100]
	WORD $0x3cc74099 // ldur q25, [x4, #116]
	WORD $0x4e301e9a // and v26.16b, v20.16b, v16.16b
	WORD $0x4e301ebb // and v27.16b, v21.16b, v16.16b
	WORD $0x6f0c069c // ushr v28.16b, v20.16b, #4
	WORD $0x6f0c06bd // ushr v29.16b, v21.16b, #4
	WORD $0x4f00041e // movi v30.4s, #0
	WORD $0x4f00041f // movi v31.4s, #0
	WORD $0x4e96975e // sdot v30.4s, v26.16b, v22.16b
	WORD $0x4e97977e // sdot v30.4s, v27.16b, v23.16b
	WORD $0x4e98979f // sdot v31.4s, v28.16b, v24.16b
	WORD $0x4e9997bf // sdot v31.4s, v29.16b, v25.16b
	WORD $0x6f840bc1 // mla v1.4s, v30.4s, v4.s[2]
	WORD $0x6fa40be1 // mla v1.4s, v31.4s, v4.s[3]
	WORD $0x3cc50074 // ldur q20, [x3, #80]
	WORD $0x3cc60075 // ldur q21, [x3, #96]
	WORD $0x3cc84096 // ldur q22, [x4, #132]
	WORD $0x3cc94097 // ldur q23, [x4, #148]
	WORD $0x3cca4098 // ldur q24, [x4, #164]
	WORD $0x3ccb4099 // ldur q25, [x4, #180]
	WORD $0x4e301e9a // and v26.16b, v20.16b, v16.16b
	WORD $0x4e301ebb // and v27.16b, v21.16b, v16.16b
	WORD $0x6f0c069c // ushr v28.16b, v20.16b, #4
	WORD $0x6f0c06bd // ushr v29.16b, v21.16b, #4
	WORD $0x4f00041e // movi v30.4s, #0
	WORD $0x4f00041f // movi v31.4s, #0
	WORD $0x4e96975e // sdot v30.4s, v26.16b, v22.16b
	WORD $0x4e97977e // sdot v30.4s, v27.16b, v23.16b
	WORD $0x4e98979f // sdot v31.4s, v28.16b, v24.16b
	WORD $0x4e9997bf // sdot v31.4s, v29.16b, v25.16b
	WORD $0x6f8503c1 // mla v1.4s, v30.4s, v5.s[0]
	WORD $0x6fa503e1 // mla v1.4s, v31.4s, v5.s[1]
	WORD $0x3cc70074 // ldur q20, [x3, #112]
	WORD $0x3cc80075 // ldur q21, [x3, #128]
	WORD $0x3ccc4096 // ldur q22, [x4, #196]
	WORD $0x3ccd4097 // ldur q23, [x4, #212]
	WORD $0x3cce4098 // ldur q24, [x4, #228]
	WORD $0x3ccf4099 // ldur q25, [x4, #244]
	WORD $0x4e301e9a // and v26.16b, v20.16b, v16.16b
	WORD $0x4e301ebb // and v27.16b, v21.16b, v16.16b
	WORD $0x6f0c069c // ushr v28.16b, v20.16b, #4
	WORD $0x6f0c06bd // ushr v29.16b, v21.16b, #4
	WORD $0x4f00041e // movi v30.4s, #0
	WORD $0x4f00041f // movi v31.4s, #0
	WORD $0x4e96975e // sdot v30.4s, v26.16b, v22.16b
	WORD $0x4e97977e // sdot v30.4s, v27.16b, v23.16b
	WORD $0x4e98979f // sdot v31.4s, v28.16b, v24.16b
	WORD $0x4e9997bf // sdot v31.4s, v29.16b, v25.16b
	WORD $0x6f850bc1 // mla v1.4s, v30.4s, v5.s[2]
	WORD $0x6fa50be1 // mla v1.4s, v31.4s, v5.s[3]
	WORD $0x4e21d821 // scvtf v1.4s, v1.4s
	WORD $0x4f8d1020 // fmla v0.4s, v1.4s, v13.s[0]
	ADD	$144, R3, R3
	ADD	$292, R4, R4
	SUBW	$1, R1, R1
	CBNZW	R1, q4kblk
q4kzero:
	CMPW	$2, R6
	BEQ	q4ktilestore
	WORD $0x6e20d400 // faddp v0.4s, v0.4s, v0.4s
	WORD $0x7e30d800 // faddp s0, v0.2s
	FMOVS	F0, (R2)
	RET
q4ktile:
	WORD $0x4f00e5f0 // movi v16.16b, #15
q4ktileblk:
	MOVWU	4(R3), R9
	MOVWU	8(R3), R10
	MOVWU	12(R3), R11
	ANDW	$0x3f3f3f3f, R10, R12
	LSRW	$4, R11, R13
	ANDW	$0x0f0f0f0f, R13, R13
	LSRW	$6, R10, R10
	ANDW	$0x03030303, R10, R10
	ORRW	R10<<4, R13, R13
	ORR	R13<<32, R12, R12
	WORD $0x9e670189 // fmov d9, x12
	ANDW	$0x3f3f3f3f, R9, R12
	ANDW	$0x0f0f0f0f, R11, R13
	LSRW	$6, R9, R10
	ANDW	$0x03030303, R10, R10
	ORRW	R10<<4, R13, R13
	ORR	R13<<32, R12, R12
	WORD $0x9e670185 // fmov d5, x12
	MOVWU	4(R5), R9
	MOVWU	8(R5), R10
	MOVWU	12(R5), R11
	ANDW	$0x3f3f3f3f, R10, R12
	LSRW	$4, R11, R13
	ANDW	$0x0f0f0f0f, R13, R13
	LSRW	$6, R10, R10
	ANDW	$0x03030303, R10, R10
	ORRW	R10<<4, R13, R13
	ORR	R13<<32, R12, R12
	WORD $0x9e67018a // fmov d10, x12
	ANDW	$0x3f3f3f3f, R9, R12
	ANDW	$0x0f0f0f0f, R11, R13
	LSRW	$6, R9, R10
	ANDW	$0x03030303, R10, R10
	ORRW	R10<<4, R13, R13
	ORR	R13<<32, R12, R12
	WORD $0x9e670187 // fmov d7, x12
	WORD $0x2f08a4a5 // ushll v5.8h, v5.8b, #0
	WORD $0x6f10a4a6 // ushll2 v6.4s, v5.8h, #0
	WORD $0x2f10a4a5 // ushll v5.4s, v5.4h, #0
	WORD $0x2f08a4e7 // ushll v7.8h, v7.8b, #0
	WORD $0x6f10a4e8 // ushll2 v8.4s, v7.8h, #0
	WORD $0x2f10a4e7 // ushll v7.4s, v7.4h, #0
	WORD $0x2f08a529 // ushll v9.8h, v9.8b, #0
	WORD $0x2f08a54a // ushll v10.8h, v10.8b, #0
	ADD	$256, R4, R9
	WORD $0x3cc0412d // ldur q13, [x9, #4]
	WORD $0x3cc1412e // ldur q14, [x9, #20]
	WORD $0x4e6ebdab // addp v11.8h, v13.8h, v14.8h
	ADD	$256, R7, R9
	WORD $0x3cc0412d // ldur q13, [x9, #4]
	WORD $0x3cc1412e // ldur q14, [x9, #20]
	WORD $0x4e6ebdac // addp v12.8h, v13.8h, v14.8h
	WORD $0x0e69c16d // smull v13.4s, v11.4h, v9.4h
	WORD $0x4e69816d // smlal2 v13.4s, v11.8h, v9.8h
	WORD $0x0e6ac16e // smull v14.4s, v11.4h, v10.4h
	WORD $0x4e6a816e // smlal2 v14.4s, v11.8h, v10.8h
	WORD $0x4eb1b9ad // addv s13, v13.4s
	WORD $0x4eb1b9ce // addv s14, v14.4s
	WORD $0x6e0c05cd // mov v13.s[1], v14.s[0]
	WORD $0x0e69c18e // smull v14.4s, v12.4h, v9.4h
	WORD $0x4e69818e // smlal2 v14.4s, v12.8h, v9.8h
	WORD $0x4eb1b9ce // addv s14, v14.4s
	WORD $0x6e1405cd // mov v13.s[2], v14.s[0]
	WORD $0x0e6ac18e // smull v14.4s, v12.4h, v10.4h
	WORD $0x4e6a818e // smlal2 v14.4s, v12.8h, v10.8h
	WORD $0x4eb1b9ce // addv s14, v14.4s
	WORD $0x6e1c05cd // mov v13.s[3], v14.s[0]
	WORD $0xbc40008b // ldur s11, [x4, #0]
	WORD $0xbc4000ec // ldur s12, [x7, #0]
	WORD $0x6e0c058b // mov v11.s[1], v12.s[0]
	WORD $0x4e8b396b // zip1 v11.4s, v11.4s, v11.4s
	WORD $0x7c400069 // ldur h9, [x3, #0]
	WORD $0x7c4000ac // ldur h12, [x5, #0]
	WORD $0x1ee24129 // fcvt s9, h9
	WORD $0x1ee2418c // fcvt s12, h12
	WORD $0x6e0c0589 // mov v9.s[1], v12.s[0]
	WORD $0x4e080529 // dup v9.2d, v9.d[0]
	WORD $0x6e2bdd29 // fmul v9.4s, v9.4s, v11.4s
	WORD $0x7c40206a // ldur h10, [x3, #2]
	WORD $0x7c4020ac // ldur h12, [x5, #2]
	WORD $0x1ee2414a // fcvt s10, h10
	WORD $0x1ee2418c // fcvt s12, h12
	WORD $0x6e0c058a // mov v10.s[1], v12.s[0]
	WORD $0x4e08054a // dup v10.2d, v10.d[0]
	WORD $0x6e2bdd4a // fmul v10.4s, v10.4s, v11.4s
	WORD $0x4e21d9ad // scvtf v13.4s, v13.4s
	WORD $0x4eaacda0 // fmls v0.4s, v13.4s, v10.4s
	WORD $0x4f000401 // movi v1.4s, #0
	WORD $0x4f000402 // movi v2.4s, #0
	WORD $0x4f000403 // movi v3.4s, #0
	WORD $0x4f000404 // movi v4.4s, #0
	WORD $0x3cc10071 // ldur q17, [x3, #16]
	WORD $0x3cc20072 // ldur q18, [x3, #32]
	WORD $0x3cc100b5 // ldur q21, [x5, #16]
	WORD $0x3cc200b6 // ldur q22, [x5, #32]
	WORD $0x4e301e33 // and v19.16b, v17.16b, v16.16b
	WORD $0x4e301e54 // and v20.16b, v18.16b, v16.16b
	WORD $0x6f0c0631 // ushr v17.16b, v17.16b, #4
	WORD $0x6f0c0652 // ushr v18.16b, v18.16b, #4
	WORD $0x4e301eb7 // and v23.16b, v21.16b, v16.16b
	WORD $0x4e301ed8 // and v24.16b, v22.16b, v16.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x6f0c06d6 // ushr v22.16b, v22.16b, #4
	WORD $0x3cc04099 // ldur q25, [x4, #4]
	WORD $0x3cc1409a // ldur q26, [x4, #20]
	WORD $0x3cc2409b // ldur q27, [x4, #36]
	WORD $0x3cc3409c // ldur q28, [x4, #52]
	WORD $0x3cc040fd // ldur q29, [x7, #4]
	WORD $0x3cc140fe // ldur q30, [x7, #20]
	WORD $0x3cc240ff // ldur q31, [x7, #36]
	WORD $0x3cc340ef // ldur q15, [x7, #52]
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e99966d // sdot v13.4s, v19.16b, v25.16b
	WORD $0x4e9a968d // sdot v13.4s, v20.16b, v26.16b
	WORD $0x6f8501a1 // mla v1.4s, v13.4s, v5.s[0]
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e9996ed // sdot v13.4s, v23.16b, v25.16b
	WORD $0x4e9a970d // sdot v13.4s, v24.16b, v26.16b
	WORD $0x6f8701a2 // mla v2.4s, v13.4s, v7.s[0]
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e9d966d // sdot v13.4s, v19.16b, v29.16b
	WORD $0x4e9e968d // sdot v13.4s, v20.16b, v30.16b
	WORD $0x6f8501a3 // mla v3.4s, v13.4s, v5.s[0]
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e9d96ed // sdot v13.4s, v23.16b, v29.16b
	WORD $0x4e9e970d // sdot v13.4s, v24.16b, v30.16b
	WORD $0x6f8701a4 // mla v4.4s, v13.4s, v7.s[0]
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e9b962d // sdot v13.4s, v17.16b, v27.16b
	WORD $0x4e9c964d // sdot v13.4s, v18.16b, v28.16b
	WORD $0x6fa501a1 // mla v1.4s, v13.4s, v5.s[1]
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e9b96ad // sdot v13.4s, v21.16b, v27.16b
	WORD $0x4e9c96cd // sdot v13.4s, v22.16b, v28.16b
	WORD $0x6fa701a2 // mla v2.4s, v13.4s, v7.s[1]
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e9f962d // sdot v13.4s, v17.16b, v31.16b
	WORD $0x4e8f964d // sdot v13.4s, v18.16b, v15.16b
	WORD $0x6fa501a3 // mla v3.4s, v13.4s, v5.s[1]
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e9f96ad // sdot v13.4s, v21.16b, v31.16b
	WORD $0x4e8f96cd // sdot v13.4s, v22.16b, v15.16b
	WORD $0x6fa701a4 // mla v4.4s, v13.4s, v7.s[1]
	WORD $0x3cc30071 // ldur q17, [x3, #48]
	WORD $0x3cc40072 // ldur q18, [x3, #64]
	WORD $0x3cc300b5 // ldur q21, [x5, #48]
	WORD $0x3cc400b6 // ldur q22, [x5, #64]
	WORD $0x4e301e33 // and v19.16b, v17.16b, v16.16b
	WORD $0x4e301e54 // and v20.16b, v18.16b, v16.16b
	WORD $0x6f0c0631 // ushr v17.16b, v17.16b, #4
	WORD $0x6f0c0652 // ushr v18.16b, v18.16b, #4
	WORD $0x4e301eb7 // and v23.16b, v21.16b, v16.16b
	WORD $0x4e301ed8 // and v24.16b, v22.16b, v16.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x6f0c06d6 // ushr v22.16b, v22.16b, #4
	WORD $0x3cc44099 // ldur q25, [x4, #68]
	WORD $0x3cc5409a // ldur q26, [x4, #84]
	WORD $0x3cc6409b // ldur q27, [x4, #100]
	WORD $0x3cc7409c // ldur q28, [x4, #116]
	WORD $0x3cc440fd // ldur q29, [x7, #68]
	WORD $0x3cc540fe // ldur q30, [x7, #84]
	WORD $0x3cc640ff // ldur q31, [x7, #100]
	WORD $0x3cc740ef // ldur q15, [x7, #116]
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e99966d // sdot v13.4s, v19.16b, v25.16b
	WORD $0x4e9a968d // sdot v13.4s, v20.16b, v26.16b
	WORD $0x6f8509a1 // mla v1.4s, v13.4s, v5.s[2]
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e9996ed // sdot v13.4s, v23.16b, v25.16b
	WORD $0x4e9a970d // sdot v13.4s, v24.16b, v26.16b
	WORD $0x6f8709a2 // mla v2.4s, v13.4s, v7.s[2]
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e9d966d // sdot v13.4s, v19.16b, v29.16b
	WORD $0x4e9e968d // sdot v13.4s, v20.16b, v30.16b
	WORD $0x6f8509a3 // mla v3.4s, v13.4s, v5.s[2]
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e9d96ed // sdot v13.4s, v23.16b, v29.16b
	WORD $0x4e9e970d // sdot v13.4s, v24.16b, v30.16b
	WORD $0x6f8709a4 // mla v4.4s, v13.4s, v7.s[2]
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e9b962d // sdot v13.4s, v17.16b, v27.16b
	WORD $0x4e9c964d // sdot v13.4s, v18.16b, v28.16b
	WORD $0x6fa509a1 // mla v1.4s, v13.4s, v5.s[3]
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e9b96ad // sdot v13.4s, v21.16b, v27.16b
	WORD $0x4e9c96cd // sdot v13.4s, v22.16b, v28.16b
	WORD $0x6fa709a2 // mla v2.4s, v13.4s, v7.s[3]
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e9f962d // sdot v13.4s, v17.16b, v31.16b
	WORD $0x4e8f964d // sdot v13.4s, v18.16b, v15.16b
	WORD $0x6fa509a3 // mla v3.4s, v13.4s, v5.s[3]
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e9f96ad // sdot v13.4s, v21.16b, v31.16b
	WORD $0x4e8f96cd // sdot v13.4s, v22.16b, v15.16b
	WORD $0x6fa709a4 // mla v4.4s, v13.4s, v7.s[3]
	WORD $0x3cc50071 // ldur q17, [x3, #80]
	WORD $0x3cc60072 // ldur q18, [x3, #96]
	WORD $0x3cc500b5 // ldur q21, [x5, #80]
	WORD $0x3cc600b6 // ldur q22, [x5, #96]
	WORD $0x4e301e33 // and v19.16b, v17.16b, v16.16b
	WORD $0x4e301e54 // and v20.16b, v18.16b, v16.16b
	WORD $0x6f0c0631 // ushr v17.16b, v17.16b, #4
	WORD $0x6f0c0652 // ushr v18.16b, v18.16b, #4
	WORD $0x4e301eb7 // and v23.16b, v21.16b, v16.16b
	WORD $0x4e301ed8 // and v24.16b, v22.16b, v16.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x6f0c06d6 // ushr v22.16b, v22.16b, #4
	WORD $0x3cc84099 // ldur q25, [x4, #132]
	WORD $0x3cc9409a // ldur q26, [x4, #148]
	WORD $0x3cca409b // ldur q27, [x4, #164]
	WORD $0x3ccb409c // ldur q28, [x4, #180]
	WORD $0x3cc840fd // ldur q29, [x7, #132]
	WORD $0x3cc940fe // ldur q30, [x7, #148]
	WORD $0x3cca40ff // ldur q31, [x7, #164]
	WORD $0x3ccb40ef // ldur q15, [x7, #180]
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e99966d // sdot v13.4s, v19.16b, v25.16b
	WORD $0x4e9a968d // sdot v13.4s, v20.16b, v26.16b
	WORD $0x6f8601a1 // mla v1.4s, v13.4s, v6.s[0]
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e9996ed // sdot v13.4s, v23.16b, v25.16b
	WORD $0x4e9a970d // sdot v13.4s, v24.16b, v26.16b
	WORD $0x6f8801a2 // mla v2.4s, v13.4s, v8.s[0]
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e9d966d // sdot v13.4s, v19.16b, v29.16b
	WORD $0x4e9e968d // sdot v13.4s, v20.16b, v30.16b
	WORD $0x6f8601a3 // mla v3.4s, v13.4s, v6.s[0]
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e9d96ed // sdot v13.4s, v23.16b, v29.16b
	WORD $0x4e9e970d // sdot v13.4s, v24.16b, v30.16b
	WORD $0x6f8801a4 // mla v4.4s, v13.4s, v8.s[0]
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e9b962d // sdot v13.4s, v17.16b, v27.16b
	WORD $0x4e9c964d // sdot v13.4s, v18.16b, v28.16b
	WORD $0x6fa601a1 // mla v1.4s, v13.4s, v6.s[1]
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e9b96ad // sdot v13.4s, v21.16b, v27.16b
	WORD $0x4e9c96cd // sdot v13.4s, v22.16b, v28.16b
	WORD $0x6fa801a2 // mla v2.4s, v13.4s, v8.s[1]
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e9f962d // sdot v13.4s, v17.16b, v31.16b
	WORD $0x4e8f964d // sdot v13.4s, v18.16b, v15.16b
	WORD $0x6fa601a3 // mla v3.4s, v13.4s, v6.s[1]
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e9f96ad // sdot v13.4s, v21.16b, v31.16b
	WORD $0x4e8f96cd // sdot v13.4s, v22.16b, v15.16b
	WORD $0x6fa801a4 // mla v4.4s, v13.4s, v8.s[1]
	WORD $0x3cc70071 // ldur q17, [x3, #112]
	WORD $0x3cc80072 // ldur q18, [x3, #128]
	WORD $0x3cc700b5 // ldur q21, [x5, #112]
	WORD $0x3cc800b6 // ldur q22, [x5, #128]
	WORD $0x4e301e33 // and v19.16b, v17.16b, v16.16b
	WORD $0x4e301e54 // and v20.16b, v18.16b, v16.16b
	WORD $0x6f0c0631 // ushr v17.16b, v17.16b, #4
	WORD $0x6f0c0652 // ushr v18.16b, v18.16b, #4
	WORD $0x4e301eb7 // and v23.16b, v21.16b, v16.16b
	WORD $0x4e301ed8 // and v24.16b, v22.16b, v16.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x6f0c06d6 // ushr v22.16b, v22.16b, #4
	WORD $0x3ccc4099 // ldur q25, [x4, #196]
	WORD $0x3ccd409a // ldur q26, [x4, #212]
	WORD $0x3cce409b // ldur q27, [x4, #228]
	WORD $0x3ccf409c // ldur q28, [x4, #244]
	WORD $0x3ccc40fd // ldur q29, [x7, #196]
	WORD $0x3ccd40fe // ldur q30, [x7, #212]
	WORD $0x3cce40ff // ldur q31, [x7, #228]
	WORD $0x3ccf40ef // ldur q15, [x7, #244]
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e99966d // sdot v13.4s, v19.16b, v25.16b
	WORD $0x4e9a968d // sdot v13.4s, v20.16b, v26.16b
	WORD $0x6f8609a1 // mla v1.4s, v13.4s, v6.s[2]
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e9996ed // sdot v13.4s, v23.16b, v25.16b
	WORD $0x4e9a970d // sdot v13.4s, v24.16b, v26.16b
	WORD $0x6f8809a2 // mla v2.4s, v13.4s, v8.s[2]
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e9d966d // sdot v13.4s, v19.16b, v29.16b
	WORD $0x4e9e968d // sdot v13.4s, v20.16b, v30.16b
	WORD $0x6f8609a3 // mla v3.4s, v13.4s, v6.s[2]
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e9d96ed // sdot v13.4s, v23.16b, v29.16b
	WORD $0x4e9e970d // sdot v13.4s, v24.16b, v30.16b
	WORD $0x6f8809a4 // mla v4.4s, v13.4s, v8.s[2]
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e9b962d // sdot v13.4s, v17.16b, v27.16b
	WORD $0x4e9c964d // sdot v13.4s, v18.16b, v28.16b
	WORD $0x6fa609a1 // mla v1.4s, v13.4s, v6.s[3]
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e9b96ad // sdot v13.4s, v21.16b, v27.16b
	WORD $0x4e9c96cd // sdot v13.4s, v22.16b, v28.16b
	WORD $0x6fa809a2 // mla v2.4s, v13.4s, v8.s[3]
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e9f962d // sdot v13.4s, v17.16b, v31.16b
	WORD $0x4e8f964d // sdot v13.4s, v18.16b, v15.16b
	WORD $0x6fa609a3 // mla v3.4s, v13.4s, v6.s[3]
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e9f96ad // sdot v13.4s, v21.16b, v31.16b
	WORD $0x4e8f96cd // sdot v13.4s, v22.16b, v15.16b
	WORD $0x6fa809a4 // mla v4.4s, v13.4s, v8.s[3]
	WORD $0x4eb1b821 // addv s1, v1.4s
	WORD $0x4eb1b842 // addv s2, v2.4s
	WORD $0x4eb1b863 // addv s3, v3.4s
	WORD $0x4eb1b884 // addv s4, v4.4s
	WORD $0x6e0c0441 // mov v1.s[1], v2.s[0]
	WORD $0x6e140461 // mov v1.s[2], v3.s[0]
	WORD $0x6e1c0481 // mov v1.s[3], v4.s[0]
	WORD $0x4e21d821 // scvtf v1.4s, v1.4s
	WORD $0x4e29cc20 // fmla v0.4s, v1.4s, v9.4s
	ADD	$144, R3, R3
	ADD	$144, R5, R5
	ADD	$292, R4, R4
	ADD	$292, R7, R7
	SUBW	$1, R1, R1
	CBNZW	R1, q4ktileblk
q4ktilestore:
	WORD $0xfc000040 // stur d0, [x2, #0]
	WORD $0x5e180400 // mov d0, v0.d[1]
	WORD $0xfc000100 // stur d0, [x8, #0]
	RET
q4koob:
	B	ovr_oob
