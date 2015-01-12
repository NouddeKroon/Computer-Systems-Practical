@DATA
    adval      DW    0
    ; ARRAYS
	leds_output DW  1
    leds_array DS  8
    led_timers DS  8

@CODE

   IOAREA      EQU  -16  ;  address of the I/O-Area, modulo 2^18
   OUTPUT      EQU   11  ;  relative position of the power outputs
   DSPDIG      EQU    9  ;  relative position of the 7-segment display's digit selector
   DSPSEG      EQU    8  ;  relative position of the 7-segment display's segments
    TIMER      EQU   13  ;  rel pos of timer in I/O area
    ADCONV     EQU    6
    ;
    LEDS       EQU   8
    ; GLOBALS

main :
				
				LOAD  R5  IOAREA
				LOAD  R0  0
				STOR  R0  [R5+OUTPUT]
				STOR  R0  [GB+leds_output]
				LOAD  R0  [R5+TIMER]
				SUB   R0  100
				STOR  R0  [GB+led_timers]

loop :
				BRS right_led
loop_end :
				BRA  loop

shift_bits:
        CMP  R1  0
shift_bits_cond:
        BEQ  shift_bits_end
        MULS  R0  2 ; shift left
        SUB  R1  1
        BRA shift_bits_cond
shift_bits_end:
        RTS

;Subroutine turning on or off the rightmost led
right_led:
			LOAD R1 [GB+led_timers]
			CMP R1 [R5+TIMER]      			; Check if the blink task should be performed
			BMI right_led_end    			; If negative just continue with next task
			LOAD R1 [GB+leds_output]		; Load previous output into R1
			LOAD R0 R1						; Make a copy of previous output into R0	
			XOR  R1 %01						; Flip the first bit
			STOR R1 [GB+leds_output]
			STOR R1 [R5+OUTPUT]				; Store the new bit sequence into output
			AND  R0 1						; Check if previous status was on
			BEQ  right_led_off_timer		; If previous status was off, continue to right_led_off_timer
			LOAD R0 [GB+leds_array]			; Load previous timer into R0
			LOAD R1 10000					; Load 100 into R1
			SUB  R1 R0						; Substract previous timer offset from 100
			LOAD R0 [GB+led_timers]			; Load previous timer into R0
			SUB  R0 R1						; Substract offset from R0
			STOR R0 [GB+led_timers]			; Store new timer into the timer array
			BRA  right_led_end				; End subroutine
right_led_off_timer:
			LOAD R0  [R5+ADCONV]			; Load new A/D
			AND  R0  255					; Only use rightmost 8 bits
			MULS R0  100				; Multiply by 100
			DIV  R0  255					; Divide by 255, it's now scaled from 0 to 100
			MULS R0  100
			STOR R0   [GB+leds_array]
			LOAD R1  [GB+led_timers]		; Load previous timer into R1
			SUB  R1  R0						; Substract the A/D from previous timer
			STOR R1  [GB+led_timers]		; Load new timer into the timer array
right_led_end:		
			RTS