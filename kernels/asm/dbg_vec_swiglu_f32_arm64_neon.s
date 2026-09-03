// dbg_vec_swiglu_f32: y = x / (1 + expf(-x)) * g.
	MOVW	l0+8(FP), R1
	CMPW	$1, R1
	BLT	swdone
	MOVD	l1+16(FP), R2
	MOVD	l2+24(FP), R3
	MOVD	l3+32(FP), R4
	LSL	$2, R1, R26
	ADD	R2, R26, R27
	CMP	R27, R21
	BLO	swoob
	ADD	R3, R26, R27
	CMP	R27, R21
	BLO	swoob
	ADD	R4, R26, R27
	CMP	R27, R21
	BLO	swoob
	ADD	R20, R2, R2
	ADD	R20, R3, R3
	ADD	R20, R4, R4
	MOVD	$·ovr_dbg_vec_swiglu_f32_neon_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000(SB), R5
	VLD1	(R5), [V28.S4, V29.S4, V30.S4, V31.S4]
	WORD $0x4e0c07db // dup v27.4s, v30.s[1]
	WORD $0x4e1407da // dup v26.4s, v30.s[2]
	WORD $0x4e1c07d9 // dup v25.4s, v30.s[3]
	WORD $0x4e0407f8 // dup v24.4s, v31.s[0]
	WORD $0x4e0c07f7 // dup v23.4s, v31.s[1]
	WORD $0x4e040796 // dup v22.4s, v28.s[0]
	WORD $0x4e0c07b5 // dup v21.4s, v29.s[1]
	WORD $0x4e1c07b4 // dup v20.4s, v29.s[3]
swloop4:
	CMPW	$4, R1
	BLT	swtail
	WORD $0x3cc0006d // ldur q13, [x3, #0]
	WORD $0x3cc0008c // ldur q12, [x4, #0]
	WORD $0x6ea0f9a0 // fneg v0.4s, v13.4s
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
	WORD $0x4e39d400 // fadd v0.4s, v0.4s, v25.4s
	WORD $0x6e20fda0 // fdiv v0.4s, v13.4s, v0.4s
	WORD $0x6e2cdc00 // fmul v0.4s, v0.4s, v12.4s
	WORD $0x3c800040 // stur q0, [x2, #0]
	ADD	$16, R2, R2
	ADD	$16, R3, R3
	ADD	$16, R4, R4
	SUBW	$4, R1, R1
	B	swloop4
swtail:
	CBZW	R1, swdone
	FMOVS	(R3), F13
	FMOVS	(R4), F12
	WORD $0x6ea0f9a0 // fneg v0.4s, v13.4s
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
	WORD $0x4e39d400 // fadd v0.4s, v0.4s, v25.4s
	WORD $0x6e20fda0 // fdiv v0.4s, v13.4s, v0.4s
	WORD $0x6e2cdc00 // fmul v0.4s, v0.4s, v12.4s
	FMOVS	F0, (R2)
	ADD	$4, R2, R2
	ADD	$4, R3, R3
	ADD	$4, R4, R4
	SUBW	$1, R1, R1
	B	swtail
swdone:
	RET
swoob:
	B	ovr_oob

DATA ·ovr_dbg_vec_swiglu_f32_neon_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000+0(SB)/8, $0x3fb8aa3b4b400000
DATA ·ovr_dbg_vec_swiglu_f32_neon_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000+8(SB)/8, $0x35bfbe8e3f317200
DATA ·ovr_dbg_vec_swiglu_f32_neon_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000+16(SB)/8, $0x3d2b9f173c072010
DATA ·ovr_dbg_vec_swiglu_f32_neon_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000+24(SB)/8, $0x3efffedb3e2aaf33
DATA ·ovr_dbg_vec_swiglu_f32_neon_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000+32(SB)/8, $0x42fc00003f7ffff6
DATA ·ovr_dbg_vec_swiglu_f32_neon_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000+40(SB)/8, $0x3f80000043400000
DATA ·ovr_dbg_vec_swiglu_f32_neon_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000+48(SB)/8, $0x7f00000082000000
DATA ·ovr_dbg_vec_swiglu_f32_neon_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000+56(SB)/8, $0x7fffffff
GLOBL ·ovr_dbg_vec_swiglu_f32_neon_b64_0000404b3baab83f0072313f8ebebf351020073c179f2b3d33af2a3edbfeff3ef6ff7f3f0000fc42000040430000803f000000820000007fffffff7f00000000(SB), RODATA|NOPTR, $64
