@DATA
    ad_val      DW  0
    prev_inputs      DW  0
    cur_inputs      DW  0
    ; ARRAYS
    leds_output DW  0   ; state of the 8 binary output leds
    ; n percent value of PWM for each of the 8 leds
    ;leds_array DS  50,50,50,50,50,50,50,50
    leds_array  DW  5000,5000,5000,5000,5000,5000,5000,5000
    leds_timer  DS  8     ; scheduled time for change of state for each of the 8 leds

@CODE
   IOAREA      EQU  -16  ;  address of the I/O-Area, modulo 2^18
    ; offsets into IOAREA
   OUTPUT      EQU   11  ;  relative position of the power outputs
    INPUT      EQU    7  ;  position of the input buttons (relative to IOAREA)
   DSPDIG      EQU    9  ;  relative position of the 7-segment display's digit selector
   DSPSEG      EQU    8  ;  relative position of the 7-segment display's segments
    TIMER      EQU   13  ;  rel pos of timer in I/O area
    ADCONV     EQU    6  ;  rel pos of ad converter values
    ;
    LEDS       EQU   8
    ; GLOBALS

    ; ARRAY_LENGTHs
    LEDS_LEN EQU   8
    ;TIMER_DELTA  EQU   100
    TIMER_DELTA  EQU   10000
    ;N_DELTA 10
    N_DELTA    EQU  1000
    ;MAX_N      EQU  100
    MAX_N      EQU  10000

main :
        LOAD R5  IOAREA
        LOAD R4  [R5+TIMER]
        SUB  R4  500
        STOR R4  [GB+leds_timer]
        STOR R4  [GB+leds_timer+1]
        STOR R4  [GB+leds_timer+2]
        STOR R4  [GB+leds_timer+3]
        SUB  R4  5000
        STOR R4  [GB+leds_timer+4]
        STOR R4  [GB+leds_timer+5]
        STOR R4  [GB+leds_timer+6]
        STOR R4  [GB+leds_timer+7]

        LOAD R0  1
        PUSH R0

loop :
        BRS  right_led
        LOAD R0  [R5+INPUT]
        STOR R0  [GB+cur_inputs]
        BRS  load_n_delta
        LOAD R1  1
loop_for_each_button:
        BRS  update_led_percentage
        ADD  R1  1
        CMP  R1  8
        BNE  loop_for_each_button
        LOAD R0  [GB+cur_inputs]
        STOR R0  [GB+prev_inputs]
loop_for_each_led:
        BRS  update_led
        LOAD R0  [SP]
        ADD  R0  1
        STOR R0  [SP]
        CMP  R0  LEDS_LEN
        BLT  loop_for_each_led
loop_end :
        LOAD R0  [GB+leds_output]
        STOR R0  [R5+OUTPUT]
        LOAD R0  1
        STOR R0  [SP]
        BRA  loop

load_n_delta:
        LOAD R0  [GB+cur_inputs]  ; load binary input button states
        AND  R0  %01         ; only select bit0/button0
        MULS R0  -1*N_DELTA
        BNE  load_n_delta_end
        LOAD R0  N_DELTA
load_n_delta_end:
        RTS

update_led_percentage: ; R0 is the delta, R1 is the index
        PUSH R0
        PUSH R1
        LOAD R3  [GB+cur_inputs]
        LOAD R4  [GB+prev_inputs]
        LOAD R0  1
        BRS  shift_bits
        AND  R3  R0                ; only select the button specified by the index
        BEQ  update_led_percentage_end ; if button is 0 goto end
        AND  R4  R0                ; only select the button specified by the index
        BNE  update_led_percentage_end ; if button was already 1 goto end
        ADD  R1  leds_array
        LOAD R0  [GB+R1]   ; load old value
        ADD  R0  [SP+1]    ; add the delta (delta may be negative)
        BMI  update_led_percentage_end  ; if the result is negative don't update the global
        CMP  R0  MAX_N
        BGT  update_led_percentage_end  ; if the result is too large don't update the global
        STOR R0  [GB+R1]   ; store the new value in the global
update_led_percentage_end:
        PULL R1
        PULL R0
        RTS


; Top of the stack needs to contain the index of the led into leds_array
update_led:
        LOAD R1  [SP+1]
        ADD  R1  leds_timer
        LOAD R1  [GB+R1]  ; Load the timer for led
        CMP  R1  [R5+TIMER] ; If not passed the scheduled time jump to end
        BMI  update_led_end
update_set_led:
        LOAD R1  [SP+1]    ; index is the number of bits to shift left
        LOAD R0  1
        BRS  shift_bits  ; set the bit for index of the led
        ; R0 is now the bit pattern for led, R1 holds index
        LOAD R2  [GB+leds_output] ; retrieve prev led states
        LOAD R3  R2      ; make a copy
        XOR  R3  R0      ; invert the previous state of the led, while maintaining others
        STOR R3  [GB+leds_output] ; and save it
        AND  R2  R0      ; Check if the led was on
        ; start scheduling, LAST_OUTPUT `AND` BIT_PATTERN gives ZERO if prev state was off
        BEQ  update_led_sched_off
update_led_sched_on: ; R1 holds index
        ADD  R1  leds_array ; calc relative position of led's n val to GB
        LOAD R3  [SP+1]       ; load index
        ADD  R3  leds_timer ; calc relative position of led's timer to GB
        LOAD R1  [GB+R1]  ; load the n value for the led
        LOAD R2  [GB+R3]  ; Load the timer for led
        LOAD R0  TIMER_DELTA
        SUB  R0  R1       ; diff = TIMER_DELTA - n_value
        SUB  R2  R0       ; new_timer = timer - diff
        STOR R2  [GB+R3]  ; leds_timer[index] = new_timer
update_led_sched_off: ; R1 holds index
        ADD  R1  leds_array ; calc relative position of led's n val to GB
        LOAD R3  [SP+1]       ; load index
        ADD  R3  leds_timer ; calc relative position of led's timer to GB
        LOAD R1  [GB+R1]  ; load the n value for the led
        LOAD R2  [GB+R3]  ; Load the timer for led
        SUB  R2  R1       ; new_timer = timer - n_value
        STOR R2  [GB+R3]  ; leds_timer[index] = new_timer
update_led_end:
        RTS

; R0 is value to be shifted (right) and R1 number of bits to be shifted
shift_bits:
        PUSH R1
        CMP  R1  0
shift_bits_cond:
        BEQ  shift_bits_end
        MULS  R0  2 ; shift left
        SUB  R1  1
        BRA shift_bits_cond
shift_bits_end:
        PULL R1
        RTS

;Subroutine turning on or off the rightmost led
right_led:
			LOAD R1 [GB+leds_timer]
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
			LOAD R1 TIMER_DELTA					; Load 100 into R1
			SUB  R1 R0						; Substract previous timer offset from 100
			LOAD R0 [GB+leds_timer]			; Load previous timer into R0
			SUB  R0 R1						; Substract offset from R0
			STOR R0 [GB+leds_timer]			; Store new timer into the timer array
			BRA  right_led_end				; End subroutine
right_led_off_timer:
			LOAD R0  [R5+ADCONV]			; Load new A/D
			AND  R0  255					; Only use rightmost 8 bits
			;MULS R0  N_DELTA   		     ; Multiply by 100
			MULS R0  100   		; Multiply by 100
			DIV  R0  255					; Divide by 255, it's now scaled from 0 to 100
			MULS R0  100   ; TODO remove when N_DELTA is right
			STOR R0   [GB+leds_array]
			LOAD R1  [GB+leds_timer]		; Load previous timer into R1
			SUB  R1  R0						; Substract the A/D from previous timer
			STOR R1  [GB+leds_timer]		; Load new timer into the timer array
right_led_end:
			RTS
