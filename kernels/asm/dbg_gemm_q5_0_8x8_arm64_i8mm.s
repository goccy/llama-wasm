// dbg_gemm_q5_0_8x8: q5_0 8x8 repack GEMM, SMMLA 2x2 tiles over the unpacked runs; -16 folded through the block sums.
	MOVW	l0+8(FP), R1
	LSRW	$5, R1, R1
	MOVWU	l6+52(FP), R7
	LSRW	$3, R7, R7
	MOVWU	l5+48(FP), R8
	LSRW	$2, R8, R8
	CBZW	R7, gm5done
	CBZW	R8, gm5done
	MOVD	l1+16(FP), R2
	MOVD	l2+24(FP), R5
	LSL	$2, R5, R5
	LSL	$2, R8, R26
	SUB	$1, R26, R26
	MUL	R26, R5, R26
	ADD	R2, R26, R26
	ADD	R7<<5, R26, R26
	CMP	R26, R21
	BLO	gm5oob
	MOVD	l3+32(FP), R3
	MOVD	$176, R6
	MUL	R1, R6, R6
	MUL	R7, R6, R26
	ADD	R3, R26, R26
	CMP	R26, R21
	BLO	gm5oob
	MOVD	l4+40(FP), R4
	MOVD	$136, R26
	MUL	R1, R26, R26
	MUL	R8, R26, R26
	ADD	R4, R26, R26
	CMP	R26, R21
	BLO	gm5oob
	ADD	R20, R2, R2
	ADD	R20, R3, R3
	ADD	R20, R4, R4
	MOVD	$q5scratch-128(SP), R23
	MOVD	$·ovr_dbg_gemm_q5_0_8x8_i8mm_b48_010204081020408001020408102040800000000000000000010101010101010102020202020202020303030303030303(SB), R12
	WORD $0x3cc0019d // ldur q29, [x12, #0]
	WORD $0x3cc1019c // ldur q28, [x12, #16]
	WORD $0x3cc2019b // ldur q27, [x12, #32]
	WORD $0x4f00e5ff // movi v31.16b, #15
	WORD $0x4f00e61e // movi v30.16b, #16
	WORD $0x4f00e43a // movi v26.16b, #1
gm5rows:
	MOVD	R3, R0
	MOVD	R2, R24
	MOVW	R7, R25
gm5cols:
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x3c8002e8 // stur q8, [x23, #0]
	WORD $0x3c8102e8 // stur q8, [x23, #16]
	WORD $0x3c8202e8 // stur q8, [x23, #32]
	WORD $0x3c8302e8 // stur q8, [x23, #48]
	WORD $0x3c8402e8 // stur q8, [x23, #64]
	WORD $0x3c8502e8 // stur q8, [x23, #80]
	WORD $0x3c8602e8 // stur q8, [x23, #96]
	WORD $0x3c8702e8 // stur q8, [x23, #112]
	MOVD	R0, R9
	MOVD	R4, R10
	MOVW	R1, R11
	CBZW	R11, gm5store
gm5blk:
	WORD $0x3cc0814c // ldur q12, [x10, #8]
	WORD $0x3cc1814d // ldur q13, [x10, #24]
	WORD $0x3cc2814e // ldur q14, [x10, #40]
	WORD $0x3cc3814f // ldur q15, [x10, #56]
	WORD $0x3cc48150 // ldur q16, [x10, #72]
	WORD $0x3cc58151 // ldur q17, [x10, #88]
	WORD $0x3cc68152 // ldur q18, [x10, #104]
	WORD $0x3cc78153 // ldur q19, [x10, #120]
	WORD $0x4f000414 // movi v20.4s, #0
	WORD $0x4f000415 // movi v21.4s, #0
	WORD $0x4e9a9594 // sdot v20.4s, v12.16b, v26.16b
	WORD $0x4e9a95b5 // sdot v21.4s, v13.16b, v26.16b
	WORD $0x4e9a95d4 // sdot v20.4s, v14.16b, v26.16b
	WORD $0x4e9a95f5 // sdot v21.4s, v15.16b, v26.16b
	WORD $0x4e9a9614 // sdot v20.4s, v16.16b, v26.16b
	WORD $0x4e9a9635 // sdot v21.4s, v17.16b, v26.16b
	WORD $0x4e9a9654 // sdot v20.4s, v18.16b, v26.16b
	WORD $0x4e9a9675 // sdot v21.4s, v19.16b, v26.16b
	WORD $0x4eb5be94 // addp v20.4s, v20.4s, v21.4s
	WORD $0x4f245694 // shl v20.4s, v20.4s, #4
	WORD $0x4e080696 // dup v22.2d, v20.d[0]
	WORD $0x4e180697 // dup v23.2d, v20.d[1]
	WORD $0x4f000400 // movi v0.4s, #0
	WORD $0x4f000401 // movi v1.4s, #0
	WORD $0x4f000402 // movi v2.4s, #0
	WORD $0x4f000403 // movi v3.4s, #0
	WORD $0x4f000404 // movi v4.4s, #0
	WORD $0x4f000405 // movi v5.4s, #0
	WORD $0x4f000406 // movi v6.4s, #0
	WORD $0x4f000407 // movi v7.4s, #0
	WORD $0x3cc30128 // ldur q8, [x9, #48]
	WORD $0x4e3f1d09 // and v9.16b, v8.16b, v31.16b
	WORD $0x6f0c050a // ushr v10.16b, v8.16b, #4
	WORD $0xbc41012b // ldur s11, [x9, #16]
	WORD $0x4e1c0178 // tbl v24.16b, {v11.16b}, v28.16b
	WORD $0x4e3d8f18 // cmtst v24.16b, v24.16b, v29.16b
	WORD $0x4e3e1f18 // and v24.16b, v24.16b, v30.16b
	WORD $0x4eb81d29 // orr v9.16b, v9.16b, v24.16b
	WORD $0x4e1b0178 // tbl v24.16b, {v11.16b}, v27.16b
	WORD $0x4e3d8f18 // cmtst v24.16b, v24.16b, v29.16b
	WORD $0x4e3e1f18 // and v24.16b, v24.16b, v30.16b
	WORD $0x4eb81d4a // orr v10.16b, v10.16b, v24.16b
	WORD $0x4e8ca520 // smmla v0.4s, v9.16b, v12.16b
	WORD $0x4e8da524 // smmla v4.4s, v9.16b, v13.16b
	WORD $0x4e90a540 // smmla v0.4s, v10.16b, v16.16b
	WORD $0x4e91a544 // smmla v4.4s, v10.16b, v17.16b
	WORD $0x3cc40128 // ldur q8, [x9, #64]
	WORD $0x4e3f1d09 // and v9.16b, v8.16b, v31.16b
	WORD $0x6f0c050a // ushr v10.16b, v8.16b, #4
	WORD $0xbc41412b // ldur s11, [x9, #20]
	WORD $0x4e1c0178 // tbl v24.16b, {v11.16b}, v28.16b
	WORD $0x4e3d8f18 // cmtst v24.16b, v24.16b, v29.16b
	WORD $0x4e3e1f18 // and v24.16b, v24.16b, v30.16b
	WORD $0x4eb81d29 // orr v9.16b, v9.16b, v24.16b
	WORD $0x4e1b0178 // tbl v24.16b, {v11.16b}, v27.16b
	WORD $0x4e3d8f18 // cmtst v24.16b, v24.16b, v29.16b
	WORD $0x4e3e1f18 // and v24.16b, v24.16b, v30.16b
	WORD $0x4eb81d4a // orr v10.16b, v10.16b, v24.16b
	WORD $0x4e8ca521 // smmla v1.4s, v9.16b, v12.16b
	WORD $0x4e8da525 // smmla v5.4s, v9.16b, v13.16b
	WORD $0x4e90a541 // smmla v1.4s, v10.16b, v16.16b
	WORD $0x4e91a545 // smmla v5.4s, v10.16b, v17.16b
	WORD $0x3cc50128 // ldur q8, [x9, #80]
	WORD $0x4e3f1d09 // and v9.16b, v8.16b, v31.16b
	WORD $0x6f0c050a // ushr v10.16b, v8.16b, #4
	WORD $0xbc41812b // ldur s11, [x9, #24]
	WORD $0x4e1c0178 // tbl v24.16b, {v11.16b}, v28.16b
	WORD $0x4e3d8f18 // cmtst v24.16b, v24.16b, v29.16b
	WORD $0x4e3e1f18 // and v24.16b, v24.16b, v30.16b
	WORD $0x4eb81d29 // orr v9.16b, v9.16b, v24.16b
	WORD $0x4e1b0178 // tbl v24.16b, {v11.16b}, v27.16b
	WORD $0x4e3d8f18 // cmtst v24.16b, v24.16b, v29.16b
	WORD $0x4e3e1f18 // and v24.16b, v24.16b, v30.16b
	WORD $0x4eb81d4a // orr v10.16b, v10.16b, v24.16b
	WORD $0x4e8ca522 // smmla v2.4s, v9.16b, v12.16b
	WORD $0x4e8da526 // smmla v6.4s, v9.16b, v13.16b
	WORD $0x4e90a542 // smmla v2.4s, v10.16b, v16.16b
	WORD $0x4e91a546 // smmla v6.4s, v10.16b, v17.16b
	WORD $0x3cc60128 // ldur q8, [x9, #96]
	WORD $0x4e3f1d09 // and v9.16b, v8.16b, v31.16b
	WORD $0x6f0c050a // ushr v10.16b, v8.16b, #4
	WORD $0xbc41c12b // ldur s11, [x9, #28]
	WORD $0x4e1c0178 // tbl v24.16b, {v11.16b}, v28.16b
	WORD $0x4e3d8f18 // cmtst v24.16b, v24.16b, v29.16b
	WORD $0x4e3e1f18 // and v24.16b, v24.16b, v30.16b
	WORD $0x4eb81d29 // orr v9.16b, v9.16b, v24.16b
	WORD $0x4e1b0178 // tbl v24.16b, {v11.16b}, v27.16b
	WORD $0x4e3d8f18 // cmtst v24.16b, v24.16b, v29.16b
	WORD $0x4e3e1f18 // and v24.16b, v24.16b, v30.16b
	WORD $0x4eb81d4a // orr v10.16b, v10.16b, v24.16b
	WORD $0x4e8ca523 // smmla v3.4s, v9.16b, v12.16b
	WORD $0x4e8da527 // smmla v7.4s, v9.16b, v13.16b
	WORD $0x4e90a543 // smmla v3.4s, v10.16b, v16.16b
	WORD $0x4e91a547 // smmla v7.4s, v10.16b, v17.16b
	WORD $0x3cc70128 // ldur q8, [x9, #112]
	WORD $0x4e3f1d09 // and v9.16b, v8.16b, v31.16b
	WORD $0x6f0c050a // ushr v10.16b, v8.16b, #4
	WORD $0xbc42012b // ldur s11, [x9, #32]
	WORD $0x4e1c0178 // tbl v24.16b, {v11.16b}, v28.16b
	WORD $0x4e3d8f18 // cmtst v24.16b, v24.16b, v29.16b
	WORD $0x4e3e1f18 // and v24.16b, v24.16b, v30.16b
	WORD $0x4eb81d29 // orr v9.16b, v9.16b, v24.16b
	WORD $0x4e1b0178 // tbl v24.16b, {v11.16b}, v27.16b
	WORD $0x4e3d8f18 // cmtst v24.16b, v24.16b, v29.16b
	WORD $0x4e3e1f18 // and v24.16b, v24.16b, v30.16b
	WORD $0x4eb81d4a // orr v10.16b, v10.16b, v24.16b
	WORD $0x4e8ea520 // smmla v0.4s, v9.16b, v14.16b
	WORD $0x4e8fa524 // smmla v4.4s, v9.16b, v15.16b
	WORD $0x4e92a540 // smmla v0.4s, v10.16b, v18.16b
	WORD $0x4e93a544 // smmla v4.4s, v10.16b, v19.16b
	WORD $0x3cc80128 // ldur q8, [x9, #128]
	WORD $0x4e3f1d09 // and v9.16b, v8.16b, v31.16b
	WORD $0x6f0c050a // ushr v10.16b, v8.16b, #4
	WORD $0xbc42412b // ldur s11, [x9, #36]
	WORD $0x4e1c0178 // tbl v24.16b, {v11.16b}, v28.16b
	WORD $0x4e3d8f18 // cmtst v24.16b, v24.16b, v29.16b
	WORD $0x4e3e1f18 // and v24.16b, v24.16b, v30.16b
	WORD $0x4eb81d29 // orr v9.16b, v9.16b, v24.16b
	WORD $0x4e1b0178 // tbl v24.16b, {v11.16b}, v27.16b
	WORD $0x4e3d8f18 // cmtst v24.16b, v24.16b, v29.16b
	WORD $0x4e3e1f18 // and v24.16b, v24.16b, v30.16b
	WORD $0x4eb81d4a // orr v10.16b, v10.16b, v24.16b
	WORD $0x4e8ea521 // smmla v1.4s, v9.16b, v14.16b
	WORD $0x4e8fa525 // smmla v5.4s, v9.16b, v15.16b
	WORD $0x4e92a541 // smmla v1.4s, v10.16b, v18.16b
	WORD $0x4e93a545 // smmla v5.4s, v10.16b, v19.16b
	WORD $0x3cc90128 // ldur q8, [x9, #144]
	WORD $0x4e3f1d09 // and v9.16b, v8.16b, v31.16b
	WORD $0x6f0c050a // ushr v10.16b, v8.16b, #4
	WORD $0xbc42812b // ldur s11, [x9, #40]
	WORD $0x4e1c0178 // tbl v24.16b, {v11.16b}, v28.16b
	WORD $0x4e3d8f18 // cmtst v24.16b, v24.16b, v29.16b
	WORD $0x4e3e1f18 // and v24.16b, v24.16b, v30.16b
	WORD $0x4eb81d29 // orr v9.16b, v9.16b, v24.16b
	WORD $0x4e1b0178 // tbl v24.16b, {v11.16b}, v27.16b
	WORD $0x4e3d8f18 // cmtst v24.16b, v24.16b, v29.16b
	WORD $0x4e3e1f18 // and v24.16b, v24.16b, v30.16b
	WORD $0x4eb81d4a // orr v10.16b, v10.16b, v24.16b
	WORD $0x4e8ea522 // smmla v2.4s, v9.16b, v14.16b
	WORD $0x4e8fa526 // smmla v6.4s, v9.16b, v15.16b
	WORD $0x4e92a542 // smmla v2.4s, v10.16b, v18.16b
	WORD $0x4e93a546 // smmla v6.4s, v10.16b, v19.16b
	WORD $0x3cca0128 // ldur q8, [x9, #160]
	WORD $0x4e3f1d09 // and v9.16b, v8.16b, v31.16b
	WORD $0x6f0c050a // ushr v10.16b, v8.16b, #4
	WORD $0xbc42c12b // ldur s11, [x9, #44]
	WORD $0x4e1c0178 // tbl v24.16b, {v11.16b}, v28.16b
	WORD $0x4e3d8f18 // cmtst v24.16b, v24.16b, v29.16b
	WORD $0x4e3e1f18 // and v24.16b, v24.16b, v30.16b
	WORD $0x4eb81d29 // orr v9.16b, v9.16b, v24.16b
	WORD $0x4e1b0178 // tbl v24.16b, {v11.16b}, v27.16b
	WORD $0x4e3d8f18 // cmtst v24.16b, v24.16b, v29.16b
	WORD $0x4e3e1f18 // and v24.16b, v24.16b, v30.16b
	WORD $0x4eb81d4a // orr v10.16b, v10.16b, v24.16b
	WORD $0x4e8ea523 // smmla v3.4s, v9.16b, v14.16b
	WORD $0x4e8fa527 // smmla v7.4s, v9.16b, v15.16b
	WORD $0x4e92a543 // smmla v3.4s, v10.16b, v18.16b
	WORD $0x4e93a547 // smmla v7.4s, v10.16b, v19.16b
	WORD $0x6eb68400 // sub v0.4s, v0.4s, v22.4s
	WORD $0x6eb78484 // sub v4.4s, v4.4s, v23.4s
	WORD $0x6eb68421 // sub v1.4s, v1.4s, v22.4s
	WORD $0x6eb784a5 // sub v5.4s, v5.4s, v23.4s
	WORD $0x6eb68442 // sub v2.4s, v2.4s, v22.4s
	WORD $0x6eb784c6 // sub v6.4s, v6.4s, v23.4s
	WORD $0x6eb68463 // sub v3.4s, v3.4s, v22.4s
	WORD $0x6eb784e7 // sub v7.4s, v7.4s, v23.4s
	WORD $0xfc400128 // ldur d8, [x9, #0]
	WORD $0x0e217908 // fcvtl v8.4s, v8.4h
	WORD $0xfc408129 // ldur d9, [x9, #8]
	WORD $0x0e217929 // fcvtl v9.4s, v9.4h
	WORD $0xfc40014a // ldur d10, [x10, #0]
	WORD $0x0e21794a // fcvtl v10.4s, v10.4h
	WORD $0x4e08054b // dup v11.2d, v10.d[0]
	WORD $0x4e180559 // dup v25.2d, v10.d[1]
	WORD $0x4e883918 // zip1 v24.4s, v8.4s, v8.4s
	WORD $0x6e2bdf14 // fmul v20.4s, v24.4s, v11.4s
	WORD $0x6e39df15 // fmul v21.4s, v24.4s, v25.4s
	WORD $0x4e21d800 // scvtf v0.4s, v0.4s
	WORD $0x3cc002f8 // ldur q24, [x23, #0]
	WORD $0x4e34cc18 // fmla v24.4s, v0.4s, v20.4s
	WORD $0x3c8002f8 // stur q24, [x23, #0]
	WORD $0x4e21d884 // scvtf v4.4s, v4.4s
	WORD $0x3cc402f8 // ldur q24, [x23, #64]
	WORD $0x4e35cc98 // fmla v24.4s, v4.4s, v21.4s
	WORD $0x3c8402f8 // stur q24, [x23, #64]
	WORD $0x4e887918 // zip2 v24.4s, v8.4s, v8.4s
	WORD $0x6e2bdf14 // fmul v20.4s, v24.4s, v11.4s
	WORD $0x6e39df15 // fmul v21.4s, v24.4s, v25.4s
	WORD $0x4e21d821 // scvtf v1.4s, v1.4s
	WORD $0x3cc102f8 // ldur q24, [x23, #16]
	WORD $0x4e34cc38 // fmla v24.4s, v1.4s, v20.4s
	WORD $0x3c8102f8 // stur q24, [x23, #16]
	WORD $0x4e21d8a5 // scvtf v5.4s, v5.4s
	WORD $0x3cc502f8 // ldur q24, [x23, #80]
	WORD $0x4e35ccb8 // fmla v24.4s, v5.4s, v21.4s
	WORD $0x3c8502f8 // stur q24, [x23, #80]
	WORD $0x4e893938 // zip1 v24.4s, v9.4s, v9.4s
	WORD $0x6e2bdf14 // fmul v20.4s, v24.4s, v11.4s
	WORD $0x6e39df15 // fmul v21.4s, v24.4s, v25.4s
	WORD $0x4e21d842 // scvtf v2.4s, v2.4s
	WORD $0x3cc202f8 // ldur q24, [x23, #32]
	WORD $0x4e34cc58 // fmla v24.4s, v2.4s, v20.4s
	WORD $0x3c8202f8 // stur q24, [x23, #32]
	WORD $0x4e21d8c6 // scvtf v6.4s, v6.4s
	WORD $0x3cc602f8 // ldur q24, [x23, #96]
	WORD $0x4e35ccd8 // fmla v24.4s, v6.4s, v21.4s
	WORD $0x3c8602f8 // stur q24, [x23, #96]
	WORD $0x4e897938 // zip2 v24.4s, v9.4s, v9.4s
	WORD $0x6e2bdf14 // fmul v20.4s, v24.4s, v11.4s
	WORD $0x6e39df15 // fmul v21.4s, v24.4s, v25.4s
	WORD $0x4e21d863 // scvtf v3.4s, v3.4s
	WORD $0x3cc302f8 // ldur q24, [x23, #48]
	WORD $0x4e34cc78 // fmla v24.4s, v3.4s, v20.4s
	WORD $0x3c8302f8 // stur q24, [x23, #48]
	WORD $0x4e21d8e7 // scvtf v7.4s, v7.4s
	WORD $0x3cc702f8 // ldur q24, [x23, #112]
	WORD $0x4e35ccf8 // fmla v24.4s, v7.4s, v21.4s
	WORD $0x3c8702f8 // stur q24, [x23, #112]
	ADD	$176, R9, R9
	ADD	$136, R10, R10
	SUBW	$1, R11, R11
	CBNZW	R11, gm5blk
gm5store:
	WORD $0x3cc002e0 // ldur q0, [x23, #0]
	WORD $0x3cc102e1 // ldur q1, [x23, #16]
	WORD $0x3cc202e2 // ldur q2, [x23, #32]
	WORD $0x3cc302e3 // ldur q3, [x23, #48]
	WORD $0x3cc402e4 // ldur q4, [x23, #64]
	WORD $0x3cc502e5 // ldur q5, [x23, #80]
	WORD $0x3cc602e6 // ldur q6, [x23, #96]
	WORD $0x3cc702e7 // ldur q7, [x23, #112]
	MOVD	R24, R12
	WORD $0x4e811810 // uzp1 v16.4s, v0.4s, v1.4s
	WORD $0x3c800190 // stur q16, [x12, #0]
	WORD $0x4e831850 // uzp1 v16.4s, v2.4s, v3.4s
	WORD $0x3c810190 // stur q16, [x12, #16]
	ADD	R12, R5, R12
	WORD $0x4e815810 // uzp2 v16.4s, v0.4s, v1.4s
	WORD $0x3c800190 // stur q16, [x12, #0]
	WORD $0x4e835850 // uzp2 v16.4s, v2.4s, v3.4s
	WORD $0x3c810190 // stur q16, [x12, #16]
	ADD	R12, R5, R12
	WORD $0x4e851890 // uzp1 v16.4s, v4.4s, v5.4s
	WORD $0x3c800190 // stur q16, [x12, #0]
	WORD $0x4e8718d0 // uzp1 v16.4s, v6.4s, v7.4s
	WORD $0x3c810190 // stur q16, [x12, #16]
	ADD	R12, R5, R12
	WORD $0x4e855890 // uzp2 v16.4s, v4.4s, v5.4s
	WORD $0x3c800190 // stur q16, [x12, #0]
	WORD $0x4e8758d0 // uzp2 v16.4s, v6.4s, v7.4s
	WORD $0x3c810190 // stur q16, [x12, #16]
	ADD	$32, R24, R24
	ADD	R0, R6, R0
	SUBW	$1, R25, R25
	CBNZW	R25, gm5cols
	MOVD	$136, R26
	MUL	R1, R26, R26
	ADD	R4, R26, R4
	LSL	$2, R5, R26
	ADD	R2, R26, R2
	SUBW	$1, R8, R8
	CBNZW	R8, gm5rows
gm5done:
	RET
gm5oob:
	B	ovr_oob

DATA ·ovr_dbg_gemm_q5_0_8x8_i8mm_b48_010204081020408001020408102040800000000000000000010101010101010102020202020202020303030303030303+0(SB)/8, $0x8040201008040201
DATA ·ovr_dbg_gemm_q5_0_8x8_i8mm_b48_010204081020408001020408102040800000000000000000010101010101010102020202020202020303030303030303+8(SB)/8, $0x8040201008040201
DATA ·ovr_dbg_gemm_q5_0_8x8_i8mm_b48_010204081020408001020408102040800000000000000000010101010101010102020202020202020303030303030303+16(SB)/8, $0x0
DATA ·ovr_dbg_gemm_q5_0_8x8_i8mm_b48_010204081020408001020408102040800000000000000000010101010101010102020202020202020303030303030303+24(SB)/8, $0x101010101010101
DATA ·ovr_dbg_gemm_q5_0_8x8_i8mm_b48_010204081020408001020408102040800000000000000000010101010101010102020202020202020303030303030303+32(SB)/8, $0x202020202020202
DATA ·ovr_dbg_gemm_q5_0_8x8_i8mm_b48_010204081020408001020408102040800000000000000000010101010101010102020202020202020303030303030303+40(SB)/8, $0x303030303030303
GLOBL ·ovr_dbg_gemm_q5_0_8x8_i8mm_b48_010204081020408001020408102040800000000000000000010101010101010102020202020202020303030303030303(SB), RODATA|NOPTR, $48
