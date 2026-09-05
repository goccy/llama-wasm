// dbg_vec_dot_q4_0_q8_0: q4_0 x q8_0 dot (AVX2).
	VXORPS	Y0, Y0, Y0
	MOVLQSX	l0+8(FP), CX
	SHRQ	$5, CX
	MOVQ	l1+16(FP), DI
	LEAQ	4(DI), R8
	CMPQ	R15, R8
	JCS	q4doob
	ADDQ	R14, DI
	TESTQ	CX, CX
	JZ	q4dreduce
	MOVQ	l3+32(FP), SI
	MOVQ	l5+48(FP), DX
	IMUL3Q	$18, CX, R8
	ADDQ	SI, R8
	CMPQ	R15, R8
	JCS	q4doob
	IMUL3Q	$34, CX, R8
	ADDQ	DX, R8
	CMPQ	R15, R8
	JCS	q4doob
	ADDQ	R14, SI
	ADDQ	R14, DX
	VMOVDQU	·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+64(SB), Y10
	VMOVDQU	·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+0(SB), Y8
	VMOVDQU	·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+800(SB), Y9
	VPSRLW	$1, Y9, Y9
q4dblk:
	VMOVDQU	2(SI), X2
	VPSRLW	$4, X2, X3
	VINSERTI128	$1, X3, Y2, Y2
	VPAND	Y8, Y2, Y2
	VPSUBB	Y9, Y2, Y2
	VMOVDQU	2(DX), Y4
	VPSIGNB	Y2, Y2, Y5
	VPSIGNB	Y2, Y4, Y4
	VPMADDUBSW	Y4, Y5, Y5
	VPMADDWD	Y10, Y5, Y5
	VCVTDQ2PS	Y5, Y5
	MOVWLZX	0(SI), R8
	VMOVD	R8, X6
	VCVTPH2PS	X6, X6
	MOVWLZX	0(DX), R8
	VMOVD	R8, X7
	VCVTPH2PS	X7, X7
	VMULSS	X7, X6, X6
	VBROADCASTSS	X6, Y6
	VFMADD231PS	Y5, Y6, Y0
	ADDQ	$18, SI
	ADDQ	$34, DX
	DECQ	CX
	JNZ	q4dblk
q4dreduce:
	VEXTRACTF128	$1, Y0, X2
	VADDPS	X2, X0, X0
	VHADDPS	X0, X0, X0
	VHADDPS	X0, X0, X0
	VMOVSS	X0, (DI)
	VZEROUPPER
	RET
q4doob:
	VZEROUPPER
	JMP	ovr_oob

DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+0(SB)/8, $0xf0f0f0f0f0f0f0f
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+8(SB)/8, $0xf0f0f0f0f0f0f0f
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+16(SB)/8, $0xf0f0f0f0f0f0f0f
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+24(SB)/8, $0xf0f0f0f0f0f0f0f
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+32(SB)/8, $0xf0f0f0f0f0f0f0f0
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+40(SB)/8, $0xf0f0f0f0f0f0f0f0
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+48(SB)/8, $0xf0f0f0f0f0f0f0f0
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+56(SB)/8, $0xf0f0f0f0f0f0f0f0
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+64(SB)/8, $0x1000100010001
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+72(SB)/8, $0x1000100010001
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+80(SB)/8, $0x1000100010001
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+88(SB)/8, $0x1000100010001
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+96(SB)/8, $0x0
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+104(SB)/8, $0x101010101010101
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+112(SB)/8, $0x202020202020202
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+120(SB)/8, $0x303030303030303
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+128(SB)/8, $0x7fbfdfeff7fbfdfe
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+136(SB)/8, $0x7fbfdfeff7fbfdfe
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+144(SB)/8, $0x7fbfdfeff7fbfdfe
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+152(SB)/8, $0x7fbfdfeff7fbfdfe
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+160(SB)/8, $0x303030303030303
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+168(SB)/8, $0x303030303030303
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+176(SB)/8, $0x303030303030303
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+184(SB)/8, $0x303030303030303
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+192(SB)/8, $0xc0c0c0c0c0c0c0c
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+200(SB)/8, $0xc0c0c0c0c0c0c0c
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+208(SB)/8, $0xc0c0c0c0c0c0c0c
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+216(SB)/8, $0xc0c0c0c0c0c0c0c
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+224(SB)/8, $0x3030303030303030
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+232(SB)/8, $0x3030303030303030
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+240(SB)/8, $0x3030303030303030
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+248(SB)/8, $0x3030303030303030
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+256(SB)/8, $0xc0c0c0c0c0c0c0c0
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+264(SB)/8, $0xc0c0c0c0c0c0c0c0
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+272(SB)/8, $0xc0c0c0c0c0c0c0c0
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+280(SB)/8, $0xc0c0c0c0c0c0c0c0
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+288(SB)/8, $0x100010001000100
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+296(SB)/8, $0x100010001000100
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+304(SB)/8, $0x100010001000100
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+312(SB)/8, $0x100010001000100
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+320(SB)/8, $0x302030203020302
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+328(SB)/8, $0x302030203020302
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+336(SB)/8, $0x302030203020302
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+344(SB)/8, $0x302030203020302
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+352(SB)/8, $0x504050405040504
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+360(SB)/8, $0x504050405040504
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+368(SB)/8, $0x504050405040504
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+376(SB)/8, $0x504050405040504
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+384(SB)/8, $0x706070607060706
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+392(SB)/8, $0x706070607060706
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+400(SB)/8, $0x706070607060706
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+408(SB)/8, $0x706070607060706
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+416(SB)/8, $0x908090809080908
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+424(SB)/8, $0x908090809080908
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+432(SB)/8, $0x908090809080908
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+440(SB)/8, $0x908090809080908
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+448(SB)/8, $0xb0a0b0a0b0a0b0a
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+456(SB)/8, $0xb0a0b0a0b0a0b0a
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+464(SB)/8, $0xb0a0b0a0b0a0b0a
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+472(SB)/8, $0xb0a0b0a0b0a0b0a
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+480(SB)/8, $0xd0c0d0c0d0c0d0c
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+488(SB)/8, $0xd0c0d0c0d0c0d0c
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+496(SB)/8, $0xd0c0d0c0d0c0d0c
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+504(SB)/8, $0xd0c0d0c0d0c0d0c
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+512(SB)/8, $0xf0e0f0e0f0e0f0e
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+520(SB)/8, $0xf0e0f0e0f0e0f0e
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+528(SB)/8, $0xf0e0f0e0f0e0f0e
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+536(SB)/8, $0xf0e0f0e0f0e0f0e
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+544(SB)/8, $0x0
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+552(SB)/8, $0x101010101010101
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+560(SB)/8, $0x202020202020202
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+568(SB)/8, $0x303030303030303
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+576(SB)/8, $0x404040404040404
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+584(SB)/8, $0x505050505050505
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+592(SB)/8, $0x606060606060606
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+600(SB)/8, $0x707070707070707
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+608(SB)/8, $0x808080808080808
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+616(SB)/8, $0x909090909090909
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+624(SB)/8, $0xa0a0a0a0a0a0a0a
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+632(SB)/8, $0xb0b0b0b0b0b0b0b
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+640(SB)/8, $0xc0c0c0c0c0c0c0c
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+648(SB)/8, $0xd0d0d0d0d0d0d0d
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+656(SB)/8, $0xe0e0e0e0e0e0e0e
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+664(SB)/8, $0xf0f0f0f0f0f0f0f
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+672(SB)/8, $0x101010101010101
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+680(SB)/8, $0x101010101010101
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+688(SB)/8, $0x101010101010101
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+696(SB)/8, $0x101010101010101
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+704(SB)/8, $0x202020202020202
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+712(SB)/8, $0x202020202020202
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+720(SB)/8, $0x202020202020202
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+728(SB)/8, $0x202020202020202
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+736(SB)/8, $0x2020202020202020
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+744(SB)/8, $0x2020202020202020
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+752(SB)/8, $0x2020202020202020
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+760(SB)/8, $0x2020202020202020
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+768(SB)/8, $0xf6eaddcfbfad9881
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+776(SB)/8, $0x7159453526190d01
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+784(SB)/8, $0xf6eaddcfbfad9881
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+792(SB)/8, $0x7159453526190d01
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+800(SB)/8, $0x1010101010101010
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+808(SB)/8, $0x1010101010101010
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+816(SB)/8, $0x1010101010101010
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+824(SB)/8, $0x1010101010101010
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+832(SB)/8, $0xc08060403020100
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+840(SB)/8, $0xf4f8fafcfdfeff00
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+848(SB)/8, $0xc08060403020100
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+856(SB)/8, $0xf4f8fafcfdfeff00
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+864(SB)/8, $0x0
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+872(SB)/8, $0x0
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+880(SB)/8, $0x0
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+888(SB)/8, $0x0
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+896(SB)/8, $0x0
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+904(SB)/8, $0x101010101010101
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+912(SB)/8, $0x202020202020202
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+920(SB)/8, $0x303030303030303
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+928(SB)/8, $0x8040201008040201
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+936(SB)/8, $0x8040201008040201
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+944(SB)/8, $0x8040201008040201
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+952(SB)/8, $0x8040201008040201
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+960(SB)/8, $0x0
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+968(SB)/8, $0x0
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+976(SB)/8, $0x101010101010101
DATA ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4+984(SB)/8, $0x101010101010101
GLOBL ·ovr_dbg_vec_dot_q4_0_q8_0_avx2_b992_162b794bb93e2ca4(SB), RODATA|NOPTR, $992
