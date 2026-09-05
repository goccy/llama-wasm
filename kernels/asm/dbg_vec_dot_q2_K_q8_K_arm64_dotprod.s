// dbg_vec_dot_q2_K_q8_K: q2_K x q8_K dot, SDOT per 16-quant sub-block with MLA-by-element scales.
	WORD $0x4f000400 // movi v0.4s, #0
	MOVW	l0+8(FP), R1
	LSRW	$8, R1, R1
	MOVD	l1+16(FP), R2
	ADD	$4, R2, R27
	CMP	R27, R21
	BLO	q2koob
	ADD	R20, R2, R2
	CBZW	R1, q2kzero
	MOVD	l3+32(FP), R3
	MOVD	l5+48(FP), R4
	MOVD	$84, R26
	MUL	R1, R26, R26
	ADD	R3, R26, R27
	CMP	R27, R21
	BLO	q2koob
	MOVD	$292, R26
	MUL	R1, R26, R26
	ADD	R4, R26, R27
	CMP	R27, R21
	BLO	q2koob
	ADD	R20, R3, R3
	ADD	R20, R4, R4
	WORD $0x4f00e5fe // movi v30.16b, #15
	WORD $0x4f00e47f // movi v31.16b, #3
q2kblk:
	WORD $0x3cc00062 // ldur q2, [x3, #0]
	WORD $0x4e3e1c44 // and v4.16b, v2.16b, v30.16b
	WORD $0x6f0c0445 // ushr v5.16b, v2.16b, #4
	WORD $0x2f08a486 // ushll v6.8h, v4.8b, #0
	WORD $0x6f08a487 // ushll2 v7.8h, v4.16b, #0
	WORD $0x2f10a4c8 // ushll v8.4s, v6.4h, #0
	WORD $0x6f10a4c9 // ushll2 v9.4s, v6.8h, #0
	WORD $0x2f10a4ea // ushll v10.4s, v7.4h, #0
	WORD $0x6f10a4eb // ushll2 v11.4s, v7.8h, #0
	WORD $0x2f08a4ac // ushll v12.8h, v5.8b, #0
	WORD $0x6f08a4ad // ushll2 v13.8h, v5.16b, #0
	ADD	$256, R4, R5
	WORD $0x3cc040ae // ldur q14, [x5, #4]
	WORD $0x3cc140af // ldur q15, [x5, #20]
	WORD $0x0e6cc1d0 // smull v16.4s, v14.4h, v12.4h
	WORD $0x4e6c81d0 // smlal2 v16.4s, v14.8h, v12.8h
	WORD $0x0e6d81f0 // smlal v16.4s, v15.4h, v13.4h
	WORD $0x4e6d81f0 // smlal2 v16.4s, v15.8h, v13.8h
	WORD $0xbc400091 // ldur s17, [x4, #0]
	WORD $0x7c452072 // ldur h18, [x3, #82]
	WORD $0x7c450073 // ldur h19, [x3, #80]
	WORD $0x1ee24252 // fcvt s18, h18
	WORD $0x1ee24273 // fcvt s19, h19
	WORD $0x1e310a52 // fmul s18, s18, s17
	WORD $0x1e310a73 // fmul s19, s19, s17
	WORD $0x4e21da10 // scvtf v16.4s, v16.4s
	WORD $0x4f925200 // fmls v0.4s, v16.4s, v18.s[0]
	WORD $0x4f000401 // movi v1.4s, #0
	WORD $0x3cc10074 // ldur q20, [x3, #16]
	WORD $0x3cc20075 // ldur q21, [x3, #32]
	WORD $0x3cc04096 // ldur q22, [x4, #4]
	WORD $0x3cc14097 // ldur q23, [x4, #20]
	WORD $0x4e3f1e9a // and v26.16b, v20.16b, v31.16b
	WORD $0x4e3f1ebb // and v27.16b, v21.16b, v31.16b
	WORD $0x4f00041c // movi v28.4s, #0
	WORD $0x4f00041d // movi v29.4s, #0
	WORD $0x4e96975c // sdot v28.4s, v26.16b, v22.16b
	WORD $0x4e97977d // sdot v29.4s, v27.16b, v23.16b
	WORD $0x6f880381 // mla v1.4s, v28.4s, v8.s[0]
	WORD $0x6fa803a1 // mla v1.4s, v29.4s, v8.s[1]
	WORD $0x3cc24096 // ldur q22, [x4, #36]
	WORD $0x3cc34097 // ldur q23, [x4, #52]
	WORD $0x6f0e069a // ushr v26.16b, v20.16b, #2
	WORD $0x6f0e06bb // ushr v27.16b, v21.16b, #2
	WORD $0x4e3f1f5a // and v26.16b, v26.16b, v31.16b
	WORD $0x4e3f1f7b // and v27.16b, v27.16b, v31.16b
	WORD $0x4f00041c // movi v28.4s, #0
	WORD $0x4f00041d // movi v29.4s, #0
	WORD $0x4e96975c // sdot v28.4s, v26.16b, v22.16b
	WORD $0x4e97977d // sdot v29.4s, v27.16b, v23.16b
	WORD $0x6f880b81 // mla v1.4s, v28.4s, v8.s[2]
	WORD $0x6fa80ba1 // mla v1.4s, v29.4s, v8.s[3]
	WORD $0x3cc44096 // ldur q22, [x4, #68]
	WORD $0x3cc54097 // ldur q23, [x4, #84]
	WORD $0x6f0c069a // ushr v26.16b, v20.16b, #4
	WORD $0x6f0c06bb // ushr v27.16b, v21.16b, #4
	WORD $0x4e3f1f5a // and v26.16b, v26.16b, v31.16b
	WORD $0x4e3f1f7b // and v27.16b, v27.16b, v31.16b
	WORD $0x4f00041c // movi v28.4s, #0
	WORD $0x4f00041d // movi v29.4s, #0
	WORD $0x4e96975c // sdot v28.4s, v26.16b, v22.16b
	WORD $0x4e97977d // sdot v29.4s, v27.16b, v23.16b
	WORD $0x6f890381 // mla v1.4s, v28.4s, v9.s[0]
	WORD $0x6fa903a1 // mla v1.4s, v29.4s, v9.s[1]
	WORD $0x3cc64096 // ldur q22, [x4, #100]
	WORD $0x3cc74097 // ldur q23, [x4, #116]
	WORD $0x6f0a069a // ushr v26.16b, v20.16b, #6
	WORD $0x6f0a06bb // ushr v27.16b, v21.16b, #6
	WORD $0x4e3f1f5a // and v26.16b, v26.16b, v31.16b
	WORD $0x4e3f1f7b // and v27.16b, v27.16b, v31.16b
	WORD $0x4f00041c // movi v28.4s, #0
	WORD $0x4f00041d // movi v29.4s, #0
	WORD $0x4e96975c // sdot v28.4s, v26.16b, v22.16b
	WORD $0x4e97977d // sdot v29.4s, v27.16b, v23.16b
	WORD $0x6f890b81 // mla v1.4s, v28.4s, v9.s[2]
	WORD $0x6fa90ba1 // mla v1.4s, v29.4s, v9.s[3]
	WORD $0x3cc30074 // ldur q20, [x3, #48]
	WORD $0x3cc40075 // ldur q21, [x3, #64]
	WORD $0x3cc84096 // ldur q22, [x4, #132]
	WORD $0x3cc94097 // ldur q23, [x4, #148]
	WORD $0x4e3f1e9a // and v26.16b, v20.16b, v31.16b
	WORD $0x4e3f1ebb // and v27.16b, v21.16b, v31.16b
	WORD $0x4f00041c // movi v28.4s, #0
	WORD $0x4f00041d // movi v29.4s, #0
	WORD $0x4e96975c // sdot v28.4s, v26.16b, v22.16b
	WORD $0x4e97977d // sdot v29.4s, v27.16b, v23.16b
	WORD $0x6f8a0381 // mla v1.4s, v28.4s, v10.s[0]
	WORD $0x6faa03a1 // mla v1.4s, v29.4s, v10.s[1]
	WORD $0x3cca4096 // ldur q22, [x4, #164]
	WORD $0x3ccb4097 // ldur q23, [x4, #180]
	WORD $0x6f0e069a // ushr v26.16b, v20.16b, #2
	WORD $0x6f0e06bb // ushr v27.16b, v21.16b, #2
	WORD $0x4e3f1f5a // and v26.16b, v26.16b, v31.16b
	WORD $0x4e3f1f7b // and v27.16b, v27.16b, v31.16b
	WORD $0x4f00041c // movi v28.4s, #0
	WORD $0x4f00041d // movi v29.4s, #0
	WORD $0x4e96975c // sdot v28.4s, v26.16b, v22.16b
	WORD $0x4e97977d // sdot v29.4s, v27.16b, v23.16b
	WORD $0x6f8a0b81 // mla v1.4s, v28.4s, v10.s[2]
	WORD $0x6faa0ba1 // mla v1.4s, v29.4s, v10.s[3]
	WORD $0x3ccc4096 // ldur q22, [x4, #196]
	WORD $0x3ccd4097 // ldur q23, [x4, #212]
	WORD $0x6f0c069a // ushr v26.16b, v20.16b, #4
	WORD $0x6f0c06bb // ushr v27.16b, v21.16b, #4
	WORD $0x4e3f1f5a // and v26.16b, v26.16b, v31.16b
	WORD $0x4e3f1f7b // and v27.16b, v27.16b, v31.16b
	WORD $0x4f00041c // movi v28.4s, #0
	WORD $0x4f00041d // movi v29.4s, #0
	WORD $0x4e96975c // sdot v28.4s, v26.16b, v22.16b
	WORD $0x4e97977d // sdot v29.4s, v27.16b, v23.16b
	WORD $0x6f8b0381 // mla v1.4s, v28.4s, v11.s[0]
	WORD $0x6fab03a1 // mla v1.4s, v29.4s, v11.s[1]
	WORD $0x3cce4096 // ldur q22, [x4, #228]
	WORD $0x3ccf4097 // ldur q23, [x4, #244]
	WORD $0x6f0a069a // ushr v26.16b, v20.16b, #6
	WORD $0x6f0a06bb // ushr v27.16b, v21.16b, #6
	WORD $0x4e3f1f5a // and v26.16b, v26.16b, v31.16b
	WORD $0x4e3f1f7b // and v27.16b, v27.16b, v31.16b
	WORD $0x4f00041c // movi v28.4s, #0
	WORD $0x4f00041d // movi v29.4s, #0
	WORD $0x4e96975c // sdot v28.4s, v26.16b, v22.16b
	WORD $0x4e97977d // sdot v29.4s, v27.16b, v23.16b
	WORD $0x6f8b0b81 // mla v1.4s, v28.4s, v11.s[2]
	WORD $0x6fab0ba1 // mla v1.4s, v29.4s, v11.s[3]
	WORD $0x4e21d821 // scvtf v1.4s, v1.4s
	WORD $0x4f931020 // fmla v0.4s, v1.4s, v19.s[0]
	ADD	$84, R3, R3
	ADD	$292, R4, R4
	SUBW	$1, R1, R1
	CBNZW	R1, q2kblk
q2kzero:
	WORD $0x6e20d400 // faddp v0.4s, v0.4s, v0.4s
	WORD $0x7e30d800 // faddp s0, v0.2s
	FMOVS	F0, (R2)
	RET
q2koob:
	B	ovr_oob
