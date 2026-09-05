// dbg_gemv_q6_K_8x8: q6_K 8x8 repack GEMV, SDOT over broadcast activation quads.
	MOVW	l0+8(FP), R1
	LSRW	$8, R1, R1
	MOVWU	l6+52(FP), R7
	LSRW	$3, R7, R7
	CBZW	R7, g6done
	MOVD	l1+16(FP), R2
	LSL	$5, R7, R26
	ADD	R2, R26, R26
	CMP	R26, R21
	BLO	g6oob
	MOVD	l3+32(FP), R3
	MOVD	$1680, R6
	MUL	R1, R6, R6
	MUL	R7, R6, R26
	ADD	R3, R26, R26
	CMP	R26, R21
	BLO	g6oob
	MOVD	l4+40(FP), R4
	MOVD	$292, R26
	MUL	R1, R26, R26
	ADD	R4, R26, R26
	CMP	R26, R21
	BLO	g6oob
	ADD	R20, R2, R2
	ADD	R20, R3, R3
	ADD	R20, R4, R4
	WORD $0x4f00e5ff // movi v31.16b, #15
	WORD $0x4f00e47d // movi v29.16b, #3
	WORD $0x4f01e61c // movi v28.16b, #48
g6group:
	WORD $0x4f000400 // movi v0.4s, #0
	WORD $0x4f000401 // movi v1.4s, #0
	MOVD	R3, R9
	MOVD	R4, R10
	MOVW	R1, R8
	CBZW	R8, g6store
g6blk:
	WORD $0xbc400158 // ldur s24, [x10, #0]
	WORD $0xfc400139 // ldur d25, [x9, #0]
	WORD $0x0e217b22 // fcvtl v2.4s, v25.4h
	WORD $0x4f989042 // fmul v2.4s, v2.4s, v24.s[0]
	WORD $0xfc408139 // ldur d25, [x9, #8]
	WORD $0x0e217b23 // fcvtl v3.4s, v25.4h
	WORD $0x4f989063 // fmul v3.4s, v3.4s, v24.s[0]
	ADD	$256, R10, R11
	WORD $0x4f00041e // movi v30.4s, #0
	WORD $0x4f000407 // movi v7.4s, #0
	WORD $0x4f000404 // movi v4.4s, #0
	WORD $0x4f000405 // movi v5.4s, #0
	WORD $0x3cc04166 // ldur q6, [x11, #4]
	WORD $0xfc404150 // ldur d16, [x10, #4]
	WORD $0x4e080610 // dup v16.2d, v16.d[0]
	WORD $0xfc40c151 // ldur d17, [x10, #12]
	WORD $0x4e080631 // dup v17.2d, v17.d[0]
	WORD $0xfc444152 // ldur d18, [x10, #68]
	WORD $0x4e080652 // dup v18.2d, v18.d[0]
	WORD $0xfc44c153 // ldur d19, [x10, #76]
	WORD $0x4e080673 // dup v19.2d, v19.d[0]
	ADD	$144, R9, R12
	ADD	$1168, R9, R13
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4f00040e // movi v14.4s, #0
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x3cc00194 // ldur q20, [x12, #0]
	WORD $0x3cc40195 // ldur q21, [x12, #64]
	WORD $0x3cc001b6 // ldur q22, [x13, #0]
	WORD $0x3cc401b7 // ldur q23, [x13, #64]
	WORD $0x4e3f1e98 // and v24.16b, v20.16b, v31.16b
	WORD $0x4e3d1ed9 // and v25.16b, v22.16b, v29.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91f18 // orr v24.16b, v24.16b, v25.16b
	WORD $0x6f0c0694 // ushr v20.16b, v20.16b, #4
	WORD $0x4e3c1ed6 // and v22.16b, v22.16b, v28.16b
	WORD $0x4eb61e94 // orr v20.16b, v20.16b, v22.16b
	WORD $0x4e909708 // sdot v8.4s, v24.16b, v16.16b
	WORD $0x4e92968c // sdot v12.4s, v20.16b, v18.16b
	WORD $0x4e3f1eb9 // and v25.16b, v21.16b, v31.16b
	WORD $0x4e3d1ef6 // and v22.16b, v23.16b, v29.16b
	WORD $0x4f0c56d6 // shl v22.16b, v22.16b, #4
	WORD $0x4eb61f39 // orr v25.16b, v25.16b, v22.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x4e3c1ef7 // and v23.16b, v23.16b, v28.16b
	WORD $0x4eb71eb5 // orr v21.16b, v21.16b, v23.16b
	WORD $0x4e919728 // sdot v8.4s, v25.16b, v17.16b
	WORD $0x4e9396ac // sdot v12.4s, v21.16b, v19.16b
	WORD $0x3cc10194 // ldur q20, [x12, #16]
	WORD $0x3cc50195 // ldur q21, [x12, #80]
	WORD $0x3cc101b6 // ldur q22, [x13, #16]
	WORD $0x3cc501b7 // ldur q23, [x13, #80]
	WORD $0x4e3f1e98 // and v24.16b, v20.16b, v31.16b
	WORD $0x4e3d1ed9 // and v25.16b, v22.16b, v29.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91f18 // orr v24.16b, v24.16b, v25.16b
	WORD $0x6f0c0694 // ushr v20.16b, v20.16b, #4
	WORD $0x4e3c1ed6 // and v22.16b, v22.16b, v28.16b
	WORD $0x4eb61e94 // orr v20.16b, v20.16b, v22.16b
	WORD $0x4e909709 // sdot v9.4s, v24.16b, v16.16b
	WORD $0x4e92968d // sdot v13.4s, v20.16b, v18.16b
	WORD $0x4e3f1eb9 // and v25.16b, v21.16b, v31.16b
	WORD $0x4e3d1ef6 // and v22.16b, v23.16b, v29.16b
	WORD $0x4f0c56d6 // shl v22.16b, v22.16b, #4
	WORD $0x4eb61f39 // orr v25.16b, v25.16b, v22.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x4e3c1ef7 // and v23.16b, v23.16b, v28.16b
	WORD $0x4eb71eb5 // orr v21.16b, v21.16b, v23.16b
	WORD $0x4e919729 // sdot v9.4s, v25.16b, v17.16b
	WORD $0x4e9396ad // sdot v13.4s, v21.16b, v19.16b
	WORD $0x3cc20194 // ldur q20, [x12, #32]
	WORD $0x3cc60195 // ldur q21, [x12, #96]
	WORD $0x3cc201b6 // ldur q22, [x13, #32]
	WORD $0x3cc601b7 // ldur q23, [x13, #96]
	WORD $0x4e3f1e98 // and v24.16b, v20.16b, v31.16b
	WORD $0x4e3d1ed9 // and v25.16b, v22.16b, v29.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91f18 // orr v24.16b, v24.16b, v25.16b
	WORD $0x6f0c0694 // ushr v20.16b, v20.16b, #4
	WORD $0x4e3c1ed6 // and v22.16b, v22.16b, v28.16b
	WORD $0x4eb61e94 // orr v20.16b, v20.16b, v22.16b
	WORD $0x4e90970a // sdot v10.4s, v24.16b, v16.16b
	WORD $0x4e92968e // sdot v14.4s, v20.16b, v18.16b
	WORD $0x4e3f1eb9 // and v25.16b, v21.16b, v31.16b
	WORD $0x4e3d1ef6 // and v22.16b, v23.16b, v29.16b
	WORD $0x4f0c56d6 // shl v22.16b, v22.16b, #4
	WORD $0x4eb61f39 // orr v25.16b, v25.16b, v22.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x4e3c1ef7 // and v23.16b, v23.16b, v28.16b
	WORD $0x4eb71eb5 // orr v21.16b, v21.16b, v23.16b
	WORD $0x4e91972a // sdot v10.4s, v25.16b, v17.16b
	WORD $0x4e9396ae // sdot v14.4s, v21.16b, v19.16b
	WORD $0x3cc30194 // ldur q20, [x12, #48]
	WORD $0x3cc70195 // ldur q21, [x12, #112]
	WORD $0x3cc301b6 // ldur q22, [x13, #48]
	WORD $0x3cc701b7 // ldur q23, [x13, #112]
	WORD $0x4e3f1e98 // and v24.16b, v20.16b, v31.16b
	WORD $0x4e3d1ed9 // and v25.16b, v22.16b, v29.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91f18 // orr v24.16b, v24.16b, v25.16b
	WORD $0x6f0c0694 // ushr v20.16b, v20.16b, #4
	WORD $0x4e3c1ed6 // and v22.16b, v22.16b, v28.16b
	WORD $0x4eb61e94 // orr v20.16b, v20.16b, v22.16b
	WORD $0x4e90970b // sdot v11.4s, v24.16b, v16.16b
	WORD $0x4e92968f // sdot v15.4s, v20.16b, v18.16b
	WORD $0x4e3f1eb9 // and v25.16b, v21.16b, v31.16b
	WORD $0x4e3d1ef6 // and v22.16b, v23.16b, v29.16b
	WORD $0x4f0c56d6 // shl v22.16b, v22.16b, #4
	WORD $0x4eb61f39 // orr v25.16b, v25.16b, v22.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x4e3c1ef7 // and v23.16b, v23.16b, v28.16b
	WORD $0x4eb71eb5 // orr v21.16b, v21.16b, v23.16b
	WORD $0x4e91972b // sdot v11.4s, v25.16b, v17.16b
	WORD $0x4e9396af // sdot v15.4s, v21.16b, v19.16b
	WORD $0x4ea9bd14 // addp v20.4s, v8.4s, v9.4s
	WORD $0x4eabbd55 // addp v21.4s, v10.4s, v11.4s
	WORD $0x4eadbd96 // addp v22.4s, v12.4s, v13.4s
	WORD $0x4eafbdd7 // addp v23.4s, v14.4s, v15.4s
	WORD $0xfc410138 // ldur d24, [x9, #16]
	WORD $0xfc430139 // ldur d25, [x9, #48]
	WORD $0x0f08a718 // sshll v24.8h, v24.8b, #0
	WORD $0x0f08a739 // sshll v25.8h, v25.8b, #0
	WORD $0x0f10a708 // sshll v8.4s, v24.4h, #0
	WORD $0x4ea8969e // mla v30.4s, v20.4s, v8.4s
	WORD $0x4f10a708 // sshll2 v8.4s, v24.8h, #0
	WORD $0x4ea896a7 // mla v7.4s, v21.4s, v8.4s
	WORD $0x0f10a728 // sshll v8.4s, v25.4h, #0
	WORD $0x4ea896de // mla v30.4s, v22.4s, v8.4s
	WORD $0x4f10a728 // sshll2 v8.4s, v25.8h, #0
	WORD $0x4ea896e7 // mla v7.4s, v23.4s, v8.4s
	WORD $0x0f462304 // smlal v4.4s, v24.4h, v6.h[0]
	WORD $0x4f462305 // smlal2 v5.4s, v24.8h, v6.h[0]
	WORD $0x0f462b24 // smlal v4.4s, v25.4h, v6.h[4]
	WORD $0x4f462b25 // smlal2 v5.4s, v25.8h, v6.h[4]
	WORD $0xfc414150 // ldur d16, [x10, #20]
	WORD $0x4e080610 // dup v16.2d, v16.d[0]
	WORD $0xfc41c151 // ldur d17, [x10, #28]
	WORD $0x4e080631 // dup v17.2d, v17.d[0]
	WORD $0xfc454152 // ldur d18, [x10, #84]
	WORD $0x4e080652 // dup v18.2d, v18.d[0]
	WORD $0xfc45c153 // ldur d19, [x10, #92]
	WORD $0x4e080673 // dup v19.2d, v19.d[0]
	ADD	$272, R9, R12
	ADD	$1296, R9, R13
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4f00040e // movi v14.4s, #0
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x3cc00194 // ldur q20, [x12, #0]
	WORD $0x3cc40195 // ldur q21, [x12, #64]
	WORD $0x3cc001b6 // ldur q22, [x13, #0]
	WORD $0x3cc401b7 // ldur q23, [x13, #64]
	WORD $0x4e3f1e98 // and v24.16b, v20.16b, v31.16b
	WORD $0x4e3d1ed9 // and v25.16b, v22.16b, v29.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91f18 // orr v24.16b, v24.16b, v25.16b
	WORD $0x6f0c0694 // ushr v20.16b, v20.16b, #4
	WORD $0x4e3c1ed6 // and v22.16b, v22.16b, v28.16b
	WORD $0x4eb61e94 // orr v20.16b, v20.16b, v22.16b
	WORD $0x4e909708 // sdot v8.4s, v24.16b, v16.16b
	WORD $0x4e92968c // sdot v12.4s, v20.16b, v18.16b
	WORD $0x4e3f1eb9 // and v25.16b, v21.16b, v31.16b
	WORD $0x4e3d1ef6 // and v22.16b, v23.16b, v29.16b
	WORD $0x4f0c56d6 // shl v22.16b, v22.16b, #4
	WORD $0x4eb61f39 // orr v25.16b, v25.16b, v22.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x4e3c1ef7 // and v23.16b, v23.16b, v28.16b
	WORD $0x4eb71eb5 // orr v21.16b, v21.16b, v23.16b
	WORD $0x4e919728 // sdot v8.4s, v25.16b, v17.16b
	WORD $0x4e9396ac // sdot v12.4s, v21.16b, v19.16b
	WORD $0x3cc10194 // ldur q20, [x12, #16]
	WORD $0x3cc50195 // ldur q21, [x12, #80]
	WORD $0x3cc101b6 // ldur q22, [x13, #16]
	WORD $0x3cc501b7 // ldur q23, [x13, #80]
	WORD $0x4e3f1e98 // and v24.16b, v20.16b, v31.16b
	WORD $0x4e3d1ed9 // and v25.16b, v22.16b, v29.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91f18 // orr v24.16b, v24.16b, v25.16b
	WORD $0x6f0c0694 // ushr v20.16b, v20.16b, #4
	WORD $0x4e3c1ed6 // and v22.16b, v22.16b, v28.16b
	WORD $0x4eb61e94 // orr v20.16b, v20.16b, v22.16b
	WORD $0x4e909709 // sdot v9.4s, v24.16b, v16.16b
	WORD $0x4e92968d // sdot v13.4s, v20.16b, v18.16b
	WORD $0x4e3f1eb9 // and v25.16b, v21.16b, v31.16b
	WORD $0x4e3d1ef6 // and v22.16b, v23.16b, v29.16b
	WORD $0x4f0c56d6 // shl v22.16b, v22.16b, #4
	WORD $0x4eb61f39 // orr v25.16b, v25.16b, v22.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x4e3c1ef7 // and v23.16b, v23.16b, v28.16b
	WORD $0x4eb71eb5 // orr v21.16b, v21.16b, v23.16b
	WORD $0x4e919729 // sdot v9.4s, v25.16b, v17.16b
	WORD $0x4e9396ad // sdot v13.4s, v21.16b, v19.16b
	WORD $0x3cc20194 // ldur q20, [x12, #32]
	WORD $0x3cc60195 // ldur q21, [x12, #96]
	WORD $0x3cc201b6 // ldur q22, [x13, #32]
	WORD $0x3cc601b7 // ldur q23, [x13, #96]
	WORD $0x4e3f1e98 // and v24.16b, v20.16b, v31.16b
	WORD $0x4e3d1ed9 // and v25.16b, v22.16b, v29.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91f18 // orr v24.16b, v24.16b, v25.16b
	WORD $0x6f0c0694 // ushr v20.16b, v20.16b, #4
	WORD $0x4e3c1ed6 // and v22.16b, v22.16b, v28.16b
	WORD $0x4eb61e94 // orr v20.16b, v20.16b, v22.16b
	WORD $0x4e90970a // sdot v10.4s, v24.16b, v16.16b
	WORD $0x4e92968e // sdot v14.4s, v20.16b, v18.16b
	WORD $0x4e3f1eb9 // and v25.16b, v21.16b, v31.16b
	WORD $0x4e3d1ef6 // and v22.16b, v23.16b, v29.16b
	WORD $0x4f0c56d6 // shl v22.16b, v22.16b, #4
	WORD $0x4eb61f39 // orr v25.16b, v25.16b, v22.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x4e3c1ef7 // and v23.16b, v23.16b, v28.16b
	WORD $0x4eb71eb5 // orr v21.16b, v21.16b, v23.16b
	WORD $0x4e91972a // sdot v10.4s, v25.16b, v17.16b
	WORD $0x4e9396ae // sdot v14.4s, v21.16b, v19.16b
	WORD $0x3cc30194 // ldur q20, [x12, #48]
	WORD $0x3cc70195 // ldur q21, [x12, #112]
	WORD $0x3cc301b6 // ldur q22, [x13, #48]
	WORD $0x3cc701b7 // ldur q23, [x13, #112]
	WORD $0x4e3f1e98 // and v24.16b, v20.16b, v31.16b
	WORD $0x4e3d1ed9 // and v25.16b, v22.16b, v29.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91f18 // orr v24.16b, v24.16b, v25.16b
	WORD $0x6f0c0694 // ushr v20.16b, v20.16b, #4
	WORD $0x4e3c1ed6 // and v22.16b, v22.16b, v28.16b
	WORD $0x4eb61e94 // orr v20.16b, v20.16b, v22.16b
	WORD $0x4e90970b // sdot v11.4s, v24.16b, v16.16b
	WORD $0x4e92968f // sdot v15.4s, v20.16b, v18.16b
	WORD $0x4e3f1eb9 // and v25.16b, v21.16b, v31.16b
	WORD $0x4e3d1ef6 // and v22.16b, v23.16b, v29.16b
	WORD $0x4f0c56d6 // shl v22.16b, v22.16b, #4
	WORD $0x4eb61f39 // orr v25.16b, v25.16b, v22.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x4e3c1ef7 // and v23.16b, v23.16b, v28.16b
	WORD $0x4eb71eb5 // orr v21.16b, v21.16b, v23.16b
	WORD $0x4e91972b // sdot v11.4s, v25.16b, v17.16b
	WORD $0x4e9396af // sdot v15.4s, v21.16b, v19.16b
	WORD $0x4ea9bd14 // addp v20.4s, v8.4s, v9.4s
	WORD $0x4eabbd55 // addp v21.4s, v10.4s, v11.4s
	WORD $0x4eadbd96 // addp v22.4s, v12.4s, v13.4s
	WORD $0x4eafbdd7 // addp v23.4s, v14.4s, v15.4s
	WORD $0xfc418138 // ldur d24, [x9, #24]
	WORD $0xfc438139 // ldur d25, [x9, #56]
	WORD $0x0f08a718 // sshll v24.8h, v24.8b, #0
	WORD $0x0f08a739 // sshll v25.8h, v25.8b, #0
	WORD $0x0f10a708 // sshll v8.4s, v24.4h, #0
	WORD $0x4ea8969e // mla v30.4s, v20.4s, v8.4s
	WORD $0x4f10a708 // sshll2 v8.4s, v24.8h, #0
	WORD $0x4ea896a7 // mla v7.4s, v21.4s, v8.4s
	WORD $0x0f10a728 // sshll v8.4s, v25.4h, #0
	WORD $0x4ea896de // mla v30.4s, v22.4s, v8.4s
	WORD $0x4f10a728 // sshll2 v8.4s, v25.8h, #0
	WORD $0x4ea896e7 // mla v7.4s, v23.4s, v8.4s
	WORD $0x0f562304 // smlal v4.4s, v24.4h, v6.h[1]
	WORD $0x4f562305 // smlal2 v5.4s, v24.8h, v6.h[1]
	WORD $0x0f562b24 // smlal v4.4s, v25.4h, v6.h[5]
	WORD $0x4f562b25 // smlal2 v5.4s, v25.8h, v6.h[5]
	WORD $0xfc424150 // ldur d16, [x10, #36]
	WORD $0x4e080610 // dup v16.2d, v16.d[0]
	WORD $0xfc42c151 // ldur d17, [x10, #44]
	WORD $0x4e080631 // dup v17.2d, v17.d[0]
	WORD $0xfc464152 // ldur d18, [x10, #100]
	WORD $0x4e080652 // dup v18.2d, v18.d[0]
	WORD $0xfc46c153 // ldur d19, [x10, #108]
	WORD $0x4e080673 // dup v19.2d, v19.d[0]
	ADD	$400, R9, R12
	ADD	$1168, R9, R13
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4f00040e // movi v14.4s, #0
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x3cc00194 // ldur q20, [x12, #0]
	WORD $0x3cc40195 // ldur q21, [x12, #64]
	WORD $0x3cc001b6 // ldur q22, [x13, #0]
	WORD $0x3cc401b7 // ldur q23, [x13, #64]
	WORD $0x6f0e06d6 // ushr v22.16b, v22.16b, #2
	WORD $0x6f0e06f7 // ushr v23.16b, v23.16b, #2
	WORD $0x4e3f1e98 // and v24.16b, v20.16b, v31.16b
	WORD $0x4e3d1ed9 // and v25.16b, v22.16b, v29.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91f18 // orr v24.16b, v24.16b, v25.16b
	WORD $0x6f0c0694 // ushr v20.16b, v20.16b, #4
	WORD $0x4e3c1ed6 // and v22.16b, v22.16b, v28.16b
	WORD $0x4eb61e94 // orr v20.16b, v20.16b, v22.16b
	WORD $0x4e909708 // sdot v8.4s, v24.16b, v16.16b
	WORD $0x4e92968c // sdot v12.4s, v20.16b, v18.16b
	WORD $0x4e3f1eb9 // and v25.16b, v21.16b, v31.16b
	WORD $0x4e3d1ef6 // and v22.16b, v23.16b, v29.16b
	WORD $0x4f0c56d6 // shl v22.16b, v22.16b, #4
	WORD $0x4eb61f39 // orr v25.16b, v25.16b, v22.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x4e3c1ef7 // and v23.16b, v23.16b, v28.16b
	WORD $0x4eb71eb5 // orr v21.16b, v21.16b, v23.16b
	WORD $0x4e919728 // sdot v8.4s, v25.16b, v17.16b
	WORD $0x4e9396ac // sdot v12.4s, v21.16b, v19.16b
	WORD $0x3cc10194 // ldur q20, [x12, #16]
	WORD $0x3cc50195 // ldur q21, [x12, #80]
	WORD $0x3cc101b6 // ldur q22, [x13, #16]
	WORD $0x3cc501b7 // ldur q23, [x13, #80]
	WORD $0x6f0e06d6 // ushr v22.16b, v22.16b, #2
	WORD $0x6f0e06f7 // ushr v23.16b, v23.16b, #2
	WORD $0x4e3f1e98 // and v24.16b, v20.16b, v31.16b
	WORD $0x4e3d1ed9 // and v25.16b, v22.16b, v29.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91f18 // orr v24.16b, v24.16b, v25.16b
	WORD $0x6f0c0694 // ushr v20.16b, v20.16b, #4
	WORD $0x4e3c1ed6 // and v22.16b, v22.16b, v28.16b
	WORD $0x4eb61e94 // orr v20.16b, v20.16b, v22.16b
	WORD $0x4e909709 // sdot v9.4s, v24.16b, v16.16b
	WORD $0x4e92968d // sdot v13.4s, v20.16b, v18.16b
	WORD $0x4e3f1eb9 // and v25.16b, v21.16b, v31.16b
	WORD $0x4e3d1ef6 // and v22.16b, v23.16b, v29.16b
	WORD $0x4f0c56d6 // shl v22.16b, v22.16b, #4
	WORD $0x4eb61f39 // orr v25.16b, v25.16b, v22.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x4e3c1ef7 // and v23.16b, v23.16b, v28.16b
	WORD $0x4eb71eb5 // orr v21.16b, v21.16b, v23.16b
	WORD $0x4e919729 // sdot v9.4s, v25.16b, v17.16b
	WORD $0x4e9396ad // sdot v13.4s, v21.16b, v19.16b
	WORD $0x3cc20194 // ldur q20, [x12, #32]
	WORD $0x3cc60195 // ldur q21, [x12, #96]
	WORD $0x3cc201b6 // ldur q22, [x13, #32]
	WORD $0x3cc601b7 // ldur q23, [x13, #96]
	WORD $0x6f0e06d6 // ushr v22.16b, v22.16b, #2
	WORD $0x6f0e06f7 // ushr v23.16b, v23.16b, #2
	WORD $0x4e3f1e98 // and v24.16b, v20.16b, v31.16b
	WORD $0x4e3d1ed9 // and v25.16b, v22.16b, v29.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91f18 // orr v24.16b, v24.16b, v25.16b
	WORD $0x6f0c0694 // ushr v20.16b, v20.16b, #4
	WORD $0x4e3c1ed6 // and v22.16b, v22.16b, v28.16b
	WORD $0x4eb61e94 // orr v20.16b, v20.16b, v22.16b
	WORD $0x4e90970a // sdot v10.4s, v24.16b, v16.16b
	WORD $0x4e92968e // sdot v14.4s, v20.16b, v18.16b
	WORD $0x4e3f1eb9 // and v25.16b, v21.16b, v31.16b
	WORD $0x4e3d1ef6 // and v22.16b, v23.16b, v29.16b
	WORD $0x4f0c56d6 // shl v22.16b, v22.16b, #4
	WORD $0x4eb61f39 // orr v25.16b, v25.16b, v22.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x4e3c1ef7 // and v23.16b, v23.16b, v28.16b
	WORD $0x4eb71eb5 // orr v21.16b, v21.16b, v23.16b
	WORD $0x4e91972a // sdot v10.4s, v25.16b, v17.16b
	WORD $0x4e9396ae // sdot v14.4s, v21.16b, v19.16b
	WORD $0x3cc30194 // ldur q20, [x12, #48]
	WORD $0x3cc70195 // ldur q21, [x12, #112]
	WORD $0x3cc301b6 // ldur q22, [x13, #48]
	WORD $0x3cc701b7 // ldur q23, [x13, #112]
	WORD $0x6f0e06d6 // ushr v22.16b, v22.16b, #2
	WORD $0x6f0e06f7 // ushr v23.16b, v23.16b, #2
	WORD $0x4e3f1e98 // and v24.16b, v20.16b, v31.16b
	WORD $0x4e3d1ed9 // and v25.16b, v22.16b, v29.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91f18 // orr v24.16b, v24.16b, v25.16b
	WORD $0x6f0c0694 // ushr v20.16b, v20.16b, #4
	WORD $0x4e3c1ed6 // and v22.16b, v22.16b, v28.16b
	WORD $0x4eb61e94 // orr v20.16b, v20.16b, v22.16b
	WORD $0x4e90970b // sdot v11.4s, v24.16b, v16.16b
	WORD $0x4e92968f // sdot v15.4s, v20.16b, v18.16b
	WORD $0x4e3f1eb9 // and v25.16b, v21.16b, v31.16b
	WORD $0x4e3d1ef6 // and v22.16b, v23.16b, v29.16b
	WORD $0x4f0c56d6 // shl v22.16b, v22.16b, #4
	WORD $0x4eb61f39 // orr v25.16b, v25.16b, v22.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x4e3c1ef7 // and v23.16b, v23.16b, v28.16b
	WORD $0x4eb71eb5 // orr v21.16b, v21.16b, v23.16b
	WORD $0x4e91972b // sdot v11.4s, v25.16b, v17.16b
	WORD $0x4e9396af // sdot v15.4s, v21.16b, v19.16b
	WORD $0x4ea9bd14 // addp v20.4s, v8.4s, v9.4s
	WORD $0x4eabbd55 // addp v21.4s, v10.4s, v11.4s
	WORD $0x4eadbd96 // addp v22.4s, v12.4s, v13.4s
	WORD $0x4eafbdd7 // addp v23.4s, v14.4s, v15.4s
	WORD $0xfc420138 // ldur d24, [x9, #32]
	WORD $0xfc440139 // ldur d25, [x9, #64]
	WORD $0x0f08a718 // sshll v24.8h, v24.8b, #0
	WORD $0x0f08a739 // sshll v25.8h, v25.8b, #0
	WORD $0x0f10a708 // sshll v8.4s, v24.4h, #0
	WORD $0x4ea8969e // mla v30.4s, v20.4s, v8.4s
	WORD $0x4f10a708 // sshll2 v8.4s, v24.8h, #0
	WORD $0x4ea896a7 // mla v7.4s, v21.4s, v8.4s
	WORD $0x0f10a728 // sshll v8.4s, v25.4h, #0
	WORD $0x4ea896de // mla v30.4s, v22.4s, v8.4s
	WORD $0x4f10a728 // sshll2 v8.4s, v25.8h, #0
	WORD $0x4ea896e7 // mla v7.4s, v23.4s, v8.4s
	WORD $0x0f662304 // smlal v4.4s, v24.4h, v6.h[2]
	WORD $0x4f662305 // smlal2 v5.4s, v24.8h, v6.h[2]
	WORD $0x0f662b24 // smlal v4.4s, v25.4h, v6.h[6]
	WORD $0x4f662b25 // smlal2 v5.4s, v25.8h, v6.h[6]
	WORD $0xfc434150 // ldur d16, [x10, #52]
	WORD $0x4e080610 // dup v16.2d, v16.d[0]
	WORD $0xfc43c151 // ldur d17, [x10, #60]
	WORD $0x4e080631 // dup v17.2d, v17.d[0]
	WORD $0xfc474152 // ldur d18, [x10, #116]
	WORD $0x4e080652 // dup v18.2d, v18.d[0]
	WORD $0xfc47c153 // ldur d19, [x10, #124]
	WORD $0x4e080673 // dup v19.2d, v19.d[0]
	ADD	$528, R9, R12
	ADD	$1296, R9, R13
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4f00040e // movi v14.4s, #0
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x3cc00194 // ldur q20, [x12, #0]
	WORD $0x3cc40195 // ldur q21, [x12, #64]
	WORD $0x3cc001b6 // ldur q22, [x13, #0]
	WORD $0x3cc401b7 // ldur q23, [x13, #64]
	WORD $0x6f0e06d6 // ushr v22.16b, v22.16b, #2
	WORD $0x6f0e06f7 // ushr v23.16b, v23.16b, #2
	WORD $0x4e3f1e98 // and v24.16b, v20.16b, v31.16b
	WORD $0x4e3d1ed9 // and v25.16b, v22.16b, v29.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91f18 // orr v24.16b, v24.16b, v25.16b
	WORD $0x6f0c0694 // ushr v20.16b, v20.16b, #4
	WORD $0x4e3c1ed6 // and v22.16b, v22.16b, v28.16b
	WORD $0x4eb61e94 // orr v20.16b, v20.16b, v22.16b
	WORD $0x4e909708 // sdot v8.4s, v24.16b, v16.16b
	WORD $0x4e92968c // sdot v12.4s, v20.16b, v18.16b
	WORD $0x4e3f1eb9 // and v25.16b, v21.16b, v31.16b
	WORD $0x4e3d1ef6 // and v22.16b, v23.16b, v29.16b
	WORD $0x4f0c56d6 // shl v22.16b, v22.16b, #4
	WORD $0x4eb61f39 // orr v25.16b, v25.16b, v22.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x4e3c1ef7 // and v23.16b, v23.16b, v28.16b
	WORD $0x4eb71eb5 // orr v21.16b, v21.16b, v23.16b
	WORD $0x4e919728 // sdot v8.4s, v25.16b, v17.16b
	WORD $0x4e9396ac // sdot v12.4s, v21.16b, v19.16b
	WORD $0x3cc10194 // ldur q20, [x12, #16]
	WORD $0x3cc50195 // ldur q21, [x12, #80]
	WORD $0x3cc101b6 // ldur q22, [x13, #16]
	WORD $0x3cc501b7 // ldur q23, [x13, #80]
	WORD $0x6f0e06d6 // ushr v22.16b, v22.16b, #2
	WORD $0x6f0e06f7 // ushr v23.16b, v23.16b, #2
	WORD $0x4e3f1e98 // and v24.16b, v20.16b, v31.16b
	WORD $0x4e3d1ed9 // and v25.16b, v22.16b, v29.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91f18 // orr v24.16b, v24.16b, v25.16b
	WORD $0x6f0c0694 // ushr v20.16b, v20.16b, #4
	WORD $0x4e3c1ed6 // and v22.16b, v22.16b, v28.16b
	WORD $0x4eb61e94 // orr v20.16b, v20.16b, v22.16b
	WORD $0x4e909709 // sdot v9.4s, v24.16b, v16.16b
	WORD $0x4e92968d // sdot v13.4s, v20.16b, v18.16b
	WORD $0x4e3f1eb9 // and v25.16b, v21.16b, v31.16b
	WORD $0x4e3d1ef6 // and v22.16b, v23.16b, v29.16b
	WORD $0x4f0c56d6 // shl v22.16b, v22.16b, #4
	WORD $0x4eb61f39 // orr v25.16b, v25.16b, v22.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x4e3c1ef7 // and v23.16b, v23.16b, v28.16b
	WORD $0x4eb71eb5 // orr v21.16b, v21.16b, v23.16b
	WORD $0x4e919729 // sdot v9.4s, v25.16b, v17.16b
	WORD $0x4e9396ad // sdot v13.4s, v21.16b, v19.16b
	WORD $0x3cc20194 // ldur q20, [x12, #32]
	WORD $0x3cc60195 // ldur q21, [x12, #96]
	WORD $0x3cc201b6 // ldur q22, [x13, #32]
	WORD $0x3cc601b7 // ldur q23, [x13, #96]
	WORD $0x6f0e06d6 // ushr v22.16b, v22.16b, #2
	WORD $0x6f0e06f7 // ushr v23.16b, v23.16b, #2
	WORD $0x4e3f1e98 // and v24.16b, v20.16b, v31.16b
	WORD $0x4e3d1ed9 // and v25.16b, v22.16b, v29.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91f18 // orr v24.16b, v24.16b, v25.16b
	WORD $0x6f0c0694 // ushr v20.16b, v20.16b, #4
	WORD $0x4e3c1ed6 // and v22.16b, v22.16b, v28.16b
	WORD $0x4eb61e94 // orr v20.16b, v20.16b, v22.16b
	WORD $0x4e90970a // sdot v10.4s, v24.16b, v16.16b
	WORD $0x4e92968e // sdot v14.4s, v20.16b, v18.16b
	WORD $0x4e3f1eb9 // and v25.16b, v21.16b, v31.16b
	WORD $0x4e3d1ef6 // and v22.16b, v23.16b, v29.16b
	WORD $0x4f0c56d6 // shl v22.16b, v22.16b, #4
	WORD $0x4eb61f39 // orr v25.16b, v25.16b, v22.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x4e3c1ef7 // and v23.16b, v23.16b, v28.16b
	WORD $0x4eb71eb5 // orr v21.16b, v21.16b, v23.16b
	WORD $0x4e91972a // sdot v10.4s, v25.16b, v17.16b
	WORD $0x4e9396ae // sdot v14.4s, v21.16b, v19.16b
	WORD $0x3cc30194 // ldur q20, [x12, #48]
	WORD $0x3cc70195 // ldur q21, [x12, #112]
	WORD $0x3cc301b6 // ldur q22, [x13, #48]
	WORD $0x3cc701b7 // ldur q23, [x13, #112]
	WORD $0x6f0e06d6 // ushr v22.16b, v22.16b, #2
	WORD $0x6f0e06f7 // ushr v23.16b, v23.16b, #2
	WORD $0x4e3f1e98 // and v24.16b, v20.16b, v31.16b
	WORD $0x4e3d1ed9 // and v25.16b, v22.16b, v29.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91f18 // orr v24.16b, v24.16b, v25.16b
	WORD $0x6f0c0694 // ushr v20.16b, v20.16b, #4
	WORD $0x4e3c1ed6 // and v22.16b, v22.16b, v28.16b
	WORD $0x4eb61e94 // orr v20.16b, v20.16b, v22.16b
	WORD $0x4e90970b // sdot v11.4s, v24.16b, v16.16b
	WORD $0x4e92968f // sdot v15.4s, v20.16b, v18.16b
	WORD $0x4e3f1eb9 // and v25.16b, v21.16b, v31.16b
	WORD $0x4e3d1ef6 // and v22.16b, v23.16b, v29.16b
	WORD $0x4f0c56d6 // shl v22.16b, v22.16b, #4
	WORD $0x4eb61f39 // orr v25.16b, v25.16b, v22.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x4e3c1ef7 // and v23.16b, v23.16b, v28.16b
	WORD $0x4eb71eb5 // orr v21.16b, v21.16b, v23.16b
	WORD $0x4e91972b // sdot v11.4s, v25.16b, v17.16b
	WORD $0x4e9396af // sdot v15.4s, v21.16b, v19.16b
	WORD $0x4ea9bd14 // addp v20.4s, v8.4s, v9.4s
	WORD $0x4eabbd55 // addp v21.4s, v10.4s, v11.4s
	WORD $0x4eadbd96 // addp v22.4s, v12.4s, v13.4s
	WORD $0x4eafbdd7 // addp v23.4s, v14.4s, v15.4s
	WORD $0xfc428138 // ldur d24, [x9, #40]
	WORD $0xfc448139 // ldur d25, [x9, #72]
	WORD $0x0f08a718 // sshll v24.8h, v24.8b, #0
	WORD $0x0f08a739 // sshll v25.8h, v25.8b, #0
	WORD $0x0f10a708 // sshll v8.4s, v24.4h, #0
	WORD $0x4ea8969e // mla v30.4s, v20.4s, v8.4s
	WORD $0x4f10a708 // sshll2 v8.4s, v24.8h, #0
	WORD $0x4ea896a7 // mla v7.4s, v21.4s, v8.4s
	WORD $0x0f10a728 // sshll v8.4s, v25.4h, #0
	WORD $0x4ea896de // mla v30.4s, v22.4s, v8.4s
	WORD $0x4f10a728 // sshll2 v8.4s, v25.8h, #0
	WORD $0x4ea896e7 // mla v7.4s, v23.4s, v8.4s
	WORD $0x0f762304 // smlal v4.4s, v24.4h, v6.h[3]
	WORD $0x4f762305 // smlal2 v5.4s, v24.8h, v6.h[3]
	WORD $0x0f762b24 // smlal v4.4s, v25.4h, v6.h[7]
	WORD $0x4f762b25 // smlal2 v5.4s, v25.8h, v6.h[7]
	WORD $0x3cc14166 // ldur q6, [x11, #20]
	WORD $0xfc484150 // ldur d16, [x10, #132]
	WORD $0x4e080610 // dup v16.2d, v16.d[0]
	WORD $0xfc48c151 // ldur d17, [x10, #140]
	WORD $0x4e080631 // dup v17.2d, v17.d[0]
	WORD $0xfc4c4152 // ldur d18, [x10, #196]
	WORD $0x4e080652 // dup v18.2d, v18.d[0]
	WORD $0xfc4cc153 // ldur d19, [x10, #204]
	WORD $0x4e080673 // dup v19.2d, v19.d[0]
	ADD	$656, R9, R12
	ADD	$1424, R9, R13
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4f00040e // movi v14.4s, #0
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x3cc00194 // ldur q20, [x12, #0]
	WORD $0x3cc40195 // ldur q21, [x12, #64]
	WORD $0x3cc001b6 // ldur q22, [x13, #0]
	WORD $0x3cc401b7 // ldur q23, [x13, #64]
	WORD $0x4e3f1e98 // and v24.16b, v20.16b, v31.16b
	WORD $0x4e3d1ed9 // and v25.16b, v22.16b, v29.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91f18 // orr v24.16b, v24.16b, v25.16b
	WORD $0x6f0c0694 // ushr v20.16b, v20.16b, #4
	WORD $0x4e3c1ed6 // and v22.16b, v22.16b, v28.16b
	WORD $0x4eb61e94 // orr v20.16b, v20.16b, v22.16b
	WORD $0x4e909708 // sdot v8.4s, v24.16b, v16.16b
	WORD $0x4e92968c // sdot v12.4s, v20.16b, v18.16b
	WORD $0x4e3f1eb9 // and v25.16b, v21.16b, v31.16b
	WORD $0x4e3d1ef6 // and v22.16b, v23.16b, v29.16b
	WORD $0x4f0c56d6 // shl v22.16b, v22.16b, #4
	WORD $0x4eb61f39 // orr v25.16b, v25.16b, v22.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x4e3c1ef7 // and v23.16b, v23.16b, v28.16b
	WORD $0x4eb71eb5 // orr v21.16b, v21.16b, v23.16b
	WORD $0x4e919728 // sdot v8.4s, v25.16b, v17.16b
	WORD $0x4e9396ac // sdot v12.4s, v21.16b, v19.16b
	WORD $0x3cc10194 // ldur q20, [x12, #16]
	WORD $0x3cc50195 // ldur q21, [x12, #80]
	WORD $0x3cc101b6 // ldur q22, [x13, #16]
	WORD $0x3cc501b7 // ldur q23, [x13, #80]
	WORD $0x4e3f1e98 // and v24.16b, v20.16b, v31.16b
	WORD $0x4e3d1ed9 // and v25.16b, v22.16b, v29.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91f18 // orr v24.16b, v24.16b, v25.16b
	WORD $0x6f0c0694 // ushr v20.16b, v20.16b, #4
	WORD $0x4e3c1ed6 // and v22.16b, v22.16b, v28.16b
	WORD $0x4eb61e94 // orr v20.16b, v20.16b, v22.16b
	WORD $0x4e909709 // sdot v9.4s, v24.16b, v16.16b
	WORD $0x4e92968d // sdot v13.4s, v20.16b, v18.16b
	WORD $0x4e3f1eb9 // and v25.16b, v21.16b, v31.16b
	WORD $0x4e3d1ef6 // and v22.16b, v23.16b, v29.16b
	WORD $0x4f0c56d6 // shl v22.16b, v22.16b, #4
	WORD $0x4eb61f39 // orr v25.16b, v25.16b, v22.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x4e3c1ef7 // and v23.16b, v23.16b, v28.16b
	WORD $0x4eb71eb5 // orr v21.16b, v21.16b, v23.16b
	WORD $0x4e919729 // sdot v9.4s, v25.16b, v17.16b
	WORD $0x4e9396ad // sdot v13.4s, v21.16b, v19.16b
	WORD $0x3cc20194 // ldur q20, [x12, #32]
	WORD $0x3cc60195 // ldur q21, [x12, #96]
	WORD $0x3cc201b6 // ldur q22, [x13, #32]
	WORD $0x3cc601b7 // ldur q23, [x13, #96]
	WORD $0x4e3f1e98 // and v24.16b, v20.16b, v31.16b
	WORD $0x4e3d1ed9 // and v25.16b, v22.16b, v29.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91f18 // orr v24.16b, v24.16b, v25.16b
	WORD $0x6f0c0694 // ushr v20.16b, v20.16b, #4
	WORD $0x4e3c1ed6 // and v22.16b, v22.16b, v28.16b
	WORD $0x4eb61e94 // orr v20.16b, v20.16b, v22.16b
	WORD $0x4e90970a // sdot v10.4s, v24.16b, v16.16b
	WORD $0x4e92968e // sdot v14.4s, v20.16b, v18.16b
	WORD $0x4e3f1eb9 // and v25.16b, v21.16b, v31.16b
	WORD $0x4e3d1ef6 // and v22.16b, v23.16b, v29.16b
	WORD $0x4f0c56d6 // shl v22.16b, v22.16b, #4
	WORD $0x4eb61f39 // orr v25.16b, v25.16b, v22.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x4e3c1ef7 // and v23.16b, v23.16b, v28.16b
	WORD $0x4eb71eb5 // orr v21.16b, v21.16b, v23.16b
	WORD $0x4e91972a // sdot v10.4s, v25.16b, v17.16b
	WORD $0x4e9396ae // sdot v14.4s, v21.16b, v19.16b
	WORD $0x3cc30194 // ldur q20, [x12, #48]
	WORD $0x3cc70195 // ldur q21, [x12, #112]
	WORD $0x3cc301b6 // ldur q22, [x13, #48]
	WORD $0x3cc701b7 // ldur q23, [x13, #112]
	WORD $0x4e3f1e98 // and v24.16b, v20.16b, v31.16b
	WORD $0x4e3d1ed9 // and v25.16b, v22.16b, v29.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91f18 // orr v24.16b, v24.16b, v25.16b
	WORD $0x6f0c0694 // ushr v20.16b, v20.16b, #4
	WORD $0x4e3c1ed6 // and v22.16b, v22.16b, v28.16b
	WORD $0x4eb61e94 // orr v20.16b, v20.16b, v22.16b
	WORD $0x4e90970b // sdot v11.4s, v24.16b, v16.16b
	WORD $0x4e92968f // sdot v15.4s, v20.16b, v18.16b
	WORD $0x4e3f1eb9 // and v25.16b, v21.16b, v31.16b
	WORD $0x4e3d1ef6 // and v22.16b, v23.16b, v29.16b
	WORD $0x4f0c56d6 // shl v22.16b, v22.16b, #4
	WORD $0x4eb61f39 // orr v25.16b, v25.16b, v22.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x4e3c1ef7 // and v23.16b, v23.16b, v28.16b
	WORD $0x4eb71eb5 // orr v21.16b, v21.16b, v23.16b
	WORD $0x4e91972b // sdot v11.4s, v25.16b, v17.16b
	WORD $0x4e9396af // sdot v15.4s, v21.16b, v19.16b
	WORD $0x4ea9bd14 // addp v20.4s, v8.4s, v9.4s
	WORD $0x4eabbd55 // addp v21.4s, v10.4s, v11.4s
	WORD $0x4eadbd96 // addp v22.4s, v12.4s, v13.4s
	WORD $0x4eafbdd7 // addp v23.4s, v14.4s, v15.4s
	WORD $0xfc450138 // ldur d24, [x9, #80]
	WORD $0xfc470139 // ldur d25, [x9, #112]
	WORD $0x0f08a718 // sshll v24.8h, v24.8b, #0
	WORD $0x0f08a739 // sshll v25.8h, v25.8b, #0
	WORD $0x0f10a708 // sshll v8.4s, v24.4h, #0
	WORD $0x4ea8969e // mla v30.4s, v20.4s, v8.4s
	WORD $0x4f10a708 // sshll2 v8.4s, v24.8h, #0
	WORD $0x4ea896a7 // mla v7.4s, v21.4s, v8.4s
	WORD $0x0f10a728 // sshll v8.4s, v25.4h, #0
	WORD $0x4ea896de // mla v30.4s, v22.4s, v8.4s
	WORD $0x4f10a728 // sshll2 v8.4s, v25.8h, #0
	WORD $0x4ea896e7 // mla v7.4s, v23.4s, v8.4s
	WORD $0x0f462304 // smlal v4.4s, v24.4h, v6.h[0]
	WORD $0x4f462305 // smlal2 v5.4s, v24.8h, v6.h[0]
	WORD $0x0f462b24 // smlal v4.4s, v25.4h, v6.h[4]
	WORD $0x4f462b25 // smlal2 v5.4s, v25.8h, v6.h[4]
	WORD $0xfc494150 // ldur d16, [x10, #148]
	WORD $0x4e080610 // dup v16.2d, v16.d[0]
	WORD $0xfc49c151 // ldur d17, [x10, #156]
	WORD $0x4e080631 // dup v17.2d, v17.d[0]
	WORD $0xfc4d4152 // ldur d18, [x10, #212]
	WORD $0x4e080652 // dup v18.2d, v18.d[0]
	WORD $0xfc4dc153 // ldur d19, [x10, #220]
	WORD $0x4e080673 // dup v19.2d, v19.d[0]
	ADD	$784, R9, R12
	ADD	$1552, R9, R13
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4f00040e // movi v14.4s, #0
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x3cc00194 // ldur q20, [x12, #0]
	WORD $0x3cc40195 // ldur q21, [x12, #64]
	WORD $0x3cc001b6 // ldur q22, [x13, #0]
	WORD $0x3cc401b7 // ldur q23, [x13, #64]
	WORD $0x4e3f1e98 // and v24.16b, v20.16b, v31.16b
	WORD $0x4e3d1ed9 // and v25.16b, v22.16b, v29.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91f18 // orr v24.16b, v24.16b, v25.16b
	WORD $0x6f0c0694 // ushr v20.16b, v20.16b, #4
	WORD $0x4e3c1ed6 // and v22.16b, v22.16b, v28.16b
	WORD $0x4eb61e94 // orr v20.16b, v20.16b, v22.16b
	WORD $0x4e909708 // sdot v8.4s, v24.16b, v16.16b
	WORD $0x4e92968c // sdot v12.4s, v20.16b, v18.16b
	WORD $0x4e3f1eb9 // and v25.16b, v21.16b, v31.16b
	WORD $0x4e3d1ef6 // and v22.16b, v23.16b, v29.16b
	WORD $0x4f0c56d6 // shl v22.16b, v22.16b, #4
	WORD $0x4eb61f39 // orr v25.16b, v25.16b, v22.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x4e3c1ef7 // and v23.16b, v23.16b, v28.16b
	WORD $0x4eb71eb5 // orr v21.16b, v21.16b, v23.16b
	WORD $0x4e919728 // sdot v8.4s, v25.16b, v17.16b
	WORD $0x4e9396ac // sdot v12.4s, v21.16b, v19.16b
	WORD $0x3cc10194 // ldur q20, [x12, #16]
	WORD $0x3cc50195 // ldur q21, [x12, #80]
	WORD $0x3cc101b6 // ldur q22, [x13, #16]
	WORD $0x3cc501b7 // ldur q23, [x13, #80]
	WORD $0x4e3f1e98 // and v24.16b, v20.16b, v31.16b
	WORD $0x4e3d1ed9 // and v25.16b, v22.16b, v29.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91f18 // orr v24.16b, v24.16b, v25.16b
	WORD $0x6f0c0694 // ushr v20.16b, v20.16b, #4
	WORD $0x4e3c1ed6 // and v22.16b, v22.16b, v28.16b
	WORD $0x4eb61e94 // orr v20.16b, v20.16b, v22.16b
	WORD $0x4e909709 // sdot v9.4s, v24.16b, v16.16b
	WORD $0x4e92968d // sdot v13.4s, v20.16b, v18.16b
	WORD $0x4e3f1eb9 // and v25.16b, v21.16b, v31.16b
	WORD $0x4e3d1ef6 // and v22.16b, v23.16b, v29.16b
	WORD $0x4f0c56d6 // shl v22.16b, v22.16b, #4
	WORD $0x4eb61f39 // orr v25.16b, v25.16b, v22.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x4e3c1ef7 // and v23.16b, v23.16b, v28.16b
	WORD $0x4eb71eb5 // orr v21.16b, v21.16b, v23.16b
	WORD $0x4e919729 // sdot v9.4s, v25.16b, v17.16b
	WORD $0x4e9396ad // sdot v13.4s, v21.16b, v19.16b
	WORD $0x3cc20194 // ldur q20, [x12, #32]
	WORD $0x3cc60195 // ldur q21, [x12, #96]
	WORD $0x3cc201b6 // ldur q22, [x13, #32]
	WORD $0x3cc601b7 // ldur q23, [x13, #96]
	WORD $0x4e3f1e98 // and v24.16b, v20.16b, v31.16b
	WORD $0x4e3d1ed9 // and v25.16b, v22.16b, v29.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91f18 // orr v24.16b, v24.16b, v25.16b
	WORD $0x6f0c0694 // ushr v20.16b, v20.16b, #4
	WORD $0x4e3c1ed6 // and v22.16b, v22.16b, v28.16b
	WORD $0x4eb61e94 // orr v20.16b, v20.16b, v22.16b
	WORD $0x4e90970a // sdot v10.4s, v24.16b, v16.16b
	WORD $0x4e92968e // sdot v14.4s, v20.16b, v18.16b
	WORD $0x4e3f1eb9 // and v25.16b, v21.16b, v31.16b
	WORD $0x4e3d1ef6 // and v22.16b, v23.16b, v29.16b
	WORD $0x4f0c56d6 // shl v22.16b, v22.16b, #4
	WORD $0x4eb61f39 // orr v25.16b, v25.16b, v22.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x4e3c1ef7 // and v23.16b, v23.16b, v28.16b
	WORD $0x4eb71eb5 // orr v21.16b, v21.16b, v23.16b
	WORD $0x4e91972a // sdot v10.4s, v25.16b, v17.16b
	WORD $0x4e9396ae // sdot v14.4s, v21.16b, v19.16b
	WORD $0x3cc30194 // ldur q20, [x12, #48]
	WORD $0x3cc70195 // ldur q21, [x12, #112]
	WORD $0x3cc301b6 // ldur q22, [x13, #48]
	WORD $0x3cc701b7 // ldur q23, [x13, #112]
	WORD $0x4e3f1e98 // and v24.16b, v20.16b, v31.16b
	WORD $0x4e3d1ed9 // and v25.16b, v22.16b, v29.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91f18 // orr v24.16b, v24.16b, v25.16b
	WORD $0x6f0c0694 // ushr v20.16b, v20.16b, #4
	WORD $0x4e3c1ed6 // and v22.16b, v22.16b, v28.16b
	WORD $0x4eb61e94 // orr v20.16b, v20.16b, v22.16b
	WORD $0x4e90970b // sdot v11.4s, v24.16b, v16.16b
	WORD $0x4e92968f // sdot v15.4s, v20.16b, v18.16b
	WORD $0x4e3f1eb9 // and v25.16b, v21.16b, v31.16b
	WORD $0x4e3d1ef6 // and v22.16b, v23.16b, v29.16b
	WORD $0x4f0c56d6 // shl v22.16b, v22.16b, #4
	WORD $0x4eb61f39 // orr v25.16b, v25.16b, v22.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x4e3c1ef7 // and v23.16b, v23.16b, v28.16b
	WORD $0x4eb71eb5 // orr v21.16b, v21.16b, v23.16b
	WORD $0x4e91972b // sdot v11.4s, v25.16b, v17.16b
	WORD $0x4e9396af // sdot v15.4s, v21.16b, v19.16b
	WORD $0x4ea9bd14 // addp v20.4s, v8.4s, v9.4s
	WORD $0x4eabbd55 // addp v21.4s, v10.4s, v11.4s
	WORD $0x4eadbd96 // addp v22.4s, v12.4s, v13.4s
	WORD $0x4eafbdd7 // addp v23.4s, v14.4s, v15.4s
	WORD $0xfc458138 // ldur d24, [x9, #88]
	WORD $0xfc478139 // ldur d25, [x9, #120]
	WORD $0x0f08a718 // sshll v24.8h, v24.8b, #0
	WORD $0x0f08a739 // sshll v25.8h, v25.8b, #0
	WORD $0x0f10a708 // sshll v8.4s, v24.4h, #0
	WORD $0x4ea8969e // mla v30.4s, v20.4s, v8.4s
	WORD $0x4f10a708 // sshll2 v8.4s, v24.8h, #0
	WORD $0x4ea896a7 // mla v7.4s, v21.4s, v8.4s
	WORD $0x0f10a728 // sshll v8.4s, v25.4h, #0
	WORD $0x4ea896de // mla v30.4s, v22.4s, v8.4s
	WORD $0x4f10a728 // sshll2 v8.4s, v25.8h, #0
	WORD $0x4ea896e7 // mla v7.4s, v23.4s, v8.4s
	WORD $0x0f562304 // smlal v4.4s, v24.4h, v6.h[1]
	WORD $0x4f562305 // smlal2 v5.4s, v24.8h, v6.h[1]
	WORD $0x0f562b24 // smlal v4.4s, v25.4h, v6.h[5]
	WORD $0x4f562b25 // smlal2 v5.4s, v25.8h, v6.h[5]
	WORD $0xfc4a4150 // ldur d16, [x10, #164]
	WORD $0x4e080610 // dup v16.2d, v16.d[0]
	WORD $0xfc4ac151 // ldur d17, [x10, #172]
	WORD $0x4e080631 // dup v17.2d, v17.d[0]
	WORD $0xfc4e4152 // ldur d18, [x10, #228]
	WORD $0x4e080652 // dup v18.2d, v18.d[0]
	WORD $0xfc4ec153 // ldur d19, [x10, #236]
	WORD $0x4e080673 // dup v19.2d, v19.d[0]
	ADD	$912, R9, R12
	ADD	$1424, R9, R13
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4f00040e // movi v14.4s, #0
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x3cc00194 // ldur q20, [x12, #0]
	WORD $0x3cc40195 // ldur q21, [x12, #64]
	WORD $0x3cc001b6 // ldur q22, [x13, #0]
	WORD $0x3cc401b7 // ldur q23, [x13, #64]
	WORD $0x6f0e06d6 // ushr v22.16b, v22.16b, #2
	WORD $0x6f0e06f7 // ushr v23.16b, v23.16b, #2
	WORD $0x4e3f1e98 // and v24.16b, v20.16b, v31.16b
	WORD $0x4e3d1ed9 // and v25.16b, v22.16b, v29.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91f18 // orr v24.16b, v24.16b, v25.16b
	WORD $0x6f0c0694 // ushr v20.16b, v20.16b, #4
	WORD $0x4e3c1ed6 // and v22.16b, v22.16b, v28.16b
	WORD $0x4eb61e94 // orr v20.16b, v20.16b, v22.16b
	WORD $0x4e909708 // sdot v8.4s, v24.16b, v16.16b
	WORD $0x4e92968c // sdot v12.4s, v20.16b, v18.16b
	WORD $0x4e3f1eb9 // and v25.16b, v21.16b, v31.16b
	WORD $0x4e3d1ef6 // and v22.16b, v23.16b, v29.16b
	WORD $0x4f0c56d6 // shl v22.16b, v22.16b, #4
	WORD $0x4eb61f39 // orr v25.16b, v25.16b, v22.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x4e3c1ef7 // and v23.16b, v23.16b, v28.16b
	WORD $0x4eb71eb5 // orr v21.16b, v21.16b, v23.16b
	WORD $0x4e919728 // sdot v8.4s, v25.16b, v17.16b
	WORD $0x4e9396ac // sdot v12.4s, v21.16b, v19.16b
	WORD $0x3cc10194 // ldur q20, [x12, #16]
	WORD $0x3cc50195 // ldur q21, [x12, #80]
	WORD $0x3cc101b6 // ldur q22, [x13, #16]
	WORD $0x3cc501b7 // ldur q23, [x13, #80]
	WORD $0x6f0e06d6 // ushr v22.16b, v22.16b, #2
	WORD $0x6f0e06f7 // ushr v23.16b, v23.16b, #2
	WORD $0x4e3f1e98 // and v24.16b, v20.16b, v31.16b
	WORD $0x4e3d1ed9 // and v25.16b, v22.16b, v29.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91f18 // orr v24.16b, v24.16b, v25.16b
	WORD $0x6f0c0694 // ushr v20.16b, v20.16b, #4
	WORD $0x4e3c1ed6 // and v22.16b, v22.16b, v28.16b
	WORD $0x4eb61e94 // orr v20.16b, v20.16b, v22.16b
	WORD $0x4e909709 // sdot v9.4s, v24.16b, v16.16b
	WORD $0x4e92968d // sdot v13.4s, v20.16b, v18.16b
	WORD $0x4e3f1eb9 // and v25.16b, v21.16b, v31.16b
	WORD $0x4e3d1ef6 // and v22.16b, v23.16b, v29.16b
	WORD $0x4f0c56d6 // shl v22.16b, v22.16b, #4
	WORD $0x4eb61f39 // orr v25.16b, v25.16b, v22.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x4e3c1ef7 // and v23.16b, v23.16b, v28.16b
	WORD $0x4eb71eb5 // orr v21.16b, v21.16b, v23.16b
	WORD $0x4e919729 // sdot v9.4s, v25.16b, v17.16b
	WORD $0x4e9396ad // sdot v13.4s, v21.16b, v19.16b
	WORD $0x3cc20194 // ldur q20, [x12, #32]
	WORD $0x3cc60195 // ldur q21, [x12, #96]
	WORD $0x3cc201b6 // ldur q22, [x13, #32]
	WORD $0x3cc601b7 // ldur q23, [x13, #96]
	WORD $0x6f0e06d6 // ushr v22.16b, v22.16b, #2
	WORD $0x6f0e06f7 // ushr v23.16b, v23.16b, #2
	WORD $0x4e3f1e98 // and v24.16b, v20.16b, v31.16b
	WORD $0x4e3d1ed9 // and v25.16b, v22.16b, v29.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91f18 // orr v24.16b, v24.16b, v25.16b
	WORD $0x6f0c0694 // ushr v20.16b, v20.16b, #4
	WORD $0x4e3c1ed6 // and v22.16b, v22.16b, v28.16b
	WORD $0x4eb61e94 // orr v20.16b, v20.16b, v22.16b
	WORD $0x4e90970a // sdot v10.4s, v24.16b, v16.16b
	WORD $0x4e92968e // sdot v14.4s, v20.16b, v18.16b
	WORD $0x4e3f1eb9 // and v25.16b, v21.16b, v31.16b
	WORD $0x4e3d1ef6 // and v22.16b, v23.16b, v29.16b
	WORD $0x4f0c56d6 // shl v22.16b, v22.16b, #4
	WORD $0x4eb61f39 // orr v25.16b, v25.16b, v22.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x4e3c1ef7 // and v23.16b, v23.16b, v28.16b
	WORD $0x4eb71eb5 // orr v21.16b, v21.16b, v23.16b
	WORD $0x4e91972a // sdot v10.4s, v25.16b, v17.16b
	WORD $0x4e9396ae // sdot v14.4s, v21.16b, v19.16b
	WORD $0x3cc30194 // ldur q20, [x12, #48]
	WORD $0x3cc70195 // ldur q21, [x12, #112]
	WORD $0x3cc301b6 // ldur q22, [x13, #48]
	WORD $0x3cc701b7 // ldur q23, [x13, #112]
	WORD $0x6f0e06d6 // ushr v22.16b, v22.16b, #2
	WORD $0x6f0e06f7 // ushr v23.16b, v23.16b, #2
	WORD $0x4e3f1e98 // and v24.16b, v20.16b, v31.16b
	WORD $0x4e3d1ed9 // and v25.16b, v22.16b, v29.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91f18 // orr v24.16b, v24.16b, v25.16b
	WORD $0x6f0c0694 // ushr v20.16b, v20.16b, #4
	WORD $0x4e3c1ed6 // and v22.16b, v22.16b, v28.16b
	WORD $0x4eb61e94 // orr v20.16b, v20.16b, v22.16b
	WORD $0x4e90970b // sdot v11.4s, v24.16b, v16.16b
	WORD $0x4e92968f // sdot v15.4s, v20.16b, v18.16b
	WORD $0x4e3f1eb9 // and v25.16b, v21.16b, v31.16b
	WORD $0x4e3d1ef6 // and v22.16b, v23.16b, v29.16b
	WORD $0x4f0c56d6 // shl v22.16b, v22.16b, #4
	WORD $0x4eb61f39 // orr v25.16b, v25.16b, v22.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x4e3c1ef7 // and v23.16b, v23.16b, v28.16b
	WORD $0x4eb71eb5 // orr v21.16b, v21.16b, v23.16b
	WORD $0x4e91972b // sdot v11.4s, v25.16b, v17.16b
	WORD $0x4e9396af // sdot v15.4s, v21.16b, v19.16b
	WORD $0x4ea9bd14 // addp v20.4s, v8.4s, v9.4s
	WORD $0x4eabbd55 // addp v21.4s, v10.4s, v11.4s
	WORD $0x4eadbd96 // addp v22.4s, v12.4s, v13.4s
	WORD $0x4eafbdd7 // addp v23.4s, v14.4s, v15.4s
	WORD $0xfc460138 // ldur d24, [x9, #96]
	WORD $0xfc480139 // ldur d25, [x9, #128]
	WORD $0x0f08a718 // sshll v24.8h, v24.8b, #0
	WORD $0x0f08a739 // sshll v25.8h, v25.8b, #0
	WORD $0x0f10a708 // sshll v8.4s, v24.4h, #0
	WORD $0x4ea8969e // mla v30.4s, v20.4s, v8.4s
	WORD $0x4f10a708 // sshll2 v8.4s, v24.8h, #0
	WORD $0x4ea896a7 // mla v7.4s, v21.4s, v8.4s
	WORD $0x0f10a728 // sshll v8.4s, v25.4h, #0
	WORD $0x4ea896de // mla v30.4s, v22.4s, v8.4s
	WORD $0x4f10a728 // sshll2 v8.4s, v25.8h, #0
	WORD $0x4ea896e7 // mla v7.4s, v23.4s, v8.4s
	WORD $0x0f662304 // smlal v4.4s, v24.4h, v6.h[2]
	WORD $0x4f662305 // smlal2 v5.4s, v24.8h, v6.h[2]
	WORD $0x0f662b24 // smlal v4.4s, v25.4h, v6.h[6]
	WORD $0x4f662b25 // smlal2 v5.4s, v25.8h, v6.h[6]
	WORD $0xfc4b4150 // ldur d16, [x10, #180]
	WORD $0x4e080610 // dup v16.2d, v16.d[0]
	WORD $0xfc4bc151 // ldur d17, [x10, #188]
	WORD $0x4e080631 // dup v17.2d, v17.d[0]
	WORD $0xfc4f4152 // ldur d18, [x10, #244]
	WORD $0x4e080652 // dup v18.2d, v18.d[0]
	WORD $0xfc4fc153 // ldur d19, [x10, #252]
	WORD $0x4e080673 // dup v19.2d, v19.d[0]
	ADD	$1040, R9, R12
	ADD	$1552, R9, R13
	WORD $0x4f000408 // movi v8.4s, #0
	WORD $0x4f000409 // movi v9.4s, #0
	WORD $0x4f00040a // movi v10.4s, #0
	WORD $0x4f00040b // movi v11.4s, #0
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4f00040d // movi v13.4s, #0
	WORD $0x4f00040e // movi v14.4s, #0
	WORD $0x4f00040f // movi v15.4s, #0
	WORD $0x3cc00194 // ldur q20, [x12, #0]
	WORD $0x3cc40195 // ldur q21, [x12, #64]
	WORD $0x3cc001b6 // ldur q22, [x13, #0]
	WORD $0x3cc401b7 // ldur q23, [x13, #64]
	WORD $0x6f0e06d6 // ushr v22.16b, v22.16b, #2
	WORD $0x6f0e06f7 // ushr v23.16b, v23.16b, #2
	WORD $0x4e3f1e98 // and v24.16b, v20.16b, v31.16b
	WORD $0x4e3d1ed9 // and v25.16b, v22.16b, v29.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91f18 // orr v24.16b, v24.16b, v25.16b
	WORD $0x6f0c0694 // ushr v20.16b, v20.16b, #4
	WORD $0x4e3c1ed6 // and v22.16b, v22.16b, v28.16b
	WORD $0x4eb61e94 // orr v20.16b, v20.16b, v22.16b
	WORD $0x4e909708 // sdot v8.4s, v24.16b, v16.16b
	WORD $0x4e92968c // sdot v12.4s, v20.16b, v18.16b
	WORD $0x4e3f1eb9 // and v25.16b, v21.16b, v31.16b
	WORD $0x4e3d1ef6 // and v22.16b, v23.16b, v29.16b
	WORD $0x4f0c56d6 // shl v22.16b, v22.16b, #4
	WORD $0x4eb61f39 // orr v25.16b, v25.16b, v22.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x4e3c1ef7 // and v23.16b, v23.16b, v28.16b
	WORD $0x4eb71eb5 // orr v21.16b, v21.16b, v23.16b
	WORD $0x4e919728 // sdot v8.4s, v25.16b, v17.16b
	WORD $0x4e9396ac // sdot v12.4s, v21.16b, v19.16b
	WORD $0x3cc10194 // ldur q20, [x12, #16]
	WORD $0x3cc50195 // ldur q21, [x12, #80]
	WORD $0x3cc101b6 // ldur q22, [x13, #16]
	WORD $0x3cc501b7 // ldur q23, [x13, #80]
	WORD $0x6f0e06d6 // ushr v22.16b, v22.16b, #2
	WORD $0x6f0e06f7 // ushr v23.16b, v23.16b, #2
	WORD $0x4e3f1e98 // and v24.16b, v20.16b, v31.16b
	WORD $0x4e3d1ed9 // and v25.16b, v22.16b, v29.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91f18 // orr v24.16b, v24.16b, v25.16b
	WORD $0x6f0c0694 // ushr v20.16b, v20.16b, #4
	WORD $0x4e3c1ed6 // and v22.16b, v22.16b, v28.16b
	WORD $0x4eb61e94 // orr v20.16b, v20.16b, v22.16b
	WORD $0x4e909709 // sdot v9.4s, v24.16b, v16.16b
	WORD $0x4e92968d // sdot v13.4s, v20.16b, v18.16b
	WORD $0x4e3f1eb9 // and v25.16b, v21.16b, v31.16b
	WORD $0x4e3d1ef6 // and v22.16b, v23.16b, v29.16b
	WORD $0x4f0c56d6 // shl v22.16b, v22.16b, #4
	WORD $0x4eb61f39 // orr v25.16b, v25.16b, v22.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x4e3c1ef7 // and v23.16b, v23.16b, v28.16b
	WORD $0x4eb71eb5 // orr v21.16b, v21.16b, v23.16b
	WORD $0x4e919729 // sdot v9.4s, v25.16b, v17.16b
	WORD $0x4e9396ad // sdot v13.4s, v21.16b, v19.16b
	WORD $0x3cc20194 // ldur q20, [x12, #32]
	WORD $0x3cc60195 // ldur q21, [x12, #96]
	WORD $0x3cc201b6 // ldur q22, [x13, #32]
	WORD $0x3cc601b7 // ldur q23, [x13, #96]
	WORD $0x6f0e06d6 // ushr v22.16b, v22.16b, #2
	WORD $0x6f0e06f7 // ushr v23.16b, v23.16b, #2
	WORD $0x4e3f1e98 // and v24.16b, v20.16b, v31.16b
	WORD $0x4e3d1ed9 // and v25.16b, v22.16b, v29.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91f18 // orr v24.16b, v24.16b, v25.16b
	WORD $0x6f0c0694 // ushr v20.16b, v20.16b, #4
	WORD $0x4e3c1ed6 // and v22.16b, v22.16b, v28.16b
	WORD $0x4eb61e94 // orr v20.16b, v20.16b, v22.16b
	WORD $0x4e90970a // sdot v10.4s, v24.16b, v16.16b
	WORD $0x4e92968e // sdot v14.4s, v20.16b, v18.16b
	WORD $0x4e3f1eb9 // and v25.16b, v21.16b, v31.16b
	WORD $0x4e3d1ef6 // and v22.16b, v23.16b, v29.16b
	WORD $0x4f0c56d6 // shl v22.16b, v22.16b, #4
	WORD $0x4eb61f39 // orr v25.16b, v25.16b, v22.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x4e3c1ef7 // and v23.16b, v23.16b, v28.16b
	WORD $0x4eb71eb5 // orr v21.16b, v21.16b, v23.16b
	WORD $0x4e91972a // sdot v10.4s, v25.16b, v17.16b
	WORD $0x4e9396ae // sdot v14.4s, v21.16b, v19.16b
	WORD $0x3cc30194 // ldur q20, [x12, #48]
	WORD $0x3cc70195 // ldur q21, [x12, #112]
	WORD $0x3cc301b6 // ldur q22, [x13, #48]
	WORD $0x3cc701b7 // ldur q23, [x13, #112]
	WORD $0x6f0e06d6 // ushr v22.16b, v22.16b, #2
	WORD $0x6f0e06f7 // ushr v23.16b, v23.16b, #2
	WORD $0x4e3f1e98 // and v24.16b, v20.16b, v31.16b
	WORD $0x4e3d1ed9 // and v25.16b, v22.16b, v29.16b
	WORD $0x4f0c5739 // shl v25.16b, v25.16b, #4
	WORD $0x4eb91f18 // orr v24.16b, v24.16b, v25.16b
	WORD $0x6f0c0694 // ushr v20.16b, v20.16b, #4
	WORD $0x4e3c1ed6 // and v22.16b, v22.16b, v28.16b
	WORD $0x4eb61e94 // orr v20.16b, v20.16b, v22.16b
	WORD $0x4e90970b // sdot v11.4s, v24.16b, v16.16b
	WORD $0x4e92968f // sdot v15.4s, v20.16b, v18.16b
	WORD $0x4e3f1eb9 // and v25.16b, v21.16b, v31.16b
	WORD $0x4e3d1ef6 // and v22.16b, v23.16b, v29.16b
	WORD $0x4f0c56d6 // shl v22.16b, v22.16b, #4
	WORD $0x4eb61f39 // orr v25.16b, v25.16b, v22.16b
	WORD $0x6f0c06b5 // ushr v21.16b, v21.16b, #4
	WORD $0x4e3c1ef7 // and v23.16b, v23.16b, v28.16b
	WORD $0x4eb71eb5 // orr v21.16b, v21.16b, v23.16b
	WORD $0x4e91972b // sdot v11.4s, v25.16b, v17.16b
	WORD $0x4e9396af // sdot v15.4s, v21.16b, v19.16b
	WORD $0x4ea9bd14 // addp v20.4s, v8.4s, v9.4s
	WORD $0x4eabbd55 // addp v21.4s, v10.4s, v11.4s
	WORD $0x4eadbd96 // addp v22.4s, v12.4s, v13.4s
	WORD $0x4eafbdd7 // addp v23.4s, v14.4s, v15.4s
	WORD $0xfc468138 // ldur d24, [x9, #104]
	WORD $0xfc488139 // ldur d25, [x9, #136]
	WORD $0x0f08a718 // sshll v24.8h, v24.8b, #0
	WORD $0x0f08a739 // sshll v25.8h, v25.8b, #0
	WORD $0x0f10a708 // sshll v8.4s, v24.4h, #0
	WORD $0x4ea8969e // mla v30.4s, v20.4s, v8.4s
	WORD $0x4f10a708 // sshll2 v8.4s, v24.8h, #0
	WORD $0x4ea896a7 // mla v7.4s, v21.4s, v8.4s
	WORD $0x0f10a728 // sshll v8.4s, v25.4h, #0
	WORD $0x4ea896de // mla v30.4s, v22.4s, v8.4s
	WORD $0x4f10a728 // sshll2 v8.4s, v25.8h, #0
	WORD $0x4ea896e7 // mla v7.4s, v23.4s, v8.4s
	WORD $0x0f762304 // smlal v4.4s, v24.4h, v6.h[3]
	WORD $0x4f762305 // smlal2 v5.4s, v24.8h, v6.h[3]
	WORD $0x0f762b24 // smlal v4.4s, v25.4h, v6.h[7]
	WORD $0x4f762b25 // smlal2 v5.4s, v25.8h, v6.h[7]
	WORD $0x4f255484 // shl v4.4s, v4.4s, #5
	WORD $0x4f2554a5 // shl v5.4s, v5.4s, #5
	WORD $0x6ea487de // sub v30.4s, v30.4s, v4.4s
	WORD $0x6ea584e7 // sub v7.4s, v7.4s, v5.4s
	WORD $0x4e21dbde // scvtf v30.4s, v30.4s
	WORD $0x4e21d8e7 // scvtf v7.4s, v7.4s
	WORD $0x4e22cfc0 // fmla v0.4s, v30.4s, v2.4s
	WORD $0x4e23cce1 // fmla v1.4s, v7.4s, v3.4s
	ADD	$1680, R9, R9
	ADD	$292, R10, R10
	SUBW	$1, R8, R8
	CBNZW	R8, g6blk
g6store:
	WORD $0x3c800040 // stur q0, [x2, #0]
	WORD $0x3c810041 // stur q1, [x2, #16]
	ADD	$32, R2, R2
	ADD	R3, R6, R3
	SUBW	$1, R7, R7
	CBNZW	R7, g6group
g6done:
	RET
g6oob:
	B	ovr_oob
