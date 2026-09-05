// dbg_flash_attn_kv_f16: single-query flash-attention KV loop (F16 K/V, f32 VKQ), exp in registers.
	MOVD	l0+8(FP), R0
	ADD	$96, R0, R27
	CMP	R27, R21
	BLO	faoob
	ADD	R20, R0, R0
	MOVW	88(R0), R1
	MOVW	92(R0), R2
	MOVD	0(R0), R3
	MOVD	8(R0), R4
	MOVD	16(R0), R5
	MOVD	24(R0), R6
	MOVD	32(R0), R7
	MOVD	40(R0), R8
	MOVD	64(R0), R12
	MOVD	72(R0), R9
	MOVD	48(R0), R10
	MOVD	56(R0), R11
	FMOVS	80(R0), F15
	FMOVS	84(R0), F14
	ADD	$8, R10, R27
	CMP	R27, R21
	BLO	faoob
	ADD	R2<<2, R11, R27
	CMP	R27, R21
	BLO	faoob
	ADD	R1<<1, R3, R27
	CMP	R27, R21
	BLO	faoob
	ADD	R20, R10, R10
	ADD	R20, R11, R11
	ADD	R20, R3, R3
	WORD $0xbd40014c // ldr s12, [x10, #0]
	WORD $0xbd40054d // ldr s13, [x10, #4]
	SUB	R12, R9, R9
	CMP	$0, R9
	BLE	fadone
	MADD	R5, R4, R12, R4
	MADD	R7, R6, R12, R6
	SUB	$1, R9, R13
	MUL	R13, R5, R27
	ADD	R4, R27, R27
	ADD	R1<<1, R27, R27
	CMP	R27, R21
	BLO	faoob
	MUL	R13, R7, R27
	ADD	R6, R27, R27
	ADD	R2<<1, R27, R27
	CMP	R27, R21
	BLO	faoob
	ADD	R20, R4, R4
	ADD	R20, R6, R6
	CBZ	R8, famaskok
	ADD	R12<<1, R8, R8
	ADD	R9<<1, R8, R27
	CMP	R27, R21
	BLO	faoob
	ADD	R20, R8, R8
famaskok:
	MOVW	$0xff800000, R27
	WORD $0x1e270370 // fmov s16, w27
	LSRW	$3, R1, R22
	ANDW	$1, R22, R22
	LSRW	$3, R2, R23
	ANDW	$1, R23, R23
	LSRW	$4, R1, R1
	LSRW	$4, R2, R2
	CBNZW	R23, fhmslow
	CMPW	$4, R2
	BEQ	fhmfast
	CMPW	$8, R2
	BEQ	fhmfast
fhmslow:
	MOVD	$·ovr_dbg_flash_attn_kv_f16_fhm_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000(SB), R13
	VLD1	(R13), [V28.S4, V29.S4, V30.S4, V31.S4]
	WORD $0x4e0c07db // dup v27.4s, v30.s[1]
	WORD $0x4e1407da // dup v26.4s, v30.s[2]
	WORD $0x4e1c07d9 // dup v25.4s, v30.s[3]
	WORD $0x4e0407f8 // dup v24.4s, v31.s[0]
	WORD $0x4e0c07f7 // dup v23.4s, v31.s[1]
	WORD $0x4e040796 // dup v22.4s, v28.s[0]
	WORD $0x4e0c07b5 // dup v21.4s, v29.s[1]
	WORD $0x4e1c07b4 // dup v20.4s, v29.s[3]
fapos:
	WORD $0x1e2703f1 // fmov s17, wzr
	CBZ	R8, fadot
	WORD $0x7c402511 // ldr h17, [x8], #2
	WORD $0x1ee24231 // fcvt s17, h17
	WORD $0x1e2f0a31 // fmul s17, s17, s15
	WORD $0x1e302220 // fcmp s17, s16
	BEQ	faskip
fadot:
	MOVD	R4, R13
	MOVD	R3, R14
	MOVW	R1, R12
	WORD $0x4f000401 // movi v1.4s, #0
	WORD $0x4f000402 // movi v2.4s, #0
	CBZW	R12, fadottail
fadotloop:
	WORD $0x3cc105a3 // ldr q3, [x13], #16
	WORD $0x3cc105a4 // ldr q4, [x13], #16
	WORD $0x3cc105c5 // ldr q5, [x14], #16
	WORD $0x3cc105c6 // ldr q6, [x14], #16
	WORD $0x0e217867 // fcvtl v7.4s, v3.4h
	WORD $0x4e217868 // fcvtl2 v8.4s, v3.8h
	WORD $0x0e2178a9 // fcvtl v9.4s, v5.4h
	WORD $0x4e2178aa // fcvtl2 v10.4s, v5.8h
	WORD $0x4e29cce1 // fmla v1.4s, v7.4s, v9.4s
	WORD $0x4e2acd02 // fmla v2.4s, v8.4s, v10.4s
	WORD $0x0e217887 // fcvtl v7.4s, v4.4h
	WORD $0x4e217888 // fcvtl2 v8.4s, v4.8h
	WORD $0x0e2178c9 // fcvtl v9.4s, v6.4h
	WORD $0x4e2178ca // fcvtl2 v10.4s, v6.8h
	WORD $0x4e29cce1 // fmla v1.4s, v7.4s, v9.4s
	WORD $0x4e2acd02 // fmla v2.4s, v8.4s, v10.4s
	SUBW	$1, R12, R12
	CBNZW	R12, fadotloop
fadottail:
	CBZW	R22, fadotdone
	WORD $0x3dc001a3 // ldr q3, [x13, #0]
	WORD $0x3dc001c5 // ldr q5, [x14, #0]
	WORD $0x0e217867 // fcvtl v7.4s, v3.4h
	WORD $0x4e217868 // fcvtl2 v8.4s, v3.8h
	WORD $0x0e2178a9 // fcvtl v9.4s, v5.4h
	WORD $0x4e2178aa // fcvtl2 v10.4s, v5.8h
	WORD $0x4e29cce1 // fmla v1.4s, v7.4s, v9.4s
	WORD $0x4e2acd02 // fmla v2.4s, v8.4s, v10.4s
fadotdone:
	WORD $0x4e22d421 // fadd v1.4s, v1.4s, v2.4s
	WORD $0x6e21d421 // faddp v1.4s, v1.4s, v1.4s
	WORD $0x7e30d821 // faddp s1, v1.2s
	WORD $0x1f0e4421 // fmadd s1, s1, s14, s17
	WORD $0x1e2d2020 // fcmp s1, s13
	BGT	fanewmax
	WORD $0x1e2d3820 // fsub s0, s1, s13
	WORD $0x4e040400 // dup v0.4s, v0.s[0]
	WORD $0x4eb61ec1 // mov v1.16b, v22.16b
	WORD $0x4fbc1001 // fmla v1.4s, v0.4s, v28.s[1]
	WORD $0x4eb6d422 // fsub v2.4s, v1.4s, v22.4s
	WORD $0x4ea01c03 // mov v3.16b, v0.16b
	WORD $0x4f9c5843 // fmls v3.4s, v2.4s, v28.s[2]
	WORD $0x4fbc5843 // fmls v3.4s, v2.4s, v28.s[3]
	WORD $0x4f375424 // shl v4.4s, v1.4s, #23
	WORD $0x4eb98485 // add v5.4s, v4.4s, v25.4s
	WORD $0x4ea0f846 // fabs v6.4s, v2.4s
	WORD $0x6ebbe4c7 // fcmgt v7.4s, v6.4s, v27.4s
	WORD $0x6e23dc68 // fmul v8.4s, v3.4s, v3.4s
	WORD $0x4eb51ea9 // mov v9.16b, v21.16b
	WORD $0x4f9d1069 // fmla v9.4s, v3.4s, v29.s[0]
	WORD $0x4eb41e8a // mov v10.16b, v20.16b
	WORD $0x4f9d186a // fmla v10.4s, v3.4s, v29.s[2]
	WORD $0x4e28cd2a // fmla v10.4s, v9.4s, v8.4s
	WORD $0x4f9e906b // fmul v11.4s, v3.4s, v30.s[0]
	WORD $0x4e28cd4b // fmla v11.4s, v10.4s, v8.4s
	WORD $0x4ea51ca9 // mov v9.16b, v5.16b
	WORD $0x4e25cd69 // fmla v9.4s, v11.4s, v5.4s
	WORD $0x6ea0d841 // fcmle v1.4s, v2.4s, #0.0
	WORD $0x4e381c21 // and v1.16b, v1.16b, v24.16b
	WORD $0x4eb78423 // add v3.4s, v1.4s, v23.4s
	WORD $0x6ea18488 // sub v8.4s, v4.4s, v1.4s
	WORD $0x4ea81d0a // mov v10.16b, v8.16b
	WORD $0x4e2bcd0a // fmla v10.4s, v8.4s, v11.4s
	WORD $0x6e23dd4a // fmul v10.4s, v10.4s, v3.4s
	WORD $0x6e23dc65 // fmul v5.4s, v3.4s, v3.4s
	WORD $0x6ebae4c2 // fcmgt v2.4s, v6.4s, v26.4s
	WORD $0x6e691d47 // bsl v7.16b, v10.16b, v9.16b
	WORD $0x6e671ca2 // bsl v2.16b, v5.16b, v7.16b
	WORD $0x4ea21c40 // mov v0.16b, v2.16b
	FMOVS	F0, F19
	WORD $0x1e2e1012 // fmov s18, #1.0
	B	famad
fanewmax:
	WORD $0x1e2139a0 // fsub s0, s13, s1
	FMOVS	F1, F13
	WORD $0x4e040400 // dup v0.4s, v0.s[0]
	WORD $0x4eb61ec1 // mov v1.16b, v22.16b
	WORD $0x4fbc1001 // fmla v1.4s, v0.4s, v28.s[1]
	WORD $0x4eb6d422 // fsub v2.4s, v1.4s, v22.4s
	WORD $0x4ea01c03 // mov v3.16b, v0.16b
	WORD $0x4f9c5843 // fmls v3.4s, v2.4s, v28.s[2]
	WORD $0x4fbc5843 // fmls v3.4s, v2.4s, v28.s[3]
	WORD $0x4f375424 // shl v4.4s, v1.4s, #23
	WORD $0x4eb98485 // add v5.4s, v4.4s, v25.4s
	WORD $0x4ea0f846 // fabs v6.4s, v2.4s
	WORD $0x6ebbe4c7 // fcmgt v7.4s, v6.4s, v27.4s
	WORD $0x6e23dc68 // fmul v8.4s, v3.4s, v3.4s
	WORD $0x4eb51ea9 // mov v9.16b, v21.16b
	WORD $0x4f9d1069 // fmla v9.4s, v3.4s, v29.s[0]
	WORD $0x4eb41e8a // mov v10.16b, v20.16b
	WORD $0x4f9d186a // fmla v10.4s, v3.4s, v29.s[2]
	WORD $0x4e28cd2a // fmla v10.4s, v9.4s, v8.4s
	WORD $0x4f9e906b // fmul v11.4s, v3.4s, v30.s[0]
	WORD $0x4e28cd4b // fmla v11.4s, v10.4s, v8.4s
	WORD $0x4ea51ca9 // mov v9.16b, v5.16b
	WORD $0x4e25cd69 // fmla v9.4s, v11.4s, v5.4s
	WORD $0x6ea0d841 // fcmle v1.4s, v2.4s, #0.0
	WORD $0x4e381c21 // and v1.16b, v1.16b, v24.16b
	WORD $0x4eb78423 // add v3.4s, v1.4s, v23.4s
	WORD $0x6ea18488 // sub v8.4s, v4.4s, v1.4s
	WORD $0x4ea81d0a // mov v10.16b, v8.16b
	WORD $0x4e2bcd0a // fmla v10.4s, v8.4s, v11.4s
	WORD $0x6e23dd4a // fmul v10.4s, v10.4s, v3.4s
	WORD $0x6e23dc65 // fmul v5.4s, v3.4s, v3.4s
	WORD $0x6ebae4c2 // fcmgt v2.4s, v6.4s, v26.4s
	WORD $0x6e691d47 // bsl v7.16b, v10.16b, v9.16b
	WORD $0x6e671ca2 // bsl v2.16b, v5.16b, v7.16b
	WORD $0x4ea21c40 // mov v0.16b, v2.16b
	FMOVS	F0, F18
	WORD $0x1e2e1013 // fmov s19, #1.0
	MOVD	R11, R14
	MOVW	R2, R12
	CBZW	R12, fascaletail
fascale:
	WORD $0x3dc001c3 // ldr q3, [x14, #0]
	WORD $0x3dc005c4 // ldr q4, [x14, #16]
	WORD $0x3dc009c5 // ldr q5, [x14, #32]
	WORD $0x3dc00dc6 // ldr q6, [x14, #48]
	WORD $0x4f929063 // fmul v3.4s, v3.4s, v18.s[0]
	WORD $0x4f929084 // fmul v4.4s, v4.4s, v18.s[0]
	WORD $0x4f9290a5 // fmul v5.4s, v5.4s, v18.s[0]
	WORD $0x4f9290c6 // fmul v6.4s, v6.4s, v18.s[0]
	WORD $0x3d8001c3 // str q3, [x14, #0]
	WORD $0x3d8005c4 // str q4, [x14, #16]
	WORD $0x3d8009c5 // str q5, [x14, #32]
	WORD $0x3d800dc6 // str q6, [x14, #48]
	ADD	$64, R14, R14
	SUBW	$1, R12, R12
	CBNZW	R12, fascale
fascaletail:
	CBZW	R23, famad
	WORD $0x3dc001c3 // ldr q3, [x14, #0]
	WORD $0x3dc005c4 // ldr q4, [x14, #16]
	WORD $0x4f929063 // fmul v3.4s, v3.4s, v18.s[0]
	WORD $0x4f929084 // fmul v4.4s, v4.4s, v18.s[0]
	WORD $0x3d8001c3 // str q3, [x14, #0]
	WORD $0x3d8005c4 // str q4, [x14, #16]
famad:
	MOVD	R6, R13
	MOVD	R11, R14
	MOVW	R2, R12
	CBZW	R12, famadtail
famadloop:
	WORD $0x3cc105a3 // ldr q3, [x13], #16
	WORD $0x3cc105a4 // ldr q4, [x13], #16
	WORD $0x0e217865 // fcvtl v5.4s, v3.4h
	WORD $0x4e217866 // fcvtl2 v6.4s, v3.8h
	WORD $0x0e217887 // fcvtl v7.4s, v4.4h
	WORD $0x4e217888 // fcvtl2 v8.4s, v4.8h
	WORD $0x3dc001c9 // ldr q9, [x14, #0]
	WORD $0x3dc005ca // ldr q10, [x14, #16]
	WORD $0x3dc009cb // ldr q11, [x14, #32]
	WORD $0x3dc00dc0 // ldr q0, [x14, #48]
	WORD $0x4f9310a9 // fmla v9.4s, v5.4s, v19.s[0]
	WORD $0x4f9310ca // fmla v10.4s, v6.4s, v19.s[0]
	WORD $0x4f9310eb // fmla v11.4s, v7.4s, v19.s[0]
	WORD $0x4f931100 // fmla v0.4s, v8.4s, v19.s[0]
	WORD $0x3d8001c9 // str q9, [x14, #0]
	WORD $0x3d8005ca // str q10, [x14, #16]
	WORD $0x3d8009cb // str q11, [x14, #32]
	WORD $0x3d800dc0 // str q0, [x14, #48]
	ADD	$64, R14, R14
	SUBW	$1, R12, R12
	CBNZW	R12, famadloop
famadtail:
	CBZW	R23, famaddone
	WORD $0x3dc001a3 // ldr q3, [x13, #0]
	WORD $0x0e217865 // fcvtl v5.4s, v3.4h
	WORD $0x4e217866 // fcvtl2 v6.4s, v3.8h
	WORD $0x3dc001c9 // ldr q9, [x14, #0]
	WORD $0x3dc005ca // ldr q10, [x14, #16]
	WORD $0x4f9310a9 // fmla v9.4s, v5.4s, v19.s[0]
	WORD $0x4f9310ca // fmla v10.4s, v6.4s, v19.s[0]
	WORD $0x3d8001c9 // str q9, [x14, #0]
	WORD $0x3d8005ca // str q10, [x14, #16]
famaddone:
	WORD $0x1f124d8c // fmadd s12, s12, s18, s19
faskip:
	ADD	R4, R5, R4
	ADD	R6, R7, R6
	SUB	$1, R9, R9
	CBNZ	R9, fapos
	B	fadone
fhmfast:
	MOVD	$·ovr_dbg_flash_attn_kv_f16_fhm_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000(SB), R13
	VLD1	(R13), [V20.S4, V21.S4, V22.S4, V23.S4]
	WORD $0x4e0c06d3 // dup v19.4s, v22.s[1]
	WORD $0x4e1406d2 // dup v18.4s, v22.s[2]
	WORD $0x4e1c06d1 // dup v17.4s, v22.s[3]
	WORD $0x4e0406f0 // dup v16.4s, v23.s[0]
	WORD $0x4e0c06ef // dup v15.4s, v23.s[1]
	WORD $0x4e04068e // dup v14.4s, v20.s[0]
	WORD $0x4e0c06ad // dup v13.4s, v21.s[1]
	WORD $0x4e1c06ac // dup v12.4s, v21.s[3]
	MOVD	$fhmscratch-288(SP), R19
	LSLW	$1, R1, R17
	ADDW	R22, R17, R17
	LSLW	$1, R2, R16
	LSRW	$2, R2, R23
	MOVD	R11, R13
	MOVD	R19, R14
	MOVW	R16, R15
fhmcvtin:
	WORD $0x3dc001a0 // ldr q0, [x13, #0]
	WORD $0x3dc005a1 // ldr q1, [x13, #16]
	WORD $0x0e216800 // fcvtn v0.4h, v0.4s
	WORD $0x4e216820 // fcvtn2 v0.8h, v1.4s
	WORD $0x3d8001c0 // str q0, [x14, #0]
	ADD	$32, R13, R13
	ADD	$16, R14, R14
	SUBW	$1, R15, R15
	CBNZW	R15, fhmcvtin
fhmblk:
	MOVD	$8, R12
	CMP	R12, R9
	BGE	fhmnblk
	MOVD	R9, R12
fhmnblk:
	MOVW	$0xff800000, R27
	WORD $0x1e270362 // fmov s2, w27
	WORD $0x4e040442 // dup v2.4s, v2.s[0]
	WORD $0x4ea21c43 // mov v3.16b, v2.16b
	MOVD	R4, R13
	MOVD	R13, R15
	MOVD	R3, R14
	MOVW	R17, R26
	WORD $0x4f000400 // movi v0.4s, #0
	WORD $0x4f000401 // movi v1.4s, #0
fhmdot0:
	WORD $0x3cc105e4 // ldr q4, [x15], #16
	WORD $0x3cc105c5 // ldr q5, [x14], #16
	WORD $0x4e25ec80 // fmlal v0.4s, v4.4h, v5.4h
	WORD $0x6e25cc81 // fmlal2 v1.4s, v4.4h, v5.4h
	SUBW	$1, R26, R26
	CBNZW	R26, fhmdot0
	WORD $0x4e21d400 // fadd v0.4s, v0.4s, v1.4s
	WORD $0x6e20d400 // faddp v0.4s, v0.4s, v0.4s
	WORD $0x7e30d800 // faddp s0, v0.2s
	WORD $0x1e2703e6 // fmov s6, wzr
	CBZ	R8, fhmnomask0
	WORD $0x7d400106 // ldr h6, [x8, #0]
	WORD $0x1ee240c6 // fcvt s6, h6
	FMOVS	80(R0), F7
	WORD $0x1e2708c6 // fmul s6, s6, s7
fhmnomask0:
	FMOVS	84(R0), F7
	WORD $0x1f071800 // fmadd s0, s0, s7, s6
	WORD $0x6e040402 // mov v2.s[0], v0.s[0]
	ADD	R13, R5, R13
	CMPW	$1, R12
	BLE	fhmscored
	MOVD	R13, R15
	MOVD	R3, R14
	MOVW	R17, R26
	WORD $0x4f000400 // movi v0.4s, #0
	WORD $0x4f000401 // movi v1.4s, #0
fhmdot1:
	WORD $0x3cc105e4 // ldr q4, [x15], #16
	WORD $0x3cc105c5 // ldr q5, [x14], #16
	WORD $0x4e25ec80 // fmlal v0.4s, v4.4h, v5.4h
	WORD $0x6e25cc81 // fmlal2 v1.4s, v4.4h, v5.4h
	SUBW	$1, R26, R26
	CBNZW	R26, fhmdot1
	WORD $0x4e21d400 // fadd v0.4s, v0.4s, v1.4s
	WORD $0x6e20d400 // faddp v0.4s, v0.4s, v0.4s
	WORD $0x7e30d800 // faddp s0, v0.2s
	WORD $0x1e2703e6 // fmov s6, wzr
	CBZ	R8, fhmnomask1
	WORD $0x7d400506 // ldr h6, [x8, #2]
	WORD $0x1ee240c6 // fcvt s6, h6
	FMOVS	80(R0), F7
	WORD $0x1e2708c6 // fmul s6, s6, s7
fhmnomask1:
	FMOVS	84(R0), F7
	WORD $0x1f071800 // fmadd s0, s0, s7, s6
	WORD $0x6e0c0402 // mov v2.s[1], v0.s[0]
	ADD	R13, R5, R13
	CMPW	$2, R12
	BLE	fhmscored
	MOVD	R13, R15
	MOVD	R3, R14
	MOVW	R17, R26
	WORD $0x4f000400 // movi v0.4s, #0
	WORD $0x4f000401 // movi v1.4s, #0
fhmdot2:
	WORD $0x3cc105e4 // ldr q4, [x15], #16
	WORD $0x3cc105c5 // ldr q5, [x14], #16
	WORD $0x4e25ec80 // fmlal v0.4s, v4.4h, v5.4h
	WORD $0x6e25cc81 // fmlal2 v1.4s, v4.4h, v5.4h
	SUBW	$1, R26, R26
	CBNZW	R26, fhmdot2
	WORD $0x4e21d400 // fadd v0.4s, v0.4s, v1.4s
	WORD $0x6e20d400 // faddp v0.4s, v0.4s, v0.4s
	WORD $0x7e30d800 // faddp s0, v0.2s
	WORD $0x1e2703e6 // fmov s6, wzr
	CBZ	R8, fhmnomask2
	WORD $0x7d400906 // ldr h6, [x8, #4]
	WORD $0x1ee240c6 // fcvt s6, h6
	FMOVS	80(R0), F7
	WORD $0x1e2708c6 // fmul s6, s6, s7
fhmnomask2:
	FMOVS	84(R0), F7
	WORD $0x1f071800 // fmadd s0, s0, s7, s6
	WORD $0x6e140402 // mov v2.s[2], v0.s[0]
	ADD	R13, R5, R13
	CMPW	$3, R12
	BLE	fhmscored
	MOVD	R13, R15
	MOVD	R3, R14
	MOVW	R17, R26
	WORD $0x4f000400 // movi v0.4s, #0
	WORD $0x4f000401 // movi v1.4s, #0
fhmdot3:
	WORD $0x3cc105e4 // ldr q4, [x15], #16
	WORD $0x3cc105c5 // ldr q5, [x14], #16
	WORD $0x4e25ec80 // fmlal v0.4s, v4.4h, v5.4h
	WORD $0x6e25cc81 // fmlal2 v1.4s, v4.4h, v5.4h
	SUBW	$1, R26, R26
	CBNZW	R26, fhmdot3
	WORD $0x4e21d400 // fadd v0.4s, v0.4s, v1.4s
	WORD $0x6e20d400 // faddp v0.4s, v0.4s, v0.4s
	WORD $0x7e30d800 // faddp s0, v0.2s
	WORD $0x1e2703e6 // fmov s6, wzr
	CBZ	R8, fhmnomask3
	WORD $0x7d400d06 // ldr h6, [x8, #6]
	WORD $0x1ee240c6 // fcvt s6, h6
	FMOVS	80(R0), F7
	WORD $0x1e2708c6 // fmul s6, s6, s7
fhmnomask3:
	FMOVS	84(R0), F7
	WORD $0x1f071800 // fmadd s0, s0, s7, s6
	WORD $0x6e1c0402 // mov v2.s[3], v0.s[0]
	ADD	R13, R5, R13
	CMPW	$4, R12
	BLE	fhmscored
	MOVD	R13, R15
	MOVD	R3, R14
	MOVW	R17, R26
	WORD $0x4f000400 // movi v0.4s, #0
	WORD $0x4f000401 // movi v1.4s, #0
fhmdot4:
	WORD $0x3cc105e4 // ldr q4, [x15], #16
	WORD $0x3cc105c5 // ldr q5, [x14], #16
	WORD $0x4e25ec80 // fmlal v0.4s, v4.4h, v5.4h
	WORD $0x6e25cc81 // fmlal2 v1.4s, v4.4h, v5.4h
	SUBW	$1, R26, R26
	CBNZW	R26, fhmdot4
	WORD $0x4e21d400 // fadd v0.4s, v0.4s, v1.4s
	WORD $0x6e20d400 // faddp v0.4s, v0.4s, v0.4s
	WORD $0x7e30d800 // faddp s0, v0.2s
	WORD $0x1e2703e6 // fmov s6, wzr
	CBZ	R8, fhmnomask4
	WORD $0x7d401106 // ldr h6, [x8, #8]
	WORD $0x1ee240c6 // fcvt s6, h6
	FMOVS	80(R0), F7
	WORD $0x1e2708c6 // fmul s6, s6, s7
fhmnomask4:
	FMOVS	84(R0), F7
	WORD $0x1f071800 // fmadd s0, s0, s7, s6
	WORD $0x6e040403 // mov v3.s[0], v0.s[0]
	ADD	R13, R5, R13
	CMPW	$5, R12
	BLE	fhmscored
	MOVD	R13, R15
	MOVD	R3, R14
	MOVW	R17, R26
	WORD $0x4f000400 // movi v0.4s, #0
	WORD $0x4f000401 // movi v1.4s, #0
fhmdot5:
	WORD $0x3cc105e4 // ldr q4, [x15], #16
	WORD $0x3cc105c5 // ldr q5, [x14], #16
	WORD $0x4e25ec80 // fmlal v0.4s, v4.4h, v5.4h
	WORD $0x6e25cc81 // fmlal2 v1.4s, v4.4h, v5.4h
	SUBW	$1, R26, R26
	CBNZW	R26, fhmdot5
	WORD $0x4e21d400 // fadd v0.4s, v0.4s, v1.4s
	WORD $0x6e20d400 // faddp v0.4s, v0.4s, v0.4s
	WORD $0x7e30d800 // faddp s0, v0.2s
	WORD $0x1e2703e6 // fmov s6, wzr
	CBZ	R8, fhmnomask5
	WORD $0x7d401506 // ldr h6, [x8, #10]
	WORD $0x1ee240c6 // fcvt s6, h6
	FMOVS	80(R0), F7
	WORD $0x1e2708c6 // fmul s6, s6, s7
fhmnomask5:
	FMOVS	84(R0), F7
	WORD $0x1f071800 // fmadd s0, s0, s7, s6
	WORD $0x6e0c0403 // mov v3.s[1], v0.s[0]
	ADD	R13, R5, R13
	CMPW	$6, R12
	BLE	fhmscored
	MOVD	R13, R15
	MOVD	R3, R14
	MOVW	R17, R26
	WORD $0x4f000400 // movi v0.4s, #0
	WORD $0x4f000401 // movi v1.4s, #0
fhmdot6:
	WORD $0x3cc105e4 // ldr q4, [x15], #16
	WORD $0x3cc105c5 // ldr q5, [x14], #16
	WORD $0x4e25ec80 // fmlal v0.4s, v4.4h, v5.4h
	WORD $0x6e25cc81 // fmlal2 v1.4s, v4.4h, v5.4h
	SUBW	$1, R26, R26
	CBNZW	R26, fhmdot6
	WORD $0x4e21d400 // fadd v0.4s, v0.4s, v1.4s
	WORD $0x6e20d400 // faddp v0.4s, v0.4s, v0.4s
	WORD $0x7e30d800 // faddp s0, v0.2s
	WORD $0x1e2703e6 // fmov s6, wzr
	CBZ	R8, fhmnomask6
	WORD $0x7d401906 // ldr h6, [x8, #12]
	WORD $0x1ee240c6 // fcvt s6, h6
	FMOVS	80(R0), F7
	WORD $0x1e2708c6 // fmul s6, s6, s7
fhmnomask6:
	FMOVS	84(R0), F7
	WORD $0x1f071800 // fmadd s0, s0, s7, s6
	WORD $0x6e140403 // mov v3.s[2], v0.s[0]
	ADD	R13, R5, R13
	CMPW	$7, R12
	BLE	fhmscored
	MOVD	R13, R15
	MOVD	R3, R14
	MOVW	R17, R26
	WORD $0x4f000400 // movi v0.4s, #0
	WORD $0x4f000401 // movi v1.4s, #0
fhmdot7:
	WORD $0x3cc105e4 // ldr q4, [x15], #16
	WORD $0x3cc105c5 // ldr q5, [x14], #16
	WORD $0x4e25ec80 // fmlal v0.4s, v4.4h, v5.4h
	WORD $0x6e25cc81 // fmlal2 v1.4s, v4.4h, v5.4h
	SUBW	$1, R26, R26
	CBNZW	R26, fhmdot7
	WORD $0x4e21d400 // fadd v0.4s, v0.4s, v1.4s
	WORD $0x6e20d400 // faddp v0.4s, v0.4s, v0.4s
	WORD $0x7e30d800 // faddp s0, v0.2s
	WORD $0x1e2703e6 // fmov s6, wzr
	CBZ	R8, fhmnomask7
	WORD $0x7d401d06 // ldr h6, [x8, #14]
	WORD $0x1ee240c6 // fcvt s6, h6
	FMOVS	80(R0), F7
	WORD $0x1e2708c6 // fmul s6, s6, s7
fhmnomask7:
	FMOVS	84(R0), F7
	WORD $0x1f071800 // fmadd s0, s0, s7, s6
	WORD $0x6e1c0403 // mov v3.s[3], v0.s[0]
	ADD	R13, R5, R13
fhmscored:
	WORD $0x6e30f844 // fmaxv s4, v2.4s
	WORD $0x6e30f865 // fmaxv s5, v3.4s
	WORD $0x1e25489e // fmax s30, s4, s5
	MOVW	$0xff800000, R27
	WORD $0x1e270366 // fmov s6, w27
	WORD $0x1e2623c0 // fcmp s30, s6
	BEQ	fhmadvance
	WORD $0xbd40055f // ldr s31, [x10, #4]
	WORD $0x1e3f23c0 // fcmp s30, s31
	BGT	fhmexact
	WORD $0x4e0407e6 // dup v6.4s, v31.s[0]
	WORD $0x4ea6d442 // fsub v2.4s, v2.4s, v6.4s
	WORD $0x4ea6d463 // fsub v3.4s, v3.4s, v6.4s
	MOVW	$0xc3480000, R27
	WORD $0x1e270367 // fmov s7, w27
	WORD $0x4e0404e7 // dup v7.4s, v7.s[0]
	WORD $0x4e27f442 // fmax v2.4s, v2.4s, v7.4s
	WORD $0x4e27f463 // fmax v3.4s, v3.4s, v7.4s
	WORD $0x3d804663 // str q3, [x19, #272]
	WORD $0x4ea21c40 // mov v0.16b, v2.16b
	WORD $0x4eae1dc1 // mov v1.16b, v14.16b
	WORD $0x4fb41001 // fmla v1.4s, v0.4s, v20.s[1]
	WORD $0x4eaed422 // fsub v2.4s, v1.4s, v14.4s
	WORD $0x4ea01c03 // mov v3.16b, v0.16b
	WORD $0x4f945843 // fmls v3.4s, v2.4s, v20.s[2]
	WORD $0x4fb45843 // fmls v3.4s, v2.4s, v20.s[3]
	WORD $0x4f375424 // shl v4.4s, v1.4s, #23
	WORD $0x4eb18485 // add v5.4s, v4.4s, v17.4s
	WORD $0x4ea0f846 // fabs v6.4s, v2.4s
	WORD $0x6eb3e4c7 // fcmgt v7.4s, v6.4s, v19.4s
	WORD $0x6e23dc68 // fmul v8.4s, v3.4s, v3.4s
	WORD $0x4ead1da9 // mov v9.16b, v13.16b
	WORD $0x4f951069 // fmla v9.4s, v3.4s, v21.s[0]
	WORD $0x4eac1d8a // mov v10.16b, v12.16b
	WORD $0x4f95186a // fmla v10.4s, v3.4s, v21.s[2]
	WORD $0x4e28cd2a // fmla v10.4s, v9.4s, v8.4s
	WORD $0x4f96906b // fmul v11.4s, v3.4s, v22.s[0]
	WORD $0x4e28cd4b // fmla v11.4s, v10.4s, v8.4s
	WORD $0x4ea51ca9 // mov v9.16b, v5.16b
	WORD $0x4e25cd69 // fmla v9.4s, v11.4s, v5.4s
	WORD $0x6ea0d841 // fcmle v1.4s, v2.4s, #0.0
	WORD $0x4e301c21 // and v1.16b, v1.16b, v16.16b
	WORD $0x4eaf8423 // add v3.4s, v1.4s, v15.4s
	WORD $0x6ea18488 // sub v8.4s, v4.4s, v1.4s
	WORD $0x4ea81d0a // mov v10.16b, v8.16b
	WORD $0x4e2bcd0a // fmla v10.4s, v8.4s, v11.4s
	WORD $0x6e23dd4a // fmul v10.4s, v10.4s, v3.4s
	WORD $0x6e23dc65 // fmul v5.4s, v3.4s, v3.4s
	WORD $0x6eb2e4c2 // fcmgt v2.4s, v6.4s, v18.4s
	WORD $0x6e691d47 // bsl v7.16b, v10.16b, v9.16b
	WORD $0x6e671ca2 // bsl v2.16b, v5.16b, v7.16b
	WORD $0x4ea21c40 // mov v0.16b, v2.16b
	WORD $0x3d804260 // str q0, [x19, #256]
	WORD $0x3dc04660 // ldr q0, [x19, #272]
	WORD $0x4eae1dc1 // mov v1.16b, v14.16b
	WORD $0x4fb41001 // fmla v1.4s, v0.4s, v20.s[1]
	WORD $0x4eaed422 // fsub v2.4s, v1.4s, v14.4s
	WORD $0x4ea01c03 // mov v3.16b, v0.16b
	WORD $0x4f945843 // fmls v3.4s, v2.4s, v20.s[2]
	WORD $0x4fb45843 // fmls v3.4s, v2.4s, v20.s[3]
	WORD $0x4f375424 // shl v4.4s, v1.4s, #23
	WORD $0x4eb18485 // add v5.4s, v4.4s, v17.4s
	WORD $0x4ea0f846 // fabs v6.4s, v2.4s
	WORD $0x6eb3e4c7 // fcmgt v7.4s, v6.4s, v19.4s
	WORD $0x6e23dc68 // fmul v8.4s, v3.4s, v3.4s
	WORD $0x4ead1da9 // mov v9.16b, v13.16b
	WORD $0x4f951069 // fmla v9.4s, v3.4s, v21.s[0]
	WORD $0x4eac1d8a // mov v10.16b, v12.16b
	WORD $0x4f95186a // fmla v10.4s, v3.4s, v21.s[2]
	WORD $0x4e28cd2a // fmla v10.4s, v9.4s, v8.4s
	WORD $0x4f96906b // fmul v11.4s, v3.4s, v22.s[0]
	WORD $0x4e28cd4b // fmla v11.4s, v10.4s, v8.4s
	WORD $0x4ea51ca9 // mov v9.16b, v5.16b
	WORD $0x4e25cd69 // fmla v9.4s, v11.4s, v5.4s
	WORD $0x6ea0d841 // fcmle v1.4s, v2.4s, #0.0
	WORD $0x4e301c21 // and v1.16b, v1.16b, v16.16b
	WORD $0x4eaf8423 // add v3.4s, v1.4s, v15.4s
	WORD $0x6ea18488 // sub v8.4s, v4.4s, v1.4s
	WORD $0x4ea81d0a // mov v10.16b, v8.16b
	WORD $0x4e2bcd0a // fmla v10.4s, v8.4s, v11.4s
	WORD $0x6e23dd4a // fmul v10.4s, v10.4s, v3.4s
	WORD $0x6e23dc65 // fmul v5.4s, v3.4s, v3.4s
	WORD $0x6eb2e4c2 // fcmgt v2.4s, v6.4s, v18.4s
	WORD $0x6e691d47 // bsl v7.16b, v10.16b, v9.16b
	WORD $0x6e671ca2 // bsl v2.16b, v5.16b, v7.16b
	WORD $0x4ea21c40 // mov v0.16b, v2.16b
	WORD $0x4ea01c03 // mov v3.16b, v0.16b
	WORD $0x3dc04262 // ldr q2, [x19, #256]
	WORD $0xbd400141 // ldr s1, [x10, #0]
	WORD $0x5e040440 // mov s0, v2.s[0]
	WORD $0x1e202821 // fadd s1, s1, s0
	WORD $0x5e0c0440 // mov s0, v2.s[1]
	WORD $0x1e202821 // fadd s1, s1, s0
	WORD $0x5e140440 // mov s0, v2.s[2]
	WORD $0x1e202821 // fadd s1, s1, s0
	WORD $0x5e1c0440 // mov s0, v2.s[3]
	WORD $0x1e202821 // fadd s1, s1, s0
	WORD $0x5e040460 // mov s0, v3.s[0]
	WORD $0x1e202821 // fadd s1, s1, s0
	WORD $0x5e0c0460 // mov s0, v3.s[1]
	WORD $0x1e202821 // fadd s1, s1, s0
	WORD $0x5e140460 // mov s0, v3.s[2]
	WORD $0x1e202821 // fadd s1, s1, s0
	WORD $0x5e1c0460 // mov s0, v3.s[3]
	WORD $0x1e202821 // fadd s1, s1, s0
	WORD $0xbd000141 // str s1, [x10, #0]
	WORD $0x0e21684a // fcvtn v10.4h, v2.4s
	WORD $0x4e21686a // fcvtn2 v10.8h, v3.4s
	MOVD	R19, R14
	MOVD	R6, R24
	MOVW	R23, R25
fhmhalf:
	WORD $0x3dc001d8 // ldr q24, [x14, #0]
	WORD $0x3dc005d9 // ldr q25, [x14, #16]
	WORD $0x3dc009da // ldr q26, [x14, #32]
	WORD $0x3dc00ddb // ldr q27, [x14, #48]
	WORD $0x3dc011dc // ldr q28, [x14, #64]
	WORD $0x3dc015dd // ldr q29, [x14, #80]
	WORD $0x3dc019de // ldr q30, [x14, #96]
	WORD $0x3dc01ddf // ldr q31, [x14, #112]
	MOVD	R24, R13
	WORD $0x3dc001a0 // ldr q0, [x13, #0]
	WORD $0x4f0a1018 // fmla v24.8h, v0.8h, v10.h[0]
	WORD $0x3dc005a1 // ldr q1, [x13, #16]
	WORD $0x4f0a1039 // fmla v25.8h, v1.8h, v10.h[0]
	WORD $0x3dc009a0 // ldr q0, [x13, #32]
	WORD $0x4f0a101a // fmla v26.8h, v0.8h, v10.h[0]
	WORD $0x3dc00da1 // ldr q1, [x13, #48]
	WORD $0x4f0a103b // fmla v27.8h, v1.8h, v10.h[0]
	WORD $0x3dc011a0 // ldr q0, [x13, #64]
	WORD $0x4f0a101c // fmla v28.8h, v0.8h, v10.h[0]
	WORD $0x3dc015a1 // ldr q1, [x13, #80]
	WORD $0x4f0a103d // fmla v29.8h, v1.8h, v10.h[0]
	WORD $0x3dc019a0 // ldr q0, [x13, #96]
	WORD $0x4f0a101e // fmla v30.8h, v0.8h, v10.h[0]
	WORD $0x3dc01da1 // ldr q1, [x13, #112]
	WORD $0x4f0a103f // fmla v31.8h, v1.8h, v10.h[0]
	ADD	R13, R7, R13
	CMPW	$1, R12
	BLE	fhmhalfdone
	WORD $0x3dc001a0 // ldr q0, [x13, #0]
	WORD $0x4f1a1018 // fmla v24.8h, v0.8h, v10.h[1]
	WORD $0x3dc005a1 // ldr q1, [x13, #16]
	WORD $0x4f1a1039 // fmla v25.8h, v1.8h, v10.h[1]
	WORD $0x3dc009a0 // ldr q0, [x13, #32]
	WORD $0x4f1a101a // fmla v26.8h, v0.8h, v10.h[1]
	WORD $0x3dc00da1 // ldr q1, [x13, #48]
	WORD $0x4f1a103b // fmla v27.8h, v1.8h, v10.h[1]
	WORD $0x3dc011a0 // ldr q0, [x13, #64]
	WORD $0x4f1a101c // fmla v28.8h, v0.8h, v10.h[1]
	WORD $0x3dc015a1 // ldr q1, [x13, #80]
	WORD $0x4f1a103d // fmla v29.8h, v1.8h, v10.h[1]
	WORD $0x3dc019a0 // ldr q0, [x13, #96]
	WORD $0x4f1a101e // fmla v30.8h, v0.8h, v10.h[1]
	WORD $0x3dc01da1 // ldr q1, [x13, #112]
	WORD $0x4f1a103f // fmla v31.8h, v1.8h, v10.h[1]
	ADD	R13, R7, R13
	CMPW	$2, R12
	BLE	fhmhalfdone
	WORD $0x3dc001a0 // ldr q0, [x13, #0]
	WORD $0x4f2a1018 // fmla v24.8h, v0.8h, v10.h[2]
	WORD $0x3dc005a1 // ldr q1, [x13, #16]
	WORD $0x4f2a1039 // fmla v25.8h, v1.8h, v10.h[2]
	WORD $0x3dc009a0 // ldr q0, [x13, #32]
	WORD $0x4f2a101a // fmla v26.8h, v0.8h, v10.h[2]
	WORD $0x3dc00da1 // ldr q1, [x13, #48]
	WORD $0x4f2a103b // fmla v27.8h, v1.8h, v10.h[2]
	WORD $0x3dc011a0 // ldr q0, [x13, #64]
	WORD $0x4f2a101c // fmla v28.8h, v0.8h, v10.h[2]
	WORD $0x3dc015a1 // ldr q1, [x13, #80]
	WORD $0x4f2a103d // fmla v29.8h, v1.8h, v10.h[2]
	WORD $0x3dc019a0 // ldr q0, [x13, #96]
	WORD $0x4f2a101e // fmla v30.8h, v0.8h, v10.h[2]
	WORD $0x3dc01da1 // ldr q1, [x13, #112]
	WORD $0x4f2a103f // fmla v31.8h, v1.8h, v10.h[2]
	ADD	R13, R7, R13
	CMPW	$3, R12
	BLE	fhmhalfdone
	WORD $0x3dc001a0 // ldr q0, [x13, #0]
	WORD $0x4f3a1018 // fmla v24.8h, v0.8h, v10.h[3]
	WORD $0x3dc005a1 // ldr q1, [x13, #16]
	WORD $0x4f3a1039 // fmla v25.8h, v1.8h, v10.h[3]
	WORD $0x3dc009a0 // ldr q0, [x13, #32]
	WORD $0x4f3a101a // fmla v26.8h, v0.8h, v10.h[3]
	WORD $0x3dc00da1 // ldr q1, [x13, #48]
	WORD $0x4f3a103b // fmla v27.8h, v1.8h, v10.h[3]
	WORD $0x3dc011a0 // ldr q0, [x13, #64]
	WORD $0x4f3a101c // fmla v28.8h, v0.8h, v10.h[3]
	WORD $0x3dc015a1 // ldr q1, [x13, #80]
	WORD $0x4f3a103d // fmla v29.8h, v1.8h, v10.h[3]
	WORD $0x3dc019a0 // ldr q0, [x13, #96]
	WORD $0x4f3a101e // fmla v30.8h, v0.8h, v10.h[3]
	WORD $0x3dc01da1 // ldr q1, [x13, #112]
	WORD $0x4f3a103f // fmla v31.8h, v1.8h, v10.h[3]
	ADD	R13, R7, R13
	CMPW	$4, R12
	BLE	fhmhalfdone
	WORD $0x3dc001a0 // ldr q0, [x13, #0]
	WORD $0x4f0a1818 // fmla v24.8h, v0.8h, v10.h[4]
	WORD $0x3dc005a1 // ldr q1, [x13, #16]
	WORD $0x4f0a1839 // fmla v25.8h, v1.8h, v10.h[4]
	WORD $0x3dc009a0 // ldr q0, [x13, #32]
	WORD $0x4f0a181a // fmla v26.8h, v0.8h, v10.h[4]
	WORD $0x3dc00da1 // ldr q1, [x13, #48]
	WORD $0x4f0a183b // fmla v27.8h, v1.8h, v10.h[4]
	WORD $0x3dc011a0 // ldr q0, [x13, #64]
	WORD $0x4f0a181c // fmla v28.8h, v0.8h, v10.h[4]
	WORD $0x3dc015a1 // ldr q1, [x13, #80]
	WORD $0x4f0a183d // fmla v29.8h, v1.8h, v10.h[4]
	WORD $0x3dc019a0 // ldr q0, [x13, #96]
	WORD $0x4f0a181e // fmla v30.8h, v0.8h, v10.h[4]
	WORD $0x3dc01da1 // ldr q1, [x13, #112]
	WORD $0x4f0a183f // fmla v31.8h, v1.8h, v10.h[4]
	ADD	R13, R7, R13
	CMPW	$5, R12
	BLE	fhmhalfdone
	WORD $0x3dc001a0 // ldr q0, [x13, #0]
	WORD $0x4f1a1818 // fmla v24.8h, v0.8h, v10.h[5]
	WORD $0x3dc005a1 // ldr q1, [x13, #16]
	WORD $0x4f1a1839 // fmla v25.8h, v1.8h, v10.h[5]
	WORD $0x3dc009a0 // ldr q0, [x13, #32]
	WORD $0x4f1a181a // fmla v26.8h, v0.8h, v10.h[5]
	WORD $0x3dc00da1 // ldr q1, [x13, #48]
	WORD $0x4f1a183b // fmla v27.8h, v1.8h, v10.h[5]
	WORD $0x3dc011a0 // ldr q0, [x13, #64]
	WORD $0x4f1a181c // fmla v28.8h, v0.8h, v10.h[5]
	WORD $0x3dc015a1 // ldr q1, [x13, #80]
	WORD $0x4f1a183d // fmla v29.8h, v1.8h, v10.h[5]
	WORD $0x3dc019a0 // ldr q0, [x13, #96]
	WORD $0x4f1a181e // fmla v30.8h, v0.8h, v10.h[5]
	WORD $0x3dc01da1 // ldr q1, [x13, #112]
	WORD $0x4f1a183f // fmla v31.8h, v1.8h, v10.h[5]
	ADD	R13, R7, R13
	CMPW	$6, R12
	BLE	fhmhalfdone
	WORD $0x3dc001a0 // ldr q0, [x13, #0]
	WORD $0x4f2a1818 // fmla v24.8h, v0.8h, v10.h[6]
	WORD $0x3dc005a1 // ldr q1, [x13, #16]
	WORD $0x4f2a1839 // fmla v25.8h, v1.8h, v10.h[6]
	WORD $0x3dc009a0 // ldr q0, [x13, #32]
	WORD $0x4f2a181a // fmla v26.8h, v0.8h, v10.h[6]
	WORD $0x3dc00da1 // ldr q1, [x13, #48]
	WORD $0x4f2a183b // fmla v27.8h, v1.8h, v10.h[6]
	WORD $0x3dc011a0 // ldr q0, [x13, #64]
	WORD $0x4f2a181c // fmla v28.8h, v0.8h, v10.h[6]
	WORD $0x3dc015a1 // ldr q1, [x13, #80]
	WORD $0x4f2a183d // fmla v29.8h, v1.8h, v10.h[6]
	WORD $0x3dc019a0 // ldr q0, [x13, #96]
	WORD $0x4f2a181e // fmla v30.8h, v0.8h, v10.h[6]
	WORD $0x3dc01da1 // ldr q1, [x13, #112]
	WORD $0x4f2a183f // fmla v31.8h, v1.8h, v10.h[6]
	ADD	R13, R7, R13
	CMPW	$7, R12
	BLE	fhmhalfdone
	WORD $0x3dc001a0 // ldr q0, [x13, #0]
	WORD $0x4f3a1818 // fmla v24.8h, v0.8h, v10.h[7]
	WORD $0x3dc005a1 // ldr q1, [x13, #16]
	WORD $0x4f3a1839 // fmla v25.8h, v1.8h, v10.h[7]
	WORD $0x3dc009a0 // ldr q0, [x13, #32]
	WORD $0x4f3a181a // fmla v26.8h, v0.8h, v10.h[7]
	WORD $0x3dc00da1 // ldr q1, [x13, #48]
	WORD $0x4f3a183b // fmla v27.8h, v1.8h, v10.h[7]
	WORD $0x3dc011a0 // ldr q0, [x13, #64]
	WORD $0x4f3a181c // fmla v28.8h, v0.8h, v10.h[7]
	WORD $0x3dc015a1 // ldr q1, [x13, #80]
	WORD $0x4f3a183d // fmla v29.8h, v1.8h, v10.h[7]
	WORD $0x3dc019a0 // ldr q0, [x13, #96]
	WORD $0x4f3a181e // fmla v30.8h, v0.8h, v10.h[7]
	WORD $0x3dc01da1 // ldr q1, [x13, #112]
	WORD $0x4f3a183f // fmla v31.8h, v1.8h, v10.h[7]
	ADD	R13, R7, R13
fhmhalfdone:
	WORD $0x3d8001d8 // str q24, [x14, #0]
	WORD $0x3d8005d9 // str q25, [x14, #16]
	WORD $0x3d8009da // str q26, [x14, #32]
	WORD $0x3d800ddb // str q27, [x14, #48]
	WORD $0x3d8011dc // str q28, [x14, #64]
	WORD $0x3d8015dd // str q29, [x14, #80]
	WORD $0x3d8019de // str q30, [x14, #96]
	WORD $0x3d801ddf // str q31, [x14, #112]
	ADD	$128, R14, R14
	ADD	$128, R24, R24
	SUBW	$1, R25, R25
	CBNZW	R25, fhmhalf
	B	fhmadvance
fhmexact:
	WORD $0x3d804262 // str q2, [x19, #256]
	WORD $0x3d804663 // str q3, [x19, #272]
	ADD	$256, R19, R24
	MOVD	R6, R25
	MOVW	R12, R26
fhmpos:
	FMOVS	(R24), F0
	MOVW	$0xff800000, R27
	WORD $0x1e270366 // fmov s6, w27
	WORD $0x1e262000 // fcmp s0, s6
	BEQ	fhmposnext
	MOVW	$0xc3480000, R27
	WORD $0x1e270367 // fmov s7, w27
	WORD $0x1e3f2000 // fcmp s0, s31
	BLE	fhmposkeep
	FMOVS	F0, F29
	WORD $0x1e3d3be0 // fsub s0, s31, s29
	WORD $0x1e274800 // fmax s0, s0, s7
	WORD $0x4e040400 // dup v0.4s, v0.s[0]
	WORD $0x4eae1dc1 // mov v1.16b, v14.16b
	WORD $0x4fb41001 // fmla v1.4s, v0.4s, v20.s[1]
	WORD $0x4eaed422 // fsub v2.4s, v1.4s, v14.4s
	WORD $0x4ea01c03 // mov v3.16b, v0.16b
	WORD $0x4f945843 // fmls v3.4s, v2.4s, v20.s[2]
	WORD $0x4fb45843 // fmls v3.4s, v2.4s, v20.s[3]
	WORD $0x4f375424 // shl v4.4s, v1.4s, #23
	WORD $0x4eb18485 // add v5.4s, v4.4s, v17.4s
	WORD $0x4ea0f846 // fabs v6.4s, v2.4s
	WORD $0x6eb3e4c7 // fcmgt v7.4s, v6.4s, v19.4s
	WORD $0x6e23dc68 // fmul v8.4s, v3.4s, v3.4s
	WORD $0x4ead1da9 // mov v9.16b, v13.16b
	WORD $0x4f951069 // fmla v9.4s, v3.4s, v21.s[0]
	WORD $0x4eac1d8a // mov v10.16b, v12.16b
	WORD $0x4f95186a // fmla v10.4s, v3.4s, v21.s[2]
	WORD $0x4e28cd2a // fmla v10.4s, v9.4s, v8.4s
	WORD $0x4f96906b // fmul v11.4s, v3.4s, v22.s[0]
	WORD $0x4e28cd4b // fmla v11.4s, v10.4s, v8.4s
	WORD $0x4ea51ca9 // mov v9.16b, v5.16b
	WORD $0x4e25cd69 // fmla v9.4s, v11.4s, v5.4s
	WORD $0x6ea0d841 // fcmle v1.4s, v2.4s, #0.0
	WORD $0x4e301c21 // and v1.16b, v1.16b, v16.16b
	WORD $0x4eaf8423 // add v3.4s, v1.4s, v15.4s
	WORD $0x6ea18488 // sub v8.4s, v4.4s, v1.4s
	WORD $0x4ea81d0a // mov v10.16b, v8.16b
	WORD $0x4e2bcd0a // fmla v10.4s, v8.4s, v11.4s
	WORD $0x6e23dd4a // fmul v10.4s, v10.4s, v3.4s
	WORD $0x6e23dc65 // fmul v5.4s, v3.4s, v3.4s
	WORD $0x6eb2e4c2 // fcmgt v2.4s, v6.4s, v18.4s
	WORD $0x6e691d47 // bsl v7.16b, v10.16b, v9.16b
	WORD $0x6e671ca2 // bsl v2.16b, v5.16b, v7.16b
	WORD $0x4ea21c40 // mov v0.16b, v2.16b
	WORD $0xbd400141 // ldr s1, [x10, #0]
	WORD $0x1e200821 // fmul s1, s1, s0
	WORD $0xbd000141 // str s1, [x10, #0]
	WORD $0x1e23c000 // fcvt h0, s0
	MOVD	R19, R14
	MOVW	R16, R15
fhmposscale:
	WORD $0x3dc001c1 // ldr q1, [x14, #0]
	WORD $0x4f009021 // fmul v1.8h, v1.8h, v0.h[0]
	WORD $0x3d8001c1 // str q1, [x14, #0]
	ADD	$16, R14, R14
	SUBW	$1, R15, R15
	CBNZW	R15, fhmposscale
	FMOVS	F29, F31
	WORD $0xbd00055f // str s31, [x10, #4]
	FMOVS	$1.0, F0
	B	fhmposacc
fhmposkeep:
	WORD $0x1e3f3800 // fsub s0, s0, s31
	WORD $0x1e274800 // fmax s0, s0, s7
	WORD $0x4e040400 // dup v0.4s, v0.s[0]
	WORD $0x4eae1dc1 // mov v1.16b, v14.16b
	WORD $0x4fb41001 // fmla v1.4s, v0.4s, v20.s[1]
	WORD $0x4eaed422 // fsub v2.4s, v1.4s, v14.4s
	WORD $0x4ea01c03 // mov v3.16b, v0.16b
	WORD $0x4f945843 // fmls v3.4s, v2.4s, v20.s[2]
	WORD $0x4fb45843 // fmls v3.4s, v2.4s, v20.s[3]
	WORD $0x4f375424 // shl v4.4s, v1.4s, #23
	WORD $0x4eb18485 // add v5.4s, v4.4s, v17.4s
	WORD $0x4ea0f846 // fabs v6.4s, v2.4s
	WORD $0x6eb3e4c7 // fcmgt v7.4s, v6.4s, v19.4s
	WORD $0x6e23dc68 // fmul v8.4s, v3.4s, v3.4s
	WORD $0x4ead1da9 // mov v9.16b, v13.16b
	WORD $0x4f951069 // fmla v9.4s, v3.4s, v21.s[0]
	WORD $0x4eac1d8a // mov v10.16b, v12.16b
	WORD $0x4f95186a // fmla v10.4s, v3.4s, v21.s[2]
	WORD $0x4e28cd2a // fmla v10.4s, v9.4s, v8.4s
	WORD $0x4f96906b // fmul v11.4s, v3.4s, v22.s[0]
	WORD $0x4e28cd4b // fmla v11.4s, v10.4s, v8.4s
	WORD $0x4ea51ca9 // mov v9.16b, v5.16b
	WORD $0x4e25cd69 // fmla v9.4s, v11.4s, v5.4s
	WORD $0x6ea0d841 // fcmle v1.4s, v2.4s, #0.0
	WORD $0x4e301c21 // and v1.16b, v1.16b, v16.16b
	WORD $0x4eaf8423 // add v3.4s, v1.4s, v15.4s
	WORD $0x6ea18488 // sub v8.4s, v4.4s, v1.4s
	WORD $0x4ea81d0a // mov v10.16b, v8.16b
	WORD $0x4e2bcd0a // fmla v10.4s, v8.4s, v11.4s
	WORD $0x6e23dd4a // fmul v10.4s, v10.4s, v3.4s
	WORD $0x6e23dc65 // fmul v5.4s, v3.4s, v3.4s
	WORD $0x6eb2e4c2 // fcmgt v2.4s, v6.4s, v18.4s
	WORD $0x6e691d47 // bsl v7.16b, v10.16b, v9.16b
	WORD $0x6e671ca2 // bsl v2.16b, v5.16b, v7.16b
	WORD $0x4ea21c40 // mov v0.16b, v2.16b
fhmposacc:
	WORD $0xbd400141 // ldr s1, [x10, #0]
	WORD $0x1e202821 // fadd s1, s1, s0
	WORD $0xbd000141 // str s1, [x10, #0]
	WORD $0x1e23c000 // fcvt h0, s0
	MOVD	R19, R14
	MOVD	R25, R13
	MOVW	R16, R15
fhmposmad:
	WORD $0x3dc001a1 // ldr q1, [x13, #0]
	WORD $0x3dc001c2 // ldr q2, [x14, #0]
	WORD $0x4f001022 // fmla v2.8h, v1.8h, v0.h[0]
	WORD $0x3d8001c2 // str q2, [x14, #0]
	ADD	$16, R13, R13
	ADD	$16, R14, R14
	SUBW	$1, R15, R15
	CBNZW	R15, fhmposmad
fhmposnext:
	ADD	$4, R24, R24
	ADD	R7, R25, R25
	SUBW	$1, R26, R26
	CBNZW	R26, fhmpos
fhmadvance:
	MADD	R5, R4, R12, R4
	MADD	R7, R6, R12, R6
	CBZ	R8, fhmnomaskadv
	ADD	R12<<1, R8, R8
fhmnomaskadv:
	SUB	R12, R9, R9
	CBNZ	R9, fhmblk
	MOVD	R11, R13
	MOVD	R19, R14
	MOVW	R16, R15
fhmcvtout:
	WORD $0x3dc001c0 // ldr q0, [x14, #0]
	WORD $0x0e217801 // fcvtl v1.4s, v0.4h
	WORD $0x4e217802 // fcvtl2 v2.4s, v0.8h
	WORD $0x3d8001a1 // str q1, [x13, #0]
	WORD $0x3d8005a2 // str q2, [x13, #16]
	ADD	$32, R13, R13
	ADD	$16, R14, R14
	SUBW	$1, R15, R15
	CBNZW	R15, fhmcvtout
	WORD $0xbd40014c // ldr s12, [x10, #0]
	WORD $0xbd40054d // ldr s13, [x10, #4]
fadone:
	WORD $0xbd00014c // str s12, [x10, #0]
	WORD $0xbd00054d // str s13, [x10, #4]
	RET
faoob:
	B	ovr_oob

DATA ·ovr_dbg_flash_attn_kv_f16_fhm_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000+0(SB)/8, $0x3fb8aa3b4b400000
DATA ·ovr_dbg_flash_attn_kv_f16_fhm_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000+8(SB)/8, $0x35bfbe8e3f317200
DATA ·ovr_dbg_flash_attn_kv_f16_fhm_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000+16(SB)/8, $0x3d2b9f173c072010
DATA ·ovr_dbg_flash_attn_kv_f16_fhm_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000+24(SB)/8, $0x3efffedb3e2aaf33
DATA ·ovr_dbg_flash_attn_kv_f16_fhm_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000+32(SB)/8, $0x42fc00003f7ffff6
DATA ·ovr_dbg_flash_attn_kv_f16_fhm_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000+40(SB)/8, $0x3f80000043400000
DATA ·ovr_dbg_flash_attn_kv_f16_fhm_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000+48(SB)/8, $0x7f00000082000000
DATA ·ovr_dbg_flash_attn_kv_f16_fhm_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000+56(SB)/8, $0x7fffffff
GLOBL ·ovr_dbg_flash_attn_kv_f16_fhm_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000(SB), RODATA|NOPTR, $64
