// dbg_vec_dot_q5_0_q8_0: q5_0 x q8_0 dot, two blocks per step via TBL/CMTST fifth bits and SDOT.
	WORD $0x4f000400 // movi v0.4s, #0
	WORD $0x4f000401 // movi v1.4s, #0
	MOVW	l0+8(FP), R1
	LSRW	$5, R1, R1
	MOVD	l1+16(FP), R2
	ADD	$4, R2, R27
	CMP	R27, R21
	BLO	q5oob
	ADD	R20, R2, R2
	CBZW	R1, q5reduce
	MOVD	l3+32(FP), R3
	MOVD	l5+48(FP), R4
	MOVD	$22, R26
	MUL	R1, R26, R26
	ADD	R3, R26, R27
	CMP	R27, R21
	BLO	q5oob
	MOVD	$34, R26
	MUL	R1, R26, R26
	ADD	R4, R26, R27
	CMP	R27, R21
	BLO	q5oob
	ADD	R20, R3, R3
	ADD	R20, R4, R4
	MOVD	$·ovr_dbg_vec_dot_q5_0_q8_0_dotprod_b48_c52ebbbbfeb423cf(SB), R5
	VLD1	(R5), [V18.B16, V19.B16, V20.B16]
	WORD $0x4f00e5f0 // movi v16.16b, #15
	WORD $0x4f00e611 // movi v17.16b, #16
q5loop2:
	CMPW	$2, R1
	BLT	q5tail
	WORD $0x3cc06062 // ldur q2, [x3, #6]
	WORD $0xbc402064 // ldur s4, [x3, #2]
	WORD $0x3cc0208e // ldur q14, [x4, #2]
	WORD $0x3cc12095 // ldur q21, [x4, #18]
	WORD $0x4e301c46 // and v6.16b, v2.16b, v16.16b
	WORD $0x6f0c0448 // ushr v8.16b, v2.16b, #4
	WORD $0x4e12008a // tbl v10.16b, {v4.16b}, v18.16b
	WORD $0x4e13008c // tbl v12.16b, {v4.16b}, v19.16b
	WORD $0x4e348d4a // cmtst v10.16b, v10.16b, v20.16b
	WORD $0x4e348d8c // cmtst v12.16b, v12.16b, v20.16b
	WORD $0x4e6a1e2a // bic v10.16b, v17.16b, v10.16b
	WORD $0x4e6c1e2c // bic v12.16b, v17.16b, v12.16b
	WORD $0x6e2a84c6 // sub v6.16b, v6.16b, v10.16b
	WORD $0x6e2c8508 // sub v8.16b, v8.16b, v12.16b
	WORD $0x4f000417 // movi v23.4s, #0
	WORD $0x4e8e94d7 // sdot v23.4s, v6.16b, v14.16b
	WORD $0x4e959517 // sdot v23.4s, v8.16b, v21.16b
	WORD $0x7c400079 // ldur h25, [x3, #0]
	WORD $0x7c400082 // ldur h2, [x4, #0]
	WORD $0x1ee24339 // fcvt s25, h25
	WORD $0x1ee24042 // fcvt s2, h2
	WORD $0x1e220b39 // fmul s25, s25, s2
	WORD $0x4e21daf7 // scvtf v23.4s, v23.4s
	WORD $0x4f9912e0 // fmla v0.4s, v23.4s, v25.s[0]
	WORD $0x3cc1c063 // ldur q3, [x3, #28]
	WORD $0xbc418065 // ldur s5, [x3, #24]
	WORD $0x3cc2408f // ldur q15, [x4, #36]
	WORD $0x3cc34096 // ldur q22, [x4, #52]
	WORD $0x4e301c67 // and v7.16b, v3.16b, v16.16b
	WORD $0x6f0c0469 // ushr v9.16b, v3.16b, #4
	WORD $0x4e1200ab // tbl v11.16b, {v5.16b}, v18.16b
	WORD $0x4e1300ad // tbl v13.16b, {v5.16b}, v19.16b
	WORD $0x4e348d6b // cmtst v11.16b, v11.16b, v20.16b
	WORD $0x4e348dad // cmtst v13.16b, v13.16b, v20.16b
	WORD $0x4e6b1e2b // bic v11.16b, v17.16b, v11.16b
	WORD $0x4e6d1e2d // bic v13.16b, v17.16b, v13.16b
	WORD $0x6e2b84e7 // sub v7.16b, v7.16b, v11.16b
	WORD $0x6e2d8529 // sub v9.16b, v9.16b, v13.16b
	WORD $0x4f000418 // movi v24.4s, #0
	WORD $0x4e8f94f8 // sdot v24.4s, v7.16b, v15.16b
	WORD $0x4e969538 // sdot v24.4s, v9.16b, v22.16b
	WORD $0x7c41607a // ldur h26, [x3, #22]
	WORD $0x7c422083 // ldur h3, [x4, #34]
	WORD $0x1ee2435a // fcvt s26, h26
	WORD $0x1ee24063 // fcvt s3, h3
	WORD $0x1e230b5a // fmul s26, s26, s3
	WORD $0x4e21db18 // scvtf v24.4s, v24.4s
	WORD $0x4f9a1301 // fmla v1.4s, v24.4s, v26.s[0]
	ADD	$44, R3, R3
	ADD	$68, R4, R4
	SUBW	$2, R1, R1
	B	q5loop2
q5tail:
	CBZW	R1, q5reduce
	WORD $0x3cc06062 // ldur q2, [x3, #6]
	WORD $0xbc402064 // ldur s4, [x3, #2]
	WORD $0x3cc0208e // ldur q14, [x4, #2]
	WORD $0x3cc12095 // ldur q21, [x4, #18]
	WORD $0x4e301c46 // and v6.16b, v2.16b, v16.16b
	WORD $0x6f0c0448 // ushr v8.16b, v2.16b, #4
	WORD $0x4e12008a // tbl v10.16b, {v4.16b}, v18.16b
	WORD $0x4e13008c // tbl v12.16b, {v4.16b}, v19.16b
	WORD $0x4e348d4a // cmtst v10.16b, v10.16b, v20.16b
	WORD $0x4e348d8c // cmtst v12.16b, v12.16b, v20.16b
	WORD $0x4e6a1e2a // bic v10.16b, v17.16b, v10.16b
	WORD $0x4e6c1e2c // bic v12.16b, v17.16b, v12.16b
	WORD $0x6e2a84c6 // sub v6.16b, v6.16b, v10.16b
	WORD $0x6e2c8508 // sub v8.16b, v8.16b, v12.16b
	WORD $0x4f000417 // movi v23.4s, #0
	WORD $0x4e8e94d7 // sdot v23.4s, v6.16b, v14.16b
	WORD $0x4e959517 // sdot v23.4s, v8.16b, v21.16b
	WORD $0x7c400079 // ldur h25, [x3, #0]
	WORD $0x7c400082 // ldur h2, [x4, #0]
	WORD $0x1ee24339 // fcvt s25, h25
	WORD $0x1ee24042 // fcvt s2, h2
	WORD $0x1e220b39 // fmul s25, s25, s2
	WORD $0x4e21daf7 // scvtf v23.4s, v23.4s
	WORD $0x4f9912e0 // fmla v0.4s, v23.4s, v25.s[0]
q5reduce:
	WORD $0x4e21d400 // fadd v0.4s, v0.4s, v1.4s
	WORD $0x6e20d400 // faddp v0.4s, v0.4s, v0.4s
	WORD $0x7e30d800 // faddp s0, v0.2s
	FMOVS	F0, (R2)
	RET
q5oob:
	B	ovr_oob

DATA ·ovr_dbg_vec_dot_q5_0_q8_0_dotprod_b48_c52ebbbbfeb423cf+0(SB)/8, $0x0
DATA ·ovr_dbg_vec_dot_q5_0_q8_0_dotprod_b48_c52ebbbbfeb423cf+8(SB)/8, $0x101010101010101
DATA ·ovr_dbg_vec_dot_q5_0_q8_0_dotprod_b48_c52ebbbbfeb423cf+16(SB)/8, $0x202020202020202
DATA ·ovr_dbg_vec_dot_q5_0_q8_0_dotprod_b48_c52ebbbbfeb423cf+24(SB)/8, $0x303030303030303
DATA ·ovr_dbg_vec_dot_q5_0_q8_0_dotprod_b48_c52ebbbbfeb423cf+32(SB)/8, $0x8040201008040201
DATA ·ovr_dbg_vec_dot_q5_0_q8_0_dotprod_b48_c52ebbbbfeb423cf+40(SB)/8, $0x8040201008040201
GLOBL ·ovr_dbg_vec_dot_q5_0_q8_0_dotprod_b48_c52ebbbbfeb423cf(SB), RODATA|NOPTR, $48
