// dbg_vec_dot_q8_0_q8_0: q8_0 x q8_0 dot, two blocks per step via SDOT.
	WORD $0x4f000400 // movi v0.4s, #0
	WORD $0x4f000401 // movi v1.4s, #0
	MOVW	l0+8(FP), R1
	LSRW	$5, R1, R1
	MOVD	l1+16(FP), R2
	ADD	$4, R2, R27
	CMP	R27, R21
	BLO	q8doob
	ADD	R20, R2, R2
	CBZW	R1, q8dreduce
	MOVD	l3+32(FP), R3
	MOVD	l5+48(FP), R4
	MOVD	$34, R26
	MUL	R1, R26, R26
	ADD	R3, R26, R27
	CMP	R27, R21
	BLO	q8doob
	MOVD	$34, R26
	MUL	R1, R26, R26
	ADD	R4, R26, R27
	CMP	R27, R21
	BLO	q8doob
	ADD	R20, R3, R3
	ADD	R20, R4, R4
q8dloop2:
	CMPW	$2, R1
	BLT	q8dtail
	WORD $0x3cc02062 // ldur q2, [x3, #2]
	WORD $0x3cc12064 // ldur q4, [x3, #18]
	WORD $0x3cc02086 // ldur q6, [x4, #2]
	WORD $0x3cc12088 // ldur q8, [x4, #18]
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4e86944a // sdot v10.4s, v2.16b, v6.16b
	WORD $0x4e88948a // sdot v10.4s, v4.16b, v8.16b
	WORD $0x7c40006c // ldur h12, [x3, #0]
	WORD $0x7c40008e // ldur h14, [x4, #0]
	WORD $0x1ee2418c // fcvt s12, h12
	WORD $0x1ee241ce // fcvt s14, h14
	WORD $0x1e2e098c // fmul s12, s12, s14
	WORD $0x4e21d94a // scvtf v10.4s, v10.4s
	WORD $0x4f8c1140 // fmla v0.4s, v10.4s, v12.s[0]
	WORD $0x3cc24063 // ldur q3, [x3, #36]
	WORD $0x3cc34065 // ldur q5, [x3, #52]
	WORD $0x3cc24087 // ldur q7, [x4, #36]
	WORD $0x3cc34089 // ldur q9, [x4, #52]
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x4e87946b // sdot v11.4s, v3.16b, v7.16b
	WORD $0x4e8994ab // sdot v11.4s, v5.16b, v9.16b
	WORD $0x7c42206d // ldur h13, [x3, #34]
	WORD $0x7c42208f // ldur h15, [x4, #34]
	WORD $0x1ee241ad // fcvt s13, h13
	WORD $0x1ee241ef // fcvt s15, h15
	WORD $0x1e2f09ad // fmul s13, s13, s15
	WORD $0x4e21d96b // scvtf v11.4s, v11.4s
	WORD $0x4f8d1161 // fmla v1.4s, v11.4s, v13.s[0]
	ADD	$68, R3, R3
	ADD	$68, R4, R4
	SUBW	$2, R1, R1
	B	q8dloop2
q8dtail:
	CBZW	R1, q8dreduce
	WORD $0x3cc02062 // ldur q2, [x3, #2]
	WORD $0x3cc12064 // ldur q4, [x3, #18]
	WORD $0x3cc02086 // ldur q6, [x4, #2]
	WORD $0x3cc12088 // ldur q8, [x4, #18]
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4e86944a // sdot v10.4s, v2.16b, v6.16b
	WORD $0x4e88948a // sdot v10.4s, v4.16b, v8.16b
	WORD $0x7c40006c // ldur h12, [x3, #0]
	WORD $0x7c40008e // ldur h14, [x4, #0]
	WORD $0x1ee2418c // fcvt s12, h12
	WORD $0x1ee241ce // fcvt s14, h14
	WORD $0x1e2e098c // fmul s12, s12, s14
	WORD $0x4e21d94a // scvtf v10.4s, v10.4s
	WORD $0x4f8c1140 // fmla v0.4s, v10.4s, v12.s[0]
q8dreduce:
	WORD $0x4e21d400 // fadd v0.4s, v0.4s, v1.4s
	WORD $0x6e20d400 // faddp v0.4s, v0.4s, v0.4s
	WORD $0x7e30d800 // faddp s0, v0.2s
	FMOVS	F0, (R2)
	RET
q8doob:
	B	ovr_oob
