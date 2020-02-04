

	AREA	AsmTemplate, CODE, READWRITE
	IMPORT	main
	
; Written by John Keaney (Github: keaneyjo)

ARR_R	SPACE	4 *	32	; 4 * 4 * word-size values

		
		
	EXPORT	start
start

IO1DIR	EQU	0xE0028018
IO1SET	EQU	0xE0028014
IO1CLR	EQU	0xE002801C
	
VALUE	EQU 0x00000419
	
		LDR	R1,=IO1DIR
		LDR	R2,=0x000f0000		;select P1.19--P1.16
		STR	R2,[R1]				;make them outputs
		LDR	R1,=IO1SET
		STR	R2,[R1]				;set them to turn the LEDs off
		LDR	R2,=IO1CLR
; R1 points to the SET register
; R2 points to the CLEAR register

;		LDR	R5,=0x00100000		; end when the mask reaches this value
;wloop	LDR	R3,=0x00010000		; start with P1.16.
;floop	STR	R3,[R2]	   			; clear the bit -> turn on the LED



;		STR	R3,[R1]			;set the bit -> turn off the LED
;		MOV	R3,R3,LSL #1	;shift up to next bit. P1.16 -> P1.17 etc.
;		CMP	R3,R5
;		BNE	floop
;		B	wloop

; R3 is the LED
; Storing R3 in R1 turns LED off
; Storing R3 in R2	turns LED on




startup 
		LDR R5, =VALUE		; Place hex value here, sample given =0x00000419 or in decimal 1049 	;n
		LDR	R6, =table		; mod address
		LDR R7, =0x0		; count
		LDR R8, [R6]
		LDR R10, =0x40000000
		LDR R9, =0x0
		LDR R12, =0x0

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
		ADD R12, R12, #1
skip2
		LDR R7, =0x0					; count = 0
		
		B while1
endwhile1
		STR R5, [R10]					; store count

	; your program goes here
	
;division (+remove leading zeros)
;while(true)
;{
;	restart value
;	check negative (+delay)
;	for(int i = 0; i < R12; i++)
;	{
;		if(0) {1,1,1,1}
;		else {lightOn}
;		shiftToNextValue
;	}
;}
	
whileloop1	
; Negative
		LDR R5, =VALUE		; Restart value
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
		LDR	R4,=40000000
dloop10	SUBS	R4,R4,#1
		BNE	dloop10
notNegative


		LDR R7, =0x40000000		;
		MOV R9, #0				;quadruple zeros count
		LDR R8, [R7], #4

whileloop2
		CMP R12, R11
		BEQ	endwhileloop2
		CMP R8, #0			;if(0) {1,1,1,1}
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
		LDR	R4,=40000000
dloop11	SUBS	R4,R4,#1
		BNE	dloop11
		
noZero
		
		
		
		
		
		;R3 = light
		;R4 = loop delay
		;R5 = VALUE ? could be changed
		;R6 = mask
		; 
		
		;else {lightOn}
		
		LDR	R3,=0x00010000		; start with P1.16.
		LDR R6,=0x00000008
;first bit
		AND R10, R8, R6
		CMP R10, #0
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
		MOV	R3, R3,	LSL #1	;shift up to next bit. P1.16 -> P1.17 etc.
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
		MOV	R3, R3,	LSL #1	;shift up to next bit. P1.16 -> P1.17 etc.
		MOV R6, R6, LSR #1
		AND R10, R8, R6
		CMP R10, #0
		BEQ lightoff4
		STR	R3,[R2]	   			; clear the bit -> turn on the LED
		B	skiplight4
lightoff4
		STR	R3,[R1]				; set the bit -> turn off the LED
skiplight4
		
		
		
		LDR R8, [R7], #4
		ADD R11, R11, #1		

;delayloop
		LDR	R4,=40000000
dloop2	SUBS	R4,R4,#1
		BNE	dloop2
		
		
		
		B	whileloop2

endwhileloop2
		B	whileloop1
		

	
STOP	B	STOP

table	
	DCD 1000000000, 100000000, 10000000, 1000000, 100000, 10000, 1000, 100, 10
		
		END
