;Config
			TIME EQU 0xDC05					;Timer value, 0xFFFF - 9216 = 0xDC00, 5 extra step to jump and step this value
			TCYL EQU 0x64					;Timer cycle, 100 (0x64). @11.0529MHz, 12T, 1s = 9216 * 100 steps

;Define
			HOU_H DATA 0x20					;Memory address for 6 time values
			HOU_L DATA 0x21
			MIN_H DATA 0x22
			MIN_L DATA 0x23
			SEC_H DATA 0x24
			SEC_L DATA 0x25
			TIMER DATA 0x26

;Vector table, reserved P-ROM
			ORG 0x0000
			JMP INI
			ORG 0x001B
			JMP PROCESS

;Ini
INI:
			MOV P1, #0x00					;Reset I/O
			MOV P2, #0x00
			MOV P3, #0x00
			MOV HOU_H, #0x00				;Reset time values
			MOV HOU_L, #0x00
			MOV MIN_H, #0x00
			MOV MIN_L, #0x00
			MOV SEC_H, #0x00
			MOV SEC_L, #0x00
			MOV TMOD, #0x10					;Enable time interupt (16-bit)
			MOV TL1, #LOW TIME				;Set timer
			MOV TH1, #HIGH TIME
			MOV TIMER, #TCYL				;Set timer cycle counter
			SETB TR1
			SETB ET1
			SETB EA
			JMP $							;Wait for timer interupt

;Process output
PROCESS:
			;Check if 1 second passed
			MOV TL1, #LOW TIME				;Reset timer
			MOV TH1, #HIGH TIME
			DJNZ TIMER, WAIT				;Timer cycle counter decrements, if not zero, do nothing
			;+1s
			MOV TIMER, #TCYL				;Reset timer cycle counter
			MOV R0, #0x25					;Set pointers for time values, first at SEC_L
			MOV R1, #0x01					;Set carry flag
			ACALL F_10INC					;Increment time value
			ACALL F_06INC
			ACALL F_10INC
			ACALL F_06INC
			ACALL F_10INC
			ACALL F_03INC
			;Check user interface
			MOV P3 #0xFF
			MOV A P3
			
			
			;Update time value to I/O
			ACALL F_UPDATE					;Update I/O
WAIT:		RETI							;Exit the interupt process, wait for another interupt

;Function: Increment time value (Common exit code)
F_10INC:
			CJNE R1, #0x01, F_INC_ED		;Do nothing if no carry
			INC @R0							;Increment time value
			MOV R1, #0x00
			CJNE @R0, #0x0A, F_INC_ED		;Do nothing if does not reach 10, otherwise set flag (for next INC function)
			MOV R1, #0x01
			MOV @R0, #0x00					;Reset current value
			JMP F_INC_ED					;Return
F_06INC:
			CJNE R1, #0x01, F_INC_ED
			INC @R0
			MOV R1, #0x00
			CJNE @R0, #0x06, F_INC_ED		;Do nothing if does not reach 10
			MOV R1, #0x01
			MOV @R0, #0x00
			JMP F_INC_ED
F_03INC:
			CJNE R1, #0x01, F_INC_ED
			INC @R0
			;MOV R1, #0x00					;Last value, no need to reset carry flag
			CJNE @R0, #0x02, F_INC_ED		;Do some thing if 2 and last value is 4
			INC R0							;Point to HOU_L
			CJNE @R0, #0x04, F_INC_ED
			MOV HOU_H, #0x00				;Reset all values when hour is 24
			MOV HOU_L, #0x00
			;MOV MIN_H, #0x00
			;MOV MIN_L, #0x00
			;MOV SEC_H, #0x00
			;MOV SEC_L, #0x00
			JMP F_INC_ED
F_INC_ED:
			DEC R0							;Pointer set to next time value
			RET
			
;Function: Increment time value (Common exit code)
F_10DEC:
			CJNE R1, #0x01, F_INC_ED		;Do nothing if no carry
			INC @R0							;Increment time value
			MOV R1, #0x00
			CJNE @R0, #0x0A, F_INC_ED		;Do nothing if does not reach 10, otherwise set flag (for next INC function)
			MOV R1, #0x01
			MOV @R0, #0x00					;Reset current value
			JMP F_INC_ED					;Return
F_06DEC:
			CJNE R1, #0x01, F_INC_ED
			INC @R0
			MOV R1, #0x00
			CJNE @R0, #0x06, F_INC_ED		;Do nothing if does not reach 10
			MOV R1, #0x01
			MOV @R0, #0x00
			JMP F_INC_ED
F_03DEC:
			CJNE R1, #0x01, F_INC_ED
			INC @R0
			;MOV R1, #0x00					;Last value, no need to reset carry flag
			CJNE @R0, #0x02, F_INC_ED		;Do some thing if 2 and last value is 4
			INC R0							;Point to HOU_L
			CJNE @R0, #0x04, F_INC_ED
			MOV HOU_H, #0x00				;Reset all values when hour is 24
			MOV HOU_L, #0x00
			;MOV MIN_H, #0x00
			;MOV MIN_L, #0x00
			;MOV SEC_H, #0x00
			;MOV SEC_L, #0x00
			JMP F_INC_ED
F_DEC_ED:
			DEC R0							;Pointer set to next time value
			RET

;Function: Update I/O for second
F_UPDATE:
			MOV A, HOU_H					;Get I/O for hour
			RL A							;Shift left 4 bit
			RL A
			RL A
			RL A
			ADD A, HOU_L					;Adding up low value
			MOV R7, A						;Save value to register
			MOV A, MIN_H					;Get I/O for minute
			RL A
			RL A
			RL A
			RL A
			ADD A, MIN_L
			MOV R6, A
			MOV A, SEC_H					;Get I/O for second
			RL A
			RL A
			RL A
			RL A
			ADD A, SEC_L
			MOV R5, A
			CJNE R6, #0x00, F_UP_DIT		;Tube cycle every 1 hour to prevent tube demage
F_UP_CYL:	MOV A, R5						;Check if SEC_H is 0: 0000xxxx AND 11110000 = 00000000; 0010xxxx AND 11110000 = 00100000
			ANL A, #0xF0
			JNZ F_UP_DIT
			MOV A, R5
			MOV R7, A						;Tube cycle, set 
			MOV R6, A
F_UP_DIT:	MOV P2, R7						;Update I/O for hour (R7->P2), minute (R6-P1), second (R5-P1)
			MOV P1, R6
			MOV P0, R5
			RET

;END
			END
