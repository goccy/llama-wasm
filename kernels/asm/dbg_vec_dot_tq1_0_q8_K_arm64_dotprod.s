// dbg_vec_dot_tq1_0_q8_K: tq1_0 x q8_K dot, base-3 digits by byte multiply and two threshold compares, SDOT.
	WORD $0x4f000400 // movi v0.4s, #0
	MOVW	l0+8(FP), R1
	LSRW	$8, R1, R1
	MOVD	l1+16(FP), R2
	ADD	$4, R2, R27
	CMP	R27, R21
	BLO	tq1oob
	ADD	R20, R2, R2
	CBZW	R1, tq1reduce
	MOVD	l3+32(FP), R3
	MOVD	l5+48(FP), R4
	MOVD	$54, R26
	MUL	R1, R26, R26
	ADD	R3, R26, R27
	CMP	R27, R21
	BLO	tq1oob
	MOVD	$292, R26
	MUL	R1, R26, R26
	ADD	R4, R26, R27
	CMP	R27, R21
	BLO	tq1oob
	ADD	R20, R3, R3
	ADD	R20, R4, R4
	MOVD	$·ovr_dbg_vec_dot_tq1_0_q8_K_dotprod_b128_4296f77920d379e9(SB), R12
	WORD $0x3cc00192 // ldur q18, [x12, #0]
	WORD $0x3cc10190 // ldur q16, [x12, #16]
	WORD $0x3cc20191 // ldur q17, [x12, #32]
tq1blk:
	WORD $0x4f000414 // movi v20.4s, #0
	WORD $0x3cc00062 // ldur q2, [x3, #0]
	WORD $0x3cc10063 // ldur q3, [x3, #16]
	WORD $0x6e303c44 // cmhs v4.16b, v2.16b, v16.16b
	WORD $0x6e313c55 // cmhs v21.16b, v2.16b, v17.16b
	WORD $0x4e358484 // add v4.16b, v4.16b, v21.16b
	WORD $0x6e205884 // mvn v4.16b, v4.16b
	WORD $0x4e329c42 // mul v2.16b, v2.16b, v18.16b
	WORD $0x6e303c65 // cmhs v5.16b, v3.16b, v16.16b
	WORD $0x6e313c75 // cmhs v21.16b, v3.16b, v17.16b
	WORD $0x4e3584a5 // add v5.16b, v5.16b, v21.16b
	WORD $0x6e2058a5 // mvn v5.16b, v5.16b
	WORD $0x4e329c63 // mul v3.16b, v3.16b, v18.16b
	WORD $0x3cc04086 // ldur q6, [x4, #4]
	WORD $0x3cc14087 // ldur q7, [x4, #20]
	WORD $0x4e869494 // sdot v20.4s, v4.16b, v6.16b
	WORD $0x4e8794b4 // sdot v20.4s, v5.16b, v7.16b
	WORD $0x6e303c44 // cmhs v4.16b, v2.16b, v16.16b
	WORD $0x6e313c55 // cmhs v21.16b, v2.16b, v17.16b
	WORD $0x4e358484 // add v4.16b, v4.16b, v21.16b
	WORD $0x6e205884 // mvn v4.16b, v4.16b
	WORD $0x4e329c42 // mul v2.16b, v2.16b, v18.16b
	WORD $0x6e303c65 // cmhs v5.16b, v3.16b, v16.16b
	WORD $0x6e313c75 // cmhs v21.16b, v3.16b, v17.16b
	WORD $0x4e3584a5 // add v5.16b, v5.16b, v21.16b
	WORD $0x6e2058a5 // mvn v5.16b, v5.16b
	WORD $0x4e329c63 // mul v3.16b, v3.16b, v18.16b
	WORD $0x3cc24086 // ldur q6, [x4, #36]
	WORD $0x3cc34087 // ldur q7, [x4, #52]
	WORD $0x4e869494 // sdot v20.4s, v4.16b, v6.16b
	WORD $0x4e8794b4 // sdot v20.4s, v5.16b, v7.16b
	WORD $0x6e303c44 // cmhs v4.16b, v2.16b, v16.16b
	WORD $0x6e313c55 // cmhs v21.16b, v2.16b, v17.16b
	WORD $0x4e358484 // add v4.16b, v4.16b, v21.16b
	WORD $0x6e205884 // mvn v4.16b, v4.16b
	WORD $0x4e329c42 // mul v2.16b, v2.16b, v18.16b
	WORD $0x6e303c65 // cmhs v5.16b, v3.16b, v16.16b
	WORD $0x6e313c75 // cmhs v21.16b, v3.16b, v17.16b
	WORD $0x4e3584a5 // add v5.16b, v5.16b, v21.16b
	WORD $0x6e2058a5 // mvn v5.16b, v5.16b
	WORD $0x4e329c63 // mul v3.16b, v3.16b, v18.16b
	WORD $0x3cc44086 // ldur q6, [x4, #68]
	WORD $0x3cc54087 // ldur q7, [x4, #84]
	WORD $0x4e869494 // sdot v20.4s, v4.16b, v6.16b
	WORD $0x4e8794b4 // sdot v20.4s, v5.16b, v7.16b
	WORD $0x6e303c44 // cmhs v4.16b, v2.16b, v16.16b
	WORD $0x6e313c55 // cmhs v21.16b, v2.16b, v17.16b
	WORD $0x4e358484 // add v4.16b, v4.16b, v21.16b
	WORD $0x6e205884 // mvn v4.16b, v4.16b
	WORD $0x4e329c42 // mul v2.16b, v2.16b, v18.16b
	WORD $0x6e303c65 // cmhs v5.16b, v3.16b, v16.16b
	WORD $0x6e313c75 // cmhs v21.16b, v3.16b, v17.16b
	WORD $0x4e3584a5 // add v5.16b, v5.16b, v21.16b
	WORD $0x6e2058a5 // mvn v5.16b, v5.16b
	WORD $0x4e329c63 // mul v3.16b, v3.16b, v18.16b
	WORD $0x3cc64086 // ldur q6, [x4, #100]
	WORD $0x3cc74087 // ldur q7, [x4, #116]
	WORD $0x4e869494 // sdot v20.4s, v4.16b, v6.16b
	WORD $0x4e8794b4 // sdot v20.4s, v5.16b, v7.16b
	WORD $0x6e303c44 // cmhs v4.16b, v2.16b, v16.16b
	WORD $0x6e313c55 // cmhs v21.16b, v2.16b, v17.16b
	WORD $0x4e358484 // add v4.16b, v4.16b, v21.16b
	WORD $0x6e205884 // mvn v4.16b, v4.16b
	WORD $0x4e329c42 // mul v2.16b, v2.16b, v18.16b
	WORD $0x6e303c65 // cmhs v5.16b, v3.16b, v16.16b
	WORD $0x6e313c75 // cmhs v21.16b, v3.16b, v17.16b
	WORD $0x4e3584a5 // add v5.16b, v5.16b, v21.16b
	WORD $0x6e2058a5 // mvn v5.16b, v5.16b
	WORD $0x4e329c63 // mul v3.16b, v3.16b, v18.16b
	WORD $0x3cc84086 // ldur q6, [x4, #132]
	WORD $0x3cc94087 // ldur q7, [x4, #148]
	WORD $0x4e869494 // sdot v20.4s, v4.16b, v6.16b
	WORD $0x4e8794b4 // sdot v20.4s, v5.16b, v7.16b
	WORD $0x3cc20062 // ldur q2, [x3, #32]
	WORD $0x6e303c44 // cmhs v4.16b, v2.16b, v16.16b
	WORD $0x6e313c55 // cmhs v21.16b, v2.16b, v17.16b
	WORD $0x4e358484 // add v4.16b, v4.16b, v21.16b
	WORD $0x6e205884 // mvn v4.16b, v4.16b
	WORD $0x4e329c42 // mul v2.16b, v2.16b, v18.16b
	WORD $0x3cca4086 // ldur q6, [x4, #164]
	WORD $0x4e869494 // sdot v20.4s, v4.16b, v6.16b
	WORD $0x6e303c44 // cmhs v4.16b, v2.16b, v16.16b
	WORD $0x6e313c55 // cmhs v21.16b, v2.16b, v17.16b
	WORD $0x4e358484 // add v4.16b, v4.16b, v21.16b
	WORD $0x6e205884 // mvn v4.16b, v4.16b
	WORD $0x4e329c42 // mul v2.16b, v2.16b, v18.16b
	WORD $0x3ccb4086 // ldur q6, [x4, #180]
	WORD $0x4e869494 // sdot v20.4s, v4.16b, v6.16b
	WORD $0x6e303c44 // cmhs v4.16b, v2.16b, v16.16b
	WORD $0x6e313c55 // cmhs v21.16b, v2.16b, v17.16b
	WORD $0x4e358484 // add v4.16b, v4.16b, v21.16b
	WORD $0x6e205884 // mvn v4.16b, v4.16b
	WORD $0x4e329c42 // mul v2.16b, v2.16b, v18.16b
	WORD $0x3ccc4086 // ldur q6, [x4, #196]
	WORD $0x4e869494 // sdot v20.4s, v4.16b, v6.16b
	WORD $0x6e303c44 // cmhs v4.16b, v2.16b, v16.16b
	WORD $0x6e313c55 // cmhs v21.16b, v2.16b, v17.16b
	WORD $0x4e358484 // add v4.16b, v4.16b, v21.16b
	WORD $0x6e205884 // mvn v4.16b, v4.16b
	WORD $0x4e329c42 // mul v2.16b, v2.16b, v18.16b
	WORD $0x3ccd4086 // ldur q6, [x4, #212]
	WORD $0x4e869494 // sdot v20.4s, v4.16b, v6.16b
	WORD $0x6e303c44 // cmhs v4.16b, v2.16b, v16.16b
	WORD $0x6e313c55 // cmhs v21.16b, v2.16b, v17.16b
	WORD $0x4e358484 // add v4.16b, v4.16b, v21.16b
	WORD $0x6e205884 // mvn v4.16b, v4.16b
	WORD $0x4e329c42 // mul v2.16b, v2.16b, v18.16b
	WORD $0x3cce4086 // ldur q6, [x4, #228]
	WORD $0x4e869494 // sdot v20.4s, v4.16b, v6.16b
	WORD $0xbc430062 // ldur s2, [x3, #48]
	ADD	$244, R4, R5
	WORD $0x6e303c44 // cmhs v4.16b, v2.16b, v16.16b
	WORD $0x6e313c55 // cmhs v21.16b, v2.16b, v17.16b
	WORD $0x4e358484 // add v4.16b, v4.16b, v21.16b
	WORD $0x6e205884 // mvn v4.16b, v4.16b
	WORD $0x4e329c42 // mul v2.16b, v2.16b, v18.16b
	WORD $0xbc4000a6 // ldur s6, [x5, #0]
	WORD $0x4e869494 // sdot v20.4s, v4.16b, v6.16b
	WORD $0x6e303c44 // cmhs v4.16b, v2.16b, v16.16b
	WORD $0x6e313c55 // cmhs v21.16b, v2.16b, v17.16b
	WORD $0x4e358484 // add v4.16b, v4.16b, v21.16b
	WORD $0x6e205884 // mvn v4.16b, v4.16b
	WORD $0x4e329c42 // mul v2.16b, v2.16b, v18.16b
	WORD $0xbc4040a6 // ldur s6, [x5, #4]
	WORD $0x4e869494 // sdot v20.4s, v4.16b, v6.16b
	WORD $0x6e303c44 // cmhs v4.16b, v2.16b, v16.16b
	WORD $0x6e313c55 // cmhs v21.16b, v2.16b, v17.16b
	WORD $0x4e358484 // add v4.16b, v4.16b, v21.16b
	WORD $0x6e205884 // mvn v4.16b, v4.16b
	WORD $0x4e329c42 // mul v2.16b, v2.16b, v18.16b
	WORD $0xbc4080a6 // ldur s6, [x5, #8]
	WORD $0x4e869494 // sdot v20.4s, v4.16b, v6.16b
	WORD $0x6e303c44 // cmhs v4.16b, v2.16b, v16.16b
	WORD $0x6e313c55 // cmhs v21.16b, v2.16b, v17.16b
	WORD $0x4e358484 // add v4.16b, v4.16b, v21.16b
	WORD $0x6e205884 // mvn v4.16b, v4.16b
	WORD $0x4e329c42 // mul v2.16b, v2.16b, v18.16b
	WORD $0xbc40c0a6 // ldur s6, [x5, #12]
	WORD $0x4e869494 // sdot v20.4s, v4.16b, v6.16b
	WORD $0x4eb1ba94 // addv s20, v20.4s
	WORD $0x4e21da94 // scvtf v20.4s, v20.4s
	WORD $0x7c434076 // ldur h22, [x3, #52]
	WORD $0xbc400097 // ldur s23, [x4, #0]
	WORD $0x1ee242d6 // fcvt s22, h22
	WORD $0x1e370ad6 // fmul s22, s22, s23
	WORD $0x4f961280 // fmla v0.4s, v20.4s, v22.s[0]
	ADD	$54, R3, R3
	ADD	$292, R4, R4
	SUBW	$1, R1, R1
	CBNZW	R1, tq1blk
tq1reduce:
	WORD $0x6e20d400 // faddp v0.4s, v0.4s, v0.4s
	WORD $0x7e30d800 // faddp s0, v0.2s
	FMOVS	F0, (R2)
	RET
tq1oob:
	B	ovr_oob

DATA ·ovr_dbg_vec_dot_tq1_0_q8_K_dotprod_b128_4296f77920d379e9+0(SB)/8, $0x303030303030303
DATA ·ovr_dbg_vec_dot_tq1_0_q8_K_dotprod_b128_4296f77920d379e9+8(SB)/8, $0x303030303030303
DATA ·ovr_dbg_vec_dot_tq1_0_q8_K_dotprod_b128_4296f77920d379e9+16(SB)/8, $0x5656565656565656
DATA ·ovr_dbg_vec_dot_tq1_0_q8_K_dotprod_b128_4296f77920d379e9+24(SB)/8, $0x5656565656565656
DATA ·ovr_dbg_vec_dot_tq1_0_q8_K_dotprod_b128_4296f77920d379e9+32(SB)/8, $0xabababababababab
DATA ·ovr_dbg_vec_dot_tq1_0_q8_K_dotprod_b128_4296f77920d379e9+40(SB)/8, $0xabababababababab
DATA ·ovr_dbg_vec_dot_tq1_0_q8_K_dotprod_b128_4296f77920d379e9+48(SB)/8, $0x101010101010101
DATA ·ovr_dbg_vec_dot_tq1_0_q8_K_dotprod_b128_4296f77920d379e9+56(SB)/8, $0x101010101010101
DATA ·ovr_dbg_vec_dot_tq1_0_q8_K_dotprod_b128_4296f77920d379e9+64(SB)/8, $0x8040201008040201
DATA ·ovr_dbg_vec_dot_tq1_0_q8_K_dotprod_b128_4296f77920d379e9+72(SB)/8, $0x8040201008040201
DATA ·ovr_dbg_vec_dot_tq1_0_q8_K_dotprod_b128_4296f77920d379e9+80(SB)/8, $0x101010100000000
DATA ·ovr_dbg_vec_dot_tq1_0_q8_K_dotprod_b128_4296f77920d379e9+88(SB)/8, $0x303030302020202
DATA ·ovr_dbg_vec_dot_tq1_0_q8_K_dotprod_b128_4296f77920d379e9+96(SB)/8, $0xfafcfe00fafcfe00
DATA ·ovr_dbg_vec_dot_tq1_0_q8_K_dotprod_b128_4296f77920d379e9+104(SB)/8, $0xfafcfe00fafcfe00
DATA ·ovr_dbg_vec_dot_tq1_0_q8_K_dotprod_b128_4296f77920d379e9+112(SB)/8, $0x303030303030303
DATA ·ovr_dbg_vec_dot_tq1_0_q8_K_dotprod_b128_4296f77920d379e9+120(SB)/8, $0x303030303030303
GLOBL ·ovr_dbg_vec_dot_tq1_0_q8_K_dotprod_b128_4296f77920d379e9(SB), RODATA|NOPTR, $128
