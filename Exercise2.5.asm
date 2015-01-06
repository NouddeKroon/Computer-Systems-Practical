@CODE

   IOAREA      EQU  -16  ;  address of the I/O-Area, modulo 2^18
    INPUT      EQU    7  ;  position of the input buttons (relative to IOAREA)
   OUTPUT      EQU   11  ;  relative position of the power outputs
   DSPDIG      EQU    9  ;  relative position of the 7-segment display's digit selector
   DSPSEG      EQU    8  ;  relative position of the 7-segment display's segments
    TIMER      EQU   13  ;  rel pos of timer in I/O area
    ; GLOBALS
    INPUTS     EQU   1
    DIGITS_ARR EQU   2   ;  Digits to be shown on the segment displays, length = 6
    ; LENGTH GLOBAL VARS
    DIGITS_LEN EQU   6

   main :
              LOAD  R0  0  ; initilization value
              ;LOAD  R1  0  ; first offset into DIGITS
              ;BRS   set_digit
              ;LOAD  R1  1  ; offset into DIGITS
              ;BRS   set_digit
              ;LOAD  R1  2  ; offset into DIGITS
              ;BRS   set_digit
              ;LOAD  R1  3  ; offset into DIGITS
              ;BRS   set_digit
              ;LOAD  R1  4  ; offset into DIGITS
              ;BRS   set_digit
              ;LOAD  R1  5  ; offset into DIGITS
              ;BRS   set_digit

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

loop :
               SUB  R4  10    ; the timer uses a 10kHz frequency and our tasks are
                              ; to be performed once every 1000st of a second
loop_wait:
               CMP  R4  [R5+TIMER]  ; busy waiting taking account of timer underflow
               BMI  loop_wait
loop_task_light_single_display:
              LOAD  R1  DIGITS_ARR
              ADD   R1  R3
              LOAD  R0  [GB+R1]    ;  load the digit value
               BRS  Hex7Seg      ;  translate (value in) R0 into a display pattern
              STOR  R1  [R5+DSPSEG] ; and place this in the Display Element
              LOAD  R0  %01  ; setup shift bits for display bit
              LOAD  R1  R3
              BRS shift_bits
              STOR  R0  [R5+DSPDIG] ; activate Display Element nr. 0
              ; increment idx
              ADD   R3  1
              MOD   R3  DIGITS_LEN
loop_increment_digit:
              PUSH R3
              LOAD R3 0
               BRS  maybe_increment_digit
               ADD R3 1
               BRS  maybe_increment_digit
               ADD R3 1
               BRS  maybe_increment_digit
               ADD R3 1
               BRS  maybe_increment_digit
               ADD R3 1
               BRS  maybe_increment_digit
               ADD R3 1
               BRS  maybe_increment_digit
               PULL R3
loop_increment_digit_end:
              LOAD  R1  [R5+INPUT]
              STOR  R1  [GB+INPUTS]



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
               BRA  loop

; R3 is current idx
maybe_increment_digit:
              LOAD  R0  1
              LOAD  R1  R3
              BRS shift_bits
              LOAD  R2  R0
              LOAD  R0  [GB+INPUTS]  ; load the prev state of the input buttons
              LOAD  R1  [R5+INPUT]   ; load state input buttons
               AND  R0  R2 ; select only button idx
               AND  R1  R2 ; select only button idx
               BEQ  maybe_increment_digit_end         ; Only change led if the button has just been pushed
               XOR  R0  R1
               BEQ  maybe_increment_digit_end
              LOAD  R1  DIGITS_ARR
              ADD   R1  R3
              LOAD  R0  [GB+R1]    ;  load the digit value
               ADD  R0  1
               MOD  R0  16
              STOR  R0  [GB+R1]
maybe_increment_digit_end:
                RTS



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


set_digit:  ; R0 should be the value of the digit and R1 should be the offset in the DIGITS array
               MOD  R0  16
               LOAD R2  GB  ; GODDAMN DUMB DEBUGGER
               LOAD R3  R1
               ADD  R3  R2  ; GODDAMN DUMB DEBUGGER
               ADD  R3  DIGITS_ARR
              STOR  R0  [R3]
               RTS

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

