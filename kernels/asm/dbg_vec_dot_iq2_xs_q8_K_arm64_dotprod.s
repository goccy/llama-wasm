// dbg_vec_dot_iq2_xs_q8_K: iq2_xs x q8_K dot, u64 grid gathers through general registers, SDOT per 16 quants.
	WORD $0x4f000400 // movi v0.4s, #0
	MOVW	l0+8(FP), R1
	LSRW	$8, R1, R1
	MOVD	l1+16(FP), R2
	ADD	$4, R2, R27
	CMP	R27, R21
	BLO	i2soob
	ADD	R20, R2, R2
	CBZW	R1, i2sreduce
	MOVD	l3+32(FP), R3
	MOVD	l5+48(FP), R4
	MOVD	$74, R26
	MUL	R1, R26, R26
	ADD	R3, R26, R27
	CMP	R27, R21
	BLO	i2soob
	MOVD	$292, R26
	MUL	R1, R26, R26
	ADD	R4, R26, R27
	CMP	R27, R21
	BLO	i2soob
	ADD	R20, R3, R3
	ADD	R20, R4, R4
	MOVD	$·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89(SB), R12
	ADD	$4096, R12, R13
	MOVW	$0x3E000000, R5
	WORD $0x1e2700b1 // fmov s17, w5
i2sblk:
	WORD $0x4f000414 // movi v20.4s, #0
	MOVD	2(R3), R5
	UBFX	$0, R5, $9, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e081d02 // mov v2.d[0], x8
	UBFX	$9, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d04 // mov v4.d[0], x8
	UBFX	$16, R5, $9, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e181d02 // mov v2.d[1], x8
	UBFX	$25, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d04 // mov v4.d[1], x8
	UBFX	$32, R5, $9, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e081d03 // mov v3.d[0], x8
	UBFX	$41, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d05 // mov v5.d[0], x8
	UBFX	$48, R5, $9, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e181d03 // mov v3.d[1], x8
	UBFX	$57, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d05 // mov v5.d[1], x8
	WORD $0x4e249c42 // mul v2.16b, v2.16b, v4.16b
	WORD $0x4e259c63 // mul v3.16b, v3.16b, v5.16b
	WORD $0x3cc04086 // ldur q6, [x4, #4]
	WORD $0x3cc14087 // ldur q7, [x4, #20]
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e86944c // sdot v12.4s, v2.16b, v6.16b
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e87946d // sdot v13.4s, v3.16b, v7.16b
	MOVBU	66(R3), R7
	ANDW	$0xf, R7, R8
	LSLW	$1, R8, R8
	ADDW	$1, R8, R8
	WORD $0x4e040d15 // dup v21.4s, w8
	WORD $0x4eb59594 // mla v20.4s, v12.4s, v21.4s
	LSRW	$4, R7, R8
	LSLW	$1, R8, R8
	ADDW	$1, R8, R8
	WORD $0x4e040d15 // dup v21.4s, w8
	WORD $0x4eb595b4 // mla v20.4s, v13.4s, v21.4s
	MOVD	10(R3), R5
	UBFX	$0, R5, $9, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e081d02 // mov v2.d[0], x8
	UBFX	$9, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d04 // mov v4.d[0], x8
	UBFX	$16, R5, $9, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e181d02 // mov v2.d[1], x8
	UBFX	$25, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d04 // mov v4.d[1], x8
	UBFX	$32, R5, $9, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e081d03 // mov v3.d[0], x8
	UBFX	$41, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d05 // mov v5.d[0], x8
	UBFX	$48, R5, $9, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e181d03 // mov v3.d[1], x8
	UBFX	$57, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d05 // mov v5.d[1], x8
	WORD $0x4e249c42 // mul v2.16b, v2.16b, v4.16b
	WORD $0x4e259c63 // mul v3.16b, v3.16b, v5.16b
	WORD $0x3cc24086 // ldur q6, [x4, #36]
	WORD $0x3cc34087 // ldur q7, [x4, #52]
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e86944c // sdot v12.4s, v2.16b, v6.16b
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e87946d // sdot v13.4s, v3.16b, v7.16b
	MOVBU	67(R3), R7
	ANDW	$0xf, R7, R8
	LSLW	$1, R8, R8
	ADDW	$1, R8, R8
	WORD $0x4e040d15 // dup v21.4s, w8
	WORD $0x4eb59594 // mla v20.4s, v12.4s, v21.4s
	LSRW	$4, R7, R8
	LSLW	$1, R8, R8
	ADDW	$1, R8, R8
	WORD $0x4e040d15 // dup v21.4s, w8
	WORD $0x4eb595b4 // mla v20.4s, v13.4s, v21.4s
	MOVD	18(R3), R5
	UBFX	$0, R5, $9, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e081d02 // mov v2.d[0], x8
	UBFX	$9, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d04 // mov v4.d[0], x8
	UBFX	$16, R5, $9, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e181d02 // mov v2.d[1], x8
	UBFX	$25, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d04 // mov v4.d[1], x8
	UBFX	$32, R5, $9, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e081d03 // mov v3.d[0], x8
	UBFX	$41, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d05 // mov v5.d[0], x8
	UBFX	$48, R5, $9, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e181d03 // mov v3.d[1], x8
	UBFX	$57, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d05 // mov v5.d[1], x8
	WORD $0x4e249c42 // mul v2.16b, v2.16b, v4.16b
	WORD $0x4e259c63 // mul v3.16b, v3.16b, v5.16b
	WORD $0x3cc44086 // ldur q6, [x4, #68]
	WORD $0x3cc54087 // ldur q7, [x4, #84]
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e86944c // sdot v12.4s, v2.16b, v6.16b
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e87946d // sdot v13.4s, v3.16b, v7.16b
	MOVBU	68(R3), R7
	ANDW	$0xf, R7, R8
	LSLW	$1, R8, R8
	ADDW	$1, R8, R8
	WORD $0x4e040d15 // dup v21.4s, w8
	WORD $0x4eb59594 // mla v20.4s, v12.4s, v21.4s
	LSRW	$4, R7, R8
	LSLW	$1, R8, R8
	ADDW	$1, R8, R8
	WORD $0x4e040d15 // dup v21.4s, w8
	WORD $0x4eb595b4 // mla v20.4s, v13.4s, v21.4s
	MOVD	26(R3), R5
	UBFX	$0, R5, $9, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e081d02 // mov v2.d[0], x8
	UBFX	$9, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d04 // mov v4.d[0], x8
	UBFX	$16, R5, $9, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e181d02 // mov v2.d[1], x8
	UBFX	$25, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d04 // mov v4.d[1], x8
	UBFX	$32, R5, $9, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e081d03 // mov v3.d[0], x8
	UBFX	$41, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d05 // mov v5.d[0], x8
	UBFX	$48, R5, $9, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e181d03 // mov v3.d[1], x8
	UBFX	$57, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d05 // mov v5.d[1], x8
	WORD $0x4e249c42 // mul v2.16b, v2.16b, v4.16b
	WORD $0x4e259c63 // mul v3.16b, v3.16b, v5.16b
	WORD $0x3cc64086 // ldur q6, [x4, #100]
	WORD $0x3cc74087 // ldur q7, [x4, #116]
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e86944c // sdot v12.4s, v2.16b, v6.16b
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e87946d // sdot v13.4s, v3.16b, v7.16b
	MOVBU	69(R3), R7
	ANDW	$0xf, R7, R8
	LSLW	$1, R8, R8
	ADDW	$1, R8, R8
	WORD $0x4e040d15 // dup v21.4s, w8
	WORD $0x4eb59594 // mla v20.4s, v12.4s, v21.4s
	LSRW	$4, R7, R8
	LSLW	$1, R8, R8
	ADDW	$1, R8, R8
	WORD $0x4e040d15 // dup v21.4s, w8
	WORD $0x4eb595b4 // mla v20.4s, v13.4s, v21.4s
	MOVD	34(R3), R5
	UBFX	$0, R5, $9, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e081d02 // mov v2.d[0], x8
	UBFX	$9, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d04 // mov v4.d[0], x8
	UBFX	$16, R5, $9, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e181d02 // mov v2.d[1], x8
	UBFX	$25, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d04 // mov v4.d[1], x8
	UBFX	$32, R5, $9, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e081d03 // mov v3.d[0], x8
	UBFX	$41, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d05 // mov v5.d[0], x8
	UBFX	$48, R5, $9, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e181d03 // mov v3.d[1], x8
	UBFX	$57, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d05 // mov v5.d[1], x8
	WORD $0x4e249c42 // mul v2.16b, v2.16b, v4.16b
	WORD $0x4e259c63 // mul v3.16b, v3.16b, v5.16b
	WORD $0x3cc84086 // ldur q6, [x4, #132]
	WORD $0x3cc94087 // ldur q7, [x4, #148]
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e86944c // sdot v12.4s, v2.16b, v6.16b
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e87946d // sdot v13.4s, v3.16b, v7.16b
	MOVBU	70(R3), R7
	ANDW	$0xf, R7, R8
	LSLW	$1, R8, R8
	ADDW	$1, R8, R8
	WORD $0x4e040d15 // dup v21.4s, w8
	WORD $0x4eb59594 // mla v20.4s, v12.4s, v21.4s
	LSRW	$4, R7, R8
	LSLW	$1, R8, R8
	ADDW	$1, R8, R8
	WORD $0x4e040d15 // dup v21.4s, w8
	WORD $0x4eb595b4 // mla v20.4s, v13.4s, v21.4s
	MOVD	42(R3), R5
	UBFX	$0, R5, $9, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e081d02 // mov v2.d[0], x8
	UBFX	$9, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d04 // mov v4.d[0], x8
	UBFX	$16, R5, $9, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e181d02 // mov v2.d[1], x8
	UBFX	$25, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d04 // mov v4.d[1], x8
	UBFX	$32, R5, $9, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e081d03 // mov v3.d[0], x8
	UBFX	$41, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d05 // mov v5.d[0], x8
	UBFX	$48, R5, $9, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e181d03 // mov v3.d[1], x8
	UBFX	$57, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d05 // mov v5.d[1], x8
	WORD $0x4e249c42 // mul v2.16b, v2.16b, v4.16b
	WORD $0x4e259c63 // mul v3.16b, v3.16b, v5.16b
	WORD $0x3cca4086 // ldur q6, [x4, #164]
	WORD $0x3ccb4087 // ldur q7, [x4, #180]
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e86944c // sdot v12.4s, v2.16b, v6.16b
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e87946d // sdot v13.4s, v3.16b, v7.16b
	MOVBU	71(R3), R7
	ANDW	$0xf, R7, R8
	LSLW	$1, R8, R8
	ADDW	$1, R8, R8
	WORD $0x4e040d15 // dup v21.4s, w8
	WORD $0x4eb59594 // mla v20.4s, v12.4s, v21.4s
	LSRW	$4, R7, R8
	LSLW	$1, R8, R8
	ADDW	$1, R8, R8
	WORD $0x4e040d15 // dup v21.4s, w8
	WORD $0x4eb595b4 // mla v20.4s, v13.4s, v21.4s
	MOVD	50(R3), R5
	UBFX	$0, R5, $9, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e081d02 // mov v2.d[0], x8
	UBFX	$9, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d04 // mov v4.d[0], x8
	UBFX	$16, R5, $9, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e181d02 // mov v2.d[1], x8
	UBFX	$25, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d04 // mov v4.d[1], x8
	UBFX	$32, R5, $9, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e081d03 // mov v3.d[0], x8
	UBFX	$41, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d05 // mov v5.d[0], x8
	UBFX	$48, R5, $9, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e181d03 // mov v3.d[1], x8
	UBFX	$57, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d05 // mov v5.d[1], x8
	WORD $0x4e249c42 // mul v2.16b, v2.16b, v4.16b
	WORD $0x4e259c63 // mul v3.16b, v3.16b, v5.16b
	WORD $0x3ccc4086 // ldur q6, [x4, #196]
	WORD $0x3ccd4087 // ldur q7, [x4, #212]
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e86944c // sdot v12.4s, v2.16b, v6.16b
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e87946d // sdot v13.4s, v3.16b, v7.16b
	MOVBU	72(R3), R7
	ANDW	$0xf, R7, R8
	LSLW	$1, R8, R8
	ADDW	$1, R8, R8
	WORD $0x4e040d15 // dup v21.4s, w8
	WORD $0x4eb59594 // mla v20.4s, v12.4s, v21.4s
	LSRW	$4, R7, R8
	LSLW	$1, R8, R8
	ADDW	$1, R8, R8
	WORD $0x4e040d15 // dup v21.4s, w8
	WORD $0x4eb595b4 // mla v20.4s, v13.4s, v21.4s
	MOVD	58(R3), R5
	UBFX	$0, R5, $9, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e081d02 // mov v2.d[0], x8
	UBFX	$9, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d04 // mov v4.d[0], x8
	UBFX	$16, R5, $9, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e181d02 // mov v2.d[1], x8
	UBFX	$25, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d04 // mov v4.d[1], x8
	UBFX	$32, R5, $9, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e081d03 // mov v3.d[0], x8
	UBFX	$41, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d05 // mov v5.d[0], x8
	UBFX	$48, R5, $9, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e181d03 // mov v3.d[1], x8
	UBFX	$57, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d05 // mov v5.d[1], x8
	WORD $0x4e249c42 // mul v2.16b, v2.16b, v4.16b
	WORD $0x4e259c63 // mul v3.16b, v3.16b, v5.16b
	WORD $0x3cce4086 // ldur q6, [x4, #228]
	WORD $0x3ccf4087 // ldur q7, [x4, #244]
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e86944c // sdot v12.4s, v2.16b, v6.16b
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e87946d // sdot v13.4s, v3.16b, v7.16b
	MOVBU	73(R3), R7
	ANDW	$0xf, R7, R8
	LSLW	$1, R8, R8
	ADDW	$1, R8, R8
	WORD $0x4e040d15 // dup v21.4s, w8
	WORD $0x4eb59594 // mla v20.4s, v12.4s, v21.4s
	LSRW	$4, R7, R8
	LSLW	$1, R8, R8
	ADDW	$1, R8, R8
	WORD $0x4e040d15 // dup v21.4s, w8
	WORD $0x4eb595b4 // mla v20.4s, v13.4s, v21.4s
	WORD $0x4eb1ba94 // addv s20, v20.4s
	WORD $0x4e21da94 // scvtf v20.4s, v20.4s
	WORD $0x7c400079 // ldur h25, [x3, #0]
	WORD $0xbc40009a // ldur s26, [x4, #0]
	WORD $0x1ee24339 // fcvt s25, h25
	WORD $0x1e3a0b39 // fmul s25, s25, s26
	WORD $0x1e310b39 // fmul s25, s25, s17
	WORD $0x4f991280 // fmla v0.4s, v20.4s, v25.s[0]
	ADD	$74, R3, R3
	ADD	$292, R4, R4
	SUBW	$1, R1, R1
	CBNZW	R1, i2sblk
i2sreduce:
	WORD $0x6e20d400 // faddp v0.4s, v0.4s, v0.4s
	WORD $0x7e30d800 // faddp s0, v0.2s
	FMOVS	F0, (R2)
	RET
i2soob:
	B	ovr_oob

DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+0(SB)/8, $0x808080808080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+8(SB)/8, $0x80808080808082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+16(SB)/8, $0x808080808081919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+24(SB)/8, $0x808080808082b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+32(SB)/8, $0x808080808082b2b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+40(SB)/8, $0x808080808190819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+48(SB)/8, $0x808080808191908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+56(SB)/8, $0x80808080819192b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+64(SB)/8, $0x808080808192b19
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+72(SB)/8, $0x8080808082b0808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+80(SB)/8, $0x8080808082b082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+88(SB)/8, $0x8080808082b1919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+96(SB)/8, $0x8080808082b2b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+104(SB)/8, $0x808080819080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+112(SB)/8, $0x808080819081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+120(SB)/8, $0x80808081908192b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+128(SB)/8, $0x808080819082b19
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+136(SB)/8, $0x808080819190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+144(SB)/8, $0x80808081919082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+152(SB)/8, $0x808080819191919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+160(SB)/8, $0x808080819192b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+168(SB)/8, $0x8080808192b0819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+176(SB)/8, $0x8080808192b1908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+184(SB)/8, $0x80808082b080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+192(SB)/8, $0x80808082b08082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+200(SB)/8, $0x80808082b081919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+208(SB)/8, $0x80808082b082b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+216(SB)/8, $0x80808082b190819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+224(SB)/8, $0x80808082b191908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+232(SB)/8, $0x80808082b192b19
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+240(SB)/8, $0x80808082b2b0808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+248(SB)/8, $0x808081908080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+256(SB)/8, $0x808081908081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+264(SB)/8, $0x80808190808192b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+272(SB)/8, $0x808081908082b19
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+280(SB)/8, $0x808081908190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+288(SB)/8, $0x80808190819082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+296(SB)/8, $0x808081908191919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+304(SB)/8, $0x808081908192b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+312(SB)/8, $0x808081908192b2b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+320(SB)/8, $0x8080819082b0819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+328(SB)/8, $0x8080819082b1908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+336(SB)/8, $0x808081919080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+344(SB)/8, $0x80808191908082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+352(SB)/8, $0x808081919081919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+360(SB)/8, $0x808081919082b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+368(SB)/8, $0x808081919190819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+376(SB)/8, $0x808081919191908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+384(SB)/8, $0x8080819192b0808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+392(SB)/8, $0x8080819192b2b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+400(SB)/8, $0x80808192b080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+408(SB)/8, $0x80808192b081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+416(SB)/8, $0x80808192b190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+424(SB)/8, $0x808082b08080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+432(SB)/8, $0x808082b0808082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+440(SB)/8, $0x808082b08081919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+448(SB)/8, $0x808082b08082b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+456(SB)/8, $0x808082b08190819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+464(SB)/8, $0x808082b08191908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+472(SB)/8, $0x808082b082b0808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+480(SB)/8, $0x808082b19080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+488(SB)/8, $0x808082b19081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+496(SB)/8, $0x808082b19190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+504(SB)/8, $0x808082b19191919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+512(SB)/8, $0x808082b2b080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+520(SB)/8, $0x808082b2b082b2b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+528(SB)/8, $0x808190808080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+536(SB)/8, $0x808190808081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+544(SB)/8, $0x80819080808192b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+552(SB)/8, $0x808190808082b19
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+560(SB)/8, $0x808190808190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+568(SB)/8, $0x80819080819082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+576(SB)/8, $0x808190808191919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+584(SB)/8, $0x808190808192b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+592(SB)/8, $0x8081908082b0819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+600(SB)/8, $0x8081908082b1908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+608(SB)/8, $0x808190819080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+616(SB)/8, $0x80819081908082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+624(SB)/8, $0x808190819081919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+632(SB)/8, $0x808190819082b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+640(SB)/8, $0x808190819190819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+648(SB)/8, $0x808190819191908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+656(SB)/8, $0x80819081919192b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+664(SB)/8, $0x8081908192b0808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+672(SB)/8, $0x80819082b080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+680(SB)/8, $0x80819082b081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+688(SB)/8, $0x80819082b190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+696(SB)/8, $0x808191908080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+704(SB)/8, $0x80819190808082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+712(SB)/8, $0x808191908081919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+720(SB)/8, $0x808191908082b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+728(SB)/8, $0x808191908190819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+736(SB)/8, $0x808191908191908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+744(SB)/8, $0x8081919082b0808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+752(SB)/8, $0x808191919080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+760(SB)/8, $0x808191919081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+768(SB)/8, $0x808191919190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+776(SB)/8, $0x8081919192b0819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+784(SB)/8, $0x80819192b080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+792(SB)/8, $0x808192b08080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+800(SB)/8, $0x808192b08081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+808(SB)/8, $0x808192b08190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+816(SB)/8, $0x808192b082b192b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+824(SB)/8, $0x808192b19080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+832(SB)/8, $0x808192b1908082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+840(SB)/8, $0x808192b2b081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+848(SB)/8, $0x8082b0808080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+856(SB)/8, $0x8082b080808082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+864(SB)/8, $0x8082b0808081919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+872(SB)/8, $0x8082b0808082b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+880(SB)/8, $0x8082b0808082b2b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+888(SB)/8, $0x8082b0808190819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+896(SB)/8, $0x8082b0808191908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+904(SB)/8, $0x8082b08082b0808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+912(SB)/8, $0x8082b08082b1919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+920(SB)/8, $0x8082b0819080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+928(SB)/8, $0x8082b0819081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+936(SB)/8, $0x8082b0819190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+944(SB)/8, $0x8082b0819192b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+952(SB)/8, $0x8082b082b080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+960(SB)/8, $0x8082b082b2b0808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+968(SB)/8, $0x8082b082b2b2b2b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+976(SB)/8, $0x8082b1908080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+984(SB)/8, $0x8082b1908081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+992(SB)/8, $0x8082b1908190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1000(SB)/8, $0x8082b1919080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1008(SB)/8, $0x8082b192b080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1016(SB)/8, $0x8082b192b082b19
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1024(SB)/8, $0x8082b2b08080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1032(SB)/8, $0x8082b2b082b0808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1040(SB)/8, $0x8082b2b082b2b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1048(SB)/8, $0x8082b2b2b19192b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1056(SB)/8, $0x8082b2b2b2b0808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1064(SB)/8, $0x819080808080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1072(SB)/8, $0x819080808081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1080(SB)/8, $0x81908080808192b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1088(SB)/8, $0x819080808082b19
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1096(SB)/8, $0x819080808190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1104(SB)/8, $0x81908080819082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1112(SB)/8, $0x819080808191919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1120(SB)/8, $0x819080808192b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1128(SB)/8, $0x8190808082b0819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1136(SB)/8, $0x8190808082b1908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1144(SB)/8, $0x819080819080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1152(SB)/8, $0x81908081908082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1160(SB)/8, $0x819080819081919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1168(SB)/8, $0x819080819082b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1176(SB)/8, $0x819080819190819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1184(SB)/8, $0x819080819191908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1192(SB)/8, $0x8190808192b0808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1200(SB)/8, $0x8190808192b2b2b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1208(SB)/8, $0x81908082b080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1216(SB)/8, $0x81908082b081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1224(SB)/8, $0x81908082b190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1232(SB)/8, $0x819081908080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1240(SB)/8, $0x81908190808082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1248(SB)/8, $0x819081908081919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1256(SB)/8, $0x819081908082b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1264(SB)/8, $0x819081908190819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1272(SB)/8, $0x819081908191908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1280(SB)/8, $0x8190819082b0808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1288(SB)/8, $0x819081919080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1296(SB)/8, $0x819081919081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1304(SB)/8, $0x819081919190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1312(SB)/8, $0x81908192b080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1320(SB)/8, $0x81908192b191908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1328(SB)/8, $0x81908192b19192b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1336(SB)/8, $0x819082b08080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1344(SB)/8, $0x819082b08081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1352(SB)/8, $0x819082b0808192b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1360(SB)/8, $0x819082b08190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1368(SB)/8, $0x819082b19080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1376(SB)/8, $0x819082b192b0808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1384(SB)/8, $0x819190808080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1392(SB)/8, $0x81919080808082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1400(SB)/8, $0x819190808081919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1408(SB)/8, $0x819190808082b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1416(SB)/8, $0x819190808190819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1424(SB)/8, $0x819190808191908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1432(SB)/8, $0x8191908082b0808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1440(SB)/8, $0x819190819080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1448(SB)/8, $0x819190819081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1456(SB)/8, $0x819190819082b19
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1464(SB)/8, $0x819190819190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1472(SB)/8, $0x8191908192b1908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1480(SB)/8, $0x81919082b080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1488(SB)/8, $0x819191908080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1496(SB)/8, $0x819191908081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1504(SB)/8, $0x819191908190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1512(SB)/8, $0x819191919080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1520(SB)/8, $0x819192b08080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1528(SB)/8, $0x819192b08191908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1536(SB)/8, $0x819192b19082b19
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1544(SB)/8, $0x8192b0808080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1552(SB)/8, $0x8192b0808081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1560(SB)/8, $0x8192b0808190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1568(SB)/8, $0x8192b080819082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1576(SB)/8, $0x8192b0819080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1584(SB)/8, $0x8192b0819191908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1592(SB)/8, $0x8192b082b08192b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1600(SB)/8, $0x8192b1908080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1608(SB)/8, $0x8192b1908081919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1616(SB)/8, $0x8192b19192b192b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1624(SB)/8, $0x8192b2b19190819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1632(SB)/8, $0x8192b2b2b2b2b19
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1640(SB)/8, $0x82b080808080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1648(SB)/8, $0x82b08080808082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1656(SB)/8, $0x82b080808081919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1664(SB)/8, $0x82b080808082b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1672(SB)/8, $0x82b080808082b2b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1680(SB)/8, $0x82b080808190819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1688(SB)/8, $0x82b080808191908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1696(SB)/8, $0x82b0808082b0808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1704(SB)/8, $0x82b080819080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1712(SB)/8, $0x82b080819081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1720(SB)/8, $0x82b080819190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1728(SB)/8, $0x82b08082b080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1736(SB)/8, $0x82b08082b2b0808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1744(SB)/8, $0x82b081908080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1752(SB)/8, $0x82b081908081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1760(SB)/8, $0x82b081908190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1768(SB)/8, $0x82b081919080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1776(SB)/8, $0x82b081919082b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1784(SB)/8, $0x82b0819192b1919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1792(SB)/8, $0x82b082b08080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1800(SB)/8, $0x82b082b082b082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1808(SB)/8, $0x82b082b2b080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1816(SB)/8, $0x82b082b2b2b2b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1824(SB)/8, $0x82b190808080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1832(SB)/8, $0x82b190808081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1840(SB)/8, $0x82b190808190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1848(SB)/8, $0x82b1908082b2b19
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1856(SB)/8, $0x82b190819080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1864(SB)/8, $0x82b191908080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1872(SB)/8, $0x82b191919080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1880(SB)/8, $0x82b19191919082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1888(SB)/8, $0x82b19192b192b19
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1896(SB)/8, $0x82b192b08080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1904(SB)/8, $0x82b192b08192b2b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1912(SB)/8, $0x82b192b2b2b192b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1920(SB)/8, $0x82b2b0808080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1928(SB)/8, $0x82b2b0808082b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1936(SB)/8, $0x82b2b0808082b2b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1944(SB)/8, $0x82b2b08082b0808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1952(SB)/8, $0x82b2b0819191919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1960(SB)/8, $0x82b2b082b082b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1968(SB)/8, $0x82b2b082b2b082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1976(SB)/8, $0x82b2b19192b2b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1984(SB)/8, $0x82b2b192b190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+1992(SB)/8, $0x82b2b2b08082b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2000(SB)/8, $0x82b2b2b082b0808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2008(SB)/8, $0x82b2b2b2b08082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2016(SB)/8, $0x82b2b2b2b082b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2024(SB)/8, $0x82b2b2b2b082b2b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2032(SB)/8, $0x1908080808080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2040(SB)/8, $0x1908080808081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2048(SB)/8, $0x190808080808192b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2056(SB)/8, $0x1908080808082b19
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2064(SB)/8, $0x1908080808190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2072(SB)/8, $0x190808080819082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2080(SB)/8, $0x1908080808191919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2088(SB)/8, $0x1908080808192b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2096(SB)/8, $0x19080808082b0819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2104(SB)/8, $0x19080808082b1908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2112(SB)/8, $0x1908080819080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2120(SB)/8, $0x190808081908082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2128(SB)/8, $0x1908080819081919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2136(SB)/8, $0x1908080819082b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2144(SB)/8, $0x1908080819082b2b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2152(SB)/8, $0x1908080819190819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2160(SB)/8, $0x1908080819191908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2168(SB)/8, $0x19080808192b0808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2176(SB)/8, $0x19080808192b1919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2184(SB)/8, $0x190808082b080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2192(SB)/8, $0x190808082b081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2200(SB)/8, $0x190808082b190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2208(SB)/8, $0x1908081908080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2216(SB)/8, $0x190808190808082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2224(SB)/8, $0x1908081908081919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2232(SB)/8, $0x1908081908082b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2240(SB)/8, $0x1908081908190819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2248(SB)/8, $0x1908081908191908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2256(SB)/8, $0x19080819082b0808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2264(SB)/8, $0x1908081919080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2272(SB)/8, $0x1908081919081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2280(SB)/8, $0x1908081919190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2288(SB)/8, $0x190808192b080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2296(SB)/8, $0x190808192b081919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2304(SB)/8, $0x190808192b2b082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2312(SB)/8, $0x1908082b08080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2320(SB)/8, $0x1908082b08081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2328(SB)/8, $0x1908082b08190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2336(SB)/8, $0x1908082b0819082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2344(SB)/8, $0x1908082b082b2b19
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2352(SB)/8, $0x1908082b19080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2360(SB)/8, $0x1908190808080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2368(SB)/8, $0x190819080808082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2376(SB)/8, $0x1908190808081919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2384(SB)/8, $0x1908190808082b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2392(SB)/8, $0x1908190808190819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2400(SB)/8, $0x1908190808191908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2408(SB)/8, $0x1908190808192b19
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2416(SB)/8, $0x19081908082b0808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2424(SB)/8, $0x1908190819080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2432(SB)/8, $0x1908190819081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2440(SB)/8, $0x1908190819190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2448(SB)/8, $0x190819082b080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2456(SB)/8, $0x190819082b191908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2464(SB)/8, $0x1908191908080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2472(SB)/8, $0x1908191908081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2480(SB)/8, $0x1908191908190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2488(SB)/8, $0x19081919082b1908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2496(SB)/8, $0x1908191919080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2504(SB)/8, $0x190819192b192b2b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2512(SB)/8, $0x1908192b08080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2520(SB)/8, $0x1908192b08082b2b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2528(SB)/8, $0x1908192b19081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2536(SB)/8, $0x1908192b19190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2544(SB)/8, $0x19082b0808080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2552(SB)/8, $0x19082b0808081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2560(SB)/8, $0x19082b0808190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2568(SB)/8, $0x19082b0819080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2576(SB)/8, $0x19082b0819081919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2584(SB)/8, $0x19082b0819191908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2592(SB)/8, $0x19082b08192b082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2600(SB)/8, $0x19082b1908080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2608(SB)/8, $0x19082b1908190819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2616(SB)/8, $0x19082b1919081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2624(SB)/8, $0x19082b1919190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2632(SB)/8, $0x19082b19192b2b19
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2640(SB)/8, $0x19082b2b08081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2648(SB)/8, $0x1919080808080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2656(SB)/8, $0x191908080808082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2664(SB)/8, $0x1919080808081919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2672(SB)/8, $0x1919080808082b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2680(SB)/8, $0x1919080808190819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2688(SB)/8, $0x1919080808191908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2696(SB)/8, $0x19190808082b0808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2704(SB)/8, $0x19190808082b2b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2712(SB)/8, $0x1919080819080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2720(SB)/8, $0x1919080819081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2728(SB)/8, $0x1919080819190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2736(SB)/8, $0x191908082b080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2744(SB)/8, $0x1919081908080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2752(SB)/8, $0x1919081908081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2760(SB)/8, $0x1919081908190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2768(SB)/8, $0x1919081908191919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2776(SB)/8, $0x1919081919080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2784(SB)/8, $0x191908191908082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2792(SB)/8, $0x1919082b08080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2800(SB)/8, $0x1919082b19081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2808(SB)/8, $0x1919082b2b2b2b2b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2816(SB)/8, $0x1919190808080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2824(SB)/8, $0x1919190808081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2832(SB)/8, $0x1919190808190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2840(SB)/8, $0x19191908082b0819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2848(SB)/8, $0x1919190819080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2856(SB)/8, $0x19191908192b0808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2864(SB)/8, $0x191919082b080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2872(SB)/8, $0x191919082b2b0819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2880(SB)/8, $0x1919191908080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2888(SB)/8, $0x1919191908082b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2896(SB)/8, $0x191919192b080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2904(SB)/8, $0x191919192b082b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2912(SB)/8, $0x1919192b082b0819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2920(SB)/8, $0x1919192b192b2b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2928(SB)/8, $0x1919192b2b2b0819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2936(SB)/8, $0x19192b0808080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2944(SB)/8, $0x19192b0808191908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2952(SB)/8, $0x19192b0819080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2960(SB)/8, $0x19192b0819190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2968(SB)/8, $0x19192b082b192b19
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2976(SB)/8, $0x19192b1908192b2b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2984(SB)/8, $0x19192b1919080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+2992(SB)/8, $0x19192b191908082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3000(SB)/8, $0x19192b2b2b081919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3008(SB)/8, $0x192b080808080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3016(SB)/8, $0x192b080808081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3024(SB)/8, $0x192b080808190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3032(SB)/8, $0x192b080819080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3040(SB)/8, $0x192b080819191908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3048(SB)/8, $0x192b0808192b082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3056(SB)/8, $0x192b08082b08192b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3064(SB)/8, $0x192b08082b2b2b19
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3072(SB)/8, $0x192b081908080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3080(SB)/8, $0x192b082b082b1908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3088(SB)/8, $0x192b082b19082b2b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3096(SB)/8, $0x192b082b2b19082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3104(SB)/8, $0x192b190808080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3112(SB)/8, $0x192b19080819192b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3120(SB)/8, $0x192b191908190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3128(SB)/8, $0x192b191919080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3136(SB)/8, $0x192b191919081919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3144(SB)/8, $0x192b19192b2b1908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3152(SB)/8, $0x192b2b0808080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3160(SB)/8, $0x192b2b08192b2b2b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3168(SB)/8, $0x192b2b19082b1919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3176(SB)/8, $0x192b2b2b0808192b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3184(SB)/8, $0x192b2b2b19191908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3192(SB)/8, $0x192b2b2b192b082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3200(SB)/8, $0x2b08080808080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3208(SB)/8, $0x2b0808080808082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3216(SB)/8, $0x2b08080808081919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3224(SB)/8, $0x2b08080808082b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3232(SB)/8, $0x2b08080808190819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3240(SB)/8, $0x2b08080808191908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3248(SB)/8, $0x2b080808082b0808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3256(SB)/8, $0x2b080808082b2b2b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3264(SB)/8, $0x2b08080819080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3272(SB)/8, $0x2b08080819081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3280(SB)/8, $0x2b08080819190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3288(SB)/8, $0x2b0808082b080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3296(SB)/8, $0x2b0808082b08082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3304(SB)/8, $0x2b0808082b2b2b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3312(SB)/8, $0x2b0808082b2b2b2b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3320(SB)/8, $0x2b08081908080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3328(SB)/8, $0x2b08081908081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3336(SB)/8, $0x2b0808190808192b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3344(SB)/8, $0x2b08081908190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3352(SB)/8, $0x2b08081919080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3360(SB)/8, $0x2b08081919190819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3368(SB)/8, $0x2b08081919192b19
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3376(SB)/8, $0x2b08082b08080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3384(SB)/8, $0x2b08082b082b0808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3392(SB)/8, $0x2b08082b2b080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3400(SB)/8, $0x2b08082b2b08082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3408(SB)/8, $0x2b08082b2b2b0808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3416(SB)/8, $0x2b08082b2b2b2b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3424(SB)/8, $0x2b08190808080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3432(SB)/8, $0x2b08190808081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3440(SB)/8, $0x2b08190808190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3448(SB)/8, $0x2b0819080819082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3456(SB)/8, $0x2b08190808191919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3464(SB)/8, $0x2b08190819080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3472(SB)/8, $0x2b081908192b0808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3480(SB)/8, $0x2b0819082b082b19
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3488(SB)/8, $0x2b08191908080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3496(SB)/8, $0x2b08191919081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3504(SB)/8, $0x2b0819192b2b1919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3512(SB)/8, $0x2b08192b08192b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3520(SB)/8, $0x2b08192b192b2b2b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3528(SB)/8, $0x2b082b0808080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3536(SB)/8, $0x2b082b0808082b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3544(SB)/8, $0x2b082b08082b1919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3552(SB)/8, $0x2b082b0819192b2b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3560(SB)/8, $0x2b082b082b080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3568(SB)/8, $0x2b082b082b08082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3576(SB)/8, $0x2b082b082b2b2b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3584(SB)/8, $0x2b082b190808192b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3592(SB)/8, $0x2b082b2b082b082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3600(SB)/8, $0x2b082b2b2b080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3608(SB)/8, $0x2b082b2b2b082b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3616(SB)/8, $0x2b082b2b2b19192b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3624(SB)/8, $0x2b082b2b2b2b2b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3632(SB)/8, $0x2b19080808080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3640(SB)/8, $0x2b19080808081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3648(SB)/8, $0x2b19080808190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3656(SB)/8, $0x2b19080819080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3664(SB)/8, $0x2b1908081919192b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3672(SB)/8, $0x2b1908082b081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3680(SB)/8, $0x2b19081908080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3688(SB)/8, $0x2b190819082b082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3696(SB)/8, $0x2b190819192b1908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3704(SB)/8, $0x2b19082b1919192b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3712(SB)/8, $0x2b19082b2b082b19
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3720(SB)/8, $0x2b19190808080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3728(SB)/8, $0x2b19190808081919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3736(SB)/8, $0x2b19190819081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3744(SB)/8, $0x2b19190819190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3752(SB)/8, $0x2b19190819192b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3760(SB)/8, $0x2b191919082b2b19
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3768(SB)/8, $0x2b1919192b190808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3776(SB)/8, $0x2b1919192b19082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3784(SB)/8, $0x2b19192b19080819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3792(SB)/8, $0x2b192b0819190819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3800(SB)/8, $0x2b192b082b2b192b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3808(SB)/8, $0x2b192b1919082b19
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3816(SB)/8, $0x2b192b2b08191919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3824(SB)/8, $0x2b192b2b192b0808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3832(SB)/8, $0x2b2b080808080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3840(SB)/8, $0x2b2b08080808082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3848(SB)/8, $0x2b2b080808082b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3856(SB)/8, $0x2b2b080808082b2b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3864(SB)/8, $0x2b2b0808082b0808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3872(SB)/8, $0x2b2b0808082b2b2b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3880(SB)/8, $0x2b2b08082b2b0808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3888(SB)/8, $0x2b2b081919190819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3896(SB)/8, $0x2b2b081919192b19
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3904(SB)/8, $0x2b2b08192b2b192b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3912(SB)/8, $0x2b2b082b08080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3920(SB)/8, $0x2b2b082b0808082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3928(SB)/8, $0x2b2b082b08082b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3936(SB)/8, $0x2b2b082b082b2b2b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3944(SB)/8, $0x2b2b082b2b080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3952(SB)/8, $0x2b2b082b2b2b0808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3960(SB)/8, $0x2b2b190819080808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3968(SB)/8, $0x2b2b19082b191919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3976(SB)/8, $0x2b2b192b192b1919
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3984(SB)/8, $0x2b2b192b2b192b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+3992(SB)/8, $0x2b2b2b0808082b2b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4000(SB)/8, $0x2b2b2b08082b0808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4008(SB)/8, $0x2b2b2b08082b082b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4016(SB)/8, $0x2b2b2b08082b2b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4024(SB)/8, $0x2b2b2b082b2b0808
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4032(SB)/8, $0x2b2b2b082b2b2b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4040(SB)/8, $0x2b2b2b1908081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4048(SB)/8, $0x2b2b2b192b081908
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4056(SB)/8, $0x2b2b2b192b08192b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4064(SB)/8, $0x2b2b2b2b082b2b08
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4072(SB)/8, $0x2b2b2b2b082b2b2b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4080(SB)/8, $0x2b2b2b2b2b190819
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4088(SB)/8, $0x2b2b2b2b2b2b2b2b
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4096(SB)/8, $0x101010101010101
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4104(SB)/8, $0xff010101010101ff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4112(SB)/8, $0xff0101010101ff01
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4120(SB)/8, $0x10101010101ffff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4128(SB)/8, $0xff01010101ff0101
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4136(SB)/8, $0x101010101ff01ff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4144(SB)/8, $0x101010101ffff01
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4152(SB)/8, $0xff01010101ffffff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4160(SB)/8, $0xff010101ff010101
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4168(SB)/8, $0x1010101ff0101ff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4176(SB)/8, $0x1010101ff01ff01
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4184(SB)/8, $0xff010101ff01ffff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4192(SB)/8, $0x1010101ffff0101
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4200(SB)/8, $0xff010101ffff01ff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4208(SB)/8, $0xff010101ffffff01
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4216(SB)/8, $0x1010101ffffffff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4224(SB)/8, $0xff0101ff01010101
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4232(SB)/8, $0x10101ff010101ff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4240(SB)/8, $0x10101ff0101ff01
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4248(SB)/8, $0xff0101ff0101ffff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4256(SB)/8, $0x10101ff01ff0101
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4264(SB)/8, $0xff0101ff01ff01ff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4272(SB)/8, $0xff0101ff01ffff01
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4280(SB)/8, $0x10101ff01ffffff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4288(SB)/8, $0x10101ffff010101
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4296(SB)/8, $0xff0101ffff0101ff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4304(SB)/8, $0xff0101ffff01ff01
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4312(SB)/8, $0x10101ffff01ffff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4320(SB)/8, $0xff0101ffffff0101
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4328(SB)/8, $0x10101ffffff01ff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4336(SB)/8, $0x10101ffffffff01
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4344(SB)/8, $0xff0101ffffffffff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4352(SB)/8, $0xff01ff0101010101
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4360(SB)/8, $0x101ff01010101ff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4368(SB)/8, $0x101ff010101ff01
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4376(SB)/8, $0xff01ff010101ffff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4384(SB)/8, $0x101ff0101ff0101
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4392(SB)/8, $0xff01ff0101ff01ff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4400(SB)/8, $0xff01ff0101ffff01
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4408(SB)/8, $0x101ff0101ffffff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4416(SB)/8, $0x101ff01ff010101
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4424(SB)/8, $0xff01ff01ff0101ff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4432(SB)/8, $0xff01ff01ff01ff01
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4440(SB)/8, $0x101ff01ff01ffff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4448(SB)/8, $0xff01ff01ffff0101
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4456(SB)/8, $0x101ff01ffff01ff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4464(SB)/8, $0x101ff01ffffff01
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4472(SB)/8, $0xff01ff01ffffffff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4480(SB)/8, $0x101ffff01010101
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4488(SB)/8, $0xff01ffff010101ff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4496(SB)/8, $0xff01ffff0101ff01
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4504(SB)/8, $0x101ffff0101ffff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4512(SB)/8, $0xff01ffff01ff0101
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4520(SB)/8, $0x101ffff01ff01ff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4528(SB)/8, $0x101ffff01ffff01
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4536(SB)/8, $0xff01ffff01ffffff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4544(SB)/8, $0xff01ffffff010101
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4552(SB)/8, $0x101ffffff0101ff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4560(SB)/8, $0x101ffffff01ff01
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4568(SB)/8, $0xff01ffffff01ffff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4576(SB)/8, $0x101ffffffff0101
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4584(SB)/8, $0xff01ffffffff01ff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4592(SB)/8, $0xff01ffffffffff01
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4600(SB)/8, $0x101ffffffffffff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4608(SB)/8, $0xffff010101010101
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4616(SB)/8, $0x1ff0101010101ff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4624(SB)/8, $0x1ff01010101ff01
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4632(SB)/8, $0xffff01010101ffff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4640(SB)/8, $0x1ff010101ff0101
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4648(SB)/8, $0xffff010101ff01ff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4656(SB)/8, $0xffff010101ffff01
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4664(SB)/8, $0x1ff010101ffffff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4672(SB)/8, $0x1ff0101ff010101
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4680(SB)/8, $0xffff0101ff0101ff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4688(SB)/8, $0xffff0101ff01ff01
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4696(SB)/8, $0x1ff0101ff01ffff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4704(SB)/8, $0xffff0101ffff0101
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4712(SB)/8, $0x1ff0101ffff01ff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4720(SB)/8, $0x1ff0101ffffff01
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4728(SB)/8, $0xffff0101ffffffff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4736(SB)/8, $0x1ff01ff01010101
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4744(SB)/8, $0xffff01ff010101ff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4752(SB)/8, $0xffff01ff0101ff01
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4760(SB)/8, $0x1ff01ff0101ffff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4768(SB)/8, $0xffff01ff01ff0101
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4776(SB)/8, $0x1ff01ff01ff01ff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4784(SB)/8, $0x1ff01ff01ffff01
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4792(SB)/8, $0xffff01ff01ffffff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4800(SB)/8, $0xffff01ffff010101
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4808(SB)/8, $0x1ff01ffff0101ff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4816(SB)/8, $0x1ff01ffff01ff01
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4824(SB)/8, $0xffff01ffff01ffff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4832(SB)/8, $0x1ff01ffffff0101
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4840(SB)/8, $0xffff01ffffff01ff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4848(SB)/8, $0xffff01ffffffff01
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4856(SB)/8, $0x1ff01ffffffffff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4864(SB)/8, $0x1ffff0101010101
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4872(SB)/8, $0xffffff01010101ff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4880(SB)/8, $0xffffff010101ff01
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4888(SB)/8, $0x1ffff010101ffff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4896(SB)/8, $0xffffff0101ff0101
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4904(SB)/8, $0x1ffff0101ff01ff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4912(SB)/8, $0x1ffff0101ffff01
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4920(SB)/8, $0xffffff0101ffffff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4928(SB)/8, $0xffffff01ff010101
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4936(SB)/8, $0x1ffff01ff0101ff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4944(SB)/8, $0x1ffff01ff01ff01
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4952(SB)/8, $0xffffff01ff01ffff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4960(SB)/8, $0x1ffff01ffff0101
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4968(SB)/8, $0xffffff01ffff01ff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4976(SB)/8, $0xffffff01ffffff01
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4984(SB)/8, $0x1ffff01ffffffff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+4992(SB)/8, $0xffffffff01010101
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+5000(SB)/8, $0x1ffffff010101ff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+5008(SB)/8, $0x1ffffff0101ff01
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+5016(SB)/8, $0xffffffff0101ffff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+5024(SB)/8, $0x1ffffff01ff0101
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+5032(SB)/8, $0xffffffff01ff01ff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+5040(SB)/8, $0xffffffff01ffff01
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+5048(SB)/8, $0x1ffffff01ffffff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+5056(SB)/8, $0x1ffffffff010101
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+5064(SB)/8, $0xffffffffff0101ff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+5072(SB)/8, $0xffffffffff01ff01
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+5080(SB)/8, $0x1ffffffff01ffff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+5088(SB)/8, $0xffffffffffff0101
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+5096(SB)/8, $0x1ffffffffff01ff
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+5104(SB)/8, $0x1ffffffffffff01
DATA ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89+5112(SB)/8, $0xffffffffffffffff
GLOBL ·ovr_dbg_vec_dot_iq2_xs_q8_K_dotprod_b5120_c52c9c367baf2c89(SB), RODATA|NOPTR, $5120
