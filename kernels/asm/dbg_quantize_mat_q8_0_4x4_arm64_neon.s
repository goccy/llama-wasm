// dbg_quantize_mat_q8_0_4x4: quantize four f32 rows into block_q8_0x4, 4-wide interleave (FMAXV amax, FCVTNS quants).
	MOVD	l0+8(FP), R1
	MOVD	l1+16(FP), R2
	MOVD	l2+24(FP), R3
	LSR	$5, R3, R4
	CBZ	R4, q44done
	LSL	$2, R3, R3
	ADD	R3<<2, R1, R27
	CMP	R27, R21
	BLO	q44oob
	MOVD	$136, R26
	MUL	R4, R26, R26
	ADD	R2, R26, R27
	CMP	R27, R21
	BLO	q44oob
	ADD	R20, R1, R1
	ADD	R20, R2, R2
	MOVW	$0x42fe0000, R11
	WORD $0x1e27016e // fmov s14, w11
	WORD $0x1e2e100f // fmov s15, #1.0
	ADD	R1, R3, R9
	ADD	R9, R3, R10
	ADD	R10, R3, R11
q44blk:
	MOVD	R1, R6
	MOVD	R2, R8
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
	BEQ	q44zero0
	WORD $0x1e2a19e9 // fdiv s9, s15, s10
	B	q44scale0
q44zero0:
	WORD $0x1e2703e9 // fmov s9, wzr
q44scale0:
	WORD $0x1e23c14a // fcvt h10, s10
	WORD $0x7d00010a // str h10, [x8, #0]
	WORD $0x4e040530 // dup v16.4s, v9.s[0]
	ADD	R6, R3, R6
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
	BEQ	q44zero1
	WORD $0x1e2a19e9 // fdiv s9, s15, s10
	B	q44scale1
q44zero1:
	WORD $0x1e2703e9 // fmov s9, wzr
q44scale1:
	WORD $0x1e23c14a // fcvt h10, s10
	WORD $0x7d00050a // str h10, [x8, #2]
	WORD $0x4e040531 // dup v17.4s, v9.s[0]
	ADD	R6, R3, R6
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
	BEQ	q44zero2
	WORD $0x1e2a19e9 // fdiv s9, s15, s10
	B	q44scale2
q44zero2:
	WORD $0x1e2703e9 // fmov s9, wzr
q44scale2:
	WORD $0x1e23c14a // fcvt h10, s10
	WORD $0x7d00090a // str h10, [x8, #4]
	WORD $0x4e040532 // dup v18.4s, v9.s[0]
	ADD	R6, R3, R6
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
	BEQ	q44zero3
	WORD $0x1e2a19e9 // fdiv s9, s15, s10
	B	q44scale3
q44zero3:
	WORD $0x1e2703e9 // fmov s9, wzr
q44scale3:
	WORD $0x1e23c14a // fcvt h10, s10
	WORD $0x7d000d0a // str h10, [x8, #6]
	WORD $0x4e040533 // dup v19.4s, v9.s[0]
	WORD $0x3dc00020 // ldr q0, [x1, #0]
	WORD $0x3dc00121 // ldr q1, [x9, #0]
	WORD $0x3dc00142 // ldr q2, [x10, #0]
	WORD $0x3dc00163 // ldr q3, [x11, #0]
	WORD $0x6e30dc00 // fmul v0.4s, v0.4s, v16.4s
	WORD $0x4e21a800 // fcvtns v0.4s, v0.4s
	WORD $0x6e31dc21 // fmul v1.4s, v1.4s, v17.4s
	WORD $0x4e21a821 // fcvtns v1.4s, v1.4s
	WORD $0x6e32dc42 // fmul v2.4s, v2.4s, v18.4s
	WORD $0x4e21a842 // fcvtns v2.4s, v2.4s
	WORD $0x6e33dc63 // fmul v3.4s, v3.4s, v19.4s
	WORD $0x4e21a863 // fcvtns v3.4s, v3.4s
	WORD $0x0e614804 // sqxtn v4.4h, v0.4s
	WORD $0x4e614824 // sqxtn2 v4.8h, v1.4s
	WORD $0x0e614845 // sqxtn v5.4h, v2.4s
	WORD $0x4e614865 // sqxtn2 v5.8h, v3.4s
	WORD $0x0e214886 // sqxtn v6.8b, v4.8h
	WORD $0x4e2148a6 // sqxtn2 v6.16b, v5.8h
	WORD $0x3c808046 // stur q6, [x2, #8]
	WORD $0x3dc00420 // ldr q0, [x1, #16]
	WORD $0x3dc00521 // ldr q1, [x9, #16]
	WORD $0x3dc00542 // ldr q2, [x10, #16]
	WORD $0x3dc00563 // ldr q3, [x11, #16]
	WORD $0x6e30dc00 // fmul v0.4s, v0.4s, v16.4s
	WORD $0x4e21a800 // fcvtns v0.4s, v0.4s
	WORD $0x6e31dc21 // fmul v1.4s, v1.4s, v17.4s
	WORD $0x4e21a821 // fcvtns v1.4s, v1.4s
	WORD $0x6e32dc42 // fmul v2.4s, v2.4s, v18.4s
	WORD $0x4e21a842 // fcvtns v2.4s, v2.4s
	WORD $0x6e33dc63 // fmul v3.4s, v3.4s, v19.4s
	WORD $0x4e21a863 // fcvtns v3.4s, v3.4s
	WORD $0x0e614804 // sqxtn v4.4h, v0.4s
	WORD $0x4e614824 // sqxtn2 v4.8h, v1.4s
	WORD $0x0e614845 // sqxtn v5.4h, v2.4s
	WORD $0x4e614865 // sqxtn2 v5.8h, v3.4s
	WORD $0x0e214886 // sqxtn v6.8b, v4.8h
	WORD $0x4e2148a6 // sqxtn2 v6.16b, v5.8h
	WORD $0x3c818046 // stur q6, [x2, #24]
	WORD $0x3dc00820 // ldr q0, [x1, #32]
	WORD $0x3dc00921 // ldr q1, [x9, #32]
	WORD $0x3dc00942 // ldr q2, [x10, #32]
	WORD $0x3dc00963 // ldr q3, [x11, #32]
	WORD $0x6e30dc00 // fmul v0.4s, v0.4s, v16.4s
	WORD $0x4e21a800 // fcvtns v0.4s, v0.4s
	WORD $0x6e31dc21 // fmul v1.4s, v1.4s, v17.4s
	WORD $0x4e21a821 // fcvtns v1.4s, v1.4s
	WORD $0x6e32dc42 // fmul v2.4s, v2.4s, v18.4s
	WORD $0x4e21a842 // fcvtns v2.4s, v2.4s
	WORD $0x6e33dc63 // fmul v3.4s, v3.4s, v19.4s
	WORD $0x4e21a863 // fcvtns v3.4s, v3.4s
	WORD $0x0e614804 // sqxtn v4.4h, v0.4s
	WORD $0x4e614824 // sqxtn2 v4.8h, v1.4s
	WORD $0x0e614845 // sqxtn v5.4h, v2.4s
	WORD $0x4e614865 // sqxtn2 v5.8h, v3.4s
	WORD $0x0e214886 // sqxtn v6.8b, v4.8h
	WORD $0x4e2148a6 // sqxtn2 v6.16b, v5.8h
	WORD $0x3c828046 // stur q6, [x2, #40]
	WORD $0x3dc00c20 // ldr q0, [x1, #48]
	WORD $0x3dc00d21 // ldr q1, [x9, #48]
	WORD $0x3dc00d42 // ldr q2, [x10, #48]
	WORD $0x3dc00d63 // ldr q3, [x11, #48]
	WORD $0x6e30dc00 // fmul v0.4s, v0.4s, v16.4s
	WORD $0x4e21a800 // fcvtns v0.4s, v0.4s
	WORD $0x6e31dc21 // fmul v1.4s, v1.4s, v17.4s
	WORD $0x4e21a821 // fcvtns v1.4s, v1.4s
	WORD $0x6e32dc42 // fmul v2.4s, v2.4s, v18.4s
	WORD $0x4e21a842 // fcvtns v2.4s, v2.4s
	WORD $0x6e33dc63 // fmul v3.4s, v3.4s, v19.4s
	WORD $0x4e21a863 // fcvtns v3.4s, v3.4s
	WORD $0x0e614804 // sqxtn v4.4h, v0.4s
	WORD $0x4e614824 // sqxtn2 v4.8h, v1.4s
	WORD $0x0e614845 // sqxtn v5.4h, v2.4s
	WORD $0x4e614865 // sqxtn2 v5.8h, v3.4s
	WORD $0x0e214886 // sqxtn v6.8b, v4.8h
	WORD $0x4e2148a6 // sqxtn2 v6.16b, v5.8h
	WORD $0x3c838046 // stur q6, [x2, #56]
	WORD $0x3dc01020 // ldr q0, [x1, #64]
	WORD $0x3dc01121 // ldr q1, [x9, #64]
	WORD $0x3dc01142 // ldr q2, [x10, #64]
	WORD $0x3dc01163 // ldr q3, [x11, #64]
	WORD $0x6e30dc00 // fmul v0.4s, v0.4s, v16.4s
	WORD $0x4e21a800 // fcvtns v0.4s, v0.4s
	WORD $0x6e31dc21 // fmul v1.4s, v1.4s, v17.4s
	WORD $0x4e21a821 // fcvtns v1.4s, v1.4s
	WORD $0x6e32dc42 // fmul v2.4s, v2.4s, v18.4s
	WORD $0x4e21a842 // fcvtns v2.4s, v2.4s
	WORD $0x6e33dc63 // fmul v3.4s, v3.4s, v19.4s
	WORD $0x4e21a863 // fcvtns v3.4s, v3.4s
	WORD $0x0e614804 // sqxtn v4.4h, v0.4s
	WORD $0x4e614824 // sqxtn2 v4.8h, v1.4s
	WORD $0x0e614845 // sqxtn v5.4h, v2.4s
	WORD $0x4e614865 // sqxtn2 v5.8h, v3.4s
	WORD $0x0e214886 // sqxtn v6.8b, v4.8h
	WORD $0x4e2148a6 // sqxtn2 v6.16b, v5.8h
	WORD $0x3c848046 // stur q6, [x2, #72]
	WORD $0x3dc01420 // ldr q0, [x1, #80]
	WORD $0x3dc01521 // ldr q1, [x9, #80]
	WORD $0x3dc01542 // ldr q2, [x10, #80]
	WORD $0x3dc01563 // ldr q3, [x11, #80]
	WORD $0x6e30dc00 // fmul v0.4s, v0.4s, v16.4s
	WORD $0x4e21a800 // fcvtns v0.4s, v0.4s
	WORD $0x6e31dc21 // fmul v1.4s, v1.4s, v17.4s
	WORD $0x4e21a821 // fcvtns v1.4s, v1.4s
	WORD $0x6e32dc42 // fmul v2.4s, v2.4s, v18.4s
	WORD $0x4e21a842 // fcvtns v2.4s, v2.4s
	WORD $0x6e33dc63 // fmul v3.4s, v3.4s, v19.4s
	WORD $0x4e21a863 // fcvtns v3.4s, v3.4s
	WORD $0x0e614804 // sqxtn v4.4h, v0.4s
	WORD $0x4e614824 // sqxtn2 v4.8h, v1.4s
	WORD $0x0e614845 // sqxtn v5.4h, v2.4s
	WORD $0x4e614865 // sqxtn2 v5.8h, v3.4s
	WORD $0x0e214886 // sqxtn v6.8b, v4.8h
	WORD $0x4e2148a6 // sqxtn2 v6.16b, v5.8h
	WORD $0x3c858046 // stur q6, [x2, #88]
	WORD $0x3dc01820 // ldr q0, [x1, #96]
	WORD $0x3dc01921 // ldr q1, [x9, #96]
	WORD $0x3dc01942 // ldr q2, [x10, #96]
	WORD $0x3dc01963 // ldr q3, [x11, #96]
	WORD $0x6e30dc00 // fmul v0.4s, v0.4s, v16.4s
	WORD $0x4e21a800 // fcvtns v0.4s, v0.4s
	WORD $0x6e31dc21 // fmul v1.4s, v1.4s, v17.4s
	WORD $0x4e21a821 // fcvtns v1.4s, v1.4s
	WORD $0x6e32dc42 // fmul v2.4s, v2.4s, v18.4s
	WORD $0x4e21a842 // fcvtns v2.4s, v2.4s
	WORD $0x6e33dc63 // fmul v3.4s, v3.4s, v19.4s
	WORD $0x4e21a863 // fcvtns v3.4s, v3.4s
	WORD $0x0e614804 // sqxtn v4.4h, v0.4s
	WORD $0x4e614824 // sqxtn2 v4.8h, v1.4s
	WORD $0x0e614845 // sqxtn v5.4h, v2.4s
	WORD $0x4e614865 // sqxtn2 v5.8h, v3.4s
	WORD $0x0e214886 // sqxtn v6.8b, v4.8h
	WORD $0x4e2148a6 // sqxtn2 v6.16b, v5.8h
	WORD $0x3c868046 // stur q6, [x2, #104]
	WORD $0x3dc01c20 // ldr q0, [x1, #112]
	WORD $0x3dc01d21 // ldr q1, [x9, #112]
	WORD $0x3dc01d42 // ldr q2, [x10, #112]
	WORD $0x3dc01d63 // ldr q3, [x11, #112]
	WORD $0x6e30dc00 // fmul v0.4s, v0.4s, v16.4s
	WORD $0x4e21a800 // fcvtns v0.4s, v0.4s
	WORD $0x6e31dc21 // fmul v1.4s, v1.4s, v17.4s
	WORD $0x4e21a821 // fcvtns v1.4s, v1.4s
	WORD $0x6e32dc42 // fmul v2.4s, v2.4s, v18.4s
	WORD $0x4e21a842 // fcvtns v2.4s, v2.4s
	WORD $0x6e33dc63 // fmul v3.4s, v3.4s, v19.4s
	WORD $0x4e21a863 // fcvtns v3.4s, v3.4s
	WORD $0x0e614804 // sqxtn v4.4h, v0.4s
	WORD $0x4e614824 // sqxtn2 v4.8h, v1.4s
	WORD $0x0e614845 // sqxtn v5.4h, v2.4s
	WORD $0x4e614865 // sqxtn2 v5.8h, v3.4s
	WORD $0x0e214886 // sqxtn v6.8b, v4.8h
	WORD $0x4e2148a6 // sqxtn2 v6.16b, v5.8h
	WORD $0x3c878046 // stur q6, [x2, #120]
	ADD	$128, R1, R1
	ADD	$128, R9, R9
	ADD	$128, R10, R10
	ADD	$128, R11, R11
	ADD	$136, R2, R2
	SUB	$1, R4, R4
	CBNZ	R4, q44blk
q44done:
	RET
q44oob:
	B	ovr_oob
