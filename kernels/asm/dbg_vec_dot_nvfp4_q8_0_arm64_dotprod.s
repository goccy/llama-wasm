// dbg_vec_dot_nvfp4_q8_0: nvfp4 x q8_0 dot, fp4 nibbles through TBL, UE4M3 sub-block scales through a table.
	WORD $0x4f000400 // movi v0.4s, #0
	MOVW	l0+8(FP), R1
	LSRW	$6, R1, R1
	MOVD	l1+16(FP), R2
	ADD	$4, R2, R27
	CMP	R27, R21
	BLO	nvoob
	ADD	R20, R2, R2
	CBZW	R1, nvreduce
	MOVD	l3+32(FP), R3
	MOVD	l5+48(FP), R4
	MOVD	$36, R26
	MUL	R1, R26, R26
	ADD	R3, R26, R27
	CMP	R27, R21
	BLO	nvoob
	MOVD	$68, R26
	MUL	R1, R26, R26
	ADD	R4, R26, R27
	CMP	R27, R21
	BLO	nvoob
	ADD	R20, R3, R3
	ADD	R20, R4, R4
	MOVD	$·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf(SB), R12
	ADD	$1024, R12, R13
	WORD $0x3cc001b2 // ldur q18, [x13, #0]
	WORD $0x4f00e5f0 // movi v16.16b, #15
nvblk:
	WORD $0xfc404062 // ldur d2, [x3, #4]
	WORD $0x4e301c44 // and v4.16b, v2.16b, v16.16b
	WORD $0x6f0c0445 // ushr v5.16b, v2.16b, #4
	WORD $0x4e040244 // tbl v4.16b, {v18.16b}, v4.16b
	WORD $0x4e050245 // tbl v5.16b, {v18.16b}, v5.16b
	WORD $0xfc402086 // ldur d6, [x4, #2]
	WORD $0xfc40a087 // ldur d7, [x4, #10]
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e86948c // sdot v12.4s, v4.16b, v6.16b
	WORD $0x4e8794ac // sdot v12.4s, v5.16b, v7.16b
	WORD $0x4eb1b98c // addv s12, v12.4s
	WORD $0x4e21d98c // scvtf v12.4s, v12.4s
	MOVBU	0(R3), R5
	MOVWU	(R12)(R5<<2), R5
	WORD $0x1e2700b6 // fmov s22, w5
	WORD $0x7c400097 // ldur h23, [x4, #0]
	WORD $0x1ee242f7 // fcvt s23, h23
	WORD $0x1e370ad6 // fmul s22, s22, s23
	WORD $0x4f961180 // fmla v0.4s, v12.4s, v22.s[0]
	WORD $0xfc40c062 // ldur d2, [x3, #12]
	WORD $0x4e301c44 // and v4.16b, v2.16b, v16.16b
	WORD $0x6f0c0445 // ushr v5.16b, v2.16b, #4
	WORD $0x4e040244 // tbl v4.16b, {v18.16b}, v4.16b
	WORD $0x4e050245 // tbl v5.16b, {v18.16b}, v5.16b
	WORD $0xfc412086 // ldur d6, [x4, #18]
	WORD $0xfc41a087 // ldur d7, [x4, #26]
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e86948c // sdot v12.4s, v4.16b, v6.16b
	WORD $0x4e8794ac // sdot v12.4s, v5.16b, v7.16b
	WORD $0x4eb1b98c // addv s12, v12.4s
	WORD $0x4e21d98c // scvtf v12.4s, v12.4s
	MOVBU	1(R3), R5
	MOVWU	(R12)(R5<<2), R5
	WORD $0x1e2700b6 // fmov s22, w5
	WORD $0x7c400097 // ldur h23, [x4, #0]
	WORD $0x1ee242f7 // fcvt s23, h23
	WORD $0x1e370ad6 // fmul s22, s22, s23
	WORD $0x4f961180 // fmla v0.4s, v12.4s, v22.s[0]
	WORD $0xfc414062 // ldur d2, [x3, #20]
	WORD $0x4e301c44 // and v4.16b, v2.16b, v16.16b
	WORD $0x6f0c0445 // ushr v5.16b, v2.16b, #4
	WORD $0x4e040244 // tbl v4.16b, {v18.16b}, v4.16b
	WORD $0x4e050245 // tbl v5.16b, {v18.16b}, v5.16b
	WORD $0xfc424086 // ldur d6, [x4, #36]
	WORD $0xfc42c087 // ldur d7, [x4, #44]
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e86948c // sdot v12.4s, v4.16b, v6.16b
	WORD $0x4e8794ac // sdot v12.4s, v5.16b, v7.16b
	WORD $0x4eb1b98c // addv s12, v12.4s
	WORD $0x4e21d98c // scvtf v12.4s, v12.4s
	MOVBU	2(R3), R5
	MOVWU	(R12)(R5<<2), R5
	WORD $0x1e2700b6 // fmov s22, w5
	WORD $0x7c422097 // ldur h23, [x4, #34]
	WORD $0x1ee242f7 // fcvt s23, h23
	WORD $0x1e370ad6 // fmul s22, s22, s23
	WORD $0x4f961180 // fmla v0.4s, v12.4s, v22.s[0]
	WORD $0xfc41c062 // ldur d2, [x3, #28]
	WORD $0x4e301c44 // and v4.16b, v2.16b, v16.16b
	WORD $0x6f0c0445 // ushr v5.16b, v2.16b, #4
	WORD $0x4e040244 // tbl v4.16b, {v18.16b}, v4.16b
	WORD $0x4e050245 // tbl v5.16b, {v18.16b}, v5.16b
	WORD $0xfc434086 // ldur d6, [x4, #52]
	WORD $0xfc43c087 // ldur d7, [x4, #60]
	WORD $0x4f00040c // movi v12.4s, #0
	WORD $0x4e86948c // sdot v12.4s, v4.16b, v6.16b
	WORD $0x4e8794ac // sdot v12.4s, v5.16b, v7.16b
	WORD $0x4eb1b98c // addv s12, v12.4s
	WORD $0x4e21d98c // scvtf v12.4s, v12.4s
	MOVBU	3(R3), R5
	MOVWU	(R12)(R5<<2), R5
	WORD $0x1e2700b6 // fmov s22, w5
	WORD $0x7c422097 // ldur h23, [x4, #34]
	WORD $0x1ee242f7 // fcvt s23, h23
	WORD $0x1e370ad6 // fmul s22, s22, s23
	WORD $0x4f961180 // fmla v0.4s, v12.4s, v22.s[0]
	ADD	$36, R3, R3
	ADD	$68, R4, R4
	SUBW	$1, R1, R1
	CBNZW	R1, nvblk
nvreduce:
	WORD $0x6e20d400 // faddp v0.4s, v0.4s, v0.4s
	WORD $0x7e30d800 // faddp s0, v0.2s
	FMOVS	F0, (R2)
	RET
nvoob:
	B	ovr_oob

DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+0(SB)/8, $0x3a80000000000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+8(SB)/8, $0x3b4000003b000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+16(SB)/8, $0x3ba000003b800000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+24(SB)/8, $0x3be000003bc00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+32(SB)/8, $0x3c1000003c000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+40(SB)/8, $0x3c3000003c200000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+48(SB)/8, $0x3c5000003c400000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+56(SB)/8, $0x3c7000003c600000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+64(SB)/8, $0x3c9000003c800000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+72(SB)/8, $0x3cb000003ca00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+80(SB)/8, $0x3cd000003cc00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+88(SB)/8, $0x3cf000003ce00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+96(SB)/8, $0x3d1000003d000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+104(SB)/8, $0x3d3000003d200000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+112(SB)/8, $0x3d5000003d400000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+120(SB)/8, $0x3d7000003d600000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+128(SB)/8, $0x3d9000003d800000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+136(SB)/8, $0x3db000003da00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+144(SB)/8, $0x3dd000003dc00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+152(SB)/8, $0x3df000003de00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+160(SB)/8, $0x3e1000003e000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+168(SB)/8, $0x3e3000003e200000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+176(SB)/8, $0x3e5000003e400000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+184(SB)/8, $0x3e7000003e600000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+192(SB)/8, $0x3e9000003e800000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+200(SB)/8, $0x3eb000003ea00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+208(SB)/8, $0x3ed000003ec00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+216(SB)/8, $0x3ef000003ee00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+224(SB)/8, $0x3f1000003f000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+232(SB)/8, $0x3f3000003f200000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+240(SB)/8, $0x3f5000003f400000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+248(SB)/8, $0x3f7000003f600000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+256(SB)/8, $0x3f9000003f800000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+264(SB)/8, $0x3fb000003fa00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+272(SB)/8, $0x3fd000003fc00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+280(SB)/8, $0x3ff000003fe00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+288(SB)/8, $0x4010000040000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+296(SB)/8, $0x4030000040200000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+304(SB)/8, $0x4050000040400000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+312(SB)/8, $0x4070000040600000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+320(SB)/8, $0x4090000040800000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+328(SB)/8, $0x40b0000040a00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+336(SB)/8, $0x40d0000040c00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+344(SB)/8, $0x40f0000040e00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+352(SB)/8, $0x4110000041000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+360(SB)/8, $0x4130000041200000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+368(SB)/8, $0x4150000041400000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+376(SB)/8, $0x4170000041600000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+384(SB)/8, $0x4190000041800000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+392(SB)/8, $0x41b0000041a00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+400(SB)/8, $0x41d0000041c00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+408(SB)/8, $0x41f0000041e00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+416(SB)/8, $0x4210000042000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+424(SB)/8, $0x4230000042200000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+432(SB)/8, $0x4250000042400000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+440(SB)/8, $0x4270000042600000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+448(SB)/8, $0x4290000042800000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+456(SB)/8, $0x42b0000042a00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+464(SB)/8, $0x42d0000042c00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+472(SB)/8, $0x42f0000042e00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+480(SB)/8, $0x4310000043000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+488(SB)/8, $0x4330000043200000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+496(SB)/8, $0x4350000043400000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+504(SB)/8, $0x43600000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+512(SB)/8, $0x3a80000000000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+520(SB)/8, $0x3b4000003b000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+528(SB)/8, $0x3ba000003b800000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+536(SB)/8, $0x3be000003bc00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+544(SB)/8, $0x3c1000003c000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+552(SB)/8, $0x3c3000003c200000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+560(SB)/8, $0x3c5000003c400000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+568(SB)/8, $0x3c7000003c600000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+576(SB)/8, $0x3c9000003c800000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+584(SB)/8, $0x3cb000003ca00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+592(SB)/8, $0x3cd000003cc00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+600(SB)/8, $0x3cf000003ce00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+608(SB)/8, $0x3d1000003d000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+616(SB)/8, $0x3d3000003d200000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+624(SB)/8, $0x3d5000003d400000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+632(SB)/8, $0x3d7000003d600000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+640(SB)/8, $0x3d9000003d800000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+648(SB)/8, $0x3db000003da00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+656(SB)/8, $0x3dd000003dc00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+664(SB)/8, $0x3df000003de00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+672(SB)/8, $0x3e1000003e000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+680(SB)/8, $0x3e3000003e200000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+688(SB)/8, $0x3e5000003e400000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+696(SB)/8, $0x3e7000003e600000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+704(SB)/8, $0x3e9000003e800000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+712(SB)/8, $0x3eb000003ea00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+720(SB)/8, $0x3ed000003ec00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+728(SB)/8, $0x3ef000003ee00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+736(SB)/8, $0x3f1000003f000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+744(SB)/8, $0x3f3000003f200000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+752(SB)/8, $0x3f5000003f400000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+760(SB)/8, $0x3f7000003f600000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+768(SB)/8, $0x3f9000003f800000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+776(SB)/8, $0x3fb000003fa00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+784(SB)/8, $0x3fd000003fc00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+792(SB)/8, $0x3ff000003fe00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+800(SB)/8, $0x4010000040000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+808(SB)/8, $0x4030000040200000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+816(SB)/8, $0x4050000040400000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+824(SB)/8, $0x4070000040600000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+832(SB)/8, $0x4090000040800000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+840(SB)/8, $0x40b0000040a00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+848(SB)/8, $0x40d0000040c00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+856(SB)/8, $0x40f0000040e00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+864(SB)/8, $0x4110000041000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+872(SB)/8, $0x4130000041200000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+880(SB)/8, $0x4150000041400000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+888(SB)/8, $0x4170000041600000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+896(SB)/8, $0x4190000041800000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+904(SB)/8, $0x41b0000041a00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+912(SB)/8, $0x41d0000041c00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+920(SB)/8, $0x41f0000041e00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+928(SB)/8, $0x4210000042000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+936(SB)/8, $0x4230000042200000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+944(SB)/8, $0x4250000042400000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+952(SB)/8, $0x4270000042600000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+960(SB)/8, $0x4290000042800000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+968(SB)/8, $0x42b0000042a00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+976(SB)/8, $0x42d0000042c00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+984(SB)/8, $0x42f0000042e00000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+992(SB)/8, $0x4310000043000000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+1000(SB)/8, $0x4330000043200000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+1008(SB)/8, $0x4350000043400000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+1016(SB)/8, $0x4370000043600000
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+1024(SB)/8, $0xc08060403020100
DATA ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf+1032(SB)/8, $0xf4f8fafcfdfeff00
GLOBL ·ovr_dbg_vec_dot_nvfp4_q8_0_dotprod_b1040_c1740f79b0d9ccaf(SB), RODATA|NOPTR, $1040
