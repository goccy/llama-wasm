// dbg_vec_soft_max_f32: y = expf(x - max), returns sum(y) (f64).
	FMOVD	ZR, F15
	MOVW	l0+8(FP), R1
	CMPW	$1, R1
	BLT	smdone
	MOVD	l1+16(FP), R2
	MOVD	l2+24(FP), R3
	LSL	$2, R1, R26
	ADD	R2, R26, R27
	CMP	R27, R21
	BLO	smoob
	ADD	R3, R26, R27
	CMP	R27, R21
	BLO	smoob
	ADD	R20, R2, R2
	ADD	R20, R3, R3
	MOVD	$·kov_dbg_vec_soft_max_f32_neon_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000(SB), R4
	VLD1	(R4), [V28.S4, V29.S4, V30.S4, V31.S4]
	WORD $0x4e0c07db // dup v27.4s, v30.s[1]
	WORD $0x4e1407da // dup v26.4s, v30.s[2]
	WORD $0x4e1c07d9 // dup v25.4s, v30.s[3]
	WORD $0x4e0407f8 // dup v24.4s, v31.s[0]
	WORD $0x4e0c07f7 // dup v23.4s, v31.s[1]
	WORD $0x4e040796 // dup v22.4s, v28.s[0]
	WORD $0x4e0c07b5 // dup v21.4s, v29.s[1]
	WORD $0x4e1c07b4 // dup v20.4s, v29.s[3]
	FMOVS	l3+32(FP), F14
	WORD $0x4e0405ce // dup v14.4s, v14.s[0]
smloop4:
	CMPW	$4, R1
	BLT	smtail
	WORD $0x3cc00060 // ldur q0, [x3, #0]
	WORD $0x4eaed400 // fsub v0.4s, v0.4s, v14.4s
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
	WORD $0x3c800040 // stur q0, [x2, #0]
	WORD $0x6e20d401 // faddp v1.4s, v0.4s, v0.4s
	WORD $0x7e30d821 // faddp s1, v1.2s
	FCVTSD	F1, F1
	FADDD	F1, F15, F15
	ADD	$16, R2, R2
	ADD	$16, R3, R3
	SUBW	$4, R1, R1
	B	smloop4
smtail:
	CBZW	R1, smdone
	FMOVS	(R3), F0
	WORD $0x4eaed400 // fsub v0.4s, v0.4s, v14.4s
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
	FMOVS	F0, (R2)
	FCVTSD	F0, F1
	FADDD	F1, F15, F15
	ADD	$4, R2, R2
	ADD	$4, R3, R3
	SUBW	$1, R1, R1
	B	smtail
smdone:
	FMOVD	F15, r0+40(FP)
	RET
smoob:
	B	kov_oob

DATA ·kov_dbg_vec_soft_max_f32_neon_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000+0(SB)/8, $0x3fb8aa3b4b400000
DATA ·kov_dbg_vec_soft_max_f32_neon_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000+8(SB)/8, $0x35bfbe8e3f317200
DATA ·kov_dbg_vec_soft_max_f32_neon_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000+16(SB)/8, $0x3d2b9f173c072010
DATA ·kov_dbg_vec_soft_max_f32_neon_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000+24(SB)/8, $0x3efffedb3e2aaf33
DATA ·kov_dbg_vec_soft_max_f32_neon_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000+32(SB)/8, $0x42fc00003f7ffff6
DATA ·kov_dbg_vec_soft_max_f32_neon_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000+40(SB)/8, $0x3f80000043400000
DATA ·kov_dbg_vec_soft_max_f32_neon_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000+48(SB)/8, $0x7f00000082000000
DATA ·kov_dbg_vec_soft_max_f32_neon_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000+56(SB)/8, $0x7fffffff
GLOBL ·kov_dbg_vec_soft_max_f32_neon_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000(SB), RODATA|NOPTR, $64
