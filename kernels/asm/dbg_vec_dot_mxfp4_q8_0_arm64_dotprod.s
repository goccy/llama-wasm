// dbg_vec_dot_mxfp4_q8_0: mxfp4 x q8_0 dot, TBL table lookup and SDOT, two blocks per step.
	WORD $0x4f000400 // movi v0.4s, #0
	WORD $0x4f000401 // movi v1.4s, #0
	MOVW	l0+8(FP), R1
	LSRW	$5, R1, R1
	MOVD	l1+16(FP), R2
	ADD	$4, R2, R27
	CMP	R27, R21
	BLO	mx4oob
	ADD	R20, R2, R2
	CBZW	R1, mx4reduce
	MOVD	l3+32(FP), R3
	MOVD	l5+48(FP), R4
	MOVD	$17, R26
	MUL	R1, R26, R26
	ADD	R3, R26, R27
	CMP	R27, R21
	BLO	mx4oob
	MOVD	$34, R26
	MUL	R1, R26, R26
	ADD	R4, R26, R27
	CMP	R27, R21
	BLO	mx4oob
	ADD	R20, R3, R3
	ADD	R20, R4, R4
	MOVD	$·ovr_dbg_vec_dot_mxfp4_q8_0_dotprod_b16_adf76b672d47eb7f(SB), R5
	WORD $0x3cc000b2 // ldur q18, [x5, #0]
	WORD $0x4f00e5f0 // movi v16.16b, #15
mx4loop2:
	CMPW	$2, R1
	BLT	mx4tail
	WORD $0x3cc01062 // ldur q2, [x3, #1]
	WORD $0x3cc02088 // ldur q8, [x4, #2]
	WORD $0x3cc1208a // ldur q10, [x4, #18]
	WORD $0x4e301c44 // and v4.16b, v2.16b, v16.16b
	WORD $0x6f0c0446 // ushr v6.16b, v2.16b, #4
	WORD $0x4e040244 // tbl v4.16b, {v18.16b}, v4.16b
	WORD $0x4e060246 // tbl v6.16b, {v18.16b}, v6.16b
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e88948c // sdot v12.4s, v4.16b, v8.16b
	WORD $0x4e8a94cc // sdot v12.4s, v6.16b, v10.16b
	MOVBU	0(R3), R5
	SUBW	$1, R5, R6
	LSLW	$23, R6, R6
	MOVW	$0x00200000, R7
	LSLW	R5, R7, R7
	CMPW	$2, R5
	CSELW	LO, R7, R6, R6
	WORD $0x1e2700ce // fmov s14, w6
	WORD $0x7c400082 // ldur h2, [x4, #0]
	WORD $0x1ee24042 // fcvt s2, h2
	WORD $0x1e2209ce // fmul s14, s14, s2
	WORD $0x4e21d98c // scvtf v12.4s, v12.4s
	WORD $0x4f8e1180 // fmla v0.4s, v12.4s, v14.s[0]
	WORD $0x3cc12063 // ldur q3, [x3, #18]
	WORD $0x3cc24089 // ldur q9, [x4, #36]
	WORD $0x3cc3408b // ldur q11, [x4, #52]
	WORD $0x4e301c65 // and v5.16b, v3.16b, v16.16b
	WORD $0x6f0c0467 // ushr v7.16b, v3.16b, #4
	WORD $0x4e050245 // tbl v5.16b, {v18.16b}, v5.16b
	WORD $0x4e070247 // tbl v7.16b, {v18.16b}, v7.16b
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4e8994ad // sdot v13.4s, v5.16b, v9.16b
	WORD $0x4e8b94ed // sdot v13.4s, v7.16b, v11.16b
	MOVBU	17(R3), R5
	SUBW	$1, R5, R6
	LSLW	$23, R6, R6
	MOVW	$0x00200000, R7
	LSLW	R5, R7, R7
	CMPW	$2, R5
	CSELW	LO, R7, R6, R6
	WORD $0x1e2700cf // fmov s15, w6
	WORD $0x7c422083 // ldur h3, [x4, #34]
	WORD $0x1ee24063 // fcvt s3, h3
	WORD $0x1e2309ef // fmul s15, s15, s3
	WORD $0x4e21d9ad // scvtf v13.4s, v13.4s
	WORD $0x4f8f11a1 // fmla v1.4s, v13.4s, v15.s[0]
	ADD	$34, R3, R3
	ADD	$68, R4, R4
	SUBW	$2, R1, R1
	B	mx4loop2
mx4tail:
	CBZW	R1, mx4reduce
	WORD $0x3cc01062 // ldur q2, [x3, #1]
	WORD $0x3cc02088 // ldur q8, [x4, #2]
	WORD $0x3cc1208a // ldur q10, [x4, #18]
	WORD $0x4e301c44 // and v4.16b, v2.16b, v16.16b
	WORD $0x6f0c0446 // ushr v6.16b, v2.16b, #4
	WORD $0x4e040244 // tbl v4.16b, {v18.16b}, v4.16b
	WORD $0x4e060246 // tbl v6.16b, {v18.16b}, v6.16b
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e88948c // sdot v12.4s, v4.16b, v8.16b
	WORD $0x4e8a94cc // sdot v12.4s, v6.16b, v10.16b
	MOVBU	0(R3), R5
	SUBW	$1, R5, R6
	LSLW	$23, R6, R6
	MOVW	$0x00200000, R7
	LSLW	R5, R7, R7
	CMPW	$2, R5
	CSELW	LO, R7, R6, R6
	WORD $0x1e2700ce // fmov s14, w6
	WORD $0x7c400082 // ldur h2, [x4, #0]
	WORD $0x1ee24042 // fcvt s2, h2
	WORD $0x1e2209ce // fmul s14, s14, s2
	WORD $0x4e21d98c // scvtf v12.4s, v12.4s
	WORD $0x4f8e1180 // fmla v0.4s, v12.4s, v14.s[0]
mx4reduce:
	WORD $0x4e21d400 // fadd v0.4s, v0.4s, v1.4s
	WORD $0x6e20d400 // faddp v0.4s, v0.4s, v0.4s
	WORD $0x7e30d800 // faddp s0, v0.2s
	FMOVS	F0, (R2)
	RET
mx4oob:
	B	ovr_oob

DATA ·ovr_dbg_vec_dot_mxfp4_q8_0_dotprod_b16_adf76b672d47eb7f+0(SB)/8, $0xc08060403020100
DATA ·ovr_dbg_vec_dot_mxfp4_q8_0_dotprod_b16_adf76b672d47eb7f+8(SB)/8, $0xf4f8fafcfdfeff00
GLOBL ·ovr_dbg_vec_dot_mxfp4_q8_0_dotprod_b16_adf76b672d47eb7f(SB), RODATA|NOPTR, $16
