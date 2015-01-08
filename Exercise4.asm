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
              LOAD  R5  IOAREA

loop :
        CMP  R0  R0
loop_end :
               BRA  loop
`
shift_bits:
        CMP  R1  0
shift_bits_cond:
        BEQ  shift_bits_end
        MULS  R0  2 ; shift left
        SUB  R1  1
        BRA shift_bits_cond
shift_bits_end:
        RTS
