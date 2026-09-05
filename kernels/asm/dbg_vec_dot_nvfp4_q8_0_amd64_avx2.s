// dbg_vec_dot_nvfp4_q8_0: nvfp4 x q8_0 dot (AVX2), fp4 nibbles through VPSHUFB, UE4M3 sub-block scales through a table.
	VXORPS	Y0, Y0, Y0
	MOVLQSX	l0+8(FP), CX
	SHRQ	$6, CX
	MOVQ	l1+16(FP), DI
	LEAQ	4(DI), R8
	CMPQ	R15, R8
	JCS	nvoob
	ADDQ	R14, DI
	TESTQ	CX, CX
	JZ	nvreduce
	MOVQ	l3+32(FP), SI
	MOVQ	l5+48(FP), DX
	IMUL3Q	$36, CX, R8
	ADDQ	SI, R8
	CMPQ	R15, R8
	JCS	nvoob
	IMUL3Q	$68, CX, R8
	ADDQ	DX, R8
	CMPQ	R15, R8
	JCS	nvoob
	ADDQ	R14, SI
	ADDQ	R14, DX
	MOVQ	$·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf(SB), R12
	VMOVDQU	·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+64(SB), Y10
	VMOVDQU	·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+832(SB), X11
	VMOVDQU	·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+0(SB), X8
	VPXOR	Y9, Y9, Y9
nvblk:
	VMOVQ	4(SI), X2
	VPSRLW	$4, X2, X3
	VPUNPCKLQDQ	X3, X2, X2
	VPAND	X8, X2, X2
	VPSHUFB	X2, X11, X2
	VINSERTI128	$1, X9, Y2, Y2
	VMOVDQU	2(DX), X3
	VINSERTI128	$1, X9, Y3, Y3
	VPSIGNB	Y2, Y2, Y5
	VPSIGNB	Y2, Y3, Y4
	VPMADDUBSW	Y4, Y5, Y5
	VPMADDWD	Y10, Y5, Y5
	VCVTDQ2PS	Y5, Y5
	MOVBLZX	0(SI), R8
	VMOVSS	(R12)(R8*4), X6
	MOVWLZX	0(DX), R8
	VMOVD	R8, X7
	VCVTPH2PS	X7, X7
	VMULSS	X7, X6, X6
	VBROADCASTSS	X6, Y6
	VFMADD231PS	Y5, Y6, Y0
	VMOVQ	12(SI), X2
	VPSRLW	$4, X2, X3
	VPUNPCKLQDQ	X3, X2, X2
	VPAND	X8, X2, X2
	VPSHUFB	X2, X11, X2
	VINSERTI128	$1, X9, Y2, Y2
	VMOVDQU	18(DX), X3
	VINSERTI128	$1, X9, Y3, Y3
	VPSIGNB	Y2, Y2, Y5
	VPSIGNB	Y2, Y3, Y4
	VPMADDUBSW	Y4, Y5, Y5
	VPMADDWD	Y10, Y5, Y5
	VCVTDQ2PS	Y5, Y5
	MOVBLZX	1(SI), R8
	VMOVSS	(R12)(R8*4), X6
	MOVWLZX	0(DX), R8
	VMOVD	R8, X7
	VCVTPH2PS	X7, X7
	VMULSS	X7, X6, X6
	VBROADCASTSS	X6, Y6
	VFMADD231PS	Y5, Y6, Y0
	VMOVQ	20(SI), X2
	VPSRLW	$4, X2, X3
	VPUNPCKLQDQ	X3, X2, X2
	VPAND	X8, X2, X2
	VPSHUFB	X2, X11, X2
	VINSERTI128	$1, X9, Y2, Y2
	VMOVDQU	36(DX), X3
	VINSERTI128	$1, X9, Y3, Y3
	VPSIGNB	Y2, Y2, Y5
	VPSIGNB	Y2, Y3, Y4
	VPMADDUBSW	Y4, Y5, Y5
	VPMADDWD	Y10, Y5, Y5
	VCVTDQ2PS	Y5, Y5
	MOVBLZX	2(SI), R8
	VMOVSS	(R12)(R8*4), X6
	MOVWLZX	34(DX), R8
	VMOVD	R8, X7
	VCVTPH2PS	X7, X7
	VMULSS	X7, X6, X6
	VBROADCASTSS	X6, Y6
	VFMADD231PS	Y5, Y6, Y0
	VMOVQ	28(SI), X2
	VPSRLW	$4, X2, X3
	VPUNPCKLQDQ	X3, X2, X2
	VPAND	X8, X2, X2
	VPSHUFB	X2, X11, X2
	VINSERTI128	$1, X9, Y2, Y2
	VMOVDQU	52(DX), X3
	VINSERTI128	$1, X9, Y3, Y3
	VPSIGNB	Y2, Y2, Y5
	VPSIGNB	Y2, Y3, Y4
	VPMADDUBSW	Y4, Y5, Y5
	VPMADDWD	Y10, Y5, Y5
	VCVTDQ2PS	Y5, Y5
	MOVBLZX	3(SI), R8
	VMOVSS	(R12)(R8*4), X6
	MOVWLZX	34(DX), R8
	VMOVD	R8, X7
	VCVTPH2PS	X7, X7
	VMULSS	X7, X6, X6
	VBROADCASTSS	X6, Y6
	VFMADD231PS	Y5, Y6, Y0
	ADDQ	$36, SI
	ADDQ	$68, DX
	DECQ	CX
	JNZ	nvblk
nvreduce:
	VEXTRACTF128	$1, Y0, X2
	VADDPS	X2, X0, X0
	VHADDPS	X0, X0, X0
	VHADDPS	X0, X0, X0
	VMOVSS	X0, (DI)
	VZEROUPPER
	RET
nvoob:
	VZEROUPPER
	JMP	ovr_oob

DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+0(SB)/8, $0x3a80000000000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+8(SB)/8, $0x3b4000003b000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+16(SB)/8, $0x3ba000003b800000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+24(SB)/8, $0x3be000003bc00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+32(SB)/8, $0x3c1000003c000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+40(SB)/8, $0x3c3000003c200000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+48(SB)/8, $0x3c5000003c400000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+56(SB)/8, $0x3c7000003c600000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+64(SB)/8, $0x3c9000003c800000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+72(SB)/8, $0x3cb000003ca00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+80(SB)/8, $0x3cd000003cc00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+88(SB)/8, $0x3cf000003ce00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+96(SB)/8, $0x3d1000003d000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+104(SB)/8, $0x3d3000003d200000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+112(SB)/8, $0x3d5000003d400000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+120(SB)/8, $0x3d7000003d600000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+128(SB)/8, $0x3d9000003d800000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+136(SB)/8, $0x3db000003da00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+144(SB)/8, $0x3dd000003dc00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+152(SB)/8, $0x3df000003de00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+160(SB)/8, $0x3e1000003e000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+168(SB)/8, $0x3e3000003e200000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+176(SB)/8, $0x3e5000003e400000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+184(SB)/8, $0x3e7000003e600000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+192(SB)/8, $0x3e9000003e800000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+200(SB)/8, $0x3eb000003ea00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+208(SB)/8, $0x3ed000003ec00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+216(SB)/8, $0x3ef000003ee00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+224(SB)/8, $0x3f1000003f000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+232(SB)/8, $0x3f3000003f200000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+240(SB)/8, $0x3f5000003f400000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+248(SB)/8, $0x3f7000003f600000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+256(SB)/8, $0x3f9000003f800000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+264(SB)/8, $0x3fb000003fa00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+272(SB)/8, $0x3fd000003fc00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+280(SB)/8, $0x3ff000003fe00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+288(SB)/8, $0x4010000040000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+296(SB)/8, $0x4030000040200000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+304(SB)/8, $0x4050000040400000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+312(SB)/8, $0x4070000040600000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+320(SB)/8, $0x4090000040800000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+328(SB)/8, $0x40b0000040a00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+336(SB)/8, $0x40d0000040c00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+344(SB)/8, $0x40f0000040e00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+352(SB)/8, $0x4110000041000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+360(SB)/8, $0x4130000041200000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+368(SB)/8, $0x4150000041400000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+376(SB)/8, $0x4170000041600000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+384(SB)/8, $0x4190000041800000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+392(SB)/8, $0x41b0000041a00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+400(SB)/8, $0x41d0000041c00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+408(SB)/8, $0x41f0000041e00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+416(SB)/8, $0x4210000042000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+424(SB)/8, $0x4230000042200000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+432(SB)/8, $0x4250000042400000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+440(SB)/8, $0x4270000042600000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+448(SB)/8, $0x4290000042800000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+456(SB)/8, $0x42b0000042a00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+464(SB)/8, $0x42d0000042c00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+472(SB)/8, $0x42f0000042e00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+480(SB)/8, $0x4310000043000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+488(SB)/8, $0x4330000043200000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+496(SB)/8, $0x4350000043400000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+504(SB)/8, $0x43600000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+512(SB)/8, $0x3a80000000000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+520(SB)/8, $0x3b4000003b000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+528(SB)/8, $0x3ba000003b800000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+536(SB)/8, $0x3be000003bc00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+544(SB)/8, $0x3c1000003c000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+552(SB)/8, $0x3c3000003c200000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+560(SB)/8, $0x3c5000003c400000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+568(SB)/8, $0x3c7000003c600000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+576(SB)/8, $0x3c9000003c800000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+584(SB)/8, $0x3cb000003ca00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+592(SB)/8, $0x3cd000003cc00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+600(SB)/8, $0x3cf000003ce00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+608(SB)/8, $0x3d1000003d000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+616(SB)/8, $0x3d3000003d200000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+624(SB)/8, $0x3d5000003d400000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+632(SB)/8, $0x3d7000003d600000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+640(SB)/8, $0x3d9000003d800000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+648(SB)/8, $0x3db000003da00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+656(SB)/8, $0x3dd000003dc00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+664(SB)/8, $0x3df000003de00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+672(SB)/8, $0x3e1000003e000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+680(SB)/8, $0x3e3000003e200000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+688(SB)/8, $0x3e5000003e400000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+696(SB)/8, $0x3e7000003e600000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+704(SB)/8, $0x3e9000003e800000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+712(SB)/8, $0x3eb000003ea00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+720(SB)/8, $0x3ed000003ec00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+728(SB)/8, $0x3ef000003ee00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+736(SB)/8, $0x3f1000003f000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+744(SB)/8, $0x3f3000003f200000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+752(SB)/8, $0x3f5000003f400000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+760(SB)/8, $0x3f7000003f600000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+768(SB)/8, $0x3f9000003f800000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+776(SB)/8, $0x3fb000003fa00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+784(SB)/8, $0x3fd000003fc00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+792(SB)/8, $0x3ff000003fe00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+800(SB)/8, $0x4010000040000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+808(SB)/8, $0x4030000040200000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+816(SB)/8, $0x4050000040400000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+824(SB)/8, $0x4070000040600000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+832(SB)/8, $0x4090000040800000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+840(SB)/8, $0x40b0000040a00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+848(SB)/8, $0x40d0000040c00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+856(SB)/8, $0x40f0000040e00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+864(SB)/8, $0x4110000041000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+872(SB)/8, $0x4130000041200000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+880(SB)/8, $0x4150000041400000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+888(SB)/8, $0x4170000041600000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+896(SB)/8, $0x4190000041800000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+904(SB)/8, $0x41b0000041a00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+912(SB)/8, $0x41d0000041c00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+920(SB)/8, $0x41f0000041e00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+928(SB)/8, $0x4210000042000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+936(SB)/8, $0x4230000042200000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+944(SB)/8, $0x4250000042400000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+952(SB)/8, $0x4270000042600000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+960(SB)/8, $0x4290000042800000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+968(SB)/8, $0x42b0000042a00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+976(SB)/8, $0x42d0000042c00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+984(SB)/8, $0x42f0000042e00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+992(SB)/8, $0x4310000043000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+1000(SB)/8, $0x4330000043200000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+1008(SB)/8, $0x4350000043400000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+1016(SB)/8, $0x4370000043600000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+1024(SB)/8, $0xc08060403020100
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf+1032(SB)/8, $0xf4f8fafcfdfeff00
GLOBL ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b1040_c1740f79b0d9ccaf(SB), RODATA|NOPTR, $1040
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+0(SB)/8, $0xf0f0f0f0f0f0f0f
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+8(SB)/8, $0xf0f0f0f0f0f0f0f
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+16(SB)/8, $0xf0f0f0f0f0f0f0f
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+24(SB)/8, $0xf0f0f0f0f0f0f0f
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+32(SB)/8, $0xf0f0f0f0f0f0f0f0
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+40(SB)/8, $0xf0f0f0f0f0f0f0f0
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+48(SB)/8, $0xf0f0f0f0f0f0f0f0
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+56(SB)/8, $0xf0f0f0f0f0f0f0f0
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+64(SB)/8, $0x1000100010001
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+72(SB)/8, $0x1000100010001
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+80(SB)/8, $0x1000100010001
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+88(SB)/8, $0x1000100010001
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+96(SB)/8, $0x0
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+104(SB)/8, $0x101010101010101
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+112(SB)/8, $0x202020202020202
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+120(SB)/8, $0x303030303030303
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+128(SB)/8, $0x7fbfdfeff7fbfdfe
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+136(SB)/8, $0x7fbfdfeff7fbfdfe
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+144(SB)/8, $0x7fbfdfeff7fbfdfe
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+152(SB)/8, $0x7fbfdfeff7fbfdfe
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+160(SB)/8, $0x303030303030303
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+168(SB)/8, $0x303030303030303
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+176(SB)/8, $0x303030303030303
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+184(SB)/8, $0x303030303030303
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+192(SB)/8, $0xc0c0c0c0c0c0c0c
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+200(SB)/8, $0xc0c0c0c0c0c0c0c
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+208(SB)/8, $0xc0c0c0c0c0c0c0c
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+216(SB)/8, $0xc0c0c0c0c0c0c0c
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+224(SB)/8, $0x3030303030303030
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+232(SB)/8, $0x3030303030303030
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+240(SB)/8, $0x3030303030303030
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+248(SB)/8, $0x3030303030303030
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+256(SB)/8, $0xc0c0c0c0c0c0c0c0
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+264(SB)/8, $0xc0c0c0c0c0c0c0c0
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+272(SB)/8, $0xc0c0c0c0c0c0c0c0
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+280(SB)/8, $0xc0c0c0c0c0c0c0c0
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+288(SB)/8, $0x100010001000100
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+296(SB)/8, $0x100010001000100
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+304(SB)/8, $0x100010001000100
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+312(SB)/8, $0x100010001000100
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+320(SB)/8, $0x302030203020302
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+328(SB)/8, $0x302030203020302
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+336(SB)/8, $0x302030203020302
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+344(SB)/8, $0x302030203020302
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+352(SB)/8, $0x504050405040504
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+360(SB)/8, $0x504050405040504
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+368(SB)/8, $0x504050405040504
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+376(SB)/8, $0x504050405040504
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+384(SB)/8, $0x706070607060706
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+392(SB)/8, $0x706070607060706
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+400(SB)/8, $0x706070607060706
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+408(SB)/8, $0x706070607060706
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+416(SB)/8, $0x908090809080908
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+424(SB)/8, $0x908090809080908
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+432(SB)/8, $0x908090809080908
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+440(SB)/8, $0x908090809080908
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+448(SB)/8, $0xb0a0b0a0b0a0b0a
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+456(SB)/8, $0xb0a0b0a0b0a0b0a
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+464(SB)/8, $0xb0a0b0a0b0a0b0a
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+472(SB)/8, $0xb0a0b0a0b0a0b0a
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+480(SB)/8, $0xd0c0d0c0d0c0d0c
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+488(SB)/8, $0xd0c0d0c0d0c0d0c
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+496(SB)/8, $0xd0c0d0c0d0c0d0c
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+504(SB)/8, $0xd0c0d0c0d0c0d0c
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+512(SB)/8, $0xf0e0f0e0f0e0f0e
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+520(SB)/8, $0xf0e0f0e0f0e0f0e
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+528(SB)/8, $0xf0e0f0e0f0e0f0e
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+536(SB)/8, $0xf0e0f0e0f0e0f0e
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+544(SB)/8, $0x0
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+552(SB)/8, $0x101010101010101
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+560(SB)/8, $0x202020202020202
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+568(SB)/8, $0x303030303030303
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+576(SB)/8, $0x404040404040404
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+584(SB)/8, $0x505050505050505
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+592(SB)/8, $0x606060606060606
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+600(SB)/8, $0x707070707070707
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+608(SB)/8, $0x808080808080808
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+616(SB)/8, $0x909090909090909
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+624(SB)/8, $0xa0a0a0a0a0a0a0a
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+632(SB)/8, $0xb0b0b0b0b0b0b0b
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+640(SB)/8, $0xc0c0c0c0c0c0c0c
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+648(SB)/8, $0xd0d0d0d0d0d0d0d
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+656(SB)/8, $0xe0e0e0e0e0e0e0e
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+664(SB)/8, $0xf0f0f0f0f0f0f0f
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+672(SB)/8, $0x101010101010101
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+680(SB)/8, $0x101010101010101
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+688(SB)/8, $0x101010101010101
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+696(SB)/8, $0x101010101010101
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+704(SB)/8, $0x202020202020202
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+712(SB)/8, $0x202020202020202
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+720(SB)/8, $0x202020202020202
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+728(SB)/8, $0x202020202020202
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+736(SB)/8, $0x2020202020202020
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+744(SB)/8, $0x2020202020202020
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+752(SB)/8, $0x2020202020202020
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+760(SB)/8, $0x2020202020202020
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+768(SB)/8, $0xf6eaddcfbfad9881
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+776(SB)/8, $0x7159453526190d01
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+784(SB)/8, $0xf6eaddcfbfad9881
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+792(SB)/8, $0x7159453526190d01
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+800(SB)/8, $0x1010101010101010
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+808(SB)/8, $0x1010101010101010
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+816(SB)/8, $0x1010101010101010
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+824(SB)/8, $0x1010101010101010
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+832(SB)/8, $0xc08060403020100
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+840(SB)/8, $0xf4f8fafcfdfeff00
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+848(SB)/8, $0xc08060403020100
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+856(SB)/8, $0xf4f8fafcfdfeff00
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+864(SB)/8, $0x0
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+872(SB)/8, $0x0
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+880(SB)/8, $0x0
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+888(SB)/8, $0x0
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+896(SB)/8, $0x0
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+904(SB)/8, $0x101010101010101
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+912(SB)/8, $0x202020202020202
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+920(SB)/8, $0x303030303030303
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+928(SB)/8, $0x8040201008040201
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+936(SB)/8, $0x8040201008040201
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+944(SB)/8, $0x8040201008040201
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+952(SB)/8, $0x8040201008040201
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+960(SB)/8, $0x0
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+968(SB)/8, $0x0
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+976(SB)/8, $0x101010101010101
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4+984(SB)/8, $0x101010101010101
GLOBL ·ovr_dbg_vec_dot_nvfp4_q8_0_avx2_b992_162b794bb93e2ca4(SB), RODATA|NOPTR, $992
