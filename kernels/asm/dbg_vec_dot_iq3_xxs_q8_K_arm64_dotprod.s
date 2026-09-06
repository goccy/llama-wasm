// dbg_vec_dot_iq3_xxs_q8_K: iq3_xxs x q8_K dot, grid and sign gathers through general registers, SDOT per sub-block.
	WORD $0x4f000400 // movi v0.4s, #0
	MOVW	l0+8(FP), R1
	LSRW	$8, R1, R1
	MOVD	l1+16(FP), R2
	ADD	$4, R2, R27
	CMP	R27, R21
	BLO	i3xoob
	ADD	R20, R2, R2
	CBZW	R1, i3xreduce
	MOVD	l3+32(FP), R3
	MOVD	l5+48(FP), R4
	MOVD	$98, R26
	MUL	R1, R26, R26
	ADD	R3, R26, R27
	CMP	R27, R21
	BLO	i3xoob
	MOVD	$292, R26
	MUL	R1, R26, R26
	ADD	R4, R26, R27
	CMP	R27, R21
	BLO	i3xoob
	ADD	R20, R3, R3
	ADD	R20, R4, R4
	MOVD	$·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b(SB), R12
	ADD	$1024, R12, R13
	MOVW	$0x3E800000, R5
	WORD $0x1e2700b1 // fmov s17, w5
i3xblk:
	WORD $0x4f000414 // movi v20.4s, #0
	MOVD	2(R3), R5
	MOVWU	66(R3), R6
	UBFX	$0, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e041d02 // mov v2.s[0], w8
	UBFX	$8, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e0c1d02 // mov v2.s[1], w8
	UBFX	$16, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e141d02 // mov v2.s[2], w8
	UBFX	$24, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e1c1d02 // mov v2.s[3], w8
	UBFX	$32, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e041d03 // mov v3.s[0], w8
	UBFX	$40, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e0c1d03 // mov v3.s[1], w8
	UBFX	$48, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e141d03 // mov v3.s[2], w8
	UBFX	$56, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e1c1d03 // mov v3.s[3], w8
	UBFX	$0, R6, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d04 // mov v4.d[0], x8
	UBFX	$7, R6, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d04 // mov v4.d[1], x8
	UBFX	$14, R6, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d05 // mov v5.d[0], x8
	UBFX	$21, R6, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d05 // mov v5.d[1], x8
	WORD $0x4e249c42 // mul v2.16b, v2.16b, v4.16b
	WORD $0x4e259c63 // mul v3.16b, v3.16b, v5.16b
	WORD $0x3cc04086 // ldur q6, [x4, #4]
	WORD $0x3cc14087 // ldur q7, [x4, #20]
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e86944c // sdot v12.4s, v2.16b, v6.16b
	WORD $0x4e87946c // sdot v12.4s, v3.16b, v7.16b
	LSRW	$28, R6, R7
	LSLW	$1, R7, R7
	ADDW	$1, R7, R7
	WORD $0x4e040cf5 // dup v21.4s, w7
	WORD $0x4eb59594 // mla v20.4s, v12.4s, v21.4s
	MOVD	10(R3), R5
	MOVWU	70(R3), R6
	UBFX	$0, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e041d02 // mov v2.s[0], w8
	UBFX	$8, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e0c1d02 // mov v2.s[1], w8
	UBFX	$16, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e141d02 // mov v2.s[2], w8
	UBFX	$24, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e1c1d02 // mov v2.s[3], w8
	UBFX	$32, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e041d03 // mov v3.s[0], w8
	UBFX	$40, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e0c1d03 // mov v3.s[1], w8
	UBFX	$48, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e141d03 // mov v3.s[2], w8
	UBFX	$56, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e1c1d03 // mov v3.s[3], w8
	UBFX	$0, R6, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d04 // mov v4.d[0], x8
	UBFX	$7, R6, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d04 // mov v4.d[1], x8
	UBFX	$14, R6, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d05 // mov v5.d[0], x8
	UBFX	$21, R6, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d05 // mov v5.d[1], x8
	WORD $0x4e249c42 // mul v2.16b, v2.16b, v4.16b
	WORD $0x4e259c63 // mul v3.16b, v3.16b, v5.16b
	WORD $0x3cc24086 // ldur q6, [x4, #36]
	WORD $0x3cc34087 // ldur q7, [x4, #52]
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e86944c // sdot v12.4s, v2.16b, v6.16b
	WORD $0x4e87946c // sdot v12.4s, v3.16b, v7.16b
	LSRW	$28, R6, R7
	LSLW	$1, R7, R7
	ADDW	$1, R7, R7
	WORD $0x4e040cf5 // dup v21.4s, w7
	WORD $0x4eb59594 // mla v20.4s, v12.4s, v21.4s
	MOVD	18(R3), R5
	MOVWU	74(R3), R6
	UBFX	$0, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e041d02 // mov v2.s[0], w8
	UBFX	$8, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e0c1d02 // mov v2.s[1], w8
	UBFX	$16, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e141d02 // mov v2.s[2], w8
	UBFX	$24, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e1c1d02 // mov v2.s[3], w8
	UBFX	$32, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e041d03 // mov v3.s[0], w8
	UBFX	$40, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e0c1d03 // mov v3.s[1], w8
	UBFX	$48, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e141d03 // mov v3.s[2], w8
	UBFX	$56, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e1c1d03 // mov v3.s[3], w8
	UBFX	$0, R6, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d04 // mov v4.d[0], x8
	UBFX	$7, R6, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d04 // mov v4.d[1], x8
	UBFX	$14, R6, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d05 // mov v5.d[0], x8
	UBFX	$21, R6, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d05 // mov v5.d[1], x8
	WORD $0x4e249c42 // mul v2.16b, v2.16b, v4.16b
	WORD $0x4e259c63 // mul v3.16b, v3.16b, v5.16b
	WORD $0x3cc44086 // ldur q6, [x4, #68]
	WORD $0x3cc54087 // ldur q7, [x4, #84]
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e86944c // sdot v12.4s, v2.16b, v6.16b
	WORD $0x4e87946c // sdot v12.4s, v3.16b, v7.16b
	LSRW	$28, R6, R7
	LSLW	$1, R7, R7
	ADDW	$1, R7, R7
	WORD $0x4e040cf5 // dup v21.4s, w7
	WORD $0x4eb59594 // mla v20.4s, v12.4s, v21.4s
	MOVD	26(R3), R5
	MOVWU	78(R3), R6
	UBFX	$0, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e041d02 // mov v2.s[0], w8
	UBFX	$8, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e0c1d02 // mov v2.s[1], w8
	UBFX	$16, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e141d02 // mov v2.s[2], w8
	UBFX	$24, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e1c1d02 // mov v2.s[3], w8
	UBFX	$32, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e041d03 // mov v3.s[0], w8
	UBFX	$40, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e0c1d03 // mov v3.s[1], w8
	UBFX	$48, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e141d03 // mov v3.s[2], w8
	UBFX	$56, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e1c1d03 // mov v3.s[3], w8
	UBFX	$0, R6, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d04 // mov v4.d[0], x8
	UBFX	$7, R6, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d04 // mov v4.d[1], x8
	UBFX	$14, R6, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d05 // mov v5.d[0], x8
	UBFX	$21, R6, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d05 // mov v5.d[1], x8
	WORD $0x4e249c42 // mul v2.16b, v2.16b, v4.16b
	WORD $0x4e259c63 // mul v3.16b, v3.16b, v5.16b
	WORD $0x3cc64086 // ldur q6, [x4, #100]
	WORD $0x3cc74087 // ldur q7, [x4, #116]
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e86944c // sdot v12.4s, v2.16b, v6.16b
	WORD $0x4e87946c // sdot v12.4s, v3.16b, v7.16b
	LSRW	$28, R6, R7
	LSLW	$1, R7, R7
	ADDW	$1, R7, R7
	WORD $0x4e040cf5 // dup v21.4s, w7
	WORD $0x4eb59594 // mla v20.4s, v12.4s, v21.4s
	MOVD	34(R3), R5
	MOVWU	82(R3), R6
	UBFX	$0, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e041d02 // mov v2.s[0], w8
	UBFX	$8, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e0c1d02 // mov v2.s[1], w8
	UBFX	$16, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e141d02 // mov v2.s[2], w8
	UBFX	$24, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e1c1d02 // mov v2.s[3], w8
	UBFX	$32, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e041d03 // mov v3.s[0], w8
	UBFX	$40, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e0c1d03 // mov v3.s[1], w8
	UBFX	$48, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e141d03 // mov v3.s[2], w8
	UBFX	$56, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e1c1d03 // mov v3.s[3], w8
	UBFX	$0, R6, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d04 // mov v4.d[0], x8
	UBFX	$7, R6, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d04 // mov v4.d[1], x8
	UBFX	$14, R6, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d05 // mov v5.d[0], x8
	UBFX	$21, R6, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d05 // mov v5.d[1], x8
	WORD $0x4e249c42 // mul v2.16b, v2.16b, v4.16b
	WORD $0x4e259c63 // mul v3.16b, v3.16b, v5.16b
	WORD $0x3cc84086 // ldur q6, [x4, #132]
	WORD $0x3cc94087 // ldur q7, [x4, #148]
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e86944c // sdot v12.4s, v2.16b, v6.16b
	WORD $0x4e87946c // sdot v12.4s, v3.16b, v7.16b
	LSRW	$28, R6, R7
	LSLW	$1, R7, R7
	ADDW	$1, R7, R7
	WORD $0x4e040cf5 // dup v21.4s, w7
	WORD $0x4eb59594 // mla v20.4s, v12.4s, v21.4s
	MOVD	42(R3), R5
	MOVWU	86(R3), R6
	UBFX	$0, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e041d02 // mov v2.s[0], w8
	UBFX	$8, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e0c1d02 // mov v2.s[1], w8
	UBFX	$16, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e141d02 // mov v2.s[2], w8
	UBFX	$24, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e1c1d02 // mov v2.s[3], w8
	UBFX	$32, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e041d03 // mov v3.s[0], w8
	UBFX	$40, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e0c1d03 // mov v3.s[1], w8
	UBFX	$48, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e141d03 // mov v3.s[2], w8
	UBFX	$56, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e1c1d03 // mov v3.s[3], w8
	UBFX	$0, R6, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d04 // mov v4.d[0], x8
	UBFX	$7, R6, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d04 // mov v4.d[1], x8
	UBFX	$14, R6, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d05 // mov v5.d[0], x8
	UBFX	$21, R6, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d05 // mov v5.d[1], x8
	WORD $0x4e249c42 // mul v2.16b, v2.16b, v4.16b
	WORD $0x4e259c63 // mul v3.16b, v3.16b, v5.16b
	WORD $0x3cca4086 // ldur q6, [x4, #164]
	WORD $0x3ccb4087 // ldur q7, [x4, #180]
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e86944c // sdot v12.4s, v2.16b, v6.16b
	WORD $0x4e87946c // sdot v12.4s, v3.16b, v7.16b
	LSRW	$28, R6, R7
	LSLW	$1, R7, R7
	ADDW	$1, R7, R7
	WORD $0x4e040cf5 // dup v21.4s, w7
	WORD $0x4eb59594 // mla v20.4s, v12.4s, v21.4s
	MOVD	50(R3), R5
	MOVWU	90(R3), R6
	UBFX	$0, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e041d02 // mov v2.s[0], w8
	UBFX	$8, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e0c1d02 // mov v2.s[1], w8
	UBFX	$16, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e141d02 // mov v2.s[2], w8
	UBFX	$24, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e1c1d02 // mov v2.s[3], w8
	UBFX	$32, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e041d03 // mov v3.s[0], w8
	UBFX	$40, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e0c1d03 // mov v3.s[1], w8
	UBFX	$48, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e141d03 // mov v3.s[2], w8
	UBFX	$56, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e1c1d03 // mov v3.s[3], w8
	UBFX	$0, R6, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d04 // mov v4.d[0], x8
	UBFX	$7, R6, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d04 // mov v4.d[1], x8
	UBFX	$14, R6, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d05 // mov v5.d[0], x8
	UBFX	$21, R6, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d05 // mov v5.d[1], x8
	WORD $0x4e249c42 // mul v2.16b, v2.16b, v4.16b
	WORD $0x4e259c63 // mul v3.16b, v3.16b, v5.16b
	WORD $0x3ccc4086 // ldur q6, [x4, #196]
	WORD $0x3ccd4087 // ldur q7, [x4, #212]
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e86944c // sdot v12.4s, v2.16b, v6.16b
	WORD $0x4e87946c // sdot v12.4s, v3.16b, v7.16b
	LSRW	$28, R6, R7
	LSLW	$1, R7, R7
	ADDW	$1, R7, R7
	WORD $0x4e040cf5 // dup v21.4s, w7
	WORD $0x4eb59594 // mla v20.4s, v12.4s, v21.4s
	MOVD	58(R3), R5
	MOVWU	94(R3), R6
	UBFX	$0, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e041d02 // mov v2.s[0], w8
	UBFX	$8, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e0c1d02 // mov v2.s[1], w8
	UBFX	$16, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e141d02 // mov v2.s[2], w8
	UBFX	$24, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e1c1d02 // mov v2.s[3], w8
	UBFX	$32, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e041d03 // mov v3.s[0], w8
	UBFX	$40, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e0c1d03 // mov v3.s[1], w8
	UBFX	$48, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e141d03 // mov v3.s[2], w8
	UBFX	$56, R5, $8, R7
	MOVWU	(R12)(R7<<2), R8
	WORD $0x4e1c1d03 // mov v3.s[3], w8
	UBFX	$0, R6, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d04 // mov v4.d[0], x8
	UBFX	$7, R6, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d04 // mov v4.d[1], x8
	UBFX	$14, R6, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e081d05 // mov v5.d[0], x8
	UBFX	$21, R6, $7, R7
	MOVD	(R13)(R7<<3), R8
	WORD $0x4e181d05 // mov v5.d[1], x8
	WORD $0x4e249c42 // mul v2.16b, v2.16b, v4.16b
	WORD $0x4e259c63 // mul v3.16b, v3.16b, v5.16b
	WORD $0x3cce4086 // ldur q6, [x4, #228]
	WORD $0x3ccf4087 // ldur q7, [x4, #244]
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e86944c // sdot v12.4s, v2.16b, v6.16b
	WORD $0x4e87946c // sdot v12.4s, v3.16b, v7.16b
	LSRW	$28, R6, R7
	LSLW	$1, R7, R7
	ADDW	$1, R7, R7
	WORD $0x4e040cf5 // dup v21.4s, w7
	WORD $0x4eb59594 // mla v20.4s, v12.4s, v21.4s
	WORD $0x4eb1ba94 // addv s20, v20.4s
	WORD $0x4e21da94 // scvtf v20.4s, v20.4s
	WORD $0x7c400076 // ldur h22, [x3, #0]
	WORD $0xbc400097 // ldur s23, [x4, #0]
	WORD $0x1ee242d6 // fcvt s22, h22
	WORD $0x1e370ad6 // fmul s22, s22, s23
	WORD $0x1e310ad6 // fmul s22, s22, s17
	WORD $0x4f961280 // fmla v0.4s, v20.4s, v22.s[0]
	ADD	$98, R3, R3
	ADD	$292, R4, R4
	SUBW	$1, R1, R1
	CBNZW	R1, i3xblk
i3xreduce:
	WORD $0x6e20d400 // faddp v0.4s, v0.4s, v0.4s
	WORD $0x7e30d800 // faddp s0, v0.2s
	FMOVS	F0, (R2)
	RET
i3xoob:
	B	ovr_oob

DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+0(SB)/8, $0x404041404040404
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+8(SB)/8, $0x4040c0c04040424
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+16(SB)/8, $0x4040c3e04040c1c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+24(SB)/8, $0x404141404041404
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+32(SB)/8, $0x404241404041c0c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+40(SB)/8, $0x4043e2c04043e1c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+48(SB)/8, $0x40c041c040c040c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+56(SB)/8, $0x40c0c14040c0c04
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+64(SB)/8, $0x40c142c040c140c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+72(SB)/8, $0x40c1c14040c1c04
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+80(SB)/8, $0x40c2c24040c240c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+88(SB)/8, $0x4140404040c3e04
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+96(SB)/8, $0x414042404140414
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+104(SB)/8, $0x414140404140c0c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+112(SB)/8, $0x4141c0c04141414
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+120(SB)/8, $0x4141c3e04141c1c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+128(SB)/8, $0x4142c3e04142c0c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+136(SB)/8, $0x41c040c04143e2c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+144(SB)/8, $0x41c0c04041c043e
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+152(SB)/8, $0x41c142c041c0c14
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+160(SB)/8, $0x4240c1c041c3e04
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+168(SB)/8, $0x424242404241c3e
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+176(SB)/8, $0x4243e1c04242c3e
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+184(SB)/8, $0x42c040c04243e2c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+192(SB)/8, $0x42c1c14042c043e
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+200(SB)/8, $0x4341c2c042c2c14
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+208(SB)/8, $0x43e0c0404343424
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+216(SB)/8, $0x43e0c34043e0c24
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+224(SB)/8, $0x43e340c043e241c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+232(SB)/8, $0xc04041c0c04040c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+240(SB)/8, $0xc040c140c040c04
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+248(SB)/8, $0xc04141c0c04140c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+256(SB)/8, $0xc041c140c041c04
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+264(SB)/8, $0xc04243e0c041c24
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+272(SB)/8, $0xc0c04040c042c04
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+280(SB)/8, $0xc0c0c0c0c0c0414
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+288(SB)/8, $0xc0c14140c0c1404
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+296(SB)/8, $0xc14041c0c14040c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+304(SB)/8, $0xc140c140c140c04
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+312(SB)/8, $0xc141c040c14140c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+320(SB)/8, $0xc1c04040c143e14
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+328(SB)/8, $0xc1c14040c1c0414
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+336(SB)/8, $0xc1c24340c1c1c0c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+344(SB)/8, $0xc24040c0c1c3434
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+352(SB)/8, $0xc242c040c24042c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+360(SB)/8, $0xc2c14240c2c1404
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+368(SB)/8, $0xc2c3e0c0c2c2434
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+376(SB)/8, $0xc3e14140c34042c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+384(SB)/8, $0x140404040c3e2404
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+392(SB)/8, $0x14040c0c14040414
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+400(SB)/8, $0x1404140414040c1c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+408(SB)/8, $0x1404143414041414
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+416(SB)/8, $0x1404241414041c0c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+424(SB)/8, $0x140c041c140c040c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+432(SB)/8, $0x140c0c04140c042c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+440(SB)/8, $0x140c140c140c0c14
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+448(SB)/8, $0x140c341c140c1c04
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+456(SB)/8, $0x140c3e04140c343e
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+464(SB)/8, $0x1414041414140404
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+472(SB)/8, $0x14140c3e14140c0c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+480(SB)/8, $0x1414141414141404
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+488(SB)/8, $0x1414240414141c3e
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+496(SB)/8, $0x141c040c14142c2c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+504(SB)/8, $0x141c0c24141c0c04
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+512(SB)/8, $0x141c3e24141c3e04
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+520(SB)/8, $0x14242c1c14241c2c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+528(SB)/8, $0x142c143e142c041c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+536(SB)/8, $0x142c3e24142c240c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+544(SB)/8, $0x143e041c143e040c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+552(SB)/8, $0x143e242c143e0c34
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+560(SB)/8, $0x1c040c041c04040c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+568(SB)/8, $0x1c04140c1c040c14
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+576(SB)/8, $0x1c042c041c04141c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+584(SB)/8, $0x1c043e141c04342c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+592(SB)/8, $0x1c0c04141c0c0404
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+600(SB)/8, $0x1c0c1c0c1c0c1404
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+608(SB)/8, $0x1c0c24341c0c2424
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+616(SB)/8, $0x1c14041c1c14040c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+624(SB)/8, $0x1c14142c1c140c04
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+632(SB)/8, $0x1c143e141c142c14
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+640(SB)/8, $0x1c1c1c1c1c1c0c0c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+648(SB)/8, $0x1c24243e1c241c04
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+656(SB)/8, $0x1c2c04041c243e14
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+664(SB)/8, $0x1c2c14141c2c0434
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+672(SB)/8, $0x1c340c241c2c2c2c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+680(SB)/8, $0x1c34341c1c341c34
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+688(SB)/8, $0x1c3e34041c3e1c1c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+696(SB)/8, $0x24040c3e24040424
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+704(SB)/8, $0x24041c3e24041c2c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+712(SB)/8, $0x24042c3e24042c1c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+720(SB)/8, $0x24141404240c3e24
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+728(SB)/8, $0x2414240424141c3e
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+736(SB)/8, $0x2414343424143404
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+744(SB)/8, $0x241c242c241c043e
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+752(SB)/8, $0x24242c0c24240424
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+760(SB)/8, $0x242c142c24243424
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+768(SB)/8, $0x242c3e04242c241c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+776(SB)/8, $0x243e0c04243e042c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+784(SB)/8, $0x243e1c04243e0c14
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+792(SB)/8, $0x2c04240c2c040c14
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+800(SB)/8, $0x2c0c04042c043e04
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+808(SB)/8, $0x2c0c14342c0c0434
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+816(SB)/8, $0x2c140c242c0c2c2c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+824(SB)/8, $0x2c143e142c141c14
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+832(SB)/8, $0x2c1c2c1c2c1c0414
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+840(SB)/8, $0x2c24141c2c240c04
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+848(SB)/8, $0x2c243e142c24143e
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+856(SB)/8, $0x2c2c1c0c2c2c0414
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+864(SB)/8, $0x2c3e14242c342c04
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+872(SB)/8, $0x340414242c3e2414
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+880(SB)/8, $0x3404243434042424
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+888(SB)/8, $0x340c140c34043424
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+896(SB)/8, $0x34140c3e340c340c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+904(SB)/8, $0x341c1c0434143424
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+912(SB)/8, $0x34242424341c1c34
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+920(SB)/8, $0x342c2c14342c042c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+928(SB)/8, $0x343e041c34341c1c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+936(SB)/8, $0x3e04041c343e140c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+944(SB)/8, $0x3e04043e3e04042c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+952(SB)/8, $0x3e041c143e040c04
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+960(SB)/8, $0x3e0c14343e042c14
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+968(SB)/8, $0x3e140c143e0c2404
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+976(SB)/8, $0x3e142c143e14242c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+984(SB)/8, $0x3e1c0c2c3e1c0404
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+992(SB)/8, $0x3e1c34043e1c1c1c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1000(SB)/8, $0x3e24240c3e24140c
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1008(SB)/8, $0x3e2c04143e2c0404
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1016(SB)/8, $0x3e341c043e2c1424
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1024(SB)/8, $0x101010101010101
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1032(SB)/8, $0xff010101010101ff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1040(SB)/8, $0xff0101010101ff01
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1048(SB)/8, $0x10101010101ffff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1056(SB)/8, $0xff01010101ff0101
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1064(SB)/8, $0x101010101ff01ff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1072(SB)/8, $0x101010101ffff01
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1080(SB)/8, $0xff01010101ffffff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1088(SB)/8, $0xff010101ff010101
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1096(SB)/8, $0x1010101ff0101ff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1104(SB)/8, $0x1010101ff01ff01
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1112(SB)/8, $0xff010101ff01ffff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1120(SB)/8, $0x1010101ffff0101
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1128(SB)/8, $0xff010101ffff01ff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1136(SB)/8, $0xff010101ffffff01
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1144(SB)/8, $0x1010101ffffffff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1152(SB)/8, $0xff0101ff01010101
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1160(SB)/8, $0x10101ff010101ff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1168(SB)/8, $0x10101ff0101ff01
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1176(SB)/8, $0xff0101ff0101ffff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1184(SB)/8, $0x10101ff01ff0101
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1192(SB)/8, $0xff0101ff01ff01ff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1200(SB)/8, $0xff0101ff01ffff01
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1208(SB)/8, $0x10101ff01ffffff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1216(SB)/8, $0x10101ffff010101
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1224(SB)/8, $0xff0101ffff0101ff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1232(SB)/8, $0xff0101ffff01ff01
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1240(SB)/8, $0x10101ffff01ffff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1248(SB)/8, $0xff0101ffffff0101
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1256(SB)/8, $0x10101ffffff01ff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1264(SB)/8, $0x10101ffffffff01
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1272(SB)/8, $0xff0101ffffffffff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1280(SB)/8, $0xff01ff0101010101
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1288(SB)/8, $0x101ff01010101ff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1296(SB)/8, $0x101ff010101ff01
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1304(SB)/8, $0xff01ff010101ffff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1312(SB)/8, $0x101ff0101ff0101
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1320(SB)/8, $0xff01ff0101ff01ff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1328(SB)/8, $0xff01ff0101ffff01
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1336(SB)/8, $0x101ff0101ffffff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1344(SB)/8, $0x101ff01ff010101
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1352(SB)/8, $0xff01ff01ff0101ff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1360(SB)/8, $0xff01ff01ff01ff01
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1368(SB)/8, $0x101ff01ff01ffff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1376(SB)/8, $0xff01ff01ffff0101
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1384(SB)/8, $0x101ff01ffff01ff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1392(SB)/8, $0x101ff01ffffff01
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1400(SB)/8, $0xff01ff01ffffffff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1408(SB)/8, $0x101ffff01010101
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1416(SB)/8, $0xff01ffff010101ff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1424(SB)/8, $0xff01ffff0101ff01
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1432(SB)/8, $0x101ffff0101ffff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1440(SB)/8, $0xff01ffff01ff0101
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1448(SB)/8, $0x101ffff01ff01ff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1456(SB)/8, $0x101ffff01ffff01
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1464(SB)/8, $0xff01ffff01ffffff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1472(SB)/8, $0xff01ffffff010101
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1480(SB)/8, $0x101ffffff0101ff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1488(SB)/8, $0x101ffffff01ff01
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1496(SB)/8, $0xff01ffffff01ffff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1504(SB)/8, $0x101ffffffff0101
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1512(SB)/8, $0xff01ffffffff01ff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1520(SB)/8, $0xff01ffffffffff01
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1528(SB)/8, $0x101ffffffffffff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1536(SB)/8, $0xffff010101010101
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1544(SB)/8, $0x1ff0101010101ff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1552(SB)/8, $0x1ff01010101ff01
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1560(SB)/8, $0xffff01010101ffff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1568(SB)/8, $0x1ff010101ff0101
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1576(SB)/8, $0xffff010101ff01ff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1584(SB)/8, $0xffff010101ffff01
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1592(SB)/8, $0x1ff010101ffffff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1600(SB)/8, $0x1ff0101ff010101
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1608(SB)/8, $0xffff0101ff0101ff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1616(SB)/8, $0xffff0101ff01ff01
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1624(SB)/8, $0x1ff0101ff01ffff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1632(SB)/8, $0xffff0101ffff0101
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1640(SB)/8, $0x1ff0101ffff01ff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1648(SB)/8, $0x1ff0101ffffff01
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1656(SB)/8, $0xffff0101ffffffff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1664(SB)/8, $0x1ff01ff01010101
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1672(SB)/8, $0xffff01ff010101ff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1680(SB)/8, $0xffff01ff0101ff01
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1688(SB)/8, $0x1ff01ff0101ffff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1696(SB)/8, $0xffff01ff01ff0101
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1704(SB)/8, $0x1ff01ff01ff01ff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1712(SB)/8, $0x1ff01ff01ffff01
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1720(SB)/8, $0xffff01ff01ffffff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1728(SB)/8, $0xffff01ffff010101
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1736(SB)/8, $0x1ff01ffff0101ff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1744(SB)/8, $0x1ff01ffff01ff01
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1752(SB)/8, $0xffff01ffff01ffff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1760(SB)/8, $0x1ff01ffffff0101
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1768(SB)/8, $0xffff01ffffff01ff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1776(SB)/8, $0xffff01ffffffff01
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1784(SB)/8, $0x1ff01ffffffffff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1792(SB)/8, $0x1ffff0101010101
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1800(SB)/8, $0xffffff01010101ff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1808(SB)/8, $0xffffff010101ff01
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1816(SB)/8, $0x1ffff010101ffff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1824(SB)/8, $0xffffff0101ff0101
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1832(SB)/8, $0x1ffff0101ff01ff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1840(SB)/8, $0x1ffff0101ffff01
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1848(SB)/8, $0xffffff0101ffffff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1856(SB)/8, $0xffffff01ff010101
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1864(SB)/8, $0x1ffff01ff0101ff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1872(SB)/8, $0x1ffff01ff01ff01
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1880(SB)/8, $0xffffff01ff01ffff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1888(SB)/8, $0x1ffff01ffff0101
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1896(SB)/8, $0xffffff01ffff01ff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1904(SB)/8, $0xffffff01ffffff01
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1912(SB)/8, $0x1ffff01ffffffff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1920(SB)/8, $0xffffffff01010101
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1928(SB)/8, $0x1ffffff010101ff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1936(SB)/8, $0x1ffffff0101ff01
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1944(SB)/8, $0xffffffff0101ffff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1952(SB)/8, $0x1ffffff01ff0101
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1960(SB)/8, $0xffffffff01ff01ff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1968(SB)/8, $0xffffffff01ffff01
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1976(SB)/8, $0x1ffffff01ffffff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1984(SB)/8, $0x1ffffffff010101
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+1992(SB)/8, $0xffffffffff0101ff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+2000(SB)/8, $0xffffffffff01ff01
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+2008(SB)/8, $0x1ffffffff01ffff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+2016(SB)/8, $0xffffffffffff0101
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+2024(SB)/8, $0x1ffffffffff01ff
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+2032(SB)/8, $0x1ffffffffffff01
DATA ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b+2040(SB)/8, $0xffffffffffffffff
GLOBL ·ovr_dbg_vec_dot_iq3_xxs_q8_K_dotprod_b2048_0dff0a225fac788b(SB), RODATA|NOPTR, $2048
