.cseg
	jmp main


main:
	; copy two 32-bit values from FLASH into SRAM
	ldi zh, high(pmv1*2)
	ldi zl, low(pmv1*2)

	ldi xh, high(value1)
	ldi xl, low(value1)

	ldi r16, 8
	rcall copybytes

	; multiply value1 * value2
	rcall mul32bit


fin:
	rjmp fin

mul32bit:

	; clear 64-bit product
	ldi xh, high(product)
	ldi xl, low(product)
	ldi r16, 8
	clr r20

mulclr:
	st x+, r20 ; set all of result sram to 00
	dec r16
	brne mulclr


	; byte 3 * byte 3, MSB first
	lds r20, value1+3
	lds r21, value2+3
	mul r20, r21			; r1:r0 is the product (it is 16 bits)

	lds r22, product+7 ; LSB
	add r22, r0		   ; r0 has LSB of product. no carry yet
	sts product+7, r22

	lds r22, product+6 ; second LSB
	adc r22, r1        ; r1 has MSB of product. no carry yet
	sts product+6, r22


	; byte 3 * byte 2
	lds r20, value1+3
	lds r21, value2+2
	mul r20, r21

	lds r22, product+6
	add r22, r0
	sts product+6, r22

	lds r22, product+5
	adc r22, r1
	sts product+5, r22

	ldi r23, 0
	lds r22, product+4
	adc r22, r23
	sts product+4, r22


	; byte 3 * byte 1
	lds r20, value1+3
	lds r21, value2+1
	mul r20, r21

	lds r22, product+5
	add r22, r0
	sts product+5, r22

	lds r22, product+4
	adc r22, r1
	sts product+4, r22

	ldi r23, 0
	lds r22, product+3
	adc r22, r23
	sts product+3, r22


	; byte 3 * byte 0
	lds r20, value1+3
	lds r21, value2
	mul r20, r21

	lds r22, product+4
	add r22, r0
	sts product+4, r22

	lds r22, product+3
	adc r22, r1
	sts product+3, r22

	ldi r23, 0
	lds r22, product+2
	adc r22, r23
	sts product+2, r22


	; byte 2 * byte 3
	lds r20, value1+2
	lds r21, value2+3
	mul r20, r21

	lds r22, product+6
	add r22, r0
	sts product+6, r22

	lds r22, product+5
	adc r22, r1
	sts product+5, r22

	ldi r23, 0
	lds r22, product+4
	adc r22, r23
	sts product+4, r22


	; byte 2 * byte 2
	lds r20, value1+2
	lds r21, value2+2
	mul r20, r21

	lds r22, product+5
	add r22, r0
	sts product+5, r22

	lds r22, product+4
	adc r22, r1
	sts product+4, r22

	ldi r23, 0
	lds r22, product+3
	adc r22, r23
	sts product+3, r22


	; byte 2 * byte 1
	lds r20, value1+2
	lds r21, value2+1
	mul r20, r21

	lds r22, product+4
	add r22, r0
	sts product+4, r22

	lds r22, product+3
	adc r22, r1
	sts product+3, r22

	ldi r23, 0
	lds r22, product+2
	adc r22, r23
	sts product+2, r22


	; byte 2 * byte 0
	lds r20, value1+2
	lds r21, value2
	mul r20, r21

	lds r22, product+3
	add r22, r0
	sts product+3, r22

	lds r22, product+2
	adc r22, r1
	sts product+2, r22

	ldi r23, 0
	lds r22, product+1
	adc r22, r23
	sts product+1, r22


	; byte 1 * byte 3
	lds r20, value1+1
	lds r21, value2+3
	mul r20, r21

	lds r22, product+5
	add r22, r0
	sts product+5, r22

	lds r22, product+4
	adc r22, r1
	sts product+4, r22

	ldi r23, 0
	lds r22, product+3
	adc r22, r23
	sts product+3, r22


	; byte 1 * byte 2
	lds r20, value1+1
	lds r21, value2+2
	mul r20, r21

	lds r22, product+4
	add r22, r0
	sts product+4, r22

	lds r22, product+3
	adc r22, r1
	sts product+3, r22

	ldi r23, 0
	lds r22, product+2
	adc r22, r23
	sts product+2, r22


	; byte 1 * byte 1
	lds r20, value1+1
	lds r21, value2+1
	mul r20, r21

	lds r22, product+3
	add r22, r0
	sts product+3, r22

	lds r22, product+2
	adc r22, r1
	sts product+2, r22

	ldi r23, 0
	lds r22, product+1
	adc r22, r23
	sts product+1, r22


	; byte 1 * byte 0
	lds r20, value1+1
	lds r21, value2
	mul r20, r21

	lds r22, product+2
	add r22, r0
	sts product+2, r22

	lds r22, product+1
	adc r22, r1
	sts product+1, r22

	ldi r23, 0
	lds r22, product
	adc r22, r23
	sts product, r22


	; byte 0 * byte 3
	lds r20, value1
	lds r21, value2+3
	mul r20, r21

	lds r22, product+4
	add r22, r0
	sts product+4, r22

	lds r22, product+3
	adc r22, r1
	sts product+3, r22

	ldi r23, 0
	lds r22, product+2
	adc r22, r23
	sts product+2, r22


	; byte 0 * byte 2
	lds r20, value1
	lds r21, value2+2
	mul r20, r21

	lds r22, product+3
	add r22, r0
	sts product+3, r22

	lds r22, product+2
	adc r22, r1
	sts product+2, r22

	ldi r23, 0
	lds r22, product+1
	adc r22, r23
	sts product+1, r22


	; byte 0 * byte 1
	lds r20, value1
	lds r21, value2+1
	mul r20, r21

	lds r22, product+2
	add r22, r0
	sts product+2, r22

	lds r22, product+1
	adc r22, r1
	sts product+1, r22

	ldi r23, 0
	lds r22, product
	adc r22, r23
	sts product, r22


	; byte 0 * byte 0
	lds r20, value1
	lds r21, value2
	mul r20, r21

	lds r22, product+1
	add r22, r0
	sts product+1, r22

	lds r22, product
	adc r22, r1
	sts product, r22


	; MUL writes to r1:r0
	; restore r1 to zero
	clr r1

	ret


copybytes:
	lpm r0, z+
	st x+, r0
	dec r16
	brne copybytes
	ret

pmv1:
	.db 0x00, 0x00, 0x0F, 0xFF
	.db 0x00, 0x00, 0x01, 0x11


	.dseg

value1:.byte 4
value2:.byte 4
product:.byte 8