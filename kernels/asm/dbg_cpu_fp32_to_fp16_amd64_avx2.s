// dbg_cpu_fp32_to_fp16: y = (f16) x, n elements.
	MOVQ	l2+24(FP), CX
	TESTQ	CX, CX
	JLE	c3done
	MOVQ	l0+8(FP), SI
	MOVQ	l1+16(FP), DI
	LEAQ	(SI)(CX*4), R8
	CMPQ	R15, R8
	JCS	c3oob
	LEAQ	(DI)(CX*2), R8
	CMPQ	R15, R8
	JCS	c3oob
	ADDQ	R14, SI
	ADDQ	R14, DI
c3loop8:
	CMPQ	CX, $8
	JLT	c3loop4
	VMOVUPS	(SI), Y0
	VCVTPS2PH	$0, Y0, X0
	VMOVDQU	X0, (DI)
	ADDQ	$32, SI
	ADDQ	$16, DI
	SUBQ	$8, CX
	JMP	c3loop8
c3loop4:
	CMPQ	CX, $4
	JLT	c3tail
	VMOVUPS	(SI), X0
	VCVTPS2PH	$0, X0, X0
	VMOVQ	X0, (DI)
	ADDQ	$16, SI
	ADDQ	$8, DI
	SUBQ	$4, CX
	JMP	c3loop4
c3tail:
	TESTQ	CX, CX
	JZ	c3done
	VMOVSS	(SI), X0
	VCVTPS2PH	$0, X0, X0
	VPEXTRW	$0, X0, AX
	MOVW	AX, (DI)
	ADDQ	$4, SI
	ADDQ	$2, DI
	SUBQ	$1, CX
	JMP	c3tail
c3done:
	VZEROUPPER
	RET
c3oob:
	JMP	ovr_oob
