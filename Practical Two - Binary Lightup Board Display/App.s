

	AREA	AsmTemplate, CODE, READWRITE
	IMPORT	main
	
; Written by John Keaney (Github: keaneyjo)

ARR_R	SPACE	4 *	32	; 4 * 4 * word-size values

		
		
	EXPORT	start
start

IO1DIR	EQU	0xE0028018
IO1SET	EQU	0xE0028014
IO1CLR	EQU	0xE002801C
	
VALUE	EQU 0x80000001		;Largest Negative Integer
	
		LDR	R1,=IO1DIR
		LDR	R2,=0x000f0000		;select P1.19--P1.16
		STR	R2,[R1]				;make them outputs
		LDR	R1,=IO1SET
		STR	R2,[R1]				;set them to turn the LEDs off
		LDR	R2,=IO1CLR
		
; R1 points to the SET register
; R2 points to the CLEAR register

;		LDR	R3,=0x00010000		; start with P1.16.
;		STR	R3,[R2]	   			; clear the bit -> turn on the LED
;		STR	R3,[R1]			;set the bit -> turn off the LED
;		MOV	R3,R3,LSL #1	;shift up to next bit. P1.16 -> P1.17 etc.

; R3 is the LED
; Storing R3 in R1 turns LED off
; Storing R3 in R2	turns LED on



;	Three Components to this code:
; 1. Start-up (which is above and the singular block of code below)
; 2. Division Algorithm: Converts hexadecimal value to decimal representation
; 3. Display values on Board lights


startup 
		LDR R5, =VALUE		; Place hex value here, sample given =0x00000419 or in decimal 1049 	;n
		LDR	R6, =table		; Modulus' Table Address
		LDR R7, =0x0		; count
		LDR R8, [R6]		; Load first modulus value
		LDR R10, =0x40000000; Storage place for decimal values
		LDR R12, =0x0		;
		
	
	
	
; 2. Division Algorithm: Converts hexadecimal value to decimal representation

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Pseudo-Code for Division Algorithm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; n = value
; mod = table[0]
; while(n > 10)
; {
; 		while(n > mod)
; 		{
; 				count++
; 				n = n - mod
; 		}
; 		mod = mod LSL #2
; 		if(count != 0)
; 			leadingzeros = 1
; 		if(count == 0)
; 			if(leadingzeros == 1)
; 				store count
; 		count = 0
; 		shift count address
; }
; store count
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;		
		
		CMP R5, #0
		BGT skip
; Twos Complement the negative Number
		SUB R5, R5, #1
		LDR R9, =0xFFFFFFFF
		EOR R5, R9, R5

		LDR R9, =0x0
skip



while1
		CMP R5, #10
		BLT endwhile1
		
;		{
while2
		CMP R5, R8
		BLT endwhile2
;				{
		ADD R7, R7, #1	; count++
		SUB R5, R5, R8	; n = n - mod
;				}
		B	while2
endwhile2
		;MOV R11, R11, LSL #1
		LDR R8, [R6, #4]!				;mod = mod LSL #2
		
		CMP R7, #0
		BEQ	skip1						;if(count != 0)
		LDR R9, =0x01					;	leadingzeros = 1
skip1		
		
		CMP R9, #0
		BEQ skip2
		STR R7, [R10], #4				; store count
		ADD R12, R12, #1				; increase "number of decimals" count
skip2
		LDR R7, =0x0					; count = 0
		
		B while1
endwhile1
		
		STR R5, [R10]					; store count (decimal)
		ADD R12, R12, #1				; increase "number of decimals" count

		
		
		
		
; 3. Display values on Board lights

whileloop1	



; Negative {1,0,1,1}
		LDR R11, =0x0
		LDR R5, =VALUE			; Restart value
		CMP R5, #0
		BGE	notNegative
negative
		LDR	R3,=0x00010000		; start with P1.16.
		STR	R3,[R2]	   			; clear the bit -> turn on the LED
		MOV	R3,R3,LSL #1		; shift up to next bit. P1.16 -> P1.17 etc.
		STR	R3,[R1]				; set the bit -> turn off the LED
		MOV	R3,R3,LSL #1		; shift up to next bit. P1.17 -> P1.18 etc.
		STR	R3,[R2]	   			; clear the bit -> turn on the LED
		MOV	R3,R3,LSL #1		; shift up to next bit. P1.18 -> P1.19 etc.
		STR	R3,[R2]	   			; clear the bit -> turn on the LED
		; Delay Loop
		LDR	R4,=40000000
dloop10	SUBS	R4,R4,#1
		BNE	dloop10
notNegative


		LDR R7, =0x40000000		; Load address of decimal representation of values 
		LDR R8, [R7], #4		; Load current value and increment address to next value

whileloop2
		CMP R12, R11			; Check to see if all values have been shown
		BEQ	endwhileloop2
		
		
		
; If current decimal is a zero
		CMP R8, #0				;if(0) {1,1,1,1}
		BNE	noZero
zeropresent
		LDR	R3,=0x00010000		; start with P1.16.
		STR	R3,[R2]	   			; clear the bit -> turn on the LED
		MOV	R3,R3,LSL #1		; shift up to next bit. P1.16 -> P1.17 etc.
		STR	R3,[R2]				; set the bit -> turn on the LED
		MOV	R3,R3,LSL #1		; shift up to next bit. P1.17 -> P1.18 etc.
		STR	R3,[R2]	   			; clear the bit -> turn on the LED
		MOV	R3,R3,LSL #1		; shift up to next bit. P1.18 -> P1.19 etc.
		STR	R3,[R2]	   			; clear the bit -> turn on the LED
		; Delay Loop
		LDR	R4,=40000000
dloop11	SUBS	R4,R4,#1
		BNE	dloop11
		B	zeroSkip
noZero
		
		
		
		
;Otherwise preform binary representation

		;R3 = light
		;R4 = loop delay
		;R6 = mask
		;R7 = decimal value locations
		;R8 = store physical decimal values
		;R10 = spare register used to AND mask and value
		;R11 = comparison to number of decimals count to check if all decimals have been run through
		
		;else {lightOn}
		
		LDR	R3,=0x00010000		; start with P1.16.
		LDR R6,=0x00000008		; Mask {1,0,0,0}
;first bit
		AND R10, R8, R6			; AND mask and value to see if current bit is present
		CMP R10, #0				; Check if current bit is there
		BEQ lightoff1
		STR	R3,[R2]	   			; clear the bit -> turn on the LED
		B	skiplight1
lightoff1
		STR	R3,[R1]				; set the bit -> turn off the LED
skiplight1


;second bit
		MOV	R3,	R3,	LSL #1		;shift up to next bit. P1.16 -> P1.17 etc.
		MOV R6, R6, LSR #1
		AND R10, R8, R6
		CMP R10, #0
		BEQ lightoff2
		STR	R3,[R2]	   			; clear the bit -> turn on the LED
		B	skiplight2
lightoff2
		STR	R3,[R1]				; set the bit -> turn off the LED
skiplight2


;third bit
		MOV	R3, R3,	LSL #1		; shift up to next bit. P1.16 -> P1.17 etc.
		MOV R6, R6, LSR #1
		AND R10, R8, R6
		CMP R10, #0
		BEQ lightoff3
		STR	R3,[R2]	   			; clear the bit -> turn on the LED
		B	skiplight3
lightoff3
		STR	R3,[R1]				; set the bit -> turn off the LED
skiplight3


;fourth bit
		MOV	R3, R3,	LSL #1		; shift up to next bit. P1.16 -> P1.17 etc.
		MOV R6, R6, LSR #1
		AND R10, R8, R6
		CMP R10, #0
		BEQ lightoff4
		STR	R3,[R2]	   			; clear the bit -> turn on the LED
		B	skiplight4
lightoff4
		STR	R3,[R1]				; set the bit -> turn off the LED
skiplight4
		
		; Delay Loop
		LDR	R4,=40000000
dloop2	SUBS	R4,R4,#1
		BNE	dloop2
		
zeroSkip
		LDR R8, [R7], #4		; Load current value and increment address to next value
		ADD R11, R11, #1		; increment count for number of decimals
		B	whileloop2

endwhileloop2
		B	whileloop1			; Start number all over again
		

	
STOP	B	STOP

; Table of values to divide by
table	
	DCD 1000000000, 100000000, 10000000, 1000000, 100000, 10000, 1000, 100, 10
		
		END
