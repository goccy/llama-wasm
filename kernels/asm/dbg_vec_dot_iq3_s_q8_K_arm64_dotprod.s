// dbg_vec_dot_iq3_s_q8_K: iq3_s x q8_K dot, 9-bit grid gathers, sign bytes expanded with TBL/CMTST, SDOT per sub-block.
	WORD $0x4f000400 // movi v0.4s, #0
	MOVW	l0+8(FP), R1
	LSRW	$8, R1, R1
	MOVD	l1+16(FP), R2
	ADD	$4, R2, R27
	CMP	R27, R21
	BLO	i3soob
	ADD	R20, R2, R2
	CBZW	R1, i3sreduce
	MOVD	l3+32(FP), R3
	MOVD	l5+48(FP), R4
	MOVD	$110, R26
	MUL	R1, R26, R26
	ADD	R3, R26, R27
	CMP	R27, R21
	BLO	i3soob
	MOVD	$292, R26
	MUL	R1, R26, R26
	ADD	R4, R26, R27
	CMP	R27, R21
	BLO	i3soob
	ADD	R20, R3, R3
	ADD	R20, R4, R4
	MOVD	$·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48(SB), R12
	ADD	$2048, R12, R13
	WORD $0x3cc001b3 // ldur q19, [x13, #0]
	WORD $0x3cc101b6 // ldur q22, [x13, #16]
	WORD $0x3cc201b2 // ldur q18, [x13, #32]
	WORD $0x4f00e437 // movi v23.16b, #1
i3sblk:
	WORD $0x4f000414 // movi v20.4s, #0
	MOVD	2(R3), R5
	MOVBU	66(R3), R6
	MOVWU	74(R3), R9
	UBFX	$0, R5, $8, R7
	UBFX	$0, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e041d02 // mov v2.s[0], w8
	UBFX	$8, R5, $8, R7
	UBFX	$1, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e0c1d02 // mov v2.s[1], w8
	UBFX	$16, R5, $8, R7
	UBFX	$2, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e141d02 // mov v2.s[2], w8
	UBFX	$24, R5, $8, R7
	UBFX	$3, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e1c1d02 // mov v2.s[3], w8
	UBFX	$32, R5, $8, R7
	UBFX	$4, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e041d03 // mov v3.s[0], w8
	UBFX	$40, R5, $8, R7
	UBFX	$5, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e0c1d03 // mov v3.s[1], w8
	UBFX	$48, R5, $8, R7
	UBFX	$6, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e141d03 // mov v3.s[2], w8
	UBFX	$56, R5, $8, R7
	UBFX	$7, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e1c1d03 // mov v3.s[3], w8
	WORD $0x4e041d38 // mov v24.s[0], w9
	WORD $0x4e130304 // tbl v4.16b, {v24.16b}, v19.16b
	WORD $0x4e160305 // tbl v5.16b, {v24.16b}, v22.16b
	WORD $0x4e328c84 // cmtst v4.16b, v4.16b, v18.16b
	WORD $0x4e328ca5 // cmtst v5.16b, v5.16b, v18.16b
	WORD $0x4eb71c84 // orr v4.16b, v4.16b, v23.16b
	WORD $0x4eb71ca5 // orr v5.16b, v5.16b, v23.16b
	WORD $0x4e249c42 // mul v2.16b, v2.16b, v4.16b
	WORD $0x4e259c63 // mul v3.16b, v3.16b, v5.16b
	WORD $0x3cc04086 // ldur q6, [x4, #4]
	WORD $0x3cc14087 // ldur q7, [x4, #20]
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e86944c // sdot v12.4s, v2.16b, v6.16b
	WORD $0x4e87946c // sdot v12.4s, v3.16b, v7.16b
	MOVBU	106(R3), R7
	ANDW	$0xf, R7, R7
	LSLW	$1, R7, R7
	ADDW	$1, R7, R7
	WORD $0x4e040cf5 // dup v21.4s, w7
	WORD $0x4eb59594 // mla v20.4s, v12.4s, v21.4s
	MOVD	10(R3), R5
	MOVBU	67(R3), R6
	MOVWU	78(R3), R9
	UBFX	$0, R5, $8, R7
	UBFX	$0, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e041d02 // mov v2.s[0], w8
	UBFX	$8, R5, $8, R7
	UBFX	$1, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e0c1d02 // mov v2.s[1], w8
	UBFX	$16, R5, $8, R7
	UBFX	$2, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e141d02 // mov v2.s[2], w8
	UBFX	$24, R5, $8, R7
	UBFX	$3, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e1c1d02 // mov v2.s[3], w8
	UBFX	$32, R5, $8, R7
	UBFX	$4, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e041d03 // mov v3.s[0], w8
	UBFX	$40, R5, $8, R7
	UBFX	$5, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e0c1d03 // mov v3.s[1], w8
	UBFX	$48, R5, $8, R7
	UBFX	$6, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e141d03 // mov v3.s[2], w8
	UBFX	$56, R5, $8, R7
	UBFX	$7, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e1c1d03 // mov v3.s[3], w8
	WORD $0x4e041d38 // mov v24.s[0], w9
	WORD $0x4e130304 // tbl v4.16b, {v24.16b}, v19.16b
	WORD $0x4e160305 // tbl v5.16b, {v24.16b}, v22.16b
	WORD $0x4e328c84 // cmtst v4.16b, v4.16b, v18.16b
	WORD $0x4e328ca5 // cmtst v5.16b, v5.16b, v18.16b
	WORD $0x4eb71c84 // orr v4.16b, v4.16b, v23.16b
	WORD $0x4eb71ca5 // orr v5.16b, v5.16b, v23.16b
	WORD $0x4e249c42 // mul v2.16b, v2.16b, v4.16b
	WORD $0x4e259c63 // mul v3.16b, v3.16b, v5.16b
	WORD $0x3cc24086 // ldur q6, [x4, #36]
	WORD $0x3cc34087 // ldur q7, [x4, #52]
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e86944c // sdot v12.4s, v2.16b, v6.16b
	WORD $0x4e87946c // sdot v12.4s, v3.16b, v7.16b
	MOVBU	106(R3), R7
	LSRW	$4, R7, R7
	LSLW	$1, R7, R7
	ADDW	$1, R7, R7
	WORD $0x4e040cf5 // dup v21.4s, w7
	WORD $0x4eb59594 // mla v20.4s, v12.4s, v21.4s
	MOVD	18(R3), R5
	MOVBU	68(R3), R6
	MOVWU	82(R3), R9
	UBFX	$0, R5, $8, R7
	UBFX	$0, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e041d02 // mov v2.s[0], w8
	UBFX	$8, R5, $8, R7
	UBFX	$1, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e0c1d02 // mov v2.s[1], w8
	UBFX	$16, R5, $8, R7
	UBFX	$2, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e141d02 // mov v2.s[2], w8
	UBFX	$24, R5, $8, R7
	UBFX	$3, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e1c1d02 // mov v2.s[3], w8
	UBFX	$32, R5, $8, R7
	UBFX	$4, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e041d03 // mov v3.s[0], w8
	UBFX	$40, R5, $8, R7
	UBFX	$5, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e0c1d03 // mov v3.s[1], w8
	UBFX	$48, R5, $8, R7
	UBFX	$6, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e141d03 // mov v3.s[2], w8
	UBFX	$56, R5, $8, R7
	UBFX	$7, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e1c1d03 // mov v3.s[3], w8
	WORD $0x4e041d38 // mov v24.s[0], w9
	WORD $0x4e130304 // tbl v4.16b, {v24.16b}, v19.16b
	WORD $0x4e160305 // tbl v5.16b, {v24.16b}, v22.16b
	WORD $0x4e328c84 // cmtst v4.16b, v4.16b, v18.16b
	WORD $0x4e328ca5 // cmtst v5.16b, v5.16b, v18.16b
	WORD $0x4eb71c84 // orr v4.16b, v4.16b, v23.16b
	WORD $0x4eb71ca5 // orr v5.16b, v5.16b, v23.16b
	WORD $0x4e249c42 // mul v2.16b, v2.16b, v4.16b
	WORD $0x4e259c63 // mul v3.16b, v3.16b, v5.16b
	WORD $0x3cc44086 // ldur q6, [x4, #68]
	WORD $0x3cc54087 // ldur q7, [x4, #84]
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e86944c // sdot v12.4s, v2.16b, v6.16b
	WORD $0x4e87946c // sdot v12.4s, v3.16b, v7.16b
	MOVBU	107(R3), R7
	ANDW	$0xf, R7, R7
	LSLW	$1, R7, R7
	ADDW	$1, R7, R7
	WORD $0x4e040cf5 // dup v21.4s, w7
	WORD $0x4eb59594 // mla v20.4s, v12.4s, v21.4s
	MOVD	26(R3), R5
	MOVBU	69(R3), R6
	MOVWU	86(R3), R9
	UBFX	$0, R5, $8, R7
	UBFX	$0, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e041d02 // mov v2.s[0], w8
	UBFX	$8, R5, $8, R7
	UBFX	$1, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e0c1d02 // mov v2.s[1], w8
	UBFX	$16, R5, $8, R7
	UBFX	$2, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e141d02 // mov v2.s[2], w8
	UBFX	$24, R5, $8, R7
	UBFX	$3, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e1c1d02 // mov v2.s[3], w8
	UBFX	$32, R5, $8, R7
	UBFX	$4, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e041d03 // mov v3.s[0], w8
	UBFX	$40, R5, $8, R7
	UBFX	$5, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e0c1d03 // mov v3.s[1], w8
	UBFX	$48, R5, $8, R7
	UBFX	$6, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e141d03 // mov v3.s[2], w8
	UBFX	$56, R5, $8, R7
	UBFX	$7, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e1c1d03 // mov v3.s[3], w8
	WORD $0x4e041d38 // mov v24.s[0], w9
	WORD $0x4e130304 // tbl v4.16b, {v24.16b}, v19.16b
	WORD $0x4e160305 // tbl v5.16b, {v24.16b}, v22.16b
	WORD $0x4e328c84 // cmtst v4.16b, v4.16b, v18.16b
	WORD $0x4e328ca5 // cmtst v5.16b, v5.16b, v18.16b
	WORD $0x4eb71c84 // orr v4.16b, v4.16b, v23.16b
	WORD $0x4eb71ca5 // orr v5.16b, v5.16b, v23.16b
	WORD $0x4e249c42 // mul v2.16b, v2.16b, v4.16b
	WORD $0x4e259c63 // mul v3.16b, v3.16b, v5.16b
	WORD $0x3cc64086 // ldur q6, [x4, #100]
	WORD $0x3cc74087 // ldur q7, [x4, #116]
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e86944c // sdot v12.4s, v2.16b, v6.16b
	WORD $0x4e87946c // sdot v12.4s, v3.16b, v7.16b
	MOVBU	107(R3), R7
	LSRW	$4, R7, R7
	LSLW	$1, R7, R7
	ADDW	$1, R7, R7
	WORD $0x4e040cf5 // dup v21.4s, w7
	WORD $0x4eb59594 // mla v20.4s, v12.4s, v21.4s
	MOVD	34(R3), R5
	MOVBU	70(R3), R6
	MOVWU	90(R3), R9
	UBFX	$0, R5, $8, R7
	UBFX	$0, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e041d02 // mov v2.s[0], w8
	UBFX	$8, R5, $8, R7
	UBFX	$1, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e0c1d02 // mov v2.s[1], w8
	UBFX	$16, R5, $8, R7
	UBFX	$2, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e141d02 // mov v2.s[2], w8
	UBFX	$24, R5, $8, R7
	UBFX	$3, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e1c1d02 // mov v2.s[3], w8
	UBFX	$32, R5, $8, R7
	UBFX	$4, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e041d03 // mov v3.s[0], w8
	UBFX	$40, R5, $8, R7
	UBFX	$5, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e0c1d03 // mov v3.s[1], w8
	UBFX	$48, R5, $8, R7
	UBFX	$6, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e141d03 // mov v3.s[2], w8
	UBFX	$56, R5, $8, R7
	UBFX	$7, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e1c1d03 // mov v3.s[3], w8
	WORD $0x4e041d38 // mov v24.s[0], w9
	WORD $0x4e130304 // tbl v4.16b, {v24.16b}, v19.16b
	WORD $0x4e160305 // tbl v5.16b, {v24.16b}, v22.16b
	WORD $0x4e328c84 // cmtst v4.16b, v4.16b, v18.16b
	WORD $0x4e328ca5 // cmtst v5.16b, v5.16b, v18.16b
	WORD $0x4eb71c84 // orr v4.16b, v4.16b, v23.16b
	WORD $0x4eb71ca5 // orr v5.16b, v5.16b, v23.16b
	WORD $0x4e249c42 // mul v2.16b, v2.16b, v4.16b
	WORD $0x4e259c63 // mul v3.16b, v3.16b, v5.16b
	WORD $0x3cc84086 // ldur q6, [x4, #132]
	WORD $0x3cc94087 // ldur q7, [x4, #148]
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e86944c // sdot v12.4s, v2.16b, v6.16b
	WORD $0x4e87946c // sdot v12.4s, v3.16b, v7.16b
	MOVBU	108(R3), R7
	ANDW	$0xf, R7, R7
	LSLW	$1, R7, R7
	ADDW	$1, R7, R7
	WORD $0x4e040cf5 // dup v21.4s, w7
	WORD $0x4eb59594 // mla v20.4s, v12.4s, v21.4s
	MOVD	42(R3), R5
	MOVBU	71(R3), R6
	MOVWU	94(R3), R9
	UBFX	$0, R5, $8, R7
	UBFX	$0, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e041d02 // mov v2.s[0], w8
	UBFX	$8, R5, $8, R7
	UBFX	$1, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e0c1d02 // mov v2.s[1], w8
	UBFX	$16, R5, $8, R7
	UBFX	$2, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e141d02 // mov v2.s[2], w8
	UBFX	$24, R5, $8, R7
	UBFX	$3, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e1c1d02 // mov v2.s[3], w8
	UBFX	$32, R5, $8, R7
	UBFX	$4, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e041d03 // mov v3.s[0], w8
	UBFX	$40, R5, $8, R7
	UBFX	$5, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e0c1d03 // mov v3.s[1], w8
	UBFX	$48, R5, $8, R7
	UBFX	$6, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e141d03 // mov v3.s[2], w8
	UBFX	$56, R5, $8, R7
	UBFX	$7, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e1c1d03 // mov v3.s[3], w8
	WORD $0x4e041d38 // mov v24.s[0], w9
	WORD $0x4e130304 // tbl v4.16b, {v24.16b}, v19.16b
	WORD $0x4e160305 // tbl v5.16b, {v24.16b}, v22.16b
	WORD $0x4e328c84 // cmtst v4.16b, v4.16b, v18.16b
	WORD $0x4e328ca5 // cmtst v5.16b, v5.16b, v18.16b
	WORD $0x4eb71c84 // orr v4.16b, v4.16b, v23.16b
	WORD $0x4eb71ca5 // orr v5.16b, v5.16b, v23.16b
	WORD $0x4e249c42 // mul v2.16b, v2.16b, v4.16b
	WORD $0x4e259c63 // mul v3.16b, v3.16b, v5.16b
	WORD $0x3cca4086 // ldur q6, [x4, #164]
	WORD $0x3ccb4087 // ldur q7, [x4, #180]
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e86944c // sdot v12.4s, v2.16b, v6.16b
	WORD $0x4e87946c // sdot v12.4s, v3.16b, v7.16b
	MOVBU	108(R3), R7
	LSRW	$4, R7, R7
	LSLW	$1, R7, R7
	ADDW	$1, R7, R7
	WORD $0x4e040cf5 // dup v21.4s, w7
	WORD $0x4eb59594 // mla v20.4s, v12.4s, v21.4s
	MOVD	50(R3), R5
	MOVBU	72(R3), R6
	MOVWU	98(R3), R9
	UBFX	$0, R5, $8, R7
	UBFX	$0, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e041d02 // mov v2.s[0], w8
	UBFX	$8, R5, $8, R7
	UBFX	$1, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e0c1d02 // mov v2.s[1], w8
	UBFX	$16, R5, $8, R7
	UBFX	$2, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e141d02 // mov v2.s[2], w8
	UBFX	$24, R5, $8, R7
	UBFX	$3, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e1c1d02 // mov v2.s[3], w8
	UBFX	$32, R5, $8, R7
	UBFX	$4, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e041d03 // mov v3.s[0], w8
	UBFX	$40, R5, $8, R7
	UBFX	$5, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e0c1d03 // mov v3.s[1], w8
	UBFX	$48, R5, $8, R7
	UBFX	$6, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e141d03 // mov v3.s[2], w8
	UBFX	$56, R5, $8, R7
	UBFX	$7, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e1c1d03 // mov v3.s[3], w8
	WORD $0x4e041d38 // mov v24.s[0], w9
	WORD $0x4e130304 // tbl v4.16b, {v24.16b}, v19.16b
	WORD $0x4e160305 // tbl v5.16b, {v24.16b}, v22.16b
	WORD $0x4e328c84 // cmtst v4.16b, v4.16b, v18.16b
	WORD $0x4e328ca5 // cmtst v5.16b, v5.16b, v18.16b
	WORD $0x4eb71c84 // orr v4.16b, v4.16b, v23.16b
	WORD $0x4eb71ca5 // orr v5.16b, v5.16b, v23.16b
	WORD $0x4e249c42 // mul v2.16b, v2.16b, v4.16b
	WORD $0x4e259c63 // mul v3.16b, v3.16b, v5.16b
	WORD $0x3ccc4086 // ldur q6, [x4, #196]
	WORD $0x3ccd4087 // ldur q7, [x4, #212]
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e86944c // sdot v12.4s, v2.16b, v6.16b
	WORD $0x4e87946c // sdot v12.4s, v3.16b, v7.16b
	MOVBU	109(R3), R7
	ANDW	$0xf, R7, R7
	LSLW	$1, R7, R7
	ADDW	$1, R7, R7
	WORD $0x4e040cf5 // dup v21.4s, w7
	WORD $0x4eb59594 // mla v20.4s, v12.4s, v21.4s
	MOVD	58(R3), R5
	MOVBU	73(R3), R6
	MOVWU	102(R3), R9
	UBFX	$0, R5, $8, R7
	UBFX	$0, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e041d02 // mov v2.s[0], w8
	UBFX	$8, R5, $8, R7
	UBFX	$1, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e0c1d02 // mov v2.s[1], w8
	UBFX	$16, R5, $8, R7
	UBFX	$2, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e141d02 // mov v2.s[2], w8
	UBFX	$24, R5, $8, R7
	UBFX	$3, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e1c1d02 // mov v2.s[3], w8
	UBFX	$32, R5, $8, R7
	UBFX	$4, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e041d03 // mov v3.s[0], w8
	UBFX	$40, R5, $8, R7
	UBFX	$5, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e0c1d03 // mov v3.s[1], w8
	UBFX	$48, R5, $8, R7
	UBFX	$6, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e141d03 // mov v3.s[2], w8
	UBFX	$56, R5, $8, R7
	UBFX	$7, R6, $1, R8
	ORR	R8<<8, R7, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e1c1d03 // mov v3.s[3], w8
	WORD $0x4e041d38 // mov v24.s[0], w9
	WORD $0x4e130304 // tbl v4.16b, {v24.16b}, v19.16b
	WORD $0x4e160305 // tbl v5.16b, {v24.16b}, v22.16b
	WORD $0x4e328c84 // cmtst v4.16b, v4.16b, v18.16b
	WORD $0x4e328ca5 // cmtst v5.16b, v5.16b, v18.16b
	WORD $0x4eb71c84 // orr v4.16b, v4.16b, v23.16b
	WORD $0x4eb71ca5 // orr v5.16b, v5.16b, v23.16b
	WORD $0x4e249c42 // mul v2.16b, v2.16b, v4.16b
	WORD $0x4e259c63 // mul v3.16b, v3.16b, v5.16b
	WORD $0x3cce4086 // ldur q6, [x4, #228]
	WORD $0x3ccf4087 // ldur q7, [x4, #244]
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e86944c // sdot v12.4s, v2.16b, v6.16b
	WORD $0x4e87946c // sdot v12.4s, v3.16b, v7.16b
	MOVBU	109(R3), R7
	LSRW	$4, R7, R7
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
	WORD $0x4f991280 // fmla v0.4s, v20.4s, v25.s[0]
	ADD	$110, R3, R3
	ADD	$292, R4, R4
	SUBW	$1, R1, R1
	CBNZW	R1, i3sblk
i3sreduce:
	WORD $0x6e20d400 // faddp v0.4s, v0.4s, v0.4s
	WORD $0x7e30d800 // faddp s0, v0.2s
	FMOVS	F0, (R2)
	RET
i3soob:
	B	ovr_oob

DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+0(SB)/8, $0x101010301010101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+8(SB)/8, $0x101010b01010105
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+16(SB)/8, $0x10103010101010f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+24(SB)/8, $0x101030501010303
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+32(SB)/8, $0x101030d01010309
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+40(SB)/8, $0x101050301010501
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+48(SB)/8, $0x10107070101050b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+56(SB)/8, $0x101090501010901
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+64(SB)/8, $0x101090f0101090b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+72(SB)/8, $0x1010b0701010b03
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+80(SB)/8, $0x1010d0501010d01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+88(SB)/8, $0x1010f0901010f03
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+96(SB)/8, $0x103010101010f0f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+104(SB)/8, $0x103010501030103
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+112(SB)/8, $0x103030101030109
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+120(SB)/8, $0x103030b01030303
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+128(SB)/8, $0x103050701030501
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+136(SB)/8, $0x10307030103050f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+144(SB)/8, $0x10309090103070b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+152(SB)/8, $0x1030d0b01030d03
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+160(SB)/8, $0x105010101030f05
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+168(SB)/8, $0x105010b01050103
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+176(SB)/8, $0x10503010105010f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+184(SB)/8, $0x105030d01050307
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+192(SB)/8, $0x105050b01050503
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+200(SB)/8, $0x105070901050701
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+208(SB)/8, $0x105090b01050905
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+216(SB)/8, $0x1050b030105090f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+224(SB)/8, $0x1050f0101050b07
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+232(SB)/8, $0x107010701050f07
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+240(SB)/8, $0x107030b01070303
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+248(SB)/8, $0x107050501070501
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+256(SB)/8, $0x107070701070703
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+264(SB)/8, $0x10709090107070d
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+272(SB)/8, $0x1070b0501070b01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+280(SB)/8, $0x1070f0301070d0f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+288(SB)/8, $0x109010101070f0b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+296(SB)/8, $0x109030f01090307
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+304(SB)/8, $0x109050901090503
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+312(SB)/8, $0x109090101090705
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+320(SB)/8, $0x1090b0301090907
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+328(SB)/8, $0x10b010501090f01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+336(SB)/8, $0x10b0501010b0109
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+344(SB)/8, $0x10b050d010b0505
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+352(SB)/8, $0x10b0903010b0707
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+360(SB)/8, $0x10b090f010b090b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+368(SB)/8, $0x10b0f07010b0d0d
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+376(SB)/8, $0x10d0303010d010d
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+384(SB)/8, $0x10d0703010d0307
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+392(SB)/8, $0x10d0f03010d0b05
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+400(SB)/8, $0x10f0105010f0101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+408(SB)/8, $0x10f0501010f0109
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+416(SB)/8, $0x10f050d010f0505
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+424(SB)/8, $0x10f0b01010f0707
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+432(SB)/8, $0x3010101010f0b09
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+440(SB)/8, $0x301010503010103
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+448(SB)/8, $0x301030103010109
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+456(SB)/8, $0x301030703010303
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+464(SB)/8, $0x301030f0301030b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+472(SB)/8, $0x301050503010501
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+480(SB)/8, $0x301070903010703
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+488(SB)/8, $0x3010b090301070d
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+496(SB)/8, $0x3010d0303010b0d
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+504(SB)/8, $0x303010103010f05
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+512(SB)/8, $0x303010703030103
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+520(SB)/8, $0x30303010303010d
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+528(SB)/8, $0x303050303030309
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+536(SB)/8, $0x303070703030701
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+544(SB)/8, $0x3030b0103030903
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+552(SB)/8, $0x3030f0103030b05
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+560(SB)/8, $0x305010103030f0d
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+568(SB)/8, $0x305030b03050305
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+576(SB)/8, $0x30505010305030f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+584(SB)/8, $0x305070503050509
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+592(SB)/8, $0x305090703050901
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+600(SB)/8, $0x3050d0103050b0b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+608(SB)/8, $0x307010303050f05
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+616(SB)/8, $0x307010f03070109
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+624(SB)/8, $0x307030703070301
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+632(SB)/8, $0x307050f03070503
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+640(SB)/8, $0x307070903070701
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+648(SB)/8, $0x3070d0503070903
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+656(SB)/8, $0x309010703070f01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+664(SB)/8, $0x30903050309010b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+672(SB)/8, $0x309070303090309
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+680(SB)/8, $0x309090503090707
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+688(SB)/8, $0x3090b010309090d
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+696(SB)/8, $0x30b010303090b09
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+704(SB)/8, $0x30b0307030b0301
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+712(SB)/8, $0x30b0701030b0503
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+720(SB)/8, $0x30b0b03030b0705
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+728(SB)/8, $0x30d0509030d0501
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+736(SB)/8, $0x30d0909030d050f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+744(SB)/8, $0x30f0103030d090d
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+752(SB)/8, $0x30f0301030f0107
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+760(SB)/8, $0x30f0503030f0305
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+768(SB)/8, $0x30f0903030f070b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+776(SB)/8, $0x30f0f01030f0d05
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+784(SB)/8, $0x501010305010101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+792(SB)/8, $0x501010b05010107
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+800(SB)/8, $0x50103010501010f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+808(SB)/8, $0x501030905010305
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+816(SB)/8, $0x50105030501030d
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+824(SB)/8, $0x501050f05010507
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+832(SB)/8, $0x501070505010701
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+840(SB)/8, $0x501090705010903
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+848(SB)/8, $0x5010b010501090b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+856(SB)/8, $0x5010d0f05010b05
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+864(SB)/8, $0x5010f0705010f01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+872(SB)/8, $0x503010105010f0b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+880(SB)/8, $0x503030105030105
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+888(SB)/8, $0x503030f05030307
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+896(SB)/8, $0x503050b05030505
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+904(SB)/8, $0x503070905030703
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+912(SB)/8, $0x5030b0305030905
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+920(SB)/8, $0x505010905050103
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+928(SB)/8, $0x50505030505010f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+936(SB)/8, $0x505070105050507
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+944(SB)/8, $0x50509030505070f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+952(SB)/8, $0x5050b0f05050b07
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+960(SB)/8, $0x5050f0905050f03
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+968(SB)/8, $0x507010505070101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+976(SB)/8, $0x50703030507010b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+984(SB)/8, $0x507050905070505
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+992(SB)/8, $0x507070705070703
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1000(SB)/8, $0x5070b0105070905
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1008(SB)/8, $0x509010305070d0d
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1016(SB)/8, $0x50905010509010f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1024(SB)/8, $0x509070505090507
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1032(SB)/8, $0x50909030509070b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1040(SB)/8, $0x5090f0b05090f05
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1048(SB)/8, $0x50b0303050b0109
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1056(SB)/8, $0x50b070f050b0505
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1064(SB)/8, $0x50b0b07050b0901
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1072(SB)/8, $0x50d0101050b0f01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1080(SB)/8, $0x50d010f050d0105
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1088(SB)/8, $0x50d0b0b050d0503
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1096(SB)/8, $0x50f010b050d0d03
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1104(SB)/8, $0x50f050d050f0303
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1112(SB)/8, $0x50f0907050f0701
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1120(SB)/8, $0x7010105050f0b01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1128(SB)/8, $0x701030707010303
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1136(SB)/8, $0x701030f0701030b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1144(SB)/8, $0x701070307010505
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1152(SB)/8, $0x701070b07010707
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1160(SB)/8, $0x701090907010905
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1168(SB)/8, $0x7010b030701090f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1176(SB)/8, $0x7010f0307010d07
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1184(SB)/8, $0x703010707030103
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1192(SB)/8, $0x70303090703010b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1200(SB)/8, $0x703050707030503
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1208(SB)/8, $0x7030d0107030901
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1216(SB)/8, $0x7030f0d07030f05
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1224(SB)/8, $0x705030507050101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1232(SB)/8, $0x705070507050501
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1240(SB)/8, $0x7050b0107050709
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1248(SB)/8, $0x707030107070103
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1256(SB)/8, $0x707050307070309
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1264(SB)/8, $0x707050f07070507
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1272(SB)/8, $0x707090307070701
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1280(SB)/8, $0x707090f07070907
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1288(SB)/8, $0x7070f0707070b0b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1296(SB)/8, $0x709030307090107
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1304(SB)/8, $0x70905050709030d
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1312(SB)/8, $0x7090b0507090703
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1320(SB)/8, $0x7090d0907090d01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1328(SB)/8, $0x70b0301070b0103
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1336(SB)/8, $0x70b050b070b0305
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1344(SB)/8, $0x70b0909070b0705
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1352(SB)/8, $0x70b0f07070b0b0d
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1360(SB)/8, $0x70d0903070d030d
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1368(SB)/8, $0x70f0107070f0103
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1376(SB)/8, $0x70f0505070f0501
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1384(SB)/8, $0x9010101070f070b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1392(SB)/8, $0x901030509010109
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1400(SB)/8, $0x901050909010501
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1408(SB)/8, $0x90107050901050f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1416(SB)/8, $0x9010b0109010903
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1424(SB)/8, $0x903010509010f01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1432(SB)/8, $0x90303030903010f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1440(SB)/8, $0x903050509030307
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1448(SB)/8, $0x903070b09030701
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1456(SB)/8, $0x9030b0309030907
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1464(SB)/8, $0x905010309030b0b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1472(SB)/8, $0x905030109050107
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1480(SB)/8, $0x90505030905030b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1488(SB)/8, $0x905090109050707
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1496(SB)/8, $0x9050d0509050b0f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1504(SB)/8, $0x907010909050f01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1512(SB)/8, $0x907030709070303
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1520(SB)/8, $0x907050509070501
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1528(SB)/8, $0x907070b09070703
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1536(SB)/8, $0x909010509090101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1544(SB)/8, $0x909070f09090509
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1552(SB)/8, $0x9090f0309090901
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1560(SB)/8, $0x90b010f090b010b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1568(SB)/8, $0x90b0d05090b0503
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1576(SB)/8, $0x90d0709090d0307
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1584(SB)/8, $0x90f0301090d0d01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1592(SB)/8, $0x90f0701090f030b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1600(SB)/8, $0x90f0b03090f0907
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1608(SB)/8, $0xb0103010b010105
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1616(SB)/8, $0xb0105050b010309
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1624(SB)/8, $0xb0109090b010901
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1632(SB)/8, $0xb010b050b01090f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1640(SB)/8, $0xb010f090b010d0d
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1648(SB)/8, $0xb0301070b030103
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1656(SB)/8, $0xb0303050b03010b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1664(SB)/8, $0xb0307050b030503
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1672(SB)/8, $0xb0501010b030f05
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1680(SB)/8, $0xb0505070b050303
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1688(SB)/8, $0xb05070d0b050701
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1696(SB)/8, $0xb0701050b050b07
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1704(SB)/8, $0xb0703010b07010f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1712(SB)/8, $0xb0709090b07050f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1720(SB)/8, $0xb070d0b0b070b03
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1728(SB)/8, $0xb0901030b070f07
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1736(SB)/8, $0xb0905010b090109
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1744(SB)/8, $0xb09090d0b090705
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1752(SB)/8, $0xb0b050d0b0b0305
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1760(SB)/8, $0xb0b0b070b0b0b03
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1768(SB)/8, $0xb0f01050b0d0905
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1776(SB)/8, $0xb0f05050b0f0109
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1784(SB)/8, $0xd0103070d010303
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1792(SB)/8, $0xd0107030d01030b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1800(SB)/8, $0xd010d010d010707
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1808(SB)/8, $0xd0305010d030101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1816(SB)/8, $0xd030d090d03050f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1824(SB)/8, $0xd0507090d050305
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1832(SB)/8, $0xd050b0b0d050905
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1840(SB)/8, $0xd050f010d050d05
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1848(SB)/8, $0xd0703090d070101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1856(SB)/8, $0xd0709010d070503
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1864(SB)/8, $0xd0909070d09050b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1872(SB)/8, $0xd0b01010d090d05
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1880(SB)/8, $0xd0b07090d0b0107
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1888(SB)/8, $0xd0d010b0d0b0d01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1896(SB)/8, $0xd0f03030d0d0901
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1904(SB)/8, $0xf0101010d0f0307
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1912(SB)/8, $0xf01010f0f010109
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1920(SB)/8, $0xf0105050f010501
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1928(SB)/8, $0xf0109010f01070d
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1936(SB)/8, $0xf010d050f010b09
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1944(SB)/8, $0xf0303030f030105
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1952(SB)/8, $0xf0309070f030509
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1960(SB)/8, $0xf0501030f03090b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1968(SB)/8, $0xf0503010f050109
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1976(SB)/8, $0xf0505030f05030d
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1984(SB)/8, $0xf050b030f050701
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+1992(SB)/8, $0xf0707050f070105
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+2000(SB)/8, $0xf070b070f07070b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+2008(SB)/8, $0xf09010b0f090103
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+2016(SB)/8, $0xf0905010f090307
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+2024(SB)/8, $0xf0b05050f090b01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+2032(SB)/8, $0xf0d01050f0b0905
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+2040(SB)/8, $0xf0f01010f0d0703
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+2048(SB)/8, $0x0
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+2056(SB)/8, $0x101010101010101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+2064(SB)/8, $0x202020202020202
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+2072(SB)/8, $0x303030303030303
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+2080(SB)/8, $0x8040201008040201
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48+2088(SB)/8, $0x8040201008040201
GLOBL ·ovr_dbg_vec_dot_iq3_s_q8_K_dotprod_b2096_30a5fc654bffba48(SB), RODATA|NOPTR, $2096
