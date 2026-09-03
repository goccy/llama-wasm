// dbg_simd_gemm_f32: f32 GEMM C += A*B, 4x16 / 4x4 / 4x1 tiles (row tail 1xN).
	MOVW	l3+32(FP), R5
	MOVW	l4+36(FP), R6
	MOVW	l5+40(FP), R7
	CMPW	$1, R5
	BLT	sgdone
	CMPW	$1, R6
	BLT	sgdone
	CMPW	$1, R7
	BLT	sgdone
	MOVD	l0+8(FP), R2
	MOVD	l1+16(FP), R3
	MOVD	l2+24(FP), R4
	MUL	R5, R6, R26
	LSL	$2, R26, R26
	ADD	R3, R26, R26
	CMP	R26, R21
	BLO	sgoob
	MUL	R6, R7, R26
	LSL	$2, R26, R26
	ADD	R4, R26, R26
	CMP	R26, R21
	BLO	sgoob
	MUL	R5, R7, R26
	LSL	$2, R26, R26
	ADD	R2, R26, R26
	CMP	R26, R21
	BLO	sgoob
	ADD	R20, R2, R2
	ADD	R20, R3, R3
	ADD	R20, R4, R4
	LSL	$2, R7, R8
	LSL	$2, R6, R9
sgrows4:
	CMPW	$4, R5
	BLT	sgrows1
	MOVW	R7, R10
	MOVD	R2, R11
	MOVD	R4, R12
sg4c16:
	CMPW	$16, R10
	BLT	sg4c4
	ADD	R11, R8, R13
	ADD	R13, R8, R14
	ADD	R14, R8, R15
	WORD $0x3cc00160 // ldur q0, [x11, #0]
	WORD $0x3cc10161 // ldur q1, [x11, #16]
	WORD $0x3cc20162 // ldur q2, [x11, #32]
	WORD $0x3cc30163 // ldur q3, [x11, #48]
	WORD $0x3cc001a4 // ldur q4, [x13, #0]
	WORD $0x3cc101a5 // ldur q5, [x13, #16]
	WORD $0x3cc201a6 // ldur q6, [x13, #32]
	WORD $0x3cc301a7 // ldur q7, [x13, #48]
	WORD $0x3cc001c8 // ldur q8, [x14, #0]
	WORD $0x3cc101c9 // ldur q9, [x14, #16]
	WORD $0x3cc201ca // ldur q10, [x14, #32]
	WORD $0x3cc301cb // ldur q11, [x14, #48]
	WORD $0x3cc001ec // ldur q12, [x15, #0]
	WORD $0x3cc101ed // ldur q13, [x15, #16]
	WORD $0x3cc201ee // ldur q14, [x15, #32]
	WORD $0x3cc301ef // ldur q15, [x15, #48]
	MOVD	R3, R16
	ADD	R16, R9, R17
	ADD	R17, R9, R19
	ADD	R19, R9, R23
	MOVD	R12, R22
	MOVW	R6, R24
sg4c16k:
	WORD $0x3cc002d0 // ldur q16, [x22, #0]
	WORD $0x3cc102d1 // ldur q17, [x22, #16]
	WORD $0x3cc202d2 // ldur q18, [x22, #32]
	WORD $0x3cc302d3 // ldur q19, [x22, #48]
	WORD $0x4ddfca14 // ld1r {v20.4s}, [x16], #4
	WORD $0x4ddfca35 // ld1r {v21.4s}, [x17], #4
	WORD $0x4ddfca76 // ld1r {v22.4s}, [x19], #4
	WORD $0x4ddfcaf7 // ld1r {v23.4s}, [x23], #4
	WORD $0x4e34ce00 // fmla v0.4s, v16.4s, v20.4s
	WORD $0x4e34ce21 // fmla v1.4s, v17.4s, v20.4s
	WORD $0x4e34ce42 // fmla v2.4s, v18.4s, v20.4s
	WORD $0x4e34ce63 // fmla v3.4s, v19.4s, v20.4s
	WORD $0x4e35ce04 // fmla v4.4s, v16.4s, v21.4s
	WORD $0x4e35ce25 // fmla v5.4s, v17.4s, v21.4s
	WORD $0x4e35ce46 // fmla v6.4s, v18.4s, v21.4s
	WORD $0x4e35ce67 // fmla v7.4s, v19.4s, v21.4s
	WORD $0x4e36ce08 // fmla v8.4s, v16.4s, v22.4s
	WORD $0x4e36ce29 // fmla v9.4s, v17.4s, v22.4s
	WORD $0x4e36ce4a // fmla v10.4s, v18.4s, v22.4s
	WORD $0x4e36ce6b // fmla v11.4s, v19.4s, v22.4s
	WORD $0x4e37ce0c // fmla v12.4s, v16.4s, v23.4s
	WORD $0x4e37ce2d // fmla v13.4s, v17.4s, v23.4s
	WORD $0x4e37ce4e // fmla v14.4s, v18.4s, v23.4s
	WORD $0x4e37ce6f // fmla v15.4s, v19.4s, v23.4s
	ADD	R8, R22, R22
	SUBW	$1, R24, R24
	CBNZW	R24, sg4c16k
	WORD $0x3c800160 // stur q0, [x11, #0]
	WORD $0x3c810161 // stur q1, [x11, #16]
	WORD $0x3c820162 // stur q2, [x11, #32]
	WORD $0x3c830163 // stur q3, [x11, #48]
	WORD $0x3c8001a4 // stur q4, [x13, #0]
	WORD $0x3c8101a5 // stur q5, [x13, #16]
	WORD $0x3c8201a6 // stur q6, [x13, #32]
	WORD $0x3c8301a7 // stur q7, [x13, #48]
	WORD $0x3c8001c8 // stur q8, [x14, #0]
	WORD $0x3c8101c9 // stur q9, [x14, #16]
	WORD $0x3c8201ca // stur q10, [x14, #32]
	WORD $0x3c8301cb // stur q11, [x14, #48]
	WORD $0x3c8001ec // stur q12, [x15, #0]
	WORD $0x3c8101ed // stur q13, [x15, #16]
	WORD $0x3c8201ee // stur q14, [x15, #32]
	WORD $0x3c8301ef // stur q15, [x15, #48]
	ADD	$64, R11, R11
	ADD	$64, R12, R12
	SUBW	$16, R10, R10
	B	sg4c16
sg4c4:
	CMPW	$4, R10
	BLT	sg4c1
	ADD	R11, R8, R13
	ADD	R13, R8, R14
	ADD	R14, R8, R15
	WORD $0x3cc00160 // ldur q0, [x11, #0]
	WORD $0x3cc001a4 // ldur q4, [x13, #0]
	WORD $0x3cc001c8 // ldur q8, [x14, #0]
	WORD $0x3cc001ec // ldur q12, [x15, #0]
	MOVD	R3, R16
	ADD	R16, R9, R17
	ADD	R17, R9, R19
	ADD	R19, R9, R23
	MOVD	R12, R22
	MOVW	R6, R24
sg4c4k:
	WORD $0x3cc002d0 // ldur q16, [x22, #0]
	WORD $0x4ddfca14 // ld1r {v20.4s}, [x16], #4
	WORD $0x4ddfca35 // ld1r {v21.4s}, [x17], #4
	WORD $0x4ddfca76 // ld1r {v22.4s}, [x19], #4
	WORD $0x4ddfcaf7 // ld1r {v23.4s}, [x23], #4
	WORD $0x4e34ce00 // fmla v0.4s, v16.4s, v20.4s
	WORD $0x4e35ce04 // fmla v4.4s, v16.4s, v21.4s
	WORD $0x4e36ce08 // fmla v8.4s, v16.4s, v22.4s
	WORD $0x4e37ce0c // fmla v12.4s, v16.4s, v23.4s
	ADD	R8, R22, R22
	SUBW	$1, R24, R24
	CBNZW	R24, sg4c4k
	WORD $0x3c800160 // stur q0, [x11, #0]
	WORD $0x3c8001a4 // stur q4, [x13, #0]
	WORD $0x3c8001c8 // stur q8, [x14, #0]
	WORD $0x3c8001ec // stur q12, [x15, #0]
	ADD	$16, R11, R11
	ADD	$16, R12, R12
	SUBW	$4, R10, R10
	B	sg4c4
sg4c1:
	CBZW	R10, sg4next
	ADD	R11, R8, R13
	ADD	R13, R8, R14
	ADD	R14, R8, R15
	FMOVS	(R11), F0
	FMOVS	(R13), F1
	FMOVS	(R14), F2
	FMOVS	(R15), F3
	MOVD	R3, R16
	ADD	R16, R9, R17
	ADD	R17, R9, R19
	ADD	R19, R9, R23
	MOVD	R12, R22
	MOVW	R6, R24
sg4c1k:
	FMOVS	(R22), F16
	FMOVS	(R16), F20
	ADD	$4, R16, R16
	FMADDS	F16, F0, F20, F0
	FMOVS	(R17), F21
	ADD	$4, R17, R17
	FMADDS	F16, F1, F21, F1
	FMOVS	(R19), F22
	ADD	$4, R19, R19
	FMADDS	F16, F2, F22, F2
	FMOVS	(R23), F23
	ADD	$4, R23, R23
	FMADDS	F16, F3, F23, F3
	ADD	R8, R22, R22
	SUBW	$1, R24, R24
	CBNZW	R24, sg4c1k
	FMOVS	F0, (R11)
	FMOVS	F1, (R13)
	FMOVS	F2, (R14)
	FMOVS	F3, (R15)
	ADD	$4, R11, R11
	ADD	$4, R12, R12
	SUBW	$1, R10, R10
	B	sg4c1
sg4next:
	ADD	R8<<2, R2, R2
	ADD	R9<<2, R3, R3
	SUBW	$4, R5, R5
	B	sgrows4
sgrows1:
	CBZW	R5, sgdone
	MOVW	R7, R10
	MOVD	R2, R11
	MOVD	R4, R12
sg1c16:
	CMPW	$16, R10
	BLT	sg1c4
	WORD $0x3cc00160 // ldur q0, [x11, #0]
	WORD $0x3cc10161 // ldur q1, [x11, #16]
	WORD $0x3cc20162 // ldur q2, [x11, #32]
	WORD $0x3cc30163 // ldur q3, [x11, #48]
	MOVD	R3, R16
	MOVD	R12, R22
	MOVW	R6, R24
sg1c16k:
	WORD $0x3cc002d0 // ldur q16, [x22, #0]
	WORD $0x3cc102d1 // ldur q17, [x22, #16]
	WORD $0x3cc202d2 // ldur q18, [x22, #32]
	WORD $0x3cc302d3 // ldur q19, [x22, #48]
	WORD $0x4ddfca14 // ld1r {v20.4s}, [x16], #4
	WORD $0x4e34ce00 // fmla v0.4s, v16.4s, v20.4s
	WORD $0x4e34ce21 // fmla v1.4s, v17.4s, v20.4s
	WORD $0x4e34ce42 // fmla v2.4s, v18.4s, v20.4s
	WORD $0x4e34ce63 // fmla v3.4s, v19.4s, v20.4s
	ADD	R8, R22, R22
	SUBW	$1, R24, R24
	CBNZW	R24, sg1c16k
	WORD $0x3c800160 // stur q0, [x11, #0]
	WORD $0x3c810161 // stur q1, [x11, #16]
	WORD $0x3c820162 // stur q2, [x11, #32]
	WORD $0x3c830163 // stur q3, [x11, #48]
	ADD	$64, R11, R11
	ADD	$64, R12, R12
	SUBW	$16, R10, R10
	B	sg1c16
sg1c4:
	CMPW	$4, R10
	BLT	sg1c1
	WORD $0x3cc00160 // ldur q0, [x11, #0]
	MOVD	R3, R16
	MOVD	R12, R22
	MOVW	R6, R24
sg1c4k:
	WORD $0x3cc002d0 // ldur q16, [x22, #0]
	WORD $0x4ddfca14 // ld1r {v20.4s}, [x16], #4
	WORD $0x4e34ce00 // fmla v0.4s, v16.4s, v20.4s
	ADD	R8, R22, R22
	SUBW	$1, R24, R24
	CBNZW	R24, sg1c4k
	WORD $0x3c800160 // stur q0, [x11, #0]
	ADD	$16, R11, R11
	ADD	$16, R12, R12
	SUBW	$4, R10, R10
	B	sg1c4
sg1c1:
	CBZW	R10, sg1next
	FMOVS	(R11), F0
	MOVD	R3, R16
	MOVD	R12, R22
	MOVW	R6, R24
sg1c1k:
	FMOVS	(R22), F16
	FMOVS	(R16), F20
	ADD	$4, R16, R16
	FMADDS	F16, F0, F20, F0
	ADD	R8, R22, R22
	SUBW	$1, R24, R24
	CBNZW	R24, sg1c1k
	FMOVS	F0, (R11)
	ADD	$4, R11, R11
	ADD	$4, R12, R12
	SUBW	$1, R10, R10
	B	sg1c1
sg1next:
	ADD	R8, R2, R2
	ADD	R9, R3, R3
	SUBW	$1, R5, R5
	B	sgrows1
sgdone:
	RET
sgoob:
	B	kov_oob
