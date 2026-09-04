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
	MOVD	$·ovr_dbg_flash_attn_kv_f16_neon_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000(SB), R13
	VLD1	(R13), [V28.S4, V29.S4, V30.S4, V31.S4]
	WORD $0x4e0c07db // dup v27.4s, v30.s[1]
	WORD $0x4e1407da // dup v26.4s, v30.s[2]
	WORD $0x4e1c07d9 // dup v25.4s, v30.s[3]
	WORD $0x4e0407f8 // dup v24.4s, v31.s[0]
	WORD $0x4e0c07f7 // dup v23.4s, v31.s[1]
	WORD $0x4e040796 // dup v22.4s, v28.s[0]
	WORD $0x4e0c07b5 // dup v21.4s, v29.s[1]
	WORD $0x4e1c07b4 // dup v20.4s, v29.s[3]
	MOVW	$0xff800000, R27
	WORD $0x1e270370 // fmov s16, w27
	LSRW	$3, R1, R22
	ANDW	$1, R22, R22
	LSRW	$3, R2, R23
	ANDW	$1, R23, R23
	LSRW	$4, R1, R1
	LSRW	$4, R2, R2
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
fadone:
	WORD $0xbd00014c // str s12, [x10, #0]
	WORD $0xbd00054d // str s13, [x10, #4]
	RET
faoob:
	B	ovr_oob

DATA ·ovr_dbg_flash_attn_kv_f16_neon_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000+0(SB)/8, $0x3fb8aa3b4b400000
DATA ·ovr_dbg_flash_attn_kv_f16_neon_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000+8(SB)/8, $0x35bfbe8e3f317200
DATA ·ovr_dbg_flash_attn_kv_f16_neon_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000+16(SB)/8, $0x3d2b9f173c072010
DATA ·ovr_dbg_flash_attn_kv_f16_neon_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000+24(SB)/8, $0x3efffedb3e2aaf33
DATA ·ovr_dbg_flash_attn_kv_f16_neon_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000+32(SB)/8, $0x42fc00003f7ffff6
DATA ·ovr_dbg_flash_attn_kv_f16_neon_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000+40(SB)/8, $0x3f80000043400000
DATA ·ovr_dbg_flash_attn_kv_f16_neon_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000+48(SB)/8, $0x7f00000082000000
DATA ·ovr_dbg_flash_attn_kv_f16_neon_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000+56(SB)/8, $0x7fffffff
GLOBL ·ovr_dbg_flash_attn_kv_f16_neon_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000(SB), RODATA|NOPTR, $64
