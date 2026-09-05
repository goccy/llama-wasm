// dbg_gemv_q5_K_8x8: q5_K 8x8 repack GEMV, SDOT over broadcast activation quads.
	MOVW	l0+8(FP), R1
	LSRW	$8, R1, R1
	MOVWU	l6+52(FP), R7
	LSRW	$3, R7, R7
	CBZW	R7, gk5done
	MOVD	l1+16(FP), R2
	LSL	$5, R7, R26
	ADD	R2, R26, R26
	CMP	R26, R21
	BLO	gk5oob
	MOVD	l3+32(FP), R3
	MOVD	$1408, R6
	MUL	R1, R6, R6
	MUL	R7, R6, R26
	ADD	R3, R26, R26
	CMP	R26, R21
	BLO	gk5oob
	MOVD	l4+40(FP), R4
	MOVD	$292, R26
	MUL	R1, R26, R26
	ADD	R4, R26, R26
	CMP	R26, R21
	BLO	gk5oob
	ADD	R20, R2, R2
	ADD	R20, R3, R3
	ADD	R20, R4, R4
	WORD $0x4f00e5ff // movi v31.16b, #15
gk5group:
	WORD $0x4f000400 // movi v0.4s, #0
	WORD $0x4f000401 // movi v1.4s, #0
	MOVD	R3, R9
	MOVD	R4, R10
	MOVW	R1, R8
	CBZW	R8, gk5store
gk5blk:
	WORD $0x4f000402 // movi v2.4s, #0
	WORD $0x4f000403 // movi v3.4s, #0
	WORD $0x4f00041e // movi v30.4s, #0
	WORD $0x4f000407 // movi v7.4s, #0
	ADD	$256, R10, R11
	WORD $0x3cc04178 // ldur q24, [x11, #4]
	WORD $0x3cc14179 // ldur q25, [x11, #20]
	WORD $0x4e79bf06 // addp v6.8h, v24.8h, v25.8h
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
	WORD $0x9e670264 // fmov d4, x19
	ANDW	$0x3f3f3f3f, R13, R19
	ANDW	$0x0f0f0f0f, R15, R22
	LSRW	$6, R13, R14
	ANDW	$0x03030303, R14, R14
	ORRW	R14<<4, R22, R22
	ORR	R22<<32, R19, R19
	WORD $0x9e67026c // fmov d12, x19
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
	WORD $0x9e670265 // fmov d5, x19
	ANDW	$0x3f3f3f3f, R13, R19
	ANDW	$0x0f0f0f0f, R15, R22
	LSRW	$6, R13, R14
	ANDW	$0x03030303, R14, R14
	ORRW	R14<<4, R22, R22
	ORR	R22<<32, R19, R19
	WORD $0x9e67026d // fmov d13, x19
	WORD $0x2f08a484 // ushll v4.8h, v4.8b, #0
	WORD $0x2f08a4a5 // ushll v5.8h, v5.8b, #0
	WORD $0x2f08a58c // ushll v12.8h, v12.8b, #0
	WORD $0x2f08a5ad // ushll v13.8h, v13.8b, #0
	WORD $0xfc404150 // ldur d16, [x10, #4]
	WORD $0x4e080610 // dup v16.2d, v16.d[0]
	WORD $0xfc40c151 // ldur d17, [x10, #12]
	WORD $0x4e080631 // dup v17.2d, v17.d[0]
	WORD $0xfc414152 // ldur d18, [x10, #20]
	WORD $0x4e080652 // dup v18.2d, v18.d[0]
	WORD $0xfc41c153 // ldur d19, [x10, #28]
	WORD $0x4e080673 // dup v19.2d, v19.d[0]
	WORD $0xfc424154 // ldur d20, [x10, #36]
	WORD $0x4e080694 // dup v20.2d, v20.d[0]
	WORD $0xfc42c155 // ldur d21, [x10, #44]
	WORD $0x4e0806b5 // dup v21.2d, v21.d[0]
	WORD $0xfc434156 // ldur d22, [x10, #52]
	WORD $0x4e0806d6 // dup v22.2d, v22.d[0]
	WORD $0xfc43c157 // ldur d23, [x10, #60]
	WORD $0x4e0806f7 // dup v23.2d, v23.d[0]
	ADD	$384, R9, R12
	ADD	$128, R9, R13
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x4f00e42e // movi v14.16b, #1
	WORD $0x4f00e44f // movi v15.16b, #2
	WORD $0x3cc00198 // ldur q24, [x12, #0]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc001bb // ldur q27, [x13, #0]
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e909728 // sdot v8.4s, v25.16b, v16.16b
	WORD $0x4e94974a // sdot v10.4s, v26.16b, v20.16b
	WORD $0x3cc40198 // ldur q24, [x12, #64]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc401bb // ldur q27, [x13, #64]
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e919728 // sdot v8.4s, v25.16b, v17.16b
	WORD $0x4e95974a // sdot v10.4s, v26.16b, v21.16b
	WORD $0x3cc80198 // ldur q24, [x12, #128]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc801bb // ldur q27, [x13, #128]
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e929728 // sdot v8.4s, v25.16b, v18.16b
	WORD $0x4e96974a // sdot v10.4s, v26.16b, v22.16b
	WORD $0x3ccc0198 // ldur q24, [x12, #192]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3ccc01bb // ldur q27, [x13, #192]
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e939728 // sdot v8.4s, v25.16b, v19.16b
	WORD $0x4e97974a // sdot v10.4s, v26.16b, v23.16b
	WORD $0x3cc10198 // ldur q24, [x12, #16]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc101bb // ldur q27, [x13, #16]
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e909729 // sdot v9.4s, v25.16b, v16.16b
	WORD $0x4e94974b // sdot v11.4s, v26.16b, v20.16b
	WORD $0x3cc50198 // ldur q24, [x12, #80]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc501bb // ldur q27, [x13, #80]
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e919729 // sdot v9.4s, v25.16b, v17.16b
	WORD $0x4e95974b // sdot v11.4s, v26.16b, v21.16b
	WORD $0x3cc90198 // ldur q24, [x12, #144]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc901bb // ldur q27, [x13, #144]
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e929729 // sdot v9.4s, v25.16b, v18.16b
	WORD $0x4e96974b // sdot v11.4s, v26.16b, v22.16b
	WORD $0x3ccd0198 // ldur q24, [x12, #208]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3ccd01bb // ldur q27, [x13, #208]
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e939729 // sdot v9.4s, v25.16b, v19.16b
	WORD $0x4e97974b // sdot v11.4s, v26.16b, v23.16b
	WORD $0x4ea9bd0e // addp v14.4s, v8.4s, v9.4s
	WORD $0x2f10a58f // ushll v15.4s, v12.4h, #0
	WORD $0x4eaf95c2 // mla v2.4s, v14.4s, v15.4s
	WORD $0x4eabbd4e // addp v14.4s, v10.4s, v11.4s
	WORD $0x2f10a5af // ushll v15.4s, v13.4h, #0
	WORD $0x4eaf95c2 // mla v2.4s, v14.4s, v15.4s
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x4f00e42e // movi v14.16b, #1
	WORD $0x4f00e44f // movi v15.16b, #2
	WORD $0x3cc20198 // ldur q24, [x12, #32]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc201bb // ldur q27, [x13, #32]
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e909728 // sdot v8.4s, v25.16b, v16.16b
	WORD $0x4e94974a // sdot v10.4s, v26.16b, v20.16b
	WORD $0x3cc60198 // ldur q24, [x12, #96]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc601bb // ldur q27, [x13, #96]
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e919728 // sdot v8.4s, v25.16b, v17.16b
	WORD $0x4e95974a // sdot v10.4s, v26.16b, v21.16b
	WORD $0x3cca0198 // ldur q24, [x12, #160]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cca01bb // ldur q27, [x13, #160]
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e929728 // sdot v8.4s, v25.16b, v18.16b
	WORD $0x4e96974a // sdot v10.4s, v26.16b, v22.16b
	WORD $0x3cce0198 // ldur q24, [x12, #224]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cce01bb // ldur q27, [x13, #224]
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e939728 // sdot v8.4s, v25.16b, v19.16b
	WORD $0x4e97974a // sdot v10.4s, v26.16b, v23.16b
	WORD $0x3cc30198 // ldur q24, [x12, #48]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc301bb // ldur q27, [x13, #48]
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e909729 // sdot v9.4s, v25.16b, v16.16b
	WORD $0x4e94974b // sdot v11.4s, v26.16b, v20.16b
	WORD $0x3cc70198 // ldur q24, [x12, #112]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc701bb // ldur q27, [x13, #112]
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e919729 // sdot v9.4s, v25.16b, v17.16b
	WORD $0x4e95974b // sdot v11.4s, v26.16b, v21.16b
	WORD $0x3ccb0198 // ldur q24, [x12, #176]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3ccb01bb // ldur q27, [x13, #176]
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e929729 // sdot v9.4s, v25.16b, v18.16b
	WORD $0x4e96974b // sdot v11.4s, v26.16b, v22.16b
	WORD $0x3ccf0198 // ldur q24, [x12, #240]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3ccf01bb // ldur q27, [x13, #240]
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e939729 // sdot v9.4s, v25.16b, v19.16b
	WORD $0x4e97974b // sdot v11.4s, v26.16b, v23.16b
	WORD $0x4ea9bd0e // addp v14.4s, v8.4s, v9.4s
	WORD $0x6f10a58f // ushll2 v15.4s, v12.8h, #0
	WORD $0x4eaf95c3 // mla v3.4s, v14.4s, v15.4s
	WORD $0x4eabbd4e // addp v14.4s, v10.4s, v11.4s
	WORD $0x6f10a5af // ushll2 v15.4s, v13.8h, #0
	WORD $0x4eaf95c3 // mla v3.4s, v14.4s, v15.4s
	WORD $0x0f46209e // smlal v30.4s, v4.4h, v6.h[0]
	WORD $0x0f5620be // smlal v30.4s, v5.4h, v6.h[1]
	WORD $0x4f462087 // smlal2 v7.4s, v4.8h, v6.h[0]
	WORD $0x4f5620a7 // smlal2 v7.4s, v5.8h, v6.h[1]
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
	WORD $0x9e670264 // fmov d4, x19
	ANDW	$0x3f3f3f3f, R13, R19
	ANDW	$0x0f0f0f0f, R15, R22
	LSRW	$6, R13, R14
	ANDW	$0x03030303, R14, R14
	ORRW	R14<<4, R22, R22
	ORR	R22<<32, R19, R19
	WORD $0x9e67026c // fmov d12, x19
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
	WORD $0x9e670265 // fmov d5, x19
	ANDW	$0x3f3f3f3f, R13, R19
	ANDW	$0x0f0f0f0f, R15, R22
	LSRW	$6, R13, R14
	ANDW	$0x03030303, R14, R14
	ORRW	R14<<4, R22, R22
	ORR	R22<<32, R19, R19
	WORD $0x9e67026d // fmov d13, x19
	WORD $0x2f08a484 // ushll v4.8h, v4.8b, #0
	WORD $0x2f08a4a5 // ushll v5.8h, v5.8b, #0
	WORD $0x2f08a58c // ushll v12.8h, v12.8b, #0
	WORD $0x2f08a5ad // ushll v13.8h, v13.8b, #0
	WORD $0xfc444150 // ldur d16, [x10, #68]
	WORD $0x4e080610 // dup v16.2d, v16.d[0]
	WORD $0xfc44c151 // ldur d17, [x10, #76]
	WORD $0x4e080631 // dup v17.2d, v17.d[0]
	WORD $0xfc454152 // ldur d18, [x10, #84]
	WORD $0x4e080652 // dup v18.2d, v18.d[0]
	WORD $0xfc45c153 // ldur d19, [x10, #92]
	WORD $0x4e080673 // dup v19.2d, v19.d[0]
	WORD $0xfc464154 // ldur d20, [x10, #100]
	WORD $0x4e080694 // dup v20.2d, v20.d[0]
	WORD $0xfc46c155 // ldur d21, [x10, #108]
	WORD $0x4e0806b5 // dup v21.2d, v21.d[0]
	WORD $0xfc474156 // ldur d22, [x10, #116]
	WORD $0x4e0806d6 // dup v22.2d, v22.d[0]
	WORD $0xfc47c157 // ldur d23, [x10, #124]
	WORD $0x4e0806f7 // dup v23.2d, v23.d[0]
	ADD	$640, R9, R12
	ADD	$128, R9, R13
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x4f00e42e // movi v14.16b, #1
	WORD $0x4f00e44f // movi v15.16b, #2
	WORD $0x3cc00198 // ldur q24, [x12, #0]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc001bb // ldur q27, [x13, #0]
	WORD $0x6f0e077b // ushr v27.16b, v27.16b, #2
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e909728 // sdot v8.4s, v25.16b, v16.16b
	WORD $0x4e94974a // sdot v10.4s, v26.16b, v20.16b
	WORD $0x3cc40198 // ldur q24, [x12, #64]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc401bb // ldur q27, [x13, #64]
	WORD $0x6f0e077b // ushr v27.16b, v27.16b, #2
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e919728 // sdot v8.4s, v25.16b, v17.16b
	WORD $0x4e95974a // sdot v10.4s, v26.16b, v21.16b
	WORD $0x3cc80198 // ldur q24, [x12, #128]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc801bb // ldur q27, [x13, #128]
	WORD $0x6f0e077b // ushr v27.16b, v27.16b, #2
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e929728 // sdot v8.4s, v25.16b, v18.16b
	WORD $0x4e96974a // sdot v10.4s, v26.16b, v22.16b
	WORD $0x3ccc0198 // ldur q24, [x12, #192]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3ccc01bb // ldur q27, [x13, #192]
	WORD $0x6f0e077b // ushr v27.16b, v27.16b, #2
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e939728 // sdot v8.4s, v25.16b, v19.16b
	WORD $0x4e97974a // sdot v10.4s, v26.16b, v23.16b
	WORD $0x3cc10198 // ldur q24, [x12, #16]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc101bb // ldur q27, [x13, #16]
	WORD $0x6f0e077b // ushr v27.16b, v27.16b, #2
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e909729 // sdot v9.4s, v25.16b, v16.16b
	WORD $0x4e94974b // sdot v11.4s, v26.16b, v20.16b
	WORD $0x3cc50198 // ldur q24, [x12, #80]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc501bb // ldur q27, [x13, #80]
	WORD $0x6f0e077b // ushr v27.16b, v27.16b, #2
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e919729 // sdot v9.4s, v25.16b, v17.16b
	WORD $0x4e95974b // sdot v11.4s, v26.16b, v21.16b
	WORD $0x3cc90198 // ldur q24, [x12, #144]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc901bb // ldur q27, [x13, #144]
	WORD $0x6f0e077b // ushr v27.16b, v27.16b, #2
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e929729 // sdot v9.4s, v25.16b, v18.16b
	WORD $0x4e96974b // sdot v11.4s, v26.16b, v22.16b
	WORD $0x3ccd0198 // ldur q24, [x12, #208]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3ccd01bb // ldur q27, [x13, #208]
	WORD $0x6f0e077b // ushr v27.16b, v27.16b, #2
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e939729 // sdot v9.4s, v25.16b, v19.16b
	WORD $0x4e97974b // sdot v11.4s, v26.16b, v23.16b
	WORD $0x4ea9bd0e // addp v14.4s, v8.4s, v9.4s
	WORD $0x2f10a58f // ushll v15.4s, v12.4h, #0
	WORD $0x4eaf95c2 // mla v2.4s, v14.4s, v15.4s
	WORD $0x4eabbd4e // addp v14.4s, v10.4s, v11.4s
	WORD $0x2f10a5af // ushll v15.4s, v13.4h, #0
	WORD $0x4eaf95c2 // mla v2.4s, v14.4s, v15.4s
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x4f00e42e // movi v14.16b, #1
	WORD $0x4f00e44f // movi v15.16b, #2
	WORD $0x3cc20198 // ldur q24, [x12, #32]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc201bb // ldur q27, [x13, #32]
	WORD $0x6f0e077b // ushr v27.16b, v27.16b, #2
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e909728 // sdot v8.4s, v25.16b, v16.16b
	WORD $0x4e94974a // sdot v10.4s, v26.16b, v20.16b
	WORD $0x3cc60198 // ldur q24, [x12, #96]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc601bb // ldur q27, [x13, #96]
	WORD $0x6f0e077b // ushr v27.16b, v27.16b, #2
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e919728 // sdot v8.4s, v25.16b, v17.16b
	WORD $0x4e95974a // sdot v10.4s, v26.16b, v21.16b
	WORD $0x3cca0198 // ldur q24, [x12, #160]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cca01bb // ldur q27, [x13, #160]
	WORD $0x6f0e077b // ushr v27.16b, v27.16b, #2
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e929728 // sdot v8.4s, v25.16b, v18.16b
	WORD $0x4e96974a // sdot v10.4s, v26.16b, v22.16b
	WORD $0x3cce0198 // ldur q24, [x12, #224]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cce01bb // ldur q27, [x13, #224]
	WORD $0x6f0e077b // ushr v27.16b, v27.16b, #2
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e939728 // sdot v8.4s, v25.16b, v19.16b
	WORD $0x4e97974a // sdot v10.4s, v26.16b, v23.16b
	WORD $0x3cc30198 // ldur q24, [x12, #48]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc301bb // ldur q27, [x13, #48]
	WORD $0x6f0e077b // ushr v27.16b, v27.16b, #2
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e909729 // sdot v9.4s, v25.16b, v16.16b
	WORD $0x4e94974b // sdot v11.4s, v26.16b, v20.16b
	WORD $0x3cc70198 // ldur q24, [x12, #112]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc701bb // ldur q27, [x13, #112]
	WORD $0x6f0e077b // ushr v27.16b, v27.16b, #2
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e919729 // sdot v9.4s, v25.16b, v17.16b
	WORD $0x4e95974b // sdot v11.4s, v26.16b, v21.16b
	WORD $0x3ccb0198 // ldur q24, [x12, #176]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3ccb01bb // ldur q27, [x13, #176]
	WORD $0x6f0e077b // ushr v27.16b, v27.16b, #2
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e929729 // sdot v9.4s, v25.16b, v18.16b
	WORD $0x4e96974b // sdot v11.4s, v26.16b, v22.16b
	WORD $0x3ccf0198 // ldur q24, [x12, #240]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3ccf01bb // ldur q27, [x13, #240]
	WORD $0x6f0e077b // ushr v27.16b, v27.16b, #2
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e939729 // sdot v9.4s, v25.16b, v19.16b
	WORD $0x4e97974b // sdot v11.4s, v26.16b, v23.16b
	WORD $0x4ea9bd0e // addp v14.4s, v8.4s, v9.4s
	WORD $0x6f10a58f // ushll2 v15.4s, v12.8h, #0
	WORD $0x4eaf95c3 // mla v3.4s, v14.4s, v15.4s
	WORD $0x4eabbd4e // addp v14.4s, v10.4s, v11.4s
	WORD $0x6f10a5af // ushll2 v15.4s, v13.8h, #0
	WORD $0x4eaf95c3 // mla v3.4s, v14.4s, v15.4s
	WORD $0x0f66209e // smlal v30.4s, v4.4h, v6.h[2]
	WORD $0x0f7620be // smlal v30.4s, v5.4h, v6.h[3]
	WORD $0x4f662087 // smlal2 v7.4s, v4.8h, v6.h[2]
	WORD $0x4f7620a7 // smlal2 v7.4s, v5.8h, v6.h[3]
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
	WORD $0x9e670264 // fmov d4, x19
	ANDW	$0x3f3f3f3f, R13, R19
	ANDW	$0x0f0f0f0f, R15, R22
	LSRW	$6, R13, R14
	ANDW	$0x03030303, R14, R14
	ORRW	R14<<4, R22, R22
	ORR	R22<<32, R19, R19
	WORD $0x9e67026c // fmov d12, x19
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
	WORD $0x9e670265 // fmov d5, x19
	ANDW	$0x3f3f3f3f, R13, R19
	ANDW	$0x0f0f0f0f, R15, R22
	LSRW	$6, R13, R14
	ANDW	$0x03030303, R14, R14
	ORRW	R14<<4, R22, R22
	ORR	R22<<32, R19, R19
	WORD $0x9e67026d // fmov d13, x19
	WORD $0x2f08a484 // ushll v4.8h, v4.8b, #0
	WORD $0x2f08a4a5 // ushll v5.8h, v5.8b, #0
	WORD $0x2f08a58c // ushll v12.8h, v12.8b, #0
	WORD $0x2f08a5ad // ushll v13.8h, v13.8b, #0
	WORD $0xfc484150 // ldur d16, [x10, #132]
	WORD $0x4e080610 // dup v16.2d, v16.d[0]
	WORD $0xfc48c151 // ldur d17, [x10, #140]
	WORD $0x4e080631 // dup v17.2d, v17.d[0]
	WORD $0xfc494152 // ldur d18, [x10, #148]
	WORD $0x4e080652 // dup v18.2d, v18.d[0]
	WORD $0xfc49c153 // ldur d19, [x10, #156]
	WORD $0x4e080673 // dup v19.2d, v19.d[0]
	WORD $0xfc4a4154 // ldur d20, [x10, #164]
	WORD $0x4e080694 // dup v20.2d, v20.d[0]
	WORD $0xfc4ac155 // ldur d21, [x10, #172]
	WORD $0x4e0806b5 // dup v21.2d, v21.d[0]
	WORD $0xfc4b4156 // ldur d22, [x10, #180]
	WORD $0x4e0806d6 // dup v22.2d, v22.d[0]
	WORD $0xfc4bc157 // ldur d23, [x10, #188]
	WORD $0x4e0806f7 // dup v23.2d, v23.d[0]
	ADD	$896, R9, R12
	ADD	$128, R9, R13
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x4f00e42e // movi v14.16b, #1
	WORD $0x4f00e44f // movi v15.16b, #2
	WORD $0x3cc00198 // ldur q24, [x12, #0]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc001bb // ldur q27, [x13, #0]
	WORD $0x6f0c077b // ushr v27.16b, v27.16b, #4
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e909728 // sdot v8.4s, v25.16b, v16.16b
	WORD $0x4e94974a // sdot v10.4s, v26.16b, v20.16b
	WORD $0x3cc40198 // ldur q24, [x12, #64]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc401bb // ldur q27, [x13, #64]
	WORD $0x6f0c077b // ushr v27.16b, v27.16b, #4
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e919728 // sdot v8.4s, v25.16b, v17.16b
	WORD $0x4e95974a // sdot v10.4s, v26.16b, v21.16b
	WORD $0x3cc80198 // ldur q24, [x12, #128]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc801bb // ldur q27, [x13, #128]
	WORD $0x6f0c077b // ushr v27.16b, v27.16b, #4
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e929728 // sdot v8.4s, v25.16b, v18.16b
	WORD $0x4e96974a // sdot v10.4s, v26.16b, v22.16b
	WORD $0x3ccc0198 // ldur q24, [x12, #192]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3ccc01bb // ldur q27, [x13, #192]
	WORD $0x6f0c077b // ushr v27.16b, v27.16b, #4
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e939728 // sdot v8.4s, v25.16b, v19.16b
	WORD $0x4e97974a // sdot v10.4s, v26.16b, v23.16b
	WORD $0x3cc10198 // ldur q24, [x12, #16]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc101bb // ldur q27, [x13, #16]
	WORD $0x6f0c077b // ushr v27.16b, v27.16b, #4
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e909729 // sdot v9.4s, v25.16b, v16.16b
	WORD $0x4e94974b // sdot v11.4s, v26.16b, v20.16b
	WORD $0x3cc50198 // ldur q24, [x12, #80]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc501bb // ldur q27, [x13, #80]
	WORD $0x6f0c077b // ushr v27.16b, v27.16b, #4
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e919729 // sdot v9.4s, v25.16b, v17.16b
	WORD $0x4e95974b // sdot v11.4s, v26.16b, v21.16b
	WORD $0x3cc90198 // ldur q24, [x12, #144]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc901bb // ldur q27, [x13, #144]
	WORD $0x6f0c077b // ushr v27.16b, v27.16b, #4
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e929729 // sdot v9.4s, v25.16b, v18.16b
	WORD $0x4e96974b // sdot v11.4s, v26.16b, v22.16b
	WORD $0x3ccd0198 // ldur q24, [x12, #208]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3ccd01bb // ldur q27, [x13, #208]
	WORD $0x6f0c077b // ushr v27.16b, v27.16b, #4
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e939729 // sdot v9.4s, v25.16b, v19.16b
	WORD $0x4e97974b // sdot v11.4s, v26.16b, v23.16b
	WORD $0x4ea9bd0e // addp v14.4s, v8.4s, v9.4s
	WORD $0x2f10a58f // ushll v15.4s, v12.4h, #0
	WORD $0x4eaf95c2 // mla v2.4s, v14.4s, v15.4s
	WORD $0x4eabbd4e // addp v14.4s, v10.4s, v11.4s
	WORD $0x2f10a5af // ushll v15.4s, v13.4h, #0
	WORD $0x4eaf95c2 // mla v2.4s, v14.4s, v15.4s
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x4f00e42e // movi v14.16b, #1
	WORD $0x4f00e44f // movi v15.16b, #2
	WORD $0x3cc20198 // ldur q24, [x12, #32]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc201bb // ldur q27, [x13, #32]
	WORD $0x6f0c077b // ushr v27.16b, v27.16b, #4
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e909728 // sdot v8.4s, v25.16b, v16.16b
	WORD $0x4e94974a // sdot v10.4s, v26.16b, v20.16b
	WORD $0x3cc60198 // ldur q24, [x12, #96]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc601bb // ldur q27, [x13, #96]
	WORD $0x6f0c077b // ushr v27.16b, v27.16b, #4
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e919728 // sdot v8.4s, v25.16b, v17.16b
	WORD $0x4e95974a // sdot v10.4s, v26.16b, v21.16b
	WORD $0x3cca0198 // ldur q24, [x12, #160]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cca01bb // ldur q27, [x13, #160]
	WORD $0x6f0c077b // ushr v27.16b, v27.16b, #4
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e929728 // sdot v8.4s, v25.16b, v18.16b
	WORD $0x4e96974a // sdot v10.4s, v26.16b, v22.16b
	WORD $0x3cce0198 // ldur q24, [x12, #224]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cce01bb // ldur q27, [x13, #224]
	WORD $0x6f0c077b // ushr v27.16b, v27.16b, #4
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e939728 // sdot v8.4s, v25.16b, v19.16b
	WORD $0x4e97974a // sdot v10.4s, v26.16b, v23.16b
	WORD $0x3cc30198 // ldur q24, [x12, #48]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc301bb // ldur q27, [x13, #48]
	WORD $0x6f0c077b // ushr v27.16b, v27.16b, #4
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e909729 // sdot v9.4s, v25.16b, v16.16b
	WORD $0x4e94974b // sdot v11.4s, v26.16b, v20.16b
	WORD $0x3cc70198 // ldur q24, [x12, #112]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc701bb // ldur q27, [x13, #112]
	WORD $0x6f0c077b // ushr v27.16b, v27.16b, #4
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e919729 // sdot v9.4s, v25.16b, v17.16b
	WORD $0x4e95974b // sdot v11.4s, v26.16b, v21.16b
	WORD $0x3ccb0198 // ldur q24, [x12, #176]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3ccb01bb // ldur q27, [x13, #176]
	WORD $0x6f0c077b // ushr v27.16b, v27.16b, #4
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e929729 // sdot v9.4s, v25.16b, v18.16b
	WORD $0x4e96974b // sdot v11.4s, v26.16b, v22.16b
	WORD $0x3ccf0198 // ldur q24, [x12, #240]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3ccf01bb // ldur q27, [x13, #240]
	WORD $0x6f0c077b // ushr v27.16b, v27.16b, #4
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e939729 // sdot v9.4s, v25.16b, v19.16b
	WORD $0x4e97974b // sdot v11.4s, v26.16b, v23.16b
	WORD $0x4ea9bd0e // addp v14.4s, v8.4s, v9.4s
	WORD $0x6f10a58f // ushll2 v15.4s, v12.8h, #0
	WORD $0x4eaf95c3 // mla v3.4s, v14.4s, v15.4s
	WORD $0x4eabbd4e // addp v14.4s, v10.4s, v11.4s
	WORD $0x6f10a5af // ushll2 v15.4s, v13.8h, #0
	WORD $0x4eaf95c3 // mla v3.4s, v14.4s, v15.4s
	WORD $0x0f46289e // smlal v30.4s, v4.4h, v6.h[4]
	WORD $0x0f5628be // smlal v30.4s, v5.4h, v6.h[5]
	WORD $0x4f462887 // smlal2 v7.4s, v4.8h, v6.h[4]
	WORD $0x4f5628a7 // smlal2 v7.4s, v5.8h, v6.h[5]
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
	WORD $0x9e670264 // fmov d4, x19
	ANDW	$0x3f3f3f3f, R13, R19
	ANDW	$0x0f0f0f0f, R15, R22
	LSRW	$6, R13, R14
	ANDW	$0x03030303, R14, R14
	ORRW	R14<<4, R22, R22
	ORR	R22<<32, R19, R19
	WORD $0x9e67026c // fmov d12, x19
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
	WORD $0x9e670265 // fmov d5, x19
	ANDW	$0x3f3f3f3f, R13, R19
	ANDW	$0x0f0f0f0f, R15, R22
	LSRW	$6, R13, R14
	ANDW	$0x03030303, R14, R14
	ORRW	R14<<4, R22, R22
	ORR	R22<<32, R19, R19
	WORD $0x9e67026d // fmov d13, x19
	WORD $0x2f08a484 // ushll v4.8h, v4.8b, #0
	WORD $0x2f08a4a5 // ushll v5.8h, v5.8b, #0
	WORD $0x2f08a58c // ushll v12.8h, v12.8b, #0
	WORD $0x2f08a5ad // ushll v13.8h, v13.8b, #0
	WORD $0xfc4c4150 // ldur d16, [x10, #196]
	WORD $0x4e080610 // dup v16.2d, v16.d[0]
	WORD $0xfc4cc151 // ldur d17, [x10, #204]
	WORD $0x4e080631 // dup v17.2d, v17.d[0]
	WORD $0xfc4d4152 // ldur d18, [x10, #212]
	WORD $0x4e080652 // dup v18.2d, v18.d[0]
	WORD $0xfc4dc153 // ldur d19, [x10, #220]
	WORD $0x4e080673 // dup v19.2d, v19.d[0]
	WORD $0xfc4e4154 // ldur d20, [x10, #228]
	WORD $0x4e080694 // dup v20.2d, v20.d[0]
	WORD $0xfc4ec155 // ldur d21, [x10, #236]
	WORD $0x4e0806b5 // dup v21.2d, v21.d[0]
	WORD $0xfc4f4156 // ldur d22, [x10, #244]
	WORD $0x4e0806d6 // dup v22.2d, v22.d[0]
	WORD $0xfc4fc157 // ldur d23, [x10, #252]
	WORD $0x4e0806f7 // dup v23.2d, v23.d[0]
	ADD	$1152, R9, R12
	ADD	$128, R9, R13
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x4f00e42e // movi v14.16b, #1
	WORD $0x4f00e44f // movi v15.16b, #2
	WORD $0x3cc00198 // ldur q24, [x12, #0]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc001bb // ldur q27, [x13, #0]
	WORD $0x6f0a077b // ushr v27.16b, v27.16b, #6
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e909728 // sdot v8.4s, v25.16b, v16.16b
	WORD $0x4e94974a // sdot v10.4s, v26.16b, v20.16b
	WORD $0x3cc40198 // ldur q24, [x12, #64]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc401bb // ldur q27, [x13, #64]
	WORD $0x6f0a077b // ushr v27.16b, v27.16b, #6
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e919728 // sdot v8.4s, v25.16b, v17.16b
	WORD $0x4e95974a // sdot v10.4s, v26.16b, v21.16b
	WORD $0x3cc80198 // ldur q24, [x12, #128]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc801bb // ldur q27, [x13, #128]
	WORD $0x6f0a077b // ushr v27.16b, v27.16b, #6
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e929728 // sdot v8.4s, v25.16b, v18.16b
	WORD $0x4e96974a // sdot v10.4s, v26.16b, v22.16b
	WORD $0x3ccc0198 // ldur q24, [x12, #192]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3ccc01bb // ldur q27, [x13, #192]
	WORD $0x6f0a077b // ushr v27.16b, v27.16b, #6
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e939728 // sdot v8.4s, v25.16b, v19.16b
	WORD $0x4e97974a // sdot v10.4s, v26.16b, v23.16b
	WORD $0x3cc10198 // ldur q24, [x12, #16]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc101bb // ldur q27, [x13, #16]
	WORD $0x6f0a077b // ushr v27.16b, v27.16b, #6
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e909729 // sdot v9.4s, v25.16b, v16.16b
	WORD $0x4e94974b // sdot v11.4s, v26.16b, v20.16b
	WORD $0x3cc50198 // ldur q24, [x12, #80]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc501bb // ldur q27, [x13, #80]
	WORD $0x6f0a077b // ushr v27.16b, v27.16b, #6
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e919729 // sdot v9.4s, v25.16b, v17.16b
	WORD $0x4e95974b // sdot v11.4s, v26.16b, v21.16b
	WORD $0x3cc90198 // ldur q24, [x12, #144]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc901bb // ldur q27, [x13, #144]
	WORD $0x6f0a077b // ushr v27.16b, v27.16b, #6
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e929729 // sdot v9.4s, v25.16b, v18.16b
	WORD $0x4e96974b // sdot v11.4s, v26.16b, v22.16b
	WORD $0x3ccd0198 // ldur q24, [x12, #208]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3ccd01bb // ldur q27, [x13, #208]
	WORD $0x6f0a077b // ushr v27.16b, v27.16b, #6
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e939729 // sdot v9.4s, v25.16b, v19.16b
	WORD $0x4e97974b // sdot v11.4s, v26.16b, v23.16b
	WORD $0x4ea9bd0e // addp v14.4s, v8.4s, v9.4s
	WORD $0x2f10a58f // ushll v15.4s, v12.4h, #0
	WORD $0x4eaf95c2 // mla v2.4s, v14.4s, v15.4s
	WORD $0x4eabbd4e // addp v14.4s, v10.4s, v11.4s
	WORD $0x2f10a5af // ushll v15.4s, v13.4h, #0
	WORD $0x4eaf95c2 // mla v2.4s, v14.4s, v15.4s
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x4f00e42e // movi v14.16b, #1
	WORD $0x4f00e44f // movi v15.16b, #2
	WORD $0x3cc20198 // ldur q24, [x12, #32]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc201bb // ldur q27, [x13, #32]
	WORD $0x6f0a077b // ushr v27.16b, v27.16b, #6
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e909728 // sdot v8.4s, v25.16b, v16.16b
	WORD $0x4e94974a // sdot v10.4s, v26.16b, v20.16b
	WORD $0x3cc60198 // ldur q24, [x12, #96]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc601bb // ldur q27, [x13, #96]
	WORD $0x6f0a077b // ushr v27.16b, v27.16b, #6
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e919728 // sdot v8.4s, v25.16b, v17.16b
	WORD $0x4e95974a // sdot v10.4s, v26.16b, v21.16b
	WORD $0x3cca0198 // ldur q24, [x12, #160]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cca01bb // ldur q27, [x13, #160]
	WORD $0x6f0a077b // ushr v27.16b, v27.16b, #6
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e929728 // sdot v8.4s, v25.16b, v18.16b
	WORD $0x4e96974a // sdot v10.4s, v26.16b, v22.16b
	WORD $0x3cce0198 // ldur q24, [x12, #224]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cce01bb // ldur q27, [x13, #224]
	WORD $0x6f0a077b // ushr v27.16b, v27.16b, #6
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e939728 // sdot v8.4s, v25.16b, v19.16b
	WORD $0x4e97974a // sdot v10.4s, v26.16b, v23.16b
	WORD $0x3cc30198 // ldur q24, [x12, #48]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc301bb // ldur q27, [x13, #48]
	WORD $0x6f0a077b // ushr v27.16b, v27.16b, #6
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e909729 // sdot v9.4s, v25.16b, v16.16b
	WORD $0x4e94974b // sdot v11.4s, v26.16b, v20.16b
	WORD $0x3cc70198 // ldur q24, [x12, #112]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3cc701bb // ldur q27, [x13, #112]
	WORD $0x6f0a077b // ushr v27.16b, v27.16b, #6
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e919729 // sdot v9.4s, v25.16b, v17.16b
	WORD $0x4e95974b // sdot v11.4s, v26.16b, v21.16b
	WORD $0x3ccb0198 // ldur q24, [x12, #176]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3ccb01bb // ldur q27, [x13, #176]
	WORD $0x6f0a077b // ushr v27.16b, v27.16b, #6
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e929729 // sdot v9.4s, v25.16b, v18.16b
	WORD $0x4e96974b // sdot v11.4s, v26.16b, v22.16b
	WORD $0x3ccf0198 // ldur q24, [x12, #240]
	WORD $0x4e3f1f19 // and v25.16b, v24.16b, v31.16b
	WORD $0x6f0c071a // ushr v26.16b, v24.16b, #4
	WORD $0x3ccf01bb // ldur q27, [x13, #240]
	WORD $0x6f0a077b // ushr v27.16b, v27.16b, #6
	WORD $0x4e2e1f78 // and v24.16b, v27.16b, v14.16b
	WORD $0x4f0c5718 // shl v24.16b, v24.16b, #4
	WORD $0x4eb81f39 // orr v25.16b, v25.16b, v24.16b
	WORD $0x4e2f1f78 // and v24.16b, v27.16b, v15.16b
	WORD $0x4f0b5718 // shl v24.16b, v24.16b, #3
	WORD $0x4eb81f5a // orr v26.16b, v26.16b, v24.16b
	WORD $0x4e939729 // sdot v9.4s, v25.16b, v19.16b
	WORD $0x4e97974b // sdot v11.4s, v26.16b, v23.16b
	WORD $0x4ea9bd0e // addp v14.4s, v8.4s, v9.4s
	WORD $0x6f10a58f // ushll2 v15.4s, v12.8h, #0
	WORD $0x4eaf95c3 // mla v3.4s, v14.4s, v15.4s
	WORD $0x4eabbd4e // addp v14.4s, v10.4s, v11.4s
	WORD $0x6f10a5af // ushll2 v15.4s, v13.8h, #0
	WORD $0x4eaf95c3 // mla v3.4s, v14.4s, v15.4s
	WORD $0x0f66289e // smlal v30.4s, v4.4h, v6.h[6]
	WORD $0x0f7628be // smlal v30.4s, v5.4h, v6.h[7]
	WORD $0x4f662887 // smlal2 v7.4s, v4.8h, v6.h[6]
	WORD $0x4f7628a7 // smlal2 v7.4s, v5.8h, v6.h[7]
	WORD $0xbc400158 // ldur s24, [x10, #0]
	WORD $0xfc400139 // ldur d25, [x9, #0]
	WORD $0x0e217b3c // fcvtl v28.4s, v25.4h
	WORD $0x4f98939c // fmul v28.4s, v28.4s, v24.s[0]
	WORD $0xfc408139 // ldur d25, [x9, #8]
	WORD $0x0e217b3d // fcvtl v29.4s, v25.4h
	WORD $0x4f9893bd // fmul v29.4s, v29.4s, v24.s[0]
	WORD $0x4e21d842 // scvtf v2.4s, v2.4s
	WORD $0x4e21d863 // scvtf v3.4s, v3.4s
	WORD $0x4e3ccc40 // fmla v0.4s, v2.4s, v28.4s
	WORD $0x4e3dcc61 // fmla v1.4s, v3.4s, v29.4s
	WORD $0xfc410139 // ldur d25, [x9, #16]
	WORD $0x0e217b3c // fcvtl v28.4s, v25.4h
	WORD $0x4f98939c // fmul v28.4s, v28.4s, v24.s[0]
	WORD $0xfc418139 // ldur d25, [x9, #24]
	WORD $0x0e217b3d // fcvtl v29.4s, v25.4h
	WORD $0x4f9893bd // fmul v29.4s, v29.4s, v24.s[0]
	WORD $0x4e21dbde // scvtf v30.4s, v30.4s
	WORD $0x4e21d8e7 // scvtf v7.4s, v7.4s
	WORD $0x4ebccfc0 // fmls v0.4s, v30.4s, v28.4s
	WORD $0x4ebdcce1 // fmls v1.4s, v7.4s, v29.4s
	ADD	$1408, R9, R9
	ADD	$292, R10, R10
	SUBW	$1, R8, R8
	CBNZW	R8, gk5blk
gk5store:
	WORD $0x3c800040 // stur q0, [x2, #0]
	WORD $0x3c810041 // stur q1, [x2, #16]
	ADD	$32, R2, R2
	ADD	R3, R6, R3
	SUBW	$1, R7, R7
	CBNZW	R7, gk5group
gk5done:
	RET
gk5oob:
	B	ovr_oob
