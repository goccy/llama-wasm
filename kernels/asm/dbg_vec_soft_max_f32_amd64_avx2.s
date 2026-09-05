// dbg_vec_soft_max_f32: y = expf(x - max), returns sum(y) (f64).
	VXORPS	X15, X15, X15
	MOVLQSX	l0+8(FP), CX
	TESTQ	CX, CX
	JLE	smdone
	MOVQ	l1+16(FP), DI
	MOVQ	l2+24(FP), SI
	LEAQ	(DI)(CX*4), R8
	CMPQ	R15, R8
	JCS	smoob
	LEAQ	(SI)(CX*4), R8
	CMPQ	R15, R8
	JCS	smoob
	ADDQ	R14, DI
	ADDQ	R14, SI
	VBROADCASTSS	l3+32(FP), Y14
smloop8:
	CMPQ	CX, $8
	JLT	smloop4
	VMOVUPS	(SI), Y0
	VSUBPS	Y14, Y0, Y0
	VMOVUPS	·ovr_dbg_vec_soft_max_f32_avx2_b32_8beb4cb0795f7186(SB), Y1
	VFMADD231PS	·ovr_dbg_vec_soft_max_f32_avx2_b32_7054b50c24276e06(SB), Y0, Y1
	VSUBPS	·ovr_dbg_vec_soft_max_f32_avx2_b32_8beb4cb0795f7186(SB), Y1, Y2
	VMOVAPS	Y0, Y3
	VFNMADD231PS	·ovr_dbg_vec_soft_max_f32_avx2_b32_049aeb2153adf33d(SB), Y2, Y3
	VFNMADD231PS	·ovr_dbg_vec_soft_max_f32_avx2_b32_dc9b3e83f27d7ba8(SB), Y2, Y3
	VPSLLD	$23, Y1, Y4
	VPADDD	·ovr_dbg_vec_soft_max_f32_avx2_b32_4f05df05f8da9356(SB), Y4, Y5
	VANDPS	·ovr_dbg_vec_soft_max_f32_avx2_b32_2270a8180ede3e7f(SB), Y2, Y6
	VCMPPS	$0x1e, ·ovr_dbg_vec_soft_max_f32_avx2_b32_f6f783af67905ee6(SB), Y6, Y7
	VMULPS	Y3, Y3, Y8
	VMOVUPS	·ovr_dbg_vec_soft_max_f32_avx2_b32_ba4f9dd3a258e0fe(SB), Y9
	VFMADD231PS	·ovr_dbg_vec_soft_max_f32_avx2_b32_a04a5c1eff2920be(SB), Y3, Y9
	VMOVUPS	·ovr_dbg_vec_soft_max_f32_avx2_b32_53b44234aa1a0eee(SB), Y10
	VFMADD231PS	·ovr_dbg_vec_soft_max_f32_avx2_b32_ca59331a47aa4fad(SB), Y3, Y10
	VFMADD231PS	Y8, Y9, Y10
	VMULPS	·ovr_dbg_vec_soft_max_f32_avx2_b32_a681f556d7d26b20(SB), Y3, Y11
	VFMADD231PS	Y8, Y10, Y11
	VMOVAPS	Y5, Y9
	VFMADD231PS	Y5, Y11, Y9
	VCMPPS	$0x12, ·ovr_dbg_vec_soft_max_f32_avx2_b32_66687aadf862bd77(SB), Y2, Y1
	VANDPS	·ovr_dbg_vec_soft_max_f32_avx2_b32_9b4f127fa18cc208(SB), Y1, Y1
	VPADDD	·ovr_dbg_vec_soft_max_f32_avx2_b32_63a36bf02fcb2933(SB), Y1, Y3
	VPSUBD	Y1, Y4, Y8
	VMOVAPS	Y8, Y10
	VFMADD231PS	Y11, Y8, Y10
	VMULPS	Y3, Y10, Y10
	VMULPS	Y3, Y3, Y5
	VCMPPS	$0x1e, ·ovr_dbg_vec_soft_max_f32_avx2_b32_f0363deef8ef6097(SB), Y6, Y2
	VBLENDVPS	Y7, Y10, Y9, Y7
	VBLENDVPS	Y2, Y5, Y7, Y0
	VMOVUPS	Y0, (DI)
	VEXTRACTF128	$1, Y0, X1
	VADDPS	X1, X0, X0
	VHADDPS	X0, X0, X0
	VHADDPS	X0, X0, X0
	VCVTSS2SD	X0, X0, X0
	VADDSD	X0, X15, X15
	ADDQ	$32, DI
	ADDQ	$32, SI
	SUBQ	$8, CX
	JMP	smloop8
smloop4:
	CMPQ	CX, $4
	JLT	smtail
	VMOVUPS	(SI), X0
	VSUBPS	X14, X0, X0
	VMOVUPS	·ovr_dbg_vec_soft_max_f32_avx2_b32_8beb4cb0795f7186(SB), X1
	VFMADD231PS	·ovr_dbg_vec_soft_max_f32_avx2_b32_7054b50c24276e06(SB), X0, X1
	VSUBPS	·ovr_dbg_vec_soft_max_f32_avx2_b32_8beb4cb0795f7186(SB), X1, X2
	VMOVAPS	X0, X3
	VFNMADD231PS	·ovr_dbg_vec_soft_max_f32_avx2_b32_049aeb2153adf33d(SB), X2, X3
	VFNMADD231PS	·ovr_dbg_vec_soft_max_f32_avx2_b32_dc9b3e83f27d7ba8(SB), X2, X3
	VPSLLD	$23, X1, X4
	VPADDD	·ovr_dbg_vec_soft_max_f32_avx2_b32_4f05df05f8da9356(SB), X4, X5
	VANDPS	·ovr_dbg_vec_soft_max_f32_avx2_b32_2270a8180ede3e7f(SB), X2, X6
	VCMPPS	$0x1e, ·ovr_dbg_vec_soft_max_f32_avx2_b32_f6f783af67905ee6(SB), X6, X7
	VMULPS	X3, X3, X8
	VMOVUPS	·ovr_dbg_vec_soft_max_f32_avx2_b32_ba4f9dd3a258e0fe(SB), X9
	VFMADD231PS	·ovr_dbg_vec_soft_max_f32_avx2_b32_a04a5c1eff2920be(SB), X3, X9
	VMOVUPS	·ovr_dbg_vec_soft_max_f32_avx2_b32_53b44234aa1a0eee(SB), X10
	VFMADD231PS	·ovr_dbg_vec_soft_max_f32_avx2_b32_ca59331a47aa4fad(SB), X3, X10
	VFMADD231PS	X8, X9, X10
	VMULPS	·ovr_dbg_vec_soft_max_f32_avx2_b32_a681f556d7d26b20(SB), X3, X11
	VFMADD231PS	X8, X10, X11
	VMOVAPS	X5, X9
	VFMADD231PS	X5, X11, X9
	VCMPPS	$0x12, ·ovr_dbg_vec_soft_max_f32_avx2_b32_66687aadf862bd77(SB), X2, X1
	VANDPS	·ovr_dbg_vec_soft_max_f32_avx2_b32_9b4f127fa18cc208(SB), X1, X1
	VPADDD	·ovr_dbg_vec_soft_max_f32_avx2_b32_63a36bf02fcb2933(SB), X1, X3
	VPSUBD	X1, X4, X8
	VMOVAPS	X8, X10
	VFMADD231PS	X11, X8, X10
	VMULPS	X3, X10, X10
	VMULPS	X3, X3, X5
	VCMPPS	$0x1e, ·ovr_dbg_vec_soft_max_f32_avx2_b32_f0363deef8ef6097(SB), X6, X2
	VBLENDVPS	X7, X10, X9, X7
	VBLENDVPS	X2, X5, X7, X0
	VMOVUPS	X0, (DI)
	VHADDPS	X0, X0, X0
	VHADDPS	X0, X0, X0
	VCVTSS2SD	X0, X0, X0
	VADDSD	X0, X15, X15
	ADDQ	$16, DI
	ADDQ	$16, SI
	SUBQ	$4, CX
	JMP	smloop4
smtail:
	TESTQ	CX, CX
	JZ	smdone
	VMOVSS	(SI), X0
	VSUBPS	X14, X0, X0
	VMOVUPS	·ovr_dbg_vec_soft_max_f32_avx2_b32_8beb4cb0795f7186(SB), X1
	VFMADD231PS	·ovr_dbg_vec_soft_max_f32_avx2_b32_7054b50c24276e06(SB), X0, X1
	VSUBPS	·ovr_dbg_vec_soft_max_f32_avx2_b32_8beb4cb0795f7186(SB), X1, X2
	VMOVAPS	X0, X3
	VFNMADD231PS	·ovr_dbg_vec_soft_max_f32_avx2_b32_049aeb2153adf33d(SB), X2, X3
	VFNMADD231PS	·ovr_dbg_vec_soft_max_f32_avx2_b32_dc9b3e83f27d7ba8(SB), X2, X3
	VPSLLD	$23, X1, X4
	VPADDD	·ovr_dbg_vec_soft_max_f32_avx2_b32_4f05df05f8da9356(SB), X4, X5
	VANDPS	·ovr_dbg_vec_soft_max_f32_avx2_b32_2270a8180ede3e7f(SB), X2, X6
	VCMPPS	$0x1e, ·ovr_dbg_vec_soft_max_f32_avx2_b32_f6f783af67905ee6(SB), X6, X7
	VMULPS	X3, X3, X8
	VMOVUPS	·ovr_dbg_vec_soft_max_f32_avx2_b32_ba4f9dd3a258e0fe(SB), X9
	VFMADD231PS	·ovr_dbg_vec_soft_max_f32_avx2_b32_a04a5c1eff2920be(SB), X3, X9
	VMOVUPS	·ovr_dbg_vec_soft_max_f32_avx2_b32_53b44234aa1a0eee(SB), X10
	VFMADD231PS	·ovr_dbg_vec_soft_max_f32_avx2_b32_ca59331a47aa4fad(SB), X3, X10
	VFMADD231PS	X8, X9, X10
	VMULPS	·ovr_dbg_vec_soft_max_f32_avx2_b32_a681f556d7d26b20(SB), X3, X11
	VFMADD231PS	X8, X10, X11
	VMOVAPS	X5, X9
	VFMADD231PS	X5, X11, X9
	VCMPPS	$0x12, ·ovr_dbg_vec_soft_max_f32_avx2_b32_66687aadf862bd77(SB), X2, X1
	VANDPS	·ovr_dbg_vec_soft_max_f32_avx2_b32_9b4f127fa18cc208(SB), X1, X1
	VPADDD	·ovr_dbg_vec_soft_max_f32_avx2_b32_63a36bf02fcb2933(SB), X1, X3
	VPSUBD	X1, X4, X8
	VMOVAPS	X8, X10
	VFMADD231PS	X11, X8, X10
	VMULPS	X3, X10, X10
	VMULPS	X3, X3, X5
	VCMPPS	$0x1e, ·ovr_dbg_vec_soft_max_f32_avx2_b32_f0363deef8ef6097(SB), X6, X2
	VBLENDVPS	X7, X10, X9, X7
	VBLENDVPS	X2, X5, X7, X0
	VMOVSS	X0, (DI)
	VCVTSS2SD	X0, X0, X0
	VADDSD	X0, X15, X15
	ADDQ	$4, DI
	ADDQ	$4, SI
	SUBQ	$1, CX
	JMP	smtail
smdone:
	VMOVSD	X15, r0+40(FP)
	VZEROUPPER
	RET
smoob:
	VZEROUPPER
	JMP	ovr_oob

DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_049aeb2153adf33d+0(SB)/8, $0x3f3172003f317200
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_049aeb2153adf33d+8(SB)/8, $0x3f3172003f317200
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_049aeb2153adf33d+16(SB)/8, $0x3f3172003f317200
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_049aeb2153adf33d+24(SB)/8, $0x3f3172003f317200
GLOBL ·ovr_dbg_vec_soft_max_f32_avx2_b32_049aeb2153adf33d(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_2270a8180ede3e7f+0(SB)/8, $0x7fffffff7fffffff
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_2270a8180ede3e7f+8(SB)/8, $0x7fffffff7fffffff
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_2270a8180ede3e7f+16(SB)/8, $0x7fffffff7fffffff
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_2270a8180ede3e7f+24(SB)/8, $0x7fffffff7fffffff
GLOBL ·ovr_dbg_vec_soft_max_f32_avx2_b32_2270a8180ede3e7f(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_4f05df05f8da9356+0(SB)/8, $0x3f8000003f800000
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_4f05df05f8da9356+8(SB)/8, $0x3f8000003f800000
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_4f05df05f8da9356+16(SB)/8, $0x3f8000003f800000
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_4f05df05f8da9356+24(SB)/8, $0x3f8000003f800000
GLOBL ·ovr_dbg_vec_soft_max_f32_avx2_b32_4f05df05f8da9356(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_53b44234aa1a0eee+0(SB)/8, $0x3efffedb3efffedb
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_53b44234aa1a0eee+8(SB)/8, $0x3efffedb3efffedb
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_53b44234aa1a0eee+16(SB)/8, $0x3efffedb3efffedb
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_53b44234aa1a0eee+24(SB)/8, $0x3efffedb3efffedb
GLOBL ·ovr_dbg_vec_soft_max_f32_avx2_b32_53b44234aa1a0eee(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_63a36bf02fcb2933+0(SB)/8, $0x7f0000007f000000
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_63a36bf02fcb2933+8(SB)/8, $0x7f0000007f000000
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_63a36bf02fcb2933+16(SB)/8, $0x7f0000007f000000
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_63a36bf02fcb2933+24(SB)/8, $0x7f0000007f000000
GLOBL ·ovr_dbg_vec_soft_max_f32_avx2_b32_63a36bf02fcb2933(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_66687aadf862bd77+0(SB)/8, $0x0
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_66687aadf862bd77+8(SB)/8, $0x0
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_66687aadf862bd77+16(SB)/8, $0x0
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_66687aadf862bd77+24(SB)/8, $0x0
GLOBL ·ovr_dbg_vec_soft_max_f32_avx2_b32_66687aadf862bd77(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_7054b50c24276e06+0(SB)/8, $0x3fb8aa3b3fb8aa3b
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_7054b50c24276e06+8(SB)/8, $0x3fb8aa3b3fb8aa3b
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_7054b50c24276e06+16(SB)/8, $0x3fb8aa3b3fb8aa3b
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_7054b50c24276e06+24(SB)/8, $0x3fb8aa3b3fb8aa3b
GLOBL ·ovr_dbg_vec_soft_max_f32_avx2_b32_7054b50c24276e06(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_8beb4cb0795f7186+0(SB)/8, $0x4b4000004b400000
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_8beb4cb0795f7186+8(SB)/8, $0x4b4000004b400000
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_8beb4cb0795f7186+16(SB)/8, $0x4b4000004b400000
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_8beb4cb0795f7186+24(SB)/8, $0x4b4000004b400000
GLOBL ·ovr_dbg_vec_soft_max_f32_avx2_b32_8beb4cb0795f7186(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_9b4f127fa18cc208+0(SB)/8, $0x8200000082000000
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_9b4f127fa18cc208+8(SB)/8, $0x8200000082000000
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_9b4f127fa18cc208+16(SB)/8, $0x8200000082000000
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_9b4f127fa18cc208+24(SB)/8, $0x8200000082000000
GLOBL ·ovr_dbg_vec_soft_max_f32_avx2_b32_9b4f127fa18cc208(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_a04a5c1eff2920be+0(SB)/8, $0x3c0720103c072010
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_a04a5c1eff2920be+8(SB)/8, $0x3c0720103c072010
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_a04a5c1eff2920be+16(SB)/8, $0x3c0720103c072010
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_a04a5c1eff2920be+24(SB)/8, $0x3c0720103c072010
GLOBL ·ovr_dbg_vec_soft_max_f32_avx2_b32_a04a5c1eff2920be(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_a681f556d7d26b20+0(SB)/8, $0x3f7ffff63f7ffff6
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_a681f556d7d26b20+8(SB)/8, $0x3f7ffff63f7ffff6
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_a681f556d7d26b20+16(SB)/8, $0x3f7ffff63f7ffff6
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_a681f556d7d26b20+24(SB)/8, $0x3f7ffff63f7ffff6
GLOBL ·ovr_dbg_vec_soft_max_f32_avx2_b32_a681f556d7d26b20(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_ba4f9dd3a258e0fe+0(SB)/8, $0x3d2b9f173d2b9f17
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_ba4f9dd3a258e0fe+8(SB)/8, $0x3d2b9f173d2b9f17
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_ba4f9dd3a258e0fe+16(SB)/8, $0x3d2b9f173d2b9f17
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_ba4f9dd3a258e0fe+24(SB)/8, $0x3d2b9f173d2b9f17
GLOBL ·ovr_dbg_vec_soft_max_f32_avx2_b32_ba4f9dd3a258e0fe(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_ca59331a47aa4fad+0(SB)/8, $0x3e2aaf333e2aaf33
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_ca59331a47aa4fad+8(SB)/8, $0x3e2aaf333e2aaf33
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_ca59331a47aa4fad+16(SB)/8, $0x3e2aaf333e2aaf33
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_ca59331a47aa4fad+24(SB)/8, $0x3e2aaf333e2aaf33
GLOBL ·ovr_dbg_vec_soft_max_f32_avx2_b32_ca59331a47aa4fad(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_dc9b3e83f27d7ba8+0(SB)/8, $0x35bfbe8e35bfbe8e
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_dc9b3e83f27d7ba8+8(SB)/8, $0x35bfbe8e35bfbe8e
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_dc9b3e83f27d7ba8+16(SB)/8, $0x35bfbe8e35bfbe8e
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_dc9b3e83f27d7ba8+24(SB)/8, $0x35bfbe8e35bfbe8e
GLOBL ·ovr_dbg_vec_soft_max_f32_avx2_b32_dc9b3e83f27d7ba8(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_f0363deef8ef6097+0(SB)/8, $0x4340000043400000
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_f0363deef8ef6097+8(SB)/8, $0x4340000043400000
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_f0363deef8ef6097+16(SB)/8, $0x4340000043400000
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_f0363deef8ef6097+24(SB)/8, $0x4340000043400000
GLOBL ·ovr_dbg_vec_soft_max_f32_avx2_b32_f0363deef8ef6097(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_f6f783af67905ee6+0(SB)/8, $0x42fc000042fc0000
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_f6f783af67905ee6+8(SB)/8, $0x42fc000042fc0000
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_f6f783af67905ee6+16(SB)/8, $0x42fc000042fc0000
DATA ·ovr_dbg_vec_soft_max_f32_avx2_b32_f6f783af67905ee6+24(SB)/8, $0x42fc000042fc0000
GLOBL ·ovr_dbg_vec_soft_max_f32_avx2_b32_f6f783af67905ee6(SB), RODATA|NOPTR, $32
