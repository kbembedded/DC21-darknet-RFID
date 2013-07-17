  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;                                                                          ;;
;;                                                                            ;;
;                              RFID Emulator                                   ;
;;                                                                            ;;
 ;;                                                                          ;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




	#include "p12f683.inc"	
	#include "RFID_Emulator.inc"
	#include "../Common/RFID_Emulator_io.inc"
	#include "../Common/RFID_Emulator_misc.inc"
	#include "../Common/RFID_Emulator_rf.inc"


	__CONFIG       _CP_ON & _CPD_OFF & _WDT_OFF & _BOD_OFF & _PWRTE_ON & _INTRC_OSC_NOCLKOUT & _MCLRE_ON & _IESO_OFF & _FCMEN_OFF

	EXTERN	_initIO
	EXTERN	_pauseX10uS, _pauseX1mS
	EXTERN  _initRF
	EXTERN _writeEEPROM, PARAM1

	EXTERN _ISRTimer1RF, _start_PLAY

	GLOBAL EE_MEMORY_SIZE, EE_CLOCKS_PER_BIT, EE_TAG_MODE, EE_RFID_MEMORY

	GLOBAL FLAGS



#DEFINE NUM_BIT_MANCHESTER 2			; Señala en que bit manchester nos encontramos (el primero == 0, o el segundo == 1)
#DEFINE BIT_BASE		   3			; Almacenamos aqui el bit en banda base (no demodulado manchester) 
#DEFINE PROCESAR_BIT_BASE  4			; Indicamos que hay un bit en banda base (no demodulado manchester) que procesar
#DEFINE	BIT 5							; Bit demodulado para ser procesado
#DEFINE GRABADO				0
#DEFINE CAPTURE_MODE	    7			; Indica si hay que capturar



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                VARIABLES                                   ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	UDATA

RFID_MEMORY	res	.11
		
	UDATA_SHR


FLAGS		RES	.1			; Flags varios. Ver los defines para los flags mas abajo.
TMP			RES	.1

W_TEMP		RES	.1
STATUS_TEMP	RES	.1

EEPROM_DIRECCION RES .1

PAQUETE_MANCHESTER	RES	.1		; Variable donde almacenamos los dos bits banda base que forman un bit manchester
CONTADOR_BITS_PAQUETE RES .1	; LLeva la cuenta de los bits que esperamos recibir para procesar el paquete

PAQUETE		RES	.1

CONTADOR_NIBBLES	RES	.1
TMP2		RES	.1
PARIDAD		RES	.1
PARIDAD_COLUMNA	RES	.1
FLAGS2		RES	.1
CONFIG_CLOCKS_PER_BIT	RES .1

TRASH	UDATA	0xA0

TRASH			RES		.32			; WARNING! We reserve all the GPRs in the BANK1
									; to avoid the linker using them. 
									; This way, we force the linker to alloc all
									; the vars in the BANK0.
									;
									; The "good" way to do this is doing a linker 
									; script.


	

	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                  CODE                                      ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


RST_VECTOR		CODE	0x0000

	GOTO      _start


INT_VECTOR		CODE	0X0004

	; Save the actual context
	MOVWF 	W_TEMP			
	SWAPF 	STATUS,W 
	BCF 	STATUS,RP0
	MOVWF 	STATUS_TEMP

	BTFSC	FLAGS, CAPTURE_MODE
	GOTO	_ISR_PLAY

	; Check the TMR1 interruption
	BTFSC	PIR1, TMR1IF
	CALL	_ISRTimer1RF_RX
	GOTO	_ISR_exit


_ISR_PLAY

	; Check the TMR1 interruption
	BTFSC	PIR1, TMR1IF
	CALL	_ISRTimer1RF


_ISR_exit

	BANKSEL	STATUS_TEMP					; _ISR_TIMER1RF can return in BANK 1

	; Restore the context
	SWAPF 	STATUS_TEMP,W
	MOVWF 	STATUS
	SWAPF 	W_TEMP,F
	SWAPF 	W_TEMP,W

	RETFIE
	


_start

;We need to follow the EM4100 and EM4150/EM4450 standards to be read by a normal
; EM4100 RFID reader as well as the EM4095 reader/writer frontend chip
;
;
	CALL	_initIO					; Init IO

	MOVLW	.50					; Wait for debouncing
	CALL	_pauseX10uS
	BUTTON1_GOTO_IF_NOT_PRESSED	_start_PLAY


	CLRF	FLAGS2

	
	MOVLW	.64
	CALL	_initRF_RX					; Init RF

_main
	;LED1_OFF
	call	_stopRX	

	CLRF	TMP
	CLRF	FLAGS
	CLRF	PAQUETE_MANCHESTER


	BANKSEL	CMCON0

	BTFSC	CMCON0, COUT			; Esperamos que baje el flanco
	GOTO	$-1
	BTFSS	CMCON0, COUT			; Esperamos que suba el flanco
	GOTO	$-1

	BANKSEL	TMP

	; Pausamos un poco 

	MOVLW 	.10
	MOVWF	TMP		
	DECFSZ	TMP, F
	GOTO	$-1

	call	_startRX
	

	movlw	.8
	movwf	CONTADOR_NIBBLES
	
	; Comprobamos si recibimos el par cero-uno ocho veces. Si hay algun error, salimos.
_comprobarCabecera

	BTFSS	FLAGS, PROCESAR_BIT_BASE
	GOTO	$-1
	BCF		FLAGS, PROCESAR_BIT_BASE
	BTFSC	FLAGS, BIT_BASE				; Esperamos un cero
	GOTO	_main						; No es un cero, volvemos a empezar...

	BTFSS	FLAGS, PROCESAR_BIT_BASE
	GOTO	$-1
	BCF		FLAGS, PROCESAR_BIT_BASE
	BTFSS	FLAGS, BIT_BASE				; Esperamos un uno
	GOTO	_main						; No es un uno, volvemos a empezar...

	DECFSZ	CONTADOR_NIBBLES, F
	GOTO	_comprobarCabecera

;LED1_ON
_test
;BTFSS	FLAGS, PROCESAR_BIT_BASE
;GOTO	$-1
;BCF		FLAGS, PROCESAR_BIT_BASE
;BTFSC	FLAGS, BIT_BASE				
;LED1_ON
;BTFSS	FLAGS, BIT_BASE				
;LED1_OFF
;LED1_TOGGLE
;GOTO _test

	; Apuntamos FSR a la zona de memoria donde almacenaremos el mapa de memoria RFID
	MOVLW	RFID_MEMORY
	MOVWF	FSR

	; Recibiremos 10 paquetes de datos + 1 paquete de paridad de columnas
	MOVLW	.11
	MOVWF	CONTADOR_NIBBLES

	; Cada paquete tiene 4 bits de datos y uno de paridad 
	MOVLW	.5
	MOVWF	CONTADOR_BITS_PAQUETE
	
	CLRF	PAQUETE
	CLRF	PARIDAD
	CLRF	PARIDAD_COLUMNA

	
	; Vamos esperando los distintos bits y los decodificamos en Manchester

_esperando_bit_base						
	
	BTFSS	FLAGS, PROCESAR_BIT_BASE		;Esperamos a que haya un bit en banda base para procesar
	GOTO 	_esperando_bit_base

	GOTO	_procesarBitBase				; Procesamos el bit


	; Si llegamos a este punto, es por que tenemos un bit a procesar
_procesar_bit_Manchester





_procesando_paquete
	
	; Ponemos el flag Status al mismo valor que el bit recibido
	BCF		STATUS, C
	BTFSC	FLAGS, BIT
	BSF		STATUS, C

	RLF		PAQUETE, F		;Insertamos por la derecha el paquete
	
	BTFSC	FLAGS, BIT		; Si el bit es un 1, incrementamos la variable paridad
	INCF	PARIDAD, F

	DECFSZ	CONTADOR_BITS_PAQUETE, F	
	GOTO	_esperando_bit_base		;Todavia tenemos que recibir mas bits de este paquete

	; Este paquete esta finalizado.


	; Vamos xoreando los paquetes para comprobar la paridad de columnas
	MOVFW	PAQUETE
	XORWF	PARIDAD_COLUMNA, F

	; Si este paquete es el ultimo, no tenemos que comprobar la paridad de fila
	DECF	CONTADOR_NIBBLES, W
	BTFSC	STATUS, Z		
	GOTO	_salvarPaquete

	; Comprobamos la paridad de fila
	BTFSC	PARIDAD, 0
	GOTO	_main					; Paridad no es par! Error!


_salvarPaquete

	; Salvamos paquete PERO descartando el bit de paridad
	BANKISEL RFID_MEMORY			; Acceso indirecto al banco 0
	MOVFW	PAQUETE
	MOVWF	INDF					;<- No perdemos el bit de acarreo
	;BCF		STATUS, C				; Limpiamos el carry para rotar el registro
	;RRF		INDF, F					; y perder el BIT de paridad.
	INCF	FSR,F

	; Preparamos las variables para el siguiente paquete
	MOVLW	.5						; Proximo paquete
	MOVWF	CONTADOR_BITS_PAQUETE
	CLRF	PAQUETE
	CLRF	PARIDAD

	; Comprobamos si quedan mas paquetes
	DECFSZ	CONTADOR_NIBBLES, F		; Todavia nos queda paquetes por recibir
	GOTO	_esperando_bit_base

	;HEMOS RECIBIDO TODOS LOS PAQUETES

	; Paramos las interrupciones
	call	_stopRX
	bcf INTCON,GIE ;Disable INTs


	; Comprobamos la paridad de columna
	MOVFW	PARIDAD_COLUMNA
	ANDLW	b'11111110'
	BTFSS	STATUS, Z				;
	GOTO	_main					; Error! No pasamos la paridad de columna

	BTFSS	FLAGS2, GRABADO
	CALL	grabar_RFID

	GOTO	_main


grabar_RFID

	movlw	RFID_MEMORY
	movwf	FSR

	;clrf	EEPROM_DIRECCION
	MOVLW	EE_RFID_MEMORY
	MOVWF	EEPROM_DIRECCION

	BANKISEL	RFID_MEMORY

_grabar_RFID_BUCLE



	MOVFW	EEPROM_DIRECCION
	MOVWF	PARAM1
	
	movfw	INDF

	call	_writeEEPROM

	INCF	EEPROM_DIRECCION, F
	INCF	FSR,F
	

	movlw	RFID_MEMORY+.11
	subwf	FSR, W
	btfss	STATUS, Z
	goto	_grabar_RFID_BUCLE
	

	BANKSEL	FLAGS2
	BSF		FLAGS2, GRABADO

	
	LED1_ON					; Detenemos la ejecucion y encendemos el LED
	GOTO	$-1

	return 







;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;                                                                       ;;;;
;;                             _procesarBitBase                               ;;
;;                                                                           ;;
;;    Procesarmos el bit en banda base que nos ha llegado.                   ;;
;;                                                                           ;;
;;	  ENTRADA: FLAGS:PROCESAR_BIT_BASE ; FLAGS:BIT_BASE                      ;;
;;    VARIABLES:                                                             ;;
;;    RETORNO:                                                               ;;
;;                                                                           ;;
;;;;                                                                       ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_procesarBitBase

	BCF		FLAGS, PROCESAR_BIT_BASE

	;BTFSC	FLAGS, BIT_BASE
	;LED1_ON
	;BTFSS	FLAGS, BIT_BASE
	;LED1_OFF
		
	BCF		STATUS, C						; Vamos insertando el bit en banda base dentro del paquete manchester (2 bits)
	BTFSC	FLAGS, BIT_BASE
	BSF		STATUS, C
	RLF		PAQUETE_MANCHESTER, F
	
	BTFSC	FLAGS, NUM_BIT_MANCHESTER		; Comprobamos si es el segudo bit manchester (fin del paquete
	GOTO	_demodular_paquete_manchester
	
	
	; Es el primer bit

	BSF		FLAGS, NUM_BIT_MANCHESTER		; Indicamos que vamos a por el segundo bit
	GOTO	_esperando_bit_base				; Retornamos a esperar el proximo bit
	

_demodular_paquete_manchester

	BCF		FLAGS, NUM_BIT_MANCHESTER		; Limpiamos el indicador del bit del paquete manchester


	; Vamos a comprobar si es un bit correcto (01 o 10)
	
	MOVLW	b'00000001'
	SUBWF	PAQUETE_MANCHESTER, W
	BTFSC	STATUS, Z
	GOTO	_demodular_paquete_manchester_1
	
	MOVLW	b'00000010'
	SUBWF	PAQUETE_MANCHESTER, W
	BTFSC	STATUS, Z
	GOTO	_demodular_paquete_manchester_0
	
	; ERROR! No es un manchester. Sera un error!? Desactivamos las interrupciones.
;LED1_OFF
	GOTO	_main						; Procesamos el error
	
_demodular_paquete_manchester_1
	CLRF	PAQUETE_MANCHESTER
	BSF		FLAGS, BIT
	GOTO	_procesar_bit_Manchester				; Retornamos a esperar el proximo bit
	
	
_demodular_paquete_manchester_0
	CLRF	PAQUETE_MANCHESTER
	BCF		FLAGS, BIT
	GOTO	_procesar_bit_Manchester				; Retornamos a esperar el proximo bit





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                                                            ;;
;    Function:  _initRF_RX                                                     ;
;    Desc.:     Initialize the RF                                              ;
;    Params.:   W -> CARRIER CLOCKS PER BIT                                    ;
;    Vars:      TMP                                                            ;
;                                                                              ;
;    Notes:     The TMR2 interruption is activated.                            ; 
;;                                                                            ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_initRF_RX


	MOVWF	CONFIG_CLOCKS_PER_BIT	; Backup of the CLOCK_PER_BIT value stored in W

	

	;MOVLW	b'00010100'			; Comparator Output Inverted. CIN- == GP0 ; CIN+ == CVref
	MOVLW	b'00000011'			; Comparator Output NOT Inverted. CIN- == GP0 ; CIN+ == CVref; COUT PIN enabled
	MOVWF	CMCON0

	BANKSEL	TRISIO				; Bank 1

	MOVLW	b'00000010'			; GP1 as analog input. Rest as digital
	MOVWF	ANSEL
	
	;MOVLW	b'10100011'			; Voltage Regulator ON; Low range; 0.625 volts (Vdd=5V)
	MOVLW	b'10100000'			; Voltage Regulator ON; Low range; 0.04 Vdd
	;MOVLW	b'10000000'			; Voltage Regulator ON; HIGH range; 0.750 Vdd
	MOVWF	VRCON
	
	BSF		DEMODULATOR_TRIS	; Demodulator pin as input


	BSF		COIL1_TRIS			; Coil pins as input
	BSF		COIL2_TRIS			

BCF		TRISIO, GP2			; TESTING. COUT salida

	BANKSEL	GPIO				; Bank 0

	BCF		COIL1				; COIL1 connected to GND (if COIL1_TRIS = 0)	


	RETURN


_startRX

	BCF	PIR1, TMR1IF			; Clear the TMR1IF flag

	BANKSEL	PIE1

	CLRF	PIE1				; Activate the Timer1 Interruption
	BSF		PIE1, TMR1IE				

	BANKSEL PIR1

	MOVLW	b'11000000'			; Activate GIE and PEIE
	MOVWF	INTCON
	
	
	MOVLW	0xFF				; Write the Timer1 upper byte
	MOVWF	TMR1H

	; Write the Timer1 lower byte. TMR1L = 0 - CLOCKS_PER_BIT/2
	BCF		STATUS, C					
	RRF		CONFIG_CLOCKS_PER_BIT, W	; CLOCKS_PER_BIT / 2 -> W
	ADDLW	-2							; Tuning. 
	CLRF	TMR1L						; TMR1L = 0
	SUBWF	TMR1L, F

	;IFDEF	DEBUG
	;MOVLW	b'00110001'					; Timer1: internal clock source, asynchronous, prescalerx8.
	;ELSE
	;MOVLW	b'00000111'					; Timer1: external clock source, asynchronous, no prescaler.
	MOVLW	b'00000011'					; Timer1: external clock source, asynchronous, no prescaler.
	;ENDIF
	MOVWF	T1CON						; Timer1 config

	RETURN


_stopRX


	BANKSEL	PIE1

	; DeActivate the Timer1 Interruption
	BCF		PIE1, TMR1IE				

	BANKSEL PIR1

	BCF	PIR1, TMR1IF			; Clear the TMR1IF flag	

	MOVLW	b'01000000'			; Activate GIE and PEIE
	MOVWF	INTCON
	
	

	RETURN



_ISRTimer1RF_RX

	BCF		PIR1, TMR1IF			; Cleart the TMR1F flag

	BANKSEL	PIE1					; Bank 1

	BTFSS	PIE1, TMR1IE			; Check for ghost interrupts
	RETURN							; WARNING! Return with the Bank 1 selected

	BANKSEL	TMR1H					; Bank 0	
	



	MOVLW	0xFF				; Write the Timer1 upper byte
	MOVWF	TMR1H

	; Write the Timer1 lower byte. TMR1L = 0 - CLOCKS_PER_BIT/2
	BCF		STATUS, C					
	RRF		CONFIG_CLOCKS_PER_BIT, W		; CLOCKS_PER_BIT / 2 -> W
	NOP							;TUNING
	;NOP
	;NOP
	ADDLW	-3							; Tuning. <- good for 64 CPB
	CLRF	TMR1L						; TMR1L = 0
	SUBWF	TMR1L, F

	BSF		FLAGS, PROCESAR_BIT_BASE		; Avisamos de que hay un bit por procesar

	 
	BTFSC	CMCON0, COUT				; Muestreado un 1
	GOTO	_uno
	
	

_cero
	;LED1_OFF
	BCF		FLAGS, BIT_BASE
	RETURN
	
_uno
	;LED1_ON
	BSF		FLAGS, BIT_BASE
	
	RETURN




ORG 0x2100                              
	

EE_MEMORY_SIZE		DE .11
EE_CLOCKS_PER_BIT 	DE .64
EE_TAG_MODE			DE TAG_MODE_CODING_MANCHESTER
;EE_RFID_MEMORY		DE 	b'11111111' , b'10001100' , b'01100011' , b'00011000', b'11000110' , b'00110001' , b'10001100' , b'01100000'
;EE_RFID_MEMORY		DE 	b'11111111' , b'11111111' , b'11111111' , b'11111111', b'11111111' , b'11111111' , b'11111111' , b'11111111'
EE_RFID_MEMORY		DE 	0x03, 0x0C, 0x00, 0x00, 0x17, 0x05, 0x05, 0x14, 0x12, 0x12, 0x0C

	  
	END

