// dbg_vec_dot_q5_1_q8_1: q5_1 x q8_1 dot, SDOT on unsigned quants plus the block min term, two blocks per step.
	WORD $0x4f000400 // movi v0.4s, #0
	WORD $0x4f000401 // movi v1.4s, #0
	WORD $0x4f00041e // movi v30.4s, #0
	MOVW	l0+8(FP), R1
	LSRW	$5, R1, R1
	MOVD	l1+16(FP), R2
	ADD	$4, R2, R27
	CMP	R27, R21
	BLO	q51oob
	ADD	R20, R2, R2
	CBZW	R1, q51reduce
	MOVD	l3+32(FP), R3
	MOVD	l5+48(FP), R4
	MOVD	$24, R26
	MUL	R1, R26, R26
	ADD	R3, R26, R27
	CMP	R27, R21
	BLO	q51oob
	MOVD	$36, R26
	MUL	R1, R26, R26
	ADD	R4, R26, R27
	CMP	R27, R21
	BLO	q51oob
	ADD	R20, R3, R3
	ADD	R20, R4, R4
	MOVD	$·ovr_dbg_vec_dot_q5_1_q8_1_dotprod_b48_c52ebbbbfeb423cf(SB), R5
	VLD1	(R5), [V18.B16, V19.B16, V20.B16]
	WORD $0x4f00e611 // movi v17.16b, #16
	WORD $0x4f00e5f0 // movi v16.16b, #15
q51loop2:
	CMPW	$2, R1
	BLT	q51tail
	WORD $0x3cc08062 // ldur q2, [x3, #8]
	WORD $0x3cc0408c // ldur q12, [x4, #4]
	WORD $0x3cc1408e // ldur q14, [x4, #20]
	WORD $0x4e301c46 // and v6.16b, v2.16b, v16.16b
	WORD $0x6f0c0448 // ushr v8.16b, v2.16b, #4
	WORD $0xbc404064 // ldur s4, [x3, #4]
	WORD $0x4e12008a // tbl v10.16b, {v4.16b}, v18.16b
	WORD $0x4e348d4a // cmtst v10.16b, v10.16b, v20.16b
	WORD $0x4e311d4a // and v10.16b, v10.16b, v17.16b
	WORD $0x4eaa1cc6 // orr v6.16b, v6.16b, v10.16b
	WORD $0x4e13008a // tbl v10.16b, {v4.16b}, v19.16b
	WORD $0x4e348d4a // cmtst v10.16b, v10.16b, v20.16b
	WORD $0x4e311d4a // and v10.16b, v10.16b, v17.16b
	WORD $0x4eaa1d08 // orr v8.16b, v8.16b, v10.16b
	WORD $0x4f000415 // movi v21.4s, #0
	WORD $0x4e8c94d5 // sdot v21.4s, v6.16b, v12.16b
	WORD $0x4e8e9515 // sdot v21.4s, v8.16b, v14.16b
	WORD $0x7c400077 // ldur h23, [x3, #0]
	WORD $0x7c400082 // ldur h2, [x4, #0]
	WORD $0x1ee242f7 // fcvt s23, h23
	WORD $0x1ee24042 // fcvt s2, h2
	WORD $0x1e220af7 // fmul s23, s23, s2
	WORD $0x4e21dab5 // scvtf v21.4s, v21.4s
	WORD $0x4f9712a0 // fmla v0.4s, v21.4s, v23.s[0]
	WORD $0x7c402077 // ldur h23, [x3, #2]
	WORD $0x7c402082 // ldur h2, [x4, #2]
	WORD $0x1ee242f7 // fcvt s23, h23
	WORD $0x1ee24042 // fcvt s2, h2
	WORD $0x1e220af7 // fmul s23, s23, s2
	WORD $0x1e372bde // fadd s30, s30, s23
	WORD $0x3cc20063 // ldur q3, [x3, #32]
	WORD $0x3cc2808d // ldur q13, [x4, #40]
	WORD $0x3cc3808f // ldur q15, [x4, #56]
	WORD $0x4e301c67 // and v7.16b, v3.16b, v16.16b
	WORD $0x6f0c0469 // ushr v9.16b, v3.16b, #4
	WORD $0xbc41c065 // ldur s5, [x3, #28]
	WORD $0x4e1200ab // tbl v11.16b, {v5.16b}, v18.16b
	WORD $0x4e348d6b // cmtst v11.16b, v11.16b, v20.16b
	WORD $0x4e311d6b // and v11.16b, v11.16b, v17.16b
	WORD $0x4eab1ce7 // orr v7.16b, v7.16b, v11.16b
	WORD $0x4e1300ab // tbl v11.16b, {v5.16b}, v19.16b
	WORD $0x4e348d6b // cmtst v11.16b, v11.16b, v20.16b
	WORD $0x4e311d6b // and v11.16b, v11.16b, v17.16b
	WORD $0x4eab1d29 // orr v9.16b, v9.16b, v11.16b
	WORD $0x4f000416 // movi v22.4s, #0
	WORD $0x4e8d94f6 // sdot v22.4s, v7.16b, v13.16b
	WORD $0x4e8f9536 // sdot v22.4s, v9.16b, v15.16b
	WORD $0x7c418078 // ldur h24, [x3, #24]
	WORD $0x7c424083 // ldur h3, [x4, #36]
	WORD $0x1ee24318 // fcvt s24, h24
	WORD $0x1ee24063 // fcvt s3, h3
	WORD $0x1e230b18 // fmul s24, s24, s3
	WORD $0x4e21dad6 // scvtf v22.4s, v22.4s
	WORD $0x4f9812c1 // fmla v1.4s, v22.4s, v24.s[0]
	WORD $0x7c41a078 // ldur h24, [x3, #26]
	WORD $0x7c426083 // ldur h3, [x4, #38]
	WORD $0x1ee24318 // fcvt s24, h24
	WORD $0x1ee24063 // fcvt s3, h3
	WORD $0x1e230b18 // fmul s24, s24, s3
	WORD $0x1e382bde // fadd s30, s30, s24
	ADD	$48, R3, R3
	ADD	$72, R4, R4
	SUBW	$2, R1, R1
	B	q51loop2
q51tail:
	CBZW	R1, q51reduce
	WORD $0x3cc08062 // ldur q2, [x3, #8]
	WORD $0x3cc0408c // ldur q12, [x4, #4]
	WORD $0x3cc1408e // ldur q14, [x4, #20]
	WORD $0x4e301c46 // and v6.16b, v2.16b, v16.16b
	WORD $0x6f0c0448 // ushr v8.16b, v2.16b, #4
	WORD $0xbc404064 // ldur s4, [x3, #4]
	WORD $0x4e12008a // tbl v10.16b, {v4.16b}, v18.16b
	WORD $0x4e348d4a // cmtst v10.16b, v10.16b, v20.16b
	WORD $0x4e311d4a // and v10.16b, v10.16b, v17.16b
	WORD $0x4eaa1cc6 // orr v6.16b, v6.16b, v10.16b
	WORD $0x4e13008a // tbl v10.16b, {v4.16b}, v19.16b
	WORD $0x4e348d4a // cmtst v10.16b, v10.16b, v20.16b
	WORD $0x4e311d4a // and v10.16b, v10.16b, v17.16b
	WORD $0x4eaa1d08 // orr v8.16b, v8.16b, v10.16b
	WORD $0x4f000415 // movi v21.4s, #0
	WORD $0x4e8c94d5 // sdot v21.4s, v6.16b, v12.16b
	WORD $0x4e8e9515 // sdot v21.4s, v8.16b, v14.16b
	WORD $0x7c400077 // ldur h23, [x3, #0]
	WORD $0x7c400082 // ldur h2, [x4, #0]
	WORD $0x1ee242f7 // fcvt s23, h23
	WORD $0x1ee24042 // fcvt s2, h2
	WORD $0x1e220af7 // fmul s23, s23, s2
	WORD $0x4e21dab5 // scvtf v21.4s, v21.4s
	WORD $0x4f9712a0 // fmla v0.4s, v21.4s, v23.s[0]
	WORD $0x7c402077 // ldur h23, [x3, #2]
	WORD $0x7c402082 // ldur h2, [x4, #2]
	WORD $0x1ee242f7 // fcvt s23, h23
	WORD $0x1ee24042 // fcvt s2, h2
	WORD $0x1e220af7 // fmul s23, s23, s2
	WORD $0x1e372bde // fadd s30, s30, s23
q51reduce:
	WORD $0x4e21d400 // fadd v0.4s, v0.4s, v1.4s
	WORD $0x4f00041f // movi v31.4s, #0
	WORD $0x6e0407df // mov v31.s[0], v30.s[0]
	WORD $0x4e3fd400 // fadd v0.4s, v0.4s, v31.4s
	WORD $0x6e20d400 // faddp v0.4s, v0.4s, v0.4s
	WORD $0x7e30d800 // faddp s0, v0.2s
	FMOVS	F0, (R2)
	RET
q51oob:
	B	ovr_oob

DATA ·ovr_dbg_vec_dot_q5_1_q8_1_dotprod_b48_c52ebbbbfeb423cf+0(SB)/8, $0x0
DATA ·ovr_dbg_vec_dot_q5_1_q8_1_dotprod_b48_c52ebbbbfeb423cf+8(SB)/8, $0x101010101010101
DATA ·ovr_dbg_vec_dot_q5_1_q8_1_dotprod_b48_c52ebbbbfeb423cf+16(SB)/8, $0x202020202020202
DATA ·ovr_dbg_vec_dot_q5_1_q8_1_dotprod_b48_c52ebbbbfeb423cf+24(SB)/8, $0x303030303030303
DATA ·ovr_dbg_vec_dot_q5_1_q8_1_dotprod_b48_c52ebbbbfeb423cf+32(SB)/8, $0x8040201008040201
DATA ·ovr_dbg_vec_dot_q5_1_q8_1_dotprod_b48_c52ebbbbfeb423cf+40(SB)/8, $0x8040201008040201
GLOBL ·ovr_dbg_vec_dot_q5_1_q8_1_dotprod_b48_c52ebbbbfeb423cf(SB), RODATA|NOPTR, $48
