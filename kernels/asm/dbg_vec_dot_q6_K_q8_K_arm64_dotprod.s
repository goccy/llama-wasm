// dbg_vec_dot_q6_K_q8_K: q6_K x q8_K dot, SDOT per 16-quant group with MLA-by-element scales; 2x2 tile for nrc == 2.
	WORD $0x4f000400 // movi v0.4s, #0
	MOVW	l0+8(FP), R1
	LSRW	$8, R1, R1
	MOVW	l7+64(FP), R6
	MOVD	l1+16(FP), R2
	MOVD	l3+32(FP), R3
	MOVD	l5+48(FP), R4
	CMPW	$2, R6
	BEQ	q6ktile_tilepro
	ADD	$4, R2, R27
	CMP	R27, R21
	BLO	q6koob
	ADD	R20, R2, R2
	CBZW	R1, q6kzero
	MOVD	$210, R26
	MUL	R1, R26, R26
	ADD	R3, R26, R27
	CMP	R27, R21
	BLO	q6koob
	MOVD	$292, R26
	MUL	R1, R26, R26
	ADD	R4, R26, R27
	CMP	R27, R21
	BLO	q6koob
	ADD	R20, R3, R3
	ADD	R20, R4, R4
	B	q6ktile_body
q6ktile_tilepro:
	MOVD	l2+24(FP), R8
	LSL	$2, R8, R8
	ADD	R2, R8, R8
	ADD	$8, R8, R27
	CMP	R27, R21
	BLO	q6koob
	MOVD	l4+40(FP), R5
	ADD	R3, R5, R5
	MOVD	l6+56(FP), R7
	ADD	R4, R7, R7
	MOVD	$210, R26
	MUL	R1, R26, R26
	ADD	R5, R26, R27
	CMP	R27, R21
	BLO	q6koob
	MOVD	$292, R26
	MUL	R1, R26, R26
	ADD	R7, R26, R27
	CMP	R27, R21
	BLO	q6koob
	ADD	R20, R2, R2
	ADD	R20, R8, R8
	ADD	R20, R3, R3
	ADD	R20, R4, R4
	ADD	R20, R5, R5
	ADD	R20, R7, R7
	CBZW	R1, q6kzero
	B	q6ktile
q6ktile_body:
	WORD $0x4f00e5f0 // movi v16.16b, #15
	WORD $0x4f00e471 // movi v17.16b, #3
q6kblk:
	WORD $0x3ccc0062 // ldur q2, [x3, #192]
	WORD $0x4f08a443 // sshll2 v3.8h, v2.16b, #0
	WORD $0x0f08a442 // sshll v2.8h, v2.8b, #0
	WORD $0x0f10a444 // sshll v4.4s, v2.4h, #0
	WORD $0x4f10a445 // sshll2 v5.4s, v2.8h, #0
	WORD $0x0f10a466 // sshll v6.4s, v3.4h, #0
	WORD $0x4f10a467 // sshll2 v7.4s, v3.8h, #0
	WORD $0x4f000401 // movi v1.4s, #0
	WORD $0x3cc80072 // ldur q18, [x3, #128]
	WORD $0x3cc90073 // ldur q19, [x3, #144]
	WORD $0x3cc00074 // ldur q20, [x3, #0]
	WORD $0x3cc10075 // ldur q21, [x3, #16]
	WORD $0x3cc20076 // ldur q22, [x3, #32]
	WORD $0x3cc30077 // ldur q23, [x3, #48]
	WORD $0x3cc04098 // ldur q24, [x4, #4]
	WORD $0x3cc14099 // ldur q25, [x4, #20]
	WORD $0x3cc2409a // ldur q26, [x4, #36]
	WORD $0x3cc3409b // ldur q27, [x4, #52]
	WORD $0x4e311e5c // and v28.16b, v18.16b, v17.16b
	WORD $0x4e311e7d // and v29.16b, v19.16b, v17.16b
	WORD $0x6f0e065e // ushr v30.16b, v18.16b, #2
	WORD $0x6f0e067f // ushr v31.16b, v19.16b, #2
	WORD $0x4e311fde // and v30.16b, v30.16b, v17.16b
	WORD $0x4e311fff // and v31.16b, v31.16b, v17.16b
	WORD $0x4f0c579c // shl v28.16b, v28.16b, #4
	WORD $0x4f0c57bd // shl v29.16b, v29.16b, #4
	WORD $0x4f0c57de // shl v30.16b, v30.16b, #4
	WORD $0x4f0c57ff // shl v31.16b, v31.16b, #4
	WORD $0x4e301e8c // and v12.16b, v20.16b, v16.16b
	WORD $0x4ebc1d8c // orr v12.16b, v12.16b, v28.16b
	WORD $0x4e301ead // and v13.16b, v21.16b, v16.16b
	WORD $0x4ebd1dad // orr v13.16b, v13.16b, v29.16b
	WORD $0x4e301ece // and v14.16b, v22.16b, v16.16b
	WORD $0x4ebe1dce // orr v14.16b, v14.16b, v30.16b
	WORD $0x4e301eef // and v15.16b, v23.16b, v16.16b
	WORD $0x4ebf1def // orr v15.16b, v15.16b, v31.16b
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4e989588 // sdot v8.4s, v12.16b, v24.16b
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4e9995a9 // sdot v9.4s, v13.16b, v25.16b
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4e9a95ca // sdot v10.4s, v14.16b, v26.16b
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x4e9b95eb // sdot v11.4s, v15.16b, v27.16b
	WORD $0x6f840101 // mla v1.4s, v8.4s, v4.s[0]
	WORD $0x6fa40121 // mla v1.4s, v9.4s, v4.s[1]
	WORD $0x6f840941 // mla v1.4s, v10.4s, v4.s[2]
	WORD $0x6fa40961 // mla v1.4s, v11.4s, v4.s[3]
	WORD $0x3cc44098 // ldur q24, [x4, #68]
	WORD $0x3cc54099 // ldur q25, [x4, #84]
	WORD $0x3cc6409a // ldur q26, [x4, #100]
	WORD $0x3cc7409b // ldur q27, [x4, #116]
	WORD $0x6f0c065c // ushr v28.16b, v18.16b, #4
	WORD $0x6f0c067d // ushr v29.16b, v19.16b, #4
	WORD $0x6f0a065e // ushr v30.16b, v18.16b, #6
	WORD $0x6f0a067f // ushr v31.16b, v19.16b, #6
	WORD $0x4e311f9c // and v28.16b, v28.16b, v17.16b
	WORD $0x4e311fbd // and v29.16b, v29.16b, v17.16b
	WORD $0x4f0c579c // shl v28.16b, v28.16b, #4
	WORD $0x4f0c57bd // shl v29.16b, v29.16b, #4
	WORD $0x4f0c57de // shl v30.16b, v30.16b, #4
	WORD $0x4f0c57ff // shl v31.16b, v31.16b, #4
	WORD $0x6f0c068c // ushr v12.16b, v20.16b, #4
	WORD $0x4ebc1d8c // orr v12.16b, v12.16b, v28.16b
	WORD $0x6f0c06ad // ushr v13.16b, v21.16b, #4
	WORD $0x4ebd1dad // orr v13.16b, v13.16b, v29.16b
	WORD $0x6f0c06ce // ushr v14.16b, v22.16b, #4
	WORD $0x4ebe1dce // orr v14.16b, v14.16b, v30.16b
	WORD $0x6f0c06ef // ushr v15.16b, v23.16b, #4
	WORD $0x4ebf1def // orr v15.16b, v15.16b, v31.16b
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4e989588 // sdot v8.4s, v12.16b, v24.16b
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4e9995a9 // sdot v9.4s, v13.16b, v25.16b
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4e9a95ca // sdot v10.4s, v14.16b, v26.16b
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x4e9b95eb // sdot v11.4s, v15.16b, v27.16b
	WORD $0x6f850101 // mla v1.4s, v8.4s, v5.s[0]
	WORD $0x6fa50121 // mla v1.4s, v9.4s, v5.s[1]
	WORD $0x6f850941 // mla v1.4s, v10.4s, v5.s[2]
	WORD $0x6fa50961 // mla v1.4s, v11.4s, v5.s[3]
	WORD $0x3cca0072 // ldur q18, [x3, #160]
	WORD $0x3ccb0073 // ldur q19, [x3, #176]
	WORD $0x3cc40074 // ldur q20, [x3, #64]
	WORD $0x3cc50075 // ldur q21, [x3, #80]
	WORD $0x3cc60076 // ldur q22, [x3, #96]
	WORD $0x3cc70077 // ldur q23, [x3, #112]
	WORD $0x3cc84098 // ldur q24, [x4, #132]
	WORD $0x3cc94099 // ldur q25, [x4, #148]
	WORD $0x3cca409a // ldur q26, [x4, #164]
	WORD $0x3ccb409b // ldur q27, [x4, #180]
	WORD $0x4e311e5c // and v28.16b, v18.16b, v17.16b
	WORD $0x4e311e7d // and v29.16b, v19.16b, v17.16b
	WORD $0x6f0e065e // ushr v30.16b, v18.16b, #2
	WORD $0x6f0e067f // ushr v31.16b, v19.16b, #2
	WORD $0x4e311fde // and v30.16b, v30.16b, v17.16b
	WORD $0x4e311fff // and v31.16b, v31.16b, v17.16b
	WORD $0x4f0c579c // shl v28.16b, v28.16b, #4
	WORD $0x4f0c57bd // shl v29.16b, v29.16b, #4
	WORD $0x4f0c57de // shl v30.16b, v30.16b, #4
	WORD $0x4f0c57ff // shl v31.16b, v31.16b, #4
	WORD $0x4e301e8c // and v12.16b, v20.16b, v16.16b
	WORD $0x4ebc1d8c // orr v12.16b, v12.16b, v28.16b
	WORD $0x4e301ead // and v13.16b, v21.16b, v16.16b
	WORD $0x4ebd1dad // orr v13.16b, v13.16b, v29.16b
	WORD $0x4e301ece // and v14.16b, v22.16b, v16.16b
	WORD $0x4ebe1dce // orr v14.16b, v14.16b, v30.16b
	WORD $0x4e301eef // and v15.16b, v23.16b, v16.16b
	WORD $0x4ebf1def // orr v15.16b, v15.16b, v31.16b
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4e989588 // sdot v8.4s, v12.16b, v24.16b
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4e9995a9 // sdot v9.4s, v13.16b, v25.16b
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4e9a95ca // sdot v10.4s, v14.16b, v26.16b
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x4e9b95eb // sdot v11.4s, v15.16b, v27.16b
	WORD $0x6f860101 // mla v1.4s, v8.4s, v6.s[0]
	WORD $0x6fa60121 // mla v1.4s, v9.4s, v6.s[1]
	WORD $0x6f860941 // mla v1.4s, v10.4s, v6.s[2]
	WORD $0x6fa60961 // mla v1.4s, v11.4s, v6.s[3]
	WORD $0x3ccc4098 // ldur q24, [x4, #196]
	WORD $0x3ccd4099 // ldur q25, [x4, #212]
	WORD $0x3cce409a // ldur q26, [x4, #228]
	WORD $0x3ccf409b // ldur q27, [x4, #244]
	WORD $0x6f0c065c // ushr v28.16b, v18.16b, #4
	WORD $0x6f0c067d // ushr v29.16b, v19.16b, #4
	WORD $0x6f0a065e // ushr v30.16b, v18.16b, #6
	WORD $0x6f0a067f // ushr v31.16b, v19.16b, #6
	WORD $0x4e311f9c // and v28.16b, v28.16b, v17.16b
	WORD $0x4e311fbd // and v29.16b, v29.16b, v17.16b
	WORD $0x4f0c579c // shl v28.16b, v28.16b, #4
	WORD $0x4f0c57bd // shl v29.16b, v29.16b, #4
	WORD $0x4f0c57de // shl v30.16b, v30.16b, #4
	WORD $0x4f0c57ff // shl v31.16b, v31.16b, #4
	WORD $0x6f0c068c // ushr v12.16b, v20.16b, #4
	WORD $0x4ebc1d8c // orr v12.16b, v12.16b, v28.16b
	WORD $0x6f0c06ad // ushr v13.16b, v21.16b, #4
	WORD $0x4ebd1dad // orr v13.16b, v13.16b, v29.16b
	WORD $0x6f0c06ce // ushr v14.16b, v22.16b, #4
	WORD $0x4ebe1dce // orr v14.16b, v14.16b, v30.16b
	WORD $0x6f0c06ef // ushr v15.16b, v23.16b, #4
	WORD $0x4ebf1def // orr v15.16b, v15.16b, v31.16b
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4e989588 // sdot v8.4s, v12.16b, v24.16b
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4e9995a9 // sdot v9.4s, v13.16b, v25.16b
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4e9a95ca // sdot v10.4s, v14.16b, v26.16b
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x4e9b95eb // sdot v11.4s, v15.16b, v27.16b
	WORD $0x6f870101 // mla v1.4s, v8.4s, v7.s[0]
	WORD $0x6fa70121 // mla v1.4s, v9.4s, v7.s[1]
	WORD $0x6f870941 // mla v1.4s, v10.4s, v7.s[2]
	WORD $0x6fa70961 // mla v1.4s, v11.4s, v7.s[3]
	ADD	$256, R4, R5
	WORD $0x3cc040a8 // ldur q8, [x5, #4]
	WORD $0x3cc140a9 // ldur q9, [x5, #20]
	WORD $0x0e62c10a // smull v10.4s, v8.4h, v2.4h
	WORD $0x4e62810a // smlal2 v10.4s, v8.8h, v2.8h
	WORD $0x0e63812a // smlal v10.4s, v9.4h, v3.4h
	WORD $0x4e63812a // smlal2 v10.4s, v9.8h, v3.8h
	WORD $0xbc40008b // ldur s11, [x4, #0]
	WORD $0x7c4d006d // ldur h13, [x3, #208]
	WORD $0x1ee241ad // fcvt s13, h13
	WORD $0x1e2b09ad // fmul s13, s13, s11
	WORD $0x4f25554a // shl v10.4s, v10.4s, #5
	WORD $0x4eb1b94a // addv s10, v10.4s
	WORD $0x4e21d94a // scvtf v10.4s, v10.4s
	WORD $0x4f8d5140 // fmls v0.4s, v10.4s, v13.s[0]
	WORD $0x4eb1b821 // addv s1, v1.4s
	WORD $0x4e21d821 // scvtf v1.4s, v1.4s
	WORD $0x4f8d1020 // fmla v0.4s, v1.4s, v13.s[0]
	ADD	$210, R3, R3
	ADD	$292, R4, R4
	SUBW	$1, R1, R1
	CBNZW	R1, q6kblk
q6kzero:
	CMPW	$2, R6
	BEQ	q6ktilestore
	WORD $0x6e20d400 // faddp v0.4s, v0.4s, v0.4s
	WORD $0x7e30d800 // faddp s0, v0.2s
	FMOVS	F0, (R2)
	RET
q6ktile:
	WORD $0x4f00e5ed // movi v13.16b, #15
	WORD $0x4f01e60e // movi v14.16b, #48
q6ktileblk:
	WORD $0x3ccc0065 // ldur q5, [x3, #192]
	WORD $0x4f08a4a6 // sshll2 v6.8h, v5.16b, #0
	WORD $0x0f08a4a5 // sshll v5.8h, v5.8b, #0
	WORD $0x3ccc00a9 // ldur q9, [x5, #192]
	WORD $0x4f08a52a // sshll2 v10.8h, v9.16b, #0
	WORD $0x0f08a529 // sshll v9.8h, v9.8b, #0
	ADD	$256, R4, R9
	WORD $0x3cc0413c // ldur q28, [x9, #4]
	WORD $0x3cc1413d // ldur q29, [x9, #20]
	ADD	$256, R7, R9
	WORD $0x3cc04130 // ldur q16, [x9, #4]
	WORD $0x3cc14131 // ldur q17, [x9, #20]
	WORD $0x0e65c38f // smull v15.4s, v28.4h, v5.4h
	WORD $0x4e65838f // smlal2 v15.4s, v28.8h, v5.8h
	WORD $0x0e6683af // smlal v15.4s, v29.4h, v6.4h
	WORD $0x4e6683af // smlal2 v15.4s, v29.8h, v6.8h
	WORD $0x4eb1b9ef // addv s15, v15.4s
	WORD $0x6e0405f2 // mov v18.s[0], v15.s[0]
	WORD $0x0e69c38f // smull v15.4s, v28.4h, v9.4h
	WORD $0x4e69838f // smlal2 v15.4s, v28.8h, v9.8h
	WORD $0x0e6a83af // smlal v15.4s, v29.4h, v10.4h
	WORD $0x4e6a83af // smlal2 v15.4s, v29.8h, v10.8h
	WORD $0x4eb1b9ef // addv s15, v15.4s
	WORD $0x6e0c05f2 // mov v18.s[1], v15.s[0]
	WORD $0x0e65c20f // smull v15.4s, v16.4h, v5.4h
	WORD $0x4e65820f // smlal2 v15.4s, v16.8h, v5.8h
	WORD $0x0e66822f // smlal v15.4s, v17.4h, v6.4h
	WORD $0x4e66822f // smlal2 v15.4s, v17.8h, v6.8h
	WORD $0x4eb1b9ef // addv s15, v15.4s
	WORD $0x6e1405f2 // mov v18.s[2], v15.s[0]
	WORD $0x0e69c20f // smull v15.4s, v16.4h, v9.4h
	WORD $0x4e69820f // smlal2 v15.4s, v16.8h, v9.8h
	WORD $0x0e6a822f // smlal v15.4s, v17.4h, v10.4h
	WORD $0x4e6a822f // smlal2 v15.4s, v17.8h, v10.8h
	WORD $0x4eb1b9ef // addv s15, v15.4s
	WORD $0x6e1c05f2 // mov v18.s[3], v15.s[0]
	WORD $0x0f10a4c7 // sshll v7.4s, v6.4h, #0
	WORD $0x4f10a4c8 // sshll2 v8.4s, v6.8h, #0
	WORD $0x4f10a4a6 // sshll2 v6.4s, v5.8h, #0
	WORD $0x0f10a4a5 // sshll v5.4s, v5.4h, #0
	WORD $0x0f10a54b // sshll v11.4s, v10.4h, #0
	WORD $0x4f10a54c // sshll2 v12.4s, v10.8h, #0
	WORD $0x4f10a52a // sshll2 v10.4s, v9.8h, #0
	WORD $0x0f10a529 // sshll v9.4s, v9.4h, #0
	WORD $0xbc40009f // ldur s31, [x4, #0]
	WORD $0xbc4000ef // ldur s15, [x7, #0]
	WORD $0x6e0c05ff // mov v31.s[1], v15.s[0]
	WORD $0x4e9f3bff // zip1 v31.4s, v31.4s, v31.4s
	WORD $0x7c4d007e // ldur h30, [x3, #208]
	WORD $0x7c4d00af // ldur h15, [x5, #208]
	WORD $0x1ee243de // fcvt s30, h30
	WORD $0x1ee241ef // fcvt s15, h15
	WORD $0x6e0c05fe // mov v30.s[1], v15.s[0]
	WORD $0x4e0807de // dup v30.2d, v30.d[0]
	WORD $0x6e3fdfde // fmul v30.4s, v30.4s, v31.4s
	WORD $0x4f255652 // shl v18.4s, v18.4s, #5
	WORD $0x4e21da52 // scvtf v18.4s, v18.4s
	WORD $0x4ebece40 // fmls v0.4s, v18.4s, v30.4s
	WORD $0x4f000401 // movi v1.4s, #0
	WORD $0x4f000402 // movi v2.4s, #0
	WORD $0x4f000403 // movi v3.4s, #0
	WORD $0x4f000404 // movi v4.4s, #0
	WORD $0x3cc80078 // ldur q24, [x3, #128]
	WORD $0x3cc90079 // ldur q25, [x3, #144]
	WORD $0x3cc800ba // ldur q26, [x5, #128]
	WORD $0x3cc900bb // ldur q27, [x5, #144]
	WORD $0x3cc00070 // ldur q16, [x3, #0]
	WORD $0x3cc10071 // ldur q17, [x3, #16]
	WORD $0x3cc20072 // ldur q18, [x3, #32]
	WORD $0x3cc30073 // ldur q19, [x3, #48]
	WORD $0x4f0c571f // shl v31.16b, v24.16b, #4
	WORD $0x4e2e1fff // and v31.16b, v31.16b, v14.16b
	WORD $0x4e2d1e10 // and v16.16b, v16.16b, v13.16b
	WORD $0x4ebf1e10 // orr v16.16b, v16.16b, v31.16b
	WORD $0x4f0c573f // shl v31.16b, v25.16b, #4
	WORD $0x4e2e1fff // and v31.16b, v31.16b, v14.16b
	WORD $0x4e2d1e31 // and v17.16b, v17.16b, v13.16b
	WORD $0x4ebf1e31 // orr v17.16b, v17.16b, v31.16b
	WORD $0x4f0a571f // shl v31.16b, v24.16b, #2
	WORD $0x4e2e1fff // and v31.16b, v31.16b, v14.16b
	WORD $0x4e2d1e52 // and v18.16b, v18.16b, v13.16b
	WORD $0x4ebf1e52 // orr v18.16b, v18.16b, v31.16b
	WORD $0x4f0a573f // shl v31.16b, v25.16b, #2
	WORD $0x4e2e1fff // and v31.16b, v31.16b, v14.16b
	WORD $0x4e2d1e73 // and v19.16b, v19.16b, v13.16b
	WORD $0x4ebf1e73 // orr v19.16b, v19.16b, v31.16b
	WORD $0x3cc000b4 // ldur q20, [x5, #0]
	WORD $0x3cc100b5 // ldur q21, [x5, #16]
	WORD $0x3cc200b6 // ldur q22, [x5, #32]
	WORD $0x3cc300b7 // ldur q23, [x5, #48]
	WORD $0x4f0c575f // shl v31.16b, v26.16b, #4
	WORD $0x4e2e1fff // and v31.16b, v31.16b, v14.16b
	WORD $0x4e2d1e94 // and v20.16b, v20.16b, v13.16b
	WORD $0x4ebf1e94 // orr v20.16b, v20.16b, v31.16b
	WORD $0x4f0c577f // shl v31.16b, v27.16b, #4
	WORD $0x4e2e1fff // and v31.16b, v31.16b, v14.16b
	WORD $0x4e2d1eb5 // and v21.16b, v21.16b, v13.16b
	WORD $0x4ebf1eb5 // orr v21.16b, v21.16b, v31.16b
	WORD $0x4f0a575f // shl v31.16b, v26.16b, #2
	WORD $0x4e2e1fff // and v31.16b, v31.16b, v14.16b
	WORD $0x4e2d1ed6 // and v22.16b, v22.16b, v13.16b
	WORD $0x4ebf1ed6 // orr v22.16b, v22.16b, v31.16b
	WORD $0x4f0a577f // shl v31.16b, v27.16b, #2
	WORD $0x4e2e1fff // and v31.16b, v31.16b, v14.16b
	WORD $0x4e2d1ef7 // and v23.16b, v23.16b, v13.16b
	WORD $0x4ebf1ef7 // orr v23.16b, v23.16b, v31.16b
	WORD $0x3cc0409c // ldur q28, [x4, #4]
	WORD $0x3cc040fd // ldur q29, [x7, #4]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9c960f // sdot v15.4s, v16.16b, v28.16b
	WORD $0x6f8501e1 // mla v1.4s, v15.4s, v5.s[0]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9c968f // sdot v15.4s, v20.16b, v28.16b
	WORD $0x6f8901e2 // mla v2.4s, v15.4s, v9.s[0]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9d960f // sdot v15.4s, v16.16b, v29.16b
	WORD $0x6f8501e3 // mla v3.4s, v15.4s, v5.s[0]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9d968f // sdot v15.4s, v20.16b, v29.16b
	WORD $0x6f8901e4 // mla v4.4s, v15.4s, v9.s[0]
	WORD $0x3cc1409c // ldur q28, [x4, #20]
	WORD $0x3cc140fd // ldur q29, [x7, #20]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9c962f // sdot v15.4s, v17.16b, v28.16b
	WORD $0x6fa501e1 // mla v1.4s, v15.4s, v5.s[1]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9c96af // sdot v15.4s, v21.16b, v28.16b
	WORD $0x6fa901e2 // mla v2.4s, v15.4s, v9.s[1]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9d962f // sdot v15.4s, v17.16b, v29.16b
	WORD $0x6fa501e3 // mla v3.4s, v15.4s, v5.s[1]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9d96af // sdot v15.4s, v21.16b, v29.16b
	WORD $0x6fa901e4 // mla v4.4s, v15.4s, v9.s[1]
	WORD $0x3cc2409c // ldur q28, [x4, #36]
	WORD $0x3cc240fd // ldur q29, [x7, #36]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9c964f // sdot v15.4s, v18.16b, v28.16b
	WORD $0x6f8509e1 // mla v1.4s, v15.4s, v5.s[2]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9c96cf // sdot v15.4s, v22.16b, v28.16b
	WORD $0x6f8909e2 // mla v2.4s, v15.4s, v9.s[2]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9d964f // sdot v15.4s, v18.16b, v29.16b
	WORD $0x6f8509e3 // mla v3.4s, v15.4s, v5.s[2]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9d96cf // sdot v15.4s, v22.16b, v29.16b
	WORD $0x6f8909e4 // mla v4.4s, v15.4s, v9.s[2]
	WORD $0x3cc3409c // ldur q28, [x4, #52]
	WORD $0x3cc340fd // ldur q29, [x7, #52]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9c966f // sdot v15.4s, v19.16b, v28.16b
	WORD $0x6fa509e1 // mla v1.4s, v15.4s, v5.s[3]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9c96ef // sdot v15.4s, v23.16b, v28.16b
	WORD $0x6fa909e2 // mla v2.4s, v15.4s, v9.s[3]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9d966f // sdot v15.4s, v19.16b, v29.16b
	WORD $0x6fa509e3 // mla v3.4s, v15.4s, v5.s[3]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9d96ef // sdot v15.4s, v23.16b, v29.16b
	WORD $0x6fa909e4 // mla v4.4s, v15.4s, v9.s[3]
	WORD $0x3cc00070 // ldur q16, [x3, #0]
	WORD $0x3cc10071 // ldur q17, [x3, #16]
	WORD $0x3cc20072 // ldur q18, [x3, #32]
	WORD $0x3cc30073 // ldur q19, [x3, #48]
	WORD $0x4e2e1f1f // and v31.16b, v24.16b, v14.16b
	WORD $0x6f0c0610 // ushr v16.16b, v16.16b, #4
	WORD $0x4ebf1e10 // orr v16.16b, v16.16b, v31.16b
	WORD $0x4e2e1f3f // and v31.16b, v25.16b, v14.16b
	WORD $0x6f0c0631 // ushr v17.16b, v17.16b, #4
	WORD $0x4ebf1e31 // orr v17.16b, v17.16b, v31.16b
	WORD $0x6f0e071f // ushr v31.16b, v24.16b, #2
	WORD $0x4e2e1fff // and v31.16b, v31.16b, v14.16b
	WORD $0x6f0c0652 // ushr v18.16b, v18.16b, #4
	WORD $0x4ebf1e52 // orr v18.16b, v18.16b, v31.16b
	WORD $0x6f0e073f // ushr v31.16b, v25.16b, #2
	WORD $0x4e2e1fff // and v31.16b, v31.16b, v14.16b
	WORD $0x6f0c0673 // ushr v19.16b, v19.16b, #4
	WORD $0x4ebf1e73 // orr v19.16b, v19.16b, v31.16b
	WORD $0x3cc000b4 // ldur q20, [x5, #0]
	WORD $0x3cc100b5 // ldur q21, [x5, #16]
	WORD $0x3cc200b6 // ldur q22, [x5, #32]
	WORD $0x3cc300b7 // ldur q23, [x5, #48]
	WORD $0x4e2e1f5f // and v31.16b, v26.16b, v14.16b
	WORD $0x6f0c0694 // ushr v20.16b, v20.16b, #4
	WORD $0x4ebf1e94 // orr v20.16b, v20.16b, v31.16b
	WORD $0x4e2e1f7f // and v31.16b, v27.16b, v14.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x4ebf1eb5 // orr v21.16b, v21.16b, v31.16b
	WORD $0x6f0e075f // ushr v31.16b, v26.16b, #2
	WORD $0x4e2e1fff // and v31.16b, v31.16b, v14.16b
	WORD $0x6f0c06d6 // ushr v22.16b, v22.16b, #4
	WORD $0x4ebf1ed6 // orr v22.16b, v22.16b, v31.16b
	WORD $0x6f0e077f // ushr v31.16b, v27.16b, #2
	WORD $0x4e2e1fff // and v31.16b, v31.16b, v14.16b
	WORD $0x6f0c06f7 // ushr v23.16b, v23.16b, #4
	WORD $0x4ebf1ef7 // orr v23.16b, v23.16b, v31.16b
	WORD $0x3cc4409c // ldur q28, [x4, #68]
	WORD $0x3cc440fd // ldur q29, [x7, #68]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9c960f // sdot v15.4s, v16.16b, v28.16b
	WORD $0x6f8601e1 // mla v1.4s, v15.4s, v6.s[0]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9c968f // sdot v15.4s, v20.16b, v28.16b
	WORD $0x6f8a01e2 // mla v2.4s, v15.4s, v10.s[0]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9d960f // sdot v15.4s, v16.16b, v29.16b
	WORD $0x6f8601e3 // mla v3.4s, v15.4s, v6.s[0]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9d968f // sdot v15.4s, v20.16b, v29.16b
	WORD $0x6f8a01e4 // mla v4.4s, v15.4s, v10.s[0]
	WORD $0x3cc5409c // ldur q28, [x4, #84]
	WORD $0x3cc540fd // ldur q29, [x7, #84]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9c962f // sdot v15.4s, v17.16b, v28.16b
	WORD $0x6fa601e1 // mla v1.4s, v15.4s, v6.s[1]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9c96af // sdot v15.4s, v21.16b, v28.16b
	WORD $0x6faa01e2 // mla v2.4s, v15.4s, v10.s[1]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9d962f // sdot v15.4s, v17.16b, v29.16b
	WORD $0x6fa601e3 // mla v3.4s, v15.4s, v6.s[1]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9d96af // sdot v15.4s, v21.16b, v29.16b
	WORD $0x6faa01e4 // mla v4.4s, v15.4s, v10.s[1]
	WORD $0x3cc6409c // ldur q28, [x4, #100]
	WORD $0x3cc640fd // ldur q29, [x7, #100]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9c964f // sdot v15.4s, v18.16b, v28.16b
	WORD $0x6f8609e1 // mla v1.4s, v15.4s, v6.s[2]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9c96cf // sdot v15.4s, v22.16b, v28.16b
	WORD $0x6f8a09e2 // mla v2.4s, v15.4s, v10.s[2]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9d964f // sdot v15.4s, v18.16b, v29.16b
	WORD $0x6f8609e3 // mla v3.4s, v15.4s, v6.s[2]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9d96cf // sdot v15.4s, v22.16b, v29.16b
	WORD $0x6f8a09e4 // mla v4.4s, v15.4s, v10.s[2]
	WORD $0x3cc7409c // ldur q28, [x4, #116]
	WORD $0x3cc740fd // ldur q29, [x7, #116]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9c966f // sdot v15.4s, v19.16b, v28.16b
	WORD $0x6fa609e1 // mla v1.4s, v15.4s, v6.s[3]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9c96ef // sdot v15.4s, v23.16b, v28.16b
	WORD $0x6faa09e2 // mla v2.4s, v15.4s, v10.s[3]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9d966f // sdot v15.4s, v19.16b, v29.16b
	WORD $0x6fa609e3 // mla v3.4s, v15.4s, v6.s[3]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9d96ef // sdot v15.4s, v23.16b, v29.16b
	WORD $0x6faa09e4 // mla v4.4s, v15.4s, v10.s[3]
	WORD $0x3cca0078 // ldur q24, [x3, #160]
	WORD $0x3ccb0079 // ldur q25, [x3, #176]
	WORD $0x3cca00ba // ldur q26, [x5, #160]
	WORD $0x3ccb00bb // ldur q27, [x5, #176]
	WORD $0x3cc40070 // ldur q16, [x3, #64]
	WORD $0x3cc50071 // ldur q17, [x3, #80]
	WORD $0x3cc60072 // ldur q18, [x3, #96]
	WORD $0x3cc70073 // ldur q19, [x3, #112]
	WORD $0x4f0c571f // shl v31.16b, v24.16b, #4
	WORD $0x4e2e1fff // and v31.16b, v31.16b, v14.16b
	WORD $0x4e2d1e10 // and v16.16b, v16.16b, v13.16b
	WORD $0x4ebf1e10 // orr v16.16b, v16.16b, v31.16b
	WORD $0x4f0c573f // shl v31.16b, v25.16b, #4
	WORD $0x4e2e1fff // and v31.16b, v31.16b, v14.16b
	WORD $0x4e2d1e31 // and v17.16b, v17.16b, v13.16b
	WORD $0x4ebf1e31 // orr v17.16b, v17.16b, v31.16b
	WORD $0x4f0a571f // shl v31.16b, v24.16b, #2
	WORD $0x4e2e1fff // and v31.16b, v31.16b, v14.16b
	WORD $0x4e2d1e52 // and v18.16b, v18.16b, v13.16b
	WORD $0x4ebf1e52 // orr v18.16b, v18.16b, v31.16b
	WORD $0x4f0a573f // shl v31.16b, v25.16b, #2
	WORD $0x4e2e1fff // and v31.16b, v31.16b, v14.16b
	WORD $0x4e2d1e73 // and v19.16b, v19.16b, v13.16b
	WORD $0x4ebf1e73 // orr v19.16b, v19.16b, v31.16b
	WORD $0x3cc400b4 // ldur q20, [x5, #64]
	WORD $0x3cc500b5 // ldur q21, [x5, #80]
	WORD $0x3cc600b6 // ldur q22, [x5, #96]
	WORD $0x3cc700b7 // ldur q23, [x5, #112]
	WORD $0x4f0c575f // shl v31.16b, v26.16b, #4
	WORD $0x4e2e1fff // and v31.16b, v31.16b, v14.16b
	WORD $0x4e2d1e94 // and v20.16b, v20.16b, v13.16b
	WORD $0x4ebf1e94 // orr v20.16b, v20.16b, v31.16b
	WORD $0x4f0c577f // shl v31.16b, v27.16b, #4
	WORD $0x4e2e1fff // and v31.16b, v31.16b, v14.16b
	WORD $0x4e2d1eb5 // and v21.16b, v21.16b, v13.16b
	WORD $0x4ebf1eb5 // orr v21.16b, v21.16b, v31.16b
	WORD $0x4f0a575f // shl v31.16b, v26.16b, #2
	WORD $0x4e2e1fff // and v31.16b, v31.16b, v14.16b
	WORD $0x4e2d1ed6 // and v22.16b, v22.16b, v13.16b
	WORD $0x4ebf1ed6 // orr v22.16b, v22.16b, v31.16b
	WORD $0x4f0a577f // shl v31.16b, v27.16b, #2
	WORD $0x4e2e1fff // and v31.16b, v31.16b, v14.16b
	WORD $0x4e2d1ef7 // and v23.16b, v23.16b, v13.16b
	WORD $0x4ebf1ef7 // orr v23.16b, v23.16b, v31.16b
	WORD $0x3cc8409c // ldur q28, [x4, #132]
	WORD $0x3cc840fd // ldur q29, [x7, #132]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9c960f // sdot v15.4s, v16.16b, v28.16b
	WORD $0x6f8701e1 // mla v1.4s, v15.4s, v7.s[0]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9c968f // sdot v15.4s, v20.16b, v28.16b
	WORD $0x6f8b01e2 // mla v2.4s, v15.4s, v11.s[0]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9d960f // sdot v15.4s, v16.16b, v29.16b
	WORD $0x6f8701e3 // mla v3.4s, v15.4s, v7.s[0]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9d968f // sdot v15.4s, v20.16b, v29.16b
	WORD $0x6f8b01e4 // mla v4.4s, v15.4s, v11.s[0]
	WORD $0x3cc9409c // ldur q28, [x4, #148]
	WORD $0x3cc940fd // ldur q29, [x7, #148]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9c962f // sdot v15.4s, v17.16b, v28.16b
	WORD $0x6fa701e1 // mla v1.4s, v15.4s, v7.s[1]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9c96af // sdot v15.4s, v21.16b, v28.16b
	WORD $0x6fab01e2 // mla v2.4s, v15.4s, v11.s[1]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9d962f // sdot v15.4s, v17.16b, v29.16b
	WORD $0x6fa701e3 // mla v3.4s, v15.4s, v7.s[1]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9d96af // sdot v15.4s, v21.16b, v29.16b
	WORD $0x6fab01e4 // mla v4.4s, v15.4s, v11.s[1]
	WORD $0x3cca409c // ldur q28, [x4, #164]
	WORD $0x3cca40fd // ldur q29, [x7, #164]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9c964f // sdot v15.4s, v18.16b, v28.16b
	WORD $0x6f8709e1 // mla v1.4s, v15.4s, v7.s[2]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9c96cf // sdot v15.4s, v22.16b, v28.16b
	WORD $0x6f8b09e2 // mla v2.4s, v15.4s, v11.s[2]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9d964f // sdot v15.4s, v18.16b, v29.16b
	WORD $0x6f8709e3 // mla v3.4s, v15.4s, v7.s[2]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9d96cf // sdot v15.4s, v22.16b, v29.16b
	WORD $0x6f8b09e4 // mla v4.4s, v15.4s, v11.s[2]
	WORD $0x3ccb409c // ldur q28, [x4, #180]
	WORD $0x3ccb40fd // ldur q29, [x7, #180]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9c966f // sdot v15.4s, v19.16b, v28.16b
	WORD $0x6fa709e1 // mla v1.4s, v15.4s, v7.s[3]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9c96ef // sdot v15.4s, v23.16b, v28.16b
	WORD $0x6fab09e2 // mla v2.4s, v15.4s, v11.s[3]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9d966f // sdot v15.4s, v19.16b, v29.16b
	WORD $0x6fa709e3 // mla v3.4s, v15.4s, v7.s[3]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9d96ef // sdot v15.4s, v23.16b, v29.16b
	WORD $0x6fab09e4 // mla v4.4s, v15.4s, v11.s[3]
	WORD $0x3cc40070 // ldur q16, [x3, #64]
	WORD $0x3cc50071 // ldur q17, [x3, #80]
	WORD $0x3cc60072 // ldur q18, [x3, #96]
	WORD $0x3cc70073 // ldur q19, [x3, #112]
	WORD $0x4e2e1f1f // and v31.16b, v24.16b, v14.16b
	WORD $0x6f0c0610 // ushr v16.16b, v16.16b, #4
	WORD $0x4ebf1e10 // orr v16.16b, v16.16b, v31.16b
	WORD $0x4e2e1f3f // and v31.16b, v25.16b, v14.16b
	WORD $0x6f0c0631 // ushr v17.16b, v17.16b, #4
	WORD $0x4ebf1e31 // orr v17.16b, v17.16b, v31.16b
	WORD $0x6f0e071f // ushr v31.16b, v24.16b, #2
	WORD $0x4e2e1fff // and v31.16b, v31.16b, v14.16b
	WORD $0x6f0c0652 // ushr v18.16b, v18.16b, #4
	WORD $0x4ebf1e52 // orr v18.16b, v18.16b, v31.16b
	WORD $0x6f0e073f // ushr v31.16b, v25.16b, #2
	WORD $0x4e2e1fff // and v31.16b, v31.16b, v14.16b
	WORD $0x6f0c0673 // ushr v19.16b, v19.16b, #4
	WORD $0x4ebf1e73 // orr v19.16b, v19.16b, v31.16b
	WORD $0x3cc400b4 // ldur q20, [x5, #64]
	WORD $0x3cc500b5 // ldur q21, [x5, #80]
	WORD $0x3cc600b6 // ldur q22, [x5, #96]
	WORD $0x3cc700b7 // ldur q23, [x5, #112]
	WORD $0x4e2e1f5f // and v31.16b, v26.16b, v14.16b
	WORD $0x6f0c0694 // ushr v20.16b, v20.16b, #4
	WORD $0x4ebf1e94 // orr v20.16b, v20.16b, v31.16b
	WORD $0x4e2e1f7f // and v31.16b, v27.16b, v14.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x4ebf1eb5 // orr v21.16b, v21.16b, v31.16b
	WORD $0x6f0e075f // ushr v31.16b, v26.16b, #2
	WORD $0x4e2e1fff // and v31.16b, v31.16b, v14.16b
	WORD $0x6f0c06d6 // ushr v22.16b, v22.16b, #4
	WORD $0x4ebf1ed6 // orr v22.16b, v22.16b, v31.16b
	WORD $0x6f0e077f // ushr v31.16b, v27.16b, #2
	WORD $0x4e2e1fff // and v31.16b, v31.16b, v14.16b
	WORD $0x6f0c06f7 // ushr v23.16b, v23.16b, #4
	WORD $0x4ebf1ef7 // orr v23.16b, v23.16b, v31.16b
	WORD $0x3ccc409c // ldur q28, [x4, #196]
	WORD $0x3ccc40fd // ldur q29, [x7, #196]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9c960f // sdot v15.4s, v16.16b, v28.16b
	WORD $0x6f8801e1 // mla v1.4s, v15.4s, v8.s[0]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9c968f // sdot v15.4s, v20.16b, v28.16b
	WORD $0x6f8c01e2 // mla v2.4s, v15.4s, v12.s[0]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9d960f // sdot v15.4s, v16.16b, v29.16b
	WORD $0x6f8801e3 // mla v3.4s, v15.4s, v8.s[0]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9d968f // sdot v15.4s, v20.16b, v29.16b
	WORD $0x6f8c01e4 // mla v4.4s, v15.4s, v12.s[0]
	WORD $0x3ccd409c // ldur q28, [x4, #212]
	WORD $0x3ccd40fd // ldur q29, [x7, #212]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9c962f // sdot v15.4s, v17.16b, v28.16b
	WORD $0x6fa801e1 // mla v1.4s, v15.4s, v8.s[1]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9c96af // sdot v15.4s, v21.16b, v28.16b
	WORD $0x6fac01e2 // mla v2.4s, v15.4s, v12.s[1]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9d962f // sdot v15.4s, v17.16b, v29.16b
	WORD $0x6fa801e3 // mla v3.4s, v15.4s, v8.s[1]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9d96af // sdot v15.4s, v21.16b, v29.16b
	WORD $0x6fac01e4 // mla v4.4s, v15.4s, v12.s[1]
	WORD $0x3cce409c // ldur q28, [x4, #228]
	WORD $0x3cce40fd // ldur q29, [x7, #228]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9c964f // sdot v15.4s, v18.16b, v28.16b
	WORD $0x6f8809e1 // mla v1.4s, v15.4s, v8.s[2]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9c96cf // sdot v15.4s, v22.16b, v28.16b
	WORD $0x6f8c09e2 // mla v2.4s, v15.4s, v12.s[2]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9d964f // sdot v15.4s, v18.16b, v29.16b
	WORD $0x6f8809e3 // mla v3.4s, v15.4s, v8.s[2]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9d96cf // sdot v15.4s, v22.16b, v29.16b
	WORD $0x6f8c09e4 // mla v4.4s, v15.4s, v12.s[2]
	WORD $0x3ccf409c // ldur q28, [x4, #244]
	WORD $0x3ccf40fd // ldur q29, [x7, #244]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9c966f // sdot v15.4s, v19.16b, v28.16b
	WORD $0x6fa809e1 // mla v1.4s, v15.4s, v8.s[3]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9c96ef // sdot v15.4s, v23.16b, v28.16b
	WORD $0x6fac09e2 // mla v2.4s, v15.4s, v12.s[3]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9d966f // sdot v15.4s, v19.16b, v29.16b
	WORD $0x6fa809e3 // mla v3.4s, v15.4s, v8.s[3]
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x4e9d96ef // sdot v15.4s, v23.16b, v29.16b
	WORD $0x6fac09e4 // mla v4.4s, v15.4s, v12.s[3]
	WORD $0x4eb1b821 // addv s1, v1.4s
	WORD $0x4eb1b842 // addv s2, v2.4s
	WORD $0x4eb1b863 // addv s3, v3.4s
	WORD $0x4eb1b884 // addv s4, v4.4s
	WORD $0x6e0c0441 // mov v1.s[1], v2.s[0]
	WORD $0x6e140461 // mov v1.s[2], v3.s[0]
	WORD $0x6e1c0481 // mov v1.s[3], v4.s[0]
	WORD $0x4e21d821 // scvtf v1.4s, v1.4s
	WORD $0x4e3ecc20 // fmla v0.4s, v1.4s, v30.4s
	ADD	$210, R3, R3
	ADD	$210, R5, R5
	ADD	$292, R4, R4
	ADD	$292, R7, R7
	SUBW	$1, R1, R1
	CBNZW	R1, q6ktileblk
q6ktilestore:
	WORD $0xfc000040 // stur d0, [x2, #0]
	WORD $0x5e180400 // mov d0, v0.d[1]
	WORD $0xfc000100 // stur d0, [x8, #0]
	RET
q6koob:
	B	ovr_oob
