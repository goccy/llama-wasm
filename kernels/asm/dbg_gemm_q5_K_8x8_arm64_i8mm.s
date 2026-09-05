// dbg_gemm_q5_K_8x8: q5_K 8x8 repack GEMM, SMMLA 2x2 tiles over the interleaved layouts.
	MOVW	l0+8(FP), R1
	LSRW	$8, R1, R1
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
	MOVD	$1408, R6
	MUL	R1, R6, R6
	MUL	R7, R6, R26
	ADD	R3, R26, R26
	CMP	R26, R21
	BLO	gm5oob
	MOVD	l4+40(FP), R4
	MOVD	$1168, R26
	MUL	R1, R26, R26
	MUL	R8, R26, R26
	ADD	R4, R26, R26
	CMP	R26, R21
	BLO	gm5oob
	ADD	R20, R2, R2
	ADD	R20, R3, R3
	ADD	R20, R4, R4
	MOVD	$q5kscratch-256(SP), R23
	WORD $0x4f00e5ff // movi v31.16b, #15
gm5rows:
	MOVD	R3, R0
	MOVD	R2, R24
	MOVW	R7, R25
gm5cols:
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x3c8802e8 // stur q8, [x23, #128]
	WORD $0x3c8902e8 // stur q8, [x23, #144]
	WORD $0x3c8a02e8 // stur q8, [x23, #160]
	WORD $0x3c8b02e8 // stur q8, [x23, #176]
	WORD $0x3c8c02e8 // stur q8, [x23, #192]
	WORD $0x3c8d02e8 // stur q8, [x23, #208]
	WORD $0x3c8e02e8 // stur q8, [x23, #224]
	WORD $0x3c8f02e8 // stur q8, [x23, #240]
	MOVD	R0, R9
	MOVD	R4, R10
	MOVW	R1, R11
	CBZW	R11, gm5store
gm5blk:
	MOVWU	32(R9), R13
	MOVWU	36(R9), R14
	MOVWU	40(R9), R15
	ANDW	$0x3f3f3f3f, R14, R19
	LSRW	$4, R15, R22
	ANDW	$0x0f0f0f0f, R22, R22
	LSRW	$6, R14, R14
	ANDW	$0x03030303, R14, R14
	ORRW	R14<<4, R22, R22
	ORR	R22<<32, R19, R19
	WORD $0x9e670270 // fmov d16, x19
	ANDW	$0x3f3f3f3f, R13, R19
	ANDW	$0x0f0f0f0f, R15, R22
	LSRW	$6, R13, R14
	ANDW	$0x03030303, R14, R14
	ORRW	R14<<4, R22, R22
	ORR	R22<<32, R19, R19
	WORD $0x9e670271 // fmov d17, x19
	WORD $0xfc0002f1 // stur d17, [x23, #0]
	WORD $0xfc0082f0 // stur d16, [x23, #8]
	MOVWU	44(R9), R13
	MOVWU	48(R9), R14
	MOVWU	52(R9), R15
	ANDW	$0x3f3f3f3f, R14, R19
	LSRW	$4, R15, R22
	ANDW	$0x0f0f0f0f, R22, R22
	LSRW	$6, R14, R14
	ANDW	$0x03030303, R14, R14
	ORRW	R14<<4, R22, R22
	ORR	R22<<32, R19, R19
	WORD $0x9e670270 // fmov d16, x19
	ANDW	$0x3f3f3f3f, R13, R19
	ANDW	$0x0f0f0f0f, R15, R22
	LSRW	$6, R13, R14
	ANDW	$0x03030303, R14, R14
	ORRW	R14<<4, R22, R22
	ORR	R22<<32, R19, R19
	WORD $0x9e670271 // fmov d17, x19
	WORD $0xfc0102f1 // stur d17, [x23, #16]
	WORD $0xfc0182f0 // stur d16, [x23, #24]
	MOVWU	56(R9), R13
	MOVWU	60(R9), R14
	MOVWU	64(R9), R15
	ANDW	$0x3f3f3f3f, R14, R19
	LSRW	$4, R15, R22
	ANDW	$0x0f0f0f0f, R22, R22
	LSRW	$6, R14, R14
	ANDW	$0x03030303, R14, R14
	ORRW	R14<<4, R22, R22
	ORR	R22<<32, R19, R19
	WORD $0x9e670270 // fmov d16, x19
	ANDW	$0x3f3f3f3f, R13, R19
	ANDW	$0x0f0f0f0f, R15, R22
	LSRW	$6, R13, R14
	ANDW	$0x03030303, R14, R14
	ORRW	R14<<4, R22, R22
	ORR	R22<<32, R19, R19
	WORD $0x9e670271 // fmov d17, x19
	WORD $0xfc0202f1 // stur d17, [x23, #32]
	WORD $0xfc0282f0 // stur d16, [x23, #40]
	MOVWU	68(R9), R13
	MOVWU	72(R9), R14
	MOVWU	76(R9), R15
	ANDW	$0x3f3f3f3f, R14, R19
	LSRW	$4, R15, R22
	ANDW	$0x0f0f0f0f, R22, R22
	LSRW	$6, R14, R14
	ANDW	$0x03030303, R14, R14
	ORRW	R14<<4, R22, R22
	ORR	R22<<32, R19, R19
	WORD $0x9e670270 // fmov d16, x19
	ANDW	$0x3f3f3f3f, R13, R19
	ANDW	$0x0f0f0f0f, R15, R22
	LSRW	$6, R13, R14
	ANDW	$0x03030303, R14, R14
	ORRW	R14<<4, R22, R22
	ORR	R22<<32, R19, R19
	WORD $0x9e670271 // fmov d17, x19
	WORD $0xfc0302f1 // stur d17, [x23, #48]
	WORD $0xfc0382f0 // stur d16, [x23, #56]
	MOVWU	80(R9), R13
	MOVWU	84(R9), R14
	MOVWU	88(R9), R15
	ANDW	$0x3f3f3f3f, R14, R19
	LSRW	$4, R15, R22
	ANDW	$0x0f0f0f0f, R22, R22
	LSRW	$6, R14, R14
	ANDW	$0x03030303, R14, R14
	ORRW	R14<<4, R22, R22
	ORR	R22<<32, R19, R19
	WORD $0x9e670270 // fmov d16, x19
	ANDW	$0x3f3f3f3f, R13, R19
	ANDW	$0x0f0f0f0f, R15, R22
	LSRW	$6, R13, R14
	ANDW	$0x03030303, R14, R14
	ORRW	R14<<4, R22, R22
	ORR	R22<<32, R19, R19
	WORD $0x9e670271 // fmov d17, x19
	WORD $0xfc0402f1 // stur d17, [x23, #64]
	WORD $0xfc0482f0 // stur d16, [x23, #72]
	MOVWU	92(R9), R13
	MOVWU	96(R9), R14
	MOVWU	100(R9), R15
	ANDW	$0x3f3f3f3f, R14, R19
	LSRW	$4, R15, R22
	ANDW	$0x0f0f0f0f, R22, R22
	LSRW	$6, R14, R14
	ANDW	$0x03030303, R14, R14
	ORRW	R14<<4, R22, R22
	ORR	R22<<32, R19, R19
	WORD $0x9e670270 // fmov d16, x19
	ANDW	$0x3f3f3f3f, R13, R19
	ANDW	$0x0f0f0f0f, R15, R22
	LSRW	$6, R13, R14
	ANDW	$0x03030303, R14, R14
	ORRW	R14<<4, R22, R22
	ORR	R22<<32, R19, R19
	WORD $0x9e670271 // fmov d17, x19
	WORD $0xfc0502f1 // stur d17, [x23, #80]
	WORD $0xfc0582f0 // stur d16, [x23, #88]
	MOVWU	104(R9), R13
	MOVWU	108(R9), R14
	MOVWU	112(R9), R15
	ANDW	$0x3f3f3f3f, R14, R19
	LSRW	$4, R15, R22
	ANDW	$0x0f0f0f0f, R22, R22
	LSRW	$6, R14, R14
	ANDW	$0x03030303, R14, R14
	ORRW	R14<<4, R22, R22
	ORR	R22<<32, R19, R19
	WORD $0x9e670270 // fmov d16, x19
	ANDW	$0x3f3f3f3f, R13, R19
	ANDW	$0x0f0f0f0f, R15, R22
	LSRW	$6, R13, R14
	ANDW	$0x03030303, R14, R14
	ORRW	R14<<4, R22, R22
	ORR	R22<<32, R19, R19
	WORD $0x9e670271 // fmov d17, x19
	WORD $0xfc0602f1 // stur d17, [x23, #96]
	WORD $0xfc0682f0 // stur d16, [x23, #104]
	MOVWU	116(R9), R13
	MOVWU	120(R9), R14
	MOVWU	124(R9), R15
	ANDW	$0x3f3f3f3f, R14, R19
	LSRW	$4, R15, R22
	ANDW	$0x0f0f0f0f, R22, R22
	LSRW	$6, R14, R14
	ANDW	$0x03030303, R14, R14
	ORRW	R14<<4, R22, R22
	ORR	R22<<32, R19, R19
	WORD $0x9e670270 // fmov d16, x19
	ANDW	$0x3f3f3f3f, R13, R19
	ANDW	$0x0f0f0f0f, R15, R22
	LSRW	$6, R13, R14
	ANDW	$0x03030303, R14, R14
	ORRW	R14<<4, R22, R22
	ORR	R22<<32, R19, R19
	WORD $0x9e670271 // fmov d17, x19
	WORD $0xfc0702f1 // stur d17, [x23, #112]
	WORD $0xfc0782f0 // stur d16, [x23, #120]
	WORD $0x4f000400 // movi v0.4s, #0
	WORD $0x4f000401 // movi v1.4s, #0
	WORD $0x4f000402 // movi v2.4s, #0
	WORD $0x4f000403 // movi v3.4s, #0
	WORD $0x4f000404 // movi v4.4s, #0
	WORD $0x4f000405 // movi v5.4s, #0
	WORD $0x4f000406 // movi v6.4s, #0
	WORD $0x4f000407 // movi v7.4s, #0
	ADD	$128, R9, R13
	WORD $0x4f00e436 // movi v22.16b, #1
	WORD $0x4f00e457 // movi v23.16b, #2
	WORD $0xfc4002f8 // ldur d24, [x23, #0]
	WORD $0x2f08a718 // ushll v24.8h, v24.8b, #0
	WORD $0x2f10a71a // ushll v26.4s, v24.4h, #0
	WORD $0x6f10a71b // ushll2 v27.4s, v24.8h, #0
	WORD $0xfc4102f9 // ldur d25, [x23, #16]
	WORD $0x2f08a739 // ushll v25.8h, v25.8b, #0
	WORD $0x2f10a73c // ushll v28.4s, v25.4h, #0
	WORD $0x6f10a73d // ushll2 v29.4s, v25.8h, #0
	ADD	$384, R9, R12
	ADD	$16, R10, R14
	WORD $0x4e9a3b54 // zip1 v20.4s, v26.4s, v26.4s
	WORD $0x4e9c3b95 // zip1 v21.4s, v28.4s, v28.4s
	WORD $0x3cc0018c // ldur q12, [x12, #0]
	WORD $0x3cc4018d // ldur q13, [x12, #64]
	WORD $0x3cc8018e // ldur q14, [x12, #128]
	WORD $0x3ccc018f // ldur q15, [x12, #192]
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x6f0c0591 // ushr v17.16b, v12.16b, #4
	WORD $0x3cc001b8 // ldur q24, [x13, #0]
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc801d2 // ldur q18, [x14, #128]
	WORD $0x3cc901d3 // ldur q19, [x14, #144]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1db0 // and v16.16b, v13.16b, v31.16b
	WORD $0x6f0c05b1 // ushr v17.16b, v13.16b, #4
	WORD $0x3cc401b8 // ldur q24, [x13, #64]
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cca01d2 // ldur q18, [x14, #160]
	WORD $0x3ccb01d3 // ldur q19, [x14, #176]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1dd0 // and v16.16b, v14.16b, v31.16b
	WORD $0x6f0c05d1 // ushr v17.16b, v14.16b, #4
	WORD $0x3cc801b8 // ldur q24, [x13, #128]
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc401d2 // ldur q18, [x14, #64]
	WORD $0x3cc501d3 // ldur q19, [x14, #80]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3ccc01d2 // ldur q18, [x14, #192]
	WORD $0x3ccd01d3 // ldur q19, [x14, #208]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1df0 // and v16.16b, v15.16b, v31.16b
	WORD $0x6f0c05f1 // ushr v17.16b, v15.16b, #4
	WORD $0x3ccc01b8 // ldur q24, [x13, #192]
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc601d2 // ldur q18, [x14, #96]
	WORD $0x3cc701d3 // ldur q19, [x14, #112]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cce01d2 // ldur q18, [x14, #224]
	WORD $0x3ccf01d3 // ldur q19, [x14, #240]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4eb49500 // mla v0.4s, v8.4s, v20.4s
	WORD $0x4eb59520 // mla v0.4s, v9.4s, v21.4s
	WORD $0x4eb49544 // mla v4.4s, v10.4s, v20.4s
	WORD $0x4eb59564 // mla v4.4s, v11.4s, v21.4s
	WORD $0x4e9a7b54 // zip2 v20.4s, v26.4s, v26.4s
	WORD $0x4e9c7b95 // zip2 v21.4s, v28.4s, v28.4s
	WORD $0x3cc1018c // ldur q12, [x12, #16]
	WORD $0x3cc5018d // ldur q13, [x12, #80]
	WORD $0x3cc9018e // ldur q14, [x12, #144]
	WORD $0x3ccd018f // ldur q15, [x12, #208]
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x6f0c0591 // ushr v17.16b, v12.16b, #4
	WORD $0x3cc101b8 // ldur q24, [x13, #16]
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc801d2 // ldur q18, [x14, #128]
	WORD $0x3cc901d3 // ldur q19, [x14, #144]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1db0 // and v16.16b, v13.16b, v31.16b
	WORD $0x6f0c05b1 // ushr v17.16b, v13.16b, #4
	WORD $0x3cc501b8 // ldur q24, [x13, #80]
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cca01d2 // ldur q18, [x14, #160]
	WORD $0x3ccb01d3 // ldur q19, [x14, #176]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1dd0 // and v16.16b, v14.16b, v31.16b
	WORD $0x6f0c05d1 // ushr v17.16b, v14.16b, #4
	WORD $0x3cc901b8 // ldur q24, [x13, #144]
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc401d2 // ldur q18, [x14, #64]
	WORD $0x3cc501d3 // ldur q19, [x14, #80]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3ccc01d2 // ldur q18, [x14, #192]
	WORD $0x3ccd01d3 // ldur q19, [x14, #208]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1df0 // and v16.16b, v15.16b, v31.16b
	WORD $0x6f0c05f1 // ushr v17.16b, v15.16b, #4
	WORD $0x3ccd01b8 // ldur q24, [x13, #208]
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc601d2 // ldur q18, [x14, #96]
	WORD $0x3cc701d3 // ldur q19, [x14, #112]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cce01d2 // ldur q18, [x14, #224]
	WORD $0x3ccf01d3 // ldur q19, [x14, #240]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4eb49501 // mla v1.4s, v8.4s, v20.4s
	WORD $0x4eb59521 // mla v1.4s, v9.4s, v21.4s
	WORD $0x4eb49545 // mla v5.4s, v10.4s, v20.4s
	WORD $0x4eb59565 // mla v5.4s, v11.4s, v21.4s
	WORD $0x4e9b3b74 // zip1 v20.4s, v27.4s, v27.4s
	WORD $0x4e9d3bb5 // zip1 v21.4s, v29.4s, v29.4s
	WORD $0x3cc2018c // ldur q12, [x12, #32]
	WORD $0x3cc6018d // ldur q13, [x12, #96]
	WORD $0x3cca018e // ldur q14, [x12, #160]
	WORD $0x3cce018f // ldur q15, [x12, #224]
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x6f0c0591 // ushr v17.16b, v12.16b, #4
	WORD $0x3cc201b8 // ldur q24, [x13, #32]
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc801d2 // ldur q18, [x14, #128]
	WORD $0x3cc901d3 // ldur q19, [x14, #144]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1db0 // and v16.16b, v13.16b, v31.16b
	WORD $0x6f0c05b1 // ushr v17.16b, v13.16b, #4
	WORD $0x3cc601b8 // ldur q24, [x13, #96]
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cca01d2 // ldur q18, [x14, #160]
	WORD $0x3ccb01d3 // ldur q19, [x14, #176]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1dd0 // and v16.16b, v14.16b, v31.16b
	WORD $0x6f0c05d1 // ushr v17.16b, v14.16b, #4
	WORD $0x3cca01b8 // ldur q24, [x13, #160]
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc401d2 // ldur q18, [x14, #64]
	WORD $0x3cc501d3 // ldur q19, [x14, #80]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3ccc01d2 // ldur q18, [x14, #192]
	WORD $0x3ccd01d3 // ldur q19, [x14, #208]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1df0 // and v16.16b, v15.16b, v31.16b
	WORD $0x6f0c05f1 // ushr v17.16b, v15.16b, #4
	WORD $0x3cce01b8 // ldur q24, [x13, #224]
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc601d2 // ldur q18, [x14, #96]
	WORD $0x3cc701d3 // ldur q19, [x14, #112]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cce01d2 // ldur q18, [x14, #224]
	WORD $0x3ccf01d3 // ldur q19, [x14, #240]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4eb49502 // mla v2.4s, v8.4s, v20.4s
	WORD $0x4eb59522 // mla v2.4s, v9.4s, v21.4s
	WORD $0x4eb49546 // mla v6.4s, v10.4s, v20.4s
	WORD $0x4eb59566 // mla v6.4s, v11.4s, v21.4s
	WORD $0x4e9b7b74 // zip2 v20.4s, v27.4s, v27.4s
	WORD $0x4e9d7bb5 // zip2 v21.4s, v29.4s, v29.4s
	WORD $0x3cc3018c // ldur q12, [x12, #48]
	WORD $0x3cc7018d // ldur q13, [x12, #112]
	WORD $0x3ccb018e // ldur q14, [x12, #176]
	WORD $0x3ccf018f // ldur q15, [x12, #240]
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x6f0c0591 // ushr v17.16b, v12.16b, #4
	WORD $0x3cc301b8 // ldur q24, [x13, #48]
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc801d2 // ldur q18, [x14, #128]
	WORD $0x3cc901d3 // ldur q19, [x14, #144]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1db0 // and v16.16b, v13.16b, v31.16b
	WORD $0x6f0c05b1 // ushr v17.16b, v13.16b, #4
	WORD $0x3cc701b8 // ldur q24, [x13, #112]
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cca01d2 // ldur q18, [x14, #160]
	WORD $0x3ccb01d3 // ldur q19, [x14, #176]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1dd0 // and v16.16b, v14.16b, v31.16b
	WORD $0x6f0c05d1 // ushr v17.16b, v14.16b, #4
	WORD $0x3ccb01b8 // ldur q24, [x13, #176]
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc401d2 // ldur q18, [x14, #64]
	WORD $0x3cc501d3 // ldur q19, [x14, #80]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3ccc01d2 // ldur q18, [x14, #192]
	WORD $0x3ccd01d3 // ldur q19, [x14, #208]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1df0 // and v16.16b, v15.16b, v31.16b
	WORD $0x6f0c05f1 // ushr v17.16b, v15.16b, #4
	WORD $0x3ccf01b8 // ldur q24, [x13, #240]
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc601d2 // ldur q18, [x14, #96]
	WORD $0x3cc701d3 // ldur q19, [x14, #112]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cce01d2 // ldur q18, [x14, #224]
	WORD $0x3ccf01d3 // ldur q19, [x14, #240]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4eb49503 // mla v3.4s, v8.4s, v20.4s
	WORD $0x4eb59523 // mla v3.4s, v9.4s, v21.4s
	WORD $0x4eb49547 // mla v7.4s, v10.4s, v20.4s
	WORD $0x4eb59567 // mla v7.4s, v11.4s, v21.4s
	WORD $0xfc4202f8 // ldur d24, [x23, #32]
	WORD $0x2f08a718 // ushll v24.8h, v24.8b, #0
	WORD $0x2f10a71a // ushll v26.4s, v24.4h, #0
	WORD $0x6f10a71b // ushll2 v27.4s, v24.8h, #0
	WORD $0xfc4302f9 // ldur d25, [x23, #48]
	WORD $0x2f08a739 // ushll v25.8h, v25.8b, #0
	WORD $0x2f10a73c // ushll v28.4s, v25.4h, #0
	WORD $0x6f10a73d // ushll2 v29.4s, v25.8h, #0
	ADD	$640, R9, R12
	ADD	$272, R10, R14
	WORD $0x4e9a3b54 // zip1 v20.4s, v26.4s, v26.4s
	WORD $0x4e9c3b95 // zip1 v21.4s, v28.4s, v28.4s
	WORD $0x3cc0018c // ldur q12, [x12, #0]
	WORD $0x3cc4018d // ldur q13, [x12, #64]
	WORD $0x3cc8018e // ldur q14, [x12, #128]
	WORD $0x3ccc018f // ldur q15, [x12, #192]
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x6f0c0591 // ushr v17.16b, v12.16b, #4
	WORD $0x3cc001b8 // ldur q24, [x13, #0]
	WORD $0x6f0e0718 // ushr v24.16b, v24.16b, #2
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc801d2 // ldur q18, [x14, #128]
	WORD $0x3cc901d3 // ldur q19, [x14, #144]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1db0 // and v16.16b, v13.16b, v31.16b
	WORD $0x6f0c05b1 // ushr v17.16b, v13.16b, #4
	WORD $0x3cc401b8 // ldur q24, [x13, #64]
	WORD $0x6f0e0718 // ushr v24.16b, v24.16b, #2
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cca01d2 // ldur q18, [x14, #160]
	WORD $0x3ccb01d3 // ldur q19, [x14, #176]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1dd0 // and v16.16b, v14.16b, v31.16b
	WORD $0x6f0c05d1 // ushr v17.16b, v14.16b, #4
	WORD $0x3cc801b8 // ldur q24, [x13, #128]
	WORD $0x6f0e0718 // ushr v24.16b, v24.16b, #2
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc401d2 // ldur q18, [x14, #64]
	WORD $0x3cc501d3 // ldur q19, [x14, #80]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3ccc01d2 // ldur q18, [x14, #192]
	WORD $0x3ccd01d3 // ldur q19, [x14, #208]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1df0 // and v16.16b, v15.16b, v31.16b
	WORD $0x6f0c05f1 // ushr v17.16b, v15.16b, #4
	WORD $0x3ccc01b8 // ldur q24, [x13, #192]
	WORD $0x6f0e0718 // ushr v24.16b, v24.16b, #2
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc601d2 // ldur q18, [x14, #96]
	WORD $0x3cc701d3 // ldur q19, [x14, #112]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cce01d2 // ldur q18, [x14, #224]
	WORD $0x3ccf01d3 // ldur q19, [x14, #240]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4eb49500 // mla v0.4s, v8.4s, v20.4s
	WORD $0x4eb59520 // mla v0.4s, v9.4s, v21.4s
	WORD $0x4eb49544 // mla v4.4s, v10.4s, v20.4s
	WORD $0x4eb59564 // mla v4.4s, v11.4s, v21.4s
	WORD $0x4e9a7b54 // zip2 v20.4s, v26.4s, v26.4s
	WORD $0x4e9c7b95 // zip2 v21.4s, v28.4s, v28.4s
	WORD $0x3cc1018c // ldur q12, [x12, #16]
	WORD $0x3cc5018d // ldur q13, [x12, #80]
	WORD $0x3cc9018e // ldur q14, [x12, #144]
	WORD $0x3ccd018f // ldur q15, [x12, #208]
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x6f0c0591 // ushr v17.16b, v12.16b, #4
	WORD $0x3cc101b8 // ldur q24, [x13, #16]
	WORD $0x6f0e0718 // ushr v24.16b, v24.16b, #2
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc801d2 // ldur q18, [x14, #128]
	WORD $0x3cc901d3 // ldur q19, [x14, #144]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1db0 // and v16.16b, v13.16b, v31.16b
	WORD $0x6f0c05b1 // ushr v17.16b, v13.16b, #4
	WORD $0x3cc501b8 // ldur q24, [x13, #80]
	WORD $0x6f0e0718 // ushr v24.16b, v24.16b, #2
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cca01d2 // ldur q18, [x14, #160]
	WORD $0x3ccb01d3 // ldur q19, [x14, #176]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1dd0 // and v16.16b, v14.16b, v31.16b
	WORD $0x6f0c05d1 // ushr v17.16b, v14.16b, #4
	WORD $0x3cc901b8 // ldur q24, [x13, #144]
	WORD $0x6f0e0718 // ushr v24.16b, v24.16b, #2
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc401d2 // ldur q18, [x14, #64]
	WORD $0x3cc501d3 // ldur q19, [x14, #80]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3ccc01d2 // ldur q18, [x14, #192]
	WORD $0x3ccd01d3 // ldur q19, [x14, #208]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1df0 // and v16.16b, v15.16b, v31.16b
	WORD $0x6f0c05f1 // ushr v17.16b, v15.16b, #4
	WORD $0x3ccd01b8 // ldur q24, [x13, #208]
	WORD $0x6f0e0718 // ushr v24.16b, v24.16b, #2
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc601d2 // ldur q18, [x14, #96]
	WORD $0x3cc701d3 // ldur q19, [x14, #112]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cce01d2 // ldur q18, [x14, #224]
	WORD $0x3ccf01d3 // ldur q19, [x14, #240]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4eb49501 // mla v1.4s, v8.4s, v20.4s
	WORD $0x4eb59521 // mla v1.4s, v9.4s, v21.4s
	WORD $0x4eb49545 // mla v5.4s, v10.4s, v20.4s
	WORD $0x4eb59565 // mla v5.4s, v11.4s, v21.4s
	WORD $0x4e9b3b74 // zip1 v20.4s, v27.4s, v27.4s
	WORD $0x4e9d3bb5 // zip1 v21.4s, v29.4s, v29.4s
	WORD $0x3cc2018c // ldur q12, [x12, #32]
	WORD $0x3cc6018d // ldur q13, [x12, #96]
	WORD $0x3cca018e // ldur q14, [x12, #160]
	WORD $0x3cce018f // ldur q15, [x12, #224]
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x6f0c0591 // ushr v17.16b, v12.16b, #4
	WORD $0x3cc201b8 // ldur q24, [x13, #32]
	WORD $0x6f0e0718 // ushr v24.16b, v24.16b, #2
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc801d2 // ldur q18, [x14, #128]
	WORD $0x3cc901d3 // ldur q19, [x14, #144]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1db0 // and v16.16b, v13.16b, v31.16b
	WORD $0x6f0c05b1 // ushr v17.16b, v13.16b, #4
	WORD $0x3cc601b8 // ldur q24, [x13, #96]
	WORD $0x6f0e0718 // ushr v24.16b, v24.16b, #2
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cca01d2 // ldur q18, [x14, #160]
	WORD $0x3ccb01d3 // ldur q19, [x14, #176]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1dd0 // and v16.16b, v14.16b, v31.16b
	WORD $0x6f0c05d1 // ushr v17.16b, v14.16b, #4
	WORD $0x3cca01b8 // ldur q24, [x13, #160]
	WORD $0x6f0e0718 // ushr v24.16b, v24.16b, #2
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc401d2 // ldur q18, [x14, #64]
	WORD $0x3cc501d3 // ldur q19, [x14, #80]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3ccc01d2 // ldur q18, [x14, #192]
	WORD $0x3ccd01d3 // ldur q19, [x14, #208]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1df0 // and v16.16b, v15.16b, v31.16b
	WORD $0x6f0c05f1 // ushr v17.16b, v15.16b, #4
	WORD $0x3cce01b8 // ldur q24, [x13, #224]
	WORD $0x6f0e0718 // ushr v24.16b, v24.16b, #2
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc601d2 // ldur q18, [x14, #96]
	WORD $0x3cc701d3 // ldur q19, [x14, #112]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cce01d2 // ldur q18, [x14, #224]
	WORD $0x3ccf01d3 // ldur q19, [x14, #240]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4eb49502 // mla v2.4s, v8.4s, v20.4s
	WORD $0x4eb59522 // mla v2.4s, v9.4s, v21.4s
	WORD $0x4eb49546 // mla v6.4s, v10.4s, v20.4s
	WORD $0x4eb59566 // mla v6.4s, v11.4s, v21.4s
	WORD $0x4e9b7b74 // zip2 v20.4s, v27.4s, v27.4s
	WORD $0x4e9d7bb5 // zip2 v21.4s, v29.4s, v29.4s
	WORD $0x3cc3018c // ldur q12, [x12, #48]
	WORD $0x3cc7018d // ldur q13, [x12, #112]
	WORD $0x3ccb018e // ldur q14, [x12, #176]
	WORD $0x3ccf018f // ldur q15, [x12, #240]
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x6f0c0591 // ushr v17.16b, v12.16b, #4
	WORD $0x3cc301b8 // ldur q24, [x13, #48]
	WORD $0x6f0e0718 // ushr v24.16b, v24.16b, #2
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc801d2 // ldur q18, [x14, #128]
	WORD $0x3cc901d3 // ldur q19, [x14, #144]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1db0 // and v16.16b, v13.16b, v31.16b
	WORD $0x6f0c05b1 // ushr v17.16b, v13.16b, #4
	WORD $0x3cc701b8 // ldur q24, [x13, #112]
	WORD $0x6f0e0718 // ushr v24.16b, v24.16b, #2
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cca01d2 // ldur q18, [x14, #160]
	WORD $0x3ccb01d3 // ldur q19, [x14, #176]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1dd0 // and v16.16b, v14.16b, v31.16b
	WORD $0x6f0c05d1 // ushr v17.16b, v14.16b, #4
	WORD $0x3ccb01b8 // ldur q24, [x13, #176]
	WORD $0x6f0e0718 // ushr v24.16b, v24.16b, #2
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc401d2 // ldur q18, [x14, #64]
	WORD $0x3cc501d3 // ldur q19, [x14, #80]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3ccc01d2 // ldur q18, [x14, #192]
	WORD $0x3ccd01d3 // ldur q19, [x14, #208]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1df0 // and v16.16b, v15.16b, v31.16b
	WORD $0x6f0c05f1 // ushr v17.16b, v15.16b, #4
	WORD $0x3ccf01b8 // ldur q24, [x13, #240]
	WORD $0x6f0e0718 // ushr v24.16b, v24.16b, #2
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc601d2 // ldur q18, [x14, #96]
	WORD $0x3cc701d3 // ldur q19, [x14, #112]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cce01d2 // ldur q18, [x14, #224]
	WORD $0x3ccf01d3 // ldur q19, [x14, #240]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4eb49503 // mla v3.4s, v8.4s, v20.4s
	WORD $0x4eb59523 // mla v3.4s, v9.4s, v21.4s
	WORD $0x4eb49547 // mla v7.4s, v10.4s, v20.4s
	WORD $0x4eb59567 // mla v7.4s, v11.4s, v21.4s
	WORD $0xfc4402f8 // ldur d24, [x23, #64]
	WORD $0x2f08a718 // ushll v24.8h, v24.8b, #0
	WORD $0x2f10a71a // ushll v26.4s, v24.4h, #0
	WORD $0x6f10a71b // ushll2 v27.4s, v24.8h, #0
	WORD $0xfc4502f9 // ldur d25, [x23, #80]
	WORD $0x2f08a739 // ushll v25.8h, v25.8b, #0
	WORD $0x2f10a73c // ushll v28.4s, v25.4h, #0
	WORD $0x6f10a73d // ushll2 v29.4s, v25.8h, #0
	ADD	$896, R9, R12
	ADD	$528, R10, R14
	WORD $0x4e9a3b54 // zip1 v20.4s, v26.4s, v26.4s
	WORD $0x4e9c3b95 // zip1 v21.4s, v28.4s, v28.4s
	WORD $0x3cc0018c // ldur q12, [x12, #0]
	WORD $0x3cc4018d // ldur q13, [x12, #64]
	WORD $0x3cc8018e // ldur q14, [x12, #128]
	WORD $0x3ccc018f // ldur q15, [x12, #192]
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x6f0c0591 // ushr v17.16b, v12.16b, #4
	WORD $0x3cc001b8 // ldur q24, [x13, #0]
	WORD $0x6f0c0718 // ushr v24.16b, v24.16b, #4
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc801d2 // ldur q18, [x14, #128]
	WORD $0x3cc901d3 // ldur q19, [x14, #144]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1db0 // and v16.16b, v13.16b, v31.16b
	WORD $0x6f0c05b1 // ushr v17.16b, v13.16b, #4
	WORD $0x3cc401b8 // ldur q24, [x13, #64]
	WORD $0x6f0c0718 // ushr v24.16b, v24.16b, #4
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cca01d2 // ldur q18, [x14, #160]
	WORD $0x3ccb01d3 // ldur q19, [x14, #176]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1dd0 // and v16.16b, v14.16b, v31.16b
	WORD $0x6f0c05d1 // ushr v17.16b, v14.16b, #4
	WORD $0x3cc801b8 // ldur q24, [x13, #128]
	WORD $0x6f0c0718 // ushr v24.16b, v24.16b, #4
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc401d2 // ldur q18, [x14, #64]
	WORD $0x3cc501d3 // ldur q19, [x14, #80]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3ccc01d2 // ldur q18, [x14, #192]
	WORD $0x3ccd01d3 // ldur q19, [x14, #208]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1df0 // and v16.16b, v15.16b, v31.16b
	WORD $0x6f0c05f1 // ushr v17.16b, v15.16b, #4
	WORD $0x3ccc01b8 // ldur q24, [x13, #192]
	WORD $0x6f0c0718 // ushr v24.16b, v24.16b, #4
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc601d2 // ldur q18, [x14, #96]
	WORD $0x3cc701d3 // ldur q19, [x14, #112]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cce01d2 // ldur q18, [x14, #224]
	WORD $0x3ccf01d3 // ldur q19, [x14, #240]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4eb49500 // mla v0.4s, v8.4s, v20.4s
	WORD $0x4eb59520 // mla v0.4s, v9.4s, v21.4s
	WORD $0x4eb49544 // mla v4.4s, v10.4s, v20.4s
	WORD $0x4eb59564 // mla v4.4s, v11.4s, v21.4s
	WORD $0x4e9a7b54 // zip2 v20.4s, v26.4s, v26.4s
	WORD $0x4e9c7b95 // zip2 v21.4s, v28.4s, v28.4s
	WORD $0x3cc1018c // ldur q12, [x12, #16]
	WORD $0x3cc5018d // ldur q13, [x12, #80]
	WORD $0x3cc9018e // ldur q14, [x12, #144]
	WORD $0x3ccd018f // ldur q15, [x12, #208]
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x6f0c0591 // ushr v17.16b, v12.16b, #4
	WORD $0x3cc101b8 // ldur q24, [x13, #16]
	WORD $0x6f0c0718 // ushr v24.16b, v24.16b, #4
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc801d2 // ldur q18, [x14, #128]
	WORD $0x3cc901d3 // ldur q19, [x14, #144]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1db0 // and v16.16b, v13.16b, v31.16b
	WORD $0x6f0c05b1 // ushr v17.16b, v13.16b, #4
	WORD $0x3cc501b8 // ldur q24, [x13, #80]
	WORD $0x6f0c0718 // ushr v24.16b, v24.16b, #4
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cca01d2 // ldur q18, [x14, #160]
	WORD $0x3ccb01d3 // ldur q19, [x14, #176]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1dd0 // and v16.16b, v14.16b, v31.16b
	WORD $0x6f0c05d1 // ushr v17.16b, v14.16b, #4
	WORD $0x3cc901b8 // ldur q24, [x13, #144]
	WORD $0x6f0c0718 // ushr v24.16b, v24.16b, #4
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc401d2 // ldur q18, [x14, #64]
	WORD $0x3cc501d3 // ldur q19, [x14, #80]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3ccc01d2 // ldur q18, [x14, #192]
	WORD $0x3ccd01d3 // ldur q19, [x14, #208]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1df0 // and v16.16b, v15.16b, v31.16b
	WORD $0x6f0c05f1 // ushr v17.16b, v15.16b, #4
	WORD $0x3ccd01b8 // ldur q24, [x13, #208]
	WORD $0x6f0c0718 // ushr v24.16b, v24.16b, #4
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc601d2 // ldur q18, [x14, #96]
	WORD $0x3cc701d3 // ldur q19, [x14, #112]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cce01d2 // ldur q18, [x14, #224]
	WORD $0x3ccf01d3 // ldur q19, [x14, #240]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4eb49501 // mla v1.4s, v8.4s, v20.4s
	WORD $0x4eb59521 // mla v1.4s, v9.4s, v21.4s
	WORD $0x4eb49545 // mla v5.4s, v10.4s, v20.4s
	WORD $0x4eb59565 // mla v5.4s, v11.4s, v21.4s
	WORD $0x4e9b3b74 // zip1 v20.4s, v27.4s, v27.4s
	WORD $0x4e9d3bb5 // zip1 v21.4s, v29.4s, v29.4s
	WORD $0x3cc2018c // ldur q12, [x12, #32]
	WORD $0x3cc6018d // ldur q13, [x12, #96]
	WORD $0x3cca018e // ldur q14, [x12, #160]
	WORD $0x3cce018f // ldur q15, [x12, #224]
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x6f0c0591 // ushr v17.16b, v12.16b, #4
	WORD $0x3cc201b8 // ldur q24, [x13, #32]
	WORD $0x6f0c0718 // ushr v24.16b, v24.16b, #4
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc801d2 // ldur q18, [x14, #128]
	WORD $0x3cc901d3 // ldur q19, [x14, #144]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1db0 // and v16.16b, v13.16b, v31.16b
	WORD $0x6f0c05b1 // ushr v17.16b, v13.16b, #4
	WORD $0x3cc601b8 // ldur q24, [x13, #96]
	WORD $0x6f0c0718 // ushr v24.16b, v24.16b, #4
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cca01d2 // ldur q18, [x14, #160]
	WORD $0x3ccb01d3 // ldur q19, [x14, #176]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1dd0 // and v16.16b, v14.16b, v31.16b
	WORD $0x6f0c05d1 // ushr v17.16b, v14.16b, #4
	WORD $0x3cca01b8 // ldur q24, [x13, #160]
	WORD $0x6f0c0718 // ushr v24.16b, v24.16b, #4
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc401d2 // ldur q18, [x14, #64]
	WORD $0x3cc501d3 // ldur q19, [x14, #80]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3ccc01d2 // ldur q18, [x14, #192]
	WORD $0x3ccd01d3 // ldur q19, [x14, #208]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1df0 // and v16.16b, v15.16b, v31.16b
	WORD $0x6f0c05f1 // ushr v17.16b, v15.16b, #4
	WORD $0x3cce01b8 // ldur q24, [x13, #224]
	WORD $0x6f0c0718 // ushr v24.16b, v24.16b, #4
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc601d2 // ldur q18, [x14, #96]
	WORD $0x3cc701d3 // ldur q19, [x14, #112]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cce01d2 // ldur q18, [x14, #224]
	WORD $0x3ccf01d3 // ldur q19, [x14, #240]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4eb49502 // mla v2.4s, v8.4s, v20.4s
	WORD $0x4eb59522 // mla v2.4s, v9.4s, v21.4s
	WORD $0x4eb49546 // mla v6.4s, v10.4s, v20.4s
	WORD $0x4eb59566 // mla v6.4s, v11.4s, v21.4s
	WORD $0x4e9b7b74 // zip2 v20.4s, v27.4s, v27.4s
	WORD $0x4e9d7bb5 // zip2 v21.4s, v29.4s, v29.4s
	WORD $0x3cc3018c // ldur q12, [x12, #48]
	WORD $0x3cc7018d // ldur q13, [x12, #112]
	WORD $0x3ccb018e // ldur q14, [x12, #176]
	WORD $0x3ccf018f // ldur q15, [x12, #240]
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x6f0c0591 // ushr v17.16b, v12.16b, #4
	WORD $0x3cc301b8 // ldur q24, [x13, #48]
	WORD $0x6f0c0718 // ushr v24.16b, v24.16b, #4
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc801d2 // ldur q18, [x14, #128]
	WORD $0x3cc901d3 // ldur q19, [x14, #144]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1db0 // and v16.16b, v13.16b, v31.16b
	WORD $0x6f0c05b1 // ushr v17.16b, v13.16b, #4
	WORD $0x3cc701b8 // ldur q24, [x13, #112]
	WORD $0x6f0c0718 // ushr v24.16b, v24.16b, #4
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cca01d2 // ldur q18, [x14, #160]
	WORD $0x3ccb01d3 // ldur q19, [x14, #176]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1dd0 // and v16.16b, v14.16b, v31.16b
	WORD $0x6f0c05d1 // ushr v17.16b, v14.16b, #4
	WORD $0x3ccb01b8 // ldur q24, [x13, #176]
	WORD $0x6f0c0718 // ushr v24.16b, v24.16b, #4
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc401d2 // ldur q18, [x14, #64]
	WORD $0x3cc501d3 // ldur q19, [x14, #80]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3ccc01d2 // ldur q18, [x14, #192]
	WORD $0x3ccd01d3 // ldur q19, [x14, #208]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1df0 // and v16.16b, v15.16b, v31.16b
	WORD $0x6f0c05f1 // ushr v17.16b, v15.16b, #4
	WORD $0x3ccf01b8 // ldur q24, [x13, #240]
	WORD $0x6f0c0718 // ushr v24.16b, v24.16b, #4
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc601d2 // ldur q18, [x14, #96]
	WORD $0x3cc701d3 // ldur q19, [x14, #112]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cce01d2 // ldur q18, [x14, #224]
	WORD $0x3ccf01d3 // ldur q19, [x14, #240]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4eb49503 // mla v3.4s, v8.4s, v20.4s
	WORD $0x4eb59523 // mla v3.4s, v9.4s, v21.4s
	WORD $0x4eb49547 // mla v7.4s, v10.4s, v20.4s
	WORD $0x4eb59567 // mla v7.4s, v11.4s, v21.4s
	WORD $0xfc4602f8 // ldur d24, [x23, #96]
	WORD $0x2f08a718 // ushll v24.8h, v24.8b, #0
	WORD $0x2f10a71a // ushll v26.4s, v24.4h, #0
	WORD $0x6f10a71b // ushll2 v27.4s, v24.8h, #0
	WORD $0xfc4702f9 // ldur d25, [x23, #112]
	WORD $0x2f08a739 // ushll v25.8h, v25.8b, #0
	WORD $0x2f10a73c // ushll v28.4s, v25.4h, #0
	WORD $0x6f10a73d // ushll2 v29.4s, v25.8h, #0
	ADD	$1152, R9, R12
	ADD	$784, R10, R14
	WORD $0x4e9a3b54 // zip1 v20.4s, v26.4s, v26.4s
	WORD $0x4e9c3b95 // zip1 v21.4s, v28.4s, v28.4s
	WORD $0x3cc0018c // ldur q12, [x12, #0]
	WORD $0x3cc4018d // ldur q13, [x12, #64]
	WORD $0x3cc8018e // ldur q14, [x12, #128]
	WORD $0x3ccc018f // ldur q15, [x12, #192]
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x6f0c0591 // ushr v17.16b, v12.16b, #4
	WORD $0x3cc001b8 // ldur q24, [x13, #0]
	WORD $0x6f0a0718 // ushr v24.16b, v24.16b, #6
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc801d2 // ldur q18, [x14, #128]
	WORD $0x3cc901d3 // ldur q19, [x14, #144]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1db0 // and v16.16b, v13.16b, v31.16b
	WORD $0x6f0c05b1 // ushr v17.16b, v13.16b, #4
	WORD $0x3cc401b8 // ldur q24, [x13, #64]
	WORD $0x6f0a0718 // ushr v24.16b, v24.16b, #6
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cca01d2 // ldur q18, [x14, #160]
	WORD $0x3ccb01d3 // ldur q19, [x14, #176]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1dd0 // and v16.16b, v14.16b, v31.16b
	WORD $0x6f0c05d1 // ushr v17.16b, v14.16b, #4
	WORD $0x3cc801b8 // ldur q24, [x13, #128]
	WORD $0x6f0a0718 // ushr v24.16b, v24.16b, #6
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc401d2 // ldur q18, [x14, #64]
	WORD $0x3cc501d3 // ldur q19, [x14, #80]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3ccc01d2 // ldur q18, [x14, #192]
	WORD $0x3ccd01d3 // ldur q19, [x14, #208]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1df0 // and v16.16b, v15.16b, v31.16b
	WORD $0x6f0c05f1 // ushr v17.16b, v15.16b, #4
	WORD $0x3ccc01b8 // ldur q24, [x13, #192]
	WORD $0x6f0a0718 // ushr v24.16b, v24.16b, #6
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc601d2 // ldur q18, [x14, #96]
	WORD $0x3cc701d3 // ldur q19, [x14, #112]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cce01d2 // ldur q18, [x14, #224]
	WORD $0x3ccf01d3 // ldur q19, [x14, #240]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4eb49500 // mla v0.4s, v8.4s, v20.4s
	WORD $0x4eb59520 // mla v0.4s, v9.4s, v21.4s
	WORD $0x4eb49544 // mla v4.4s, v10.4s, v20.4s
	WORD $0x4eb59564 // mla v4.4s, v11.4s, v21.4s
	WORD $0x4e9a7b54 // zip2 v20.4s, v26.4s, v26.4s
	WORD $0x4e9c7b95 // zip2 v21.4s, v28.4s, v28.4s
	WORD $0x3cc1018c // ldur q12, [x12, #16]
	WORD $0x3cc5018d // ldur q13, [x12, #80]
	WORD $0x3cc9018e // ldur q14, [x12, #144]
	WORD $0x3ccd018f // ldur q15, [x12, #208]
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x6f0c0591 // ushr v17.16b, v12.16b, #4
	WORD $0x3cc101b8 // ldur q24, [x13, #16]
	WORD $0x6f0a0718 // ushr v24.16b, v24.16b, #6
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc801d2 // ldur q18, [x14, #128]
	WORD $0x3cc901d3 // ldur q19, [x14, #144]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1db0 // and v16.16b, v13.16b, v31.16b
	WORD $0x6f0c05b1 // ushr v17.16b, v13.16b, #4
	WORD $0x3cc501b8 // ldur q24, [x13, #80]
	WORD $0x6f0a0718 // ushr v24.16b, v24.16b, #6
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cca01d2 // ldur q18, [x14, #160]
	WORD $0x3ccb01d3 // ldur q19, [x14, #176]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1dd0 // and v16.16b, v14.16b, v31.16b
	WORD $0x6f0c05d1 // ushr v17.16b, v14.16b, #4
	WORD $0x3cc901b8 // ldur q24, [x13, #144]
	WORD $0x6f0a0718 // ushr v24.16b, v24.16b, #6
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc401d2 // ldur q18, [x14, #64]
	WORD $0x3cc501d3 // ldur q19, [x14, #80]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3ccc01d2 // ldur q18, [x14, #192]
	WORD $0x3ccd01d3 // ldur q19, [x14, #208]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1df0 // and v16.16b, v15.16b, v31.16b
	WORD $0x6f0c05f1 // ushr v17.16b, v15.16b, #4
	WORD $0x3ccd01b8 // ldur q24, [x13, #208]
	WORD $0x6f0a0718 // ushr v24.16b, v24.16b, #6
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc601d2 // ldur q18, [x14, #96]
	WORD $0x3cc701d3 // ldur q19, [x14, #112]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cce01d2 // ldur q18, [x14, #224]
	WORD $0x3ccf01d3 // ldur q19, [x14, #240]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4eb49501 // mla v1.4s, v8.4s, v20.4s
	WORD $0x4eb59521 // mla v1.4s, v9.4s, v21.4s
	WORD $0x4eb49545 // mla v5.4s, v10.4s, v20.4s
	WORD $0x4eb59565 // mla v5.4s, v11.4s, v21.4s
	WORD $0x4e9b3b74 // zip1 v20.4s, v27.4s, v27.4s
	WORD $0x4e9d3bb5 // zip1 v21.4s, v29.4s, v29.4s
	WORD $0x3cc2018c // ldur q12, [x12, #32]
	WORD $0x3cc6018d // ldur q13, [x12, #96]
	WORD $0x3cca018e // ldur q14, [x12, #160]
	WORD $0x3cce018f // ldur q15, [x12, #224]
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x6f0c0591 // ushr v17.16b, v12.16b, #4
	WORD $0x3cc201b8 // ldur q24, [x13, #32]
	WORD $0x6f0a0718 // ushr v24.16b, v24.16b, #6
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc801d2 // ldur q18, [x14, #128]
	WORD $0x3cc901d3 // ldur q19, [x14, #144]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1db0 // and v16.16b, v13.16b, v31.16b
	WORD $0x6f0c05b1 // ushr v17.16b, v13.16b, #4
	WORD $0x3cc601b8 // ldur q24, [x13, #96]
	WORD $0x6f0a0718 // ushr v24.16b, v24.16b, #6
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cca01d2 // ldur q18, [x14, #160]
	WORD $0x3ccb01d3 // ldur q19, [x14, #176]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1dd0 // and v16.16b, v14.16b, v31.16b
	WORD $0x6f0c05d1 // ushr v17.16b, v14.16b, #4
	WORD $0x3cca01b8 // ldur q24, [x13, #160]
	WORD $0x6f0a0718 // ushr v24.16b, v24.16b, #6
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc401d2 // ldur q18, [x14, #64]
	WORD $0x3cc501d3 // ldur q19, [x14, #80]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3ccc01d2 // ldur q18, [x14, #192]
	WORD $0x3ccd01d3 // ldur q19, [x14, #208]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1df0 // and v16.16b, v15.16b, v31.16b
	WORD $0x6f0c05f1 // ushr v17.16b, v15.16b, #4
	WORD $0x3cce01b8 // ldur q24, [x13, #224]
	WORD $0x6f0a0718 // ushr v24.16b, v24.16b, #6
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc601d2 // ldur q18, [x14, #96]
	WORD $0x3cc701d3 // ldur q19, [x14, #112]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cce01d2 // ldur q18, [x14, #224]
	WORD $0x3ccf01d3 // ldur q19, [x14, #240]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4eb49502 // mla v2.4s, v8.4s, v20.4s
	WORD $0x4eb59522 // mla v2.4s, v9.4s, v21.4s
	WORD $0x4eb49546 // mla v6.4s, v10.4s, v20.4s
	WORD $0x4eb59566 // mla v6.4s, v11.4s, v21.4s
	WORD $0x4e9b7b74 // zip2 v20.4s, v27.4s, v27.4s
	WORD $0x4e9d7bb5 // zip2 v21.4s, v29.4s, v29.4s
	WORD $0x3cc3018c // ldur q12, [x12, #48]
	WORD $0x3cc7018d // ldur q13, [x12, #112]
	WORD $0x3ccb018e // ldur q14, [x12, #176]
	WORD $0x3ccf018f // ldur q15, [x12, #240]
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x4e3f1d90 // and v16.16b, v12.16b, v31.16b
	WORD $0x6f0c0591 // ushr v17.16b, v12.16b, #4
	WORD $0x3cc301b8 // ldur q24, [x13, #48]
	WORD $0x6f0a0718 // ushr v24.16b, v24.16b, #6
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc001d2 // ldur q18, [x14, #0]
	WORD $0x3cc101d3 // ldur q19, [x14, #16]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cc801d2 // ldur q18, [x14, #128]
	WORD $0x3cc901d3 // ldur q19, [x14, #144]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1db0 // and v16.16b, v13.16b, v31.16b
	WORD $0x6f0c05b1 // ushr v17.16b, v13.16b, #4
	WORD $0x3cc701b8 // ldur q24, [x13, #112]
	WORD $0x6f0a0718 // ushr v24.16b, v24.16b, #6
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc201d2 // ldur q18, [x14, #32]
	WORD $0x3cc301d3 // ldur q19, [x14, #48]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cca01d2 // ldur q18, [x14, #160]
	WORD $0x3ccb01d3 // ldur q19, [x14, #176]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1dd0 // and v16.16b, v14.16b, v31.16b
	WORD $0x6f0c05d1 // ushr v17.16b, v14.16b, #4
	WORD $0x3ccb01b8 // ldur q24, [x13, #176]
	WORD $0x6f0a0718 // ushr v24.16b, v24.16b, #6
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc401d2 // ldur q18, [x14, #64]
	WORD $0x3cc501d3 // ldur q19, [x14, #80]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3ccc01d2 // ldur q18, [x14, #192]
	WORD $0x3ccd01d3 // ldur q19, [x14, #208]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4e3f1df0 // and v16.16b, v15.16b, v31.16b
	WORD $0x6f0c05f1 // ushr v17.16b, v15.16b, #4
	WORD $0x3ccf01b8 // ldur q24, [x13, #240]
	WORD $0x6f0a0718 // ushr v24.16b, v24.16b, #6
	WORD $0x4e361f19 // and v25.16b, v24.16b, v22.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91e10 // orr v16.16b, v16.16b, v25.16b
	WORD $0x4e371f19 // and v25.16b, v24.16b, v23.16b
	WORD $0x4f0b5739 // shl v25.16b, v25.16b, #3
	WORD $0x4eb91e31 // orr v17.16b, v17.16b, v25.16b
	WORD $0x3cc601d2 // ldur q18, [x14, #96]
	WORD $0x3cc701d3 // ldur q19, [x14, #112]
	WORD $0x4e92a608 // smmla v8.4s, v16.16b, v18.16b
	WORD $0x4e93a60a // smmla v10.4s, v16.16b, v19.16b
	WORD $0x3cce01d2 // ldur q18, [x14, #224]
	WORD $0x3ccf01d3 // ldur q19, [x14, #240]
	WORD $0x4e92a629 // smmla v9.4s, v17.16b, v18.16b
	WORD $0x4e93a62b // smmla v11.4s, v17.16b, v19.16b
	WORD $0x4eb49503 // mla v3.4s, v8.4s, v20.4s
	WORD $0x4eb59523 // mla v3.4s, v9.4s, v21.4s
	WORD $0x4eb49547 // mla v7.4s, v10.4s, v20.4s
	WORD $0x4eb59567 // mla v7.4s, v11.4s, v21.4s
	ADD	$1040, R10, R14
	WORD $0x3cc001cc // ldur q12, [x14, #0]
	WORD $0x3cc101cd // ldur q13, [x14, #16]
	WORD $0x4e6dbd88 // addp v8.8h, v12.8h, v13.8h
	WORD $0x3cc201cc // ldur q12, [x14, #32]
	WORD $0x3cc301cd // ldur q13, [x14, #48]
	WORD $0x4e6dbd89 // addp v9.8h, v12.8h, v13.8h
	WORD $0x3cc401cc // ldur q12, [x14, #64]
	WORD $0x3cc501cd // ldur q13, [x14, #80]
	WORD $0x4e6dbd8a // addp v10.8h, v12.8h, v13.8h
	WORD $0x3cc601cc // ldur q12, [x14, #96]
	WORD $0x3cc701cd // ldur q13, [x14, #112]
	WORD $0x4e6dbd8b // addp v11.8h, v12.8h, v13.8h
	WORD $0x4f000410 // movi v16.4s, #0
	WORD $0x4f000411 // movi v17.4s, #0
	WORD $0x4f000412 // movi v18.4s, #0
	WORD $0x4f000413 // movi v19.4s, #0
	WORD $0x4f000414 // movi v20.4s, #0
	WORD $0x4f000415 // movi v21.4s, #0
	WORD $0x4f000416 // movi v22.4s, #0
	WORD $0x4f000417 // movi v23.4s, #0
	WORD $0xfc4082f8 // ldur d24, [x23, #8]
	WORD $0x2f08a718 // ushll v24.8h, v24.8b, #0
	WORD $0x0f482310 // smlal v16.4s, v24.4h, v8.h[0]
	WORD $0x4f482311 // smlal2 v17.4s, v24.8h, v8.h[0]
	WORD $0x0f682312 // smlal v18.4s, v24.4h, v8.h[2]
	WORD $0x4f682313 // smlal2 v19.4s, v24.8h, v8.h[2]
	WORD $0x0f482b14 // smlal v20.4s, v24.4h, v8.h[4]
	WORD $0x4f482b15 // smlal2 v21.4s, v24.8h, v8.h[4]
	WORD $0x0f682b16 // smlal v22.4s, v24.4h, v8.h[6]
	WORD $0x4f682b17 // smlal2 v23.4s, v24.8h, v8.h[6]
	WORD $0xfc4182f8 // ldur d24, [x23, #24]
	WORD $0x2f08a718 // ushll v24.8h, v24.8b, #0
	WORD $0x0f582310 // smlal v16.4s, v24.4h, v8.h[1]
	WORD $0x4f582311 // smlal2 v17.4s, v24.8h, v8.h[1]
	WORD $0x0f782312 // smlal v18.4s, v24.4h, v8.h[3]
	WORD $0x4f782313 // smlal2 v19.4s, v24.8h, v8.h[3]
	WORD $0x0f582b14 // smlal v20.4s, v24.4h, v8.h[5]
	WORD $0x4f582b15 // smlal2 v21.4s, v24.8h, v8.h[5]
	WORD $0x0f782b16 // smlal v22.4s, v24.4h, v8.h[7]
	WORD $0x4f782b17 // smlal2 v23.4s, v24.8h, v8.h[7]
	WORD $0xfc4282f8 // ldur d24, [x23, #40]
	WORD $0x2f08a718 // ushll v24.8h, v24.8b, #0
	WORD $0x0f492310 // smlal v16.4s, v24.4h, v9.h[0]
	WORD $0x4f492311 // smlal2 v17.4s, v24.8h, v9.h[0]
	WORD $0x0f692312 // smlal v18.4s, v24.4h, v9.h[2]
	WORD $0x4f692313 // smlal2 v19.4s, v24.8h, v9.h[2]
	WORD $0x0f492b14 // smlal v20.4s, v24.4h, v9.h[4]
	WORD $0x4f492b15 // smlal2 v21.4s, v24.8h, v9.h[4]
	WORD $0x0f692b16 // smlal v22.4s, v24.4h, v9.h[6]
	WORD $0x4f692b17 // smlal2 v23.4s, v24.8h, v9.h[6]
	WORD $0xfc4382f8 // ldur d24, [x23, #56]
	WORD $0x2f08a718 // ushll v24.8h, v24.8b, #0
	WORD $0x0f592310 // smlal v16.4s, v24.4h, v9.h[1]
	WORD $0x4f592311 // smlal2 v17.4s, v24.8h, v9.h[1]
	WORD $0x0f792312 // smlal v18.4s, v24.4h, v9.h[3]
	WORD $0x4f792313 // smlal2 v19.4s, v24.8h, v9.h[3]
	WORD $0x0f592b14 // smlal v20.4s, v24.4h, v9.h[5]
	WORD $0x4f592b15 // smlal2 v21.4s, v24.8h, v9.h[5]
	WORD $0x0f792b16 // smlal v22.4s, v24.4h, v9.h[7]
	WORD $0x4f792b17 // smlal2 v23.4s, v24.8h, v9.h[7]
	WORD $0xfc4482f8 // ldur d24, [x23, #72]
	WORD $0x2f08a718 // ushll v24.8h, v24.8b, #0
	WORD $0x0f4a2310 // smlal v16.4s, v24.4h, v10.h[0]
	WORD $0x4f4a2311 // smlal2 v17.4s, v24.8h, v10.h[0]
	WORD $0x0f6a2312 // smlal v18.4s, v24.4h, v10.h[2]
	WORD $0x4f6a2313 // smlal2 v19.4s, v24.8h, v10.h[2]
	WORD $0x0f4a2b14 // smlal v20.4s, v24.4h, v10.h[4]
	WORD $0x4f4a2b15 // smlal2 v21.4s, v24.8h, v10.h[4]
	WORD $0x0f6a2b16 // smlal v22.4s, v24.4h, v10.h[6]
	WORD $0x4f6a2b17 // smlal2 v23.4s, v24.8h, v10.h[6]
	WORD $0xfc4582f8 // ldur d24, [x23, #88]
	WORD $0x2f08a718 // ushll v24.8h, v24.8b, #0
	WORD $0x0f5a2310 // smlal v16.4s, v24.4h, v10.h[1]
	WORD $0x4f5a2311 // smlal2 v17.4s, v24.8h, v10.h[1]
	WORD $0x0f7a2312 // smlal v18.4s, v24.4h, v10.h[3]
	WORD $0x4f7a2313 // smlal2 v19.4s, v24.8h, v10.h[3]
	WORD $0x0f5a2b14 // smlal v20.4s, v24.4h, v10.h[5]
	WORD $0x4f5a2b15 // smlal2 v21.4s, v24.8h, v10.h[5]
	WORD $0x0f7a2b16 // smlal v22.4s, v24.4h, v10.h[7]
	WORD $0x4f7a2b17 // smlal2 v23.4s, v24.8h, v10.h[7]
	WORD $0xfc4682f8 // ldur d24, [x23, #104]
	WORD $0x2f08a718 // ushll v24.8h, v24.8b, #0
	WORD $0x0f4b2310 // smlal v16.4s, v24.4h, v11.h[0]
	WORD $0x4f4b2311 // smlal2 v17.4s, v24.8h, v11.h[0]
	WORD $0x0f6b2312 // smlal v18.4s, v24.4h, v11.h[2]
	WORD $0x4f6b2313 // smlal2 v19.4s, v24.8h, v11.h[2]
	WORD $0x0f4b2b14 // smlal v20.4s, v24.4h, v11.h[4]
	WORD $0x4f4b2b15 // smlal2 v21.4s, v24.8h, v11.h[4]
	WORD $0x0f6b2b16 // smlal v22.4s, v24.4h, v11.h[6]
	WORD $0x4f6b2b17 // smlal2 v23.4s, v24.8h, v11.h[6]
	WORD $0xfc4782f8 // ldur d24, [x23, #120]
	WORD $0x2f08a718 // ushll v24.8h, v24.8b, #0
	WORD $0x0f5b2310 // smlal v16.4s, v24.4h, v11.h[1]
	WORD $0x4f5b2311 // smlal2 v17.4s, v24.8h, v11.h[1]
	WORD $0x0f7b2312 // smlal v18.4s, v24.4h, v11.h[3]
	WORD $0x4f7b2313 // smlal2 v19.4s, v24.8h, v11.h[3]
	WORD $0x0f5b2b14 // smlal v20.4s, v24.4h, v11.h[5]
	WORD $0x4f5b2b15 // smlal2 v21.4s, v24.8h, v11.h[5]
	WORD $0x0f7b2b16 // smlal v22.4s, v24.4h, v11.h[7]
	WORD $0x4f7b2b17 // smlal2 v23.4s, v24.8h, v11.h[7]
	WORD $0xfc40013c // ldur d28, [x9, #0]
	WORD $0x0e217b9c // fcvtl v28.4s, v28.4h
	WORD $0xfc40813d // ldur d29, [x9, #8]
	WORD $0x0e217bbd // fcvtl v29.4s, v29.4h
	WORD $0xfc41013e // ldur d30, [x9, #16]
	WORD $0x0e217bde // fcvtl v30.4s, v30.4h
	WORD $0xfc41813f // ldur d31, [x9, #24]
	WORD $0x0e217bff // fcvtl v31.4s, v31.4h
	WORD $0xbc400159 // ldur s25, [x10, #0]
	WORD $0x4e81180c // uzp1 v12.4s, v0.4s, v1.4s
	WORD $0x4e21d98c // scvtf v12.4s, v12.4s
	WORD $0x4e21da0d // scvtf v13.4s, v16.4s
	WORD $0x4f99938e // fmul v14.4s, v28.4s, v25.s[0]
	WORD $0x4f9993cf // fmul v15.4s, v30.4s, v25.s[0]
	WORD $0x3cc802f8 // ldur q24, [x23, #128]
	WORD $0x4e2ecd98 // fmla v24.4s, v12.4s, v14.4s
	WORD $0x4eafcdb8 // fmls v24.4s, v13.4s, v15.4s
	WORD $0x3c8802f8 // stur q24, [x23, #128]
	WORD $0x4e83184c // uzp1 v12.4s, v2.4s, v3.4s
	WORD $0x4e21d98c // scvtf v12.4s, v12.4s
	WORD $0x4e21da2d // scvtf v13.4s, v17.4s
	WORD $0x4f9993ae // fmul v14.4s, v29.4s, v25.s[0]
	WORD $0x4f9993ef // fmul v15.4s, v31.4s, v25.s[0]
	WORD $0x3cc902f8 // ldur q24, [x23, #144]
	WORD $0x4e2ecd98 // fmla v24.4s, v12.4s, v14.4s
	WORD $0x4eafcdb8 // fmls v24.4s, v13.4s, v15.4s
	WORD $0x3c8902f8 // stur q24, [x23, #144]
	WORD $0xbc404159 // ldur s25, [x10, #4]
	WORD $0x4e81580c // uzp2 v12.4s, v0.4s, v1.4s
	WORD $0x4e21d98c // scvtf v12.4s, v12.4s
	WORD $0x4e21da4d // scvtf v13.4s, v18.4s
	WORD $0x4f99938e // fmul v14.4s, v28.4s, v25.s[0]
	WORD $0x4f9993cf // fmul v15.4s, v30.4s, v25.s[0]
	WORD $0x3cca02f8 // ldur q24, [x23, #160]
	WORD $0x4e2ecd98 // fmla v24.4s, v12.4s, v14.4s
	WORD $0x4eafcdb8 // fmls v24.4s, v13.4s, v15.4s
	WORD $0x3c8a02f8 // stur q24, [x23, #160]
	WORD $0x4e83584c // uzp2 v12.4s, v2.4s, v3.4s
	WORD $0x4e21d98c // scvtf v12.4s, v12.4s
	WORD $0x4e21da6d // scvtf v13.4s, v19.4s
	WORD $0x4f9993ae // fmul v14.4s, v29.4s, v25.s[0]
	WORD $0x4f9993ef // fmul v15.4s, v31.4s, v25.s[0]
	WORD $0x3ccb02f8 // ldur q24, [x23, #176]
	WORD $0x4e2ecd98 // fmla v24.4s, v12.4s, v14.4s
	WORD $0x4eafcdb8 // fmls v24.4s, v13.4s, v15.4s
	WORD $0x3c8b02f8 // stur q24, [x23, #176]
	WORD $0xbc408159 // ldur s25, [x10, #8]
	WORD $0x4e85188c // uzp1 v12.4s, v4.4s, v5.4s
	WORD $0x4e21d98c // scvtf v12.4s, v12.4s
	WORD $0x4e21da8d // scvtf v13.4s, v20.4s
	WORD $0x4f99938e // fmul v14.4s, v28.4s, v25.s[0]
	WORD $0x4f9993cf // fmul v15.4s, v30.4s, v25.s[0]
	WORD $0x3ccc02f8 // ldur q24, [x23, #192]
	WORD $0x4e2ecd98 // fmla v24.4s, v12.4s, v14.4s
	WORD $0x4eafcdb8 // fmls v24.4s, v13.4s, v15.4s
	WORD $0x3c8c02f8 // stur q24, [x23, #192]
	WORD $0x4e8718cc // uzp1 v12.4s, v6.4s, v7.4s
	WORD $0x4e21d98c // scvtf v12.4s, v12.4s
	WORD $0x4e21daad // scvtf v13.4s, v21.4s
	WORD $0x4f9993ae // fmul v14.4s, v29.4s, v25.s[0]
	WORD $0x4f9993ef // fmul v15.4s, v31.4s, v25.s[0]
	WORD $0x3ccd02f8 // ldur q24, [x23, #208]
	WORD $0x4e2ecd98 // fmla v24.4s, v12.4s, v14.4s
	WORD $0x4eafcdb8 // fmls v24.4s, v13.4s, v15.4s
	WORD $0x3c8d02f8 // stur q24, [x23, #208]
	WORD $0xbc40c159 // ldur s25, [x10, #12]
	WORD $0x4e85588c // uzp2 v12.4s, v4.4s, v5.4s
	WORD $0x4e21d98c // scvtf v12.4s, v12.4s
	WORD $0x4e21dacd // scvtf v13.4s, v22.4s
	WORD $0x4f99938e // fmul v14.4s, v28.4s, v25.s[0]
	WORD $0x4f9993cf // fmul v15.4s, v30.4s, v25.s[0]
	WORD $0x3cce02f8 // ldur q24, [x23, #224]
	WORD $0x4e2ecd98 // fmla v24.4s, v12.4s, v14.4s
	WORD $0x4eafcdb8 // fmls v24.4s, v13.4s, v15.4s
	WORD $0x3c8e02f8 // stur q24, [x23, #224]
	WORD $0x4e8758cc // uzp2 v12.4s, v6.4s, v7.4s
	WORD $0x4e21d98c // scvtf v12.4s, v12.4s
	WORD $0x4e21daed // scvtf v13.4s, v23.4s
	WORD $0x4f9993ae // fmul v14.4s, v29.4s, v25.s[0]
	WORD $0x4f9993ef // fmul v15.4s, v31.4s, v25.s[0]
	WORD $0x3ccf02f8 // ldur q24, [x23, #240]
	WORD $0x4e2ecd98 // fmla v24.4s, v12.4s, v14.4s
	WORD $0x4eafcdb8 // fmls v24.4s, v13.4s, v15.4s
	WORD $0x3c8f02f8 // stur q24, [x23, #240]
	WORD $0x4f00e5ff // movi v31.16b, #15
	ADD	$1408, R9, R9
	ADD	$1168, R10, R10
	SUBW	$1, R11, R11
	CBNZW	R11, gm5blk
gm5store:
	MOVD	R24, R12
	WORD $0x3cc802f0 // ldur q16, [x23, #128]
	WORD $0x3cc902f1 // ldur q17, [x23, #144]
	WORD $0x3c800190 // stur q16, [x12, #0]
	WORD $0x3c810191 // stur q17, [x12, #16]
	ADD	R12, R5, R12
	WORD $0x3cca02f0 // ldur q16, [x23, #160]
	WORD $0x3ccb02f1 // ldur q17, [x23, #176]
	WORD $0x3c800190 // stur q16, [x12, #0]
	WORD $0x3c810191 // stur q17, [x12, #16]
	ADD	R12, R5, R12
	WORD $0x3ccc02f0 // ldur q16, [x23, #192]
	WORD $0x3ccd02f1 // ldur q17, [x23, #208]
	WORD $0x3c800190 // stur q16, [x12, #0]
	WORD $0x3c810191 // stur q17, [x12, #16]
	ADD	R12, R5, R12
	WORD $0x3cce02f0 // ldur q16, [x23, #224]
	WORD $0x3ccf02f1 // ldur q17, [x23, #240]
	WORD $0x3c800190 // stur q16, [x12, #0]
	WORD $0x3c810191 // stur q17, [x12, #16]
	ADD	$32, R24, R24
	ADD	R0, R6, R0
	SUBW	$1, R25, R25
	CBNZW	R25, gm5cols
	MOVD	$1168, R26
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
