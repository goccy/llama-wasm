// dbg_gemm_q8_0_4x4: q8_0x4 repack GEMM, 8x4 tile via SMMLA / 4x4 tile via by-element SDOT.
	MOVW	l0+8(FP), R1
	LSRW	$5, R1, R1
	MOVD	$136, R8
	MUL	R1, R8, R8
	MOVWU	l5+48(FP), R6
	LSRW	$2, R6, R6
	MOVWU	l6+52(FP), R7
	LSRW	$2, R7, R7
	CBZW	R6, gemmdone
	CBZW	R7, gemmdone
	MOVD	l3+32(FP), R4
	MUL	R7, R8, R26
	ADD	R4, R26, R26
	CMP	R26, R21
	BLO	gemmoob
	MOVD	l4+40(FP), R5
	MUL	R6, R8, R26
	ADD	R5, R26, R26
	CMP	R26, R21
	BLO	gemmoob
	MOVD	l1+16(FP), R2
	MOVD	l2+24(FP), R3
	LSL	$2, R3, R3
	LSL	$2, R6, R9
	SUB	$1, R9, R9
	MUL	R3, R9, R26
	ADD	R2, R26, R26
	LSL	$4, R7, R9
	ADD	R9, R26, R26
	CMP	R26, R21
	BLO	gemmoob
	ADD	R20, R5, R10
	ADD	R20, R2, R11
	ADD	R20, R4, R22
	LSL	$2, R3, R23
	B	gemmm
gemmm:
	CMPW	$2, R6
	BLO	gemmsdot
	MOVD	$0, R9
	MOVW	R1, R24
gemmmchunk:
	MOVW	$256, R25
	CMPW	R25, R24
	CSELW	LO, R24, R25, R25
	ADD	R10, R9, R17
	ADD	R17, R8, R27
	MOVD	$gemmscratch-65536(SP), R19
	MOVW	R25, R15
	CBZW	R15, gemmmx0
gemmmpre:
	WORD $0x3cc08230 // ldur q16, [x17, #8]
	WORD $0x3cc18231 // ldur q17, [x17, #24]
	WORD $0x4e913a12 // zip1 v18.4s, v16.4s, v17.4s
	WORD $0x4e917a13 // zip2 v19.4s, v16.4s, v17.4s
	WORD $0x3c800272 // stur q18, [x19, #0]
	WORD $0x3c810273 // stur q19, [x19, #16]
	WORD $0x3cc08370 // ldur q16, [x27, #8]
	WORD $0x3cc18371 // ldur q17, [x27, #24]
	WORD $0x4e913a14 // zip1 v20.4s, v16.4s, v17.4s
	WORD $0x4e917a15 // zip2 v21.4s, v16.4s, v17.4s
	WORD $0x3c820274 // stur q20, [x19, #32]
	WORD $0x3c830275 // stur q21, [x19, #48]
	WORD $0x3cc28230 // ldur q16, [x17, #40]
	WORD $0x3cc38231 // ldur q17, [x17, #56]
	WORD $0x4e913a12 // zip1 v18.4s, v16.4s, v17.4s
	WORD $0x4e917a13 // zip2 v19.4s, v16.4s, v17.4s
	WORD $0x3c840272 // stur q18, [x19, #64]
	WORD $0x3c850273 // stur q19, [x19, #80]
	WORD $0x3cc28370 // ldur q16, [x27, #40]
	WORD $0x3cc38371 // ldur q17, [x27, #56]
	WORD $0x4e913a14 // zip1 v20.4s, v16.4s, v17.4s
	WORD $0x4e917a15 // zip2 v21.4s, v16.4s, v17.4s
	WORD $0x3c860274 // stur q20, [x19, #96]
	WORD $0x3c870275 // stur q21, [x19, #112]
	WORD $0x3cc48230 // ldur q16, [x17, #72]
	WORD $0x3cc58231 // ldur q17, [x17, #88]
	WORD $0x4e913a12 // zip1 v18.4s, v16.4s, v17.4s
	WORD $0x4e917a13 // zip2 v19.4s, v16.4s, v17.4s
	WORD $0x3c880272 // stur q18, [x19, #128]
	WORD $0x3c890273 // stur q19, [x19, #144]
	WORD $0x3cc48370 // ldur q16, [x27, #72]
	WORD $0x3cc58371 // ldur q17, [x27, #88]
	WORD $0x4e913a14 // zip1 v20.4s, v16.4s, v17.4s
	WORD $0x4e917a15 // zip2 v21.4s, v16.4s, v17.4s
	WORD $0x3c8a0274 // stur q20, [x19, #160]
	WORD $0x3c8b0275 // stur q21, [x19, #176]
	WORD $0x3cc68230 // ldur q16, [x17, #104]
	WORD $0x3cc78231 // ldur q17, [x17, #120]
	WORD $0x4e913a12 // zip1 v18.4s, v16.4s, v17.4s
	WORD $0x4e917a13 // zip2 v19.4s, v16.4s, v17.4s
	WORD $0x3c8c0272 // stur q18, [x19, #192]
	WORD $0x3c8d0273 // stur q19, [x19, #208]
	WORD $0x3cc68370 // ldur q16, [x27, #104]
	WORD $0x3cc78371 // ldur q17, [x27, #120]
	WORD $0x4e913a14 // zip1 v20.4s, v16.4s, v17.4s
	WORD $0x4e917a15 // zip2 v21.4s, v16.4s, v17.4s
	WORD $0x3c8e0274 // stur q20, [x19, #224]
	WORD $0x3c8f0275 // stur q21, [x19, #240]
	ADD	$136, R17, R17
	ADD	$136, R27, R27
	ADD	$256, R19, R19
	SUBW	$1, R15, R15
	CBNZW	R15, gemmmpre
gemmmx0:
	ADD	R22, R9, R13
	MOVD	R11, R14
	MOVW	R7, R12
gemmmx:
	CBNZ	R9, gemmmxload
	WORD $0x4f000418 // movi v24.4s, #0
	WORD $0x4f000419 // movi v25.4s, #0
	WORD $0x4f00041a // movi v26.4s, #0
	WORD $0x4f00041b // movi v27.4s, #0
	WORD $0x4f00041c // movi v28.4s, #0
	WORD $0x4f00041d // movi v29.4s, #0
	WORD $0x4f00041e // movi v30.4s, #0
	WORD $0x4f00041f // movi v31.4s, #0
	B	gemmmxgo
gemmmxload:
	MOVD	R14, R26
	WORD $0x3cc00350 // ldur q16, [x26, #0]
	ADD	R3, R26, R26
	WORD $0x3cc00351 // ldur q17, [x26, #0]
	ADD	R3, R26, R26
	WORD $0x4ed13a18 // zip1 v24.2d, v16.2d, v17.2d
	WORD $0x4ed17a19 // zip2 v25.2d, v16.2d, v17.2d
	WORD $0x3cc00350 // ldur q16, [x26, #0]
	ADD	R3, R26, R26
	WORD $0x3cc00351 // ldur q17, [x26, #0]
	ADD	R3, R26, R26
	WORD $0x4ed13a1a // zip1 v26.2d, v16.2d, v17.2d
	WORD $0x4ed17a1b // zip2 v27.2d, v16.2d, v17.2d
	WORD $0x3cc00350 // ldur q16, [x26, #0]
	ADD	R3, R26, R26
	WORD $0x3cc00351 // ldur q17, [x26, #0]
	ADD	R3, R26, R26
	WORD $0x4ed13a1c // zip1 v28.2d, v16.2d, v17.2d
	WORD $0x4ed17a1d // zip2 v29.2d, v16.2d, v17.2d
	WORD $0x3cc00350 // ldur q16, [x26, #0]
	ADD	R3, R26, R26
	WORD $0x3cc00351 // ldur q17, [x26, #0]
	ADD	R3, R26, R26
	WORD $0x4ed13a1e // zip1 v30.2d, v16.2d, v17.2d
	WORD $0x4ed17a1f // zip2 v31.2d, v16.2d, v17.2d
gemmmxgo:
	MOVD	R13, R16
	ADD	R10, R9, R17
	ADD	R17, R8, R27
	MOVD	$gemmscratch-65536(SP), R19
	MOVW	R25, R15
	CBZW	R15, gemmmstore
gemmmblk:
	WORD $0x4f000400 // movi v0.4s, #0
	WORD $0x4f000401 // movi v1.4s, #0
	WORD $0x4f000402 // movi v2.4s, #0
	WORD $0x4f000403 // movi v3.4s, #0
	WORD $0x4f000404 // movi v4.4s, #0
	WORD $0x4f000405 // movi v5.4s, #0
	WORD $0x4f000406 // movi v6.4s, #0
	WORD $0x4f000407 // movi v7.4s, #0
	WORD $0x3cc08210 // ldur q16, [x16, #8]
	WORD $0x3cc18211 // ldur q17, [x16, #24]
	WORD $0x4e913a12 // zip1 v18.4s, v16.4s, v17.4s
	WORD $0x4e917a13 // zip2 v19.4s, v16.4s, v17.4s
	WORD $0x3cc00274 // ldur q20, [x19, #0]
	WORD $0x3cc10275 // ldur q21, [x19, #16]
	WORD $0x3cc20276 // ldur q22, [x19, #32]
	WORD $0x3cc30277 // ldur q23, [x19, #48]
	WORD $0x4e92a680 // smmla v0.4s, v20.16b, v18.16b
	WORD $0x4e93a681 // smmla v1.4s, v20.16b, v19.16b
	WORD $0x4e92a6a2 // smmla v2.4s, v21.16b, v18.16b
	WORD $0x4e93a6a3 // smmla v3.4s, v21.16b, v19.16b
	WORD $0x4e92a6c4 // smmla v4.4s, v22.16b, v18.16b
	WORD $0x4e93a6c5 // smmla v5.4s, v22.16b, v19.16b
	WORD $0x4e92a6e6 // smmla v6.4s, v23.16b, v18.16b
	WORD $0x4e93a6e7 // smmla v7.4s, v23.16b, v19.16b
	WORD $0x3cc28210 // ldur q16, [x16, #40]
	WORD $0x3cc38211 // ldur q17, [x16, #56]
	WORD $0x4e913a12 // zip1 v18.4s, v16.4s, v17.4s
	WORD $0x4e917a13 // zip2 v19.4s, v16.4s, v17.4s
	WORD $0x3cc40274 // ldur q20, [x19, #64]
	WORD $0x3cc50275 // ldur q21, [x19, #80]
	WORD $0x3cc60276 // ldur q22, [x19, #96]
	WORD $0x3cc70277 // ldur q23, [x19, #112]
	WORD $0x4e92a680 // smmla v0.4s, v20.16b, v18.16b
	WORD $0x4e93a681 // smmla v1.4s, v20.16b, v19.16b
	WORD $0x4e92a6a2 // smmla v2.4s, v21.16b, v18.16b
	WORD $0x4e93a6a3 // smmla v3.4s, v21.16b, v19.16b
	WORD $0x4e92a6c4 // smmla v4.4s, v22.16b, v18.16b
	WORD $0x4e93a6c5 // smmla v5.4s, v22.16b, v19.16b
	WORD $0x4e92a6e6 // smmla v6.4s, v23.16b, v18.16b
	WORD $0x4e93a6e7 // smmla v7.4s, v23.16b, v19.16b
	WORD $0x3cc48210 // ldur q16, [x16, #72]
	WORD $0x3cc58211 // ldur q17, [x16, #88]
	WORD $0x4e913a12 // zip1 v18.4s, v16.4s, v17.4s
	WORD $0x4e917a13 // zip2 v19.4s, v16.4s, v17.4s
	WORD $0x3cc80274 // ldur q20, [x19, #128]
	WORD $0x3cc90275 // ldur q21, [x19, #144]
	WORD $0x3cca0276 // ldur q22, [x19, #160]
	WORD $0x3ccb0277 // ldur q23, [x19, #176]
	WORD $0x4e92a680 // smmla v0.4s, v20.16b, v18.16b
	WORD $0x4e93a681 // smmla v1.4s, v20.16b, v19.16b
	WORD $0x4e92a6a2 // smmla v2.4s, v21.16b, v18.16b
	WORD $0x4e93a6a3 // smmla v3.4s, v21.16b, v19.16b
	WORD $0x4e92a6c4 // smmla v4.4s, v22.16b, v18.16b
	WORD $0x4e93a6c5 // smmla v5.4s, v22.16b, v19.16b
	WORD $0x4e92a6e6 // smmla v6.4s, v23.16b, v18.16b
	WORD $0x4e93a6e7 // smmla v7.4s, v23.16b, v19.16b
	WORD $0x3cc68210 // ldur q16, [x16, #104]
	WORD $0x3cc78211 // ldur q17, [x16, #120]
	WORD $0x4e913a12 // zip1 v18.4s, v16.4s, v17.4s
	WORD $0x4e917a13 // zip2 v19.4s, v16.4s, v17.4s
	WORD $0x3ccc0274 // ldur q20, [x19, #192]
	WORD $0x3ccd0275 // ldur q21, [x19, #208]
	WORD $0x3cce0276 // ldur q22, [x19, #224]
	WORD $0x3ccf0277 // ldur q23, [x19, #240]
	WORD $0x4e92a680 // smmla v0.4s, v20.16b, v18.16b
	WORD $0x4e93a681 // smmla v1.4s, v20.16b, v19.16b
	WORD $0x4e92a6a2 // smmla v2.4s, v21.16b, v18.16b
	WORD $0x4e93a6a3 // smmla v3.4s, v21.16b, v19.16b
	WORD $0x4e92a6c4 // smmla v4.4s, v22.16b, v18.16b
	WORD $0x4e93a6c5 // smmla v5.4s, v22.16b, v19.16b
	WORD $0x4e92a6e6 // smmla v6.4s, v23.16b, v18.16b
	WORD $0x4e93a6e7 // smmla v7.4s, v23.16b, v19.16b
	WORD $0xfc400210 // ldur d16, [x16, #0]
	WORD $0x0e217a10 // fcvtl v16.4s, v16.4h
	WORD $0x4e080612 // dup v18.2d, v16.d[0]
	WORD $0x4e180613 // dup v19.2d, v16.d[1]
	WORD $0xfc400231 // ldur d17, [x17, #0]
	WORD $0x0e217a31 // fcvtl v17.4s, v17.4h
	WORD $0x4e913a34 // zip1 v20.4s, v17.4s, v17.4s
	WORD $0x4e917a35 // zip2 v21.4s, v17.4s, v17.4s
	WORD $0xfc400371 // ldur d17, [x27, #0]
	WORD $0x0e217a31 // fcvtl v17.4s, v17.4h
	WORD $0x4e913a36 // zip1 v22.4s, v17.4s, v17.4s
	WORD $0x4e917a37 // zip2 v23.4s, v17.4s, v17.4s
	WORD $0x4e21d800 // scvtf v0.4s, v0.4s
	WORD $0x6e32dc00 // fmul v0.4s, v0.4s, v18.4s
	WORD $0x4e34cc18 // fmla v24.4s, v0.4s, v20.4s
	WORD $0x4e21d821 // scvtf v1.4s, v1.4s
	WORD $0x6e33dc21 // fmul v1.4s, v1.4s, v19.4s
	WORD $0x4e34cc39 // fmla v25.4s, v1.4s, v20.4s
	WORD $0x4e21d842 // scvtf v2.4s, v2.4s
	WORD $0x6e32dc42 // fmul v2.4s, v2.4s, v18.4s
	WORD $0x4e35cc5a // fmla v26.4s, v2.4s, v21.4s
	WORD $0x4e21d863 // scvtf v3.4s, v3.4s
	WORD $0x6e33dc63 // fmul v3.4s, v3.4s, v19.4s
	WORD $0x4e35cc7b // fmla v27.4s, v3.4s, v21.4s
	WORD $0x4e21d884 // scvtf v4.4s, v4.4s
	WORD $0x6e32dc84 // fmul v4.4s, v4.4s, v18.4s
	WORD $0x4e36cc9c // fmla v28.4s, v4.4s, v22.4s
	WORD $0x4e21d8a5 // scvtf v5.4s, v5.4s
	WORD $0x6e33dca5 // fmul v5.4s, v5.4s, v19.4s
	WORD $0x4e36ccbd // fmla v29.4s, v5.4s, v22.4s
	WORD $0x4e21d8c6 // scvtf v6.4s, v6.4s
	WORD $0x6e32dcc6 // fmul v6.4s, v6.4s, v18.4s
	WORD $0x4e37ccde // fmla v30.4s, v6.4s, v23.4s
	WORD $0x4e21d8e7 // scvtf v7.4s, v7.4s
	WORD $0x6e33dce7 // fmul v7.4s, v7.4s, v19.4s
	WORD $0x4e37ccff // fmla v31.4s, v7.4s, v23.4s
	ADD	$136, R16, R16
	ADD	$136, R17, R17
	ADD	$136, R27, R27
	ADD	$256, R19, R19
	SUBW	$1, R15, R15
	CBNZW	R15, gemmmblk
gemmmstore:
	MOVD	R14, R26
	WORD $0x4ed93b10 // zip1 v16.2d, v24.2d, v25.2d
	WORD $0x4ed97b11 // zip2 v17.2d, v24.2d, v25.2d
	WORD $0x3c800350 // stur q16, [x26, #0]
	ADD	R3, R26, R26
	WORD $0x3c800351 // stur q17, [x26, #0]
	ADD	R3, R26, R26
	WORD $0x4edb3b50 // zip1 v16.2d, v26.2d, v27.2d
	WORD $0x4edb7b51 // zip2 v17.2d, v26.2d, v27.2d
	WORD $0x3c800350 // stur q16, [x26, #0]
	ADD	R3, R26, R26
	WORD $0x3c800351 // stur q17, [x26, #0]
	ADD	R3, R26, R26
	WORD $0x4edd3b90 // zip1 v16.2d, v28.2d, v29.2d
	WORD $0x4edd7b91 // zip2 v17.2d, v28.2d, v29.2d
	WORD $0x3c800350 // stur q16, [x26, #0]
	ADD	R3, R26, R26
	WORD $0x3c800351 // stur q17, [x26, #0]
	ADD	R3, R26, R26
	WORD $0x4edf3bd0 // zip1 v16.2d, v30.2d, v31.2d
	WORD $0x4edf7bd1 // zip2 v17.2d, v30.2d, v31.2d
	WORD $0x3c800350 // stur q16, [x26, #0]
	ADD	R3, R26, R26
	WORD $0x3c800351 // stur q17, [x26, #0]
	ADD	R3, R26, R26
	ADD	R8, R13, R13
	ADD	$16, R14, R14
	SUBW	$1, R12, R12
	CBNZW	R12, gemmmx
	SUBW	R25, R24, R24
	MOVD	$136, R26
	MUL	R25, R26, R26
	ADD	R26, R9, R9
	CBNZW	R24, gemmmchunk
	ADD	R8<<1, R10, R10
	ADD	R23<<1, R11, R11
	SUBW	$2, R6, R6
	B	gemmm
gemmsdot:
	CBZW	R6, gemmdone
gemmy:
	MOVD	R22, R13
	MOVD	R11, R14
	MOVW	R7, R12
gemmx:
	WORD $0x4f00041c // movi v28.4s, #0
	WORD $0x4f00041d // movi v29.4s, #0
	WORD $0x4f00041e // movi v30.4s, #0
	WORD $0x4f00041f // movi v31.4s, #0
	MOVD	R13, R16
	MOVD	R10, R17
	MOVW	R1, R15
	CBZW	R15, gemmstore
gemmblk:
	WORD $0x4f000418 // movi v24.4s, #0
	WORD $0x4f000419 // movi v25.4s, #0
	WORD $0x4f00041a // movi v26.4s, #0
	WORD $0x4f00041b // movi v27.4s, #0
	WORD $0x3cc08200 // ldur q0, [x16, #8]
	WORD $0x3cc08221 // ldur q1, [x17, #8]
	WORD $0x4f81e018 // sdot v24.4s, v0.16b, v1.4b[0]
	WORD $0x4fa1e019 // sdot v25.4s, v0.16b, v1.4b[1]
	WORD $0x4f81e81a // sdot v26.4s, v0.16b, v1.4b[2]
	WORD $0x4fa1e81b // sdot v27.4s, v0.16b, v1.4b[3]
	WORD $0x3cc18200 // ldur q0, [x16, #24]
	WORD $0x3cc18221 // ldur q1, [x17, #24]
	WORD $0x4f81e018 // sdot v24.4s, v0.16b, v1.4b[0]
	WORD $0x4fa1e019 // sdot v25.4s, v0.16b, v1.4b[1]
	WORD $0x4f81e81a // sdot v26.4s, v0.16b, v1.4b[2]
	WORD $0x4fa1e81b // sdot v27.4s, v0.16b, v1.4b[3]
	WORD $0x3cc28200 // ldur q0, [x16, #40]
	WORD $0x3cc28221 // ldur q1, [x17, #40]
	WORD $0x4f81e018 // sdot v24.4s, v0.16b, v1.4b[0]
	WORD $0x4fa1e019 // sdot v25.4s, v0.16b, v1.4b[1]
	WORD $0x4f81e81a // sdot v26.4s, v0.16b, v1.4b[2]
	WORD $0x4fa1e81b // sdot v27.4s, v0.16b, v1.4b[3]
	WORD $0x3cc38200 // ldur q0, [x16, #56]
	WORD $0x3cc38221 // ldur q1, [x17, #56]
	WORD $0x4f81e018 // sdot v24.4s, v0.16b, v1.4b[0]
	WORD $0x4fa1e019 // sdot v25.4s, v0.16b, v1.4b[1]
	WORD $0x4f81e81a // sdot v26.4s, v0.16b, v1.4b[2]
	WORD $0x4fa1e81b // sdot v27.4s, v0.16b, v1.4b[3]
	WORD $0x3cc48200 // ldur q0, [x16, #72]
	WORD $0x3cc48221 // ldur q1, [x17, #72]
	WORD $0x4f81e018 // sdot v24.4s, v0.16b, v1.4b[0]
	WORD $0x4fa1e019 // sdot v25.4s, v0.16b, v1.4b[1]
	WORD $0x4f81e81a // sdot v26.4s, v0.16b, v1.4b[2]
	WORD $0x4fa1e81b // sdot v27.4s, v0.16b, v1.4b[3]
	WORD $0x3cc58200 // ldur q0, [x16, #88]
	WORD $0x3cc58221 // ldur q1, [x17, #88]
	WORD $0x4f81e018 // sdot v24.4s, v0.16b, v1.4b[0]
	WORD $0x4fa1e019 // sdot v25.4s, v0.16b, v1.4b[1]
	WORD $0x4f81e81a // sdot v26.4s, v0.16b, v1.4b[2]
	WORD $0x4fa1e81b // sdot v27.4s, v0.16b, v1.4b[3]
	WORD $0x3cc68200 // ldur q0, [x16, #104]
	WORD $0x3cc68221 // ldur q1, [x17, #104]
	WORD $0x4f81e018 // sdot v24.4s, v0.16b, v1.4b[0]
	WORD $0x4fa1e019 // sdot v25.4s, v0.16b, v1.4b[1]
	WORD $0x4f81e81a // sdot v26.4s, v0.16b, v1.4b[2]
	WORD $0x4fa1e81b // sdot v27.4s, v0.16b, v1.4b[3]
	WORD $0x3cc78200 // ldur q0, [x16, #120]
	WORD $0x3cc78221 // ldur q1, [x17, #120]
	WORD $0x4f81e018 // sdot v24.4s, v0.16b, v1.4b[0]
	WORD $0x4fa1e019 // sdot v25.4s, v0.16b, v1.4b[1]
	WORD $0x4f81e81a // sdot v26.4s, v0.16b, v1.4b[2]
	WORD $0x4fa1e81b // sdot v27.4s, v0.16b, v1.4b[3]
	WORD $0xfc400202 // ldur d2, [x16, #0]
	WORD $0x0e217842 // fcvtl v2.4s, v2.4h
	WORD $0xfc400223 // ldur d3, [x17, #0]
	WORD $0x0e217863 // fcvtl v3.4s, v3.4h
	WORD $0x4e21db18 // scvtf v24.4s, v24.4s
	WORD $0x6e22df18 // fmul v24.4s, v24.4s, v2.4s
	WORD $0x4f83131c // fmla v28.4s, v24.4s, v3.s[0]
	WORD $0x4e21db39 // scvtf v25.4s, v25.4s
	WORD $0x6e22df39 // fmul v25.4s, v25.4s, v2.4s
	WORD $0x4fa3133d // fmla v29.4s, v25.4s, v3.s[1]
	WORD $0x4e21db5a // scvtf v26.4s, v26.4s
	WORD $0x6e22df5a // fmul v26.4s, v26.4s, v2.4s
	WORD $0x4f831b5e // fmla v30.4s, v26.4s, v3.s[2]
	WORD $0x4e21db7b // scvtf v27.4s, v27.4s
	WORD $0x6e22df7b // fmul v27.4s, v27.4s, v2.4s
	WORD $0x4fa31b7f // fmla v31.4s, v27.4s, v3.s[3]
	ADD	$136, R16, R16
	ADD	$136, R17, R17
	SUBW	$1, R15, R15
	CBNZW	R15, gemmblk
gemmstore:
	WORD $0x3c8001dc // stur q28, [x14, #0]
	ADD	R14, R3, R26
	WORD $0x3c80035d // stur q29, [x26, #0]
	ADD	R26, R3, R26
	WORD $0x3c80035e // stur q30, [x26, #0]
	ADD	R26, R3, R26
	WORD $0x3c80035f // stur q31, [x26, #0]
	ADD	R8, R13, R13
	ADD	$16, R14, R14
	SUBW	$1, R12, R12
	CBNZW	R12, gemmx
	ADD	R8, R10, R10
	ADD	R23, R11, R11
	SUBW	$1, R6, R6
	CBNZW	R6, gemmy
gemmdone:
	RET
gemmoob:
	B	ovr_oob
