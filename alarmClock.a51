;|-----------------------------------------------------------|
;| INSTITUTO TECNOLOGICO DE ESTUDIOS SUPERIORES DE OCCIDENTE |
;| Microprocessor and microcontroller fundamentals           |
;|                                                           |
;| AUTHORS:   Narda Ibarra                                   |
;|            Kury Vazquez                                   |
;|            Diego Lopez                                    |
;|-----------------------------------------------------------|

; Clock address values
CLK_SECL EQU R1        
CLK_SECH EQU R2
CLK_MINL EQU R3
CLK_MINH EQU R4
CLK_HOURL EQU R5
CLK_HOURH EQU R6

        
; Alarm address values
ALARM_MINL EQU 40H 		
ALARM_MINH EQU 41H
ALARM_HOURL EQU 42H
ALARM_HOURH EQU 43H
 

; Binary selector for displays 
DISPLAY_1 EQU 1H    ;0001 b
DISPLAY_2 EQU 2H    ;0010 b
DISPLAY_3 EQU 4H    ;0100 b
DISPLAY_4 EQU 8H    ;1000 b 

;---------------- Interruptions -----------------------/

ORG     0000H   			;Reset interrupt (External Interrupt 0)
JMP     START 				;go to start on reset 

ORG     000BH   			;Timer 0 interrupt (Overflow)
JMP		COUNT_SECONDS


ORG     001BH   			;Timer 1 interrupt (Overflow)
JMP		MULTIPLEXOR                  
  


;---------------- Initial values -----------------------/
ORG		0040H

START: 			MOV		DPTR, #0300H 		;Lookup table
                MOV		P2,	#0FFH			;Set all displays
                MOV		R0, #14H			;Counter to create 1 exact second (20 * 50 ms)
                MOV 	IE, #10001010b 		;enable interrupts (global, timer 0 and timer 1)

                ;Set initial clock to 12:00
                MOV	CLK_SECL, #0H
                MOV	CLK_SECH, #0H
                MOV	CLK_MINL, #0H
                MOV	CLK_MINH, #0H
                MOV CLK_HOURL, #2H
                MOV CLK_HOURH, #1H

                ;Set inital alarm to 00:00
                MOV	ALARM_MINL, #0H
                MOV	ALARM_MINH, #0H
                MOV ALARM_HOURL, #0H
                MOV ALARM_HOURH, #0H


                ;Timers
                MOV 	TMOD, #11H 			;Set timer 0 and timer 1 to MOD 1	

                ;Timer 0 50 ms
                MOV 	TH0, #03CH
                MOV 	TL0, #0B0H

                ;Timer 1 1 us
                MOV 	TH1, #0FCH
                MOV 	TL1, #018H

                ;Start timers
                SETB 	TR0
                SETB 	TR1

                ;Counter to multiplex the 4 displays (clock)
                MOV R7, #04H

                ;Counter to multiplex the 4 displays (alarm)
                MOV 65H, #04

                SETB P3.2; Switch mode (1 alarm / 0 clock)
                SETB P3.3; Button to increase minutes 
                SETB P3.4; reset clock
                SETB P3.5; reset alarm

;--------------------main program--------------------------/	
                ;Check if clock reset is pressed
MAIN:			JNB P3.4,   IS_ALARM_RESET
                SJMP RESET_CLOCK
                SJMP  MAIN

                ;Check if alarm reset is pressed
IS_ALARM_RESET:	JNB P3.5, IS_ALARM_ON		
                SJMP RESET_ALARM
                
                ;Check if alarm and clock coincide, if so, then triggers buzzer
IS_ALARM_ON:	MOV A, CLK_MINL
                CJNE A, ALARM_MINL,STOP_BUZZER
                MOV A, CLK_MINH
                CJNE A, ALARM_MINH,STOP_BUZZER
                MOV A, CLK_HOURL
                CJNE A, ALARM_HOURL,STOP_BUZZER
                MOV A, CLK_HOURH
                CJNE A, ALARM_HOURH,STOP_BUZZER
                CLR P1.1
                SJMP MAIN

STOP_BUZZER:    SETB P1.1
                SJMP MAIN

RESET_CLOCK:    MOV	CLK_SECL, #0H
                MOV	CLK_SECH, #0H
                MOV	CLK_MINL, #0H
                MOV	CLK_MINH, #0H
                MOV CLK_HOURL, #2H
                MOV CLK_HOURH, #1H
                SJMP MAIN


RESET_ALARM:    MOV	ALARM_MINL, #0H
                MOV	ALARM_MINH, #0H
                MOV ALARM_HOURL, #0H
                MOV ALARM_HOURH, #0H
                SJMP MAIN


;-------------------timer 0 interruption routines--------------------------/	

                ;Clears and restarts the timer 
                ;Checks if 20 cyles loop is over, if so, increases one sec
COUNT_SECONDS: 	CLR 	TR0
                MOV 	TH0, #03CH 
                MOV 	TL0, #0B0H
                SETB 	TR0
                DJNZ 	R0, EXIT_INT_T0
                SJMP	IS_INC_BUTTON

                ;Restart 20 cyle loop 
END_SEC:		MOV		R0, #14H

                ;returns from interruption 
EXIT_INT_T0:		RETI

                ;Checks if increase button is pressed
IS_INC_BUTTON:	JB P3.3, CHECK_MODE
                SJMP INC_SEC

                ;Checks if it is on alarm or clock mode
CHECK_MODE:	    JNB P3.2, INC_A_MIN
                JMP INC_C_MIN


                ;increase clock one second
                ;in sexagesimal number system
 INC_SEC:		INC CLK_SECL
                CJNE CLK_SECL, #10d, END_SEC
                MOV CLK_SECL, #00H

                INC CLK_SECH
                CJNE CLK_SECH, #06d, END_SEC
                MOV CLK_SECH, #00H

                INC CLK_MINL
                CJNE CLK_MINL, #10d, END_SEC
                MOV CLK_MINL, #00H

                INC CLK_MINH
                CJNE CLK_MINH, #06d, END_SEC
                MOV CLK_MINH, #00H
                        
                INC CLK_HOURL 
                CJNE CLK_HOURL, #4d, CONTINUE_HL  
                CJNE CLK_HOURH, #02d, CONTINUE_HL 
                MOV CLK_HOURL, #00H 
                MOV CLK_HOURH, #00H	

                SJMP END_INC_SEC

                ;Increase one minute to alarm
                ;sexagesimal number system
INC_A_MIN:  	INC ALARM_MINL
                MOV A, ALARM_MINL
                CJNE A, #10d, INC_SEC
                MOV ALARM_MINL, #00H

                INC ALARM_MINH
                MOV A, ALARM_MINH
                CJNE A, #6d, INC_SEC
                MOV ALARM_MINH, #00H

                INC ALARM_HOURL
                MOV A, ALARM_HOURL
                CJNE A, #4d, CONTINUE_AHL
                MOV A, ALARM_HOURH
                CJNE A, #2d, CONTINUE_AHL
                MOV ALARM_HOURL, #00H
                MOV ALARM_HOURH, #00H
                
                SJMP INC_SEC ;returns to increase clock second
                
                
                ;Increase one minute to alarm
                ;sexagesimal number system
INC_C_MIN:	    INC CLK_MINL
                CJNE CLK_MINL, #10d, INC_SEC
                MOV CLK_MINL, #00H

                INC CLK_MINH
                CJNE CLK_MINH, #06d, INC_SEC
                MOV CLK_MINH, #00H

                INC CLK_HOURL 
                CJNE CLK_HOURL, #4d, CONTINUE_BHL
                CJNE CLK_HOURH, #02d, CONTINUE_BHL
                MOV CLK_HOURL, #00H  
                MOV CLK_HOURH, #00H	
                JMP INC_SEC

END_INC_SEC:	SJMP END_SEC


            ; INCREASES HIGH HOUR AFTER VERIFYING HOUR IS NOT 24:00
CONTINUE_HL:	CJNE CLK_HOURL, #10d, END_SEC
                MOV CLK_HOURL, #00H
                INC CLK_HOURH
                SJMP END_SEC

CONTINUE_AHL: 	MOV A, ALARM_HOURL
                CJNE A, #10d, INC_SEC
                MOV ALARM_HOURL, #00H
                INC ALARM_HOURH
                SJMP INC_SEC

CONTINUE_BHL: 	CJNE CLK_HOURL, #10d, INC_SEC
                MOV CLK_HOURL, #00H
                INC CLK_HOURH
                JMP INC_SEC	


 ;-------------------timer 1 interruption routines--------------------------/              
                ;Clears and restarts the timer 
MULTIPLEXOR:    MOV 40H, A
                CLR TR1
                MOV TH1, #0FCH
                MOV TL1, #018H
                SETB TR1

;               /--DISPLAY 1--/				
                ;Checks if alarm mode is on
                JNB P3.2, ALARM1
                
                ;Turns off led

                SETB P1.0

                ;Checks if needs to turn on this display 
                CJNE R7, #04H, CLOCK2		
                
                ; moves BDC decoder clock value to P.0 and turns on display 1
                MOV P2, #00H
                MOV A, CLK_MINL 
                MOVC A, @A+DPTR
                MOV P0, A
                MOV P2, #DISPLAY_1
                JMP UPDATE_C_CNTR

                ;Turns on led
ALARM1: 	    CLR P1.0

                ;Checks if needs to turn on this display 
                MOV A, 65H
                CJNE A, #04H, CLOCK2

                ;moves BDC decoder alarm value to P.0 and turns on display 1
                MOV P2, #00H
                MOV A, ALARM_MINL
                MOVC A, @A+DPTR
                MOV P0, A
                MOV P2, #DISPLAY_1
                JMP UPDATE_A_CNTR		



;               /--DISPLAY 2--/						
        
                ;Checks if alarm mode is on
CLOCK2:        	JNB P3.2, ALARM2

                ;Turns off led
                SETB P1.0

                ;Checks if needs to turn on this display
                CJNE R7, #03H, CLOCK3			
                
                ; moves BDC decoder clock value to P.0 and turns on display 2
                MOV P2, #00H
                MOV A, CLK_MINH 	
                MOVC A, @A+DPTR
                MOV P0, A
                MOV P2, #DISPLAY_2
                JMP UPDATE_C_CNTR
        

                ;Turns on led
ALARM2:      	CLR P1.0

                ;Checks if needs to turn on this display 
                MOV A, 65H
                CJNE A, #03H, CLOCK3

                ;moves BDC decoder alarm value to P.0 and turns on display 2
                MOV P2, #00H
                MOV A, ALARM_MINH
                MOVC A, @A+DPTR
                MOV P0, A
                MOV P2, #DISPLAY_2
                JMP UPDATE_A_CNTR	
        
;               /--DISPLAY 3--/						
    
                ;Checks if alarm mode is on
CLOCK3:           JNB P3.2, ALARM3

                ;Turns off led
                SETB P1.0

                ;Checks if needs to turn on this display
                CJNE R7, #02H, CLOCK4

                ; moves BDC decoder clock value to P.0 and turns on display 3
                MOV P2, #00H
                MOV A, CLK_HOURL 
                MOVC A, @A+DPTR
                MOV P0, A
                MOV P2, #DISPLAY_3
                JMP UPDATE_C_CNTR
        

                ;Turns on led
ALARM3: 	    CLR P1.0

                ;Checks if needs to turn on this display 
                MOV A, 65H
                CJNE A, #02H, CLOCK4

                ;moves BDC decoder alarm value to P.0 and turns on display 3
                MOV P2, #00H
                MOV A, ALARM_HOURL
                MOVC A, @A+DPTR
                MOV P0, A
                MOV P2, #DISPLAY_3
                JMP UPDATE_A_CNTR
        
;               /--DISPLAY 4--/							
        
                ;Checks if alarm mode is on
CLOCK4:           JNB P3.2, ALARM4

                ;Turns off led
                SETB P1.0

                ;Checks if needs to turn on this display
                CJNE R7, #01H, UPDATE_C_CNTR
                MOV P2, #00H

                ; moves BDC decoder clock value to P.0 
                MOV A, CLK_HOURH 
                MOVC A, @A+DPTR
                MOV P0, A

                ;Checks if High hour is zero, if so, leaves it off 
                CJNE CLK_HOURH, #00H, ENABLE_DISPLAY4_C	
                SJMP RSTRT_COUNT_C


ENABLE_DISPLAY4_C: MOV P2, #DISPLAY_4


                ;Restart counter to multiplex clock
RSTRT_COUNT_C:  MOV R7, #05H
                JMP UPDATE_C_CNTR
    
                 ;Turns off led
ALARM4:     	CLR P1.0

                 ;Checks if needs to turn on this display 
                MOV A, 65H
                CJNE A, #01H, UPDATE_C_CNTR

                 ;moves BDC decoder alarm value to P.0
                MOV P2, #00H
                MOV A, ALARM_HOURH
                MOVC A, @A+DPTR
                MOV P0, A
                MOV A, ALARM_HOURH

                ;Checks if High hour is zero, if so, leaves it off 
                CJNE A, #00H, ENABLE_DISPLAY4_A
                SJMP RSTRT_COUNT_A


ENABLE_DISPLAY4_A:	MOV P2, #DISPLAY_4
        

                ;Restarts counter to multiplex alarm
RSTRT_COUNT_A:	MOV 65H, #05H
                JMP UPDATE_A_CNTR		
        

                ;decrease count to multiplex displays 
UPDATE_C_CNTR:  DEC R7
                SJMP EXIT_INT_T1
    
UPDATE_A_CNTR: 	DEC 65H

                ;returns from interruption 
EXIT_INT_T1:	RETI




;BDC DECODER LOOKUP TABLE 
ORG 0300H 
DB		0C0H // 0
DB		0F9H // 1
DB 	    0A4H // 2
DB 		0B0H // 3
DB 		099H // 4
DB		092H // 5
DB		082H // 6
DB		0F8H // 7
DB		080H // 8
DB		090H // 9
END 