@DATA
	counter  	DW  0
	inputs   	DW  0
	digit_idx	DW	0
@CODE
   IOAREA      EQU  -16  ;  address of the I/O-Area, modulo 2^18
    INPUT      EQU    7  ;  position of the input buttons (relative to IOAREA)
   OUTPUT      EQU   11  ;  relative position of the power outputs
   DSPDIG      EQU    9  ;  relative position of the 7-segment display's digit selector
   DSPSEG      EQU    8  ;  relative position of the 7-segment display's segments
    TIMER      EQU   13  ;  rel pos of timer in I/O area
    
    ; ARRAYS
    DIGITS_ARR EQU   10   ;  Digits to be shown on the segment displays, length = 6
    ; LENGTH GLOBAL ARRAYS
    DIGITS_LEN EQU   6
	TIMER_INTR_ADDR  EQU  16
    TIMER_DELTA  EQU  100

   main :
			LOAD R0  timer_interrupt
			ADD  R0  R5
			LOAD R1  TIMER_INTR_ADDR
			STOR R0  [R1]
			LOAD R5  IOAREA
			LOAD R0  0	
			SUB  R0  [R5+TIMER]
			STOR R0  [R5+TIMER]
			SETI 8
	
	loop:
			LOAD R4  [R5+INPUT]
;			
	loop_button_0:	
			LOAD R0 R4
			AND  R0 %01
			BEQ  loop_button_1
			LOAD R1  [GB+inputs]
			AND  R1  %01
			BNE  loop_button_1
			LOAD R0  [GB+counter]
			ADD  R0  1
			MOD  R0  10000
			STOR R0  [GB+counter]
			
	loop_button_1:
			LOAD R0 R4
			AND  R0 %010
			BEQ  loop_button_7
			LOAD R1  [GB+inputs]
			AND  R1  %010
			BNE  loop_button_7
			LOAD R0  [GB+counter]
			BEQ  loop_button_1_modulo
			SUB  R0  1
			BRA  loop_button_1_end
	loop_button_1_modulo:
			LOAD R0 9999
	loop_button_1_end:
			STOR R0  [GB+counter]
			
	loop_button_7:
			LOAD R0 R4
			AND  R0 %010000000
			BEQ  loop_end
			LOAD R1  [GB+inputs]
			AND  R1  %010000000
			BNE  loop_end
			LOAD R0  0
			STOR R0  [GB+counter]

	loop_end:
			STOR R4  [GB+inputs]
			BRA loop
;
;
	timer_interrupt:
			LOAD  R0  TIMER_DELTA
			STOR  R0  [R5+TIMER]
			LOAD  R4  [GB+counter]
			LOAD  R0  R4
			DVMD  R0  10
			LOAD  R2  [GB+digit_idx]
			BNE   timer_interrupt_1
			LOAD  R0  R1
			BRS   Hex7Seg
			STOR  R1  [R5+DSPSEG]
			LOAD  R0  %01
			STOR  R0  [R5+DSPDIG]
			BRA   timer_interrupt_end
	timer_interrupt_1:
			DVMD  R0  10
			CMP   R2   1
			BNE   timer_interrupt_2
			LOAD  R0  R1
			BRS   Hex7Seg
			STOR  R1  [R5+DSPSEG]
			LOAD  R0  %010
			STOR  R0  [R5+DSPDIG]
	timer_interrupt_2:
			DVMD  R0  10
			CMP   R2   2
			BNE   timer_interrupt_3
			LOAD  R0  R1
			BRS   Hex7Seg
			STOR  R1  [R5+DSPSEG]
			LOAD  R0  %0100
			STOR  R0  [R5+DSPDIG]
	timer_interrupt_3:
			DVMD  R0  10
			CMP   R2   3
			BNE   timer_interrupt_end
			LOAD  R0  R1
			BRS   Hex7Seg
			STOR  R1  [R5+DSPSEG]
			LOAD  R0  %01000
			STOR  R0  [R5+DSPDIG]
	timer_interrupt_end:
			ADD   R2  1
			MOD   R2  4
			STOR  R2  [GB+digit_idx]
			SETI  8
			RTE

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

