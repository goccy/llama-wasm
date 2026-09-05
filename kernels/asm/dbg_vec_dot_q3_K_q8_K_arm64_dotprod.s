// dbg_vec_dot_q3_K_q8_K: q3_K x q8_K dot, SDOT per 16-quant sub-block on unsigned rebuilt quants, -4 through the block sums.
	WORD $0x4f000400 // movi v0.4s, #0
	MOVW	l0+8(FP), R1
	LSRW	$8, R1, R1
	MOVD	l1+16(FP), R2
	ADD	$4, R2, R27
	CMP	R27, R21
	BLO	q3koob
	ADD	R20, R2, R2
	CBZW	R1, q3kzero
	MOVD	l3+32(FP), R3
	MOVD	l5+48(FP), R4
	MOVD	$110, R26
	MUL	R1, R26, R26
	ADD	R3, R26, R27
	CMP	R27, R21
	BLO	q3koob
	MOVD	$292, R26
	MUL	R1, R26, R26
	ADD	R4, R26, R27
	CMP	R27, R21
	BLO	q3koob
	ADD	R20, R3, R3
	ADD	R20, R4, R4
	WORD $0x4f00e47d // movi v29.16b, #3
	WORD $0x4f00e43e // movi v30.16b, #1
	WORD $0x4f01e41f // movi v31.16b, #32
q3kblk:
	MOVWU	96(R3), R13
	MOVWU	100(R3), R14
	MOVWU	104(R3), R15
	ANDW	$0x0f0f0f0f, R13, R19
	ANDW	$0x03030303, R15, R22
	ORRW	R22<<4, R19, R19
	ANDW	$0x0f0f0f0f, R14, R22
	LSRW	$2, R15, R26
	ANDW	$0x03030303, R26, R26
	ORRW	R26<<4, R22, R22
	ORR	R22<<32, R19, R19
	WORD $0x9e670262 // fmov d2, x19
	LSRW	$4, R13, R19
	ANDW	$0x0f0f0f0f, R19, R19
	LSRW	$4, R15, R22
	ANDW	$0x03030303, R22, R22
	ORRW	R22<<4, R19, R19
	LSRW	$4, R14, R22
	ANDW	$0x0f0f0f0f, R22, R22
	LSRW	$6, R15, R26
	ANDW	$0x03030303, R26, R26
	ORRW	R26<<4, R22, R22
	ORR	R22<<32, R19, R19
	WORD $0x9e670263 // fmov d3, x19
	WORD $0x6e3f8442 // sub v2.16b, v2.16b, v31.16b
	WORD $0x6e3f8463 // sub v3.16b, v3.16b, v31.16b
	WORD $0x0f08a442 // sshll v2.8h, v2.8b, #0
	WORD $0x0f08a463 // sshll v3.8h, v3.8b, #0
	WORD $0x0f10a448 // sshll v8.4s, v2.4h, #0
	WORD $0x4f10a449 // sshll2 v9.4s, v2.8h, #0
	WORD $0x0f10a46a // sshll v10.4s, v3.4h, #0
	WORD $0x4f10a46b // sshll2 v11.4s, v3.8h, #0
	ADD	$256, R4, R5
	WORD $0x3cc040ae // ldur q14, [x5, #4]
	WORD $0x3cc140af // ldur q15, [x5, #20]
	WORD $0x0e62c1d0 // smull v16.4s, v14.4h, v2.4h
	WORD $0x4e6281d0 // smlal2 v16.4s, v14.8h, v2.8h
	WORD $0x0e6381f0 // smlal v16.4s, v15.4h, v3.4h
	WORD $0x4e6381f0 // smlal2 v16.4s, v15.8h, v3.8h
	WORD $0x4f225610 // shl v16.4s, v16.4s, #2
	WORD $0x3cc00072 // ldur q18, [x3, #0]
	WORD $0x3cc10073 // ldur q19, [x3, #16]
	WORD $0x4f000401 // movi v1.4s, #0
	WORD $0x3cc20074 // ldur q20, [x3, #32]
	WORD $0x3cc30075 // ldur q21, [x3, #48]
	WORD $0x3cc04096 // ldur q22, [x4, #4]
	WORD $0x3cc14097 // ldur q23, [x4, #20]
	WORD $0x4e3d1e9a // and v26.16b, v20.16b, v29.16b
	WORD $0x4e3d1ebb // and v27.16b, v21.16b, v29.16b
	WORD $0x4e3e1e58 // and v24.16b, v18.16b, v30.16b
	WORD $0x4f0a5718 // shl v24.16b, v24.16b, #2
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e3e1e78 // and v24.16b, v19.16b, v30.16b
	WORD $0x4f0a5718 // shl v24.16b, v24.16b, #2
	WORD $0x4eb81f7b // orr v27.16b, v27.16b, v24.16b
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e96974c // sdot v12.4s, v26.16b, v22.16b
	WORD $0x4e97976d // sdot v13.4s, v27.16b, v23.16b
	WORD $0x6f880181 // mla v1.4s, v12.4s, v8.s[0]
	WORD $0x6fa801a1 // mla v1.4s, v13.4s, v8.s[1]
	WORD $0x3cc24096 // ldur q22, [x4, #36]
	WORD $0x3cc34097 // ldur q23, [x4, #52]
	WORD $0x6f0e069a // ushr v26.16b, v20.16b, #2
	WORD $0x6f0e06bb // ushr v27.16b, v21.16b, #2
	WORD $0x4e3d1f5a // and v26.16b, v26.16b, v29.16b
	WORD $0x4e3d1f7b // and v27.16b, v27.16b, v29.16b
	WORD $0x6f0f0658 // ushr v24.16b, v18.16b, #1
	WORD $0x4e3e1f18 // and v24.16b, v24.16b, v30.16b
	WORD $0x4f0a5718 // shl v24.16b, v24.16b, #2
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x6f0f0678 // ushr v24.16b, v19.16b, #1
	WORD $0x4e3e1f18 // and v24.16b, v24.16b, v30.16b
	WORD $0x4f0a5718 // shl v24.16b, v24.16b, #2
	WORD $0x4eb81f7b // orr v27.16b, v27.16b, v24.16b
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e96974c // sdot v12.4s, v26.16b, v22.16b
	WORD $0x4e97976d // sdot v13.4s, v27.16b, v23.16b
	WORD $0x6f880981 // mla v1.4s, v12.4s, v8.s[2]
	WORD $0x6fa809a1 // mla v1.4s, v13.4s, v8.s[3]
	WORD $0x3cc44096 // ldur q22, [x4, #68]
	WORD $0x3cc54097 // ldur q23, [x4, #84]
	WORD $0x6f0c069a // ushr v26.16b, v20.16b, #4
	WORD $0x6f0c06bb // ushr v27.16b, v21.16b, #4
	WORD $0x4e3d1f5a // and v26.16b, v26.16b, v29.16b
	WORD $0x4e3d1f7b // and v27.16b, v27.16b, v29.16b
	WORD $0x6f0e0658 // ushr v24.16b, v18.16b, #2
	WORD $0x4e3e1f18 // and v24.16b, v24.16b, v30.16b
	WORD $0x4f0a5718 // shl v24.16b, v24.16b, #2
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x6f0e0678 // ushr v24.16b, v19.16b, #2
	WORD $0x4e3e1f18 // and v24.16b, v24.16b, v30.16b
	WORD $0x4f0a5718 // shl v24.16b, v24.16b, #2
	WORD $0x4eb81f7b // orr v27.16b, v27.16b, v24.16b
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e96974c // sdot v12.4s, v26.16b, v22.16b
	WORD $0x4e97976d // sdot v13.4s, v27.16b, v23.16b
	WORD $0x6f890181 // mla v1.4s, v12.4s, v9.s[0]
	WORD $0x6fa901a1 // mla v1.4s, v13.4s, v9.s[1]
	WORD $0x3cc64096 // ldur q22, [x4, #100]
	WORD $0x3cc74097 // ldur q23, [x4, #116]
	WORD $0x6f0a069a // ushr v26.16b, v20.16b, #6
	WORD $0x6f0a06bb // ushr v27.16b, v21.16b, #6
	WORD $0x4e3d1f5a // and v26.16b, v26.16b, v29.16b
	WORD $0x4e3d1f7b // and v27.16b, v27.16b, v29.16b
	WORD $0x6f0d0658 // ushr v24.16b, v18.16b, #3
	WORD $0x4e3e1f18 // and v24.16b, v24.16b, v30.16b
	WORD $0x4f0a5718 // shl v24.16b, v24.16b, #2
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x6f0d0678 // ushr v24.16b, v19.16b, #3
	WORD $0x4e3e1f18 // and v24.16b, v24.16b, v30.16b
	WORD $0x4f0a5718 // shl v24.16b, v24.16b, #2
	WORD $0x4eb81f7b // orr v27.16b, v27.16b, v24.16b
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e96974c // sdot v12.4s, v26.16b, v22.16b
	WORD $0x4e97976d // sdot v13.4s, v27.16b, v23.16b
	WORD $0x6f890981 // mla v1.4s, v12.4s, v9.s[2]
	WORD $0x6fa909a1 // mla v1.4s, v13.4s, v9.s[3]
	WORD $0x3cc40074 // ldur q20, [x3, #64]
	WORD $0x3cc50075 // ldur q21, [x3, #80]
	WORD $0x3cc84096 // ldur q22, [x4, #132]
	WORD $0x3cc94097 // ldur q23, [x4, #148]
	WORD $0x4e3d1e9a // and v26.16b, v20.16b, v29.16b
	WORD $0x4e3d1ebb // and v27.16b, v21.16b, v29.16b
	WORD $0x6f0c0658 // ushr v24.16b, v18.16b, #4
	WORD $0x4e3e1f18 // and v24.16b, v24.16b, v30.16b
	WORD $0x4f0a5718 // shl v24.16b, v24.16b, #2
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x6f0c0678 // ushr v24.16b, v19.16b, #4
	WORD $0x4e3e1f18 // and v24.16b, v24.16b, v30.16b
	WORD $0x4f0a5718 // shl v24.16b, v24.16b, #2
	WORD $0x4eb81f7b // orr v27.16b, v27.16b, v24.16b
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e96974c // sdot v12.4s, v26.16b, v22.16b
	WORD $0x4e97976d // sdot v13.4s, v27.16b, v23.16b
	WORD $0x6f8a0181 // mla v1.4s, v12.4s, v10.s[0]
	WORD $0x6faa01a1 // mla v1.4s, v13.4s, v10.s[1]
	WORD $0x3cca4096 // ldur q22, [x4, #164]
	WORD $0x3ccb4097 // ldur q23, [x4, #180]
	WORD $0x6f0e069a // ushr v26.16b, v20.16b, #2
	WORD $0x6f0e06bb // ushr v27.16b, v21.16b, #2
	WORD $0x4e3d1f5a // and v26.16b, v26.16b, v29.16b
	WORD $0x4e3d1f7b // and v27.16b, v27.16b, v29.16b
	WORD $0x6f0b0658 // ushr v24.16b, v18.16b, #5
	WORD $0x4e3e1f18 // and v24.16b, v24.16b, v30.16b
	WORD $0x4f0a5718 // shl v24.16b, v24.16b, #2
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x6f0b0678 // ushr v24.16b, v19.16b, #5
	WORD $0x4e3e1f18 // and v24.16b, v24.16b, v30.16b
	WORD $0x4f0a5718 // shl v24.16b, v24.16b, #2
	WORD $0x4eb81f7b // orr v27.16b, v27.16b, v24.16b
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e96974c // sdot v12.4s, v26.16b, v22.16b
	WORD $0x4e97976d // sdot v13.4s, v27.16b, v23.16b
	WORD $0x6f8a0981 // mla v1.4s, v12.4s, v10.s[2]
	WORD $0x6faa09a1 // mla v1.4s, v13.4s, v10.s[3]
	WORD $0x3ccc4096 // ldur q22, [x4, #196]
	WORD $0x3ccd4097 // ldur q23, [x4, #212]
	WORD $0x6f0c069a // ushr v26.16b, v20.16b, #4
	WORD $0x6f0c06bb // ushr v27.16b, v21.16b, #4
	WORD $0x4e3d1f5a // and v26.16b, v26.16b, v29.16b
	WORD $0x4e3d1f7b // and v27.16b, v27.16b, v29.16b
	WORD $0x6f0a0658 // ushr v24.16b, v18.16b, #6
	WORD $0x4e3e1f18 // and v24.16b, v24.16b, v30.16b
	WORD $0x4f0a5718 // shl v24.16b, v24.16b, #2
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x6f0a0678 // ushr v24.16b, v19.16b, #6
	WORD $0x4e3e1f18 // and v24.16b, v24.16b, v30.16b
	WORD $0x4f0a5718 // shl v24.16b, v24.16b, #2
	WORD $0x4eb81f7b // orr v27.16b, v27.16b, v24.16b
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e96974c // sdot v12.4s, v26.16b, v22.16b
	WORD $0x4e97976d // sdot v13.4s, v27.16b, v23.16b
	WORD $0x6f8b0181 // mla v1.4s, v12.4s, v11.s[0]
	WORD $0x6fab01a1 // mla v1.4s, v13.4s, v11.s[1]
	WORD $0x3cce4096 // ldur q22, [x4, #228]
	WORD $0x3ccf4097 // ldur q23, [x4, #244]
	WORD $0x6f0a069a // ushr v26.16b, v20.16b, #6
	WORD $0x6f0a06bb // ushr v27.16b, v21.16b, #6
	WORD $0x4e3d1f5a // and v26.16b, v26.16b, v29.16b
	WORD $0x4e3d1f7b // and v27.16b, v27.16b, v29.16b
	WORD $0x6f090658 // ushr v24.16b, v18.16b, #7
	WORD $0x4e3e1f18 // and v24.16b, v24.16b, v30.16b
	WORD $0x4f0a5718 // shl v24.16b, v24.16b, #2
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x6f090678 // ushr v24.16b, v19.16b, #7
	WORD $0x4e3e1f18 // and v24.16b, v24.16b, v30.16b
	WORD $0x4f0a5718 // shl v24.16b, v24.16b, #2
	WORD $0x4eb81f7b // orr v27.16b, v27.16b, v24.16b
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e96974c // sdot v12.4s, v26.16b, v22.16b
	WORD $0x4e97976d // sdot v13.4s, v27.16b, v23.16b
	WORD $0x6f8b0981 // mla v1.4s, v12.4s, v11.s[2]
	WORD $0x6fab09a1 // mla v1.4s, v13.4s, v11.s[3]
	WORD $0x6eb08421 // sub v1.4s, v1.4s, v16.4s
	WORD $0x4e21d821 // scvtf v1.4s, v1.4s
	WORD $0xbc400091 // ldur s17, [x4, #0]
	WORD $0x7c46c079 // ldur h25, [x3, #108]
	WORD $0x1ee24339 // fcvt s25, h25
	WORD $0x1e310b39 // fmul s25, s25, s17
	WORD $0x4f991020 // fmla v0.4s, v1.4s, v25.s[0]
	ADD	$110, R3, R3
	ADD	$292, R4, R4
	SUBW	$1, R1, R1
	CBNZW	R1, q3kblk
q3kzero:
	WORD $0x6e20d400 // faddp v0.4s, v0.4s, v0.4s
	WORD $0x7e30d800 // faddp s0, v0.2s
	FMOVS	F0, (R2)
	RET
q3koob:
	B	ovr_oob
