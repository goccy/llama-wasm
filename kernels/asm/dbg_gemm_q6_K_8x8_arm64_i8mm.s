// dbg_gemm_q6_K_8x8: q6_K 8x8 repack GEMM, SMMLA 2x2 tiles over the interleaved layouts.
	MOVW	l0+8(FP), R1
	LSRW	$8, R1, R1
	MOVWU	l6+52(FP), R7
	LSRW	$3, R7, R7
	MOVWU	l5+48(FP), R8
	LSRW	$2, R8, R8
	CBZW	R7, m6done
	CBZW	R8, m6done
	MOVD	l1+16(FP), R2
	MOVD	l2+24(FP), R5
	LSL	$2, R5, R5
	LSL	$2, R8, R26
	SUB	$1, R26, R26
	MUL	R26, R5, R26
	ADD	R2, R26, R26
	ADD	R7<<5, R26, R26
	CMP	R26, R21
	BLO	m6oob
	MOVD	l3+32(FP), R3
	MOVD	$1680, R6
	MUL	R1, R6, R6
	MUL	R7, R6, R26
	ADD	R3, R26, R26
	CMP	R26, R21
	BLO	m6oob
	MOVD	l4+40(FP), R4
	MOVD	$1168, R26
	MUL	R1, R26, R26
	MUL	R8, R26, R26
	ADD	R4, R26, R26
	CMP	R26, R21
	BLO	m6oob
	ADD	R20, R2, R2
	ADD	R20, R3, R3
	ADD	R20, R4, R4
	MOVD	$q6kscratch-128(SP), R23
	WORD $0x4f00e5ff // movi v31.16b, #15
	WORD $0x4f00e476 // movi v22.16b, #3
	WORD $0x4f01e617 // movi v23.16b, #48
	WORD $0x4f01e419 // movi v25.16b, #32
m6rows:
	MOVD	R3, R0
	MOVD	R2, R24
	MOVW	R7, R25
m6cols:
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
	CBZW	R11, m6store
m6blk:
	WORD $0x4f000400 // movi v0.4s, #0
	WORD $0x4f000401 // movi v1.4s, #0
	WORD $0x4f000402 // movi v2.4s, #0
	WORD $0x4f000403 // movi v3.4s, #0
	WORD $0x4f000404 // movi v4.4s, #0
	WORD $0x4f000405 // movi v5.4s, #0
	WORD $0x4f000406 // movi v6.4s, #0
	WORD $0x4f000407 // movi v7.4s, #0
	ADD	$144, R9, R12
	ADD	$1168, R9, R13
	ADD	$16, R10, R14
	ADD	$256, R14, R15
	WORD $0xfc410138 // ldur d24, [x9, #16]
	WORD $0x0f08a718 // sshll v24.8h, v24.8b, #0
	WORD $0x0f10a71a // sshll v26.4s, v24.4h, #0
	WORD $0x4f10a71b // sshll2 v27.4s, v24.8h, #0
	WORD $0xfc430138 // ldur d24, [x9, #48]
	WORD $0x0f08a718 // sshll v24.8h, v24.8b, #0
	WORD $0x0f10a71c // sshll v28.4s, v24.4h, #0
	WORD $0x4f10a71d // sshll2 v29.4s, v24.8h, #0
	WORD $0x4e9a3b54 // zip1 v20.4s, v26.4s, v26.4s
	WORD $0x4e9c3b95 // zip1 v21.4s, v28.4s, v28.4s
	WORD $0x3cc0018c // ldur q12, [x12, #0]
	WORD $0x3cc4018d // ldur q13, [x12, #64]
	WORD $0x3cc001ae // ldur q14, [x13, #0]
	WORD $0x3cc401af // ldur q15, [x13, #64]
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x4e361dd1 // and v17.16b, v14.16b, v22.16b
	WORD $0x4f0c5631 // shl v17.16b, v17.16b, #4
	WORD $0x4eb11e10 // orr v16.16b, v16.16b, v17.16b
	WORD $0x6e398610 // sub v16.16b, v16.16b, v25.16b
	WORD $0x6f0c058c // ushr v12.16b, v12.16b, #4
	WORD $0x4e371dce // and v14.16b, v14.16b, v23.16b
	WORD $0x4eae1d8c // orr v12.16b, v12.16b, v14.16b
	WORD $0x6e39858c // sub v12.16b, v12.16b, v25.16b
	WORD $0x4e3f1db1 // and v17.16b, v13.16b, v31.16b
	WORD $0x4e361dee // and v14.16b, v15.16b, v22.16b
	WORD $0x4f0c55ce // shl v14.16b, v14.16b, #4
	WORD $0x4eae1e31 // orr v17.16b, v17.16b, v14.16b
	WORD $0x6e398631 // sub v17.16b, v17.16b, v25.16b
	WORD $0x6f0c05ad // ushr v13.16b, v13.16b, #4
	WORD $0x4e371def // and v15.16b, v15.16b, v23.16b
	WORD $0x4eaf1dad // orr v13.16b, v13.16b, v15.16b
	WORD $0x6e3985ad // sub v13.16b, v13.16b, v25.16b
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a628 // smmla v8.4s, v17.16b, v18.16b
	WORD $0x4e93a62a // smmla v10.4s, v17.16b, v19.16b
	WORD $0x3cc001f2 // ldur q18, [x15, #0]
	WORD $0x3cc101f3 // ldur q19, [x15, #16]
	WORD $0x4e92a589 // smmla v9.4s, v12.16b, v18.16b
	WORD $0x4e93a58b // smmla v11.4s, v12.16b, v19.16b
	WORD $0x3cc201f2 // ldur q18, [x15, #32]
	WORD $0x3cc301f3 // ldur q19, [x15, #48]
	WORD $0x4e92a5a9 // smmla v9.4s, v13.16b, v18.16b
	WORD $0x4e93a5ab // smmla v11.4s, v13.16b, v19.16b
	WORD $0x4eb49500 // mla v0.4s, v8.4s, v20.4s
	WORD $0x4eb59520 // mla v0.4s, v9.4s, v21.4s
	WORD $0x4eb49544 // mla v4.4s, v10.4s, v20.4s
	WORD $0x4eb59564 // mla v4.4s, v11.4s, v21.4s
	WORD $0x4e9a7b54 // zip2 v20.4s, v26.4s, v26.4s
	WORD $0x4e9c7b95 // zip2 v21.4s, v28.4s, v28.4s
	WORD $0x3cc1018c // ldur q12, [x12, #16]
	WORD $0x3cc5018d // ldur q13, [x12, #80]
	WORD $0x3cc101ae // ldur q14, [x13, #16]
	WORD $0x3cc501af // ldur q15, [x13, #80]
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x4e361dd1 // and v17.16b, v14.16b, v22.16b
	WORD $0x4f0c5631 // shl v17.16b, v17.16b, #4
	WORD $0x4eb11e10 // orr v16.16b, v16.16b, v17.16b
	WORD $0x6e398610 // sub v16.16b, v16.16b, v25.16b
	WORD $0x6f0c058c // ushr v12.16b, v12.16b, #4
	WORD $0x4e371dce // and v14.16b, v14.16b, v23.16b
	WORD $0x4eae1d8c // orr v12.16b, v12.16b, v14.16b
	WORD $0x6e39858c // sub v12.16b, v12.16b, v25.16b
	WORD $0x4e3f1db1 // and v17.16b, v13.16b, v31.16b
	WORD $0x4e361dee // and v14.16b, v15.16b, v22.16b
	WORD $0x4f0c55ce // shl v14.16b, v14.16b, #4
	WORD $0x4eae1e31 // orr v17.16b, v17.16b, v14.16b
	WORD $0x6e398631 // sub v17.16b, v17.16b, v25.16b
	WORD $0x6f0c05ad // ushr v13.16b, v13.16b, #4
	WORD $0x4e371def // and v15.16b, v15.16b, v23.16b
	WORD $0x4eaf1dad // orr v13.16b, v13.16b, v15.16b
	WORD $0x6e3985ad // sub v13.16b, v13.16b, v25.16b
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a628 // smmla v8.4s, v17.16b, v18.16b
	WORD $0x4e93a62a // smmla v10.4s, v17.16b, v19.16b
	WORD $0x3cc001f2 // ldur q18, [x15, #0]
	WORD $0x3cc101f3 // ldur q19, [x15, #16]
	WORD $0x4e92a589 // smmla v9.4s, v12.16b, v18.16b
	WORD $0x4e93a58b // smmla v11.4s, v12.16b, v19.16b
	WORD $0x3cc201f2 // ldur q18, [x15, #32]
	WORD $0x3cc301f3 // ldur q19, [x15, #48]
	WORD $0x4e92a5a9 // smmla v9.4s, v13.16b, v18.16b
	WORD $0x4e93a5ab // smmla v11.4s, v13.16b, v19.16b
	WORD $0x4eb49501 // mla v1.4s, v8.4s, v20.4s
	WORD $0x4eb59521 // mla v1.4s, v9.4s, v21.4s
	WORD $0x4eb49545 // mla v5.4s, v10.4s, v20.4s
	WORD $0x4eb59565 // mla v5.4s, v11.4s, v21.4s
	WORD $0x4e9b3b74 // zip1 v20.4s, v27.4s, v27.4s
	WORD $0x4e9d3bb5 // zip1 v21.4s, v29.4s, v29.4s
	WORD $0x3cc2018c // ldur q12, [x12, #32]
	WORD $0x3cc6018d // ldur q13, [x12, #96]
	WORD $0x3cc201ae // ldur q14, [x13, #32]
	WORD $0x3cc601af // ldur q15, [x13, #96]
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x4e361dd1 // and v17.16b, v14.16b, v22.16b
	WORD $0x4f0c5631 // shl v17.16b, v17.16b, #4
	WORD $0x4eb11e10 // orr v16.16b, v16.16b, v17.16b
	WORD $0x6e398610 // sub v16.16b, v16.16b, v25.16b
	WORD $0x6f0c058c // ushr v12.16b, v12.16b, #4
	WORD $0x4e371dce // and v14.16b, v14.16b, v23.16b
	WORD $0x4eae1d8c // orr v12.16b, v12.16b, v14.16b
	WORD $0x6e39858c // sub v12.16b, v12.16b, v25.16b
	WORD $0x4e3f1db1 // and v17.16b, v13.16b, v31.16b
	WORD $0x4e361dee // and v14.16b, v15.16b, v22.16b
	WORD $0x4f0c55ce // shl v14.16b, v14.16b, #4
	WORD $0x4eae1e31 // orr v17.16b, v17.16b, v14.16b
	WORD $0x6e398631 // sub v17.16b, v17.16b, v25.16b
	WORD $0x6f0c05ad // ushr v13.16b, v13.16b, #4
	WORD $0x4e371def // and v15.16b, v15.16b, v23.16b
	WORD $0x4eaf1dad // orr v13.16b, v13.16b, v15.16b
	WORD $0x6e3985ad // sub v13.16b, v13.16b, v25.16b
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a628 // smmla v8.4s, v17.16b, v18.16b
	WORD $0x4e93a62a // smmla v10.4s, v17.16b, v19.16b
	WORD $0x3cc001f2 // ldur q18, [x15, #0]
	WORD $0x3cc101f3 // ldur q19, [x15, #16]
	WORD $0x4e92a589 // smmla v9.4s, v12.16b, v18.16b
	WORD $0x4e93a58b // smmla v11.4s, v12.16b, v19.16b
	WORD $0x3cc201f2 // ldur q18, [x15, #32]
	WORD $0x3cc301f3 // ldur q19, [x15, #48]
	WORD $0x4e92a5a9 // smmla v9.4s, v13.16b, v18.16b
	WORD $0x4e93a5ab // smmla v11.4s, v13.16b, v19.16b
	WORD $0x4eb49502 // mla v2.4s, v8.4s, v20.4s
	WORD $0x4eb59522 // mla v2.4s, v9.4s, v21.4s
	WORD $0x4eb49546 // mla v6.4s, v10.4s, v20.4s
	WORD $0x4eb59566 // mla v6.4s, v11.4s, v21.4s
	WORD $0x4e9b7b74 // zip2 v20.4s, v27.4s, v27.4s
	WORD $0x4e9d7bb5 // zip2 v21.4s, v29.4s, v29.4s
	WORD $0x3cc3018c // ldur q12, [x12, #48]
	WORD $0x3cc7018d // ldur q13, [x12, #112]
	WORD $0x3cc301ae // ldur q14, [x13, #48]
	WORD $0x3cc701af // ldur q15, [x13, #112]
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x4e361dd1 // and v17.16b, v14.16b, v22.16b
	WORD $0x4f0c5631 // shl v17.16b, v17.16b, #4
	WORD $0x4eb11e10 // orr v16.16b, v16.16b, v17.16b
	WORD $0x6e398610 // sub v16.16b, v16.16b, v25.16b
	WORD $0x6f0c058c // ushr v12.16b, v12.16b, #4
	WORD $0x4e371dce // and v14.16b, v14.16b, v23.16b
	WORD $0x4eae1d8c // orr v12.16b, v12.16b, v14.16b
	WORD $0x6e39858c // sub v12.16b, v12.16b, v25.16b
	WORD $0x4e3f1db1 // and v17.16b, v13.16b, v31.16b
	WORD $0x4e361dee // and v14.16b, v15.16b, v22.16b
	WORD $0x4f0c55ce // shl v14.16b, v14.16b, #4
	WORD $0x4eae1e31 // orr v17.16b, v17.16b, v14.16b
	WORD $0x6e398631 // sub v17.16b, v17.16b, v25.16b
	WORD $0x6f0c05ad // ushr v13.16b, v13.16b, #4
	WORD $0x4e371def // and v15.16b, v15.16b, v23.16b
	WORD $0x4eaf1dad // orr v13.16b, v13.16b, v15.16b
	WORD $0x6e3985ad // sub v13.16b, v13.16b, v25.16b
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a628 // smmla v8.4s, v17.16b, v18.16b
	WORD $0x4e93a62a // smmla v10.4s, v17.16b, v19.16b
	WORD $0x3cc001f2 // ldur q18, [x15, #0]
	WORD $0x3cc101f3 // ldur q19, [x15, #16]
	WORD $0x4e92a589 // smmla v9.4s, v12.16b, v18.16b
	WORD $0x4e93a58b // smmla v11.4s, v12.16b, v19.16b
	WORD $0x3cc201f2 // ldur q18, [x15, #32]
	WORD $0x3cc301f3 // ldur q19, [x15, #48]
	WORD $0x4e92a5a9 // smmla v9.4s, v13.16b, v18.16b
	WORD $0x4e93a5ab // smmla v11.4s, v13.16b, v19.16b
	WORD $0x4eb49503 // mla v3.4s, v8.4s, v20.4s
	WORD $0x4eb59523 // mla v3.4s, v9.4s, v21.4s
	WORD $0x4eb49547 // mla v7.4s, v10.4s, v20.4s
	WORD $0x4eb59567 // mla v7.4s, v11.4s, v21.4s
	ADD	$272, R9, R12
	ADD	$1296, R9, R13
	ADD	$80, R10, R14
	ADD	$256, R14, R15
	WORD $0xfc418138 // ldur d24, [x9, #24]
	WORD $0x0f08a718 // sshll v24.8h, v24.8b, #0
	WORD $0x0f10a71a // sshll v26.4s, v24.4h, #0
	WORD $0x4f10a71b // sshll2 v27.4s, v24.8h, #0
	WORD $0xfc438138 // ldur d24, [x9, #56]
	WORD $0x0f08a718 // sshll v24.8h, v24.8b, #0
	WORD $0x0f10a71c // sshll v28.4s, v24.4h, #0
	WORD $0x4f10a71d // sshll2 v29.4s, v24.8h, #0
	WORD $0x4e9a3b54 // zip1 v20.4s, v26.4s, v26.4s
	WORD $0x4e9c3b95 // zip1 v21.4s, v28.4s, v28.4s
	WORD $0x3cc0018c // ldur q12, [x12, #0]
	WORD $0x3cc4018d // ldur q13, [x12, #64]
	WORD $0x3cc001ae // ldur q14, [x13, #0]
	WORD $0x3cc401af // ldur q15, [x13, #64]
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x4e361dd1 // and v17.16b, v14.16b, v22.16b
	WORD $0x4f0c5631 // shl v17.16b, v17.16b, #4
	WORD $0x4eb11e10 // orr v16.16b, v16.16b, v17.16b
	WORD $0x6e398610 // sub v16.16b, v16.16b, v25.16b
	WORD $0x6f0c058c // ushr v12.16b, v12.16b, #4
	WORD $0x4e371dce // and v14.16b, v14.16b, v23.16b
	WORD $0x4eae1d8c // orr v12.16b, v12.16b, v14.16b
	WORD $0x6e39858c // sub v12.16b, v12.16b, v25.16b
	WORD $0x4e3f1db1 // and v17.16b, v13.16b, v31.16b
	WORD $0x4e361dee // and v14.16b, v15.16b, v22.16b
	WORD $0x4f0c55ce // shl v14.16b, v14.16b, #4
	WORD $0x4eae1e31 // orr v17.16b, v17.16b, v14.16b
	WORD $0x6e398631 // sub v17.16b, v17.16b, v25.16b
	WORD $0x6f0c05ad // ushr v13.16b, v13.16b, #4
	WORD $0x4e371def // and v15.16b, v15.16b, v23.16b
	WORD $0x4eaf1dad // orr v13.16b, v13.16b, v15.16b
	WORD $0x6e3985ad // sub v13.16b, v13.16b, v25.16b
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a628 // smmla v8.4s, v17.16b, v18.16b
	WORD $0x4e93a62a // smmla v10.4s, v17.16b, v19.16b
	WORD $0x3cc001f2 // ldur q18, [x15, #0]
	WORD $0x3cc101f3 // ldur q19, [x15, #16]
	WORD $0x4e92a589 // smmla v9.4s, v12.16b, v18.16b
	WORD $0x4e93a58b // smmla v11.4s, v12.16b, v19.16b
	WORD $0x3cc201f2 // ldur q18, [x15, #32]
	WORD $0x3cc301f3 // ldur q19, [x15, #48]
	WORD $0x4e92a5a9 // smmla v9.4s, v13.16b, v18.16b
	WORD $0x4e93a5ab // smmla v11.4s, v13.16b, v19.16b
	WORD $0x4eb49500 // mla v0.4s, v8.4s, v20.4s
	WORD $0x4eb59520 // mla v0.4s, v9.4s, v21.4s
	WORD $0x4eb49544 // mla v4.4s, v10.4s, v20.4s
	WORD $0x4eb59564 // mla v4.4s, v11.4s, v21.4s
	WORD $0x4e9a7b54 // zip2 v20.4s, v26.4s, v26.4s
	WORD $0x4e9c7b95 // zip2 v21.4s, v28.4s, v28.4s
	WORD $0x3cc1018c // ldur q12, [x12, #16]
	WORD $0x3cc5018d // ldur q13, [x12, #80]
	WORD $0x3cc101ae // ldur q14, [x13, #16]
	WORD $0x3cc501af // ldur q15, [x13, #80]
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x4e361dd1 // and v17.16b, v14.16b, v22.16b
	WORD $0x4f0c5631 // shl v17.16b, v17.16b, #4
	WORD $0x4eb11e10 // orr v16.16b, v16.16b, v17.16b
	WORD $0x6e398610 // sub v16.16b, v16.16b, v25.16b
	WORD $0x6f0c058c // ushr v12.16b, v12.16b, #4
	WORD $0x4e371dce // and v14.16b, v14.16b, v23.16b
	WORD $0x4eae1d8c // orr v12.16b, v12.16b, v14.16b
	WORD $0x6e39858c // sub v12.16b, v12.16b, v25.16b
	WORD $0x4e3f1db1 // and v17.16b, v13.16b, v31.16b
	WORD $0x4e361dee // and v14.16b, v15.16b, v22.16b
	WORD $0x4f0c55ce // shl v14.16b, v14.16b, #4
	WORD $0x4eae1e31 // orr v17.16b, v17.16b, v14.16b
	WORD $0x6e398631 // sub v17.16b, v17.16b, v25.16b
	WORD $0x6f0c05ad // ushr v13.16b, v13.16b, #4
	WORD $0x4e371def // and v15.16b, v15.16b, v23.16b
	WORD $0x4eaf1dad // orr v13.16b, v13.16b, v15.16b
	WORD $0x6e3985ad // sub v13.16b, v13.16b, v25.16b
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a628 // smmla v8.4s, v17.16b, v18.16b
	WORD $0x4e93a62a // smmla v10.4s, v17.16b, v19.16b
	WORD $0x3cc001f2 // ldur q18, [x15, #0]
	WORD $0x3cc101f3 // ldur q19, [x15, #16]
	WORD $0x4e92a589 // smmla v9.4s, v12.16b, v18.16b
	WORD $0x4e93a58b // smmla v11.4s, v12.16b, v19.16b
	WORD $0x3cc201f2 // ldur q18, [x15, #32]
	WORD $0x3cc301f3 // ldur q19, [x15, #48]
	WORD $0x4e92a5a9 // smmla v9.4s, v13.16b, v18.16b
	WORD $0x4e93a5ab // smmla v11.4s, v13.16b, v19.16b
	WORD $0x4eb49501 // mla v1.4s, v8.4s, v20.4s
	WORD $0x4eb59521 // mla v1.4s, v9.4s, v21.4s
	WORD $0x4eb49545 // mla v5.4s, v10.4s, v20.4s
	WORD $0x4eb59565 // mla v5.4s, v11.4s, v21.4s
	WORD $0x4e9b3b74 // zip1 v20.4s, v27.4s, v27.4s
	WORD $0x4e9d3bb5 // zip1 v21.4s, v29.4s, v29.4s
	WORD $0x3cc2018c // ldur q12, [x12, #32]
	WORD $0x3cc6018d // ldur q13, [x12, #96]
	WORD $0x3cc201ae // ldur q14, [x13, #32]
	WORD $0x3cc601af // ldur q15, [x13, #96]
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x4e361dd1 // and v17.16b, v14.16b, v22.16b
	WORD $0x4f0c5631 // shl v17.16b, v17.16b, #4
	WORD $0x4eb11e10 // orr v16.16b, v16.16b, v17.16b
	WORD $0x6e398610 // sub v16.16b, v16.16b, v25.16b
	WORD $0x6f0c058c // ushr v12.16b, v12.16b, #4
	WORD $0x4e371dce // and v14.16b, v14.16b, v23.16b
	WORD $0x4eae1d8c // orr v12.16b, v12.16b, v14.16b
	WORD $0x6e39858c // sub v12.16b, v12.16b, v25.16b
	WORD $0x4e3f1db1 // and v17.16b, v13.16b, v31.16b
	WORD $0x4e361dee // and v14.16b, v15.16b, v22.16b
	WORD $0x4f0c55ce // shl v14.16b, v14.16b, #4
	WORD $0x4eae1e31 // orr v17.16b, v17.16b, v14.16b
	WORD $0x6e398631 // sub v17.16b, v17.16b, v25.16b
	WORD $0x6f0c05ad // ushr v13.16b, v13.16b, #4
	WORD $0x4e371def // and v15.16b, v15.16b, v23.16b
	WORD $0x4eaf1dad // orr v13.16b, v13.16b, v15.16b
	WORD $0x6e3985ad // sub v13.16b, v13.16b, v25.16b
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a628 // smmla v8.4s, v17.16b, v18.16b
	WORD $0x4e93a62a // smmla v10.4s, v17.16b, v19.16b
	WORD $0x3cc001f2 // ldur q18, [x15, #0]
	WORD $0x3cc101f3 // ldur q19, [x15, #16]
	WORD $0x4e92a589 // smmla v9.4s, v12.16b, v18.16b
	WORD $0x4e93a58b // smmla v11.4s, v12.16b, v19.16b
	WORD $0x3cc201f2 // ldur q18, [x15, #32]
	WORD $0x3cc301f3 // ldur q19, [x15, #48]
	WORD $0x4e92a5a9 // smmla v9.4s, v13.16b, v18.16b
	WORD $0x4e93a5ab // smmla v11.4s, v13.16b, v19.16b
	WORD $0x4eb49502 // mla v2.4s, v8.4s, v20.4s
	WORD $0x4eb59522 // mla v2.4s, v9.4s, v21.4s
	WORD $0x4eb49546 // mla v6.4s, v10.4s, v20.4s
	WORD $0x4eb59566 // mla v6.4s, v11.4s, v21.4s
	WORD $0x4e9b7b74 // zip2 v20.4s, v27.4s, v27.4s
	WORD $0x4e9d7bb5 // zip2 v21.4s, v29.4s, v29.4s
	WORD $0x3cc3018c // ldur q12, [x12, #48]
	WORD $0x3cc7018d // ldur q13, [x12, #112]
	WORD $0x3cc301ae // ldur q14, [x13, #48]
	WORD $0x3cc701af // ldur q15, [x13, #112]
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x4e361dd1 // and v17.16b, v14.16b, v22.16b
	WORD $0x4f0c5631 // shl v17.16b, v17.16b, #4
	WORD $0x4eb11e10 // orr v16.16b, v16.16b, v17.16b
	WORD $0x6e398610 // sub v16.16b, v16.16b, v25.16b
	WORD $0x6f0c058c // ushr v12.16b, v12.16b, #4
	WORD $0x4e371dce // and v14.16b, v14.16b, v23.16b
	WORD $0x4eae1d8c // orr v12.16b, v12.16b, v14.16b
	WORD $0x6e39858c // sub v12.16b, v12.16b, v25.16b
	WORD $0x4e3f1db1 // and v17.16b, v13.16b, v31.16b
	WORD $0x4e361dee // and v14.16b, v15.16b, v22.16b
	WORD $0x4f0c55ce // shl v14.16b, v14.16b, #4
	WORD $0x4eae1e31 // orr v17.16b, v17.16b, v14.16b
	WORD $0x6e398631 // sub v17.16b, v17.16b, v25.16b
	WORD $0x6f0c05ad // ushr v13.16b, v13.16b, #4
	WORD $0x4e371def // and v15.16b, v15.16b, v23.16b
	WORD $0x4eaf1dad // orr v13.16b, v13.16b, v15.16b
	WORD $0x6e3985ad // sub v13.16b, v13.16b, v25.16b
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a628 // smmla v8.4s, v17.16b, v18.16b
	WORD $0x4e93a62a // smmla v10.4s, v17.16b, v19.16b
	WORD $0x3cc001f2 // ldur q18, [x15, #0]
	WORD $0x3cc101f3 // ldur q19, [x15, #16]
	WORD $0x4e92a589 // smmla v9.4s, v12.16b, v18.16b
	WORD $0x4e93a58b // smmla v11.4s, v12.16b, v19.16b
	WORD $0x3cc201f2 // ldur q18, [x15, #32]
	WORD $0x3cc301f3 // ldur q19, [x15, #48]
	WORD $0x4e92a5a9 // smmla v9.4s, v13.16b, v18.16b
	WORD $0x4e93a5ab // smmla v11.4s, v13.16b, v19.16b
	WORD $0x4eb49503 // mla v3.4s, v8.4s, v20.4s
	WORD $0x4eb59523 // mla v3.4s, v9.4s, v21.4s
	WORD $0x4eb49547 // mla v7.4s, v10.4s, v20.4s
	WORD $0x4eb59567 // mla v7.4s, v11.4s, v21.4s
	ADD	$400, R9, R12
	ADD	$1168, R9, R13
	ADD	$144, R10, R14
	ADD	$256, R14, R15
	WORD $0xfc420138 // ldur d24, [x9, #32]
	WORD $0x0f08a718 // sshll v24.8h, v24.8b, #0
	WORD $0x0f10a71a // sshll v26.4s, v24.4h, #0
	WORD $0x4f10a71b // sshll2 v27.4s, v24.8h, #0
	WORD $0xfc440138 // ldur d24, [x9, #64]
	WORD $0x0f08a718 // sshll v24.8h, v24.8b, #0
	WORD $0x0f10a71c // sshll v28.4s, v24.4h, #0
	WORD $0x4f10a71d // sshll2 v29.4s, v24.8h, #0
	WORD $0x4e9a3b54 // zip1 v20.4s, v26.4s, v26.4s
	WORD $0x4e9c3b95 // zip1 v21.4s, v28.4s, v28.4s
	WORD $0x3cc0018c // ldur q12, [x12, #0]
	WORD $0x3cc4018d // ldur q13, [x12, #64]
	WORD $0x3cc001ae // ldur q14, [x13, #0]
	WORD $0x3cc401af // ldur q15, [x13, #64]
	WORD $0x6f0e05ce // ushr v14.16b, v14.16b, #2
	WORD $0x6f0e05ef // ushr v15.16b, v15.16b, #2
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x4e361dd1 // and v17.16b, v14.16b, v22.16b
	WORD $0x4f0c5631 // shl v17.16b, v17.16b, #4
	WORD $0x4eb11e10 // orr v16.16b, v16.16b, v17.16b
	WORD $0x6e398610 // sub v16.16b, v16.16b, v25.16b
	WORD $0x6f0c058c // ushr v12.16b, v12.16b, #4
	WORD $0x4e371dce // and v14.16b, v14.16b, v23.16b
	WORD $0x4eae1d8c // orr v12.16b, v12.16b, v14.16b
	WORD $0x6e39858c // sub v12.16b, v12.16b, v25.16b
	WORD $0x4e3f1db1 // and v17.16b, v13.16b, v31.16b
	WORD $0x4e361dee // and v14.16b, v15.16b, v22.16b
	WORD $0x4f0c55ce // shl v14.16b, v14.16b, #4
	WORD $0x4eae1e31 // orr v17.16b, v17.16b, v14.16b
	WORD $0x6e398631 // sub v17.16b, v17.16b, v25.16b
	WORD $0x6f0c05ad // ushr v13.16b, v13.16b, #4
	WORD $0x4e371def // and v15.16b, v15.16b, v23.16b
	WORD $0x4eaf1dad // orr v13.16b, v13.16b, v15.16b
	WORD $0x6e3985ad // sub v13.16b, v13.16b, v25.16b
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a628 // smmla v8.4s, v17.16b, v18.16b
	WORD $0x4e93a62a // smmla v10.4s, v17.16b, v19.16b
	WORD $0x3cc001f2 // ldur q18, [x15, #0]
	WORD $0x3cc101f3 // ldur q19, [x15, #16]
	WORD $0x4e92a589 // smmla v9.4s, v12.16b, v18.16b
	WORD $0x4e93a58b // smmla v11.4s, v12.16b, v19.16b
	WORD $0x3cc201f2 // ldur q18, [x15, #32]
	WORD $0x3cc301f3 // ldur q19, [x15, #48]
	WORD $0x4e92a5a9 // smmla v9.4s, v13.16b, v18.16b
	WORD $0x4e93a5ab // smmla v11.4s, v13.16b, v19.16b
	WORD $0x4eb49500 // mla v0.4s, v8.4s, v20.4s
	WORD $0x4eb59520 // mla v0.4s, v9.4s, v21.4s
	WORD $0x4eb49544 // mla v4.4s, v10.4s, v20.4s
	WORD $0x4eb59564 // mla v4.4s, v11.4s, v21.4s
	WORD $0x4e9a7b54 // zip2 v20.4s, v26.4s, v26.4s
	WORD $0x4e9c7b95 // zip2 v21.4s, v28.4s, v28.4s
	WORD $0x3cc1018c // ldur q12, [x12, #16]
	WORD $0x3cc5018d // ldur q13, [x12, #80]
	WORD $0x3cc101ae // ldur q14, [x13, #16]
	WORD $0x3cc501af // ldur q15, [x13, #80]
	WORD $0x6f0e05ce // ushr v14.16b, v14.16b, #2
	WORD $0x6f0e05ef // ushr v15.16b, v15.16b, #2
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x4e361dd1 // and v17.16b, v14.16b, v22.16b
	WORD $0x4f0c5631 // shl v17.16b, v17.16b, #4
	WORD $0x4eb11e10 // orr v16.16b, v16.16b, v17.16b
	WORD $0x6e398610 // sub v16.16b, v16.16b, v25.16b
	WORD $0x6f0c058c // ushr v12.16b, v12.16b, #4
	WORD $0x4e371dce // and v14.16b, v14.16b, v23.16b
	WORD $0x4eae1d8c // orr v12.16b, v12.16b, v14.16b
	WORD $0x6e39858c // sub v12.16b, v12.16b, v25.16b
	WORD $0x4e3f1db1 // and v17.16b, v13.16b, v31.16b
	WORD $0x4e361dee // and v14.16b, v15.16b, v22.16b
	WORD $0x4f0c55ce // shl v14.16b, v14.16b, #4
	WORD $0x4eae1e31 // orr v17.16b, v17.16b, v14.16b
	WORD $0x6e398631 // sub v17.16b, v17.16b, v25.16b
	WORD $0x6f0c05ad // ushr v13.16b, v13.16b, #4
	WORD $0x4e371def // and v15.16b, v15.16b, v23.16b
	WORD $0x4eaf1dad // orr v13.16b, v13.16b, v15.16b
	WORD $0x6e3985ad // sub v13.16b, v13.16b, v25.16b
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a628 // smmla v8.4s, v17.16b, v18.16b
	WORD $0x4e93a62a // smmla v10.4s, v17.16b, v19.16b
	WORD $0x3cc001f2 // ldur q18, [x15, #0]
	WORD $0x3cc101f3 // ldur q19, [x15, #16]
	WORD $0x4e92a589 // smmla v9.4s, v12.16b, v18.16b
	WORD $0x4e93a58b // smmla v11.4s, v12.16b, v19.16b
	WORD $0x3cc201f2 // ldur q18, [x15, #32]
	WORD $0x3cc301f3 // ldur q19, [x15, #48]
	WORD $0x4e92a5a9 // smmla v9.4s, v13.16b, v18.16b
	WORD $0x4e93a5ab // smmla v11.4s, v13.16b, v19.16b
	WORD $0x4eb49501 // mla v1.4s, v8.4s, v20.4s
	WORD $0x4eb59521 // mla v1.4s, v9.4s, v21.4s
	WORD $0x4eb49545 // mla v5.4s, v10.4s, v20.4s
	WORD $0x4eb59565 // mla v5.4s, v11.4s, v21.4s
	WORD $0x4e9b3b74 // zip1 v20.4s, v27.4s, v27.4s
	WORD $0x4e9d3bb5 // zip1 v21.4s, v29.4s, v29.4s
	WORD $0x3cc2018c // ldur q12, [x12, #32]
	WORD $0x3cc6018d // ldur q13, [x12, #96]
	WORD $0x3cc201ae // ldur q14, [x13, #32]
	WORD $0x3cc601af // ldur q15, [x13, #96]
	WORD $0x6f0e05ce // ushr v14.16b, v14.16b, #2
	WORD $0x6f0e05ef // ushr v15.16b, v15.16b, #2
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x4e361dd1 // and v17.16b, v14.16b, v22.16b
	WORD $0x4f0c5631 // shl v17.16b, v17.16b, #4
	WORD $0x4eb11e10 // orr v16.16b, v16.16b, v17.16b
	WORD $0x6e398610 // sub v16.16b, v16.16b, v25.16b
	WORD $0x6f0c058c // ushr v12.16b, v12.16b, #4
	WORD $0x4e371dce // and v14.16b, v14.16b, v23.16b
	WORD $0x4eae1d8c // orr v12.16b, v12.16b, v14.16b
	WORD $0x6e39858c // sub v12.16b, v12.16b, v25.16b
	WORD $0x4e3f1db1 // and v17.16b, v13.16b, v31.16b
	WORD $0x4e361dee // and v14.16b, v15.16b, v22.16b
	WORD $0x4f0c55ce // shl v14.16b, v14.16b, #4
	WORD $0x4eae1e31 // orr v17.16b, v17.16b, v14.16b
	WORD $0x6e398631 // sub v17.16b, v17.16b, v25.16b
	WORD $0x6f0c05ad // ushr v13.16b, v13.16b, #4
	WORD $0x4e371def // and v15.16b, v15.16b, v23.16b
	WORD $0x4eaf1dad // orr v13.16b, v13.16b, v15.16b
	WORD $0x6e3985ad // sub v13.16b, v13.16b, v25.16b
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a628 // smmla v8.4s, v17.16b, v18.16b
	WORD $0x4e93a62a // smmla v10.4s, v17.16b, v19.16b
	WORD $0x3cc001f2 // ldur q18, [x15, #0]
	WORD $0x3cc101f3 // ldur q19, [x15, #16]
	WORD $0x4e92a589 // smmla v9.4s, v12.16b, v18.16b
	WORD $0x4e93a58b // smmla v11.4s, v12.16b, v19.16b
	WORD $0x3cc201f2 // ldur q18, [x15, #32]
	WORD $0x3cc301f3 // ldur q19, [x15, #48]
	WORD $0x4e92a5a9 // smmla v9.4s, v13.16b, v18.16b
	WORD $0x4e93a5ab // smmla v11.4s, v13.16b, v19.16b
	WORD $0x4eb49502 // mla v2.4s, v8.4s, v20.4s
	WORD $0x4eb59522 // mla v2.4s, v9.4s, v21.4s
	WORD $0x4eb49546 // mla v6.4s, v10.4s, v20.4s
	WORD $0x4eb59566 // mla v6.4s, v11.4s, v21.4s
	WORD $0x4e9b7b74 // zip2 v20.4s, v27.4s, v27.4s
	WORD $0x4e9d7bb5 // zip2 v21.4s, v29.4s, v29.4s
	WORD $0x3cc3018c // ldur q12, [x12, #48]
	WORD $0x3cc7018d // ldur q13, [x12, #112]
	WORD $0x3cc301ae // ldur q14, [x13, #48]
	WORD $0x3cc701af // ldur q15, [x13, #112]
	WORD $0x6f0e05ce // ushr v14.16b, v14.16b, #2
	WORD $0x6f0e05ef // ushr v15.16b, v15.16b, #2
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x4e361dd1 // and v17.16b, v14.16b, v22.16b
	WORD $0x4f0c5631 // shl v17.16b, v17.16b, #4
	WORD $0x4eb11e10 // orr v16.16b, v16.16b, v17.16b
	WORD $0x6e398610 // sub v16.16b, v16.16b, v25.16b
	WORD $0x6f0c058c // ushr v12.16b, v12.16b, #4
	WORD $0x4e371dce // and v14.16b, v14.16b, v23.16b
	WORD $0x4eae1d8c // orr v12.16b, v12.16b, v14.16b
	WORD $0x6e39858c // sub v12.16b, v12.16b, v25.16b
	WORD $0x4e3f1db1 // and v17.16b, v13.16b, v31.16b
	WORD $0x4e361dee // and v14.16b, v15.16b, v22.16b
	WORD $0x4f0c55ce // shl v14.16b, v14.16b, #4
	WORD $0x4eae1e31 // orr v17.16b, v17.16b, v14.16b
	WORD $0x6e398631 // sub v17.16b, v17.16b, v25.16b
	WORD $0x6f0c05ad // ushr v13.16b, v13.16b, #4
	WORD $0x4e371def // and v15.16b, v15.16b, v23.16b
	WORD $0x4eaf1dad // orr v13.16b, v13.16b, v15.16b
	WORD $0x6e3985ad // sub v13.16b, v13.16b, v25.16b
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a628 // smmla v8.4s, v17.16b, v18.16b
	WORD $0x4e93a62a // smmla v10.4s, v17.16b, v19.16b
	WORD $0x3cc001f2 // ldur q18, [x15, #0]
	WORD $0x3cc101f3 // ldur q19, [x15, #16]
	WORD $0x4e92a589 // smmla v9.4s, v12.16b, v18.16b
	WORD $0x4e93a58b // smmla v11.4s, v12.16b, v19.16b
	WORD $0x3cc201f2 // ldur q18, [x15, #32]
	WORD $0x3cc301f3 // ldur q19, [x15, #48]
	WORD $0x4e92a5a9 // smmla v9.4s, v13.16b, v18.16b
	WORD $0x4e93a5ab // smmla v11.4s, v13.16b, v19.16b
	WORD $0x4eb49503 // mla v3.4s, v8.4s, v20.4s
	WORD $0x4eb59523 // mla v3.4s, v9.4s, v21.4s
	WORD $0x4eb49547 // mla v7.4s, v10.4s, v20.4s
	WORD $0x4eb59567 // mla v7.4s, v11.4s, v21.4s
	ADD	$528, R9, R12
	ADD	$1296, R9, R13
	ADD	$208, R10, R14
	ADD	$256, R14, R15
	WORD $0xfc428138 // ldur d24, [x9, #40]
	WORD $0x0f08a718 // sshll v24.8h, v24.8b, #0
	WORD $0x0f10a71a // sshll v26.4s, v24.4h, #0
	WORD $0x4f10a71b // sshll2 v27.4s, v24.8h, #0
	WORD $0xfc448138 // ldur d24, [x9, #72]
	WORD $0x0f08a718 // sshll v24.8h, v24.8b, #0
	WORD $0x0f10a71c // sshll v28.4s, v24.4h, #0
	WORD $0x4f10a71d // sshll2 v29.4s, v24.8h, #0
	WORD $0x4e9a3b54 // zip1 v20.4s, v26.4s, v26.4s
	WORD $0x4e9c3b95 // zip1 v21.4s, v28.4s, v28.4s
	WORD $0x3cc0018c // ldur q12, [x12, #0]
	WORD $0x3cc4018d // ldur q13, [x12, #64]
	WORD $0x3cc001ae // ldur q14, [x13, #0]
	WORD $0x3cc401af // ldur q15, [x13, #64]
	WORD $0x6f0e05ce // ushr v14.16b, v14.16b, #2
	WORD $0x6f0e05ef // ushr v15.16b, v15.16b, #2
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x4e361dd1 // and v17.16b, v14.16b, v22.16b
	WORD $0x4f0c5631 // shl v17.16b, v17.16b, #4
	WORD $0x4eb11e10 // orr v16.16b, v16.16b, v17.16b
	WORD $0x6e398610 // sub v16.16b, v16.16b, v25.16b
	WORD $0x6f0c058c // ushr v12.16b, v12.16b, #4
	WORD $0x4e371dce // and v14.16b, v14.16b, v23.16b
	WORD $0x4eae1d8c // orr v12.16b, v12.16b, v14.16b
	WORD $0x6e39858c // sub v12.16b, v12.16b, v25.16b
	WORD $0x4e3f1db1 // and v17.16b, v13.16b, v31.16b
	WORD $0x4e361dee // and v14.16b, v15.16b, v22.16b
	WORD $0x4f0c55ce // shl v14.16b, v14.16b, #4
	WORD $0x4eae1e31 // orr v17.16b, v17.16b, v14.16b
	WORD $0x6e398631 // sub v17.16b, v17.16b, v25.16b
	WORD $0x6f0c05ad // ushr v13.16b, v13.16b, #4
	WORD $0x4e371def // and v15.16b, v15.16b, v23.16b
	WORD $0x4eaf1dad // orr v13.16b, v13.16b, v15.16b
	WORD $0x6e3985ad // sub v13.16b, v13.16b, v25.16b
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a628 // smmla v8.4s, v17.16b, v18.16b
	WORD $0x4e93a62a // smmla v10.4s, v17.16b, v19.16b
	WORD $0x3cc001f2 // ldur q18, [x15, #0]
	WORD $0x3cc101f3 // ldur q19, [x15, #16]
	WORD $0x4e92a589 // smmla v9.4s, v12.16b, v18.16b
	WORD $0x4e93a58b // smmla v11.4s, v12.16b, v19.16b
	WORD $0x3cc201f2 // ldur q18, [x15, #32]
	WORD $0x3cc301f3 // ldur q19, [x15, #48]
	WORD $0x4e92a5a9 // smmla v9.4s, v13.16b, v18.16b
	WORD $0x4e93a5ab // smmla v11.4s, v13.16b, v19.16b
	WORD $0x4eb49500 // mla v0.4s, v8.4s, v20.4s
	WORD $0x4eb59520 // mla v0.4s, v9.4s, v21.4s
	WORD $0x4eb49544 // mla v4.4s, v10.4s, v20.4s
	WORD $0x4eb59564 // mla v4.4s, v11.4s, v21.4s
	WORD $0x4e9a7b54 // zip2 v20.4s, v26.4s, v26.4s
	WORD $0x4e9c7b95 // zip2 v21.4s, v28.4s, v28.4s
	WORD $0x3cc1018c // ldur q12, [x12, #16]
	WORD $0x3cc5018d // ldur q13, [x12, #80]
	WORD $0x3cc101ae // ldur q14, [x13, #16]
	WORD $0x3cc501af // ldur q15, [x13, #80]
	WORD $0x6f0e05ce // ushr v14.16b, v14.16b, #2
	WORD $0x6f0e05ef // ushr v15.16b, v15.16b, #2
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x4e361dd1 // and v17.16b, v14.16b, v22.16b
	WORD $0x4f0c5631 // shl v17.16b, v17.16b, #4
	WORD $0x4eb11e10 // orr v16.16b, v16.16b, v17.16b
	WORD $0x6e398610 // sub v16.16b, v16.16b, v25.16b
	WORD $0x6f0c058c // ushr v12.16b, v12.16b, #4
	WORD $0x4e371dce // and v14.16b, v14.16b, v23.16b
	WORD $0x4eae1d8c // orr v12.16b, v12.16b, v14.16b
	WORD $0x6e39858c // sub v12.16b, v12.16b, v25.16b
	WORD $0x4e3f1db1 // and v17.16b, v13.16b, v31.16b
	WORD $0x4e361dee // and v14.16b, v15.16b, v22.16b
	WORD $0x4f0c55ce // shl v14.16b, v14.16b, #4
	WORD $0x4eae1e31 // orr v17.16b, v17.16b, v14.16b
	WORD $0x6e398631 // sub v17.16b, v17.16b, v25.16b
	WORD $0x6f0c05ad // ushr v13.16b, v13.16b, #4
	WORD $0x4e371def // and v15.16b, v15.16b, v23.16b
	WORD $0x4eaf1dad // orr v13.16b, v13.16b, v15.16b
	WORD $0x6e3985ad // sub v13.16b, v13.16b, v25.16b
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a628 // smmla v8.4s, v17.16b, v18.16b
	WORD $0x4e93a62a // smmla v10.4s, v17.16b, v19.16b
	WORD $0x3cc001f2 // ldur q18, [x15, #0]
	WORD $0x3cc101f3 // ldur q19, [x15, #16]
	WORD $0x4e92a589 // smmla v9.4s, v12.16b, v18.16b
	WORD $0x4e93a58b // smmla v11.4s, v12.16b, v19.16b
	WORD $0x3cc201f2 // ldur q18, [x15, #32]
	WORD $0x3cc301f3 // ldur q19, [x15, #48]
	WORD $0x4e92a5a9 // smmla v9.4s, v13.16b, v18.16b
	WORD $0x4e93a5ab // smmla v11.4s, v13.16b, v19.16b
	WORD $0x4eb49501 // mla v1.4s, v8.4s, v20.4s
	WORD $0x4eb59521 // mla v1.4s, v9.4s, v21.4s
	WORD $0x4eb49545 // mla v5.4s, v10.4s, v20.4s
	WORD $0x4eb59565 // mla v5.4s, v11.4s, v21.4s
	WORD $0x4e9b3b74 // zip1 v20.4s, v27.4s, v27.4s
	WORD $0x4e9d3bb5 // zip1 v21.4s, v29.4s, v29.4s
	WORD $0x3cc2018c // ldur q12, [x12, #32]
	WORD $0x3cc6018d // ldur q13, [x12, #96]
	WORD $0x3cc201ae // ldur q14, [x13, #32]
	WORD $0x3cc601af // ldur q15, [x13, #96]
	WORD $0x6f0e05ce // ushr v14.16b, v14.16b, #2
	WORD $0x6f0e05ef // ushr v15.16b, v15.16b, #2
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x4e361dd1 // and v17.16b, v14.16b, v22.16b
	WORD $0x4f0c5631 // shl v17.16b, v17.16b, #4
	WORD $0x4eb11e10 // orr v16.16b, v16.16b, v17.16b
	WORD $0x6e398610 // sub v16.16b, v16.16b, v25.16b
	WORD $0x6f0c058c // ushr v12.16b, v12.16b, #4
	WORD $0x4e371dce // and v14.16b, v14.16b, v23.16b
	WORD $0x4eae1d8c // orr v12.16b, v12.16b, v14.16b
	WORD $0x6e39858c // sub v12.16b, v12.16b, v25.16b
	WORD $0x4e3f1db1 // and v17.16b, v13.16b, v31.16b
	WORD $0x4e361dee // and v14.16b, v15.16b, v22.16b
	WORD $0x4f0c55ce // shl v14.16b, v14.16b, #4
	WORD $0x4eae1e31 // orr v17.16b, v17.16b, v14.16b
	WORD $0x6e398631 // sub v17.16b, v17.16b, v25.16b
	WORD $0x6f0c05ad // ushr v13.16b, v13.16b, #4
	WORD $0x4e371def // and v15.16b, v15.16b, v23.16b
	WORD $0x4eaf1dad // orr v13.16b, v13.16b, v15.16b
	WORD $0x6e3985ad // sub v13.16b, v13.16b, v25.16b
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a628 // smmla v8.4s, v17.16b, v18.16b
	WORD $0x4e93a62a // smmla v10.4s, v17.16b, v19.16b
	WORD $0x3cc001f2 // ldur q18, [x15, #0]
	WORD $0x3cc101f3 // ldur q19, [x15, #16]
	WORD $0x4e92a589 // smmla v9.4s, v12.16b, v18.16b
	WORD $0x4e93a58b // smmla v11.4s, v12.16b, v19.16b
	WORD $0x3cc201f2 // ldur q18, [x15, #32]
	WORD $0x3cc301f3 // ldur q19, [x15, #48]
	WORD $0x4e92a5a9 // smmla v9.4s, v13.16b, v18.16b
	WORD $0x4e93a5ab // smmla v11.4s, v13.16b, v19.16b
	WORD $0x4eb49502 // mla v2.4s, v8.4s, v20.4s
	WORD $0x4eb59522 // mla v2.4s, v9.4s, v21.4s
	WORD $0x4eb49546 // mla v6.4s, v10.4s, v20.4s
	WORD $0x4eb59566 // mla v6.4s, v11.4s, v21.4s
	WORD $0x4e9b7b74 // zip2 v20.4s, v27.4s, v27.4s
	WORD $0x4e9d7bb5 // zip2 v21.4s, v29.4s, v29.4s
	WORD $0x3cc3018c // ldur q12, [x12, #48]
	WORD $0x3cc7018d // ldur q13, [x12, #112]
	WORD $0x3cc301ae // ldur q14, [x13, #48]
	WORD $0x3cc701af // ldur q15, [x13, #112]
	WORD $0x6f0e05ce // ushr v14.16b, v14.16b, #2
	WORD $0x6f0e05ef // ushr v15.16b, v15.16b, #2
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x4e361dd1 // and v17.16b, v14.16b, v22.16b
	WORD $0x4f0c5631 // shl v17.16b, v17.16b, #4
	WORD $0x4eb11e10 // orr v16.16b, v16.16b, v17.16b
	WORD $0x6e398610 // sub v16.16b, v16.16b, v25.16b
	WORD $0x6f0c058c // ushr v12.16b, v12.16b, #4
	WORD $0x4e371dce // and v14.16b, v14.16b, v23.16b
	WORD $0x4eae1d8c // orr v12.16b, v12.16b, v14.16b
	WORD $0x6e39858c // sub v12.16b, v12.16b, v25.16b
	WORD $0x4e3f1db1 // and v17.16b, v13.16b, v31.16b
	WORD $0x4e361dee // and v14.16b, v15.16b, v22.16b
	WORD $0x4f0c55ce // shl v14.16b, v14.16b, #4
	WORD $0x4eae1e31 // orr v17.16b, v17.16b, v14.16b
	WORD $0x6e398631 // sub v17.16b, v17.16b, v25.16b
	WORD $0x6f0c05ad // ushr v13.16b, v13.16b, #4
	WORD $0x4e371def // and v15.16b, v15.16b, v23.16b
	WORD $0x4eaf1dad // orr v13.16b, v13.16b, v15.16b
	WORD $0x6e3985ad // sub v13.16b, v13.16b, v25.16b
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a628 // smmla v8.4s, v17.16b, v18.16b
	WORD $0x4e93a62a // smmla v10.4s, v17.16b, v19.16b
	WORD $0x3cc001f2 // ldur q18, [x15, #0]
	WORD $0x3cc101f3 // ldur q19, [x15, #16]
	WORD $0x4e92a589 // smmla v9.4s, v12.16b, v18.16b
	WORD $0x4e93a58b // smmla v11.4s, v12.16b, v19.16b
	WORD $0x3cc201f2 // ldur q18, [x15, #32]
	WORD $0x3cc301f3 // ldur q19, [x15, #48]
	WORD $0x4e92a5a9 // smmla v9.4s, v13.16b, v18.16b
	WORD $0x4e93a5ab // smmla v11.4s, v13.16b, v19.16b
	WORD $0x4eb49503 // mla v3.4s, v8.4s, v20.4s
	WORD $0x4eb59523 // mla v3.4s, v9.4s, v21.4s
	WORD $0x4eb49547 // mla v7.4s, v10.4s, v20.4s
	WORD $0x4eb59567 // mla v7.4s, v11.4s, v21.4s
	ADD	$656, R9, R12
	ADD	$1424, R9, R13
	ADD	$528, R10, R14
	ADD	$256, R14, R15
	WORD $0xfc450138 // ldur d24, [x9, #80]
	WORD $0x0f08a718 // sshll v24.8h, v24.8b, #0
	WORD $0x0f10a71a // sshll v26.4s, v24.4h, #0
	WORD $0x4f10a71b // sshll2 v27.4s, v24.8h, #0
	WORD $0xfc470138 // ldur d24, [x9, #112]
	WORD $0x0f08a718 // sshll v24.8h, v24.8b, #0
	WORD $0x0f10a71c // sshll v28.4s, v24.4h, #0
	WORD $0x4f10a71d // sshll2 v29.4s, v24.8h, #0
	WORD $0x4e9a3b54 // zip1 v20.4s, v26.4s, v26.4s
	WORD $0x4e9c3b95 // zip1 v21.4s, v28.4s, v28.4s
	WORD $0x3cc0018c // ldur q12, [x12, #0]
	WORD $0x3cc4018d // ldur q13, [x12, #64]
	WORD $0x3cc001ae // ldur q14, [x13, #0]
	WORD $0x3cc401af // ldur q15, [x13, #64]
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x4e361dd1 // and v17.16b, v14.16b, v22.16b
	WORD $0x4f0c5631 // shl v17.16b, v17.16b, #4
	WORD $0x4eb11e10 // orr v16.16b, v16.16b, v17.16b
	WORD $0x6e398610 // sub v16.16b, v16.16b, v25.16b
	WORD $0x6f0c058c // ushr v12.16b, v12.16b, #4
	WORD $0x4e371dce // and v14.16b, v14.16b, v23.16b
	WORD $0x4eae1d8c // orr v12.16b, v12.16b, v14.16b
	WORD $0x6e39858c // sub v12.16b, v12.16b, v25.16b
	WORD $0x4e3f1db1 // and v17.16b, v13.16b, v31.16b
	WORD $0x4e361dee // and v14.16b, v15.16b, v22.16b
	WORD $0x4f0c55ce // shl v14.16b, v14.16b, #4
	WORD $0x4eae1e31 // orr v17.16b, v17.16b, v14.16b
	WORD $0x6e398631 // sub v17.16b, v17.16b, v25.16b
	WORD $0x6f0c05ad // ushr v13.16b, v13.16b, #4
	WORD $0x4e371def // and v15.16b, v15.16b, v23.16b
	WORD $0x4eaf1dad // orr v13.16b, v13.16b, v15.16b
	WORD $0x6e3985ad // sub v13.16b, v13.16b, v25.16b
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a628 // smmla v8.4s, v17.16b, v18.16b
	WORD $0x4e93a62a // smmla v10.4s, v17.16b, v19.16b
	WORD $0x3cc001f2 // ldur q18, [x15, #0]
	WORD $0x3cc101f3 // ldur q19, [x15, #16]
	WORD $0x4e92a589 // smmla v9.4s, v12.16b, v18.16b
	WORD $0x4e93a58b // smmla v11.4s, v12.16b, v19.16b
	WORD $0x3cc201f2 // ldur q18, [x15, #32]
	WORD $0x3cc301f3 // ldur q19, [x15, #48]
	WORD $0x4e92a5a9 // smmla v9.4s, v13.16b, v18.16b
	WORD $0x4e93a5ab // smmla v11.4s, v13.16b, v19.16b
	WORD $0x4eb49500 // mla v0.4s, v8.4s, v20.4s
	WORD $0x4eb59520 // mla v0.4s, v9.4s, v21.4s
	WORD $0x4eb49544 // mla v4.4s, v10.4s, v20.4s
	WORD $0x4eb59564 // mla v4.4s, v11.4s, v21.4s
	WORD $0x4e9a7b54 // zip2 v20.4s, v26.4s, v26.4s
	WORD $0x4e9c7b95 // zip2 v21.4s, v28.4s, v28.4s
	WORD $0x3cc1018c // ldur q12, [x12, #16]
	WORD $0x3cc5018d // ldur q13, [x12, #80]
	WORD $0x3cc101ae // ldur q14, [x13, #16]
	WORD $0x3cc501af // ldur q15, [x13, #80]
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x4e361dd1 // and v17.16b, v14.16b, v22.16b
	WORD $0x4f0c5631 // shl v17.16b, v17.16b, #4
	WORD $0x4eb11e10 // orr v16.16b, v16.16b, v17.16b
	WORD $0x6e398610 // sub v16.16b, v16.16b, v25.16b
	WORD $0x6f0c058c // ushr v12.16b, v12.16b, #4
	WORD $0x4e371dce // and v14.16b, v14.16b, v23.16b
	WORD $0x4eae1d8c // orr v12.16b, v12.16b, v14.16b
	WORD $0x6e39858c // sub v12.16b, v12.16b, v25.16b
	WORD $0x4e3f1db1 // and v17.16b, v13.16b, v31.16b
	WORD $0x4e361dee // and v14.16b, v15.16b, v22.16b
	WORD $0x4f0c55ce // shl v14.16b, v14.16b, #4
	WORD $0x4eae1e31 // orr v17.16b, v17.16b, v14.16b
	WORD $0x6e398631 // sub v17.16b, v17.16b, v25.16b
	WORD $0x6f0c05ad // ushr v13.16b, v13.16b, #4
	WORD $0x4e371def // and v15.16b, v15.16b, v23.16b
	WORD $0x4eaf1dad // orr v13.16b, v13.16b, v15.16b
	WORD $0x6e3985ad // sub v13.16b, v13.16b, v25.16b
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a628 // smmla v8.4s, v17.16b, v18.16b
	WORD $0x4e93a62a // smmla v10.4s, v17.16b, v19.16b
	WORD $0x3cc001f2 // ldur q18, [x15, #0]
	WORD $0x3cc101f3 // ldur q19, [x15, #16]
	WORD $0x4e92a589 // smmla v9.4s, v12.16b, v18.16b
	WORD $0x4e93a58b // smmla v11.4s, v12.16b, v19.16b
	WORD $0x3cc201f2 // ldur q18, [x15, #32]
	WORD $0x3cc301f3 // ldur q19, [x15, #48]
	WORD $0x4e92a5a9 // smmla v9.4s, v13.16b, v18.16b
	WORD $0x4e93a5ab // smmla v11.4s, v13.16b, v19.16b
	WORD $0x4eb49501 // mla v1.4s, v8.4s, v20.4s
	WORD $0x4eb59521 // mla v1.4s, v9.4s, v21.4s
	WORD $0x4eb49545 // mla v5.4s, v10.4s, v20.4s
	WORD $0x4eb59565 // mla v5.4s, v11.4s, v21.4s
	WORD $0x4e9b3b74 // zip1 v20.4s, v27.4s, v27.4s
	WORD $0x4e9d3bb5 // zip1 v21.4s, v29.4s, v29.4s
	WORD $0x3cc2018c // ldur q12, [x12, #32]
	WORD $0x3cc6018d // ldur q13, [x12, #96]
	WORD $0x3cc201ae // ldur q14, [x13, #32]
	WORD $0x3cc601af // ldur q15, [x13, #96]
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x4e361dd1 // and v17.16b, v14.16b, v22.16b
	WORD $0x4f0c5631 // shl v17.16b, v17.16b, #4
	WORD $0x4eb11e10 // orr v16.16b, v16.16b, v17.16b
	WORD $0x6e398610 // sub v16.16b, v16.16b, v25.16b
	WORD $0x6f0c058c // ushr v12.16b, v12.16b, #4
	WORD $0x4e371dce // and v14.16b, v14.16b, v23.16b
	WORD $0x4eae1d8c // orr v12.16b, v12.16b, v14.16b
	WORD $0x6e39858c // sub v12.16b, v12.16b, v25.16b
	WORD $0x4e3f1db1 // and v17.16b, v13.16b, v31.16b
	WORD $0x4e361dee // and v14.16b, v15.16b, v22.16b
	WORD $0x4f0c55ce // shl v14.16b, v14.16b, #4
	WORD $0x4eae1e31 // orr v17.16b, v17.16b, v14.16b
	WORD $0x6e398631 // sub v17.16b, v17.16b, v25.16b
	WORD $0x6f0c05ad // ushr v13.16b, v13.16b, #4
	WORD $0x4e371def // and v15.16b, v15.16b, v23.16b
	WORD $0x4eaf1dad // orr v13.16b, v13.16b, v15.16b
	WORD $0x6e3985ad // sub v13.16b, v13.16b, v25.16b
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a628 // smmla v8.4s, v17.16b, v18.16b
	WORD $0x4e93a62a // smmla v10.4s, v17.16b, v19.16b
	WORD $0x3cc001f2 // ldur q18, [x15, #0]
	WORD $0x3cc101f3 // ldur q19, [x15, #16]
	WORD $0x4e92a589 // smmla v9.4s, v12.16b, v18.16b
	WORD $0x4e93a58b // smmla v11.4s, v12.16b, v19.16b
	WORD $0x3cc201f2 // ldur q18, [x15, #32]
	WORD $0x3cc301f3 // ldur q19, [x15, #48]
	WORD $0x4e92a5a9 // smmla v9.4s, v13.16b, v18.16b
	WORD $0x4e93a5ab // smmla v11.4s, v13.16b, v19.16b
	WORD $0x4eb49502 // mla v2.4s, v8.4s, v20.4s
	WORD $0x4eb59522 // mla v2.4s, v9.4s, v21.4s
	WORD $0x4eb49546 // mla v6.4s, v10.4s, v20.4s
	WORD $0x4eb59566 // mla v6.4s, v11.4s, v21.4s
	WORD $0x4e9b7b74 // zip2 v20.4s, v27.4s, v27.4s
	WORD $0x4e9d7bb5 // zip2 v21.4s, v29.4s, v29.4s
	WORD $0x3cc3018c // ldur q12, [x12, #48]
	WORD $0x3cc7018d // ldur q13, [x12, #112]
	WORD $0x3cc301ae // ldur q14, [x13, #48]
	WORD $0x3cc701af // ldur q15, [x13, #112]
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x4e361dd1 // and v17.16b, v14.16b, v22.16b
	WORD $0x4f0c5631 // shl v17.16b, v17.16b, #4
	WORD $0x4eb11e10 // orr v16.16b, v16.16b, v17.16b
	WORD $0x6e398610 // sub v16.16b, v16.16b, v25.16b
	WORD $0x6f0c058c // ushr v12.16b, v12.16b, #4
	WORD $0x4e371dce // and v14.16b, v14.16b, v23.16b
	WORD $0x4eae1d8c // orr v12.16b, v12.16b, v14.16b
	WORD $0x6e39858c // sub v12.16b, v12.16b, v25.16b
	WORD $0x4e3f1db1 // and v17.16b, v13.16b, v31.16b
	WORD $0x4e361dee // and v14.16b, v15.16b, v22.16b
	WORD $0x4f0c55ce // shl v14.16b, v14.16b, #4
	WORD $0x4eae1e31 // orr v17.16b, v17.16b, v14.16b
	WORD $0x6e398631 // sub v17.16b, v17.16b, v25.16b
	WORD $0x6f0c05ad // ushr v13.16b, v13.16b, #4
	WORD $0x4e371def // and v15.16b, v15.16b, v23.16b
	WORD $0x4eaf1dad // orr v13.16b, v13.16b, v15.16b
	WORD $0x6e3985ad // sub v13.16b, v13.16b, v25.16b
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a628 // smmla v8.4s, v17.16b, v18.16b
	WORD $0x4e93a62a // smmla v10.4s, v17.16b, v19.16b
	WORD $0x3cc001f2 // ldur q18, [x15, #0]
	WORD $0x3cc101f3 // ldur q19, [x15, #16]
	WORD $0x4e92a589 // smmla v9.4s, v12.16b, v18.16b
	WORD $0x4e93a58b // smmla v11.4s, v12.16b, v19.16b
	WORD $0x3cc201f2 // ldur q18, [x15, #32]
	WORD $0x3cc301f3 // ldur q19, [x15, #48]
	WORD $0x4e92a5a9 // smmla v9.4s, v13.16b, v18.16b
	WORD $0x4e93a5ab // smmla v11.4s, v13.16b, v19.16b
	WORD $0x4eb49503 // mla v3.4s, v8.4s, v20.4s
	WORD $0x4eb59523 // mla v3.4s, v9.4s, v21.4s
	WORD $0x4eb49547 // mla v7.4s, v10.4s, v20.4s
	WORD $0x4eb59567 // mla v7.4s, v11.4s, v21.4s
	ADD	$784, R9, R12
	ADD	$1552, R9, R13
	ADD	$592, R10, R14
	ADD	$256, R14, R15
	WORD $0xfc458138 // ldur d24, [x9, #88]
	WORD $0x0f08a718 // sshll v24.8h, v24.8b, #0
	WORD $0x0f10a71a // sshll v26.4s, v24.4h, #0
	WORD $0x4f10a71b // sshll2 v27.4s, v24.8h, #0
	WORD $0xfc478138 // ldur d24, [x9, #120]
	WORD $0x0f08a718 // sshll v24.8h, v24.8b, #0
	WORD $0x0f10a71c // sshll v28.4s, v24.4h, #0
	WORD $0x4f10a71d // sshll2 v29.4s, v24.8h, #0
	WORD $0x4e9a3b54 // zip1 v20.4s, v26.4s, v26.4s
	WORD $0x4e9c3b95 // zip1 v21.4s, v28.4s, v28.4s
	WORD $0x3cc0018c // ldur q12, [x12, #0]
	WORD $0x3cc4018d // ldur q13, [x12, #64]
	WORD $0x3cc001ae // ldur q14, [x13, #0]
	WORD $0x3cc401af // ldur q15, [x13, #64]
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x4e361dd1 // and v17.16b, v14.16b, v22.16b
	WORD $0x4f0c5631 // shl v17.16b, v17.16b, #4
	WORD $0x4eb11e10 // orr v16.16b, v16.16b, v17.16b
	WORD $0x6e398610 // sub v16.16b, v16.16b, v25.16b
	WORD $0x6f0c058c // ushr v12.16b, v12.16b, #4
	WORD $0x4e371dce // and v14.16b, v14.16b, v23.16b
	WORD $0x4eae1d8c // orr v12.16b, v12.16b, v14.16b
	WORD $0x6e39858c // sub v12.16b, v12.16b, v25.16b
	WORD $0x4e3f1db1 // and v17.16b, v13.16b, v31.16b
	WORD $0x4e361dee // and v14.16b, v15.16b, v22.16b
	WORD $0x4f0c55ce // shl v14.16b, v14.16b, #4
	WORD $0x4eae1e31 // orr v17.16b, v17.16b, v14.16b
	WORD $0x6e398631 // sub v17.16b, v17.16b, v25.16b
	WORD $0x6f0c05ad // ushr v13.16b, v13.16b, #4
	WORD $0x4e371def // and v15.16b, v15.16b, v23.16b
	WORD $0x4eaf1dad // orr v13.16b, v13.16b, v15.16b
	WORD $0x6e3985ad // sub v13.16b, v13.16b, v25.16b
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a628 // smmla v8.4s, v17.16b, v18.16b
	WORD $0x4e93a62a // smmla v10.4s, v17.16b, v19.16b
	WORD $0x3cc001f2 // ldur q18, [x15, #0]
	WORD $0x3cc101f3 // ldur q19, [x15, #16]
	WORD $0x4e92a589 // smmla v9.4s, v12.16b, v18.16b
	WORD $0x4e93a58b // smmla v11.4s, v12.16b, v19.16b
	WORD $0x3cc201f2 // ldur q18, [x15, #32]
	WORD $0x3cc301f3 // ldur q19, [x15, #48]
	WORD $0x4e92a5a9 // smmla v9.4s, v13.16b, v18.16b
	WORD $0x4e93a5ab // smmla v11.4s, v13.16b, v19.16b
	WORD $0x4eb49500 // mla v0.4s, v8.4s, v20.4s
	WORD $0x4eb59520 // mla v0.4s, v9.4s, v21.4s
	WORD $0x4eb49544 // mla v4.4s, v10.4s, v20.4s
	WORD $0x4eb59564 // mla v4.4s, v11.4s, v21.4s
	WORD $0x4e9a7b54 // zip2 v20.4s, v26.4s, v26.4s
	WORD $0x4e9c7b95 // zip2 v21.4s, v28.4s, v28.4s
	WORD $0x3cc1018c // ldur q12, [x12, #16]
	WORD $0x3cc5018d // ldur q13, [x12, #80]
	WORD $0x3cc101ae // ldur q14, [x13, #16]
	WORD $0x3cc501af // ldur q15, [x13, #80]
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x4e361dd1 // and v17.16b, v14.16b, v22.16b
	WORD $0x4f0c5631 // shl v17.16b, v17.16b, #4
	WORD $0x4eb11e10 // orr v16.16b, v16.16b, v17.16b
	WORD $0x6e398610 // sub v16.16b, v16.16b, v25.16b
	WORD $0x6f0c058c // ushr v12.16b, v12.16b, #4
	WORD $0x4e371dce // and v14.16b, v14.16b, v23.16b
	WORD $0x4eae1d8c // orr v12.16b, v12.16b, v14.16b
	WORD $0x6e39858c // sub v12.16b, v12.16b, v25.16b
	WORD $0x4e3f1db1 // and v17.16b, v13.16b, v31.16b
	WORD $0x4e361dee // and v14.16b, v15.16b, v22.16b
	WORD $0x4f0c55ce // shl v14.16b, v14.16b, #4
	WORD $0x4eae1e31 // orr v17.16b, v17.16b, v14.16b
	WORD $0x6e398631 // sub v17.16b, v17.16b, v25.16b
	WORD $0x6f0c05ad // ushr v13.16b, v13.16b, #4
	WORD $0x4e371def // and v15.16b, v15.16b, v23.16b
	WORD $0x4eaf1dad // orr v13.16b, v13.16b, v15.16b
	WORD $0x6e3985ad // sub v13.16b, v13.16b, v25.16b
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a628 // smmla v8.4s, v17.16b, v18.16b
	WORD $0x4e93a62a // smmla v10.4s, v17.16b, v19.16b
	WORD $0x3cc001f2 // ldur q18, [x15, #0]
	WORD $0x3cc101f3 // ldur q19, [x15, #16]
	WORD $0x4e92a589 // smmla v9.4s, v12.16b, v18.16b
	WORD $0x4e93a58b // smmla v11.4s, v12.16b, v19.16b
	WORD $0x3cc201f2 // ldur q18, [x15, #32]
	WORD $0x3cc301f3 // ldur q19, [x15, #48]
	WORD $0x4e92a5a9 // smmla v9.4s, v13.16b, v18.16b
	WORD $0x4e93a5ab // smmla v11.4s, v13.16b, v19.16b
	WORD $0x4eb49501 // mla v1.4s, v8.4s, v20.4s
	WORD $0x4eb59521 // mla v1.4s, v9.4s, v21.4s
	WORD $0x4eb49545 // mla v5.4s, v10.4s, v20.4s
	WORD $0x4eb59565 // mla v5.4s, v11.4s, v21.4s
	WORD $0x4e9b3b74 // zip1 v20.4s, v27.4s, v27.4s
	WORD $0x4e9d3bb5 // zip1 v21.4s, v29.4s, v29.4s
	WORD $0x3cc2018c // ldur q12, [x12, #32]
	WORD $0x3cc6018d // ldur q13, [x12, #96]
	WORD $0x3cc201ae // ldur q14, [x13, #32]
	WORD $0x3cc601af // ldur q15, [x13, #96]
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x4e361dd1 // and v17.16b, v14.16b, v22.16b
	WORD $0x4f0c5631 // shl v17.16b, v17.16b, #4
	WORD $0x4eb11e10 // orr v16.16b, v16.16b, v17.16b
	WORD $0x6e398610 // sub v16.16b, v16.16b, v25.16b
	WORD $0x6f0c058c // ushr v12.16b, v12.16b, #4
	WORD $0x4e371dce // and v14.16b, v14.16b, v23.16b
	WORD $0x4eae1d8c // orr v12.16b, v12.16b, v14.16b
	WORD $0x6e39858c // sub v12.16b, v12.16b, v25.16b
	WORD $0x4e3f1db1 // and v17.16b, v13.16b, v31.16b
	WORD $0x4e361dee // and v14.16b, v15.16b, v22.16b
	WORD $0x4f0c55ce // shl v14.16b, v14.16b, #4
	WORD $0x4eae1e31 // orr v17.16b, v17.16b, v14.16b
	WORD $0x6e398631 // sub v17.16b, v17.16b, v25.16b
	WORD $0x6f0c05ad // ushr v13.16b, v13.16b, #4
	WORD $0x4e371def // and v15.16b, v15.16b, v23.16b
	WORD $0x4eaf1dad // orr v13.16b, v13.16b, v15.16b
	WORD $0x6e3985ad // sub v13.16b, v13.16b, v25.16b
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a628 // smmla v8.4s, v17.16b, v18.16b
	WORD $0x4e93a62a // smmla v10.4s, v17.16b, v19.16b
	WORD $0x3cc001f2 // ldur q18, [x15, #0]
	WORD $0x3cc101f3 // ldur q19, [x15, #16]
	WORD $0x4e92a589 // smmla v9.4s, v12.16b, v18.16b
	WORD $0x4e93a58b // smmla v11.4s, v12.16b, v19.16b
	WORD $0x3cc201f2 // ldur q18, [x15, #32]
	WORD $0x3cc301f3 // ldur q19, [x15, #48]
	WORD $0x4e92a5a9 // smmla v9.4s, v13.16b, v18.16b
	WORD $0x4e93a5ab // smmla v11.4s, v13.16b, v19.16b
	WORD $0x4eb49502 // mla v2.4s, v8.4s, v20.4s
	WORD $0x4eb59522 // mla v2.4s, v9.4s, v21.4s
	WORD $0x4eb49546 // mla v6.4s, v10.4s, v20.4s
	WORD $0x4eb59566 // mla v6.4s, v11.4s, v21.4s
	WORD $0x4e9b7b74 // zip2 v20.4s, v27.4s, v27.4s
	WORD $0x4e9d7bb5 // zip2 v21.4s, v29.4s, v29.4s
	WORD $0x3cc3018c // ldur q12, [x12, #48]
	WORD $0x3cc7018d // ldur q13, [x12, #112]
	WORD $0x3cc301ae // ldur q14, [x13, #48]
	WORD $0x3cc701af // ldur q15, [x13, #112]
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x4e361dd1 // and v17.16b, v14.16b, v22.16b
	WORD $0x4f0c5631 // shl v17.16b, v17.16b, #4
	WORD $0x4eb11e10 // orr v16.16b, v16.16b, v17.16b
	WORD $0x6e398610 // sub v16.16b, v16.16b, v25.16b
	WORD $0x6f0c058c // ushr v12.16b, v12.16b, #4
	WORD $0x4e371dce // and v14.16b, v14.16b, v23.16b
	WORD $0x4eae1d8c // orr v12.16b, v12.16b, v14.16b
	WORD $0x6e39858c // sub v12.16b, v12.16b, v25.16b
	WORD $0x4e3f1db1 // and v17.16b, v13.16b, v31.16b
	WORD $0x4e361dee // and v14.16b, v15.16b, v22.16b
	WORD $0x4f0c55ce // shl v14.16b, v14.16b, #4
	WORD $0x4eae1e31 // orr v17.16b, v17.16b, v14.16b
	WORD $0x6e398631 // sub v17.16b, v17.16b, v25.16b
	WORD $0x6f0c05ad // ushr v13.16b, v13.16b, #4
	WORD $0x4e371def // and v15.16b, v15.16b, v23.16b
	WORD $0x4eaf1dad // orr v13.16b, v13.16b, v15.16b
	WORD $0x6e3985ad // sub v13.16b, v13.16b, v25.16b
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a628 // smmla v8.4s, v17.16b, v18.16b
	WORD $0x4e93a62a // smmla v10.4s, v17.16b, v19.16b
	WORD $0x3cc001f2 // ldur q18, [x15, #0]
	WORD $0x3cc101f3 // ldur q19, [x15, #16]
	WORD $0x4e92a589 // smmla v9.4s, v12.16b, v18.16b
	WORD $0x4e93a58b // smmla v11.4s, v12.16b, v19.16b
	WORD $0x3cc201f2 // ldur q18, [x15, #32]
	WORD $0x3cc301f3 // ldur q19, [x15, #48]
	WORD $0x4e92a5a9 // smmla v9.4s, v13.16b, v18.16b
	WORD $0x4e93a5ab // smmla v11.4s, v13.16b, v19.16b
	WORD $0x4eb49503 // mla v3.4s, v8.4s, v20.4s
	WORD $0x4eb59523 // mla v3.4s, v9.4s, v21.4s
	WORD $0x4eb49547 // mla v7.4s, v10.4s, v20.4s
	WORD $0x4eb59567 // mla v7.4s, v11.4s, v21.4s
	ADD	$912, R9, R12
	ADD	$1424, R9, R13
	ADD	$656, R10, R14
	ADD	$256, R14, R15
	WORD $0xfc460138 // ldur d24, [x9, #96]
	WORD $0x0f08a718 // sshll v24.8h, v24.8b, #0
	WORD $0x0f10a71a // sshll v26.4s, v24.4h, #0
	WORD $0x4f10a71b // sshll2 v27.4s, v24.8h, #0
	WORD $0xfc480138 // ldur d24, [x9, #128]
	WORD $0x0f08a718 // sshll v24.8h, v24.8b, #0
	WORD $0x0f10a71c // sshll v28.4s, v24.4h, #0
	WORD $0x4f10a71d // sshll2 v29.4s, v24.8h, #0
	WORD $0x4e9a3b54 // zip1 v20.4s, v26.4s, v26.4s
	WORD $0x4e9c3b95 // zip1 v21.4s, v28.4s, v28.4s
	WORD $0x3cc0018c // ldur q12, [x12, #0]
	WORD $0x3cc4018d // ldur q13, [x12, #64]
	WORD $0x3cc001ae // ldur q14, [x13, #0]
	WORD $0x3cc401af // ldur q15, [x13, #64]
	WORD $0x6f0e05ce // ushr v14.16b, v14.16b, #2
	WORD $0x6f0e05ef // ushr v15.16b, v15.16b, #2
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x4e361dd1 // and v17.16b, v14.16b, v22.16b
	WORD $0x4f0c5631 // shl v17.16b, v17.16b, #4
	WORD $0x4eb11e10 // orr v16.16b, v16.16b, v17.16b
	WORD $0x6e398610 // sub v16.16b, v16.16b, v25.16b
	WORD $0x6f0c058c // ushr v12.16b, v12.16b, #4
	WORD $0x4e371dce // and v14.16b, v14.16b, v23.16b
	WORD $0x4eae1d8c // orr v12.16b, v12.16b, v14.16b
	WORD $0x6e39858c // sub v12.16b, v12.16b, v25.16b
	WORD $0x4e3f1db1 // and v17.16b, v13.16b, v31.16b
	WORD $0x4e361dee // and v14.16b, v15.16b, v22.16b
	WORD $0x4f0c55ce // shl v14.16b, v14.16b, #4
	WORD $0x4eae1e31 // orr v17.16b, v17.16b, v14.16b
	WORD $0x6e398631 // sub v17.16b, v17.16b, v25.16b
	WORD $0x6f0c05ad // ushr v13.16b, v13.16b, #4
	WORD $0x4e371def // and v15.16b, v15.16b, v23.16b
	WORD $0x4eaf1dad // orr v13.16b, v13.16b, v15.16b
	WORD $0x6e3985ad // sub v13.16b, v13.16b, v25.16b
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a628 // smmla v8.4s, v17.16b, v18.16b
	WORD $0x4e93a62a // smmla v10.4s, v17.16b, v19.16b
	WORD $0x3cc001f2 // ldur q18, [x15, #0]
	WORD $0x3cc101f3 // ldur q19, [x15, #16]
	WORD $0x4e92a589 // smmla v9.4s, v12.16b, v18.16b
	WORD $0x4e93a58b // smmla v11.4s, v12.16b, v19.16b
	WORD $0x3cc201f2 // ldur q18, [x15, #32]
	WORD $0x3cc301f3 // ldur q19, [x15, #48]
	WORD $0x4e92a5a9 // smmla v9.4s, v13.16b, v18.16b
	WORD $0x4e93a5ab // smmla v11.4s, v13.16b, v19.16b
	WORD $0x4eb49500 // mla v0.4s, v8.4s, v20.4s
	WORD $0x4eb59520 // mla v0.4s, v9.4s, v21.4s
	WORD $0x4eb49544 // mla v4.4s, v10.4s, v20.4s
	WORD $0x4eb59564 // mla v4.4s, v11.4s, v21.4s
	WORD $0x4e9a7b54 // zip2 v20.4s, v26.4s, v26.4s
	WORD $0x4e9c7b95 // zip2 v21.4s, v28.4s, v28.4s
	WORD $0x3cc1018c // ldur q12, [x12, #16]
	WORD $0x3cc5018d // ldur q13, [x12, #80]
	WORD $0x3cc101ae // ldur q14, [x13, #16]
	WORD $0x3cc501af // ldur q15, [x13, #80]
	WORD $0x6f0e05ce // ushr v14.16b, v14.16b, #2
	WORD $0x6f0e05ef // ushr v15.16b, v15.16b, #2
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x4e361dd1 // and v17.16b, v14.16b, v22.16b
	WORD $0x4f0c5631 // shl v17.16b, v17.16b, #4
	WORD $0x4eb11e10 // orr v16.16b, v16.16b, v17.16b
	WORD $0x6e398610 // sub v16.16b, v16.16b, v25.16b
	WORD $0x6f0c058c // ushr v12.16b, v12.16b, #4
	WORD $0x4e371dce // and v14.16b, v14.16b, v23.16b
	WORD $0x4eae1d8c // orr v12.16b, v12.16b, v14.16b
	WORD $0x6e39858c // sub v12.16b, v12.16b, v25.16b
	WORD $0x4e3f1db1 // and v17.16b, v13.16b, v31.16b
	WORD $0x4e361dee // and v14.16b, v15.16b, v22.16b
	WORD $0x4f0c55ce // shl v14.16b, v14.16b, #4
	WORD $0x4eae1e31 // orr v17.16b, v17.16b, v14.16b
	WORD $0x6e398631 // sub v17.16b, v17.16b, v25.16b
	WORD $0x6f0c05ad // ushr v13.16b, v13.16b, #4
	WORD $0x4e371def // and v15.16b, v15.16b, v23.16b
	WORD $0x4eaf1dad // orr v13.16b, v13.16b, v15.16b
	WORD $0x6e3985ad // sub v13.16b, v13.16b, v25.16b
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a628 // smmla v8.4s, v17.16b, v18.16b
	WORD $0x4e93a62a // smmla v10.4s, v17.16b, v19.16b
	WORD $0x3cc001f2 // ldur q18, [x15, #0]
	WORD $0x3cc101f3 // ldur q19, [x15, #16]
	WORD $0x4e92a589 // smmla v9.4s, v12.16b, v18.16b
	WORD $0x4e93a58b // smmla v11.4s, v12.16b, v19.16b
	WORD $0x3cc201f2 // ldur q18, [x15, #32]
	WORD $0x3cc301f3 // ldur q19, [x15, #48]
	WORD $0x4e92a5a9 // smmla v9.4s, v13.16b, v18.16b
	WORD $0x4e93a5ab // smmla v11.4s, v13.16b, v19.16b
	WORD $0x4eb49501 // mla v1.4s, v8.4s, v20.4s
	WORD $0x4eb59521 // mla v1.4s, v9.4s, v21.4s
	WORD $0x4eb49545 // mla v5.4s, v10.4s, v20.4s
	WORD $0x4eb59565 // mla v5.4s, v11.4s, v21.4s
	WORD $0x4e9b3b74 // zip1 v20.4s, v27.4s, v27.4s
	WORD $0x4e9d3bb5 // zip1 v21.4s, v29.4s, v29.4s
	WORD $0x3cc2018c // ldur q12, [x12, #32]
	WORD $0x3cc6018d // ldur q13, [x12, #96]
	WORD $0x3cc201ae // ldur q14, [x13, #32]
	WORD $0x3cc601af // ldur q15, [x13, #96]
	WORD $0x6f0e05ce // ushr v14.16b, v14.16b, #2
	WORD $0x6f0e05ef // ushr v15.16b, v15.16b, #2
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x4e361dd1 // and v17.16b, v14.16b, v22.16b
	WORD $0x4f0c5631 // shl v17.16b, v17.16b, #4
	WORD $0x4eb11e10 // orr v16.16b, v16.16b, v17.16b
	WORD $0x6e398610 // sub v16.16b, v16.16b, v25.16b
	WORD $0x6f0c058c // ushr v12.16b, v12.16b, #4
	WORD $0x4e371dce // and v14.16b, v14.16b, v23.16b
	WORD $0x4eae1d8c // orr v12.16b, v12.16b, v14.16b
	WORD $0x6e39858c // sub v12.16b, v12.16b, v25.16b
	WORD $0x4e3f1db1 // and v17.16b, v13.16b, v31.16b
	WORD $0x4e361dee // and v14.16b, v15.16b, v22.16b
	WORD $0x4f0c55ce // shl v14.16b, v14.16b, #4
	WORD $0x4eae1e31 // orr v17.16b, v17.16b, v14.16b
	WORD $0x6e398631 // sub v17.16b, v17.16b, v25.16b
	WORD $0x6f0c05ad // ushr v13.16b, v13.16b, #4
	WORD $0x4e371def // and v15.16b, v15.16b, v23.16b
	WORD $0x4eaf1dad // orr v13.16b, v13.16b, v15.16b
	WORD $0x6e3985ad // sub v13.16b, v13.16b, v25.16b
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a628 // smmla v8.4s, v17.16b, v18.16b
	WORD $0x4e93a62a // smmla v10.4s, v17.16b, v19.16b
	WORD $0x3cc001f2 // ldur q18, [x15, #0]
	WORD $0x3cc101f3 // ldur q19, [x15, #16]
	WORD $0x4e92a589 // smmla v9.4s, v12.16b, v18.16b
	WORD $0x4e93a58b // smmla v11.4s, v12.16b, v19.16b
	WORD $0x3cc201f2 // ldur q18, [x15, #32]
	WORD $0x3cc301f3 // ldur q19, [x15, #48]
	WORD $0x4e92a5a9 // smmla v9.4s, v13.16b, v18.16b
	WORD $0x4e93a5ab // smmla v11.4s, v13.16b, v19.16b
	WORD $0x4eb49502 // mla v2.4s, v8.4s, v20.4s
	WORD $0x4eb59522 // mla v2.4s, v9.4s, v21.4s
	WORD $0x4eb49546 // mla v6.4s, v10.4s, v20.4s
	WORD $0x4eb59566 // mla v6.4s, v11.4s, v21.4s
	WORD $0x4e9b7b74 // zip2 v20.4s, v27.4s, v27.4s
	WORD $0x4e9d7bb5 // zip2 v21.4s, v29.4s, v29.4s
	WORD $0x3cc3018c // ldur q12, [x12, #48]
	WORD $0x3cc7018d // ldur q13, [x12, #112]
	WORD $0x3cc301ae // ldur q14, [x13, #48]
	WORD $0x3cc701af // ldur q15, [x13, #112]
	WORD $0x6f0e05ce // ushr v14.16b, v14.16b, #2
	WORD $0x6f0e05ef // ushr v15.16b, v15.16b, #2
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x4e361dd1 // and v17.16b, v14.16b, v22.16b
	WORD $0x4f0c5631 // shl v17.16b, v17.16b, #4
	WORD $0x4eb11e10 // orr v16.16b, v16.16b, v17.16b
	WORD $0x6e398610 // sub v16.16b, v16.16b, v25.16b
	WORD $0x6f0c058c // ushr v12.16b, v12.16b, #4
	WORD $0x4e371dce // and v14.16b, v14.16b, v23.16b
	WORD $0x4eae1d8c // orr v12.16b, v12.16b, v14.16b
	WORD $0x6e39858c // sub v12.16b, v12.16b, v25.16b
	WORD $0x4e3f1db1 // and v17.16b, v13.16b, v31.16b
	WORD $0x4e361dee // and v14.16b, v15.16b, v22.16b
	WORD $0x4f0c55ce // shl v14.16b, v14.16b, #4
	WORD $0x4eae1e31 // orr v17.16b, v17.16b, v14.16b
	WORD $0x6e398631 // sub v17.16b, v17.16b, v25.16b
	WORD $0x6f0c05ad // ushr v13.16b, v13.16b, #4
	WORD $0x4e371def // and v15.16b, v15.16b, v23.16b
	WORD $0x4eaf1dad // orr v13.16b, v13.16b, v15.16b
	WORD $0x6e3985ad // sub v13.16b, v13.16b, v25.16b
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a628 // smmla v8.4s, v17.16b, v18.16b
	WORD $0x4e93a62a // smmla v10.4s, v17.16b, v19.16b
	WORD $0x3cc001f2 // ldur q18, [x15, #0]
	WORD $0x3cc101f3 // ldur q19, [x15, #16]
	WORD $0x4e92a589 // smmla v9.4s, v12.16b, v18.16b
	WORD $0x4e93a58b // smmla v11.4s, v12.16b, v19.16b
	WORD $0x3cc201f2 // ldur q18, [x15, #32]
	WORD $0x3cc301f3 // ldur q19, [x15, #48]
	WORD $0x4e92a5a9 // smmla v9.4s, v13.16b, v18.16b
	WORD $0x4e93a5ab // smmla v11.4s, v13.16b, v19.16b
	WORD $0x4eb49503 // mla v3.4s, v8.4s, v20.4s
	WORD $0x4eb59523 // mla v3.4s, v9.4s, v21.4s
	WORD $0x4eb49547 // mla v7.4s, v10.4s, v20.4s
	WORD $0x4eb59567 // mla v7.4s, v11.4s, v21.4s
	ADD	$1040, R9, R12
	ADD	$1552, R9, R13
	ADD	$720, R10, R14
	ADD	$256, R14, R15
	WORD $0xfc468138 // ldur d24, [x9, #104]
	WORD $0x0f08a718 // sshll v24.8h, v24.8b, #0
	WORD $0x0f10a71a // sshll v26.4s, v24.4h, #0
	WORD $0x4f10a71b // sshll2 v27.4s, v24.8h, #0
	WORD $0xfc488138 // ldur d24, [x9, #136]
	WORD $0x0f08a718 // sshll v24.8h, v24.8b, #0
	WORD $0x0f10a71c // sshll v28.4s, v24.4h, #0
	WORD $0x4f10a71d // sshll2 v29.4s, v24.8h, #0
	WORD $0x4e9a3b54 // zip1 v20.4s, v26.4s, v26.4s
	WORD $0x4e9c3b95 // zip1 v21.4s, v28.4s, v28.4s
	WORD $0x3cc0018c // ldur q12, [x12, #0]
	WORD $0x3cc4018d // ldur q13, [x12, #64]
	WORD $0x3cc001ae // ldur q14, [x13, #0]
	WORD $0x3cc401af // ldur q15, [x13, #64]
	WORD $0x6f0e05ce // ushr v14.16b, v14.16b, #2
	WORD $0x6f0e05ef // ushr v15.16b, v15.16b, #2
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x4e361dd1 // and v17.16b, v14.16b, v22.16b
	WORD $0x4f0c5631 // shl v17.16b, v17.16b, #4
	WORD $0x4eb11e10 // orr v16.16b, v16.16b, v17.16b
	WORD $0x6e398610 // sub v16.16b, v16.16b, v25.16b
	WORD $0x6f0c058c // ushr v12.16b, v12.16b, #4
	WORD $0x4e371dce // and v14.16b, v14.16b, v23.16b
	WORD $0x4eae1d8c // orr v12.16b, v12.16b, v14.16b
	WORD $0x6e39858c // sub v12.16b, v12.16b, v25.16b
	WORD $0x4e3f1db1 // and v17.16b, v13.16b, v31.16b
	WORD $0x4e361dee // and v14.16b, v15.16b, v22.16b
	WORD $0x4f0c55ce // shl v14.16b, v14.16b, #4
	WORD $0x4eae1e31 // orr v17.16b, v17.16b, v14.16b
	WORD $0x6e398631 // sub v17.16b, v17.16b, v25.16b
	WORD $0x6f0c05ad // ushr v13.16b, v13.16b, #4
	WORD $0x4e371def // and v15.16b, v15.16b, v23.16b
	WORD $0x4eaf1dad // orr v13.16b, v13.16b, v15.16b
	WORD $0x6e3985ad // sub v13.16b, v13.16b, v25.16b
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a628 // smmla v8.4s, v17.16b, v18.16b
	WORD $0x4e93a62a // smmla v10.4s, v17.16b, v19.16b
	WORD $0x3cc001f2 // ldur q18, [x15, #0]
	WORD $0x3cc101f3 // ldur q19, [x15, #16]
	WORD $0x4e92a589 // smmla v9.4s, v12.16b, v18.16b
	WORD $0x4e93a58b // smmla v11.4s, v12.16b, v19.16b
	WORD $0x3cc201f2 // ldur q18, [x15, #32]
	WORD $0x3cc301f3 // ldur q19, [x15, #48]
	WORD $0x4e92a5a9 // smmla v9.4s, v13.16b, v18.16b
	WORD $0x4e93a5ab // smmla v11.4s, v13.16b, v19.16b
	WORD $0x4eb49500 // mla v0.4s, v8.4s, v20.4s
	WORD $0x4eb59520 // mla v0.4s, v9.4s, v21.4s
	WORD $0x4eb49544 // mla v4.4s, v10.4s, v20.4s
	WORD $0x4eb59564 // mla v4.4s, v11.4s, v21.4s
	WORD $0x4e9a7b54 // zip2 v20.4s, v26.4s, v26.4s
	WORD $0x4e9c7b95 // zip2 v21.4s, v28.4s, v28.4s
	WORD $0x3cc1018c // ldur q12, [x12, #16]
	WORD $0x3cc5018d // ldur q13, [x12, #80]
	WORD $0x3cc101ae // ldur q14, [x13, #16]
	WORD $0x3cc501af // ldur q15, [x13, #80]
	WORD $0x6f0e05ce // ushr v14.16b, v14.16b, #2
	WORD $0x6f0e05ef // ushr v15.16b, v15.16b, #2
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x4e361dd1 // and v17.16b, v14.16b, v22.16b
	WORD $0x4f0c5631 // shl v17.16b, v17.16b, #4
	WORD $0x4eb11e10 // orr v16.16b, v16.16b, v17.16b
	WORD $0x6e398610 // sub v16.16b, v16.16b, v25.16b
	WORD $0x6f0c058c // ushr v12.16b, v12.16b, #4
	WORD $0x4e371dce // and v14.16b, v14.16b, v23.16b
	WORD $0x4eae1d8c // orr v12.16b, v12.16b, v14.16b
	WORD $0x6e39858c // sub v12.16b, v12.16b, v25.16b
	WORD $0x4e3f1db1 // and v17.16b, v13.16b, v31.16b
	WORD $0x4e361dee // and v14.16b, v15.16b, v22.16b
	WORD $0x4f0c55ce // shl v14.16b, v14.16b, #4
	WORD $0x4eae1e31 // orr v17.16b, v17.16b, v14.16b
	WORD $0x6e398631 // sub v17.16b, v17.16b, v25.16b
	WORD $0x6f0c05ad // ushr v13.16b, v13.16b, #4
	WORD $0x4e371def // and v15.16b, v15.16b, v23.16b
	WORD $0x4eaf1dad // orr v13.16b, v13.16b, v15.16b
	WORD $0x6e3985ad // sub v13.16b, v13.16b, v25.16b
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a628 // smmla v8.4s, v17.16b, v18.16b
	WORD $0x4e93a62a // smmla v10.4s, v17.16b, v19.16b
	WORD $0x3cc001f2 // ldur q18, [x15, #0]
	WORD $0x3cc101f3 // ldur q19, [x15, #16]
	WORD $0x4e92a589 // smmla v9.4s, v12.16b, v18.16b
	WORD $0x4e93a58b // smmla v11.4s, v12.16b, v19.16b
	WORD $0x3cc201f2 // ldur q18, [x15, #32]
	WORD $0x3cc301f3 // ldur q19, [x15, #48]
	WORD $0x4e92a5a9 // smmla v9.4s, v13.16b, v18.16b
	WORD $0x4e93a5ab // smmla v11.4s, v13.16b, v19.16b
	WORD $0x4eb49501 // mla v1.4s, v8.4s, v20.4s
	WORD $0x4eb59521 // mla v1.4s, v9.4s, v21.4s
	WORD $0x4eb49545 // mla v5.4s, v10.4s, v20.4s
	WORD $0x4eb59565 // mla v5.4s, v11.4s, v21.4s
	WORD $0x4e9b3b74 // zip1 v20.4s, v27.4s, v27.4s
	WORD $0x4e9d3bb5 // zip1 v21.4s, v29.4s, v29.4s
	WORD $0x3cc2018c // ldur q12, [x12, #32]
	WORD $0x3cc6018d // ldur q13, [x12, #96]
	WORD $0x3cc201ae // ldur q14, [x13, #32]
	WORD $0x3cc601af // ldur q15, [x13, #96]
	WORD $0x6f0e05ce // ushr v14.16b, v14.16b, #2
	WORD $0x6f0e05ef // ushr v15.16b, v15.16b, #2
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x4e361dd1 // and v17.16b, v14.16b, v22.16b
	WORD $0x4f0c5631 // shl v17.16b, v17.16b, #4
	WORD $0x4eb11e10 // orr v16.16b, v16.16b, v17.16b
	WORD $0x6e398610 // sub v16.16b, v16.16b, v25.16b
	WORD $0x6f0c058c // ushr v12.16b, v12.16b, #4
	WORD $0x4e371dce // and v14.16b, v14.16b, v23.16b
	WORD $0x4eae1d8c // orr v12.16b, v12.16b, v14.16b
	WORD $0x6e39858c // sub v12.16b, v12.16b, v25.16b
	WORD $0x4e3f1db1 // and v17.16b, v13.16b, v31.16b
	WORD $0x4e361dee // and v14.16b, v15.16b, v22.16b
	WORD $0x4f0c55ce // shl v14.16b, v14.16b, #4
	WORD $0x4eae1e31 // orr v17.16b, v17.16b, v14.16b
	WORD $0x6e398631 // sub v17.16b, v17.16b, v25.16b
	WORD $0x6f0c05ad // ushr v13.16b, v13.16b, #4
	WORD $0x4e371def // and v15.16b, v15.16b, v23.16b
	WORD $0x4eaf1dad // orr v13.16b, v13.16b, v15.16b
	WORD $0x6e3985ad // sub v13.16b, v13.16b, v25.16b
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a628 // smmla v8.4s, v17.16b, v18.16b
	WORD $0x4e93a62a // smmla v10.4s, v17.16b, v19.16b
	WORD $0x3cc001f2 // ldur q18, [x15, #0]
	WORD $0x3cc101f3 // ldur q19, [x15, #16]
	WORD $0x4e92a589 // smmla v9.4s, v12.16b, v18.16b
	WORD $0x4e93a58b // smmla v11.4s, v12.16b, v19.16b
	WORD $0x3cc201f2 // ldur q18, [x15, #32]
	WORD $0x3cc301f3 // ldur q19, [x15, #48]
	WORD $0x4e92a5a9 // smmla v9.4s, v13.16b, v18.16b
	WORD $0x4e93a5ab // smmla v11.4s, v13.16b, v19.16b
	WORD $0x4eb49502 // mla v2.4s, v8.4s, v20.4s
	WORD $0x4eb59522 // mla v2.4s, v9.4s, v21.4s
	WORD $0x4eb49546 // mla v6.4s, v10.4s, v20.4s
	WORD $0x4eb59566 // mla v6.4s, v11.4s, v21.4s
	WORD $0x4e9b7b74 // zip2 v20.4s, v27.4s, v27.4s
	WORD $0x4e9d7bb5 // zip2 v21.4s, v29.4s, v29.4s
	WORD $0x3cc3018c // ldur q12, [x12, #48]
	WORD $0x3cc7018d // ldur q13, [x12, #112]
	WORD $0x3cc301ae // ldur q14, [x13, #48]
	WORD $0x3cc701af // ldur q15, [x13, #112]
	WORD $0x6f0e05ce // ushr v14.16b, v14.16b, #2
	WORD $0x6f0e05ef // ushr v15.16b, v15.16b, #2
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x4e361dd1 // and v17.16b, v14.16b, v22.16b
	WORD $0x4f0c5631 // shl v17.16b, v17.16b, #4
	WORD $0x4eb11e10 // orr v16.16b, v16.16b, v17.16b
	WORD $0x6e398610 // sub v16.16b, v16.16b, v25.16b
	WORD $0x6f0c058c // ushr v12.16b, v12.16b, #4
	WORD $0x4e371dce // and v14.16b, v14.16b, v23.16b
	WORD $0x4eae1d8c // orr v12.16b, v12.16b, v14.16b
	WORD $0x6e39858c // sub v12.16b, v12.16b, v25.16b
	WORD $0x4e3f1db1 // and v17.16b, v13.16b, v31.16b
	WORD $0x4e361dee // and v14.16b, v15.16b, v22.16b
	WORD $0x4f0c55ce // shl v14.16b, v14.16b, #4
	WORD $0x4eae1e31 // orr v17.16b, v17.16b, v14.16b
	WORD $0x6e398631 // sub v17.16b, v17.16b, v25.16b
	WORD $0x6f0c05ad // ushr v13.16b, v13.16b, #4
	WORD $0x4e371def // and v15.16b, v15.16b, v23.16b
	WORD $0x4eaf1dad // orr v13.16b, v13.16b, v15.16b
	WORD $0x6e3985ad // sub v13.16b, v13.16b, v25.16b
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a628 // smmla v8.4s, v17.16b, v18.16b
	WORD $0x4e93a62a // smmla v10.4s, v17.16b, v19.16b
	WORD $0x3cc001f2 // ldur q18, [x15, #0]
	WORD $0x3cc101f3 // ldur q19, [x15, #16]
	WORD $0x4e92a589 // smmla v9.4s, v12.16b, v18.16b
	WORD $0x4e93a58b // smmla v11.4s, v12.16b, v19.16b
	WORD $0x3cc201f2 // ldur q18, [x15, #32]
	WORD $0x3cc301f3 // ldur q19, [x15, #48]
	WORD $0x4e92a5a9 // smmla v9.4s, v13.16b, v18.16b
	WORD $0x4e93a5ab // smmla v11.4s, v13.16b, v19.16b
	WORD $0x4eb49503 // mla v3.4s, v8.4s, v20.4s
	WORD $0x4eb59523 // mla v3.4s, v9.4s, v21.4s
	WORD $0x4eb49547 // mla v7.4s, v10.4s, v20.4s
	WORD $0x4eb59567 // mla v7.4s, v11.4s, v21.4s
	WORD $0xfc40013c // ldur d28, [x9, #0]
	WORD $0x0e217b9c // fcvtl v28.4s, v28.4h
	WORD $0xfc40813d // ldur d29, [x9, #8]
	WORD $0x0e217bbd // fcvtl v29.4s, v29.4h
	WORD $0xbc40015e // ldur s30, [x10, #0]
	WORD $0x4e81180c // uzp1 v12.4s, v0.4s, v1.4s
	WORD $0x4e21d98c // scvtf v12.4s, v12.4s
	WORD $0x4f9e938e // fmul v14.4s, v28.4s, v30.s[0]
	WORD $0x3cc002f8 // ldur q24, [x23, #0]
	WORD $0x4e2ecd98 // fmla v24.4s, v12.4s, v14.4s
	WORD $0x3c8002f8 // stur q24, [x23, #0]
	WORD $0x4e83184c // uzp1 v12.4s, v2.4s, v3.4s
	WORD $0x4e21d98c // scvtf v12.4s, v12.4s
	WORD $0x4f9e93ae // fmul v14.4s, v29.4s, v30.s[0]
	WORD $0x3cc102f8 // ldur q24, [x23, #16]
	WORD $0x4e2ecd98 // fmla v24.4s, v12.4s, v14.4s
	WORD $0x3c8102f8 // stur q24, [x23, #16]
	WORD $0xbc40415e // ldur s30, [x10, #4]
	WORD $0x4e81580c // uzp2 v12.4s, v0.4s, v1.4s
	WORD $0x4e21d98c // scvtf v12.4s, v12.4s
	WORD $0x4f9e938e // fmul v14.4s, v28.4s, v30.s[0]
	WORD $0x3cc202f8 // ldur q24, [x23, #32]
	WORD $0x4e2ecd98 // fmla v24.4s, v12.4s, v14.4s
	WORD $0x3c8202f8 // stur q24, [x23, #32]
	WORD $0x4e83584c // uzp2 v12.4s, v2.4s, v3.4s
	WORD $0x4e21d98c // scvtf v12.4s, v12.4s
	WORD $0x4f9e93ae // fmul v14.4s, v29.4s, v30.s[0]
	WORD $0x3cc302f8 // ldur q24, [x23, #48]
	WORD $0x4e2ecd98 // fmla v24.4s, v12.4s, v14.4s
	WORD $0x3c8302f8 // stur q24, [x23, #48]
	WORD $0xbc40815e // ldur s30, [x10, #8]
	WORD $0x4e85188c // uzp1 v12.4s, v4.4s, v5.4s
	WORD $0x4e21d98c // scvtf v12.4s, v12.4s
	WORD $0x4f9e938e // fmul v14.4s, v28.4s, v30.s[0]
	WORD $0x3cc402f8 // ldur q24, [x23, #64]
	WORD $0x4e2ecd98 // fmla v24.4s, v12.4s, v14.4s
	WORD $0x3c8402f8 // stur q24, [x23, #64]
	WORD $0x4e8718cc // uzp1 v12.4s, v6.4s, v7.4s
	WORD $0x4e21d98c // scvtf v12.4s, v12.4s
	WORD $0x4f9e93ae // fmul v14.4s, v29.4s, v30.s[0]
	WORD $0x3cc502f8 // ldur q24, [x23, #80]
	WORD $0x4e2ecd98 // fmla v24.4s, v12.4s, v14.4s
	WORD $0x3c8502f8 // stur q24, [x23, #80]
	WORD $0xbc40c15e // ldur s30, [x10, #12]
	WORD $0x4e85588c // uzp2 v12.4s, v4.4s, v5.4s
	WORD $0x4e21d98c // scvtf v12.4s, v12.4s
	WORD $0x4f9e938e // fmul v14.4s, v28.4s, v30.s[0]
	WORD $0x3cc602f8 // ldur q24, [x23, #96]
	WORD $0x4e2ecd98 // fmla v24.4s, v12.4s, v14.4s
	WORD $0x3c8602f8 // stur q24, [x23, #96]
	WORD $0x4e8758cc // uzp2 v12.4s, v6.4s, v7.4s
	WORD $0x4e21d98c // scvtf v12.4s, v12.4s
	WORD $0x4f9e93ae // fmul v14.4s, v29.4s, v30.s[0]
	WORD $0x3cc702f8 // ldur q24, [x23, #112]
	WORD $0x4e2ecd98 // fmla v24.4s, v12.4s, v14.4s
	WORD $0x3c8702f8 // stur q24, [x23, #112]
	ADD	$1680, R9, R9
	ADD	$1168, R10, R10
	SUBW	$1, R11, R11
	CBNZW	R11, m6blk
m6store:
	MOVD	R24, R12
	WORD $0x3cc002f0 // ldur q16, [x23, #0]
	WORD $0x3cc102f1 // ldur q17, [x23, #16]
	WORD $0x3c800190 // stur q16, [x12, #0]
	WORD $0x3c810191 // stur q17, [x12, #16]
	ADD	R12, R5, R12
	WORD $0x3cc202f0 // ldur q16, [x23, #32]
	WORD $0x3cc302f1 // ldur q17, [x23, #48]
	WORD $0x3c800190 // stur q16, [x12, #0]
	WORD $0x3c810191 // stur q17, [x12, #16]
	ADD	R12, R5, R12
	WORD $0x3cc402f0 // ldur q16, [x23, #64]
	WORD $0x3cc502f1 // ldur q17, [x23, #80]
	WORD $0x3c800190 // stur q16, [x12, #0]
	WORD $0x3c810191 // stur q17, [x12, #16]
	ADD	R12, R5, R12
	WORD $0x3cc602f0 // ldur q16, [x23, #96]
	WORD $0x3cc702f1 // ldur q17, [x23, #112]
	WORD $0x3c800190 // stur q16, [x12, #0]
	WORD $0x3c810191 // stur q17, [x12, #16]
	ADD	$32, R24, R24
	ADD	R0, R6, R0
	SUBW	$1, R25, R25
	CBNZW	R25, m6cols
	MOVD	$1168, R26
	MUL	R1, R26, R26
	ADD	R4, R26, R4
	LSL	$2, R5, R26
	ADD	R2, R26, R2
	SUBW	$1, R8, R8
	CBNZW	R8, m6rows
m6done:
	RET
m6oob:
	B	ovr_oob
