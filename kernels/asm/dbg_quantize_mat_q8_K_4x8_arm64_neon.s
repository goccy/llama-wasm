// dbg_quantize_mat_q8_K_4x8: quantize four f32 rows into block_q8_Kx4 (FMAXV/FMINV max, FCVTNS quants, ADDV chunk sums).
	MOVD	l0+8(FP), R1
	MOVD	l1+16(FP), R2
	MOVD	l2+24(FP), R3
	LSR	$8, R3, R4
	CBZ	R4, qmdone
	LSL	$2, R3, R3
	ADD	R3<<2, R1, R27
	CMP	R27, R21
	BLO	qmoob
	MOVD	$1168, R26
	MUL	R4, R26, R26
	ADD	R2, R26, R27
	CMP	R27, R21
	BLO	qmoob
	ADD	R20, R1, R1
	ADD	R20, R2, R2
	MOVW	$0x42fe0000, R11
	WORD $0x1e27016e // fmov s14, w11
	WORD $0x1e2e100f // fmov s15, #1.0
qmblk:
	MOVD	R1, R6
	MOVD	R2, R7
	MOVD	R2, R8
	MOVW	$4, R5
qmrow:
	MOVD	R6, R10
	WORD $0x3dc00140 // ldr q0, [x10, #0]
	WORD $0x4ea01c01 // mov v1.16b, v0.16b
	MOVW	$16, R9
qmmax:
	WORD $0x3cc10542 // ldr q2, [x10], #16
	WORD $0x3cc10543 // ldr q3, [x10], #16
	WORD $0x3cc10544 // ldr q4, [x10], #16
	WORD $0x3cc10545 // ldr q5, [x10], #16
	WORD $0x4e22f400 // fmax v0.4s, v0.4s, v2.4s
	WORD $0x4ea2f421 // fmin v1.4s, v1.4s, v2.4s
	WORD $0x4e23f400 // fmax v0.4s, v0.4s, v3.4s
	WORD $0x4ea3f421 // fmin v1.4s, v1.4s, v3.4s
	WORD $0x4e24f400 // fmax v0.4s, v0.4s, v4.4s
	WORD $0x4ea4f421 // fmin v1.4s, v1.4s, v4.4s
	WORD $0x4e25f400 // fmax v0.4s, v0.4s, v5.4s
	WORD $0x4ea5f421 // fmin v1.4s, v1.4s, v5.4s
	SUBW	$1, R9, R9
	CBNZW	R9, qmmax
	WORD $0x6e30f800 // fmaxv s0, v0.4s
	WORD $0x6eb0f821 // fminv s1, v1.4s
	WORD $0x1e214026 // fneg s6, s1
	WORD $0x1e262000 // fcmp s0, s6
	WORD $0x1e21ac02 // fcsel s2, s0, s1, ge
	WORD $0x1e26ac06 // fcsel s6, s0, s6, ge
	WORD $0x1e2020c8 // fcmp s6, #0.0
	BEQ	qmzero
	WORD $0x1e2219c7 // fdiv s7, s14, s2
	WORD $0x1e2140e7 // fneg s7, s7
	WORD $0x1e2719e3 // fdiv s3, s15, s7
	B	qmscale
qmzero:
	WORD $0x1e2703e7 // fmov s7, wzr
	WORD $0x1e2703e3 // fmov s3, wzr
qmscale:
	WORD $0xbd000103 // str s3, [x8, #0]
	WORD $0x4e0404e7 // dup v7.4s, v7.s[0]
	WORD $0x3dc000c8 // ldr q8, [x6, #0]
	WORD $0x3dc004c9 // ldr q9, [x6, #16]
	WORD $0x6e27dd08 // fmul v8.4s, v8.4s, v7.4s
	WORD $0x6e27dd29 // fmul v9.4s, v9.4s, v7.4s
	WORD $0x4e21a908 // fcvtns v8.4s, v8.4s
	WORD $0x4e21a929 // fcvtns v9.4s, v9.4s
	WORD $0x0e61490a // sqxtn v10.4h, v8.4s
	WORD $0x4e61492a // sqxtn2 v10.8h, v9.4s
	WORD $0x0e21494b // sqxtn v11.8b, v10.8h
	WORD $0xfd0008eb // str d11, [x7, #16]
	WORD $0x4eaa1d4c // mov v12.16b, v10.16b
	WORD $0x3dc008c8 // ldr q8, [x6, #32]
	WORD $0x3dc00cc9 // ldr q9, [x6, #48]
	WORD $0x6e27dd08 // fmul v8.4s, v8.4s, v7.4s
	WORD $0x6e27dd29 // fmul v9.4s, v9.4s, v7.4s
	WORD $0x4e21a908 // fcvtns v8.4s, v8.4s
	WORD $0x4e21a929 // fcvtns v9.4s, v9.4s
	WORD $0x0e61490a // sqxtn v10.4h, v8.4s
	WORD $0x4e61492a // sqxtn2 v10.8h, v9.4s
	WORD $0x0e21494b // sqxtn v11.8b, v10.8h
	WORD $0xfd0018eb // str d11, [x7, #48]
	WORD $0x4e6a858c // add v12.8h, v12.8h, v10.8h
	WORD $0x4e71b98d // addv h13, v12.8h
	WORD $0x7d0820ed // str h13, [x7, #1040]
	WORD $0x3dc010c8 // ldr q8, [x6, #64]
	WORD $0x3dc014c9 // ldr q9, [x6, #80]
	WORD $0x6e27dd08 // fmul v8.4s, v8.4s, v7.4s
	WORD $0x6e27dd29 // fmul v9.4s, v9.4s, v7.4s
	WORD $0x4e21a908 // fcvtns v8.4s, v8.4s
	WORD $0x4e21a929 // fcvtns v9.4s, v9.4s
	WORD $0x0e61490a // sqxtn v10.4h, v8.4s
	WORD $0x4e61492a // sqxtn2 v10.8h, v9.4s
	WORD $0x0e21494b // sqxtn v11.8b, v10.8h
	WORD $0xfd0028eb // str d11, [x7, #80]
	WORD $0x4eaa1d4c // mov v12.16b, v10.16b
	WORD $0x3dc018c8 // ldr q8, [x6, #96]
	WORD $0x3dc01cc9 // ldr q9, [x6, #112]
	WORD $0x6e27dd08 // fmul v8.4s, v8.4s, v7.4s
	WORD $0x6e27dd29 // fmul v9.4s, v9.4s, v7.4s
	WORD $0x4e21a908 // fcvtns v8.4s, v8.4s
	WORD $0x4e21a929 // fcvtns v9.4s, v9.4s
	WORD $0x0e61490a // sqxtn v10.4h, v8.4s
	WORD $0x4e61492a // sqxtn2 v10.8h, v9.4s
	WORD $0x0e21494b // sqxtn v11.8b, v10.8h
	WORD $0xfd0038eb // str d11, [x7, #112]
	WORD $0x4e6a858c // add v12.8h, v12.8h, v10.8h
	WORD $0x4e71b98d // addv h13, v12.8h
	WORD $0x7d0824ed // str h13, [x7, #1042]
	WORD $0x3dc020c8 // ldr q8, [x6, #128]
	WORD $0x3dc024c9 // ldr q9, [x6, #144]
	WORD $0x6e27dd08 // fmul v8.4s, v8.4s, v7.4s
	WORD $0x6e27dd29 // fmul v9.4s, v9.4s, v7.4s
	WORD $0x4e21a908 // fcvtns v8.4s, v8.4s
	WORD $0x4e21a929 // fcvtns v9.4s, v9.4s
	WORD $0x0e61490a // sqxtn v10.4h, v8.4s
	WORD $0x4e61492a // sqxtn2 v10.8h, v9.4s
	WORD $0x0e21494b // sqxtn v11.8b, v10.8h
	WORD $0xfd0048eb // str d11, [x7, #144]
	WORD $0x4eaa1d4c // mov v12.16b, v10.16b
	WORD $0x3dc028c8 // ldr q8, [x6, #160]
	WORD $0x3dc02cc9 // ldr q9, [x6, #176]
	WORD $0x6e27dd08 // fmul v8.4s, v8.4s, v7.4s
	WORD $0x6e27dd29 // fmul v9.4s, v9.4s, v7.4s
	WORD $0x4e21a908 // fcvtns v8.4s, v8.4s
	WORD $0x4e21a929 // fcvtns v9.4s, v9.4s
	WORD $0x0e61490a // sqxtn v10.4h, v8.4s
	WORD $0x4e61492a // sqxtn2 v10.8h, v9.4s
	WORD $0x0e21494b // sqxtn v11.8b, v10.8h
	WORD $0xfd0058eb // str d11, [x7, #176]
	WORD $0x4e6a858c // add v12.8h, v12.8h, v10.8h
	WORD $0x4e71b98d // addv h13, v12.8h
	WORD $0x7d0828ed // str h13, [x7, #1044]
	WORD $0x3dc030c8 // ldr q8, [x6, #192]
	WORD $0x3dc034c9 // ldr q9, [x6, #208]
	WORD $0x6e27dd08 // fmul v8.4s, v8.4s, v7.4s
	WORD $0x6e27dd29 // fmul v9.4s, v9.4s, v7.4s
	WORD $0x4e21a908 // fcvtns v8.4s, v8.4s
	WORD $0x4e21a929 // fcvtns v9.4s, v9.4s
	WORD $0x0e61490a // sqxtn v10.4h, v8.4s
	WORD $0x4e61492a // sqxtn2 v10.8h, v9.4s
	WORD $0x0e21494b // sqxtn v11.8b, v10.8h
	WORD $0xfd0068eb // str d11, [x7, #208]
	WORD $0x4eaa1d4c // mov v12.16b, v10.16b
	WORD $0x3dc038c8 // ldr q8, [x6, #224]
	WORD $0x3dc03cc9 // ldr q9, [x6, #240]
	WORD $0x6e27dd08 // fmul v8.4s, v8.4s, v7.4s
	WORD $0x6e27dd29 // fmul v9.4s, v9.4s, v7.4s
	WORD $0x4e21a908 // fcvtns v8.4s, v8.4s
	WORD $0x4e21a929 // fcvtns v9.4s, v9.4s
	WORD $0x0e61490a // sqxtn v10.4h, v8.4s
	WORD $0x4e61492a // sqxtn2 v10.8h, v9.4s
	WORD $0x0e21494b // sqxtn v11.8b, v10.8h
	WORD $0xfd0078eb // str d11, [x7, #240]
	WORD $0x4e6a858c // add v12.8h, v12.8h, v10.8h
	WORD $0x4e71b98d // addv h13, v12.8h
	WORD $0x7d082ced // str h13, [x7, #1046]
	WORD $0x3dc040c8 // ldr q8, [x6, #256]
	WORD $0x3dc044c9 // ldr q9, [x6, #272]
	WORD $0x6e27dd08 // fmul v8.4s, v8.4s, v7.4s
	WORD $0x6e27dd29 // fmul v9.4s, v9.4s, v7.4s
	WORD $0x4e21a908 // fcvtns v8.4s, v8.4s
	WORD $0x4e21a929 // fcvtns v9.4s, v9.4s
	WORD $0x0e61490a // sqxtn v10.4h, v8.4s
	WORD $0x4e61492a // sqxtn2 v10.8h, v9.4s
	WORD $0x0e21494b // sqxtn v11.8b, v10.8h
	WORD $0xfd0088eb // str d11, [x7, #272]
	WORD $0x4eaa1d4c // mov v12.16b, v10.16b
	WORD $0x3dc048c8 // ldr q8, [x6, #288]
	WORD $0x3dc04cc9 // ldr q9, [x6, #304]
	WORD $0x6e27dd08 // fmul v8.4s, v8.4s, v7.4s
	WORD $0x6e27dd29 // fmul v9.4s, v9.4s, v7.4s
	WORD $0x4e21a908 // fcvtns v8.4s, v8.4s
	WORD $0x4e21a929 // fcvtns v9.4s, v9.4s
	WORD $0x0e61490a // sqxtn v10.4h, v8.4s
	WORD $0x4e61492a // sqxtn2 v10.8h, v9.4s
	WORD $0x0e21494b // sqxtn v11.8b, v10.8h
	WORD $0xfd0098eb // str d11, [x7, #304]
	WORD $0x4e6a858c // add v12.8h, v12.8h, v10.8h
	WORD $0x4e71b98d // addv h13, v12.8h
	WORD $0x7d0860ed // str h13, [x7, #1072]
	WORD $0x3dc050c8 // ldr q8, [x6, #320]
	WORD $0x3dc054c9 // ldr q9, [x6, #336]
	WORD $0x6e27dd08 // fmul v8.4s, v8.4s, v7.4s
	WORD $0x6e27dd29 // fmul v9.4s, v9.4s, v7.4s
	WORD $0x4e21a908 // fcvtns v8.4s, v8.4s
	WORD $0x4e21a929 // fcvtns v9.4s, v9.4s
	WORD $0x0e61490a // sqxtn v10.4h, v8.4s
	WORD $0x4e61492a // sqxtn2 v10.8h, v9.4s
	WORD $0x0e21494b // sqxtn v11.8b, v10.8h
	WORD $0xfd00a8eb // str d11, [x7, #336]
	WORD $0x4eaa1d4c // mov v12.16b, v10.16b
	WORD $0x3dc058c8 // ldr q8, [x6, #352]
	WORD $0x3dc05cc9 // ldr q9, [x6, #368]
	WORD $0x6e27dd08 // fmul v8.4s, v8.4s, v7.4s
	WORD $0x6e27dd29 // fmul v9.4s, v9.4s, v7.4s
	WORD $0x4e21a908 // fcvtns v8.4s, v8.4s
	WORD $0x4e21a929 // fcvtns v9.4s, v9.4s
	WORD $0x0e61490a // sqxtn v10.4h, v8.4s
	WORD $0x4e61492a // sqxtn2 v10.8h, v9.4s
	WORD $0x0e21494b // sqxtn v11.8b, v10.8h
	WORD $0xfd00b8eb // str d11, [x7, #368]
	WORD $0x4e6a858c // add v12.8h, v12.8h, v10.8h
	WORD $0x4e71b98d // addv h13, v12.8h
	WORD $0x7d0864ed // str h13, [x7, #1074]
	WORD $0x3dc060c8 // ldr q8, [x6, #384]
	WORD $0x3dc064c9 // ldr q9, [x6, #400]
	WORD $0x6e27dd08 // fmul v8.4s, v8.4s, v7.4s
	WORD $0x6e27dd29 // fmul v9.4s, v9.4s, v7.4s
	WORD $0x4e21a908 // fcvtns v8.4s, v8.4s
	WORD $0x4e21a929 // fcvtns v9.4s, v9.4s
	WORD $0x0e61490a // sqxtn v10.4h, v8.4s
	WORD $0x4e61492a // sqxtn2 v10.8h, v9.4s
	WORD $0x0e21494b // sqxtn v11.8b, v10.8h
	WORD $0xfd00c8eb // str d11, [x7, #400]
	WORD $0x4eaa1d4c // mov v12.16b, v10.16b
	WORD $0x3dc068c8 // ldr q8, [x6, #416]
	WORD $0x3dc06cc9 // ldr q9, [x6, #432]
	WORD $0x6e27dd08 // fmul v8.4s, v8.4s, v7.4s
	WORD $0x6e27dd29 // fmul v9.4s, v9.4s, v7.4s
	WORD $0x4e21a908 // fcvtns v8.4s, v8.4s
	WORD $0x4e21a929 // fcvtns v9.4s, v9.4s
	WORD $0x0e61490a // sqxtn v10.4h, v8.4s
	WORD $0x4e61492a // sqxtn2 v10.8h, v9.4s
	WORD $0x0e21494b // sqxtn v11.8b, v10.8h
	WORD $0xfd00d8eb // str d11, [x7, #432]
	WORD $0x4e6a858c // add v12.8h, v12.8h, v10.8h
	WORD $0x4e71b98d // addv h13, v12.8h
	WORD $0x7d0868ed // str h13, [x7, #1076]
	WORD $0x3dc070c8 // ldr q8, [x6, #448]
	WORD $0x3dc074c9 // ldr q9, [x6, #464]
	WORD $0x6e27dd08 // fmul v8.4s, v8.4s, v7.4s
	WORD $0x6e27dd29 // fmul v9.4s, v9.4s, v7.4s
	WORD $0x4e21a908 // fcvtns v8.4s, v8.4s
	WORD $0x4e21a929 // fcvtns v9.4s, v9.4s
	WORD $0x0e61490a // sqxtn v10.4h, v8.4s
	WORD $0x4e61492a // sqxtn2 v10.8h, v9.4s
	WORD $0x0e21494b // sqxtn v11.8b, v10.8h
	WORD $0xfd00e8eb // str d11, [x7, #464]
	WORD $0x4eaa1d4c // mov v12.16b, v10.16b
	WORD $0x3dc078c8 // ldr q8, [x6, #480]
	WORD $0x3dc07cc9 // ldr q9, [x6, #496]
	WORD $0x6e27dd08 // fmul v8.4s, v8.4s, v7.4s
	WORD $0x6e27dd29 // fmul v9.4s, v9.4s, v7.4s
	WORD $0x4e21a908 // fcvtns v8.4s, v8.4s
	WORD $0x4e21a929 // fcvtns v9.4s, v9.4s
	WORD $0x0e61490a // sqxtn v10.4h, v8.4s
	WORD $0x4e61492a // sqxtn2 v10.8h, v9.4s
	WORD $0x0e21494b // sqxtn v11.8b, v10.8h
	WORD $0xfd00f8eb // str d11, [x7, #496]
	WORD $0x4e6a858c // add v12.8h, v12.8h, v10.8h
	WORD $0x4e71b98d // addv h13, v12.8h
	WORD $0x7d086ced // str h13, [x7, #1078]
	WORD $0x3dc080c8 // ldr q8, [x6, #512]
	WORD $0x3dc084c9 // ldr q9, [x6, #528]
	WORD $0x6e27dd08 // fmul v8.4s, v8.4s, v7.4s
	WORD $0x6e27dd29 // fmul v9.4s, v9.4s, v7.4s
	WORD $0x4e21a908 // fcvtns v8.4s, v8.4s
	WORD $0x4e21a929 // fcvtns v9.4s, v9.4s
	WORD $0x0e61490a // sqxtn v10.4h, v8.4s
	WORD $0x4e61492a // sqxtn2 v10.8h, v9.4s
	WORD $0x0e21494b // sqxtn v11.8b, v10.8h
	WORD $0xfd0108eb // str d11, [x7, #528]
	WORD $0x4eaa1d4c // mov v12.16b, v10.16b
	WORD $0x3dc088c8 // ldr q8, [x6, #544]
	WORD $0x3dc08cc9 // ldr q9, [x6, #560]
	WORD $0x6e27dd08 // fmul v8.4s, v8.4s, v7.4s
	WORD $0x6e27dd29 // fmul v9.4s, v9.4s, v7.4s
	WORD $0x4e21a908 // fcvtns v8.4s, v8.4s
	WORD $0x4e21a929 // fcvtns v9.4s, v9.4s
	WORD $0x0e61490a // sqxtn v10.4h, v8.4s
	WORD $0x4e61492a // sqxtn2 v10.8h, v9.4s
	WORD $0x0e21494b // sqxtn v11.8b, v10.8h
	WORD $0xfd0118eb // str d11, [x7, #560]
	WORD $0x4e6a858c // add v12.8h, v12.8h, v10.8h
	WORD $0x4e71b98d // addv h13, v12.8h
	WORD $0x7d08a0ed // str h13, [x7, #1104]
	WORD $0x3dc090c8 // ldr q8, [x6, #576]
	WORD $0x3dc094c9 // ldr q9, [x6, #592]
	WORD $0x6e27dd08 // fmul v8.4s, v8.4s, v7.4s
	WORD $0x6e27dd29 // fmul v9.4s, v9.4s, v7.4s
	WORD $0x4e21a908 // fcvtns v8.4s, v8.4s
	WORD $0x4e21a929 // fcvtns v9.4s, v9.4s
	WORD $0x0e61490a // sqxtn v10.4h, v8.4s
	WORD $0x4e61492a // sqxtn2 v10.8h, v9.4s
	WORD $0x0e21494b // sqxtn v11.8b, v10.8h
	WORD $0xfd0128eb // str d11, [x7, #592]
	WORD $0x4eaa1d4c // mov v12.16b, v10.16b
	WORD $0x3dc098c8 // ldr q8, [x6, #608]
	WORD $0x3dc09cc9 // ldr q9, [x6, #624]
	WORD $0x6e27dd08 // fmul v8.4s, v8.4s, v7.4s
	WORD $0x6e27dd29 // fmul v9.4s, v9.4s, v7.4s
	WORD $0x4e21a908 // fcvtns v8.4s, v8.4s
	WORD $0x4e21a929 // fcvtns v9.4s, v9.4s
	WORD $0x0e61490a // sqxtn v10.4h, v8.4s
	WORD $0x4e61492a // sqxtn2 v10.8h, v9.4s
	WORD $0x0e21494b // sqxtn v11.8b, v10.8h
	WORD $0xfd0138eb // str d11, [x7, #624]
	WORD $0x4e6a858c // add v12.8h, v12.8h, v10.8h
	WORD $0x4e71b98d // addv h13, v12.8h
	WORD $0x7d08a4ed // str h13, [x7, #1106]
	WORD $0x3dc0a0c8 // ldr q8, [x6, #640]
	WORD $0x3dc0a4c9 // ldr q9, [x6, #656]
	WORD $0x6e27dd08 // fmul v8.4s, v8.4s, v7.4s
	WORD $0x6e27dd29 // fmul v9.4s, v9.4s, v7.4s
	WORD $0x4e21a908 // fcvtns v8.4s, v8.4s
	WORD $0x4e21a929 // fcvtns v9.4s, v9.4s
	WORD $0x0e61490a // sqxtn v10.4h, v8.4s
	WORD $0x4e61492a // sqxtn2 v10.8h, v9.4s
	WORD $0x0e21494b // sqxtn v11.8b, v10.8h
	WORD $0xfd0148eb // str d11, [x7, #656]
	WORD $0x4eaa1d4c // mov v12.16b, v10.16b
	WORD $0x3dc0a8c8 // ldr q8, [x6, #672]
	WORD $0x3dc0acc9 // ldr q9, [x6, #688]
	WORD $0x6e27dd08 // fmul v8.4s, v8.4s, v7.4s
	WORD $0x6e27dd29 // fmul v9.4s, v9.4s, v7.4s
	WORD $0x4e21a908 // fcvtns v8.4s, v8.4s
	WORD $0x4e21a929 // fcvtns v9.4s, v9.4s
	WORD $0x0e61490a // sqxtn v10.4h, v8.4s
	WORD $0x4e61492a // sqxtn2 v10.8h, v9.4s
	WORD $0x0e21494b // sqxtn v11.8b, v10.8h
	WORD $0xfd0158eb // str d11, [x7, #688]
	WORD $0x4e6a858c // add v12.8h, v12.8h, v10.8h
	WORD $0x4e71b98d // addv h13, v12.8h
	WORD $0x7d08a8ed // str h13, [x7, #1108]
	WORD $0x3dc0b0c8 // ldr q8, [x6, #704]
	WORD $0x3dc0b4c9 // ldr q9, [x6, #720]
	WORD $0x6e27dd08 // fmul v8.4s, v8.4s, v7.4s
	WORD $0x6e27dd29 // fmul v9.4s, v9.4s, v7.4s
	WORD $0x4e21a908 // fcvtns v8.4s, v8.4s
	WORD $0x4e21a929 // fcvtns v9.4s, v9.4s
	WORD $0x0e61490a // sqxtn v10.4h, v8.4s
	WORD $0x4e61492a // sqxtn2 v10.8h, v9.4s
	WORD $0x0e21494b // sqxtn v11.8b, v10.8h
	WORD $0xfd0168eb // str d11, [x7, #720]
	WORD $0x4eaa1d4c // mov v12.16b, v10.16b
	WORD $0x3dc0b8c8 // ldr q8, [x6, #736]
	WORD $0x3dc0bcc9 // ldr q9, [x6, #752]
	WORD $0x6e27dd08 // fmul v8.4s, v8.4s, v7.4s
	WORD $0x6e27dd29 // fmul v9.4s, v9.4s, v7.4s
	WORD $0x4e21a908 // fcvtns v8.4s, v8.4s
	WORD $0x4e21a929 // fcvtns v9.4s, v9.4s
	WORD $0x0e61490a // sqxtn v10.4h, v8.4s
	WORD $0x4e61492a // sqxtn2 v10.8h, v9.4s
	WORD $0x0e21494b // sqxtn v11.8b, v10.8h
	WORD $0xfd0178eb // str d11, [x7, #752]
	WORD $0x4e6a858c // add v12.8h, v12.8h, v10.8h
	WORD $0x4e71b98d // addv h13, v12.8h
	WORD $0x7d08aced // str h13, [x7, #1110]
	WORD $0x3dc0c0c8 // ldr q8, [x6, #768]
	WORD $0x3dc0c4c9 // ldr q9, [x6, #784]
	WORD $0x6e27dd08 // fmul v8.4s, v8.4s, v7.4s
	WORD $0x6e27dd29 // fmul v9.4s, v9.4s, v7.4s
	WORD $0x4e21a908 // fcvtns v8.4s, v8.4s
	WORD $0x4e21a929 // fcvtns v9.4s, v9.4s
	WORD $0x0e61490a // sqxtn v10.4h, v8.4s
	WORD $0x4e61492a // sqxtn2 v10.8h, v9.4s
	WORD $0x0e21494b // sqxtn v11.8b, v10.8h
	WORD $0xfd0188eb // str d11, [x7, #784]
	WORD $0x4eaa1d4c // mov v12.16b, v10.16b
	WORD $0x3dc0c8c8 // ldr q8, [x6, #800]
	WORD $0x3dc0ccc9 // ldr q9, [x6, #816]
	WORD $0x6e27dd08 // fmul v8.4s, v8.4s, v7.4s
	WORD $0x6e27dd29 // fmul v9.4s, v9.4s, v7.4s
	WORD $0x4e21a908 // fcvtns v8.4s, v8.4s
	WORD $0x4e21a929 // fcvtns v9.4s, v9.4s
	WORD $0x0e61490a // sqxtn v10.4h, v8.4s
	WORD $0x4e61492a // sqxtn2 v10.8h, v9.4s
	WORD $0x0e21494b // sqxtn v11.8b, v10.8h
	WORD $0xfd0198eb // str d11, [x7, #816]
	WORD $0x4e6a858c // add v12.8h, v12.8h, v10.8h
	WORD $0x4e71b98d // addv h13, v12.8h
	WORD $0x7d08e0ed // str h13, [x7, #1136]
	WORD $0x3dc0d0c8 // ldr q8, [x6, #832]
	WORD $0x3dc0d4c9 // ldr q9, [x6, #848]
	WORD $0x6e27dd08 // fmul v8.4s, v8.4s, v7.4s
	WORD $0x6e27dd29 // fmul v9.4s, v9.4s, v7.4s
	WORD $0x4e21a908 // fcvtns v8.4s, v8.4s
	WORD $0x4e21a929 // fcvtns v9.4s, v9.4s
	WORD $0x0e61490a // sqxtn v10.4h, v8.4s
	WORD $0x4e61492a // sqxtn2 v10.8h, v9.4s
	WORD $0x0e21494b // sqxtn v11.8b, v10.8h
	WORD $0xfd01a8eb // str d11, [x7, #848]
	WORD $0x4eaa1d4c // mov v12.16b, v10.16b
	WORD $0x3dc0d8c8 // ldr q8, [x6, #864]
	WORD $0x3dc0dcc9 // ldr q9, [x6, #880]
	WORD $0x6e27dd08 // fmul v8.4s, v8.4s, v7.4s
	WORD $0x6e27dd29 // fmul v9.4s, v9.4s, v7.4s
	WORD $0x4e21a908 // fcvtns v8.4s, v8.4s
	WORD $0x4e21a929 // fcvtns v9.4s, v9.4s
	WORD $0x0e61490a // sqxtn v10.4h, v8.4s
	WORD $0x4e61492a // sqxtn2 v10.8h, v9.4s
	WORD $0x0e21494b // sqxtn v11.8b, v10.8h
	WORD $0xfd01b8eb // str d11, [x7, #880]
	WORD $0x4e6a858c // add v12.8h, v12.8h, v10.8h
	WORD $0x4e71b98d // addv h13, v12.8h
	WORD $0x7d08e4ed // str h13, [x7, #1138]
	WORD $0x3dc0e0c8 // ldr q8, [x6, #896]
	WORD $0x3dc0e4c9 // ldr q9, [x6, #912]
	WORD $0x6e27dd08 // fmul v8.4s, v8.4s, v7.4s
	WORD $0x6e27dd29 // fmul v9.4s, v9.4s, v7.4s
	WORD $0x4e21a908 // fcvtns v8.4s, v8.4s
	WORD $0x4e21a929 // fcvtns v9.4s, v9.4s
	WORD $0x0e61490a // sqxtn v10.4h, v8.4s
	WORD $0x4e61492a // sqxtn2 v10.8h, v9.4s
	WORD $0x0e21494b // sqxtn v11.8b, v10.8h
	WORD $0xfd01c8eb // str d11, [x7, #912]
	WORD $0x4eaa1d4c // mov v12.16b, v10.16b
	WORD $0x3dc0e8c8 // ldr q8, [x6, #928]
	WORD $0x3dc0ecc9 // ldr q9, [x6, #944]
	WORD $0x6e27dd08 // fmul v8.4s, v8.4s, v7.4s
	WORD $0x6e27dd29 // fmul v9.4s, v9.4s, v7.4s
	WORD $0x4e21a908 // fcvtns v8.4s, v8.4s
	WORD $0x4e21a929 // fcvtns v9.4s, v9.4s
	WORD $0x0e61490a // sqxtn v10.4h, v8.4s
	WORD $0x4e61492a // sqxtn2 v10.8h, v9.4s
	WORD $0x0e21494b // sqxtn v11.8b, v10.8h
	WORD $0xfd01d8eb // str d11, [x7, #944]
	WORD $0x4e6a858c // add v12.8h, v12.8h, v10.8h
	WORD $0x4e71b98d // addv h13, v12.8h
	WORD $0x7d08e8ed // str h13, [x7, #1140]
	WORD $0x3dc0f0c8 // ldr q8, [x6, #960]
	WORD $0x3dc0f4c9 // ldr q9, [x6, #976]
	WORD $0x6e27dd08 // fmul v8.4s, v8.4s, v7.4s
	WORD $0x6e27dd29 // fmul v9.4s, v9.4s, v7.4s
	WORD $0x4e21a908 // fcvtns v8.4s, v8.4s
	WORD $0x4e21a929 // fcvtns v9.4s, v9.4s
	WORD $0x0e61490a // sqxtn v10.4h, v8.4s
	WORD $0x4e61492a // sqxtn2 v10.8h, v9.4s
	WORD $0x0e21494b // sqxtn v11.8b, v10.8h
	WORD $0xfd01e8eb // str d11, [x7, #976]
	WORD $0x4eaa1d4c // mov v12.16b, v10.16b
	WORD $0x3dc0f8c8 // ldr q8, [x6, #992]
	WORD $0x3dc0fcc9 // ldr q9, [x6, #1008]
	WORD $0x6e27dd08 // fmul v8.4s, v8.4s, v7.4s
	WORD $0x6e27dd29 // fmul v9.4s, v9.4s, v7.4s
	WORD $0x4e21a908 // fcvtns v8.4s, v8.4s
	WORD $0x4e21a929 // fcvtns v9.4s, v9.4s
	WORD $0x0e61490a // sqxtn v10.4h, v8.4s
	WORD $0x4e61492a // sqxtn2 v10.8h, v9.4s
	WORD $0x0e21494b // sqxtn v11.8b, v10.8h
	WORD $0xfd01f8eb // str d11, [x7, #1008]
	WORD $0x4e6a858c // add v12.8h, v12.8h, v10.8h
	WORD $0x4e71b98d // addv h13, v12.8h
	WORD $0x7d08eced // str h13, [x7, #1142]
	ADD	R6, R3, R6
	ADD	$8, R7, R7
	ADD	$4, R8, R8
	SUBW	$1, R5, R5
	CBNZW	R5, qmrow
	ADD	$1024, R1, R1
	ADD	$1168, R2, R2
	SUB	$1, R4, R4
	CBNZ	R4, qmblk
qmdone:
	RET
qmoob:
	B	ovr_oob
