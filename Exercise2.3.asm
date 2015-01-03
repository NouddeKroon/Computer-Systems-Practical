;
;      2011.10.11:  author:  Rob Hoogerwoord
;
;      2013.10.29:  removed errors in the annotation [RH]
;
;      This routine continuously reads the intput buttons and copies them to the
;      LED outputs. In addition, if Button 0 is pressed this increases a modulo
;      16 counter which is displayed at the right-most digit of the display,
;      and, similarly, if Button 1 is pressed this increases a modulo 16 counter
;      which is displayed at the second right-most digit of the display.
;
;
@CODE

   IOAREA      EQU  -16  ;  address of the I/O-Area, modulo 2^18
    INPUT      EQU    7  ;  position of the input buttons (relative to IOAREA)
   OUTPUT      EQU   11  ;  relative position of the power outputs
   DSPDIG      EQU    9  ;  relative position of the 7-segment display's digit selector
   DSPSEG      EQU    8  ;  relative position of the 7-segment display's segments
    TIMER      EQU   13  ;  rel pos of timer in I/O area
    ; GLOBALS
    INPUTS     EQU   1

  begin :      BRA  main         ;  skip subroutine Hex7Seg
;
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
;
;      The body of the main program
;
   main :     LOAD  R5  IOAREA   ;  R5 := "address of the area with the I/O-registers"
              LOAD  R2  [R5+TIMER]  ; R2 will keep the scheduled time to perform task
              LOAD  R4  0  ; R4 will keep the bit pattern for the leds output state
;
loop :
               SUB  R2  5000    ; the timer uses a 10kHz frequency and our task is
                                ; to be performed once every half of a second
loop_wait :
               CMP  R2  [R5+TIMER]  ; busy waiting taking account of timer underflow
               BMI  loop_wait
loop_task_blink :
               XOR  R4  %01  ; flip bit0 to change led state for LED0
loop_task_but7 :
              LOAD  R0  [GB+INPUTS]  ; load the prev state of the input buttons
              LOAD  R1  [R5+INPUT]   ; load state input buttons
              STOR  R1  [GB+INPUTS]   ; store the cur state as the prev state
               AND  R0  %010000000   ; select only but7
               AND  R1  %010000000   ; select only but7
               BEQ  loop_end         ; Only change led if the button has just been pushed
               XOR  R0  R1           ; if but7 changed state
               BEQ  loop_end
               XOR  R4  R0           ; flip bit7 to change the state of led7
loop_end :
               STOR R4  [R5+OUTPUT]  ; set LEDs
               BRA  loop
