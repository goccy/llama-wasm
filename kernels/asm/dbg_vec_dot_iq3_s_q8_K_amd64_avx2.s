// dbg_vec_dot_iq3_s_q8_K: iq3_s x q8_K dot (AVX2), grid gathers through VPINSRD, signs applied to the activations.
	VXORPS	Y0, Y0, Y0
	MOVLQSX	l0+8(FP), CX
	SHRQ	$8, CX
	MOVQ	l1+16(FP), DI
	LEAQ	4(DI), R8
	CMPQ	R15, R8
	JCS	i3soob
	ADDQ	R14, DI
	TESTQ	CX, CX
	JZ	i3sreduce
	MOVQ	l3+32(FP), SI
	MOVQ	l5+48(FP), DX
	IMUL3Q	$110, CX, R8
	ADDQ	SI, R8
	CMPQ	R15, R8
	JCS	i3soob
	IMUL3Q	$292, CX, R8
	ADDQ	DX, R8
	CMPQ	R15, R8
	JCS	i3soob
	ADDQ	R14, SI
	ADDQ	R14, DX
	MOVQ	$·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48(SB), R12
	VMOVDQU	·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+64(SB), Y10
	VMOVDQU	·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+896(SB), Y11
	VMOVDQU	·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+928(SB), Y12
	VMOVDQU	·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+672(SB), Y13
i3sblk:
	VPXOR	Y1, Y1, Y1
	MOVBLZX	66(SI), R10
	MOVBLZX	2(SI), R14
	MOVL	R10, R11
	SHRL	$0, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$0, R15, X2, X2
	MOVBLZX	3(SI), R14
	MOVL	R10, R11
	SHRL	$1, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$1, R15, X2, X2
	MOVBLZX	4(SI), R14
	MOVL	R10, R11
	SHRL	$2, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$2, R15, X2, X2
	MOVBLZX	5(SI), R14
	MOVL	R10, R11
	SHRL	$3, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$3, R15, X2, X2
	MOVBLZX	6(SI), R14
	MOVL	R10, R11
	SHRL	$4, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$0, R15, X5, X5
	MOVBLZX	7(SI), R14
	MOVL	R10, R11
	SHRL	$5, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$1, R15, X5, X5
	MOVBLZX	8(SI), R14
	MOVL	R10, R11
	SHRL	$6, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$2, R15, X5, X5
	MOVBLZX	9(SI), R14
	MOVL	R10, R11
	SHRL	$7, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$3, R15, X5, X5
	VINSERTI128	$1, X5, Y2, Y2
	MOVL	74(SI), R9
	VMOVD	R9, X4
	VPBROADCASTD	X4, Y4
	VPSHUFB	Y11, Y4, Y4
	VPAND	Y12, Y4, Y4
	VPCMPEQB	Y12, Y4, Y4
	VPOR	Y13, Y4, Y4
	VMOVDQU	4(DX), Y3
	VPSIGNB	Y4, Y3, Y3
	VPMADDUBSW	Y3, Y2, Y5
	VPMADDWD	Y10, Y5, Y5
	MOVBLZX	106(SI), R8
	ANDL	$0xf, R8
	LEAL	1(R8)(R8*1), R8
	VMOVD	R8, X6
	VPBROADCASTD	X6, Y6
	VPMULLD	Y6, Y5, Y5
	VPADDD	Y5, Y1, Y1
	MOVBLZX	67(SI), R10
	MOVBLZX	10(SI), R14
	MOVL	R10, R11
	SHRL	$0, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$0, R15, X2, X2
	MOVBLZX	11(SI), R14
	MOVL	R10, R11
	SHRL	$1, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$1, R15, X2, X2
	MOVBLZX	12(SI), R14
	MOVL	R10, R11
	SHRL	$2, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$2, R15, X2, X2
	MOVBLZX	13(SI), R14
	MOVL	R10, R11
	SHRL	$3, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$3, R15, X2, X2
	MOVBLZX	14(SI), R14
	MOVL	R10, R11
	SHRL	$4, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$0, R15, X5, X5
	MOVBLZX	15(SI), R14
	MOVL	R10, R11
	SHRL	$5, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$1, R15, X5, X5
	MOVBLZX	16(SI), R14
	MOVL	R10, R11
	SHRL	$6, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$2, R15, X5, X5
	MOVBLZX	17(SI), R14
	MOVL	R10, R11
	SHRL	$7, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$3, R15, X5, X5
	VINSERTI128	$1, X5, Y2, Y2
	MOVL	78(SI), R9
	VMOVD	R9, X4
	VPBROADCASTD	X4, Y4
	VPSHUFB	Y11, Y4, Y4
	VPAND	Y12, Y4, Y4
	VPCMPEQB	Y12, Y4, Y4
	VPOR	Y13, Y4, Y4
	VMOVDQU	36(DX), Y3
	VPSIGNB	Y4, Y3, Y3
	VPMADDUBSW	Y3, Y2, Y5
	VPMADDWD	Y10, Y5, Y5
	MOVBLZX	106(SI), R8
	SHRL	$4, R8
	LEAL	1(R8)(R8*1), R8
	VMOVD	R8, X6
	VPBROADCASTD	X6, Y6
	VPMULLD	Y6, Y5, Y5
	VPADDD	Y5, Y1, Y1
	MOVBLZX	68(SI), R10
	MOVBLZX	18(SI), R14
	MOVL	R10, R11
	SHRL	$0, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$0, R15, X2, X2
	MOVBLZX	19(SI), R14
	MOVL	R10, R11
	SHRL	$1, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$1, R15, X2, X2
	MOVBLZX	20(SI), R14
	MOVL	R10, R11
	SHRL	$2, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$2, R15, X2, X2
	MOVBLZX	21(SI), R14
	MOVL	R10, R11
	SHRL	$3, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$3, R15, X2, X2
	MOVBLZX	22(SI), R14
	MOVL	R10, R11
	SHRL	$4, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$0, R15, X5, X5
	MOVBLZX	23(SI), R14
	MOVL	R10, R11
	SHRL	$5, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$1, R15, X5, X5
	MOVBLZX	24(SI), R14
	MOVL	R10, R11
	SHRL	$6, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$2, R15, X5, X5
	MOVBLZX	25(SI), R14
	MOVL	R10, R11
	SHRL	$7, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$3, R15, X5, X5
	VINSERTI128	$1, X5, Y2, Y2
	MOVL	82(SI), R9
	VMOVD	R9, X4
	VPBROADCASTD	X4, Y4
	VPSHUFB	Y11, Y4, Y4
	VPAND	Y12, Y4, Y4
	VPCMPEQB	Y12, Y4, Y4
	VPOR	Y13, Y4, Y4
	VMOVDQU	68(DX), Y3
	VPSIGNB	Y4, Y3, Y3
	VPMADDUBSW	Y3, Y2, Y5
	VPMADDWD	Y10, Y5, Y5
	MOVBLZX	107(SI), R8
	ANDL	$0xf, R8
	LEAL	1(R8)(R8*1), R8
	VMOVD	R8, X6
	VPBROADCASTD	X6, Y6
	VPMULLD	Y6, Y5, Y5
	VPADDD	Y5, Y1, Y1
	MOVBLZX	69(SI), R10
	MOVBLZX	26(SI), R14
	MOVL	R10, R11
	SHRL	$0, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$0, R15, X2, X2
	MOVBLZX	27(SI), R14
	MOVL	R10, R11
	SHRL	$1, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$1, R15, X2, X2
	MOVBLZX	28(SI), R14
	MOVL	R10, R11
	SHRL	$2, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$2, R15, X2, X2
	MOVBLZX	29(SI), R14
	MOVL	R10, R11
	SHRL	$3, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$3, R15, X2, X2
	MOVBLZX	30(SI), R14
	MOVL	R10, R11
	SHRL	$4, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$0, R15, X5, X5
	MOVBLZX	31(SI), R14
	MOVL	R10, R11
	SHRL	$5, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$1, R15, X5, X5
	MOVBLZX	32(SI), R14
	MOVL	R10, R11
	SHRL	$6, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$2, R15, X5, X5
	MOVBLZX	33(SI), R14
	MOVL	R10, R11
	SHRL	$7, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$3, R15, X5, X5
	VINSERTI128	$1, X5, Y2, Y2
	MOVL	86(SI), R9
	VMOVD	R9, X4
	VPBROADCASTD	X4, Y4
	VPSHUFB	Y11, Y4, Y4
	VPAND	Y12, Y4, Y4
	VPCMPEQB	Y12, Y4, Y4
	VPOR	Y13, Y4, Y4
	VMOVDQU	100(DX), Y3
	VPSIGNB	Y4, Y3, Y3
	VPMADDUBSW	Y3, Y2, Y5
	VPMADDWD	Y10, Y5, Y5
	MOVBLZX	107(SI), R8
	SHRL	$4, R8
	LEAL	1(R8)(R8*1), R8
	VMOVD	R8, X6
	VPBROADCASTD	X6, Y6
	VPMULLD	Y6, Y5, Y5
	VPADDD	Y5, Y1, Y1
	MOVBLZX	70(SI), R10
	MOVBLZX	34(SI), R14
	MOVL	R10, R11
	SHRL	$0, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$0, R15, X2, X2
	MOVBLZX	35(SI), R14
	MOVL	R10, R11
	SHRL	$1, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$1, R15, X2, X2
	MOVBLZX	36(SI), R14
	MOVL	R10, R11
	SHRL	$2, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$2, R15, X2, X2
	MOVBLZX	37(SI), R14
	MOVL	R10, R11
	SHRL	$3, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$3, R15, X2, X2
	MOVBLZX	38(SI), R14
	MOVL	R10, R11
	SHRL	$4, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$0, R15, X5, X5
	MOVBLZX	39(SI), R14
	MOVL	R10, R11
	SHRL	$5, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$1, R15, X5, X5
	MOVBLZX	40(SI), R14
	MOVL	R10, R11
	SHRL	$6, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$2, R15, X5, X5
	MOVBLZX	41(SI), R14
	MOVL	R10, R11
	SHRL	$7, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$3, R15, X5, X5
	VINSERTI128	$1, X5, Y2, Y2
	MOVL	90(SI), R9
	VMOVD	R9, X4
	VPBROADCASTD	X4, Y4
	VPSHUFB	Y11, Y4, Y4
	VPAND	Y12, Y4, Y4
	VPCMPEQB	Y12, Y4, Y4
	VPOR	Y13, Y4, Y4
	VMOVDQU	132(DX), Y3
	VPSIGNB	Y4, Y3, Y3
	VPMADDUBSW	Y3, Y2, Y5
	VPMADDWD	Y10, Y5, Y5
	MOVBLZX	108(SI), R8
	ANDL	$0xf, R8
	LEAL	1(R8)(R8*1), R8
	VMOVD	R8, X6
	VPBROADCASTD	X6, Y6
	VPMULLD	Y6, Y5, Y5
	VPADDD	Y5, Y1, Y1
	MOVBLZX	71(SI), R10
	MOVBLZX	42(SI), R14
	MOVL	R10, R11
	SHRL	$0, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$0, R15, X2, X2
	MOVBLZX	43(SI), R14
	MOVL	R10, R11
	SHRL	$1, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$1, R15, X2, X2
	MOVBLZX	44(SI), R14
	MOVL	R10, R11
	SHRL	$2, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$2, R15, X2, X2
	MOVBLZX	45(SI), R14
	MOVL	R10, R11
	SHRL	$3, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$3, R15, X2, X2
	MOVBLZX	46(SI), R14
	MOVL	R10, R11
	SHRL	$4, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$0, R15, X5, X5
	MOVBLZX	47(SI), R14
	MOVL	R10, R11
	SHRL	$5, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$1, R15, X5, X5
	MOVBLZX	48(SI), R14
	MOVL	R10, R11
	SHRL	$6, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$2, R15, X5, X5
	MOVBLZX	49(SI), R14
	MOVL	R10, R11
	SHRL	$7, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$3, R15, X5, X5
	VINSERTI128	$1, X5, Y2, Y2
	MOVL	94(SI), R9
	VMOVD	R9, X4
	VPBROADCASTD	X4, Y4
	VPSHUFB	Y11, Y4, Y4
	VPAND	Y12, Y4, Y4
	VPCMPEQB	Y12, Y4, Y4
	VPOR	Y13, Y4, Y4
	VMOVDQU	164(DX), Y3
	VPSIGNB	Y4, Y3, Y3
	VPMADDUBSW	Y3, Y2, Y5
	VPMADDWD	Y10, Y5, Y5
	MOVBLZX	108(SI), R8
	SHRL	$4, R8
	LEAL	1(R8)(R8*1), R8
	VMOVD	R8, X6
	VPBROADCASTD	X6, Y6
	VPMULLD	Y6, Y5, Y5
	VPADDD	Y5, Y1, Y1
	MOVBLZX	72(SI), R10
	MOVBLZX	50(SI), R14
	MOVL	R10, R11
	SHRL	$0, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$0, R15, X2, X2
	MOVBLZX	51(SI), R14
	MOVL	R10, R11
	SHRL	$1, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$1, R15, X2, X2
	MOVBLZX	52(SI), R14
	MOVL	R10, R11
	SHRL	$2, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$2, R15, X2, X2
	MOVBLZX	53(SI), R14
	MOVL	R10, R11
	SHRL	$3, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$3, R15, X2, X2
	MOVBLZX	54(SI), R14
	MOVL	R10, R11
	SHRL	$4, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$0, R15, X5, X5
	MOVBLZX	55(SI), R14
	MOVL	R10, R11
	SHRL	$5, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$1, R15, X5, X5
	MOVBLZX	56(SI), R14
	MOVL	R10, R11
	SHRL	$6, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$2, R15, X5, X5
	MOVBLZX	57(SI), R14
	MOVL	R10, R11
	SHRL	$7, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$3, R15, X5, X5
	VINSERTI128	$1, X5, Y2, Y2
	MOVL	98(SI), R9
	VMOVD	R9, X4
	VPBROADCASTD	X4, Y4
	VPSHUFB	Y11, Y4, Y4
	VPAND	Y12, Y4, Y4
	VPCMPEQB	Y12, Y4, Y4
	VPOR	Y13, Y4, Y4
	VMOVDQU	196(DX), Y3
	VPSIGNB	Y4, Y3, Y3
	VPMADDUBSW	Y3, Y2, Y5
	VPMADDWD	Y10, Y5, Y5
	MOVBLZX	109(SI), R8
	ANDL	$0xf, R8
	LEAL	1(R8)(R8*1), R8
	VMOVD	R8, X6
	VPBROADCASTD	X6, Y6
	VPMULLD	Y6, Y5, Y5
	VPADDD	Y5, Y1, Y1
	MOVBLZX	73(SI), R10
	MOVBLZX	58(SI), R14
	MOVL	R10, R11
	SHRL	$0, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$0, R15, X2, X2
	MOVBLZX	59(SI), R14
	MOVL	R10, R11
	SHRL	$1, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$1, R15, X2, X2
	MOVBLZX	60(SI), R14
	MOVL	R10, R11
	SHRL	$2, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$2, R15, X2, X2
	MOVBLZX	61(SI), R14
	MOVL	R10, R11
	SHRL	$3, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$3, R15, X2, X2
	MOVBLZX	62(SI), R14
	MOVL	R10, R11
	SHRL	$4, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$0, R15, X5, X5
	MOVBLZX	63(SI), R14
	MOVL	R10, R11
	SHRL	$5, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$1, R15, X5, X5
	MOVBLZX	64(SI), R14
	MOVL	R10, R11
	SHRL	$6, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$2, R15, X5, X5
	MOVBLZX	65(SI), R14
	MOVL	R10, R11
	SHRL	$7, R11
	ANDL	$1, R11
	SHLL	$8, R11
	ORL	R11, R14
	MOVL	(R12)(R14*4), R15
	VPINSRD	$3, R15, X5, X5
	VINSERTI128	$1, X5, Y2, Y2
	MOVL	102(SI), R9
	VMOVD	R9, X4
	VPBROADCASTD	X4, Y4
	VPSHUFB	Y11, Y4, Y4
	VPAND	Y12, Y4, Y4
	VPCMPEQB	Y12, Y4, Y4
	VPOR	Y13, Y4, Y4
	VMOVDQU	228(DX), Y3
	VPSIGNB	Y4, Y3, Y3
	VPMADDUBSW	Y3, Y2, Y5
	VPMADDWD	Y10, Y5, Y5
	MOVBLZX	109(SI), R8
	SHRL	$4, R8
	LEAL	1(R8)(R8*1), R8
	VMOVD	R8, X6
	VPBROADCASTD	X6, Y6
	VPMULLD	Y6, Y5, Y5
	VPADDD	Y5, Y1, Y1
	VCVTDQ2PS	Y1, Y1
	MOVWLZX	0(SI), R8
	VMOVD	R8, X6
	VCVTPH2PS	X6, X6
	VMOVSS	0(DX), X7
	VMULSS	X7, X6, X6
	VBROADCASTSS	X6, Y6
	VFMADD231PS	Y1, Y6, Y0
	ADDQ	$110, SI
	ADDQ	$292, DX
	DECQ	CX
	JNZ	i3sblk
i3sreduce:
	VEXTRACTF128	$1, Y0, X2
	VADDPS	X2, X0, X0
	VHADDPS	X0, X0, X0
	VHADDPS	X0, X0, X0
	VMOVSS	X0, (DI)
	VZEROUPPER
	RET
i3soob:
	VZEROUPPER
	JMP	ovr_oob

DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+0(SB)/8, $0x404041404040404
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+8(SB)/8, $0x4040c0c04040424
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+16(SB)/8, $0x4040c3e04040c1c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+24(SB)/8, $0x404141404041404
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+32(SB)/8, $0x404241404041c0c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+40(SB)/8, $0x4043e2c04043e1c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+48(SB)/8, $0x40c041c040c040c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+56(SB)/8, $0x40c0c14040c0c04
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+64(SB)/8, $0x40c142c040c140c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+72(SB)/8, $0x40c1c14040c1c04
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+80(SB)/8, $0x40c2c24040c240c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+88(SB)/8, $0x4140404040c3e04
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+96(SB)/8, $0x414042404140414
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+104(SB)/8, $0x414140404140c0c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+112(SB)/8, $0x4141c0c04141414
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+120(SB)/8, $0x4141c3e04141c1c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+128(SB)/8, $0x4142c3e04142c0c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+136(SB)/8, $0x41c040c04143e2c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+144(SB)/8, $0x41c0c04041c043e
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+152(SB)/8, $0x41c142c041c0c14
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+160(SB)/8, $0x4240c1c041c3e04
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+168(SB)/8, $0x424242404241c3e
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+176(SB)/8, $0x4243e1c04242c3e
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+184(SB)/8, $0x42c040c04243e2c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+192(SB)/8, $0x42c1c14042c043e
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+200(SB)/8, $0x4341c2c042c2c14
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+208(SB)/8, $0x43e0c0404343424
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+216(SB)/8, $0x43e0c34043e0c24
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+224(SB)/8, $0x43e340c043e241c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+232(SB)/8, $0xc04041c0c04040c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+240(SB)/8, $0xc040c140c040c04
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+248(SB)/8, $0xc04141c0c04140c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+256(SB)/8, $0xc041c140c041c04
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+264(SB)/8, $0xc04243e0c041c24
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+272(SB)/8, $0xc0c04040c042c04
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+280(SB)/8, $0xc0c0c0c0c0c0414
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+288(SB)/8, $0xc0c14140c0c1404
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+296(SB)/8, $0xc14041c0c14040c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+304(SB)/8, $0xc140c140c140c04
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+312(SB)/8, $0xc141c040c14140c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+320(SB)/8, $0xc1c04040c143e14
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+328(SB)/8, $0xc1c14040c1c0414
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+336(SB)/8, $0xc1c24340c1c1c0c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+344(SB)/8, $0xc24040c0c1c3434
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+352(SB)/8, $0xc242c040c24042c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+360(SB)/8, $0xc2c14240c2c1404
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+368(SB)/8, $0xc2c3e0c0c2c2434
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+376(SB)/8, $0xc3e14140c34042c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+384(SB)/8, $0x140404040c3e2404
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+392(SB)/8, $0x14040c0c14040414
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+400(SB)/8, $0x1404140414040c1c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+408(SB)/8, $0x1404143414041414
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+416(SB)/8, $0x1404241414041c0c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+424(SB)/8, $0x140c041c140c040c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+432(SB)/8, $0x140c0c04140c042c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+440(SB)/8, $0x140c140c140c0c14
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+448(SB)/8, $0x140c341c140c1c04
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+456(SB)/8, $0x140c3e04140c343e
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+464(SB)/8, $0x1414041414140404
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+472(SB)/8, $0x14140c3e14140c0c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+480(SB)/8, $0x1414141414141404
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+488(SB)/8, $0x1414240414141c3e
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+496(SB)/8, $0x141c040c14142c2c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+504(SB)/8, $0x141c0c24141c0c04
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+512(SB)/8, $0x141c3e24141c3e04
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+520(SB)/8, $0x14242c1c14241c2c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+528(SB)/8, $0x142c143e142c041c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+536(SB)/8, $0x142c3e24142c240c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+544(SB)/8, $0x143e041c143e040c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+552(SB)/8, $0x143e242c143e0c34
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+560(SB)/8, $0x1c040c041c04040c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+568(SB)/8, $0x1c04140c1c040c14
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+576(SB)/8, $0x1c042c041c04141c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+584(SB)/8, $0x1c043e141c04342c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+592(SB)/8, $0x1c0c04141c0c0404
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+600(SB)/8, $0x1c0c1c0c1c0c1404
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+608(SB)/8, $0x1c0c24341c0c2424
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+616(SB)/8, $0x1c14041c1c14040c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+624(SB)/8, $0x1c14142c1c140c04
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+632(SB)/8, $0x1c143e141c142c14
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+640(SB)/8, $0x1c1c1c1c1c1c0c0c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+648(SB)/8, $0x1c24243e1c241c04
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+656(SB)/8, $0x1c2c04041c243e14
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+664(SB)/8, $0x1c2c14141c2c0434
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+672(SB)/8, $0x1c340c241c2c2c2c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+680(SB)/8, $0x1c34341c1c341c34
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+688(SB)/8, $0x1c3e34041c3e1c1c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+696(SB)/8, $0x24040c3e24040424
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+704(SB)/8, $0x24041c3e24041c2c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+712(SB)/8, $0x24042c3e24042c1c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+720(SB)/8, $0x24141404240c3e24
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+728(SB)/8, $0x2414240424141c3e
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+736(SB)/8, $0x2414343424143404
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+744(SB)/8, $0x241c242c241c043e
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+752(SB)/8, $0x24242c0c24240424
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+760(SB)/8, $0x242c142c24243424
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+768(SB)/8, $0x242c3e04242c241c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+776(SB)/8, $0x243e0c04243e042c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+784(SB)/8, $0x243e1c04243e0c14
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+792(SB)/8, $0x2c04240c2c040c14
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+800(SB)/8, $0x2c0c04042c043e04
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+808(SB)/8, $0x2c0c14342c0c0434
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+816(SB)/8, $0x2c140c242c0c2c2c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+824(SB)/8, $0x2c143e142c141c14
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+832(SB)/8, $0x2c1c2c1c2c1c0414
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+840(SB)/8, $0x2c24141c2c240c04
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+848(SB)/8, $0x2c243e142c24143e
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+856(SB)/8, $0x2c2c1c0c2c2c0414
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+864(SB)/8, $0x2c3e14242c342c04
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+872(SB)/8, $0x340414242c3e2414
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+880(SB)/8, $0x3404243434042424
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+888(SB)/8, $0x340c140c34043424
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+896(SB)/8, $0x34140c3e340c340c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+904(SB)/8, $0x341c1c0434143424
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+912(SB)/8, $0x34242424341c1c34
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+920(SB)/8, $0x342c2c14342c042c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+928(SB)/8, $0x343e041c34341c1c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+936(SB)/8, $0x3e04041c343e140c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+944(SB)/8, $0x3e04043e3e04042c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+952(SB)/8, $0x3e041c143e040c04
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+960(SB)/8, $0x3e0c14343e042c14
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+968(SB)/8, $0x3e140c143e0c2404
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+976(SB)/8, $0x3e142c143e14242c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+984(SB)/8, $0x3e1c0c2c3e1c0404
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+992(SB)/8, $0x3e1c34043e1c1c1c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1000(SB)/8, $0x3e24240c3e24140c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1008(SB)/8, $0x3e2c04143e2c0404
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1016(SB)/8, $0x3e341c043e2c1424
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1024(SB)/8, $0x101010101010101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1032(SB)/8, $0xff010101010101ff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1040(SB)/8, $0xff0101010101ff01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1048(SB)/8, $0x10101010101ffff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1056(SB)/8, $0xff01010101ff0101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1064(SB)/8, $0x101010101ff01ff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1072(SB)/8, $0x101010101ffff01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1080(SB)/8, $0xff01010101ffffff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1088(SB)/8, $0xff010101ff010101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1096(SB)/8, $0x1010101ff0101ff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1104(SB)/8, $0x1010101ff01ff01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1112(SB)/8, $0xff010101ff01ffff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1120(SB)/8, $0x1010101ffff0101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1128(SB)/8, $0xff010101ffff01ff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1136(SB)/8, $0xff010101ffffff01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1144(SB)/8, $0x1010101ffffffff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1152(SB)/8, $0xff0101ff01010101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1160(SB)/8, $0x10101ff010101ff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1168(SB)/8, $0x10101ff0101ff01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1176(SB)/8, $0xff0101ff0101ffff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1184(SB)/8, $0x10101ff01ff0101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1192(SB)/8, $0xff0101ff01ff01ff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1200(SB)/8, $0xff0101ff01ffff01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1208(SB)/8, $0x10101ff01ffffff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1216(SB)/8, $0x10101ffff010101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1224(SB)/8, $0xff0101ffff0101ff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1232(SB)/8, $0xff0101ffff01ff01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1240(SB)/8, $0x10101ffff01ffff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1248(SB)/8, $0xff0101ffffff0101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1256(SB)/8, $0x10101ffffff01ff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1264(SB)/8, $0x10101ffffffff01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1272(SB)/8, $0xff0101ffffffffff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1280(SB)/8, $0xff01ff0101010101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1288(SB)/8, $0x101ff01010101ff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1296(SB)/8, $0x101ff010101ff01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1304(SB)/8, $0xff01ff010101ffff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1312(SB)/8, $0x101ff0101ff0101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1320(SB)/8, $0xff01ff0101ff01ff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1328(SB)/8, $0xff01ff0101ffff01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1336(SB)/8, $0x101ff0101ffffff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1344(SB)/8, $0x101ff01ff010101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1352(SB)/8, $0xff01ff01ff0101ff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1360(SB)/8, $0xff01ff01ff01ff01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1368(SB)/8, $0x101ff01ff01ffff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1376(SB)/8, $0xff01ff01ffff0101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1384(SB)/8, $0x101ff01ffff01ff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1392(SB)/8, $0x101ff01ffffff01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1400(SB)/8, $0xff01ff01ffffffff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1408(SB)/8, $0x101ffff01010101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1416(SB)/8, $0xff01ffff010101ff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1424(SB)/8, $0xff01ffff0101ff01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1432(SB)/8, $0x101ffff0101ffff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1440(SB)/8, $0xff01ffff01ff0101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1448(SB)/8, $0x101ffff01ff01ff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1456(SB)/8, $0x101ffff01ffff01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1464(SB)/8, $0xff01ffff01ffffff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1472(SB)/8, $0xff01ffffff010101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1480(SB)/8, $0x101ffffff0101ff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1488(SB)/8, $0x101ffffff01ff01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1496(SB)/8, $0xff01ffffff01ffff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1504(SB)/8, $0x101ffffffff0101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1512(SB)/8, $0xff01ffffffff01ff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1520(SB)/8, $0xff01ffffffffff01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1528(SB)/8, $0x101ffffffffffff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1536(SB)/8, $0xffff010101010101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1544(SB)/8, $0x1ff0101010101ff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1552(SB)/8, $0x1ff01010101ff01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1560(SB)/8, $0xffff01010101ffff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1568(SB)/8, $0x1ff010101ff0101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1576(SB)/8, $0xffff010101ff01ff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1584(SB)/8, $0xffff010101ffff01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1592(SB)/8, $0x1ff010101ffffff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1600(SB)/8, $0x1ff0101ff010101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1608(SB)/8, $0xffff0101ff0101ff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1616(SB)/8, $0xffff0101ff01ff01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1624(SB)/8, $0x1ff0101ff01ffff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1632(SB)/8, $0xffff0101ffff0101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1640(SB)/8, $0x1ff0101ffff01ff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1648(SB)/8, $0x1ff0101ffffff01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1656(SB)/8, $0xffff0101ffffffff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1664(SB)/8, $0x1ff01ff01010101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1672(SB)/8, $0xffff01ff010101ff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1680(SB)/8, $0xffff01ff0101ff01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1688(SB)/8, $0x1ff01ff0101ffff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1696(SB)/8, $0xffff01ff01ff0101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1704(SB)/8, $0x1ff01ff01ff01ff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1712(SB)/8, $0x1ff01ff01ffff01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1720(SB)/8, $0xffff01ff01ffffff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1728(SB)/8, $0xffff01ffff010101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1736(SB)/8, $0x1ff01ffff0101ff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1744(SB)/8, $0x1ff01ffff01ff01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1752(SB)/8, $0xffff01ffff01ffff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1760(SB)/8, $0x1ff01ffffff0101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1768(SB)/8, $0xffff01ffffff01ff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1776(SB)/8, $0xffff01ffffffff01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1784(SB)/8, $0x1ff01ffffffffff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1792(SB)/8, $0x1ffff0101010101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1800(SB)/8, $0xffffff01010101ff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1808(SB)/8, $0xffffff010101ff01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1816(SB)/8, $0x1ffff010101ffff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1824(SB)/8, $0xffffff0101ff0101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1832(SB)/8, $0x1ffff0101ff01ff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1840(SB)/8, $0x1ffff0101ffff01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1848(SB)/8, $0xffffff0101ffffff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1856(SB)/8, $0xffffff01ff010101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1864(SB)/8, $0x1ffff01ff0101ff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1872(SB)/8, $0x1ffff01ff01ff01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1880(SB)/8, $0xffffff01ff01ffff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1888(SB)/8, $0x1ffff01ffff0101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1896(SB)/8, $0xffffff01ffff01ff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1904(SB)/8, $0xffffff01ffffff01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1912(SB)/8, $0x1ffff01ffffffff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1920(SB)/8, $0xffffffff01010101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1928(SB)/8, $0x1ffffff010101ff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1936(SB)/8, $0x1ffffff0101ff01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1944(SB)/8, $0xffffffff0101ffff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1952(SB)/8, $0x1ffffff01ff0101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1960(SB)/8, $0xffffffff01ff01ff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1968(SB)/8, $0xffffffff01ffff01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1976(SB)/8, $0x1ffffff01ffffff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1984(SB)/8, $0x1ffffffff010101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+1992(SB)/8, $0xffffffffff0101ff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+2000(SB)/8, $0xffffffffff01ff01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+2008(SB)/8, $0x1ffffffff01ffff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+2016(SB)/8, $0xffffffffffff0101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+2024(SB)/8, $0x1ffffffffff01ff
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+2032(SB)/8, $0x1ffffffffffff01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b+2040(SB)/8, $0xffffffffffffffff
GLOBL ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2048_0dff0a225fac788b(SB), RODATA|NOPTR, $2048
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+0(SB)/8, $0x101010301010101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+8(SB)/8, $0x101010b01010105
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+16(SB)/8, $0x10103010101010f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+24(SB)/8, $0x101030501010303
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+32(SB)/8, $0x101030d01010309
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+40(SB)/8, $0x101050301010501
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+48(SB)/8, $0x10107070101050b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+56(SB)/8, $0x101090501010901
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+64(SB)/8, $0x101090f0101090b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+72(SB)/8, $0x1010b0701010b03
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+80(SB)/8, $0x1010d0501010d01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+88(SB)/8, $0x1010f0901010f03
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+96(SB)/8, $0x103010101010f0f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+104(SB)/8, $0x103010501030103
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+112(SB)/8, $0x103030101030109
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+120(SB)/8, $0x103030b01030303
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+128(SB)/8, $0x103050701030501
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+136(SB)/8, $0x10307030103050f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+144(SB)/8, $0x10309090103070b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+152(SB)/8, $0x1030d0b01030d03
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+160(SB)/8, $0x105010101030f05
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+168(SB)/8, $0x105010b01050103
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+176(SB)/8, $0x10503010105010f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+184(SB)/8, $0x105030d01050307
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+192(SB)/8, $0x105050b01050503
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+200(SB)/8, $0x105070901050701
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+208(SB)/8, $0x105090b01050905
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+216(SB)/8, $0x1050b030105090f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+224(SB)/8, $0x1050f0101050b07
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+232(SB)/8, $0x107010701050f07
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+240(SB)/8, $0x107030b01070303
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+248(SB)/8, $0x107050501070501
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+256(SB)/8, $0x107070701070703
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+264(SB)/8, $0x10709090107070d
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+272(SB)/8, $0x1070b0501070b01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+280(SB)/8, $0x1070f0301070d0f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+288(SB)/8, $0x109010101070f0b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+296(SB)/8, $0x109030f01090307
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+304(SB)/8, $0x109050901090503
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+312(SB)/8, $0x109090101090705
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+320(SB)/8, $0x1090b0301090907
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+328(SB)/8, $0x10b010501090f01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+336(SB)/8, $0x10b0501010b0109
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+344(SB)/8, $0x10b050d010b0505
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+352(SB)/8, $0x10b0903010b0707
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+360(SB)/8, $0x10b090f010b090b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+368(SB)/8, $0x10b0f07010b0d0d
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+376(SB)/8, $0x10d0303010d010d
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+384(SB)/8, $0x10d0703010d0307
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+392(SB)/8, $0x10d0f03010d0b05
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+400(SB)/8, $0x10f0105010f0101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+408(SB)/8, $0x10f0501010f0109
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+416(SB)/8, $0x10f050d010f0505
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+424(SB)/8, $0x10f0b01010f0707
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+432(SB)/8, $0x3010101010f0b09
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+440(SB)/8, $0x301010503010103
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+448(SB)/8, $0x301030103010109
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+456(SB)/8, $0x301030703010303
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+464(SB)/8, $0x301030f0301030b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+472(SB)/8, $0x301050503010501
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+480(SB)/8, $0x301070903010703
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+488(SB)/8, $0x3010b090301070d
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+496(SB)/8, $0x3010d0303010b0d
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+504(SB)/8, $0x303010103010f05
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+512(SB)/8, $0x303010703030103
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+520(SB)/8, $0x30303010303010d
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+528(SB)/8, $0x303050303030309
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+536(SB)/8, $0x303070703030701
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+544(SB)/8, $0x3030b0103030903
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+552(SB)/8, $0x3030f0103030b05
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+560(SB)/8, $0x305010103030f0d
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+568(SB)/8, $0x305030b03050305
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+576(SB)/8, $0x30505010305030f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+584(SB)/8, $0x305070503050509
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+592(SB)/8, $0x305090703050901
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+600(SB)/8, $0x3050d0103050b0b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+608(SB)/8, $0x307010303050f05
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+616(SB)/8, $0x307010f03070109
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+624(SB)/8, $0x307030703070301
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+632(SB)/8, $0x307050f03070503
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+640(SB)/8, $0x307070903070701
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+648(SB)/8, $0x3070d0503070903
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+656(SB)/8, $0x309010703070f01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+664(SB)/8, $0x30903050309010b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+672(SB)/8, $0x309070303090309
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+680(SB)/8, $0x309090503090707
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+688(SB)/8, $0x3090b010309090d
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+696(SB)/8, $0x30b010303090b09
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+704(SB)/8, $0x30b0307030b0301
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+712(SB)/8, $0x30b0701030b0503
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+720(SB)/8, $0x30b0b03030b0705
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+728(SB)/8, $0x30d0509030d0501
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+736(SB)/8, $0x30d0909030d050f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+744(SB)/8, $0x30f0103030d090d
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+752(SB)/8, $0x30f0301030f0107
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+760(SB)/8, $0x30f0503030f0305
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+768(SB)/8, $0x30f0903030f070b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+776(SB)/8, $0x30f0f01030f0d05
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+784(SB)/8, $0x501010305010101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+792(SB)/8, $0x501010b05010107
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+800(SB)/8, $0x50103010501010f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+808(SB)/8, $0x501030905010305
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+816(SB)/8, $0x50105030501030d
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+824(SB)/8, $0x501050f05010507
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+832(SB)/8, $0x501070505010701
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+840(SB)/8, $0x501090705010903
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+848(SB)/8, $0x5010b010501090b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+856(SB)/8, $0x5010d0f05010b05
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+864(SB)/8, $0x5010f0705010f01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+872(SB)/8, $0x503010105010f0b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+880(SB)/8, $0x503030105030105
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+888(SB)/8, $0x503030f05030307
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+896(SB)/8, $0x503050b05030505
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+904(SB)/8, $0x503070905030703
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+912(SB)/8, $0x5030b0305030905
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+920(SB)/8, $0x505010905050103
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+928(SB)/8, $0x50505030505010f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+936(SB)/8, $0x505070105050507
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+944(SB)/8, $0x50509030505070f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+952(SB)/8, $0x5050b0f05050b07
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+960(SB)/8, $0x5050f0905050f03
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+968(SB)/8, $0x507010505070101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+976(SB)/8, $0x50703030507010b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+984(SB)/8, $0x507050905070505
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+992(SB)/8, $0x507070705070703
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1000(SB)/8, $0x5070b0105070905
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1008(SB)/8, $0x509010305070d0d
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1016(SB)/8, $0x50905010509010f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1024(SB)/8, $0x509070505090507
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1032(SB)/8, $0x50909030509070b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1040(SB)/8, $0x5090f0b05090f05
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1048(SB)/8, $0x50b0303050b0109
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1056(SB)/8, $0x50b070f050b0505
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1064(SB)/8, $0x50b0b07050b0901
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1072(SB)/8, $0x50d0101050b0f01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1080(SB)/8, $0x50d010f050d0105
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1088(SB)/8, $0x50d0b0b050d0503
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1096(SB)/8, $0x50f010b050d0d03
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1104(SB)/8, $0x50f050d050f0303
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1112(SB)/8, $0x50f0907050f0701
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1120(SB)/8, $0x7010105050f0b01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1128(SB)/8, $0x701030707010303
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1136(SB)/8, $0x701030f0701030b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1144(SB)/8, $0x701070307010505
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1152(SB)/8, $0x701070b07010707
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1160(SB)/8, $0x701090907010905
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1168(SB)/8, $0x7010b030701090f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1176(SB)/8, $0x7010f0307010d07
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1184(SB)/8, $0x703010707030103
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1192(SB)/8, $0x70303090703010b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1200(SB)/8, $0x703050707030503
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1208(SB)/8, $0x7030d0107030901
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1216(SB)/8, $0x7030f0d07030f05
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1224(SB)/8, $0x705030507050101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1232(SB)/8, $0x705070507050501
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1240(SB)/8, $0x7050b0107050709
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1248(SB)/8, $0x707030107070103
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1256(SB)/8, $0x707050307070309
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1264(SB)/8, $0x707050f07070507
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1272(SB)/8, $0x707090307070701
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1280(SB)/8, $0x707090f07070907
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1288(SB)/8, $0x7070f0707070b0b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1296(SB)/8, $0x709030307090107
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1304(SB)/8, $0x70905050709030d
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1312(SB)/8, $0x7090b0507090703
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1320(SB)/8, $0x7090d0907090d01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1328(SB)/8, $0x70b0301070b0103
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1336(SB)/8, $0x70b050b070b0305
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1344(SB)/8, $0x70b0909070b0705
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1352(SB)/8, $0x70b0f07070b0b0d
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1360(SB)/8, $0x70d0903070d030d
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1368(SB)/8, $0x70f0107070f0103
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1376(SB)/8, $0x70f0505070f0501
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1384(SB)/8, $0x9010101070f070b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1392(SB)/8, $0x901030509010109
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1400(SB)/8, $0x901050909010501
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1408(SB)/8, $0x90107050901050f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1416(SB)/8, $0x9010b0109010903
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1424(SB)/8, $0x903010509010f01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1432(SB)/8, $0x90303030903010f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1440(SB)/8, $0x903050509030307
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1448(SB)/8, $0x903070b09030701
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1456(SB)/8, $0x9030b0309030907
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1464(SB)/8, $0x905010309030b0b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1472(SB)/8, $0x905030109050107
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1480(SB)/8, $0x90505030905030b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1488(SB)/8, $0x905090109050707
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1496(SB)/8, $0x9050d0509050b0f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1504(SB)/8, $0x907010909050f01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1512(SB)/8, $0x907030709070303
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1520(SB)/8, $0x907050509070501
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1528(SB)/8, $0x907070b09070703
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1536(SB)/8, $0x909010509090101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1544(SB)/8, $0x909070f09090509
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1552(SB)/8, $0x9090f0309090901
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1560(SB)/8, $0x90b010f090b010b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1568(SB)/8, $0x90b0d05090b0503
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1576(SB)/8, $0x90d0709090d0307
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1584(SB)/8, $0x90f0301090d0d01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1592(SB)/8, $0x90f0701090f030b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1600(SB)/8, $0x90f0b03090f0907
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1608(SB)/8, $0xb0103010b010105
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1616(SB)/8, $0xb0105050b010309
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1624(SB)/8, $0xb0109090b010901
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1632(SB)/8, $0xb010b050b01090f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1640(SB)/8, $0xb010f090b010d0d
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1648(SB)/8, $0xb0301070b030103
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1656(SB)/8, $0xb0303050b03010b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1664(SB)/8, $0xb0307050b030503
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1672(SB)/8, $0xb0501010b030f05
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1680(SB)/8, $0xb0505070b050303
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1688(SB)/8, $0xb05070d0b050701
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1696(SB)/8, $0xb0701050b050b07
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1704(SB)/8, $0xb0703010b07010f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1712(SB)/8, $0xb0709090b07050f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1720(SB)/8, $0xb070d0b0b070b03
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1728(SB)/8, $0xb0901030b070f07
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1736(SB)/8, $0xb0905010b090109
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1744(SB)/8, $0xb09090d0b090705
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1752(SB)/8, $0xb0b050d0b0b0305
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1760(SB)/8, $0xb0b0b070b0b0b03
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1768(SB)/8, $0xb0f01050b0d0905
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1776(SB)/8, $0xb0f05050b0f0109
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1784(SB)/8, $0xd0103070d010303
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1792(SB)/8, $0xd0107030d01030b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1800(SB)/8, $0xd010d010d010707
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1808(SB)/8, $0xd0305010d030101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1816(SB)/8, $0xd030d090d03050f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1824(SB)/8, $0xd0507090d050305
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1832(SB)/8, $0xd050b0b0d050905
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1840(SB)/8, $0xd050f010d050d05
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1848(SB)/8, $0xd0703090d070101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1856(SB)/8, $0xd0709010d070503
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1864(SB)/8, $0xd0909070d09050b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1872(SB)/8, $0xd0b01010d090d05
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1880(SB)/8, $0xd0b07090d0b0107
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1888(SB)/8, $0xd0d010b0d0b0d01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1896(SB)/8, $0xd0f03030d0d0901
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1904(SB)/8, $0xf0101010d0f0307
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1912(SB)/8, $0xf01010f0f010109
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1920(SB)/8, $0xf0105050f010501
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1928(SB)/8, $0xf0109010f01070d
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1936(SB)/8, $0xf010d050f010b09
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1944(SB)/8, $0xf0303030f030105
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1952(SB)/8, $0xf0309070f030509
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1960(SB)/8, $0xf0501030f03090b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1968(SB)/8, $0xf0503010f050109
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1976(SB)/8, $0xf0505030f05030d
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1984(SB)/8, $0xf050b030f050701
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+1992(SB)/8, $0xf0707050f070105
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+2000(SB)/8, $0xf070b070f07070b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+2008(SB)/8, $0xf09010b0f090103
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+2016(SB)/8, $0xf0905010f090307
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+2024(SB)/8, $0xf0b05050f090b01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+2032(SB)/8, $0xf0d01050f0b0905
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+2040(SB)/8, $0xf0f01010f0d0703
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+2048(SB)/8, $0x0
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+2056(SB)/8, $0x101010101010101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+2064(SB)/8, $0x202020202020202
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+2072(SB)/8, $0x303030303030303
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+2080(SB)/8, $0x8040201008040201
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48+2088(SB)/8, $0x8040201008040201
GLOBL ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b2096_30a5fc654bffba48(SB), RODATA|NOPTR, $2096
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+0(SB)/8, $0xf0f0f0f0f0f0f0f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+8(SB)/8, $0xf0f0f0f0f0f0f0f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+16(SB)/8, $0xf0f0f0f0f0f0f0f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+24(SB)/8, $0xf0f0f0f0f0f0f0f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+32(SB)/8, $0xf0f0f0f0f0f0f0f0
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+40(SB)/8, $0xf0f0f0f0f0f0f0f0
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+48(SB)/8, $0xf0f0f0f0f0f0f0f0
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+56(SB)/8, $0xf0f0f0f0f0f0f0f0
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+64(SB)/8, $0x1000100010001
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+72(SB)/8, $0x1000100010001
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+80(SB)/8, $0x1000100010001
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+88(SB)/8, $0x1000100010001
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+96(SB)/8, $0x0
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+104(SB)/8, $0x101010101010101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+112(SB)/8, $0x202020202020202
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+120(SB)/8, $0x303030303030303
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+128(SB)/8, $0x7fbfdfeff7fbfdfe
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+136(SB)/8, $0x7fbfdfeff7fbfdfe
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+144(SB)/8, $0x7fbfdfeff7fbfdfe
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+152(SB)/8, $0x7fbfdfeff7fbfdfe
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+160(SB)/8, $0x303030303030303
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+168(SB)/8, $0x303030303030303
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+176(SB)/8, $0x303030303030303
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+184(SB)/8, $0x303030303030303
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+192(SB)/8, $0xc0c0c0c0c0c0c0c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+200(SB)/8, $0xc0c0c0c0c0c0c0c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+208(SB)/8, $0xc0c0c0c0c0c0c0c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+216(SB)/8, $0xc0c0c0c0c0c0c0c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+224(SB)/8, $0x3030303030303030
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+232(SB)/8, $0x3030303030303030
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+240(SB)/8, $0x3030303030303030
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+248(SB)/8, $0x3030303030303030
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+256(SB)/8, $0xc0c0c0c0c0c0c0c0
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+264(SB)/8, $0xc0c0c0c0c0c0c0c0
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+272(SB)/8, $0xc0c0c0c0c0c0c0c0
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+280(SB)/8, $0xc0c0c0c0c0c0c0c0
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+288(SB)/8, $0x100010001000100
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+296(SB)/8, $0x100010001000100
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+304(SB)/8, $0x100010001000100
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+312(SB)/8, $0x100010001000100
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+320(SB)/8, $0x302030203020302
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+328(SB)/8, $0x302030203020302
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+336(SB)/8, $0x302030203020302
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+344(SB)/8, $0x302030203020302
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+352(SB)/8, $0x504050405040504
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+360(SB)/8, $0x504050405040504
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+368(SB)/8, $0x504050405040504
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+376(SB)/8, $0x504050405040504
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+384(SB)/8, $0x706070607060706
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+392(SB)/8, $0x706070607060706
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+400(SB)/8, $0x706070607060706
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+408(SB)/8, $0x706070607060706
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+416(SB)/8, $0x908090809080908
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+424(SB)/8, $0x908090809080908
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+432(SB)/8, $0x908090809080908
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+440(SB)/8, $0x908090809080908
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+448(SB)/8, $0xb0a0b0a0b0a0b0a
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+456(SB)/8, $0xb0a0b0a0b0a0b0a
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+464(SB)/8, $0xb0a0b0a0b0a0b0a
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+472(SB)/8, $0xb0a0b0a0b0a0b0a
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+480(SB)/8, $0xd0c0d0c0d0c0d0c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+488(SB)/8, $0xd0c0d0c0d0c0d0c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+496(SB)/8, $0xd0c0d0c0d0c0d0c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+504(SB)/8, $0xd0c0d0c0d0c0d0c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+512(SB)/8, $0xf0e0f0e0f0e0f0e
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+520(SB)/8, $0xf0e0f0e0f0e0f0e
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+528(SB)/8, $0xf0e0f0e0f0e0f0e
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+536(SB)/8, $0xf0e0f0e0f0e0f0e
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+544(SB)/8, $0x0
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+552(SB)/8, $0x101010101010101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+560(SB)/8, $0x202020202020202
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+568(SB)/8, $0x303030303030303
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+576(SB)/8, $0x404040404040404
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+584(SB)/8, $0x505050505050505
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+592(SB)/8, $0x606060606060606
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+600(SB)/8, $0x707070707070707
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+608(SB)/8, $0x808080808080808
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+616(SB)/8, $0x909090909090909
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+624(SB)/8, $0xa0a0a0a0a0a0a0a
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+632(SB)/8, $0xb0b0b0b0b0b0b0b
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+640(SB)/8, $0xc0c0c0c0c0c0c0c
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+648(SB)/8, $0xd0d0d0d0d0d0d0d
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+656(SB)/8, $0xe0e0e0e0e0e0e0e
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+664(SB)/8, $0xf0f0f0f0f0f0f0f
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+672(SB)/8, $0x101010101010101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+680(SB)/8, $0x101010101010101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+688(SB)/8, $0x101010101010101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+696(SB)/8, $0x101010101010101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+704(SB)/8, $0x202020202020202
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+712(SB)/8, $0x202020202020202
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+720(SB)/8, $0x202020202020202
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+728(SB)/8, $0x202020202020202
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+736(SB)/8, $0x2020202020202020
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+744(SB)/8, $0x2020202020202020
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+752(SB)/8, $0x2020202020202020
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+760(SB)/8, $0x2020202020202020
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+768(SB)/8, $0xf6eaddcfbfad9881
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+776(SB)/8, $0x7159453526190d01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+784(SB)/8, $0xf6eaddcfbfad9881
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+792(SB)/8, $0x7159453526190d01
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+800(SB)/8, $0x1010101010101010
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+808(SB)/8, $0x1010101010101010
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+816(SB)/8, $0x1010101010101010
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+824(SB)/8, $0x1010101010101010
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+832(SB)/8, $0xc08060403020100
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+840(SB)/8, $0xf4f8fafcfdfeff00
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+848(SB)/8, $0xc08060403020100
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+856(SB)/8, $0xf4f8fafcfdfeff00
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+864(SB)/8, $0x0
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+872(SB)/8, $0x0
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+880(SB)/8, $0x0
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+888(SB)/8, $0x0
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+896(SB)/8, $0x0
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+904(SB)/8, $0x101010101010101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+912(SB)/8, $0x202020202020202
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+920(SB)/8, $0x303030303030303
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+928(SB)/8, $0x8040201008040201
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+936(SB)/8, $0x8040201008040201
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+944(SB)/8, $0x8040201008040201
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+952(SB)/8, $0x8040201008040201
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+960(SB)/8, $0x0
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+968(SB)/8, $0x0
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+976(SB)/8, $0x101010101010101
DATA ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4+984(SB)/8, $0x101010101010101
GLOBL ·ovr_dbg_vec_dot_iq3_s_q8_K_avx2_b992_162b794bb93e2ca4(SB), RODATA|NOPTR, $992
