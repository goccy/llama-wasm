// dbg_gemm_mxfp4_8x8: mxfp4 8x8 repack GEMM, SMMLA 2x2 tiles over the unpacked runs; -1 folded through the block sums.
	MOVW	l0+8(FP), R1
	LSRW	$5, R1, R1
	MOVWU	l6+52(FP), R7
	LSRW	$3, R7, R7
	MOVWU	l5+48(FP), R8
	LSRW	$2, R8, R8
	CBZW	R7, gmxdone
	CBZW	R8, gmxdone
	MOVD	l1+16(FP), R2
	MOVD	l2+24(FP), R5
	LSL	$2, R5, R5
	LSL	$2, R8, R26
	SUB	$1, R26, R26
	MUL	R26, R5, R26
	ADD	R2, R26, R26
	ADD	R7<<5, R26, R26
	CMP	R26, R21
	BLO	gmxoob
	MOVD	l3+32(FP), R3
	MOVD	$136, R6
	MUL	R1, R6, R6
	MUL	R7, R6, R26
	ADD	R3, R26, R26
	CMP	R26, R21
	BLO	gmxoob
	MOVD	l4+40(FP), R4
	MOVD	$136, R26
	MUL	R1, R26, R26
	MUL	R8, R26, R26
	ADD	R4, R26, R26
	CMP	R26, R21
	BLO	gmxoob
	ADD	R20, R2, R2
	ADD	R20, R3, R3
	ADD	R20, R4, R4
	MOVD	$qxscratch-128(SP), R23
	MOVD	$·ovr_dbg_gemm_mxfp4_8x8_i8mm_b80_361b3c5951b4d2d4(SB), R12
	WORD $0x3cc0019d // ldur q29, [x12, #0]
	WORD $0x3cc1019c // ldur q28, [x12, #16]
	WORD $0x3cc2019b // ldur q27, [x12, #32]
	WORD $0x4f00e5ff // movi v31.16b, #15
	WORD $0x4f00e61e // movi v30.16b, #16
	WORD $0x4f00e43a // movi v26.16b, #1
gmxrows:
	MOVD	R3, R0
	MOVD	R2, R24
	MOVW	R7, R25
gmxcols:
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
	CBZW	R11, gmxstore
gmxblk:
	MOVD	$·ovr_dbg_gemm_mxfp4_8x8_i8mm_b80_361b3c5951b4d2d4(SB), R12
	WORD $0x3cc40199 // ldur q25, [x12, #64]
	WORD $0x3cc0814c // ldur q12, [x10, #8]
	WORD $0x3cc1814d // ldur q13, [x10, #24]
	WORD $0x3cc2814e // ldur q14, [x10, #40]
	WORD $0x3cc3814f // ldur q15, [x10, #56]
	WORD $0x3cc48150 // ldur q16, [x10, #72]
	WORD $0x3cc58151 // ldur q17, [x10, #88]
	WORD $0x3cc68152 // ldur q18, [x10, #104]
	WORD $0x3cc78153 // ldur q19, [x10, #120]
	WORD $0x4f000400 // movi v0.4s, #0
	WORD $0x4f000401 // movi v1.4s, #0
	WORD $0x4f000402 // movi v2.4s, #0
	WORD $0x4f000403 // movi v3.4s, #0
	WORD $0x4f000404 // movi v4.4s, #0
	WORD $0x4f000405 // movi v5.4s, #0
	WORD $0x4f000406 // movi v6.4s, #0
	WORD $0x4f000407 // movi v7.4s, #0
	WORD $0x3cc08128 // ldur q8, [x9, #8]
	WORD $0x4e3f1d09 // and v9.16b, v8.16b, v31.16b
	WORD $0x6f0c050a // ushr v10.16b, v8.16b, #4
	WORD $0x4e090329 // tbl v9.16b, {v25.16b}, v9.16b
	WORD $0x4e0a032a // tbl v10.16b, {v25.16b}, v10.16b
	WORD $0x4e8ca520 // smmla v0.4s, v9.16b, v12.16b
	WORD $0x4e8da524 // smmla v4.4s, v9.16b, v13.16b
	WORD $0x4e90a540 // smmla v0.4s, v10.16b, v16.16b
	WORD $0x4e91a544 // smmla v4.4s, v10.16b, v17.16b
	WORD $0x3cc18128 // ldur q8, [x9, #24]
	WORD $0x4e3f1d09 // and v9.16b, v8.16b, v31.16b
	WORD $0x6f0c050a // ushr v10.16b, v8.16b, #4
	WORD $0x4e090329 // tbl v9.16b, {v25.16b}, v9.16b
	WORD $0x4e0a032a // tbl v10.16b, {v25.16b}, v10.16b
	WORD $0x4e8ca521 // smmla v1.4s, v9.16b, v12.16b
	WORD $0x4e8da525 // smmla v5.4s, v9.16b, v13.16b
	WORD $0x4e90a541 // smmla v1.4s, v10.16b, v16.16b
	WORD $0x4e91a545 // smmla v5.4s, v10.16b, v17.16b
	WORD $0x3cc28128 // ldur q8, [x9, #40]
	WORD $0x4e3f1d09 // and v9.16b, v8.16b, v31.16b
	WORD $0x6f0c050a // ushr v10.16b, v8.16b, #4
	WORD $0x4e090329 // tbl v9.16b, {v25.16b}, v9.16b
	WORD $0x4e0a032a // tbl v10.16b, {v25.16b}, v10.16b
	WORD $0x4e8ca522 // smmla v2.4s, v9.16b, v12.16b
	WORD $0x4e8da526 // smmla v6.4s, v9.16b, v13.16b
	WORD $0x4e90a542 // smmla v2.4s, v10.16b, v16.16b
	WORD $0x4e91a546 // smmla v6.4s, v10.16b, v17.16b
	WORD $0x3cc38128 // ldur q8, [x9, #56]
	WORD $0x4e3f1d09 // and v9.16b, v8.16b, v31.16b
	WORD $0x6f0c050a // ushr v10.16b, v8.16b, #4
	WORD $0x4e090329 // tbl v9.16b, {v25.16b}, v9.16b
	WORD $0x4e0a032a // tbl v10.16b, {v25.16b}, v10.16b
	WORD $0x4e8ca523 // smmla v3.4s, v9.16b, v12.16b
	WORD $0x4e8da527 // smmla v7.4s, v9.16b, v13.16b
	WORD $0x4e90a543 // smmla v3.4s, v10.16b, v16.16b
	WORD $0x4e91a547 // smmla v7.4s, v10.16b, v17.16b
	WORD $0x3cc48128 // ldur q8, [x9, #72]
	WORD $0x4e3f1d09 // and v9.16b, v8.16b, v31.16b
	WORD $0x6f0c050a // ushr v10.16b, v8.16b, #4
	WORD $0x4e090329 // tbl v9.16b, {v25.16b}, v9.16b
	WORD $0x4e0a032a // tbl v10.16b, {v25.16b}, v10.16b
	WORD $0x4e8ea520 // smmla v0.4s, v9.16b, v14.16b
	WORD $0x4e8fa524 // smmla v4.4s, v9.16b, v15.16b
	WORD $0x4e92a540 // smmla v0.4s, v10.16b, v18.16b
	WORD $0x4e93a544 // smmla v4.4s, v10.16b, v19.16b
	WORD $0x3cc58128 // ldur q8, [x9, #88]
	WORD $0x4e3f1d09 // and v9.16b, v8.16b, v31.16b
	WORD $0x6f0c050a // ushr v10.16b, v8.16b, #4
	WORD $0x4e090329 // tbl v9.16b, {v25.16b}, v9.16b
	WORD $0x4e0a032a // tbl v10.16b, {v25.16b}, v10.16b
	WORD $0x4e8ea521 // smmla v1.4s, v9.16b, v14.16b
	WORD $0x4e8fa525 // smmla v5.4s, v9.16b, v15.16b
	WORD $0x4e92a541 // smmla v1.4s, v10.16b, v18.16b
	WORD $0x4e93a545 // smmla v5.4s, v10.16b, v19.16b
	WORD $0x3cc68128 // ldur q8, [x9, #104]
	WORD $0x4e3f1d09 // and v9.16b, v8.16b, v31.16b
	WORD $0x6f0c050a // ushr v10.16b, v8.16b, #4
	WORD $0x4e090329 // tbl v9.16b, {v25.16b}, v9.16b
	WORD $0x4e0a032a // tbl v10.16b, {v25.16b}, v10.16b
	WORD $0x4e8ea522 // smmla v2.4s, v9.16b, v14.16b
	WORD $0x4e8fa526 // smmla v6.4s, v9.16b, v15.16b
	WORD $0x4e92a542 // smmla v2.4s, v10.16b, v18.16b
	WORD $0x4e93a546 // smmla v6.4s, v10.16b, v19.16b
	WORD $0x3cc78128 // ldur q8, [x9, #120]
	WORD $0x4e3f1d09 // and v9.16b, v8.16b, v31.16b
	WORD $0x6f0c050a // ushr v10.16b, v8.16b, #4
	WORD $0x4e090329 // tbl v9.16b, {v25.16b}, v9.16b
	WORD $0x4e0a032a // tbl v10.16b, {v25.16b}, v10.16b
	WORD $0x4e8ea523 // smmla v3.4s, v9.16b, v14.16b
	WORD $0x4e8fa527 // smmla v7.4s, v9.16b, v15.16b
	WORD $0x4e92a543 // smmla v3.4s, v10.16b, v18.16b
	WORD $0x4e93a547 // smmla v7.4s, v10.16b, v19.16b
	WORD $0xfc400128 // ldur d8, [x9, #0]
	WORD $0x2f08a508 // ushll v8.8h, v8.8b, #0
	WORD $0x6f10a509 // ushll2 v9.4s, v8.8h, #0
	WORD $0x2f10a508 // ushll v8.4s, v8.4h, #0
	MOVW	$1, R13
	WORD $0x4e040db8 // dup v24.4s, w13
	MOVW	$2, R13
	WORD $0x4e040db9 // dup v25.4s, w13
	MOVW	$0x00200000, R13
	WORD $0x4e040dba // dup v26.4s, w13
	WORD $0x6eb8851b // sub v27.4s, v8.4s, v24.4s
	WORD $0x4f37577b // shl v27.4s, v27.4s, #23
	WORD $0x6ea8475a // ushl v26.4s, v26.4s, v8.4s
	WORD $0x6eb93d08 // cmhs v8.4s, v8.4s, v25.4s
	WORD $0x6e7a1f68 // bsl v8.16b, v27.16b, v26.16b
	MOVW	$0x00200000, R13
	WORD $0x4e040dba // dup v26.4s, w13
	WORD $0x6eb8853b // sub v27.4s, v9.4s, v24.4s
	WORD $0x4f37577b // shl v27.4s, v27.4s, #23
	WORD $0x6ea9475a // ushl v26.4s, v26.4s, v9.4s
	WORD $0x6eb93d29 // cmhs v9.4s, v9.4s, v25.4s
	WORD $0x6e7a1f69 // bsl v9.16b, v27.16b, v26.16b
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
	ADD	$136, R9, R9
	ADD	$136, R10, R10
	SUBW	$1, R11, R11
	CBNZW	R11, gmxblk
gmxstore:
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
	CBNZW	R25, gmxcols
	MOVD	$136, R26
	MUL	R1, R26, R26
	ADD	R4, R26, R4
	LSL	$2, R5, R26
	ADD	R2, R26, R2
	SUBW	$1, R8, R8
	CBNZW	R8, gmxrows
gmxdone:
	RET
gmxoob:
	B	ovr_oob

DATA ·ovr_dbg_gemm_mxfp4_8x8_i8mm_b80_361b3c5951b4d2d4+0(SB)/8, $0x8040201008040201
DATA ·ovr_dbg_gemm_mxfp4_8x8_i8mm_b80_361b3c5951b4d2d4+8(SB)/8, $0x8040201008040201
DATA ·ovr_dbg_gemm_mxfp4_8x8_i8mm_b80_361b3c5951b4d2d4+16(SB)/8, $0x0
DATA ·ovr_dbg_gemm_mxfp4_8x8_i8mm_b80_361b3c5951b4d2d4+24(SB)/8, $0x101010101010101
DATA ·ovr_dbg_gemm_mxfp4_8x8_i8mm_b80_361b3c5951b4d2d4+32(SB)/8, $0x202020202020202
DATA ·ovr_dbg_gemm_mxfp4_8x8_i8mm_b80_361b3c5951b4d2d4+40(SB)/8, $0x303030303030303
DATA ·ovr_dbg_gemm_mxfp4_8x8_i8mm_b80_361b3c5951b4d2d4+48(SB)/8, $0xf6eaddcfbfad9881
DATA ·ovr_dbg_gemm_mxfp4_8x8_i8mm_b80_361b3c5951b4d2d4+56(SB)/8, $0x7159453526190d01
DATA ·ovr_dbg_gemm_mxfp4_8x8_i8mm_b80_361b3c5951b4d2d4+64(SB)/8, $0xc08060403020100
DATA ·ovr_dbg_gemm_mxfp4_8x8_i8mm_b80_361b3c5951b4d2d4+72(SB)/8, $0xf4f8fafcfdfeff00
GLOBL ·ovr_dbg_gemm_mxfp4_8x8_i8mm_b80_361b3c5951b4d2d4(SB), RODATA|NOPTR, $80
