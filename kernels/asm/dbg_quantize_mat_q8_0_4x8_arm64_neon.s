// dbg_quantize_mat_q8_0_4x8: quantize four f32 rows into block_q8_0x4 (FMAXV amax, FCVTAS quants).
	MOVD	l0+8(FP), R1
	MOVD	l1+16(FP), R2
	MOVD	l2+24(FP), R3
	LSR	$5, R3, R4
	CBZ	R4, q8mdone
	LSL	$2, R3, R3
	ADD	R3<<2, R1, R27
	CMP	R27, R21
	BLO	q8moob
	MOVD	$136, R26
	MUL	R4, R26, R26
	ADD	R2, R26, R27
	CMP	R27, R21
	BLO	q8moob
	ADD	R20, R1, R1
	ADD	R20, R2, R2
	MOVW	$0x42fe0000, R11
	WORD $0x1e27016e // fmov s14, w11
	WORD $0x1e2e100f // fmov s15, #1.0
q8mblk:
	MOVD	R1, R6
	MOVD	R2, R7
	MOVD	R2, R8
	MOVW	$4, R5
q8mrow:
	WORD $0x3dc000c0 // ldr q0, [x6, #0]
	WORD $0x3dc004c1 // ldr q1, [x6, #16]
	WORD $0x3dc008c2 // ldr q2, [x6, #32]
	WORD $0x3dc00cc3 // ldr q3, [x6, #48]
	WORD $0x3dc010c4 // ldr q4, [x6, #64]
	WORD $0x3dc014c5 // ldr q5, [x6, #80]
	WORD $0x3dc018c6 // ldr q6, [x6, #96]
	WORD $0x3dc01cc7 // ldr q7, [x6, #112]
	WORD $0x4ea0f808 // fabs v8.4s, v0.4s
	WORD $0x4ea0f82a // fabs v10.4s, v1.4s
	WORD $0x4e2af508 // fmax v8.4s, v8.4s, v10.4s
	WORD $0x4ea0f84a // fabs v10.4s, v2.4s
	WORD $0x4e2af508 // fmax v8.4s, v8.4s, v10.4s
	WORD $0x4ea0f86a // fabs v10.4s, v3.4s
	WORD $0x4e2af508 // fmax v8.4s, v8.4s, v10.4s
	WORD $0x4ea0f88a // fabs v10.4s, v4.4s
	WORD $0x4e2af508 // fmax v8.4s, v8.4s, v10.4s
	WORD $0x4ea0f8aa // fabs v10.4s, v5.4s
	WORD $0x4e2af508 // fmax v8.4s, v8.4s, v10.4s
	WORD $0x4ea0f8ca // fabs v10.4s, v6.4s
	WORD $0x4e2af508 // fmax v8.4s, v8.4s, v10.4s
	WORD $0x4ea0f8ea // fabs v10.4s, v7.4s
	WORD $0x4e2af508 // fmax v8.4s, v8.4s, v10.4s
	WORD $0x6e30f908 // fmaxv s8, v8.4s
	WORD $0x1e2e190a // fdiv s10, s8, s14
	WORD $0x1e202108 // fcmp s8, #0.0
	BEQ	q8mzero
	WORD $0x1e2a19e9 // fdiv s9, s15, s10
	B	q8mscale
q8mzero:
	WORD $0x1e2703e9 // fmov s9, wzr
q8mscale:
	WORD $0x1e23c14a // fcvt h10, s10
	WORD $0x7d00010a // str h10, [x8, #0]
	WORD $0x4e040529 // dup v9.4s, v9.s[0]
	WORD $0x6e29dc0a // fmul v10.4s, v0.4s, v9.4s
	WORD $0x6e29dc2b // fmul v11.4s, v1.4s, v9.4s
	WORD $0x4e21c94a // fcvtas v10.4s, v10.4s
	WORD $0x4e21c96b // fcvtas v11.4s, v11.4s
	WORD $0x0e61494c // sqxtn v12.4h, v10.4s
	WORD $0x4e61496c // sqxtn2 v12.8h, v11.4s
	WORD $0x0e21498d // sqxtn v13.8b, v12.8h
	WORD $0xfd0004ed // str d13, [x7, #8]
	WORD $0x6e29dc4a // fmul v10.4s, v2.4s, v9.4s
	WORD $0x6e29dc6b // fmul v11.4s, v3.4s, v9.4s
	WORD $0x4e21c94a // fcvtas v10.4s, v10.4s
	WORD $0x4e21c96b // fcvtas v11.4s, v11.4s
	WORD $0x0e61494c // sqxtn v12.4h, v10.4s
	WORD $0x4e61496c // sqxtn2 v12.8h, v11.4s
	WORD $0x0e21498d // sqxtn v13.8b, v12.8h
	WORD $0xfd0014ed // str d13, [x7, #40]
	WORD $0x6e29dc8a // fmul v10.4s, v4.4s, v9.4s
	WORD $0x6e29dcab // fmul v11.4s, v5.4s, v9.4s
	WORD $0x4e21c94a // fcvtas v10.4s, v10.4s
	WORD $0x4e21c96b // fcvtas v11.4s, v11.4s
	WORD $0x0e61494c // sqxtn v12.4h, v10.4s
	WORD $0x4e61496c // sqxtn2 v12.8h, v11.4s
	WORD $0x0e21498d // sqxtn v13.8b, v12.8h
	WORD $0xfd0024ed // str d13, [x7, #72]
	WORD $0x6e29dcca // fmul v10.4s, v6.4s, v9.4s
	WORD $0x6e29dceb // fmul v11.4s, v7.4s, v9.4s
	WORD $0x4e21c94a // fcvtas v10.4s, v10.4s
	WORD $0x4e21c96b // fcvtas v11.4s, v11.4s
	WORD $0x0e61494c // sqxtn v12.4h, v10.4s
	WORD $0x4e61496c // sqxtn2 v12.8h, v11.4s
	WORD $0x0e21498d // sqxtn v13.8b, v12.8h
	WORD $0xfd0034ed // str d13, [x7, #104]
	ADD	R6, R3, R6
	ADD	$8, R7, R7
	ADD	$2, R8, R8
	SUBW	$1, R5, R5
	CBNZW	R5, q8mrow
	ADD	$128, R1, R1
	ADD	$136, R2, R2
	SUB	$1, R4, R4
	CBNZ	R4, q8mblk
q8mdone:
	RET
q8moob:
	B	ovr_oob
