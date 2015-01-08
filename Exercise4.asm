@DATA
    adval      DW    $0
    ; ARRAYS
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
    LEDS_ARRAY EQU   8
    ; GLOBALS

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

loop :
               SUB  R4  10    ; the timer uses a 10kHz frequency and our tasks are
                              ; to be performed once every 1000st of a second
;loop_wait:
;               CMP  R4  [R5+TIMER]  ; busy waiting taking account of timer underflow
;               BMI  loop_wait
loop_ad_read:
              LOAD  R0  [R5+ADCONV]
              AND   R0  255
              STOR
loop_task_light_single_display:
              LOAD  R1  DIGITS_ARR
              ADD   R1  R3
              LOAD  R0  [GB+R1]    ;  load the digit value
               BRS  Hex7Seg      ;  translate (value in) R0 into a display pattern
loop_task_light_single_display_dot0:
               CMP  R3  2
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
loop_end :
               BRA  loop
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
