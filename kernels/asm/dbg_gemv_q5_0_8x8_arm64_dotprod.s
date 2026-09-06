// dbg_gemv_q5_0_8x8: q5_0 8x8 repack GEMV, SDOT over the unpacked runs; -16 folded through the block sum.
	MOVW	l0+8(FP), R1
	LSRW	$5, R1, R1
	MOVWU	l6+52(FP), R7
	LSRW	$3, R7, R7
	CBZW	R7, gv5done
	MOVD	l1+16(FP), R2
	ADD	R7<<5, R2, R27
	CMP	R27, R21
	BLO	gv5oob
	MOVD	l3+32(FP), R3
	MOVD	$176, R6
	MUL	R1, R6, R6
	MUL	R7, R6, R27
	ADD	R3, R27, R27
	CMP	R27, R21
	BLO	gv5oob
	MOVD	l4+40(FP), R4
	MOVD	$34, R27
	MUL	R1, R27, R27
	ADD	R4, R27, R27
	CMP	R27, R21
	BLO	gv5oob
	ADD	R20, R2, R2
	ADD	R20, R3, R3
	ADD	R20, R4, R4
	MOVD	$·ovr_dbg_gemv_q5_0_8x8_dotprod_b80_361b3c5951b4d2d4(SB), R12
	WORD $0x3cc0019d // ldur q29, [x12, #0]
	WORD $0x3cc1019c // ldur q28, [x12, #16]
	WORD $0x3cc2019b // ldur q27, [x12, #32]
	WORD $0x4f00e5ff // movi v31.16b, #15
	WORD $0x4f00e61e // movi v30.16b, #16
	WORD $0x4f00e43a // movi v26.16b, #1
gv5group:
	WORD $0x4f000404 // movi v4.4s, #0
	WORD $0x4f000405 // movi v5.4s, #0
	MOVD	R3, R9
	MOVD	R4, R10
	MOVW	R1, R11
	CBZW	R11, gv5store
gv5blk:
	WORD $0x3cc02154 // ldur q20, [x10, #2]
	WORD $0x3cc12155 // ldur q21, [x10, #18]
	WORD $0x4f000416 // movi v22.4s, #0
	WORD $0x4e9a9696 // sdot v22.4s, v20.16b, v26.16b
	WORD $0x4e9a96b6 // sdot v22.4s, v21.16b, v26.16b
	WORD $0x4eb1bad6 // addv s22, v22.4s
	WORD $0x4f2456d6 // shl v22.4s, v22.4s, #4
	WORD $0x4e0406d6 // dup v22.4s, v22.s[0]
	WORD $0x4f000400 // movi v0.4s, #0
	WORD $0x4f000401 // movi v1.4s, #0
	WORD $0x4f000402 // movi v2.4s, #0
	WORD $0x4f000403 // movi v3.4s, #0
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
	WORD $0xfc40214d // ldur d13, [x10, #2]
	WORD $0x4e0805ad // dup v13.2d, v13.d[0]
	WORD $0xfc41214e // ldur d14, [x10, #18]
	WORD $0x4e0805ce // dup v14.2d, v14.d[0]
	WORD $0x4e8d9520 // sdot v0.4s, v9.16b, v13.16b
	WORD $0x4e8e9540 // sdot v0.4s, v10.16b, v14.16b
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
	WORD $0xfc40214d // ldur d13, [x10, #2]
	WORD $0x4e0805ad // dup v13.2d, v13.d[0]
	WORD $0xfc41214e // ldur d14, [x10, #18]
	WORD $0x4e0805ce // dup v14.2d, v14.d[0]
	WORD $0x4e8d9521 // sdot v1.4s, v9.16b, v13.16b
	WORD $0x4e8e9541 // sdot v1.4s, v10.16b, v14.16b
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
	WORD $0xfc40214d // ldur d13, [x10, #2]
	WORD $0x4e0805ad // dup v13.2d, v13.d[0]
	WORD $0xfc41214e // ldur d14, [x10, #18]
	WORD $0x4e0805ce // dup v14.2d, v14.d[0]
	WORD $0x4e8d9522 // sdot v2.4s, v9.16b, v13.16b
	WORD $0x4e8e9542 // sdot v2.4s, v10.16b, v14.16b
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
	WORD $0xfc40214d // ldur d13, [x10, #2]
	WORD $0x4e0805ad // dup v13.2d, v13.d[0]
	WORD $0xfc41214e // ldur d14, [x10, #18]
	WORD $0x4e0805ce // dup v14.2d, v14.d[0]
	WORD $0x4e8d9523 // sdot v3.4s, v9.16b, v13.16b
	WORD $0x4e8e9543 // sdot v3.4s, v10.16b, v14.16b
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
	WORD $0xfc40a14d // ldur d13, [x10, #10]
	WORD $0x4e0805ad // dup v13.2d, v13.d[0]
	WORD $0xfc41a14e // ldur d14, [x10, #26]
	WORD $0x4e0805ce // dup v14.2d, v14.d[0]
	WORD $0x4e8d9520 // sdot v0.4s, v9.16b, v13.16b
	WORD $0x4e8e9540 // sdot v0.4s, v10.16b, v14.16b
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
	WORD $0xfc40a14d // ldur d13, [x10, #10]
	WORD $0x4e0805ad // dup v13.2d, v13.d[0]
	WORD $0xfc41a14e // ldur d14, [x10, #26]
	WORD $0x4e0805ce // dup v14.2d, v14.d[0]
	WORD $0x4e8d9521 // sdot v1.4s, v9.16b, v13.16b
	WORD $0x4e8e9541 // sdot v1.4s, v10.16b, v14.16b
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
	WORD $0xfc40a14d // ldur d13, [x10, #10]
	WORD $0x4e0805ad // dup v13.2d, v13.d[0]
	WORD $0xfc41a14e // ldur d14, [x10, #26]
	WORD $0x4e0805ce // dup v14.2d, v14.d[0]
	WORD $0x4e8d9522 // sdot v2.4s, v9.16b, v13.16b
	WORD $0x4e8e9542 // sdot v2.4s, v10.16b, v14.16b
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
	WORD $0xfc40a14d // ldur d13, [x10, #10]
	WORD $0x4e0805ad // dup v13.2d, v13.d[0]
	WORD $0xfc41a14e // ldur d14, [x10, #26]
	WORD $0x4e0805ce // dup v14.2d, v14.d[0]
	WORD $0x4e8d9523 // sdot v3.4s, v9.16b, v13.16b
	WORD $0x4e8e9543 // sdot v3.4s, v10.16b, v14.16b
	WORD $0x4ea1bc00 // addp v0.4s, v0.4s, v1.4s
	WORD $0x4ea3bc41 // addp v1.4s, v2.4s, v3.4s
	WORD $0x6eb68400 // sub v0.4s, v0.4s, v22.4s
	WORD $0x6eb68421 // sub v1.4s, v1.4s, v22.4s
	WORD $0x4e21d800 // scvtf v0.4s, v0.4s
	WORD $0x4e21d821 // scvtf v1.4s, v1.4s
	WORD $0xfc40012f // ldur d15, [x9, #0]
	WORD $0x0e2179ef // fcvtl v15.4s, v15.4h
	WORD $0xfc408130 // ldur d16, [x9, #8]
	WORD $0x0e217a10 // fcvtl v16.4s, v16.4h
	WORD $0x7c400151 // ldur h17, [x10, #0]
	WORD $0x1ee24231 // fcvt s17, h17
	WORD $0x4f9191ef // fmul v15.4s, v15.4s, v17.s[0]
	WORD $0x4f919210 // fmul v16.4s, v16.4s, v17.s[0]
	WORD $0x4e2fcc04 // fmla v4.4s, v0.4s, v15.4s
	WORD $0x4e30cc25 // fmla v5.4s, v1.4s, v16.4s
	ADD	$176, R9, R9
	ADD	$34, R10, R10
	SUBW	$1, R11, R11
	CBNZW	R11, gv5blk
gv5store:
	WORD $0x3c800044 // stur q4, [x2, #0]
	WORD $0x3c810045 // stur q5, [x2, #16]
	ADD	$32, R2, R2
	ADD	R3, R6, R3
	SUBW	$1, R7, R7
	CBNZW	R7, gv5group
gv5done:
	RET
gv5oob:
	B	ovr_oob

DATA ·ovr_dbg_gemv_q5_0_8x8_dotprod_b80_361b3c5951b4d2d4+0(SB)/8, $0x8040201008040201
DATA ·ovr_dbg_gemv_q5_0_8x8_dotprod_b80_361b3c5951b4d2d4+8(SB)/8, $0x8040201008040201
DATA ·ovr_dbg_gemv_q5_0_8x8_dotprod_b80_361b3c5951b4d2d4+16(SB)/8, $0x0
DATA ·ovr_dbg_gemv_q5_0_8x8_dotprod_b80_361b3c5951b4d2d4+24(SB)/8, $0x101010101010101
DATA ·ovr_dbg_gemv_q5_0_8x8_dotprod_b80_361b3c5951b4d2d4+32(SB)/8, $0x202020202020202
DATA ·ovr_dbg_gemv_q5_0_8x8_dotprod_b80_361b3c5951b4d2d4+40(SB)/8, $0x303030303030303
DATA ·ovr_dbg_gemv_q5_0_8x8_dotprod_b80_361b3c5951b4d2d4+48(SB)/8, $0xf6eaddcfbfad9881
DATA ·ovr_dbg_gemv_q5_0_8x8_dotprod_b80_361b3c5951b4d2d4+56(SB)/8, $0x7159453526190d01
DATA ·ovr_dbg_gemv_q5_0_8x8_dotprod_b80_361b3c5951b4d2d4+64(SB)/8, $0xc08060403020100
DATA ·ovr_dbg_gemv_q5_0_8x8_dotprod_b80_361b3c5951b4d2d4+72(SB)/8, $0xf4f8fafcfdfeff00
GLOBL ·ovr_dbg_gemv_q5_0_8x8_dotprod_b80_361b3c5951b4d2d4(SB), RODATA|NOPTR, $80
