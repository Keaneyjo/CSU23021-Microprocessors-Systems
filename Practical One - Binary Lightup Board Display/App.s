	AREA	AsmTemplate, CODE, READONLY
	IMPORT	main

; sample program makes the 4 LEDs P1.16, P1.17, P1.18, P1.19 go on and off in sequence
; (c) Mike Brady, 2011 -- 2019.

	EXPORT	start
start

IO1DIR	EQU	0xE0028018
IO1SET	EQU	0xE0028014
IO1CLR	EQU	0xE002801C
	
		LDR	R1,=IO1DIR
		LDR	R2,=0x000f0000		;select P1.19--P1.16
		STR	R2,[R1]				;make them outputs
		LDR	R1,=IO1SET
		STR	R2,[R1]				;set them to turn the LEDs off
		LDR	R2,=IO1CLR
; R1 points to the SET register
; R2 points to the CLEAR register

;		LDR	R5,=0x00100000		; end when the mask reaches this value
wloop	LDR	R3,=0x00010000		; start with P1.16.
floop	STR	R3,[R2]	   			; clear the bit -> turn on the LED



		STR	R3,[R1]			;set the bit -> turn off the LED
		MOV	R3,R3,LSL #1	;shift up to next bit. P1.16 -> P1.17 etc.
		CMP	R3,R5
		BNE	floop
		B	wloop
stop	B	stop
		; R3 is the LED
		; Storing R3 in R1 turns LED off
		; Storing R3 in R2	turns LED on
		
startup
		LDR R5, =0x00000419		; Place hex value here, sample given =0x00000419 or in decimal 1049 
		LDR R11, [R5]			; clone of initial value
		
		MOV R7, #0  ; 4 bit count
		MOV R8, #0	; single bit count
		B	truemain
		;LDR R0, =0x01 ; R0 = 0x00FF (255)
		;MOV R1, R0, LSL #1 ; R1 = 0x01FE (510)
		
newnibble
		ADD R7, R7, #1
		MOV R8, #0
		B	endnewnibble
		
		;skip ahead of leading zeros by counting them for later
		;count of leading zeros stored in R8
leadingzeros
		MOV R11, R11, LSL #1 ; R1 = 0x01FE (510)
		AND R10, R11, R6
		CMP R10, #1
		BEQ	endleadingzeros
		ADD R8, R8, #1			; now I know how many leading zeros
		CMP R8, #3
		BEQ newnibble
endnewnibble
		B	leadingzeros


truemain
		B	leadingzeros
endleadingzeros
		LDR R12, [R8]		; recreate 32 bit count
whileloop
		LDR R11, [R5]		; recreate clone
		LDR R6, =0x80000000	;mask
		AND R9, R11, R6		;MSB = or =/= 1, i.e. number is negative
		CMP R9, #1
		BEQ	negative
returnnnegative
; delay used in function

		MOV	R4, #4
		MUL R10, R8, R4
		MOV R8, #1
		LDR R6, =0x80000000

removeleadingzeros
		CMP R8, R10
		BEQ	spareclone
		;LDR R0, =0x01 ; R0 = 0x00FF (255)
		;MOV R1, R0, LSL #1 ; R1 = 0x01FE (510)
		MOV R11, R11, LSL #1
		ADD R8, R8, #1
		B	removeleadingzeros
		
spareclone
		LDR R9, [R11]
		
lightup
		CMP	R12, #31
		BEQ	endlightup
		
; first check if quadruple zeros
		MOV R9, #0
;first bit
		AND R10, R11, R6
		CMP R10, #0
		BNE skip
		ADD R9, R9, #1
;second bit
		MOV R11, R11, LSL #1
		AND R10, R11, R6
		CMP R10, #0
		BNE skip
		ADD R9, R9, #1
;third bit
		MOV R11, R11, LSL #1
		AND R10, R11, R6
		CMP R10, #0
		BNE skip
		ADD R9, R9, #1
;fourth bit
		MOV R11, R11, LSL #1
		AND R10, R11, R6
		CMP R10, #0
		B	zeropresent
returnzeropresent
		
		
		
skip
		LDR R11, [R9]
		LDR	R3,=0x00010000		; start with P1.16.
		
;first bit
		AND R10, R11, R6
		CMP R10, #0
		BEQ lightoff
		BNE	lighton
;second bit
		MOV R11, R11, LSL #1
		AND R10, R11, R6
		BEQ lightoff
		BNE	lighton
;third bit
		MOV R11, R11, LSL #1
		AND R10, R11, R6
		CMP R10, #0
		BEQ lightoff
		BNE	lighton
;fourth bit
		MOV R11, R11, LSL #1
		AND R10, R11, R6
		CMP R10, #0
		BEQ lightoff
		BNE	lighton
		
		LDR R9, [R11]
		B	lightup
		
endlightup
		B whileloop
	
		
		
lighton
		STR	R3,[R2]	   			; clear the bit -> turn on the LED
		BX	LR
		
lightoff
		STR	R3,[R1]				;set the bit -> turn off the LED
		BX	LR
			
			
negative
		LDR	R3,=0x00010000		; start with P1.16.
		STR	R3,[R2]	   			; clear the bit -> turn on the LED
		MOV	R3,R3,LSL #1		; shift up to next bit. P1.16 -> P1.17 etc.
		STR	R3,[R1]				; set the bit -> turn off the LED
		MOV	R3,R3,LSL #1		; shift up to next bit. P1.17 -> P1.18 etc.
		STR	R3,[R2]	   			; clear the bit -> turn on the LED
		MOV	R3,R3,LSL #1		; shift up to next bit. P1.18 -> P1.19 etc.
		STR	R3,[R2]	   			; clear the bit -> turn on the LED
		BL 	delay
		B 	returnnnegative
		
delay
		;delay for about a half second
		LDR	R4,=40000000
dloop	SUBS	R4,R4,#1
		BNE	dloop
		BX 	LR
		; maybe use the BX 
		
zeropresent
		LDR	R3,=0x00010000		; start with P1.16.
		STR	R3,[R2]	   			; clear the bit -> turn on the LED
		MOV	R3,R3,LSL #1		; shift up to next bit. P1.16 -> P1.17 etc.
		STR	R3,[R2]				; set the bit -> turn on the LED
		MOV	R3,R3,LSL #1		; shift up to next bit. P1.17 -> P1.18 etc.
		STR	R3,[R2]	   			; clear the bit -> turn on the LED
		MOV	R3,R3,LSL #1		; shift up to next bit. P1.18 -> P1.19 etc.
		STR	R3,[R2]	   			; clear the bit -> turn on the LED
		BL 	delay
		B returnzeropresent
		
		END