; Definitions  -- references to 'UM' are to the User Manual.

; Timer Stuff -- UM, Table 173
IO0DIR	EQU	0xE0028008
IO0SET	EQU	0xE0028004
IO0CLR	EQU	0xE002800C
T0	equ	0xE0004000		; Timer 0 Base Address
T1	equ	0xE0008000

IR	equ	0			; Add this to a timer's base address to get actual register address
TCR	equ	4
MCR	equ	0x14
MR0	equ	0x18

TimerCommandReset	equ	2
TimerCommandRun	equ	1
TimerModeResetAndInterrupt	equ	3
TimerResetTimer0Interrupt	equ	1
TimerResetAllInterrupts	equ	0xFF

; VIC Stuff -- UM, Table 41
VIC	equ	0xFFFFF000		; VIC Base Address
IntEnable	equ	0x10
VectAddr	equ	0x30
VectAddr0	equ	0x100
VectCtrl0	equ	0x200

Timer0ChannelNumber	equ	4	; UM, Table 63
Timer0Mask	equ	1<<Timer0ChannelNumber	; UM, Table 63
IRQslot_en	equ	5		; UM, Table 58

	AREA	InitialisationAndMain, CODE, READONLY
	IMPORT	main

; (c) Mike Brady, 2014 -- 2019.

	EXPORT	start
start
; initialisation code

; Initialise the VIC
	ldr	r0,=VIC			; looking at you, VIC!

	ldr	r1,=irqhan
	str	r1,[r0,#VectAddr0] 	; associate our interrupt handler with Vectored Interrupt 0

	mov	r1,#Timer0ChannelNumber+(1<<IRQslot_en)
	str	r1,[r0,#VectCtrl0] 	; make Timer 0 interrupts the source of Vectored Interrupt 0

	mov	r1,#Timer0Mask
	str	r1,[r0,#IntEnable]	; enable Timer 0 interrupts to be recognised by the VIC

	mov	r1,#0
	str	r1,[r0,#VectAddr]   	; remove any pending interrupt (may not be needed)

; Initialise Timer 0
	ldr	r0,=T0			; looking at you, Timer 0!

	mov	r1,#TimerCommandReset
	str	r1,[r0,#TCR]

	mov	r1,#TimerResetAllInterrupts
	str	r1,[r0,#IR]

	;ldr	r1,=(14745600/200)-1	 ; 5 ms = 1/200 second
	ldr	r1,=(14745600/1600)-1	 ; 625 ms = 1/1600 second
	str	r1,[r0,#MR0]

	mov	r1,#TimerModeResetAndInterrupt
	str	r1,[r0,#MCR]

	mov	r1,#TimerCommandRun
	str	r1,[r0,#TCR]

;from here, initialisation is finished, so it should be the main body of the main program

	;from here, initialisation is finished, so it should be the main body of the main program
	ldr	r1,=IO0DIR
	ldr	r2,=0x00260000	;select P0.21 P0.18 P0.17
	str	r2,[r1]		;make them outputs
	ldr	r1,=IO0SET
	str	r2,[r1]		;set them to turn the LEDs off
	ldr	r2,=IO0CLR
; r1 points to the SET register
; r2 points to the CLEAR register

;P0.17 RED  0x00020000
;P0.18 BLUE 0x00040000
;P0.21 GREEN 0x00200000 

	;red -> 0x00020000 			- 0000 0010
	;blue -> 0x00040000 		- 0000 0100
	;purple -> 0x00060000		- 0000 0110
	;green -> 0x00200000 		- 1 ---- 0000
	;yellow -> 0x00220000		- 1 ---- 0010
	;light blue -> 0x00240000   - 1 ---- 0100
	;white -> 0x00260000		- 1 ---- 0110
	;black/clear -> 0x00000000  - 0000 0000
	;00,02,04,06,20,22,24
	
wloop	
	LDR R6,=estimate1sec;
	LDR R7,[R6];
waiting
	;800 * 1/1600 = 0.5s 
	CMP R7,#0x320;
	BEQ redLED;
	CMP R7,#0x640;
	BEQ blueLED;
	CMP R7,#0x960;
	BEQ purpleLED;
	CMP R7,#0xC20;
	BEQ greenLED;
	CMP R7,#0xFA0;
	BEQ yellowLED;
	CMP R7,#0x12C0;
	BEQ lightBlueLED;
	CMP R7,#0x1600;
	BEQ whiteLED;
	CMP R7,#0x1900;
	BEQ clearLED;
	
	B	wloop;
	
redLED
	LDR R5,=0X00200000;GREEN
	STR R5,[R1];
	LDR R3,=0x00020000;RED
	STR R3,[R2];
	b   wloop
	
blueLED
	LDR R3,=0x00020000;RED
	STR R3,[R1];
	LDR R4,=0X00040000;BLUE
	STR R4,[R2];
	B   wloop
	
purpleLED
	LDR R3,=0X00040000;BLUE
	STR R3,[R1];
	LDR R4,=0X00060000;PURPLE
	STR R4,[R2];
	B   wloop
	
greenLED
	LDR R4,=0X00060000;BLUE
	STR R4,[R1];
	LDR R5,=0X00200000;GREEN
	STR R5,[R2];
	B   wloop
	
yellowLED;
	LDR R4,=0X00200000;BLUE
	STR R4,[R1];
	LDR R5,=0x00220000;GREEN
	STR R5,[R2];
	B   wloop
	
lightBlueLED;
	LDR R4,=0x00220000;BLUE
	STR R4,[R1];
	LDR R5,=0x00240000;GREEN
	STR R5,[R2];
	B   wloop
	
whiteLED;
	LDR R4,=0x00240000;BLUE
	STR R4,[R1];
	LDR R5,=0x00260000;GREEN
	STR R5,[R2];
	B   wloop
	
clearLED
	LDR R4,=0x00260000;BLUE
	STR R4,[R1];
	LDR R7,=0;
	STR R7,[R6];
	b	wloop  		; branch always

;main program execution will never drop below the statement above.

	AREA	InterruptStuff, CODE, READONLY
irqhan	
	sub	lr,lr,#4
	stmfd	sp!,{r0-r1,lr}	; the lr will be restored to the pc

;this is the body of the interrupt handler

;here you'd put the unique part of your interrupt handler
;all the other stuff is "housekeeping" to save registers and acknowledge interrupts
	LDR R0,=estimate1sec;
	
	;9215875
	LDR R1,[R0];
	ADD R1,R1,#1;
	STR R1,[R0];

;this is where we stop the timer from making the interrupt request to the VIC
;i.e. we 'acknowledge' the interrupt
	ldr	r0,=T0
	mov	r1,#TimerResetTimer0Interrupt
	str	r1,[r0,#IR]	   	; remove MR0 interrupt request from timer

;here we stop the VIC from making the interrupt request to the CPU:
	ldr	r0,=VIC
	mov	r1,#0
	str	r1,[r0,#VectAddr]	; reset VIC

	ldmfd	sp!,{r0-r1,pc}^	; return from interrupt, restoring pc from lr
				; and also restoring the CPSR
				
		AREA Output,DATA,READWRITE
estimate1sec DCD 0;
	
	END

