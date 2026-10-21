// dbg_vec_geglu_erf_f32: y = 0.5*x*(1 + erf(x/sqrt2))*g, erf by A&S 7.1.26.
	MOVLQSX	l0+8(FP), CX
	TESTQ	CX, CX
	JLE	gedone
	MOVQ	l1+16(FP), DI
	MOVQ	l2+24(FP), SI
	MOVQ	l3+32(FP), DX
	LEAQ	(DI)(CX*4), R8
	CMPQ	R15, R8
	JCS	geoob
	LEAQ	(SI)(CX*4), R8
	CMPQ	R15, R8
	JCS	geoob
	LEAQ	(DX)(CX*4), R8
	CMPQ	R15, R8
	JCS	geoob
	ADDQ	R14, DI
	ADDQ	R14, SI
	ADDQ	R14, DX
geloop8:
	CMPQ	CX, $8
	JLT	geloop4
	VMOVUPS	(SI), Y13
	VMOVUPS	(DX), Y12
	VMULPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_23b9dc47f77027fa(SB), Y13, Y14
	VANDPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_2270a8180ede3e7f(SB), Y14, Y15
	VMULPS	Y15, Y15, Y0
	VXORPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_418c19e2fd56b2a8(SB), Y0, Y0
	VMOVUPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_8beb4cb0795f7186(SB), Y1
	VFMADD231PS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_7054b50c24276e06(SB), Y0, Y1
	VSUBPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_8beb4cb0795f7186(SB), Y1, Y2
	VMOVAPS	Y0, Y3
	VFNMADD231PS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_049aeb2153adf33d(SB), Y2, Y3
	VFNMADD231PS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_dc9b3e83f27d7ba8(SB), Y2, Y3
	VPSLLD	$23, Y1, Y4
	VPADDD	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_4f05df05f8da9356(SB), Y4, Y5
	VANDPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_2270a8180ede3e7f(SB), Y2, Y6
	VCMPPS	$0x1e, ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_f6f783af67905ee6(SB), Y6, Y7
	VMULPS	Y3, Y3, Y8
	VMOVUPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_ba4f9dd3a258e0fe(SB), Y9
	VFMADD231PS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_a04a5c1eff2920be(SB), Y3, Y9
	VMOVUPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_53b44234aa1a0eee(SB), Y10
	VFMADD231PS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_ca59331a47aa4fad(SB), Y3, Y10
	VFMADD231PS	Y8, Y9, Y10
	VMULPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_a681f556d7d26b20(SB), Y3, Y11
	VFMADD231PS	Y8, Y10, Y11
	VMOVAPS	Y5, Y9
	VFMADD231PS	Y5, Y11, Y9
	VCMPPS	$0x12, ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_66687aadf862bd77(SB), Y2, Y1
	VANDPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_9b4f127fa18cc208(SB), Y1, Y1
	VPADDD	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_63a36bf02fcb2933(SB), Y1, Y3
	VPSUBD	Y1, Y4, Y8
	VMOVAPS	Y8, Y10
	VFMADD231PS	Y11, Y8, Y10
	VMULPS	Y3, Y10, Y10
	VMULPS	Y3, Y3, Y5
	VCMPPS	$0x1e, ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_f0363deef8ef6097(SB), Y6, Y2
	VBLENDVPS	Y7, Y10, Y9, Y7
	VBLENDVPS	Y2, Y5, Y7, Y0
	VMULPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_4885b9be63484916(SB), Y15, Y1
	VADDPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_4f05df05f8da9356(SB), Y1, Y1
	VMOVUPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_4f05df05f8da9356(SB), Y2
	VDIVPS	Y1, Y2, Y2
	VMOVUPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_d31986b375bb3a78(SB), Y3
	VMULPS	Y2, Y3, Y3
	VADDPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_0a992fb6c25f09b0(SB), Y3, Y3
	VMULPS	Y2, Y3, Y3
	VADDPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_b533813de83c85c4(SB), Y3, Y3
	VMULPS	Y2, Y3, Y3
	VADDPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_ffa115bb612140d1(SB), Y3, Y3
	VMULPS	Y2, Y3, Y3
	VADDPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_5e499e52eec5ec07(SB), Y3, Y3
	VMULPS	Y2, Y3, Y4
	VMULPS	Y0, Y4, Y4
	VMOVUPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_4f05df05f8da9356(SB), Y5
	VSUBPS	Y4, Y5, Y5
	VANDPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_418c19e2fd56b2a8(SB), Y14, Y6
	VORPS	Y6, Y5, Y5
	VADDPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_4f05df05f8da9356(SB), Y5, Y7
	VMULPS	Y13, Y7, Y7
	VMULPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_f09896aef1dbfb9c(SB), Y7, Y7
	VMULPS	Y12, Y7, Y7
	VMOVUPS	Y7, (DI)
	ADDQ	$32, DI
	ADDQ	$32, SI
	ADDQ	$32, DX
	SUBQ	$8, CX
	JMP	geloop8
geloop4:
	CMPQ	CX, $4
	JLT	getail
	VMOVUPS	(SI), X13
	VMOVUPS	(DX), X12
	VMULPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_23b9dc47f77027fa(SB), X13, X14
	VANDPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_2270a8180ede3e7f(SB), X14, X15
	VMULPS	X15, X15, X0
	VXORPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_418c19e2fd56b2a8(SB), X0, X0
	VMOVUPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_8beb4cb0795f7186(SB), X1
	VFMADD231PS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_7054b50c24276e06(SB), X0, X1
	VSUBPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_8beb4cb0795f7186(SB), X1, X2
	VMOVAPS	X0, X3
	VFNMADD231PS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_049aeb2153adf33d(SB), X2, X3
	VFNMADD231PS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_dc9b3e83f27d7ba8(SB), X2, X3
	VPSLLD	$23, X1, X4
	VPADDD	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_4f05df05f8da9356(SB), X4, X5
	VANDPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_2270a8180ede3e7f(SB), X2, X6
	VCMPPS	$0x1e, ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_f6f783af67905ee6(SB), X6, X7
	VMULPS	X3, X3, X8
	VMOVUPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_ba4f9dd3a258e0fe(SB), X9
	VFMADD231PS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_a04a5c1eff2920be(SB), X3, X9
	VMOVUPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_53b44234aa1a0eee(SB), X10
	VFMADD231PS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_ca59331a47aa4fad(SB), X3, X10
	VFMADD231PS	X8, X9, X10
	VMULPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_a681f556d7d26b20(SB), X3, X11
	VFMADD231PS	X8, X10, X11
	VMOVAPS	X5, X9
	VFMADD231PS	X5, X11, X9
	VCMPPS	$0x12, ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_66687aadf862bd77(SB), X2, X1
	VANDPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_9b4f127fa18cc208(SB), X1, X1
	VPADDD	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_63a36bf02fcb2933(SB), X1, X3
	VPSUBD	X1, X4, X8
	VMOVAPS	X8, X10
	VFMADD231PS	X11, X8, X10
	VMULPS	X3, X10, X10
	VMULPS	X3, X3, X5
	VCMPPS	$0x1e, ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_f0363deef8ef6097(SB), X6, X2
	VBLENDVPS	X7, X10, X9, X7
	VBLENDVPS	X2, X5, X7, X0
	VMULPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_4885b9be63484916(SB), X15, X1
	VADDPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_4f05df05f8da9356(SB), X1, X1
	VMOVUPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_4f05df05f8da9356(SB), X2
	VDIVPS	X1, X2, X2
	VMOVUPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_d31986b375bb3a78(SB), X3
	VMULPS	X2, X3, X3
	VADDPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_0a992fb6c25f09b0(SB), X3, X3
	VMULPS	X2, X3, X3
	VADDPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_b533813de83c85c4(SB), X3, X3
	VMULPS	X2, X3, X3
	VADDPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_ffa115bb612140d1(SB), X3, X3
	VMULPS	X2, X3, X3
	VADDPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_5e499e52eec5ec07(SB), X3, X3
	VMULPS	X2, X3, X4
	VMULPS	X0, X4, X4
	VMOVUPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_4f05df05f8da9356(SB), X5
	VSUBPS	X4, X5, X5
	VANDPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_418c19e2fd56b2a8(SB), X14, X6
	VORPS	X6, X5, X5
	VADDPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_4f05df05f8da9356(SB), X5, X7
	VMULPS	X13, X7, X7
	VMULPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_f09896aef1dbfb9c(SB), X7, X7
	VMULPS	X12, X7, X7
	VMOVUPS	X7, (DI)
	ADDQ	$16, DI
	ADDQ	$16, SI
	ADDQ	$16, DX
	SUBQ	$4, CX
	JMP	geloop4
getail:
	TESTQ	CX, CX
	JZ	gedone
	VMOVSS	(SI), X13
	VMOVSS	(DX), X12
	VMULPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_23b9dc47f77027fa(SB), X13, X14
	VANDPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_2270a8180ede3e7f(SB), X14, X15
	VMULPS	X15, X15, X0
	VXORPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_418c19e2fd56b2a8(SB), X0, X0
	VMOVUPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_8beb4cb0795f7186(SB), X1
	VFMADD231PS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_7054b50c24276e06(SB), X0, X1
	VSUBPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_8beb4cb0795f7186(SB), X1, X2
	VMOVAPS	X0, X3
	VFNMADD231PS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_049aeb2153adf33d(SB), X2, X3
	VFNMADD231PS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_dc9b3e83f27d7ba8(SB), X2, X3
	VPSLLD	$23, X1, X4
	VPADDD	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_4f05df05f8da9356(SB), X4, X5
	VANDPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_2270a8180ede3e7f(SB), X2, X6
	VCMPPS	$0x1e, ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_f6f783af67905ee6(SB), X6, X7
	VMULPS	X3, X3, X8
	VMOVUPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_ba4f9dd3a258e0fe(SB), X9
	VFMADD231PS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_a04a5c1eff2920be(SB), X3, X9
	VMOVUPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_53b44234aa1a0eee(SB), X10
	VFMADD231PS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_ca59331a47aa4fad(SB), X3, X10
	VFMADD231PS	X8, X9, X10
	VMULPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_a681f556d7d26b20(SB), X3, X11
	VFMADD231PS	X8, X10, X11
	VMOVAPS	X5, X9
	VFMADD231PS	X5, X11, X9
	VCMPPS	$0x12, ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_66687aadf862bd77(SB), X2, X1
	VANDPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_9b4f127fa18cc208(SB), X1, X1
	VPADDD	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_63a36bf02fcb2933(SB), X1, X3
	VPSUBD	X1, X4, X8
	VMOVAPS	X8, X10
	VFMADD231PS	X11, X8, X10
	VMULPS	X3, X10, X10
	VMULPS	X3, X3, X5
	VCMPPS	$0x1e, ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_f0363deef8ef6097(SB), X6, X2
	VBLENDVPS	X7, X10, X9, X7
	VBLENDVPS	X2, X5, X7, X0
	VMULPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_4885b9be63484916(SB), X15, X1
	VADDPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_4f05df05f8da9356(SB), X1, X1
	VMOVUPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_4f05df05f8da9356(SB), X2
	VDIVPS	X1, X2, X2
	VMOVUPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_d31986b375bb3a78(SB), X3
	VMULPS	X2, X3, X3
	VADDPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_0a992fb6c25f09b0(SB), X3, X3
	VMULPS	X2, X3, X3
	VADDPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_b533813de83c85c4(SB), X3, X3
	VMULPS	X2, X3, X3
	VADDPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_ffa115bb612140d1(SB), X3, X3
	VMULPS	X2, X3, X3
	VADDPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_5e499e52eec5ec07(SB), X3, X3
	VMULPS	X2, X3, X4
	VMULPS	X0, X4, X4
	VMOVUPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_4f05df05f8da9356(SB), X5
	VSUBPS	X4, X5, X5
	VANDPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_418c19e2fd56b2a8(SB), X14, X6
	VORPS	X6, X5, X5
	VADDPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_4f05df05f8da9356(SB), X5, X7
	VMULPS	X13, X7, X7
	VMULPS	·ovr_dbg_vec_geglu_erf_f32_avx2_b32_f09896aef1dbfb9c(SB), X7, X7
	VMULPS	X12, X7, X7
	VMOVSS	X7, (DI)
	ADDQ	$4, DI
	ADDQ	$4, SI
	ADDQ	$4, DX
	SUBQ	$1, CX
	JMP	getail
gedone:
	VZEROUPPER
	RET
geoob:
	VZEROUPPER
	JMP	ovr_oob

DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_049aeb2153adf33d+0(SB)/8, $0x3f3172003f317200
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_049aeb2153adf33d+8(SB)/8, $0x3f3172003f317200
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_049aeb2153adf33d+16(SB)/8, $0x3f3172003f317200
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_049aeb2153adf33d+24(SB)/8, $0x3f3172003f317200
GLOBL ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_049aeb2153adf33d(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_0a992fb6c25f09b0+0(SB)/8, $0xbfba00e3bfba00e3
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_0a992fb6c25f09b0+8(SB)/8, $0xbfba00e3bfba00e3
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_0a992fb6c25f09b0+16(SB)/8, $0xbfba00e3bfba00e3
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_0a992fb6c25f09b0+24(SB)/8, $0xbfba00e3bfba00e3
GLOBL ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_0a992fb6c25f09b0(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_2270a8180ede3e7f+0(SB)/8, $0x7fffffff7fffffff
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_2270a8180ede3e7f+8(SB)/8, $0x7fffffff7fffffff
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_2270a8180ede3e7f+16(SB)/8, $0x7fffffff7fffffff
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_2270a8180ede3e7f+24(SB)/8, $0x7fffffff7fffffff
GLOBL ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_2270a8180ede3e7f(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_23b9dc47f77027fa+0(SB)/8, $0x3f3504f33f3504f3
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_23b9dc47f77027fa+8(SB)/8, $0x3f3504f33f3504f3
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_23b9dc47f77027fa+16(SB)/8, $0x3f3504f33f3504f3
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_23b9dc47f77027fa+24(SB)/8, $0x3f3504f33f3504f3
GLOBL ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_23b9dc47f77027fa(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_418c19e2fd56b2a8+0(SB)/8, $0x8000000080000000
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_418c19e2fd56b2a8+8(SB)/8, $0x8000000080000000
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_418c19e2fd56b2a8+16(SB)/8, $0x8000000080000000
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_418c19e2fd56b2a8+24(SB)/8, $0x8000000080000000
GLOBL ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_418c19e2fd56b2a8(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_4885b9be63484916+0(SB)/8, $0x3ea7ba053ea7ba05
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_4885b9be63484916+8(SB)/8, $0x3ea7ba053ea7ba05
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_4885b9be63484916+16(SB)/8, $0x3ea7ba053ea7ba05
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_4885b9be63484916+24(SB)/8, $0x3ea7ba053ea7ba05
GLOBL ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_4885b9be63484916(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_4f05df05f8da9356+0(SB)/8, $0x3f8000003f800000
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_4f05df05f8da9356+8(SB)/8, $0x3f8000003f800000
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_4f05df05f8da9356+16(SB)/8, $0x3f8000003f800000
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_4f05df05f8da9356+24(SB)/8, $0x3f8000003f800000
GLOBL ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_4f05df05f8da9356(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_53b44234aa1a0eee+0(SB)/8, $0x3efffedb3efffedb
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_53b44234aa1a0eee+8(SB)/8, $0x3efffedb3efffedb
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_53b44234aa1a0eee+16(SB)/8, $0x3efffedb3efffedb
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_53b44234aa1a0eee+24(SB)/8, $0x3efffedb3efffedb
GLOBL ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_53b44234aa1a0eee(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_5e499e52eec5ec07+0(SB)/8, $0x3e8279063e827906
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_5e499e52eec5ec07+8(SB)/8, $0x3e8279063e827906
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_5e499e52eec5ec07+16(SB)/8, $0x3e8279063e827906
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_5e499e52eec5ec07+24(SB)/8, $0x3e8279063e827906
GLOBL ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_5e499e52eec5ec07(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_63a36bf02fcb2933+0(SB)/8, $0x7f0000007f000000
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_63a36bf02fcb2933+8(SB)/8, $0x7f0000007f000000
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_63a36bf02fcb2933+16(SB)/8, $0x7f0000007f000000
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_63a36bf02fcb2933+24(SB)/8, $0x7f0000007f000000
GLOBL ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_63a36bf02fcb2933(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_66687aadf862bd77+0(SB)/8, $0x0
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_66687aadf862bd77+8(SB)/8, $0x0
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_66687aadf862bd77+16(SB)/8, $0x0
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_66687aadf862bd77+24(SB)/8, $0x0
GLOBL ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_66687aadf862bd77(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_7054b50c24276e06+0(SB)/8, $0x3fb8aa3b3fb8aa3b
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_7054b50c24276e06+8(SB)/8, $0x3fb8aa3b3fb8aa3b
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_7054b50c24276e06+16(SB)/8, $0x3fb8aa3b3fb8aa3b
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_7054b50c24276e06+24(SB)/8, $0x3fb8aa3b3fb8aa3b
GLOBL ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_7054b50c24276e06(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_8beb4cb0795f7186+0(SB)/8, $0x4b4000004b400000
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_8beb4cb0795f7186+8(SB)/8, $0x4b4000004b400000
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_8beb4cb0795f7186+16(SB)/8, $0x4b4000004b400000
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_8beb4cb0795f7186+24(SB)/8, $0x4b4000004b400000
GLOBL ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_8beb4cb0795f7186(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_9b4f127fa18cc208+0(SB)/8, $0x8200000082000000
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_9b4f127fa18cc208+8(SB)/8, $0x8200000082000000
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_9b4f127fa18cc208+16(SB)/8, $0x8200000082000000
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_9b4f127fa18cc208+24(SB)/8, $0x8200000082000000
GLOBL ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_9b4f127fa18cc208(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_a04a5c1eff2920be+0(SB)/8, $0x3c0720103c072010
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_a04a5c1eff2920be+8(SB)/8, $0x3c0720103c072010
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_a04a5c1eff2920be+16(SB)/8, $0x3c0720103c072010
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_a04a5c1eff2920be+24(SB)/8, $0x3c0720103c072010
GLOBL ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_a04a5c1eff2920be(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_a681f556d7d26b20+0(SB)/8, $0x3f7ffff63f7ffff6
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_a681f556d7d26b20+8(SB)/8, $0x3f7ffff63f7ffff6
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_a681f556d7d26b20+16(SB)/8, $0x3f7ffff63f7ffff6
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_a681f556d7d26b20+24(SB)/8, $0x3f7ffff63f7ffff6
GLOBL ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_a681f556d7d26b20(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_b533813de83c85c4+0(SB)/8, $0x3fb5f0e33fb5f0e3
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_b533813de83c85c4+8(SB)/8, $0x3fb5f0e33fb5f0e3
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_b533813de83c85c4+16(SB)/8, $0x3fb5f0e33fb5f0e3
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_b533813de83c85c4+24(SB)/8, $0x3fb5f0e33fb5f0e3
GLOBL ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_b533813de83c85c4(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_ba4f9dd3a258e0fe+0(SB)/8, $0x3d2b9f173d2b9f17
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_ba4f9dd3a258e0fe+8(SB)/8, $0x3d2b9f173d2b9f17
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_ba4f9dd3a258e0fe+16(SB)/8, $0x3d2b9f173d2b9f17
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_ba4f9dd3a258e0fe+24(SB)/8, $0x3d2b9f173d2b9f17
GLOBL ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_ba4f9dd3a258e0fe(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_ca59331a47aa4fad+0(SB)/8, $0x3e2aaf333e2aaf33
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_ca59331a47aa4fad+8(SB)/8, $0x3e2aaf333e2aaf33
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_ca59331a47aa4fad+16(SB)/8, $0x3e2aaf333e2aaf33
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_ca59331a47aa4fad+24(SB)/8, $0x3e2aaf333e2aaf33
GLOBL ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_ca59331a47aa4fad(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_d31986b375bb3a78+0(SB)/8, $0x3f87dc223f87dc22
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_d31986b375bb3a78+8(SB)/8, $0x3f87dc223f87dc22
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_d31986b375bb3a78+16(SB)/8, $0x3f87dc223f87dc22
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_d31986b375bb3a78+24(SB)/8, $0x3f87dc223f87dc22
GLOBL ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_d31986b375bb3a78(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_dc9b3e83f27d7ba8+0(SB)/8, $0x35bfbe8e35bfbe8e
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_dc9b3e83f27d7ba8+8(SB)/8, $0x35bfbe8e35bfbe8e
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_dc9b3e83f27d7ba8+16(SB)/8, $0x35bfbe8e35bfbe8e
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_dc9b3e83f27d7ba8+24(SB)/8, $0x35bfbe8e35bfbe8e
GLOBL ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_dc9b3e83f27d7ba8(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_f0363deef8ef6097+0(SB)/8, $0x4340000043400000
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_f0363deef8ef6097+8(SB)/8, $0x4340000043400000
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_f0363deef8ef6097+16(SB)/8, $0x4340000043400000
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_f0363deef8ef6097+24(SB)/8, $0x4340000043400000
GLOBL ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_f0363deef8ef6097(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_f09896aef1dbfb9c+0(SB)/8, $0x3f0000003f000000
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_f09896aef1dbfb9c+8(SB)/8, $0x3f0000003f000000
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_f09896aef1dbfb9c+16(SB)/8, $0x3f0000003f000000
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_f09896aef1dbfb9c+24(SB)/8, $0x3f0000003f000000
GLOBL ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_f09896aef1dbfb9c(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_f6f783af67905ee6+0(SB)/8, $0x42fc000042fc0000
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_f6f783af67905ee6+8(SB)/8, $0x42fc000042fc0000
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_f6f783af67905ee6+16(SB)/8, $0x42fc000042fc0000
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_f6f783af67905ee6+24(SB)/8, $0x42fc000042fc0000
GLOBL ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_f6f783af67905ee6(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_ffa115bb612140d1+0(SB)/8, $0xbe91a98ebe91a98e
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_ffa115bb612140d1+8(SB)/8, $0xbe91a98ebe91a98e
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_ffa115bb612140d1+16(SB)/8, $0xbe91a98ebe91a98e
DATA ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_ffa115bb612140d1+24(SB)/8, $0xbe91a98ebe91a98e
GLOBL ·ovr_dbg_vec_geglu_erf_f32_avx2_b32_ffa115bb612140d1(SB), RODATA|NOPTR, $32
