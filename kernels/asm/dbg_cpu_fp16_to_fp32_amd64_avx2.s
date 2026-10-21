// dbg_cpu_fp16_to_fp32: y = (f32) x, n elements.
	MOVQ	l2+24(FP), CX
	TESTQ	CX, CX
	JLE	c1done
	MOVQ	l0+8(FP), SI
	MOVQ	l1+16(FP), DI
	LEAQ	(SI)(CX*2), R8
	CMPQ	R15, R8
	JCS	c1oob
	LEAQ	(DI)(CX*4), R8
	CMPQ	R15, R8
	JCS	c1oob
	ADDQ	R14, SI
	ADDQ	R14, DI
c1loop8:
	CMPQ	CX, $8
	JLT	c1loop4
	VCVTPH2PS	(SI), Y0
	VMOVUPS	Y0, (DI)
	ADDQ	$16, SI
	ADDQ	$32, DI
	SUBQ	$8, CX
	JMP	c1loop8
c1loop4:
	CMPQ	CX, $4
	JLT	c1tail
	VCVTPH2PS	(SI), X0
	VMOVUPS	X0, (DI)
	ADDQ	$8, SI
	ADDQ	$16, DI
	SUBQ	$4, CX
	JMP	c1loop4
c1tail:
	TESTQ	CX, CX
	JZ	c1done
	MOVWQZX	(SI), AX
	VMOVD	AX, X0
	VCVTPH2PS	X0, X0
	VMOVSS	X0, (DI)
	ADDQ	$2, SI
	ADDQ	$4, DI
	SUBQ	$1, CX
	JMP	c1tail
c1done:
	VZEROUPPER
	RET
c1oob:
	JMP	ovr_oob
