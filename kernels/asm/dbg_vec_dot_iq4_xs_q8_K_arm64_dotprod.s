// dbg_vec_dot_iq4_xs_q8_K: iq4_xs x q8_K dot, TBL kvalues lookup, SDOT per sub-block, 6-bit scales as i32 lane multiplies.
	WORD $0x4f000400 // movi v0.4s, #0
	MOVW	l0+8(FP), R1
	LSRW	$8, R1, R1
	MOVD	l1+16(FP), R2
	ADD	$4, R2, R27
	CMP	R27, R21
	BLO	ixoob
	ADD	R20, R2, R2
	CBZW	R1, ixreduce
	MOVD	l3+32(FP), R3
	MOVD	l5+48(FP), R4
	MOVD	$136, R26
	MUL	R1, R26, R26
	ADD	R3, R26, R27
	CMP	R27, R21
	BLO	ixoob
	MOVD	$292, R26
	MUL	R1, R26, R26
	ADD	R4, R26, R27
	CMP	R27, R21
	BLO	ixoob
	ADD	R20, R3, R3
	ADD	R20, R4, R4
	MOVD	$·ovr_dbg_vec_dot_iq4_xs_q8_K_dotprod_b16_61aa47540aa024b5(SB), R7
	VLD1	(R7), [V18.B16]
	WORD $0x4f00e5f0 // movi v16.16b, #15
ixblk:
	WORD $0x4f000414 // movi v20.4s, #0
	MOVHU	2(R3), R5
	MOVWU	4(R3), R6
	WORD $0x3cc08062 // ldur q2, [x3, #8]
	WORD $0x3cc18063 // ldur q3, [x3, #24]
	WORD $0x3cc04088 // ldur q8, [x4, #4]
	WORD $0x3cc14089 // ldur q9, [x4, #20]
	WORD $0x3cc2408a // ldur q10, [x4, #36]
	WORD $0x3cc3408b // ldur q11, [x4, #52]
	WORD $0x4e301c44 // and v4.16b, v2.16b, v16.16b
	WORD $0x6f0c0445 // ushr v5.16b, v2.16b, #4
	WORD $0x4e301c66 // and v6.16b, v3.16b, v16.16b
	WORD $0x6f0c0467 // ushr v7.16b, v3.16b, #4
	WORD $0x4e040244 // tbl v4.16b, {v18.16b}, v4.16b
	WORD $0x4e050245 // tbl v5.16b, {v18.16b}, v5.16b
	WORD $0x4e060246 // tbl v6.16b, {v18.16b}, v6.16b
	WORD $0x4e070247 // tbl v7.16b, {v18.16b}, v7.16b
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e88948c // sdot v12.4s, v4.16b, v8.16b
	WORD $0x4e8994ac // sdot v12.4s, v5.16b, v9.16b
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e8a94cd // sdot v13.4s, v6.16b, v10.16b
	WORD $0x4e8b94ed // sdot v13.4s, v7.16b, v11.16b
	ANDW	$0xf, R6, R7
	LSLW	$4, R5, R8
	ANDW	$0x30, R8, R8
	ORRW	R8, R7, R7
	SUBW	$32, R7, R7
	WORD $0x4e040cf5 // dup v21.4s, w7
	WORD $0x4eb59594 // mla v20.4s, v12.4s, v21.4s
	LSRW	$4, R6, R7
	ANDW	$0xf, R7, R7
	LSLW	$2, R5, R8
	ANDW	$0x30, R8, R8
	ORRW	R8, R7, R7
	SUBW	$32, R7, R7
	WORD $0x4e040cf5 // dup v21.4s, w7
	WORD $0x4eb595b4 // mla v20.4s, v13.4s, v21.4s
	LSRW	$4, R5, R5
	LSRW	$8, R6, R6
	WORD $0x3cc28062 // ldur q2, [x3, #40]
	WORD $0x3cc38063 // ldur q3, [x3, #56]
	WORD $0x3cc44088 // ldur q8, [x4, #68]
	WORD $0x3cc54089 // ldur q9, [x4, #84]
	WORD $0x3cc6408a // ldur q10, [x4, #100]
	WORD $0x3cc7408b // ldur q11, [x4, #116]
	WORD $0x4e301c44 // and v4.16b, v2.16b, v16.16b
	WORD $0x6f0c0445 // ushr v5.16b, v2.16b, #4
	WORD $0x4e301c66 // and v6.16b, v3.16b, v16.16b
	WORD $0x6f0c0467 // ushr v7.16b, v3.16b, #4
	WORD $0x4e040244 // tbl v4.16b, {v18.16b}, v4.16b
	WORD $0x4e050245 // tbl v5.16b, {v18.16b}, v5.16b
	WORD $0x4e060246 // tbl v6.16b, {v18.16b}, v6.16b
	WORD $0x4e070247 // tbl v7.16b, {v18.16b}, v7.16b
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e88948c // sdot v12.4s, v4.16b, v8.16b
	WORD $0x4e8994ac // sdot v12.4s, v5.16b, v9.16b
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e8a94cd // sdot v13.4s, v6.16b, v10.16b
	WORD $0x4e8b94ed // sdot v13.4s, v7.16b, v11.16b
	ANDW	$0xf, R6, R7
	LSLW	$4, R5, R8
	ANDW	$0x30, R8, R8
	ORRW	R8, R7, R7
	SUBW	$32, R7, R7
	WORD $0x4e040cf5 // dup v21.4s, w7
	WORD $0x4eb59594 // mla v20.4s, v12.4s, v21.4s
	LSRW	$4, R6, R7
	ANDW	$0xf, R7, R7
	LSLW	$2, R5, R8
	ANDW	$0x30, R8, R8
	ORRW	R8, R7, R7
	SUBW	$32, R7, R7
	WORD $0x4e040cf5 // dup v21.4s, w7
	WORD $0x4eb595b4 // mla v20.4s, v13.4s, v21.4s
	LSRW	$4, R5, R5
	LSRW	$8, R6, R6
	WORD $0x3cc48062 // ldur q2, [x3, #72]
	WORD $0x3cc58063 // ldur q3, [x3, #88]
	WORD $0x3cc84088 // ldur q8, [x4, #132]
	WORD $0x3cc94089 // ldur q9, [x4, #148]
	WORD $0x3cca408a // ldur q10, [x4, #164]
	WORD $0x3ccb408b // ldur q11, [x4, #180]
	WORD $0x4e301c44 // and v4.16b, v2.16b, v16.16b
	WORD $0x6f0c0445 // ushr v5.16b, v2.16b, #4
	WORD $0x4e301c66 // and v6.16b, v3.16b, v16.16b
	WORD $0x6f0c0467 // ushr v7.16b, v3.16b, #4
	WORD $0x4e040244 // tbl v4.16b, {v18.16b}, v4.16b
	WORD $0x4e050245 // tbl v5.16b, {v18.16b}, v5.16b
	WORD $0x4e060246 // tbl v6.16b, {v18.16b}, v6.16b
	WORD $0x4e070247 // tbl v7.16b, {v18.16b}, v7.16b
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e88948c // sdot v12.4s, v4.16b, v8.16b
	WORD $0x4e8994ac // sdot v12.4s, v5.16b, v9.16b
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e8a94cd // sdot v13.4s, v6.16b, v10.16b
	WORD $0x4e8b94ed // sdot v13.4s, v7.16b, v11.16b
	ANDW	$0xf, R6, R7
	LSLW	$4, R5, R8
	ANDW	$0x30, R8, R8
	ORRW	R8, R7, R7
	SUBW	$32, R7, R7
	WORD $0x4e040cf5 // dup v21.4s, w7
	WORD $0x4eb59594 // mla v20.4s, v12.4s, v21.4s
	LSRW	$4, R6, R7
	ANDW	$0xf, R7, R7
	LSLW	$2, R5, R8
	ANDW	$0x30, R8, R8
	ORRW	R8, R7, R7
	SUBW	$32, R7, R7
	WORD $0x4e040cf5 // dup v21.4s, w7
	WORD $0x4eb595b4 // mla v20.4s, v13.4s, v21.4s
	LSRW	$4, R5, R5
	LSRW	$8, R6, R6
	WORD $0x3cc68062 // ldur q2, [x3, #104]
	WORD $0x3cc78063 // ldur q3, [x3, #120]
	WORD $0x3ccc4088 // ldur q8, [x4, #196]
	WORD $0x3ccd4089 // ldur q9, [x4, #212]
	WORD $0x3cce408a // ldur q10, [x4, #228]
	WORD $0x3ccf408b // ldur q11, [x4, #244]
	WORD $0x4e301c44 // and v4.16b, v2.16b, v16.16b
	WORD $0x6f0c0445 // ushr v5.16b, v2.16b, #4
	WORD $0x4e301c66 // and v6.16b, v3.16b, v16.16b
	WORD $0x6f0c0467 // ushr v7.16b, v3.16b, #4
	WORD $0x4e040244 // tbl v4.16b, {v18.16b}, v4.16b
	WORD $0x4e050245 // tbl v5.16b, {v18.16b}, v5.16b
	WORD $0x4e060246 // tbl v6.16b, {v18.16b}, v6.16b
	WORD $0x4e070247 // tbl v7.16b, {v18.16b}, v7.16b
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e88948c // sdot v12.4s, v4.16b, v8.16b
	WORD $0x4e8994ac // sdot v12.4s, v5.16b, v9.16b
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e8a94cd // sdot v13.4s, v6.16b, v10.16b
	WORD $0x4e8b94ed // sdot v13.4s, v7.16b, v11.16b
	ANDW	$0xf, R6, R7
	LSLW	$4, R5, R8
	ANDW	$0x30, R8, R8
	ORRW	R8, R7, R7
	SUBW	$32, R7, R7
	WORD $0x4e040cf5 // dup v21.4s, w7
	WORD $0x4eb59594 // mla v20.4s, v12.4s, v21.4s
	LSRW	$4, R6, R7
	ANDW	$0xf, R7, R7
	LSLW	$2, R5, R8
	ANDW	$0x30, R8, R8
	ORRW	R8, R7, R7
	SUBW	$32, R7, R7
	WORD $0x4e040cf5 // dup v21.4s, w7
	WORD $0x4eb595b4 // mla v20.4s, v13.4s, v21.4s
	WORD $0x4eb1ba94 // addv s20, v20.4s
	WORD $0x4e21da94 // scvtf v20.4s, v20.4s
	WORD $0x7c400076 // ldur h22, [x3, #0]
	WORD $0xbc400097 // ldur s23, [x4, #0]
	WORD $0x1ee242d6 // fcvt s22, h22
	WORD $0x1e370ad6 // fmul s22, s22, s23
	WORD $0x4f961280 // fmla v0.4s, v20.4s, v22.s[0]
	ADD	$136, R3, R3
	ADD	$292, R4, R4
	SUBW	$1, R1, R1
	CBNZW	R1, ixblk
ixreduce:
	WORD $0x6e20d400 // faddp v0.4s, v0.4s, v0.4s
	WORD $0x7e30d800 // faddp s0, v0.2s
	FMOVS	F0, (R2)
	RET
ixoob:
	B	ovr_oob

DATA ·ovr_dbg_vec_dot_iq4_xs_q8_K_dotprod_b16_61aa47540aa024b5+0(SB)/8, $0xf6eaddcfbfad9881
DATA ·ovr_dbg_vec_dot_iq4_xs_q8_K_dotprod_b16_61aa47540aa024b5+8(SB)/8, $0x7159453526190d01
GLOBL ·ovr_dbg_vec_dot_iq4_xs_q8_K_dotprod_b16_61aa47540aa024b5(SB), RODATA|NOPTR, $16
