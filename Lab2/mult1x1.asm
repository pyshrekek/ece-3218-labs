; mult1x1.asm
; 8-bit x 8-bit unsigned multiply, shift-and-add, no MUL

	.cseg
	.org 0x0000
	jmp main

main:
	ldi r16, high(RAMEND)	; stack for rcall
	out sph, r16
	ldi r16, low(RAMEND)
	out spl, r16

	ldi zh, high(pmv1*2)	; flash -> value1, value2
	ldi zl, low(pmv1*2)
	ldi xh, high(value1)
	ldi xl, low(value1)
	ldi r16, 2
	rcall copybytes

	rcall mult1x1
	rjmp fin

mult1x1:
	lds r20, value1		; multiplicand, low half of r21:r20
	clr r21
	lds r17, value2		; multiplier
	clr r18			; product low
	clr r19			; product high
	ldi r22, 8		; bit counter

m_loop:
	; checking if the bit is 0 or 1
	sbrs r17, 0		; if 1: skip the rjmp, we just add the shifted multiplicand to the product
	rjmp m_skip		; if 0: jump over the add
	add r18, r20
	adc r19, r21

m_skip:
	lsl r20			; multiplicand <<= 1
	rol r21
	lsr r17			; next multiplier bit down into position 0
	dec r22
	brne m_loop

	sts product, r19	; MSB
	sts product+1, r18	; LSB
	ret

copybytes:
	lpm r0, z+
	st x+, r0
	dec r16
	brne copybytes
	ret

fin:
	rjmp fin

pmv1:
	.db 0x0D, 0x0B		; 13 * 11 = 143 = 0x008F

	.dseg
	value1:	.byte 1
	value2:	.byte 1
	product: .byte 2
