@DATA
   inputs  DW 0
   green_leds  DW  0

@CODE

   IOAREA      EQU  -16  ;  address of the I/O-Area, modulo 2^18
    INPUT      EQU    7  ;  position of the input buttons (relative to IOAREA)
   OUTPUT      EQU   11  ;  relative position of the power outputs
   DSPDIG      EQU    9  ;  relative position of the 7-segment display's digit selector
   DSPSEG      EQU    8  ;  relative position of the 7-segment display's segments
    TIMER      EQU   13  ;  rel pos of timer in I/O area
    GREEN_OUTPUT  EQU  10
    ; GLOBALS
    TIMER_INTR_ADDR  EQU  2 * 8
    TIMER_DELTA  EQU  10000

main :
           LOAD R0  timer_interrupt
           ADD  R0  R5
           LOAD R1  TIMER_INTR_ADDR
           STOR R0  [R1]
           SETI 8
           LOAD R5  IOAREA   ;  R5 := "address of the area with the I/O-registers"
           LOAD R0  0
           SUB  R0  [R5+TIMER]
           STOR R0  [R5+TIMER]

loop :
           LOAD R0  [R5+INPUT]
           STOR R0  [GB+inputs]
           BRA  loop

timer_interrupt:
        LOAD  R0  TIMER_DELTA
        STOR  R0  [R5+TIMER]
        LOAD  R1  [GB+inputs]
        STOR  R1  [R5+OUTPUT]
        ;LOAD  R2  [GB+green_leds]
        ;XOR   R2  %0111
        ;STOR  R2  [R5+GREEN_OUTPUT]
        SETI  8
        RTE

