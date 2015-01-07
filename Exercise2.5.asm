@CODE

   IOAREA      EQU  -16  ;  address of the I/O-Area, modulo 2^18
    INPUT      EQU    7  ;  position of the input buttons (relative to IOAREA)
   OUTPUT      EQU   11  ;  relative position of the power outputs
   DSPDIG      EQU    9  ;  relative position of the 7-segment display's digit selector
   DSPSEG      EQU    8  ;  relative position of the 7-segment display's segments
    TIMER      EQU   13  ;  rel pos of timer in I/O area
    ; GLOBALS
    INPUTS     EQU   1
    MINUTES    EQU   2
    SECONDS    EQU   3
    HUNDREDS   EQU   4
    COUNTER    EQU   5
    PAUSE      EQU   6
    ; ARRAYS
    DIGITS_ARR EQU   10   ;  Digits to be shown on the segment displays, length = 6
    ; LENGTH GLOBAL ARRAYS
    DIGITS_LEN EQU   6

   main :
              LOAD  R0  0  ; initilization value
              LOAD  R5  IOAREA
              LOAD  R4  [R5+TIMER]  ; R4 will keep the scheduled time to perform task
              LOAD  R3  0       ; keep index of current display
              LOAD  R1  DIGITS_ARR
              STOR  R0  [GB+R1]
              ADD   R1  1
              STOR  R0  [GB+R1]
              ADD   R1  1
              STOR  R0  [GB+R1]
              ADD   R1  1
              STOR  R0  [GB+R1]
              ADD   R1  1
              STOR  R0  [GB+R1]
              ADD   R1  1
              STOR  R0  [GB+R1]
              STOR  R0  [GB+MINUTES]
              STOR  R0  [GB+SECONDS]
              STOR  R0  [GB+HUNDREDS]
              STOR  R0  [GB+COUNTER]

loop :
               SUB  R4  10    ; the timer uses a 10kHz frequency and our tasks are
                              ; to be performed once every 1000st of a second
loop_wait:
               CMP  R4  [R5+TIMER]  ; busy waiting taking account of timer underflow
               BMI  loop_wait

loop_checked_paused:
               LOAD R0  [GB+PAUSE]
               CMP  R0  1
               BEQ  loop_task_light_single_display
loop_calc_timer_vals:
               LOAD R0  [GB+COUNTER]
               ADD  R0  1
               DVMD R0  10    ; 10 times 1000st of a second is 100st second
               STOR R1  [GB+COUNTER] ; R1 holds result COUNTER `MOD` 10
               CMP  R0  0   ; R0 is the result of COUNTER `DIV` 10
               BEQ loop_task_light_single_display
               LOAD R0  [GB+HUNDREDS]
               ADD  R0  1
               DVMD R0  100
               STOR R1  [GB+HUNDREDS] ; R1 holds result HUNDREDS `MOD` 100
               CMP  R0  0   ; R0 is the result of HUNDREDS `DIV` 100
               BEQ loop_task_light_single_display
               LOAD R0  [GB+SECONDS]
               ADD  R0  1
               DVMD R0  60
               STOR R1  [GB+SECONDS] ; R1 holds result SECONDS `MOD` 60
               CMP  R0  0   ; R0 is the result of SECONDS `DIV` 60
               BEQ loop_task_light_single_display
               LOAD R0  [GB+MINUTES]
               ADD  R0  1
               DVMD R0  60
               STOR R1  [GB+MINUTES] ; R1 holds result MINUTES `MOD` 60
loop_task_light_single_display:
              LOAD  R1  DIGITS_ARR
              ADD   R1  R3
              LOAD  R0  [GB+R1]    ;  load the digit value
               BRS  Hex7Seg      ;  translate (value in) R0 into a display pattern
loop_task_light_single_display_dot0:
               CMP  R3  2
               BNE loop_task_light_single_display_dot1
               OR   R1  %010000000  ; Set the decimal point
loop_task_light_single_display_dot1:
               CMP  R3  4
               BNE loop_task_light_single_display_pattern
               OR   R1  %010000000  ; Set the decimal point
loop_task_light_single_display_pattern:
              STOR  R1  [R5+DSPSEG] ; and place this in the Display Element
              LOAD  R0  %01  ; setup shift bits for display bit
              LOAD  R1  R3
              BRS shift_bits
              STOR  R0  [R5+DSPDIG] ; activate Display Element nr. 0
              ; increment idx
              ADD   R3  1
              MOD   R3  DIGITS_LEN
loop_set_digits:
              PUSH R3
              LOAD R3 DIGITS_ARR
              LOAD R0 [GB+HUNDREDS]
              MOD  R0 10
              STOR R0 [GB+R3]
              ADD  R3 1
              LOAD R0 [GB+HUNDREDS]
              DIV  R0 10
              MOD  R0 10
              STOR R0 [GB+R3]
              ADD  R3 1
              LOAD R0 [GB+SECONDS]
              MOD  R0 10
              STOR R0 [GB+R3]
              ADD  R3 1
              LOAD R0 [GB+SECONDS]
              DIV  R0 10
              MOD  R0 10
              STOR R0 [GB+R3]
              ADD  R3 1
              LOAD R0 [GB+MINUTES]
              MOD  R0 10
              STOR R0 [GB+R3]
              ADD  R3 1
              LOAD R0 [GB+MINUTES]
              DIV  R0 10
              MOD  R0 10
              STOR R0 [GB+R3]
              PULL R3

read_inputs_but0:
              LOAD  R0  [GB+INPUTS]  ; load the prev state of the input buttons
              LOAD  R1  [R5+INPUT]   ; load state input buttons
               AND  R0  %01   ; select only but0
               AND  R1  %01   ; select only but0
               BEQ  read_inputs_but1         ; Only change led if the button has just been pushed
               XOR  R0  R1           ; if but7 changed state
               BEQ  read_inputs_but1
              LOAD  R2  %01
              STOR  R2  [GB+PAUSE]
read_inputs_but1:
              LOAD  R0  [GB+INPUTS]  ; load the prev state of the input buttons
              LOAD  R1  [R5+INPUT]   ; load state input buttons
               AND  R0  %010   ; select only but0
               AND  R1  %010   ; select only but0
               BEQ  read_inputs_but2         ; Only change led if the button has just been pushed
               XOR  R0  R1           ; if but7 changed state
               BEQ  read_inputs_but2
              LOAD  R2  0
              STOR  R2  [GB+PAUSE]
read_inputs_but2:
              LOAD  R0  [GB+INPUTS]  ; load the prev state of the input buttons
              LOAD  R1  [R5+INPUT]   ; load state input buttons
               AND  R0  %0100   ; select only but0
               AND  R1  %0100   ; select only but0
               BEQ  loop_end         ; Only change led if the button has just been pushed
               XOR  R0  R1           ; if but7 changed state
               BEQ  loop_end
              LOAD  R0  0
              STOR  R0  [GB+MINUTES]
              STOR  R0  [GB+SECONDS]
              STOR  R0  [GB+HUNDREDS]
              STOR  R0  [GB+COUNTER]



;loop_task_blink :
;               ADD  R3  1     ; increment counter
;               CMP  R3  100   ; when counter has reached 100 half a second will have passed
;               BNE  loop_task_but7
;               XOR  R4  %01   ; flip bit0 to change led state for LED0
;              LOAD  R3  0     ; reset the counter
;loop_task_but7 :
;              LOAD  R0  [GB+INPUTS]  ; load the prev state of the input buttons
;              LOAD  R1  [R5+INPUT]   ; load state input buttons
;              STOR  R1  [GB+INPUTS]   ; store the cur state as the prev state
;               AND  R0  %010000000   ; select only but7
;               AND  R1  %010000000   ; select only but7
;               BEQ  loop_end         ; Only change led if the button has just been pushed
;               XOR  R0  R1           ; if but7 changed state
;               BEQ  loop_end
;               XOR  R4  R0           ; flip bit7 to change the state of led7
loop_end :
              LOAD  R0  [R5+INPUT]  ; Save current inputs as previous
              STOR  R0  [GB+INPUTS]
               BRA  loop

;; R3 is current idx
;maybe_increment_digit:
;              LOAD  R0  1
;              LOAD  R1  R3
;              BRS shift_bits
;              LOAD  R2  R0
;              LOAD  R0  [GB+INPUTS]  ; load the prev state of the input buttons
;              LOAD  R1  [R5+INPUT]   ; load state input buttons
;               AND  R0  R2 ; select only button idx
;               AND  R1  R2 ; select only button idx
;               BEQ  maybe_increment_digit_end         ; Only change led if the button has just been pushed
;               XOR  R0  R1
;               BEQ  maybe_increment_digit_end
;              LOAD  R1  DIGITS_ARR
;              ADD   R1  R3
;              LOAD  R0  [GB+R1]    ;  load the digit value
;               ADD  R0  1
;               MOD  R0  16
;              STOR  R0  [GB+R1]
;maybe_increment_digit_end:
;                RTS



; R0 is value to be shifted, result will be in this register
; R1 is number of bits to shift right
shift_bits:
        CMP  R1  0
shift_bits_cond:
        BEQ  shift_bits_end
        MULS  R0  2 ; shift left
        SUB  R1  1
        BRA shift_bits_cond
shift_bits_end:
        RTS


;set_digit:  ; R0 should be the value of the digit and R1 should be the offset in the DIGITS array
;               MOD  R0  16
;               LOAD R2  GB  ; GODDAMN DUMB DEBUGGER
;               LOAD R3  R1
;               ADD  R3  R2  ; GODDAMN DUMB DEBUGGER
;               ADD  R3  DIGITS_ARR
;              STOR  R0  [R3]
;               RTS

;      Routine Hex7Seg maps a number in the range [0..15] to its hexadecimal
;      representation pattern for the 7-segment display.
;      R0 : upon entry, contains the number
;      R1 : upon exit,  contains the resulting pattern
;
Hex7Seg     :  BRS  Hex7Seg_bgn  ;  push address(tbl) onto stack and proceed at "bgn"
Hex7Seg_tbl : CONS  %01111110    ;  7-segment pattern for '0'
              CONS  %00110000    ;  7-segment pattern for '1'
              CONS  %01101101    ;  7-segment pattern for '2'
              CONS  %01111001    ;  7-segment pattern for '3'
              CONS  %00110011    ;  7-segment pattern for '4'
              CONS  %01011011    ;  7-segment pattern for '5'
              CONS  %01011111    ;  7-segment pattern for '6'
              CONS  %01110000    ;  7-segment pattern for '7'
              CONS  %01111111    ;  7-segment pattern for '8'
              CONS  %01111011    ;  7-segment pattern for '9'
              CONS  %01110111    ;  7-segment pattern for 'A'
              CONS  %00011111    ;  7-segment pattern for 'b'
              CONS  %01001110    ;  7-segment pattern for 'C'
              CONS  %00111101    ;  7-segment pattern for 'd'
              CONS  %01001111    ;  7-segment pattern for 'E'
              CONS  %01000111    ;  7-segment pattern for 'F'
Hex7Seg_bgn:   AND  R0  %01111   ;  R0 := R0 MOD 16 , just to be safe...
              LOAD  R1  [SP++]   ;  R1 := address(tbl) (retrieve from stack)
              LOAD  R1  [R1+R0]  ;  R1 := tbl[R0]
               RTS

