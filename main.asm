;
; ********************************************
; * [Add Project title here]                 *
; * [Add more info on software version here] *
; * (C)20xx by [Add Copyright Info here]     *
; ********************************************
;
; Included header file for target AVR type
.NOLIST
.INCLUDE "tn2313Adef.inc" ; Header for ATTINY2313A
.LIST
;
; ============================================
;   H A R D W A R E   I N F O R M A T I O N   
; ============================================
;
; [Add all hardware information here]
;
; ============================================
;      P O R T S   A N D   P I N S 
; ============================================
;
; [Add names for hardware ports and pins here]
; Format: .EQU Controlportout = PORTA
;         .EQU Controlportin = PINA
;         .EQU LedOutputPin = PORTA2
;
; ============================================
;    C O N S T A N T S   T O   C H A N G E 
; ============================================
;
; [Add all constants here that can be subject
;  to change by the user]
; Format: .EQU const = $ABCD
;
; ============================================
;  F I X + D E R I V E D   C O N S T A N T S 
; ============================================
;
; [Add all constants here that are not subject
;  to change or calculated from constants]
; Format: .EQU const = $ABCD
  .equ res=0
	.equ sda=1
	.equ scl=2
	.equ _ddrb=ddrb
	.equ _portb=portb
; ============================================
;   R E G I S T E R   D E F I N I T I O N S
; ============================================
;
; [Add all register names here, include info on
;  all used registers without specific names]
; Format: .DEF rmp = R16
.DEF temp = R16 ; Multipurpose register
;
; ============================================
;       S R A M   D E F I N I T I O N S
; ============================================
;
.DSEG
.ORG  0X0060
; Format: Label: .BYTE N ; reserve N Bytes from Label:
;
; ============================================
;   R E S E T   A N D   I N T   V E C T O R S
; ============================================
;
.CSEG
.ORG $0000
	rjmp Main ; Reset vector
	reti ; Int vector 1
	reti ; Int vector 2
	reti ; Int vector 3
	reti ; Int vector 4
	reti ; Int vector 5
	reti ; Int vector 6
	reti ; Int vector 7
;
;
; ============================================
;     I N T E R R U P T   S E R V I C E S
; ============================================
;
; [Add all interrupt service routines here]
;
; ============================================
;     M A I N    P R O G R A M    I N I T
; ============================================
;
Main:
; Init stack
	ldi temp, LOW(RAMEND) ; Init LSB stack
	out SPL,temp
; Init Port A
	ldi temp,0 ; Direction Port A
	out DDRA,temp
; Init Port B
	ldi temp,(1<<DDB0)|(1<<DDB1)|(1<<DDB2) ; Direction Port B
	out DDRB,temp
	sei
;
; ============================================
;         P R O G R A M    L O O P
; ============================================
;
			cbi _portb,res
			rcall pause		;сброс дисплея
			sbi _portb,res
;		
			ldi r30,20
pss:		rcall pause
			dec r30
			brne pss
			rcall lcd_init

lcd_test:

			ldi r16,7		;палитра белым по черному	
			rcall set_color	;уст палитру
			rcall lcd_clr
			
			clt
			clr r6
			clr r7
			ldi r30,low(radiokot*2)
			ldi r31,high(radiokot*2)
			rcall text
	
			set
			clr r6
			ldi r16,8
			mov r7,r16
			rcall set_xy
			ldi r30,low(myy*2)
			ldi r31,high(myy*2)
			rcall text
	
			
			clt
			ldi r25,1
			ldi r16,16
			mov r7,r16
loop:			
			
			ldi r16,8
			add r7,r16
			clr r6
			rcall set_xy
			mov r16,r25
			push r16
			rcall set_color
			ldi r30,low(lcd_t230*2)
			ldi r31,high(lcd_t230*2)
			rcall text
			pop r16
			swap r16
			rcall set_color
			ldi r30,low(lcd_t230*2)
			ldi r31,high(lcd_t230*2)
			rcall text
			inc r25
			cpi r25,8
			brcs loop
						
			rcall i2c_stop
stop:
			rjmp stop		

radiokot:	.db 'R','A','D','I','O','K','O','T','.','R','U',0
myy:		.db 'm','q','u','!',0
lcd_t230:	.db 'L','C','D','_','T','2','3','0',0


text:		lpm r16,z+
			cpi r16,0
			breq text_ex
			push r31
			push r30
			rcall symbol
			pop r30
			pop r31
			rjmp text
text_ex:	ret

prb_17:
			ldi r23,17
p17:
			ldi r16,' '
			rcall symbol
			dec r23
			brne p17
			ret


pause:		clr r17
pz0:		rcall zad
			dec r17
			brne pz0

zad:		ldi r31,25
zad0:		dec r31
			brne zad0
			ret	
			
;инициализация
lcd_init:	ldi r19,$29			;lcd capacitance
			rcall lcd_com

			ldi r19,$ea			;v bias rate
			rcall lcd_com

			rcall i2c_start
			ldi r17,$78
			rcall i2c_out
			ldi r17,$81			;vbias pot
			rcall i2c_out
			ldi r17,$a8
			rcall i2c_out		;potentiometr
			rcall i2c_stop
			rcall pause

			ldi r19,$27			;temp comp
			rcall lcd_com

			ldi r19,$8b			;auto_increment order=1
			rcall lcd_com

			ldi r19,$af			;ldc enable
			rcall lcd_com	

			ldi r19,$d4			;256 colors
			rcall lcd_com
	
			ldi r19,$a1			;line rate
			rcall lcd_com

			rcall i2c_start
			ldi r17,$7a
			rcall i2c_out
			ret

;команда на дисплей
lcd_com:	;r19 команда
	
			rcall i2c_start
			ldi r17,$78
			rcall i2c_out
			mov r17,r19
			rcall i2c_out
			rcall i2c_stop
			rcall pause
			ret


set_xy:		;  r6 - x r7 - y
			rcall i2c_stop
			rcall i2c_start
			ldi r17,$78
			rcall i2c_out
			mov r17,r6
			andi r17,$0f
			rcall i2c_out
			rcall i2c_stop
	
			rcall i2c_start
			ldi r17,$78
			rcall i2c_out
			mov r17,r6
			swap r17
			andi r17,$07
			ori r17,$10
			rcall i2c_out
			rcall i2c_stop
	
			rcall i2c_start
			ldi r17,$78
			rcall i2c_out
			mov r17,r7
			andi r17,$0f
			ori r17,$60
			rcall i2c_out
			rcall i2c_stop
			rcall i2c_start
			ldi r17,$78
			rcall i2c_out
			mov r17,r7
			swap r17
			andi r17,$07
			ori r17,$70
			rcall i2c_out
			rcall i2c_stop
	
			rcall i2c_start
			ldi r17,$7a
			rcall i2c_out
			ret


i2c_start:
			sbi _ddrb,sda
			sbi _ddrb,scl
	
			sbi _portb,sda
			sbi _portb,scl
			nop
			nop
			cbi _portb,sda
			nop
			nop
			cbi _portb,scl
			ret

i2c_stop:
			sbi _ddrb,sda
			sbi _ddrb,scl

			cbi _portb,sda
			sbi _portb,scl
			nop
			nop
			sbi _portb,sda
			nop
			nop
			cbi _portb,scl
			ret
	

;r17 out i2c
i2c_out:
			push r17
			cbi _portb,sda
			sbi _ddrb,sda
			ldi r18,8
i2c_out1:
			sbrc r17,7
			sbi _portb,sda
			sbrs r17,7
			cbi _portb,sda
			nop
			sbi _portb,scl
			nop
			cbi _portb,scl
			lsl r17
			dec r18
			brne i2c_out1
			cbi _ddrb,sda
			sbi _portb,scl
			nop
			cbi _portb,scl
			pop r17
			ret	

;вывод символа r16   t=1 большие, t=0 маленькие
symbol:

			subi r16,$20
			ldi r30,low(znak*2)
			ldi r31,high(znak*2)
		
s0:
			cpi r16,0
			breq s1
			adiw r31:r30,5
			dec r16
			rjmp s0
	
s1:			ldi r21,5
	
s3:			lpm 
			rcall out_
			brtc s33
			lpm
			rcall out_
s33:
			adiw r31:r30,1
			dec r21
			brne s3
			clr r0
			rcall out_
			brtc s44
			clr r0
			rcall out_
s44:		ret

out_:
			ldi r20,8
s2:	
			mov r17,r5
			sbrc r0,0
			mov r17,r4	
			rcall i2c_out
			brtc s22
			rcall i2c_out
s22:
			ror r0
			dec r20
			brne s2
			inc r6
			rcall set_xy
			ret


shbyte:		; вывод байта r19 в НЕХ виде
			mov r16,r19	
			andi r16,$f0
			swap r16
			rcall tetr
			mov r16,r19
			andi r16,$0f
			rcall tetr
			ldi r16,' '
			rcall symbol
			ret
	
tetr:		;вывод мл тетрады r16
			cpi r16,10
			brcs te1
			ldi r17,$41-$0a
			rjmp te2
te1:
			ldi r17,$30
te2:
			add r16,r17
			rcall symbol
			ret

/*
цвета
 0- черный
 1- синий
 2- красный
 3- фиолетовый
 4- зеленый
 5- голубой
 6- желтый
 7- белый
 	установка палитры: старшая тетрада r16 цвет фона,мл часть - цвет тона ,если 07 то белым по черному
*/
set_color:
			ldi r30,low(color*2)
			push r30
			ldi r31,high(color*2)
			mov r17,r16
			andi r17,$07
			add r30,r17
			lpm r4,z
			pop r30
			mov r17,r16
			swap r17
			andi r17,$07
			add r30,r17
			lpm r5,z
			ret

;очистка дисплея цветом фона, использует палитру, установленную set_color
lcd_clr:
			ldi r21,80
cl_2:	
			ldi r20,104
cl_1:
			mov r17,r5
			rcall i2c_out
			dec r20
			brne cl_1
			dec r21
			brne cl_2
			ret

; здесь был перевод 16 битного числа в 10-ричное и запись чтение в память eeprom.

color:
	.db $0,$c0,$07,$c7,$38,$f8,$3f,$ff

znak:
	.include "znak6.txt"

