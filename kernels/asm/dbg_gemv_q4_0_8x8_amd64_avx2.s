// dbg_gemv_q4_0_8x8: q4_0 8x8 repack GEMV (AVX2), VPMADDUBSW over the unpacked runs; -8 folded through the block sum.
	MOVL	l0+8(FP), CX
	SHRL	$5, CX
	MOVL	l6+52(FP), R11
	SHRL	$3, R11
	MOVQ	l1+16(FP), DI
	MOVQ	l3+32(FP), R9
	MOVQ	l4+40(FP), R10
	IMUL3Q	$144, CX, R12
	TESTQ	R11, R11
	JZ	done4
	MOVQ	DI, AX
	LEAQ	(AX)(R11*8), AX
	LEAQ	(AX)(R11*8), AX
	LEAQ	(AX)(R11*8), AX
	LEAQ	(AX)(R11*8), AX
	CMPQ	R15, AX
	JCS	oob4
	MOVQ	R12, AX
	IMULQ	R11, AX
	ADDQ	R9, AX
	CMPQ	R15, AX
	JCS	oob4
	IMUL3Q	$34, CX, AX
	ADDQ	R10, AX
	CMPQ	R15, AX
	JCS	oob4
	ADDQ	R14, DI
	ADDQ	R14, R9
	ADDQ	R14, R10
	VMOVDQU	·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+192(SB), Y13
	VMOVDQU	·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+224(SB), Y15
group4:
	VXORPS	Y2, Y2, Y2
	MOVQ	R10, DX
	MOVQ	CX, R8
	TESTQ	R8, R8
	JZ	store4
blk4:
	VMOVDQU	2(DX), Y10
	VPMADDUBSW	Y10, Y13, Y10
	VPMADDWD	·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+160(SB), Y10, Y10
	VEXTRACTI128	$1, Y10, X11
	VPADDD	X11, X10, X10
	VPHADDD	X10, X10, X10
	VPHADDD	X10, X10, X10
	VPSLLD	$3, X10, X10
	VPBROADCASTD	X10, Y11
	VPXOR	Y0, Y0, Y0
	VPXOR	Y1, Y1, Y1
	VMOVDQU	16(R9), Y4
	VPXOR	·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+288(SB), Y4, Y4
	VPAND	·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+0(SB), Y4, Y5
	VPSRLW	$4, Y4, Y6
	VPAND	·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+0(SB), Y6, Y6
	VPBROADCASTQ	2(DX), Y8
	VPBROADCASTQ	18(DX), Y9
	VPMADDUBSW	Y8, Y5, Y10
	VPMADDWD	·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+160(SB), Y10, Y10
	VPADDD	Y10, Y0, Y0
	VPMADDUBSW	Y9, Y6, Y10
	VPMADDWD	·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+160(SB), Y10, Y10
	VPADDD	Y10, Y0, Y0
	VMOVDQU	48(R9), Y4
	VPXOR	·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+288(SB), Y4, Y4
	VPAND	·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+0(SB), Y4, Y5
	VPSRLW	$4, Y4, Y6
	VPAND	·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+0(SB), Y6, Y6
	VPBROADCASTQ	2(DX), Y8
	VPBROADCASTQ	18(DX), Y9
	VPMADDUBSW	Y8, Y5, Y10
	VPMADDWD	·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+160(SB), Y10, Y10
	VPADDD	Y10, Y1, Y1
	VPMADDUBSW	Y9, Y6, Y10
	VPMADDWD	·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+160(SB), Y10, Y10
	VPADDD	Y10, Y1, Y1
	VMOVDQU	80(R9), Y4
	VPXOR	·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+288(SB), Y4, Y4
	VPAND	·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+0(SB), Y4, Y5
	VPSRLW	$4, Y4, Y6
	VPAND	·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+0(SB), Y6, Y6
	VPBROADCASTQ	10(DX), Y8
	VPBROADCASTQ	26(DX), Y9
	VPMADDUBSW	Y8, Y5, Y10
	VPMADDWD	·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+160(SB), Y10, Y10
	VPADDD	Y10, Y0, Y0
	VPMADDUBSW	Y9, Y6, Y10
	VPMADDWD	·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+160(SB), Y10, Y10
	VPADDD	Y10, Y0, Y0
	VMOVDQU	112(R9), Y4
	VPXOR	·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+288(SB), Y4, Y4
	VPAND	·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+0(SB), Y4, Y5
	VPSRLW	$4, Y4, Y6
	VPAND	·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+0(SB), Y6, Y6
	VPBROADCASTQ	10(DX), Y8
	VPBROADCASTQ	26(DX), Y9
	VPMADDUBSW	Y8, Y5, Y10
	VPMADDWD	·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+160(SB), Y10, Y10
	VPADDD	Y10, Y1, Y1
	VPMADDUBSW	Y9, Y6, Y10
	VPMADDWD	·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+160(SB), Y10, Y10
	VPADDD	Y10, Y1, Y1
	VPHADDD	Y1, Y0, Y0
	VPSUBD	Y11, Y0, Y0
	VCVTDQ2PS	Y0, Y0
	VCVTPH2PS	(R9), Y14
	VPERMPS	Y14, Y15, Y14
	MOVWLZX	(DX), AX
	VMOVD	AX, X10
	VCVTPH2PS	X10, X10
	VBROADCASTSS	X10, Y10
	VMULPS	Y10, Y14, Y14
	VFMADD231PS	Y14, Y0, Y2
	ADDQ	$144, R9
	ADDQ	$34, DX
	DECQ	R8
	JNZ	blk4
store4:
	VPERMPS	Y2, Y15, Y2
	VMOVUPS	Y2, (DI)
	ADDQ	$32, DI
	DECQ	R11
	JNZ	group4
done4:
	VZEROUPPER
	RET
oob4:
	VZEROUPPER
	JMP	ovr_oob

DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+0(SB)/8, $0xf0f0f0f0f0f0f0f
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+8(SB)/8, $0xf0f0f0f0f0f0f0f
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+16(SB)/8, $0xf0f0f0f0f0f0f0f
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+24(SB)/8, $0xf0f0f0f0f0f0f0f
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+32(SB)/8, $0x1010101010101010
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+40(SB)/8, $0x1010101010101010
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+48(SB)/8, $0x1010101010101010
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+56(SB)/8, $0x1010101010101010
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+64(SB)/8, $0x8040201008040201
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+72(SB)/8, $0x8040201008040201
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+80(SB)/8, $0x8040201008040201
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+88(SB)/8, $0x8040201008040201
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+96(SB)/8, $0x0
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+104(SB)/8, $0x101010101010101
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+112(SB)/8, $0x404040404040404
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+120(SB)/8, $0x505050505050505
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+128(SB)/8, $0x202020202020202
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+136(SB)/8, $0x303030303030303
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+144(SB)/8, $0x606060606060606
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+152(SB)/8, $0x707070707070707
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+160(SB)/8, $0x1000100010001
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+168(SB)/8, $0x1000100010001
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+176(SB)/8, $0x1000100010001
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+184(SB)/8, $0x1000100010001
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+192(SB)/8, $0x101010101010101
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+200(SB)/8, $0x101010101010101
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+208(SB)/8, $0x101010101010101
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+216(SB)/8, $0x101010101010101
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+224(SB)/8, $0x100000000
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+232(SB)/8, $0x500000004
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+240(SB)/8, $0x300000002
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+248(SB)/8, $0x700000006
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+256(SB)/8, $0xf6eaddcfbfad9881
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+264(SB)/8, $0x7159453526190d01
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+272(SB)/8, $0xf6eaddcfbfad9881
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+280(SB)/8, $0x7159453526190d01
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+288(SB)/8, $0x8888888888888888
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+296(SB)/8, $0x8888888888888888
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+304(SB)/8, $0x8888888888888888
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+312(SB)/8, $0x8888888888888888
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+320(SB)/8, $0xc08060403020100
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+328(SB)/8, $0xf4f8fafcfdfeff00
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+336(SB)/8, $0xc08060403020100
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+344(SB)/8, $0xf4f8fafcfdfeff00
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+352(SB)/8, $0x100000001
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+360(SB)/8, $0x100000001
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+368(SB)/8, $0x100000001
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+376(SB)/8, $0x100000001
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+384(SB)/8, $0x20000000200000
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+392(SB)/8, $0x20000000200000
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+400(SB)/8, $0x20000000200000
DATA ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0+408(SB)/8, $0x20000000200000
GLOBL ·ovr_dbg_gemv_q4_0_8x8_avx2_b416_e0acb8ea4df6c0f0(SB), RODATA|NOPTR, $416
