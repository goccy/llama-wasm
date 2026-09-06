// dbg_vec_dot_iq2_xxs_q8_K: iq2_xxs x q8_K dot, u64 grid gathers through general registers, SDOT per 16 quants.
	WORD $0x4f000400 // movi v0.4s, #0
	MOVW	l0+8(FP), R1
	LSRW	$8, R1, R1
	MOVD	l1+16(FP), R2
	ADD	$4, R2, R27
	CMP	R27, R21
	BLO	i2xoob
	ADD	R20, R2, R2
	CBZW	R1, i2xreduce
	MOVD	l3+32(FP), R3
	MOVD	l5+48(FP), R4
	MOVD	$66, R26
	MUL	R1, R26, R26
	ADD	R3, R26, R27
	CMP	R27, R21
	BLO	i2xoob
	MOVD	$292, R26
	MUL	R1, R26, R26
	ADD	R4, R26, R27
	CMP	R27, R21
	BLO	i2xoob
	ADD	R20, R3, R3
	ADD	R20, R4, R4
	MOVD	$·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184(SB), R12
	ADD	$2048, R12, R13
	MOVW	$0x3E000000, R5
	WORD $0x1e2700b1 // fmov s17, w5
i2xblk:
	WORD $0x4f000414 // movi v20.4s, #0
	MOVD	2(R3), R5
	UBFX	$0, R5, $8, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e081d02 // mov v2.d[0], x8
	UBFX	$32, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d04 // mov v4.d[0], x8
	UBFX	$8, R5, $8, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e181d02 // mov v2.d[1], x8
	UBFX	$39, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d04 // mov v4.d[1], x8
	UBFX	$16, R5, $8, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e081d03 // mov v3.d[0], x8
	UBFX	$46, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d05 // mov v5.d[0], x8
	UBFX	$24, R5, $8, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e181d03 // mov v3.d[1], x8
	UBFX	$53, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d05 // mov v5.d[1], x8
	WORD $0x4e249c42 // mul v2.16b, v2.16b, v4.16b
	WORD $0x4e259c63 // mul v3.16b, v3.16b, v5.16b
	WORD $0x3cc04086 // ldur q6, [x4, #4]
	WORD $0x3cc14087 // ldur q7, [x4, #20]
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e86944c // sdot v12.4s, v2.16b, v6.16b
	WORD $0x4e87946c // sdot v12.4s, v3.16b, v7.16b
	LSR	$60, R5, R7
	LSLW	$1, R7, R7
	ADDW	$1, R7, R7
	WORD $0x4e040cf5 // dup v21.4s, w7
	WORD $0x4eb59594 // mla v20.4s, v12.4s, v21.4s
	MOVD	10(R3), R5
	UBFX	$0, R5, $8, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e081d02 // mov v2.d[0], x8
	UBFX	$32, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d04 // mov v4.d[0], x8
	UBFX	$8, R5, $8, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e181d02 // mov v2.d[1], x8
	UBFX	$39, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d04 // mov v4.d[1], x8
	UBFX	$16, R5, $8, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e081d03 // mov v3.d[0], x8
	UBFX	$46, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d05 // mov v5.d[0], x8
	UBFX	$24, R5, $8, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e181d03 // mov v3.d[1], x8
	UBFX	$53, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d05 // mov v5.d[1], x8
	WORD $0x4e249c42 // mul v2.16b, v2.16b, v4.16b
	WORD $0x4e259c63 // mul v3.16b, v3.16b, v5.16b
	WORD $0x3cc24086 // ldur q6, [x4, #36]
	WORD $0x3cc34087 // ldur q7, [x4, #52]
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e86944c // sdot v12.4s, v2.16b, v6.16b
	WORD $0x4e87946c // sdot v12.4s, v3.16b, v7.16b
	LSR	$60, R5, R7
	LSLW	$1, R7, R7
	ADDW	$1, R7, R7
	WORD $0x4e040cf5 // dup v21.4s, w7
	WORD $0x4eb59594 // mla v20.4s, v12.4s, v21.4s
	MOVD	18(R3), R5
	UBFX	$0, R5, $8, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e081d02 // mov v2.d[0], x8
	UBFX	$32, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d04 // mov v4.d[0], x8
	UBFX	$8, R5, $8, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e181d02 // mov v2.d[1], x8
	UBFX	$39, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d04 // mov v4.d[1], x8
	UBFX	$16, R5, $8, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e081d03 // mov v3.d[0], x8
	UBFX	$46, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d05 // mov v5.d[0], x8
	UBFX	$24, R5, $8, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e181d03 // mov v3.d[1], x8
	UBFX	$53, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d05 // mov v5.d[1], x8
	WORD $0x4e249c42 // mul v2.16b, v2.16b, v4.16b
	WORD $0x4e259c63 // mul v3.16b, v3.16b, v5.16b
	WORD $0x3cc44086 // ldur q6, [x4, #68]
	WORD $0x3cc54087 // ldur q7, [x4, #84]
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e86944c // sdot v12.4s, v2.16b, v6.16b
	WORD $0x4e87946c // sdot v12.4s, v3.16b, v7.16b
	LSR	$60, R5, R7
	LSLW	$1, R7, R7
	ADDW	$1, R7, R7
	WORD $0x4e040cf5 // dup v21.4s, w7
	WORD $0x4eb59594 // mla v20.4s, v12.4s, v21.4s
	MOVD	26(R3), R5
	UBFX	$0, R5, $8, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e081d02 // mov v2.d[0], x8
	UBFX	$32, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d04 // mov v4.d[0], x8
	UBFX	$8, R5, $8, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e181d02 // mov v2.d[1], x8
	UBFX	$39, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d04 // mov v4.d[1], x8
	UBFX	$16, R5, $8, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e081d03 // mov v3.d[0], x8
	UBFX	$46, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d05 // mov v5.d[0], x8
	UBFX	$24, R5, $8, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e181d03 // mov v3.d[1], x8
	UBFX	$53, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d05 // mov v5.d[1], x8
	WORD $0x4e249c42 // mul v2.16b, v2.16b, v4.16b
	WORD $0x4e259c63 // mul v3.16b, v3.16b, v5.16b
	WORD $0x3cc64086 // ldur q6, [x4, #100]
	WORD $0x3cc74087 // ldur q7, [x4, #116]
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e86944c // sdot v12.4s, v2.16b, v6.16b
	WORD $0x4e87946c // sdot v12.4s, v3.16b, v7.16b
	LSR	$60, R5, R7
	LSLW	$1, R7, R7
	ADDW	$1, R7, R7
	WORD $0x4e040cf5 // dup v21.4s, w7
	WORD $0x4eb59594 // mla v20.4s, v12.4s, v21.4s
	MOVD	34(R3), R5
	UBFX	$0, R5, $8, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e081d02 // mov v2.d[0], x8
	UBFX	$32, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d04 // mov v4.d[0], x8
	UBFX	$8, R5, $8, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e181d02 // mov v2.d[1], x8
	UBFX	$39, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d04 // mov v4.d[1], x8
	UBFX	$16, R5, $8, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e081d03 // mov v3.d[0], x8
	UBFX	$46, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d05 // mov v5.d[0], x8
	UBFX	$24, R5, $8, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e181d03 // mov v3.d[1], x8
	UBFX	$53, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d05 // mov v5.d[1], x8
	WORD $0x4e249c42 // mul v2.16b, v2.16b, v4.16b
	WORD $0x4e259c63 // mul v3.16b, v3.16b, v5.16b
	WORD $0x3cc84086 // ldur q6, [x4, #132]
	WORD $0x3cc94087 // ldur q7, [x4, #148]
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e86944c // sdot v12.4s, v2.16b, v6.16b
	WORD $0x4e87946c // sdot v12.4s, v3.16b, v7.16b
	LSR	$60, R5, R7
	LSLW	$1, R7, R7
	ADDW	$1, R7, R7
	WORD $0x4e040cf5 // dup v21.4s, w7
	WORD $0x4eb59594 // mla v20.4s, v12.4s, v21.4s
	MOVD	42(R3), R5
	UBFX	$0, R5, $8, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e081d02 // mov v2.d[0], x8
	UBFX	$32, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d04 // mov v4.d[0], x8
	UBFX	$8, R5, $8, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e181d02 // mov v2.d[1], x8
	UBFX	$39, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d04 // mov v4.d[1], x8
	UBFX	$16, R5, $8, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e081d03 // mov v3.d[0], x8
	UBFX	$46, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d05 // mov v5.d[0], x8
	UBFX	$24, R5, $8, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e181d03 // mov v3.d[1], x8
	UBFX	$53, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d05 // mov v5.d[1], x8
	WORD $0x4e249c42 // mul v2.16b, v2.16b, v4.16b
	WORD $0x4e259c63 // mul v3.16b, v3.16b, v5.16b
	WORD $0x3cca4086 // ldur q6, [x4, #164]
	WORD $0x3ccb4087 // ldur q7, [x4, #180]
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e86944c // sdot v12.4s, v2.16b, v6.16b
	WORD $0x4e87946c // sdot v12.4s, v3.16b, v7.16b
	LSR	$60, R5, R7
	LSLW	$1, R7, R7
	ADDW	$1, R7, R7
	WORD $0x4e040cf5 // dup v21.4s, w7
	WORD $0x4eb59594 // mla v20.4s, v12.4s, v21.4s
	MOVD	50(R3), R5
	UBFX	$0, R5, $8, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e081d02 // mov v2.d[0], x8
	UBFX	$32, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d04 // mov v4.d[0], x8
	UBFX	$8, R5, $8, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e181d02 // mov v2.d[1], x8
	UBFX	$39, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d04 // mov v4.d[1], x8
	UBFX	$16, R5, $8, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e081d03 // mov v3.d[0], x8
	UBFX	$46, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d05 // mov v5.d[0], x8
	UBFX	$24, R5, $8, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e181d03 // mov v3.d[1], x8
	UBFX	$53, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d05 // mov v5.d[1], x8
	WORD $0x4e249c42 // mul v2.16b, v2.16b, v4.16b
	WORD $0x4e259c63 // mul v3.16b, v3.16b, v5.16b
	WORD $0x3ccc4086 // ldur q6, [x4, #196]
	WORD $0x3ccd4087 // ldur q7, [x4, #212]
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e86944c // sdot v12.4s, v2.16b, v6.16b
	WORD $0x4e87946c // sdot v12.4s, v3.16b, v7.16b
	LSR	$60, R5, R7
	LSLW	$1, R7, R7
	ADDW	$1, R7, R7
	WORD $0x4e040cf5 // dup v21.4s, w7
	WORD $0x4eb59594 // mla v20.4s, v12.4s, v21.4s
	MOVD	58(R3), R5
	UBFX	$0, R5, $8, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e081d02 // mov v2.d[0], x8
	UBFX	$32, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d04 // mov v4.d[0], x8
	UBFX	$8, R5, $8, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e181d02 // mov v2.d[1], x8
	UBFX	$39, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d04 // mov v4.d[1], x8
	UBFX	$16, R5, $8, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e081d03 // mov v3.d[0], x8
	UBFX	$46, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d05 // mov v5.d[0], x8
	UBFX	$24, R5, $8, R7
	MOVD	(R12)(R7<<3), R8
	WORD $0x4e181d03 // mov v3.d[1], x8
	UBFX	$53, R5, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d05 // mov v5.d[1], x8
	WORD $0x4e249c42 // mul v2.16b, v2.16b, v4.16b
	WORD $0x4e259c63 // mul v3.16b, v3.16b, v5.16b
	WORD $0x3cce4086 // ldur q6, [x4, #228]
	WORD $0x3ccf4087 // ldur q7, [x4, #244]
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e86944c // sdot v12.4s, v2.16b, v6.16b
	WORD $0x4e87946c // sdot v12.4s, v3.16b, v7.16b
	LSR	$60, R5, R7
	LSLW	$1, R7, R7
	ADDW	$1, R7, R7
	WORD $0x4e040cf5 // dup v21.4s, w7
	WORD $0x4eb59594 // mla v20.4s, v12.4s, v21.4s
	WORD $0x4eb1ba94 // addv s20, v20.4s
	WORD $0x4e21da94 // scvtf v20.4s, v20.4s
	WORD $0x7c400079 // ldur h25, [x3, #0]
	WORD $0xbc40009a // ldur s26, [x4, #0]
	WORD $0x1ee24339 // fcvt s25, h25
	WORD $0x1e3a0b39 // fmul s25, s25, s26
	WORD $0x1e310b39 // fmul s25, s25, s17
	WORD $0x4f991280 // fmla v0.4s, v20.4s, v25.s[0]
	ADD	$66, R3, R3
	ADD	$292, R4, R4
	SUBW	$1, R1, R1
	CBNZW	R1, i2xblk
i2xreduce:
	WORD $0x6e20d400 // faddp v0.4s, v0.4s, v0.4s
	WORD $0x7e30d800 // faddp s0, v0.2s
	FMOVS	F0, (R2)
	RET
i2xoob:
	B	ovr_oob

DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+0(SB)/8, $0x808080808080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+8(SB)/8, $0x80808080808082b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+16(SB)/8, $0x808080808081919
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+24(SB)/8, $0x808080808082b08
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+32(SB)/8, $0x808080808082b2b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+40(SB)/8, $0x808080808190819
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+48(SB)/8, $0x808080808191908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+56(SB)/8, $0x8080808082b0808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+64(SB)/8, $0x8080808082b082b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+72(SB)/8, $0x8080808082b2b08
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+80(SB)/8, $0x8080808082b2b2b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+88(SB)/8, $0x808080819080819
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+96(SB)/8, $0x808080819081908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+104(SB)/8, $0x808080819190808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+112(SB)/8, $0x808080819192b08
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+120(SB)/8, $0x8080808192b0819
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+128(SB)/8, $0x8080808192b1908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+136(SB)/8, $0x80808082b080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+144(SB)/8, $0x80808082b08082b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+152(SB)/8, $0x80808082b082b2b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+160(SB)/8, $0x80808082b2b082b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+168(SB)/8, $0x808081908080819
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+176(SB)/8, $0x808081908081908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+184(SB)/8, $0x808081908190808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+192(SB)/8, $0x808081908191919
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+200(SB)/8, $0x808081919080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+208(SB)/8, $0x80808192b081908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+216(SB)/8, $0x80808192b192b08
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+224(SB)/8, $0x808082b08080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+232(SB)/8, $0x808082b0808082b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+240(SB)/8, $0x808082b082b082b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+248(SB)/8, $0x808082b2b08082b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+256(SB)/8, $0x808190808080819
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+264(SB)/8, $0x808190808081908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+272(SB)/8, $0x808190808190808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+280(SB)/8, $0x8081908082b0819
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+288(SB)/8, $0x8081908082b1908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+296(SB)/8, $0x808190819080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+304(SB)/8, $0x80819081908082b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+312(SB)/8, $0x808190819082b08
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+320(SB)/8, $0x8081908192b0808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+328(SB)/8, $0x80819082b080819
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+336(SB)/8, $0x80819082b081908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+344(SB)/8, $0x80819082b190808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+352(SB)/8, $0x80819082b2b1908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+360(SB)/8, $0x808191908080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+368(SB)/8, $0x80819190808082b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+376(SB)/8, $0x808191908082b08
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+384(SB)/8, $0x8081919082b0808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+392(SB)/8, $0x80819191908192b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+400(SB)/8, $0x8081919192b2b19
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+408(SB)/8, $0x80819192b080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+416(SB)/8, $0x80819192b190819
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+424(SB)/8, $0x808192b08082b19
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+432(SB)/8, $0x808192b08190808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+440(SB)/8, $0x808192b19080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+448(SB)/8, $0x808192b2b081908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+456(SB)/8, $0x808192b2b2b1908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+464(SB)/8, $0x8082b0808080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+472(SB)/8, $0x8082b0808081919
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+480(SB)/8, $0x8082b0808082b08
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+488(SB)/8, $0x8082b0808191908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+496(SB)/8, $0x8082b08082b2b08
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+504(SB)/8, $0x8082b0819080819
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+512(SB)/8, $0x8082b0819081908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+520(SB)/8, $0x8082b0819190808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+528(SB)/8, $0x8082b081919082b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+536(SB)/8, $0x8082b082b082b08
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+544(SB)/8, $0x8082b1908081908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+552(SB)/8, $0x8082b1919080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+560(SB)/8, $0x8082b2b0808082b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+568(SB)/8, $0x8082b2b08191908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+576(SB)/8, $0x819080808080819
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+584(SB)/8, $0x819080808081908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+592(SB)/8, $0x819080808190808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+600(SB)/8, $0x8190808082b0819
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+608(SB)/8, $0x819080819080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+616(SB)/8, $0x8190808192b0808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+624(SB)/8, $0x81908082b081908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+632(SB)/8, $0x81908082b190808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+640(SB)/8, $0x81908082b191919
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+648(SB)/8, $0x819081908080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+656(SB)/8, $0x819081908082b08
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+664(SB)/8, $0x8190819082b0808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+672(SB)/8, $0x819081919190808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+680(SB)/8, $0x819081919192b2b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+688(SB)/8, $0x81908192b080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+696(SB)/8, $0x819082b082b1908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+704(SB)/8, $0x819082b19081919
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+712(SB)/8, $0x819190808080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+720(SB)/8, $0x819190808082b08
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+728(SB)/8, $0x8191908082b0808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+736(SB)/8, $0x8191908082b1919
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+744(SB)/8, $0x819190819082b19
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+752(SB)/8, $0x81919082b080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+760(SB)/8, $0x819191908192b08
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+768(SB)/8, $0x8191919192b082b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+776(SB)/8, $0x819192b08080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+784(SB)/8, $0x819192b0819192b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+792(SB)/8, $0x8192b0808080819
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+800(SB)/8, $0x8192b0808081908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+808(SB)/8, $0x8192b0808190808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+816(SB)/8, $0x8192b0819080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+824(SB)/8, $0x8192b082b080819
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+832(SB)/8, $0x8192b1908080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+840(SB)/8, $0x8192b1908081919
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+848(SB)/8, $0x8192b192b2b0808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+856(SB)/8, $0x8192b2b19190819
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+864(SB)/8, $0x82b080808080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+872(SB)/8, $0x82b08080808082b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+880(SB)/8, $0x82b080808082b2b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+888(SB)/8, $0x82b080819081908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+896(SB)/8, $0x82b0808192b0819
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+904(SB)/8, $0x82b08082b080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+912(SB)/8, $0x82b08082b08082b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+920(SB)/8, $0x82b0819082b2b19
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+928(SB)/8, $0x82b081919082b08
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+936(SB)/8, $0x82b082b08080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+944(SB)/8, $0x82b082b0808082b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+952(SB)/8, $0x82b190808080819
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+960(SB)/8, $0x82b190808081908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+968(SB)/8, $0x82b190808190808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+976(SB)/8, $0x82b190819080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+984(SB)/8, $0x82b19081919192b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+992(SB)/8, $0x82b191908080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1000(SB)/8, $0x82b191919080819
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1008(SB)/8, $0x82b1919192b1908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1016(SB)/8, $0x82b192b2b190808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1024(SB)/8, $0x82b2b0808082b08
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1032(SB)/8, $0x82b2b08082b0808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1040(SB)/8, $0x82b2b082b191908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1048(SB)/8, $0x82b2b2b19081908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1056(SB)/8, $0x1908080808080819
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1064(SB)/8, $0x1908080808081908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1072(SB)/8, $0x1908080808190808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1080(SB)/8, $0x1908080808192b08
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1088(SB)/8, $0x19080808082b0819
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1096(SB)/8, $0x19080808082b1908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1104(SB)/8, $0x1908080819080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1112(SB)/8, $0x1908080819082b08
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1120(SB)/8, $0x190808081919192b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1128(SB)/8, $0x19080808192b0808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1136(SB)/8, $0x190808082b080819
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1144(SB)/8, $0x190808082b081908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1152(SB)/8, $0x190808082b190808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1160(SB)/8, $0x1908081908080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1168(SB)/8, $0x19080819082b0808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1176(SB)/8, $0x19080819192b0819
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1184(SB)/8, $0x190808192b080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1192(SB)/8, $0x190808192b081919
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1200(SB)/8, $0x1908082b08080819
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1208(SB)/8, $0x1908082b08190808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1216(SB)/8, $0x1908082b19082b08
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1224(SB)/8, $0x1908082b1919192b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1232(SB)/8, $0x1908082b192b2b08
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1240(SB)/8, $0x1908190808080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1248(SB)/8, $0x1908190808082b08
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1256(SB)/8, $0x19081908082b0808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1264(SB)/8, $0x190819082b080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1272(SB)/8, $0x190819082b192b19
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1280(SB)/8, $0x190819190819082b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1288(SB)/8, $0x19081919082b1908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1296(SB)/8, $0x1908192b08080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1304(SB)/8, $0x19082b0808080819
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1312(SB)/8, $0x19082b0808081908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1320(SB)/8, $0x19082b0808190808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1328(SB)/8, $0x19082b0819080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1336(SB)/8, $0x19082b0819081919
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1344(SB)/8, $0x19082b1908080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1352(SB)/8, $0x19082b1919192b08
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1360(SB)/8, $0x19082b19192b0819
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1368(SB)/8, $0x19082b192b08082b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1376(SB)/8, $0x19082b2b19081919
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1384(SB)/8, $0x19082b2b2b190808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1392(SB)/8, $0x1919080808080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1400(SB)/8, $0x1919080808082b08
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1408(SB)/8, $0x1919080808190819
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1416(SB)/8, $0x1919080808192b19
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1424(SB)/8, $0x19190808082b0808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1432(SB)/8, $0x191908082b080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1440(SB)/8, $0x191908082b082b08
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1448(SB)/8, $0x1919081908081908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1456(SB)/8, $0x191908191908082b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1464(SB)/8, $0x191908192b2b1908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1472(SB)/8, $0x1919082b2b190819
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1480(SB)/8, $0x191919082b190808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1488(SB)/8, $0x191919082b19082b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1496(SB)/8, $0x1919191908082b2b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1504(SB)/8, $0x1919192b08080819
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1512(SB)/8, $0x1919192b19191908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1520(SB)/8, $0x19192b0808080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1528(SB)/8, $0x19192b0808190819
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1536(SB)/8, $0x19192b0808192b19
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1544(SB)/8, $0x19192b08192b1908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1552(SB)/8, $0x19192b1919080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1560(SB)/8, $0x19192b2b08082b08
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1568(SB)/8, $0x192b080808081908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1576(SB)/8, $0x192b080808190808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1584(SB)/8, $0x192b080819080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1592(SB)/8, $0x192b0808192b2b08
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1600(SB)/8, $0x192b081908080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1608(SB)/8, $0x192b081919191919
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1616(SB)/8, $0x192b082b08192b08
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1624(SB)/8, $0x192b082b192b0808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1632(SB)/8, $0x192b190808080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1640(SB)/8, $0x192b190808081919
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1648(SB)/8, $0x192b191908190808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1656(SB)/8, $0x192b19190819082b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1664(SB)/8, $0x192b19192b081908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1672(SB)/8, $0x192b2b081908082b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1680(SB)/8, $0x2b08080808080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1688(SB)/8, $0x2b0808080808082b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1696(SB)/8, $0x2b08080808082b2b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1704(SB)/8, $0x2b08080819080819
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1712(SB)/8, $0x2b0808082b08082b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1720(SB)/8, $0x2b08081908081908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1728(SB)/8, $0x2b08081908192b08
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1736(SB)/8, $0x2b08081919080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1744(SB)/8, $0x2b08082b08190819
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1752(SB)/8, $0x2b08190808080819
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1760(SB)/8, $0x2b08190808081908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1768(SB)/8, $0x2b08190808190808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1776(SB)/8, $0x2b08190808191919
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1784(SB)/8, $0x2b08190819080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1792(SB)/8, $0x2b081908192b0808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1800(SB)/8, $0x2b08191908080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1808(SB)/8, $0x2b0819191908192b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1816(SB)/8, $0x2b0819192b191908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1824(SB)/8, $0x2b08192b08082b19
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1832(SB)/8, $0x2b08192b19080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1840(SB)/8, $0x2b08192b192b0808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1848(SB)/8, $0x2b082b080808082b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1856(SB)/8, $0x2b082b1908081908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1864(SB)/8, $0x2b082b2b08190819
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1872(SB)/8, $0x2b19080808081908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1880(SB)/8, $0x2b19080808190808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1888(SB)/8, $0x2b190808082b1908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1896(SB)/8, $0x2b19080819080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1904(SB)/8, $0x2b1908082b2b0819
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1912(SB)/8, $0x2b1908190819192b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1920(SB)/8, $0x2b1908192b080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1928(SB)/8, $0x2b19082b19081919
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1936(SB)/8, $0x2b19190808080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1944(SB)/8, $0x2b191908082b082b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1952(SB)/8, $0x2b19190819081908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1960(SB)/8, $0x2b19191919190819
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1968(SB)/8, $0x2b192b082b080819
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1976(SB)/8, $0x2b192b19082b0808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1984(SB)/8, $0x2b2b08080808082b
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+1992(SB)/8, $0x2b2b080819190808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2000(SB)/8, $0x2b2b08082b081919
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2008(SB)/8, $0x2b2b081908082b19
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2016(SB)/8, $0x2b2b082b08080808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2024(SB)/8, $0x2b2b190808192b08
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2032(SB)/8, $0x2b2b2b0819190808
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2040(SB)/8, $0x2b2b2b1908081908
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2048(SB)/8, $0x101010101010101
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2056(SB)/8, $0xff010101010101ff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2064(SB)/8, $0xff0101010101ff01
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2072(SB)/8, $0x10101010101ffff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2080(SB)/8, $0xff01010101ff0101
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2088(SB)/8, $0x101010101ff01ff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2096(SB)/8, $0x101010101ffff01
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2104(SB)/8, $0xff01010101ffffff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2112(SB)/8, $0xff010101ff010101
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2120(SB)/8, $0x1010101ff0101ff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2128(SB)/8, $0x1010101ff01ff01
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2136(SB)/8, $0xff010101ff01ffff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2144(SB)/8, $0x1010101ffff0101
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2152(SB)/8, $0xff010101ffff01ff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2160(SB)/8, $0xff010101ffffff01
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2168(SB)/8, $0x1010101ffffffff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2176(SB)/8, $0xff0101ff01010101
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2184(SB)/8, $0x10101ff010101ff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2192(SB)/8, $0x10101ff0101ff01
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2200(SB)/8, $0xff0101ff0101ffff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2208(SB)/8, $0x10101ff01ff0101
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2216(SB)/8, $0xff0101ff01ff01ff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2224(SB)/8, $0xff0101ff01ffff01
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2232(SB)/8, $0x10101ff01ffffff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2240(SB)/8, $0x10101ffff010101
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2248(SB)/8, $0xff0101ffff0101ff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2256(SB)/8, $0xff0101ffff01ff01
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2264(SB)/8, $0x10101ffff01ffff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2272(SB)/8, $0xff0101ffffff0101
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2280(SB)/8, $0x10101ffffff01ff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2288(SB)/8, $0x10101ffffffff01
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2296(SB)/8, $0xff0101ffffffffff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2304(SB)/8, $0xff01ff0101010101
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2312(SB)/8, $0x101ff01010101ff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2320(SB)/8, $0x101ff010101ff01
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2328(SB)/8, $0xff01ff010101ffff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2336(SB)/8, $0x101ff0101ff0101
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2344(SB)/8, $0xff01ff0101ff01ff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2352(SB)/8, $0xff01ff0101ffff01
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2360(SB)/8, $0x101ff0101ffffff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2368(SB)/8, $0x101ff01ff010101
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2376(SB)/8, $0xff01ff01ff0101ff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2384(SB)/8, $0xff01ff01ff01ff01
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2392(SB)/8, $0x101ff01ff01ffff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2400(SB)/8, $0xff01ff01ffff0101
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2408(SB)/8, $0x101ff01ffff01ff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2416(SB)/8, $0x101ff01ffffff01
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2424(SB)/8, $0xff01ff01ffffffff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2432(SB)/8, $0x101ffff01010101
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2440(SB)/8, $0xff01ffff010101ff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2448(SB)/8, $0xff01ffff0101ff01
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2456(SB)/8, $0x101ffff0101ffff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2464(SB)/8, $0xff01ffff01ff0101
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2472(SB)/8, $0x101ffff01ff01ff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2480(SB)/8, $0x101ffff01ffff01
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2488(SB)/8, $0xff01ffff01ffffff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2496(SB)/8, $0xff01ffffff010101
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2504(SB)/8, $0x101ffffff0101ff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2512(SB)/8, $0x101ffffff01ff01
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2520(SB)/8, $0xff01ffffff01ffff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2528(SB)/8, $0x101ffffffff0101
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2536(SB)/8, $0xff01ffffffff01ff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2544(SB)/8, $0xff01ffffffffff01
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2552(SB)/8, $0x101ffffffffffff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2560(SB)/8, $0xffff010101010101
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2568(SB)/8, $0x1ff0101010101ff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2576(SB)/8, $0x1ff01010101ff01
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2584(SB)/8, $0xffff01010101ffff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2592(SB)/8, $0x1ff010101ff0101
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2600(SB)/8, $0xffff010101ff01ff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2608(SB)/8, $0xffff010101ffff01
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2616(SB)/8, $0x1ff010101ffffff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2624(SB)/8, $0x1ff0101ff010101
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2632(SB)/8, $0xffff0101ff0101ff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2640(SB)/8, $0xffff0101ff01ff01
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2648(SB)/8, $0x1ff0101ff01ffff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2656(SB)/8, $0xffff0101ffff0101
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2664(SB)/8, $0x1ff0101ffff01ff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2672(SB)/8, $0x1ff0101ffffff01
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2680(SB)/8, $0xffff0101ffffffff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2688(SB)/8, $0x1ff01ff01010101
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2696(SB)/8, $0xffff01ff010101ff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2704(SB)/8, $0xffff01ff0101ff01
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2712(SB)/8, $0x1ff01ff0101ffff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2720(SB)/8, $0xffff01ff01ff0101
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2728(SB)/8, $0x1ff01ff01ff01ff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2736(SB)/8, $0x1ff01ff01ffff01
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2744(SB)/8, $0xffff01ff01ffffff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2752(SB)/8, $0xffff01ffff010101
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2760(SB)/8, $0x1ff01ffff0101ff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2768(SB)/8, $0x1ff01ffff01ff01
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2776(SB)/8, $0xffff01ffff01ffff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2784(SB)/8, $0x1ff01ffffff0101
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2792(SB)/8, $0xffff01ffffff01ff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2800(SB)/8, $0xffff01ffffffff01
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2808(SB)/8, $0x1ff01ffffffffff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2816(SB)/8, $0x1ffff0101010101
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2824(SB)/8, $0xffffff01010101ff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2832(SB)/8, $0xffffff010101ff01
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2840(SB)/8, $0x1ffff010101ffff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2848(SB)/8, $0xffffff0101ff0101
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2856(SB)/8, $0x1ffff0101ff01ff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2864(SB)/8, $0x1ffff0101ffff01
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2872(SB)/8, $0xffffff0101ffffff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2880(SB)/8, $0xffffff01ff010101
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2888(SB)/8, $0x1ffff01ff0101ff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2896(SB)/8, $0x1ffff01ff01ff01
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2904(SB)/8, $0xffffff01ff01ffff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2912(SB)/8, $0x1ffff01ffff0101
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2920(SB)/8, $0xffffff01ffff01ff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2928(SB)/8, $0xffffff01ffffff01
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2936(SB)/8, $0x1ffff01ffffffff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2944(SB)/8, $0xffffffff01010101
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2952(SB)/8, $0x1ffffff010101ff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2960(SB)/8, $0x1ffffff0101ff01
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2968(SB)/8, $0xffffffff0101ffff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2976(SB)/8, $0x1ffffff01ff0101
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2984(SB)/8, $0xffffffff01ff01ff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+2992(SB)/8, $0xffffffff01ffff01
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+3000(SB)/8, $0x1ffffff01ffffff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+3008(SB)/8, $0x1ffffffff010101
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+3016(SB)/8, $0xffffffffff0101ff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+3024(SB)/8, $0xffffffffff01ff01
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+3032(SB)/8, $0x1ffffffff01ffff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+3040(SB)/8, $0xffffffffffff0101
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+3048(SB)/8, $0x1ffffffffff01ff
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+3056(SB)/8, $0x1ffffffffffff01
DATA ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184+3064(SB)/8, $0xffffffffffffffff
GLOBL ·ovr_dbg_vec_dot_iq2_xxs_q8_K_dotprod_b3072_7eae82943aa7f184(SB), RODATA|NOPTR, $3072
