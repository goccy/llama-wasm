// dbg_vec_dot_iq4_nl_q8_0: iq4_nl x q8_0 dot, TBL kvalues lookup and SDOT, two blocks per step.
	WORD $0x4f000400 // movi v0.4s, #0
	WORD $0x4f000401 // movi v1.4s, #0
	MOVW	l0+8(FP), R1
	LSRW	$5, R1, R1
	MOVD	l1+16(FP), R2
	ADD	$4, R2, R27
	CMP	R27, R21
	BLO	iq4oob
	ADD	R20, R2, R2
	CBZW	R1, iq4reduce
	MOVD	l3+32(FP), R3
	MOVD	l5+48(FP), R4
	MOVD	$18, R26
	MUL	R1, R26, R26
	ADD	R3, R26, R27
	CMP	R27, R21
	BLO	iq4oob
	MOVD	$34, R26
	MUL	R1, R26, R26
	ADD	R4, R26, R27
	CMP	R27, R21
	BLO	iq4oob
	ADD	R20, R3, R3
	ADD	R20, R4, R4
	MOVD	$·ovr_dbg_vec_dot_iq4_nl_q8_0_dotprod_b16_8198adbfcfddeaf6010d192635455971(SB), R5
	WORD $0x3cc000b2 // ldur q18, [x5, #0]
	WORD $0x4f00e5f0 // movi v16.16b, #15
iq4loop2:
	CMPW	$2, R1
	BLT	iq4tail
	WORD $0x3cc02062 // ldur q2, [x3, #2]
	WORD $0x3cc02088 // ldur q8, [x4, #2]
	WORD $0x3cc1208a // ldur q10, [x4, #18]
	WORD $0x4e301c44 // and v4.16b, v2.16b, v16.16b
	WORD $0x6f0c0446 // ushr v6.16b, v2.16b, #4
	WORD $0x4e040244 // tbl v4.16b, {v18.16b}, v4.16b
	WORD $0x4e060246 // tbl v6.16b, {v18.16b}, v6.16b
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e88948c // sdot v12.4s, v4.16b, v8.16b
	WORD $0x4e8a94cc // sdot v12.4s, v6.16b, v10.16b
	WORD $0x7c40006e // ldur h14, [x3, #0]
	WORD $0x7c400082 // ldur h2, [x4, #0]
	WORD $0x1ee241ce // fcvt s14, h14
	WORD $0x1ee24042 // fcvt s2, h2
	WORD $0x1e2209ce // fmul s14, s14, s2
	WORD $0x4e21d98c // scvtf v12.4s, v12.4s
	WORD $0x4f8e1180 // fmla v0.4s, v12.4s, v14.s[0]
	WORD $0x3cc14063 // ldur q3, [x3, #20]
	WORD $0x3cc24089 // ldur q9, [x4, #36]
	WORD $0x3cc3408b // ldur q11, [x4, #52]
	WORD $0x4e301c65 // and v5.16b, v3.16b, v16.16b
	WORD $0x6f0c0467 // ushr v7.16b, v3.16b, #4
	WORD $0x4e050245 // tbl v5.16b, {v18.16b}, v5.16b
	WORD $0x4e070247 // tbl v7.16b, {v18.16b}, v7.16b
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e8994ad // sdot v13.4s, v5.16b, v9.16b
	WORD $0x4e8b94ed // sdot v13.4s, v7.16b, v11.16b
	WORD $0x7c41206f // ldur h15, [x3, #18]
	WORD $0x7c422083 // ldur h3, [x4, #34]
	WORD $0x1ee241ef // fcvt s15, h15
	WORD $0x1ee24063 // fcvt s3, h3
	WORD $0x1e2309ef // fmul s15, s15, s3
	WORD $0x4e21d9ad // scvtf v13.4s, v13.4s
	WORD $0x4f8f11a1 // fmla v1.4s, v13.4s, v15.s[0]
	ADD	$36, R3, R3
	ADD	$68, R4, R4
	SUBW	$2, R1, R1
	B	iq4loop2
iq4tail:
	CBZW	R1, iq4reduce
	WORD $0x3cc02062 // ldur q2, [x3, #2]
	WORD $0x3cc02088 // ldur q8, [x4, #2]
	WORD $0x3cc1208a // ldur q10, [x4, #18]
	WORD $0x4e301c44 // and v4.16b, v2.16b, v16.16b
	WORD $0x6f0c0446 // ushr v6.16b, v2.16b, #4
	WORD $0x4e040244 // tbl v4.16b, {v18.16b}, v4.16b
	WORD $0x4e060246 // tbl v6.16b, {v18.16b}, v6.16b
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e88948c // sdot v12.4s, v4.16b, v8.16b
	WORD $0x4e8a94cc // sdot v12.4s, v6.16b, v10.16b
	WORD $0x7c40006e // ldur h14, [x3, #0]
	WORD $0x7c400082 // ldur h2, [x4, #0]
	WORD $0x1ee241ce // fcvt s14, h14
	WORD $0x1ee24042 // fcvt s2, h2
	WORD $0x1e2209ce // fmul s14, s14, s2
	WORD $0x4e21d98c // scvtf v12.4s, v12.4s
	WORD $0x4f8e1180 // fmla v0.4s, v12.4s, v14.s[0]
iq4reduce:
	WORD $0x4e21d400 // fadd v0.4s, v0.4s, v1.4s
	WORD $0x6e20d400 // faddp v0.4s, v0.4s, v0.4s
	WORD $0x7e30d800 // faddp s0, v0.2s
	FMOVS	F0, (R2)
	RET
iq4oob:
	B	ovr_oob

DATA ·ovr_dbg_vec_dot_iq4_nl_q8_0_dotprod_b16_8198adbfcfddeaf6010d192635455971+0(SB)/8, $0xf6eaddcfbfad9881
DATA ·ovr_dbg_vec_dot_iq4_nl_q8_0_dotprod_b16_8198adbfcfddeaf6010d192635455971+8(SB)/8, $0x7159453526190d01
GLOBL ·ovr_dbg_vec_dot_iq4_nl_q8_0_dotprod_b16_8198adbfcfddeaf6010d192635455971(SB), RODATA|NOPTR, $16
