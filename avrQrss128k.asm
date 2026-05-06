	;; fancy_avr_qrss keyer
	;; Ethan Miller
	;; K8GU
	;; ethan@k8gu.com
	;; 2 January 2026

	;; On Atmel ATtiny13:
	;;  PB0 = pin 5 = FSK signal 0/+5 volts
	;;  PB1 = unused (reserved for GPS 1PPS input)
	;;  PB2 = pin 7 = PTT output (key PA)
	
	.include "tn13def.inc"
	.def 	Temp	= r16
	.def	DelayCtr= r17
	.def	DataMask= r18
	.def	ClkTrim = r19
	
	.cseg

	;; ISR vectors
	.org	0x0000
	rjmp	MAIN
	.org	0x003
	rjmp	EXTINT

	.org 0x010
EXTINT:
	;; Is the 1PPS counter nonzero? 
	tst DelayCtr
	;; Yes...decrement and wait for next 1PPS
	brne DECEXITISR
	inc ZL
	;; Handle the carry
	;; 	brvc SKIPHIGH
	;; 	inc ZH
SKIPHIGH:
	;; Load message byte
	lpm
	;; Is message byte negative (MSB set; really 0xff)?
	tst r0
	;; No, continue to output logic
	brpl SKIPRESET
	;; Yes, reset pointer to beginning of message and load message byte
	ldi ZH,high(2*MESSAGE2)
	ldi ZL,low(2*MESSAGE2)
	lpm
SKIPRESET:
	;; Load bitmask to isolate counter
	ldi DelayCtr,0x0f
	;; AND bitmask with message byte to extract counter
	and DelayCtr,r0
	;; double delay counter - commented out for DFCW
	;; 	lsl DelayCtr
	;; Load bitmask to isolate output bits
	ldi DataMask,0x0f
	;; Swap nibbles of message byte to put output bits in low nibble
	swap r0
	;; AND bitmask with (swapped) message byte to isolate output bits
	and DataMask,r0
	;; Write to port
	out PORTB,DataMask
DECEXITISR:
	;; Decrement the delay counter
	dec DelayCtr
	;; Initialize the counter just beyond half-way to obtain more-precise 1-second interrupts
	;; It would be better to use the full counter range and use OSCCAL to trim; this will be
	;; fixed in a future version
	ldi ClkTrim,0x7d
	out TCNT0,ClkTrim
	reti

	
MAIN:
	cli
	;; set direction of PB0
	ldi Temp,0x01
	out DDRB,Temp

	;; Prescaling for the timer/counter:  128 kHz / (16 * 64) = 125 Hz
	
	;; set clock prescaler to 16
	;; this will need to be reduced to 8 if using the OSCCAL to trim frequency
 	ldi Temp,0x80
 	out CLKPR,Temp
 	ldi Temp,0x04
 	out CLKPR,Temp
	;; set timer/counter prescaler to 8 (64 is 0x03)
	ldi Temp,0x03
	out TCCR0B,Temp
	
	;; enable Timer Overflow interrupt
	ldi Temp,0x02
	out TIMSK0,Temp
	
	ldi DataMask,0x01	
	ldi Temp,0x01
	sei
	
LOOP:
	rjmp LOOP

	
MESSAGE:
	;; Timing for DFCW is absolute (not /2 like FSKCW)
	;; Note that all timing values (low nibble of message element) are doubled in the ISR when
	;; the counter is loaded - comment out the lsl instruction if using DFCW - eventually, this
	;; can be an external (toggle switch) option

	;; STANDARD FSK MESSAGE
	;; 10-minute message (everything is based on half-times)
	;; K8GU is 156 seconds
	;; 5 minutes is 300 seconds, require 144 seconds of padding
	;; padding - 36
	.db 0x06,0x06,0x06,0x06,0x06,0x06
	;; K = 3+1+1+1+3+3 = 12 ... *3 = 36
	.db 0x59,0x43,0x53,0x43,0x59,0x49
	;; 8 = 3+1+3+1+3+1+1+1+1+3 = 18 ... *3 = 54
	.db 0x59,0x43,0x59,0x43,0x59,0x43,0x53,0x43,0x53,0x49
	;; G = 3+1+3+1+1+3 = 12 ... *3 = 36
	.db 0x59,0x43,0x59,0x43,0x53,0x49
	;; U = 1+1+1+1+3+3 = 10 ... *3 = 30
	.db 0x53,0x43,0x53,0x43,0x59,0x49
	;; padding - 36 * 3 = 108
	.db 0x06,0x06,0x06,0x06,0x06,0x06
	.db 0x06,0x06,0x06,0x06,0x06,0x06
	.db 0x06,0x06,0x06,0x06,0x06,0x06
	;; termination
	.db 0xff,0xff

MESSAGE2:
	;; DFCW high-density message
	;; 300 seconds of slot exist; 300 - 74 = 226 dead air seconds
	;; K8GU = 14*3 + 22 = 74
	;; Prepadding = 11
	.db 0x0a,0x0b
	;; K = (3+1)*2 + 6 = 14
	.db 0x56,0x01,0x46,0x01,0x56,0x06
	;; 8 = (3+1)*4 + 6 = 22
	.db 0x56,0x01,0x56,0x01,0x56,0x01,0x46,0x01,0x46,0x06
	;; G = (3+1)*2 + 6 = 14
	.db 0x56,0x01,0x56,0x01,0x46,0x06
	;; U = (3+1)*2 + 6 = 14
	.db 0x46,0x01,0x46,0x01,0x56,0x06
	;; padding - 36 * 6 = 216
	.db 0x0c,0x0c,0x0c,0x0c,0x0c,0x0c
	.db 0x0c,0x0c,0x0c,0x0c,0x0c,0x0c
	.db 0x0c,0x0c,0x0c,0x0c,0x0c,0x0c
	.db 0x0c,0x0c,0x0c,0x0c,0x0c,0x0c
	.db 0x0c,0x0c,0x0c,0x0c,0x0c,0x0c
	.db 0x0c,0x0c,0x0c,0x0c,0x0c,0x0c
	;; termination
	.db 0xff,0xff
