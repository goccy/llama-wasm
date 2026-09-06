// dbg_vec_dot_q2_0_q8_0: q2_0 x q8_0 dot, 2-bit fields spread with TBL/USHL, SDOT per activation block.
	WORD $0x4f000400 // movi v0.4s, #0
	MOVW	l0+8(FP), R1
	LSRW	$6, R1, R1
	MOVD	l1+16(FP), R2
	ADD	$4, R2, R27
	CMP	R27, R21
	BLO	q2oob
	ADD	R20, R2, R2
	CBZW	R1, q2reduce
	MOVD	l3+32(FP), R3
	MOVD	l5+48(FP), R4
	MOVD	$18, R26
	MUL	R1, R26, R26
	ADD	R3, R26, R27
	CMP	R27, R21
	BLO	q2oob
	MOVD	$68, R26
	MUL	R1, R26, R26
	ADD	R4, R26, R27
	CMP	R27, R21
	BLO	q2oob
	ADD	R20, R3, R3
	ADD	R20, R4, R4
	MOVD	$·ovr_dbg_vec_dot_q2_0_q8_0_dotprod_b128_4296f77920d379e9(SB), R12
	WORD $0x3cc50192 // ldur q18, [x12, #80]
	WORD $0x3cc60193 // ldur q19, [x12, #96]
	WORD $0x3cc70190 // ldur q16, [x12, #112]
	WORD $0x4f00e431 // movi v17.16b, #1
q2blk:
	WORD $0x7c400076 // ldur h22, [x3, #0]
	WORD $0x1ee242d6 // fcvt s22, h22
	WORD $0xfc402062 // ldur d2, [x3, #2]
	WORD $0x4e080442 // dup v2.2d, v2.d[0]
	WORD $0x4e120044 // tbl v4.16b, {v2.16b}, v18.16b
	WORD $0x4f00e495 // movi v21.16b, #4
	WORD $0x4e358655 // add v21.16b, v18.16b, v21.16b
	WORD $0x4e150045 // tbl v5.16b, {v2.16b}, v21.16b
	WORD $0x6e334484 // ushl v4.16b, v4.16b, v19.16b
	WORD $0x6e3344a5 // ushl v5.16b, v5.16b, v19.16b
	WORD $0x4e301c84 // and v4.16b, v4.16b, v16.16b
	WORD $0x4e301ca5 // and v5.16b, v5.16b, v16.16b
	WORD $0x6e318484 // sub v4.16b, v4.16b, v17.16b
	WORD $0x6e3184a5 // sub v5.16b, v5.16b, v17.16b
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x3cc02086 // ldur q6, [x4, #2]
	WORD $0x3cc12087 // ldur q7, [x4, #18]
	WORD $0x4e86948c // sdot v12.4s, v4.16b, v6.16b
	WORD $0x4e8794ac // sdot v12.4s, v5.16b, v7.16b
	WORD $0x4eb1b98c // addv s12, v12.4s
	WORD $0x4e21d98c // scvtf v12.4s, v12.4s
	WORD $0x7c400097 // ldur h23, [x4, #0]
	WORD $0x1ee242f7 // fcvt s23, h23
	WORD $0x1e360af7 // fmul s23, s23, s22
	WORD $0x4f971180 // fmla v0.4s, v12.4s, v23.s[0]
	WORD $0xfc40a062 // ldur d2, [x3, #10]
	WORD $0x4e080442 // dup v2.2d, v2.d[0]
	WORD $0x4e120044 // tbl v4.16b, {v2.16b}, v18.16b
	WORD $0x4f00e495 // movi v21.16b, #4
	WORD $0x4e358655 // add v21.16b, v18.16b, v21.16b
	WORD $0x4e150045 // tbl v5.16b, {v2.16b}, v21.16b
	WORD $0x6e334484 // ushl v4.16b, v4.16b, v19.16b
	WORD $0x6e3344a5 // ushl v5.16b, v5.16b, v19.16b
	WORD $0x4e301c84 // and v4.16b, v4.16b, v16.16b
	WORD $0x4e301ca5 // and v5.16b, v5.16b, v16.16b
	WORD $0x6e318484 // sub v4.16b, v4.16b, v17.16b
	WORD $0x6e3184a5 // sub v5.16b, v5.16b, v17.16b
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x3cc24086 // ldur q6, [x4, #36]
	WORD $0x3cc34087 // ldur q7, [x4, #52]
	WORD $0x4e86948c // sdot v12.4s, v4.16b, v6.16b
	WORD $0x4e8794ac // sdot v12.4s, v5.16b, v7.16b
	WORD $0x4eb1b98c // addv s12, v12.4s
	WORD $0x4e21d98c // scvtf v12.4s, v12.4s
	WORD $0x7c422097 // ldur h23, [x4, #34]
	WORD $0x1ee242f7 // fcvt s23, h23
	WORD $0x1e360af7 // fmul s23, s23, s22
	WORD $0x4f971180 // fmla v0.4s, v12.4s, v23.s[0]
	ADD	$18, R3, R3
	ADD	$68, R4, R4
	SUBW	$1, R1, R1
	CBNZW	R1, q2blk
q2reduce:
	WORD $0x6e20d400 // faddp v0.4s, v0.4s, v0.4s
	WORD $0x7e30d800 // faddp s0, v0.2s
	FMOVS	F0, (R2)
	RET
q2oob:
	B	ovr_oob

DATA ·ovr_dbg_vec_dot_q2_0_q8_0_dotprod_b128_4296f77920d379e9+0(SB)/8, $0x303030303030303
DATA ·ovr_dbg_vec_dot_q2_0_q8_0_dotprod_b128_4296f77920d379e9+8(SB)/8, $0x303030303030303
DATA ·ovr_dbg_vec_dot_q2_0_q8_0_dotprod_b128_4296f77920d379e9+16(SB)/8, $0x5656565656565656
DATA ·ovr_dbg_vec_dot_q2_0_q8_0_dotprod_b128_4296f77920d379e9+24(SB)/8, $0x5656565656565656
DATA ·ovr_dbg_vec_dot_q2_0_q8_0_dotprod_b128_4296f77920d379e9+32(SB)/8, $0xabababababababab
DATA ·ovr_dbg_vec_dot_q2_0_q8_0_dotprod_b128_4296f77920d379e9+40(SB)/8, $0xabababababababab
DATA ·ovr_dbg_vec_dot_q2_0_q8_0_dotprod_b128_4296f77920d379e9+48(SB)/8, $0x101010101010101
DATA ·ovr_dbg_vec_dot_q2_0_q8_0_dotprod_b128_4296f77920d379e9+56(SB)/8, $0x101010101010101
DATA ·ovr_dbg_vec_dot_q2_0_q8_0_dotprod_b128_4296f77920d379e9+64(SB)/8, $0x8040201008040201
DATA ·ovr_dbg_vec_dot_q2_0_q8_0_dotprod_b128_4296f77920d379e9+72(SB)/8, $0x8040201008040201
DATA ·ovr_dbg_vec_dot_q2_0_q8_0_dotprod_b128_4296f77920d379e9+80(SB)/8, $0x101010100000000
DATA ·ovr_dbg_vec_dot_q2_0_q8_0_dotprod_b128_4296f77920d379e9+88(SB)/8, $0x303030302020202
DATA ·ovr_dbg_vec_dot_q2_0_q8_0_dotprod_b128_4296f77920d379e9+96(SB)/8, $0xfafcfe00fafcfe00
DATA ·ovr_dbg_vec_dot_q2_0_q8_0_dotprod_b128_4296f77920d379e9+104(SB)/8, $0xfafcfe00fafcfe00
DATA ·ovr_dbg_vec_dot_q2_0_q8_0_dotprod_b128_4296f77920d379e9+112(SB)/8, $0x303030303030303
DATA ·ovr_dbg_vec_dot_q2_0_q8_0_dotprod_b128_4296f77920d379e9+120(SB)/8, $0x303030303030303
GLOBL ·ovr_dbg_vec_dot_q2_0_q8_0_dotprod_b128_4296f77920d379e9(SB), RODATA|NOPTR, $128
