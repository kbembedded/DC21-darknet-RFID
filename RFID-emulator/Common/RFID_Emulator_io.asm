  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;                                                                          ;;
;;                                                                            ;;
;                     RFID Emulator - IO LIBRARY                               ;
;;                                                                            ;;
 ;;                                                                          ;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



	#include "p12f683.inc"
	#include "RFID_Emulator_io.inc"

	GLOBAL	_initIO




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                VARIABLES                                   ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                  CODE                                      ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	CODE



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                                                            ;;
;    Function:  _initIO                                                        ;
;    Desc.:     Initialize the Input/Output devices (LEDS & BUTTONS)          ;
;    Params.:   NONE                                                           ;
;                                                                              ;
;    Notes:     Returns in Bank 0                                              ; 
;;                                                                            ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_initIO

	BANKSEL TRISIO

	BCF		LED1_TRIS					; LEDs as output
	BCF		LED2_TRIS

	BCF		COUTPIN_TRIS                   ; Cout for testing
	;BSF		BUTTON2_TRIS
	
	CLRF	ANSEL 						; GPIO as digital IOs

	BCF		OPTION_REG, NOT_GPPU		; PULL-UPs activated on GPIO

	BANKSEL GPIO


	MOVLW	07h 						; Disable the analog comparators
	MOVWF	CMCON0

	BCF		LED1						; LEDS off
	BCF		LED2
	
	return



	END