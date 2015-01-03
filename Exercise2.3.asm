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

   main :     LOAD  R5  IOAREA   ;  R5 := "address of the area with the I/O-registers"
              LOAD  R2  [R5+TIMER]  ; R2 will keep the scheduled time to perform task
              LOAD  R4  0  ; R4 will keep the bit pattern for the leds output state
              LOAD  R3  0  ; maintain a loop counter for the blink task (at 100 0.5 seconds will have passed).
;
loop :
               SUB  R2  50    ; the timer uses a 10kHz frequency and our tasks are
                              ; to be performed once every 200st of a second
loop_wait :
               CMP  R2  [R5+TIMER]  ; busy waiting taking account of timer underflow
               BMI  loop_wait
loop_task_blink :
               ADD  R3  1     ; increment counter
               CMP  R3  100   ; when counter has reached 100 half a second will have passed
               BNE  loop_task_but7
               XOR  R4  %01   ; flip bit0 to change led state for LED0
              LOAD  R3  0     ; reset the counter
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
