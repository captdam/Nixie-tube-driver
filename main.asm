;Config
			TIME EQU 0xDC05					;Timer value, 0xFFFF - 9216 = 0xDC00, 5 extra step to jump and step this value
			TCYL EQU 0x64					;Timer cycle, 100 (0x64). @11.0529MHz, 12T, 1s = 9216 * 100 steps


;Define
			TIMER DATA 0x23					;Memory for core timer counter
			MEM_H DATA 0X22					;Memory for time values
			MEM_M DATA 0x21
			MEM_S DATA 0x20
			IO_H EQU P2						;I/O port for time values
			IO_M EQU P1
			IO_S EQU P0
			UI EQU P3						;I/O port for UI (setting)


;Vector table, reserved P-ROM
			ORG 0x0000
			JMP INI
			ORG 0x001B
			JMP PROCESS


;Ini
INI:
			;Reset
			MOV IO_H, #0x00					;Reset I/O
			MOV IO_M, #0x00
			MOV IO_S, #0x00
			MOV MEM_H, #0x00				;Reset memory for time values
			MOV MEM_M, #0x00
			MOV MEM_S, #0x00
			
			;Enable inner timer interupt
			MOV TMOD, #0x10					;Enable time interupt (16-bit mode)
			MOV TL1, #LOW TIME				;Set timer
			MOV TH1, #HIGH TIME
			MOV TIMER, #TCYL				;Set timer cycle counter
			SETB TR1
			SETB ET1
			SETB EA
			JMP $							;Wait for timer interupt


;Process output
PROCESS:
			;Reset timer
			MOV TL1, #LOW TIME
			MOV TH1, #HIGH TIME
			
			;Check if 1 second passed
			MOV A, TIMER					;Core timer counter decrements
			DEC A
			MOV TIMER, A
			JZ OK							;Core timer counter reaches 0, OK
			RETI							;Counter not reached, return
			OK:
			MOV TIMER, #TCYL				;Reset timer cycle counter
			
			;Time value operation
			TIME_INC:
			
			;Second++
			MOV R0, MEM_S
			INC R0
			MOV MEM_S, R0
			CJNE R0, #0x3C, SETTING			;Jump out if no carry from second (carry if 60)
			MOV MEM_S, #0x00				;Carry found, reset to zero
			
			;Minute++
			MOV R0, MEM_M
			INC R0
			MOV MEM_M, R0
			CJNE R0, #0x3C, SETTING
			MOV MEM_M, #0x00
			
			;Hour++
			MOV R0, MEM_H
			INC R0
			MOV MEM_H, R0
			CJNE R0, #0x18, SETTING
			MOV MEM_H, #0x00


;Check if user use setting interface, key is actived on low
;Notice: when setting, dont care the carry
SETTING:
			;Get UI input
			MOV UI, #0xFF
			NOP
			NOP
			MOV R1, UI
			
			;Check bit7: Hour++
			SET_H_INC:
			MOV A, R1
			ANL A, #0x80					;Leave the value of bit7, clear others (set to 0)
			JNZ SET_M_INC					;Bit is not 0, skip current
			MOV R0, MEM_H
			INC R0
			MOV MEM_H, R0
			CJNE R0, #0x18, SET_M_INC		;Overflow, reset
			MOV MEM_H, #0x00
			
			;Check bit6: Minute++
			SET_M_INC:
			MOV A, R1
			ANL A, #0x40
			JNZ SET_S_RST
			MOV R0, MEM_M
			INC R0
			MOV MEM_M, R0
			CJNE R0, #0x3C, SET_S_RST
			MOV MEM_M, #0x00
			
			;Check bit5: Second = 0
			SET_S_RST:
			MOV A, R1
			ANL A, #0x20
			JNZ SET_M_DEC
			MOV MEM_S, #0x00
			
			;Check bit4: Minute--
			SET_M_DEC:
			MOV A, R1
			ANL A, #0x10
			JNZ SET_H_DEC
			MOV R0, MEM_M
			DEC R0
			MOV MEM_M, R0
			CJNE R0, #0xFF, SET_H_DEC
			MOV MEM_M, #0x3B
			
			;Check bit3: Hour--
			SET_H_DEC:
			MOV A, R1
			ANL A, #0x08
			JNZ UPDATE
			MOV R0, MEM_H
			DEC R0
			MOV MEM_H, R0
			CJNE R0, #0xFF, UPDATE
			MOV MEM_H, #0x17


;Update I/O
UPDATE:
			;Get output value of P2 (Hour)
			MOV A, MEM_H
			MOV B, #0x0A
			DIV AB							;A is high, B is low
			RL A
			RL A
			RL A
			RL A
			ADD A, B
			MOV IO_H, A
			
			;Get output value of P1 (Minute)
			MOV A, MEM_M
			MOV B, #0x0A
			DIV AB	
			RL A
			RL A
			RL A
			RL A
			ADD A, B
			MOV IO_M, A
			
			;Get output value of P0 (Second)
			MOV A, MEM_S
			MOV B, #0x0A
			DIV AB	
			RL A
			RL A
			RL A
			RL A
			ADD A, B
			MOV IO_S, A
			

;Exit the interupt process, wait for another interupt
WAIT:
			RETI


;Just in case
ENDING:
			END
