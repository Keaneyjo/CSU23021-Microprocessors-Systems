	
	AREA AsmTemplate, CODE, READWRITE
	IMPORT main

	; Written by John Keaney (Github: keaneyjo)

storage SPACE 4 * 32 ; 4 * 4 * word-size values

	EXPORT start
start

IO1PIN EQU 0xE0028010
MASK   EQU 0x00F00000

IO1DIR EQU 0xE0028018
IO1SET EQU 0xE0028014
IO1CLR EQU 0xE002801C


Exception_Vectors
; B IRQ_Handler ; 0x00000018
; right most two buttons

; R0 = input value

startup

	LDR r1,=IO1DIR
	LDR r2,=0x000f0000 ;select P1.19--P1.16
	STR r2,[r1] ;make them outputs
	LDR r1,=IO1SET
	STR r2,[r1] ;set them to turn the LEDs off
	LDR R2,=IO1CLR
	; r1 points to the SET register
	; r2 points to the CLEAR register

	LDR R10,=IO1PIN ; when button is pressed, value of button address is placed inside R10
	; LDR R11, =0x00F00000 ; button mask
	; LDR R4, [R10] ; Then we load the value of the button from it's address
	; LDR R4, [R10]

	; To-Do
	; 0. Set current value to 0
	; 1. Initially all bits clear
	; 2. Main which displays the current number

actualMain

initially_all_bits_clear
;flash lights to show that working
	LDR R2,=IO1CLR
	LDR R3,=0x00010000 ; start with P1.16.
	STR R3,[R2]   ; clear the bit -> turn on the LED
	MOV R3,R3,LSL #1 ; shift up to next bit. P1.16 -> P1.17 etc.
	STR R3,[R2] ; set the bit -> turn off the LED
	MOV R3,R3,LSL #1 ; shift up to next bit. P1.17 -> P1.18 etc.
	STR R3,[R2]   ; clear the bit -> turn on the LED
	MOV R3,R3,LSL #1 ; shift up to next bit. P1.18 -> P1.19 etc.
	STR R3,[R2]   ; clear the bit -> turn on the LED
	
	LDR	R4,=8000000
dloop	SUBS	R4,R4,#1
	BNE	dloop
		
; then unflash to set up	
	LDR R3,=0x00010000 ; start with P1.16.
	STR R3,[R1]   ; clear the bit -> turn on the LED
	MOV R3,R3,LSL #1 ; shift up to next bit. P1.16 -> P1.17 etc.
	STR R3,[R1] ; set the bit -> turn off the LED
	MOV R3,R3,LSL #1 ; shift up to next bit. P1.17 -> P1.18 etc.
	STR R3,[R1]   ; clear the bit -> turn on the LED
	MOV R3,R3,LSL #1 ; shift up to next bit. P1.18 -> P1.19 etc.
	STR R3,[R1]   ; clear the bit -> turn on the LED



; Pseudo_code
; while(true)
; {
; int result = subroutine_check_if_button_pressed
; if (20){}
; if (21)
; if (22)
; if (23)
; if (-21) // long press
; }
;
	LDR R0, =0x0	;boolean
	LDR R1, =0x0	;first value
	LDR R2, =0x0	;second value	
repeat
; R0 is equal to the return result
	BL check_press


	; if addition
	CMP R0, #23
	BNE not_add
	BL	add_value
	BL	display_board
not_add
	
	; if subs
	CMP R0, #22
	BNE not_sub
	BL	sub_value
	BL	display_board
not_sub

	; if plus
	CMP R0, #21
	BNE not_plus
	BL	plus_value
not_plus

	; if minus
	CMP R0, #20
	BNE not_minus
	BL	minus_value
not_minus

	; clear_operator
	CMP R0, #-21
	BNE not_clear_operator
	BL 	clear_operator
not_clear_operator

	; clear_expression
	CMP R0, #-22
	BNE not_clear_expression
	BL 	clear_expression
not_clear_expression

	
	
		
	BL big_delay



	B 	repeat








stop B stop

check_press
	PUSH {R4-R10, LR}
check_press_2
	LDR R4, =IO1PIN
	LDR R5, [R4]
	LDR R4, =MASK
	AND R5, R4, R5

	CMP R5, #0x00700000 ;-0111-
	BNE skip_add
	MOV R0, #23 ;add
	POP {R4-R10, PC}
skip_add

	CMP R5, #0x00B00000 ;-1011
	BNE skip_sub
	MOV R0, #22 ;sub
	POP {R4-R10, PC}
skip_sub

	CMP R5, #0x00D00000 ;-1101
	BNE skip_plus
	MOV R0, #21 ;plus
	
	BL long_delay
	LDR R4, =IO1PIN
	LDR R5, [R4]
	LDR R4, =MASK
	AND R5, R4, R5
	CMP R5, #0x00D00000 ;-1101
	BNE skip_to_plus
	MOV R0, #-21
skip_to_plus

	POP {R4-R10, PC}
skip_plus

	CMP R5, #0x00E00000 ;-1101
	BNE skip_minus
	MOV R0, #20 ;plus
	
	BL long_delay
	LDR R4, =IO1PIN
	LDR R5, [R4]
	LDR R4, =MASK
	AND R5, R4, R5
	CMP R5, #0x00E00000 ;-1101
	BNE skip_to_plus
	MOV R0, #-22
	POP {R4-R10, PC}
skip_minus


	B	check_press_2



	;;;;;;;;;;;;;;;;;;;   big_delay_value   ;;;;;;;;;;;;;;;;;;;;
long_delay
	PUSH {R4-R10, LR}
	LDR	R4,=6000000
delay_2	SUBS	R4,R4,#1
	BNE	delay_2
	POP {R4-R10, PC}

	;;;;;;;;;;;;;;;;;;;   big_delay_value   ;;;;;;;;;;;;;;;;;;;;
big_delay
	PUSH {R4-R10, LR}
	LDR	R4,=4000000
delay	SUBS	R4,R4,#1
	BNE	delay
	POP {R4-R10, PC}
	
	;;;;;;;;;;;;;;;;;;;   add_value   ;;;;;;;;;;;;;;;;;;;;
add_value	;increment first value
	PUSH {R4-R10, LR}
	CMP R1, #7
	BEQ	skip_da_add
	ADD R1, R1, #1
skip_da_add
	POP {R4-R10, PC}
	
	;;;;;;;;;;;;;;;;;;;   sub_value   ;;;;;;;;;;;;;;;;;;;;
sub_value	;increment first value
	PUSH {R4-R10, LR}
	;CMP R1, #0xF8
	;BLS skip_da_sub
	SUB R1, R1, #1
;skip_da_sub
	POP {R4-R10, PC}
	
	;;;;;;;;;;;;;;;;;;;   plus_value   ;;;;;;;;;;;;;;;;;;;;
plus_value	;increment first value
	PUSH {R4-R10, LR}
	
	LDR R4, =storage
	LDR R5, [R4]
	
	CMP R5, #0
	BNE skip_da_display
	MOV R9, R1
	MOV R1, #0
	BL display_board
	MOV R1, R9
skip_da_display

	CMP R5, #1
	BNE skip_da_plus
	ADD R1, R2, R1
	BL display_board
skip_da_plus

	CMP R5, #2
	BNE skip_da_minus
	SUB R1, R2, R1
	BL display_board	
skip_da_minus

	MOV R2, R1
	MOV R1, #0
	
	LDR R6, =0x01	;plus value
	STR R6, [R4]
	
	POP {R4-R10, PC}
	
	
	;;;;;;;;;;;;;;;;;;;   minus_value   ;;;;;;;;;;;;;;;;;;;;
minus_value	;increment first value
	PUSH {R4-R10, LR}
	
	LDR R4, =storage
	LDR R5, [R4]
	
	CMP R5, #0
	BNE skip_da_display_2
	MOV R9, R1
	MOV R1, #0
	BL display_board
	MOV R1, R9
skip_da_display_2

	CMP R5, #1
	BNE skip_da_plus_2
	ADD R1, R2, R1
	BL display_board
skip_da_plus_2

	CMP R5, #2
	BNE skip_da_minus_2
	
	SUB R1, R2, R1
	BL display_board
skip_da_minus_2

	MOV R2, R1
	MOV R1, #0
	
	LDR R6, =0x02	;plus value
	STR R6, [R4]

	POP {R4-R10, PC}
	
	
	;;;;;;;;;;;;;;;;;;;   clear_operator   ;;;;;;;;;;;;;;;;;;;;
clear_operator	
	PUSH {R4-R10, LR}

	MOV R1, R2
	MOV R2, #0
	LDR R4, =storage
	LDR R5, =0x0
	STR R5, [R4]
	BL display_board
	
	POP {R4-R10, PC}
	
	
	;;;;;;;;;;;;;;;;;;;   clear_expression   ;;;;;;;;;;;;;;;;;;;;
clear_expression	
	PUSH {R4-R10, LR}

	MOV R1, #0
	MOV R2, #0
	LDR R4, =storage
	LDR R5, =0x0
	STR R5, [R4]
	BL display_board
	
	POP {R4-R10, PC}	
	
	
	;LDR R3,=0x00010000 ; start with P1.16.
	;STR R3,[R2]   ; clear the bit -> turn on the LED
	;LDR R2,=IO1CLR
	
	
	;CMP R5, #0x00E00000 ; 1110 - 00000
	;BEQ if1_20

	;CMP R5, #0x00D00000 ; 1101 - 00000
	;BEQ if1_21

	;CMP R5, #0x00B00000 ; 1011 - 00000
	;BEQ if1_22

	;CMP R5, #0x00700000 ; 0001 - 00000
	;BEQ if1_23
	
	
	
	
	;LDR r1,=IO1DIR
	;LDR r2,=0x000f0000 ;select P1.19--P1.16
	;STR r2,[r1] ;make them outputs
	;LDR r1,=IO1SET
	;STR r2,[r1] ;set them to turn the LEDs off
	;LDR r2,=IO1CLR
display_board

		PUSH {R4-R11, LR}
		LDR R4,=IO1CLR
		LDR R5,=IO1SET
		LDR	R3,=0x00010000		; start with P1.16.
		LDR R6,=0x00000008		; Mask {1,0,0,0}
		
;first bit
		AND R10, R1, R6			; AND mask and value to see if current bit is present
		CMP R10, #0				; Check if current bit is there
		BEQ lightoff1
		STR	R3,[R4]	   			; clear the bit -> turn on the LED
		B	skiplight1
lightoff1
		STR	R3,[R5]				; set the bit -> turn off the LED
skiplight1

;second bit
		MOV	R3,	R3,	LSL #1		;shift up to next bit. P1.16 -> P1.17 etc.
		MOV R6, R6, LSR #1
		AND R10, R1, R6
		CMP R10, #0
		BEQ lightoff2
		STR	R3,[R4]	   			; clear the bit -> turn on the LED
		B	skiplight2
lightoff2
		STR	R3,[R5]				; set the bit -> turn off the LED
skiplight2

;third bit
		MOV	R3, R3,	LSL #1		; shift up to next bit. P1.16 -> P1.17 etc.
		MOV R6, R6, LSR #1
		AND R10, R1, R6
		CMP R10, #0
		BEQ lightoff3
		STR	R3,[R4]	   			; clear the bit -> turn on the LED
		B	skiplight3
lightoff3
		STR	R3,[R5]				; set the bit -> turn off the LED
skiplight3

;fourth bit
		MOV	R3, R3,	LSL #1		; shift up to next bit. P1.16 -> P1.17 etc.
		MOV R6, R6, LSR #1
		AND R10, R1, R6
		CMP R10, #0
		BEQ lightoff4
		STR	R3,[R4]	   			; clear the bit -> turn on the LED
		B	skiplight4
lightoff4
		STR	R3,[R5]				; set the bit -> turn off the LED
skiplight4

		POP {R4-R11, PC}
;		B	return_display_board
		
		END