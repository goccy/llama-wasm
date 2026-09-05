// dbg_quantize_mat_q8_0_4x8: quantize four f32 rows into block_q8_0x4 (VMAXPS amax, nearest-even VCVTPS2DQ quants).
	MOVQ	l0+8(FP), SI
	MOVQ	l1+16(FP), DI
	MOVQ	l2+24(FP), CX
	MOVQ	CX, DX
	SHRQ	$5, DX
	JZ	q8mdone
	SHLQ	$2, CX
	LEAQ	(SI)(CX*4), AX
	CMPQ	R15, AX
	JCS	q8moob
	IMUL3Q	$136, DX, AX
	ADDQ	DI, AX
	CMPQ	R15, AX
	JCS	q8moob
	ADDQ	R14, SI
	ADDQ	R14, DI
	VXORPS	X9, X9, X9
q8mblk:
	MOVQ	SI, R9
	MOVQ	DI, R10
	MOVQ	DI, R11
	MOVL	$4, R8
q8mrow:
	VMOVUPS	0(R9), Y0
	VMOVUPS	32(R9), Y1
	VMOVUPS	64(R9), Y2
	VMOVUPS	96(R9), Y3
	VANDPS	·ovr_dbg_quantize_mat_q8_0_4x8_avx2_b32_ffffff7fffffff7fffffff7fffffff7fffffff7fffffff7fffffff7fffffff7f(SB), Y0, Y4
	VANDPS	·ovr_dbg_quantize_mat_q8_0_4x8_avx2_b32_ffffff7fffffff7fffffff7fffffff7fffffff7fffffff7fffffff7fffffff7f(SB), Y1, Y5
	VMAXPS	Y5, Y4, Y4
	VANDPS	·ovr_dbg_quantize_mat_q8_0_4x8_avx2_b32_ffffff7fffffff7fffffff7fffffff7fffffff7fffffff7fffffff7fffffff7f(SB), Y2, Y5
	VMAXPS	Y5, Y4, Y4
	VANDPS	·ovr_dbg_quantize_mat_q8_0_4x8_avx2_b32_ffffff7fffffff7fffffff7fffffff7fffffff7fffffff7fffffff7fffffff7f(SB), Y3, Y5
	VMAXPS	Y5, Y4, Y4
	VEXTRACTF128	$1, Y4, X5
	VMAXPS	X5, X4, X4
	VPERMILPS	$0x4e, X4, X5
	VMAXPS	X5, X4, X4
	VPERMILPS	$0xb1, X4, X5
	VMAXPS	X5, X4, X4
	VDIVSS	·ovr_dbg_quantize_mat_q8_0_4x8_avx2_b32_0000fe420000fe420000fe420000fe420000fe420000fe420000fe420000fe42(SB), X4, X5
	VUCOMISS	X9, X4
	JEQ	q8mzero
	VMOVSS	·ovr_dbg_quantize_mat_q8_0_4x8_avx2_b32_0000803f0000803f0000803f0000803f0000803f0000803f0000803f0000803f(SB), X6
	VDIVSS	X5, X6, X8
	JMP	q8mscale
q8mzero:
	VXORPS	X8, X8, X8
q8mscale:
	VCVTPS2PH	$0, X5, X5
	VMOVD	X5, AX
	MOVW	AX, (R11)
	VBROADCASTSS	X8, Y8
	VMULPS	Y8, Y0, Y4
	VCVTPS2DQ	Y4, Y4
	VEXTRACTI128	$1, Y4, X5
	VPACKSSDW	X5, X4, X4
	VPACKSSWB	X4, X4, X4
	VMOVQ	X4, 8(R10)
	VMULPS	Y8, Y1, Y4
	VCVTPS2DQ	Y4, Y4
	VEXTRACTI128	$1, Y4, X5
	VPACKSSDW	X5, X4, X4
	VPACKSSWB	X4, X4, X4
	VMOVQ	X4, 40(R10)
	VMULPS	Y8, Y2, Y4
	VCVTPS2DQ	Y4, Y4
	VEXTRACTI128	$1, Y4, X5
	VPACKSSDW	X5, X4, X4
	VPACKSSWB	X4, X4, X4
	VMOVQ	X4, 72(R10)
	VMULPS	Y8, Y3, Y4
	VCVTPS2DQ	Y4, Y4
	VEXTRACTI128	$1, Y4, X5
	VPACKSSDW	X5, X4, X4
	VPACKSSWB	X4, X4, X4
	VMOVQ	X4, 104(R10)
	ADDQ	CX, R9
	ADDQ	$8, R10
	ADDQ	$2, R11
	DECL	R8
	JNZ	q8mrow
	ADDQ	$128, SI
	ADDQ	$136, DI
	DECQ	DX
	JNZ	q8mblk
q8mdone:
	VZEROUPPER
	RET
q8moob:
	VZEROUPPER
	JMP	ovr_oob

DATA ·ovr_dbg_quantize_mat_q8_0_4x8_avx2_b32_0000803f0000803f0000803f0000803f0000803f0000803f0000803f0000803f+0(SB)/8, $0x3f8000003f800000
DATA ·ovr_dbg_quantize_mat_q8_0_4x8_avx2_b32_0000803f0000803f0000803f0000803f0000803f0000803f0000803f0000803f+8(SB)/8, $0x3f8000003f800000
DATA ·ovr_dbg_quantize_mat_q8_0_4x8_avx2_b32_0000803f0000803f0000803f0000803f0000803f0000803f0000803f0000803f+16(SB)/8, $0x3f8000003f800000
DATA ·ovr_dbg_quantize_mat_q8_0_4x8_avx2_b32_0000803f0000803f0000803f0000803f0000803f0000803f0000803f0000803f+24(SB)/8, $0x3f8000003f800000
GLOBL ·ovr_dbg_quantize_mat_q8_0_4x8_avx2_b32_0000803f0000803f0000803f0000803f0000803f0000803f0000803f0000803f(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_quantize_mat_q8_0_4x8_avx2_b32_0000fe420000fe420000fe420000fe420000fe420000fe420000fe420000fe42+0(SB)/8, $0x42fe000042fe0000
DATA ·ovr_dbg_quantize_mat_q8_0_4x8_avx2_b32_0000fe420000fe420000fe420000fe420000fe420000fe420000fe420000fe42+8(SB)/8, $0x42fe000042fe0000
DATA ·ovr_dbg_quantize_mat_q8_0_4x8_avx2_b32_0000fe420000fe420000fe420000fe420000fe420000fe420000fe420000fe42+16(SB)/8, $0x42fe000042fe0000
DATA ·ovr_dbg_quantize_mat_q8_0_4x8_avx2_b32_0000fe420000fe420000fe420000fe420000fe420000fe420000fe420000fe42+24(SB)/8, $0x42fe000042fe0000
GLOBL ·ovr_dbg_quantize_mat_q8_0_4x8_avx2_b32_0000fe420000fe420000fe420000fe420000fe420000fe420000fe420000fe42(SB), RODATA|NOPTR, $32
DATA ·ovr_dbg_quantize_mat_q8_0_4x8_avx2_b32_ffffff7fffffff7fffffff7fffffff7fffffff7fffffff7fffffff7fffffff7f+0(SB)/8, $0x7fffffff7fffffff
DATA ·ovr_dbg_quantize_mat_q8_0_4x8_avx2_b32_ffffff7fffffff7fffffff7fffffff7fffffff7fffffff7fffffff7fffffff7f+8(SB)/8, $0x7fffffff7fffffff
DATA ·ovr_dbg_quantize_mat_q8_0_4x8_avx2_b32_ffffff7fffffff7fffffff7fffffff7fffffff7fffffff7fffffff7fffffff7f+16(SB)/8, $0x7fffffff7fffffff
DATA ·ovr_dbg_quantize_mat_q8_0_4x8_avx2_b32_ffffff7fffffff7fffffff7fffffff7fffffff7fffffff7fffffff7fffffff7f+24(SB)/8, $0x7fffffff7fffffff
GLOBL ·ovr_dbg_quantize_mat_q8_0_4x8_avx2_b32_ffffff7fffffff7fffffff7fffffff7fffffff7fffffff7fffffff7fffffff7f(SB), RODATA|NOPTR, $32
