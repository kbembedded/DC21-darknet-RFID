  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;                                                                          ;;
;;                                                                            ;;
;                     RFID Emulator - IO LIBRARY                               ;
;;                                                                            ;;
 ;;                                                                          ;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



	#include "p12f683.inc"

	#IFNDEF	IO_INC
	
	#DEFINE IO_INC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;								   DEFINITIONS                                ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	#DEFINE LED1		GPIO,   GP0
	#DEFINE LED1_TRIS	TRISIO, GP0
	#DEFINE LED1_MASK	b'00000001'
	#DEFINE LED2		GPIO,   GP1
	#DEFINE LED2_TRIS	TRISIO, GP1
	#DEFINE LED2_MASK 	b'00000010'

	#DEFINE COUTPIN         GPIO,   GP2
	#DEFINE COUTPIN_TRIS    TRISIO,GP2
	#DEFINE COUTPIN_MASK    b'00000100'
	;#DEFINE BUTTON2		GPIO,   GP3
	;#DEFINE BUTTON2_TRIS TRISIO,GP3
	;#DEFINE BUTTON2_MASK b'00001000'




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;								    MACROS                                    ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	#DEFINE LED1_ON		BSF	LED1
	#DEFINE LED1_OFF	BCF	LED1

	#DEFINE LED2_ON		BSF	LED2
	#DEFINE LED2_OFF	BCF	LED2

LED1_TOGGLE MACRO
	MOVLW	LED1_MASK
	XORWF	GPIO
	ENDM

LED2_TOGGLE MACRO
	MOVLW	LED2_MASK
	XORWF	GPIO
	ENDM


;BUTTON1_WAIT_UNTIL_PRESSED	MACRO
;	BTFSC	BUTTON1
;	GOTO	$-1
;	ENDM

;BUTTON1_WAIT_UNTIL_NOT_PRESSED	MACRO
;	BTFSS	BUTTON1
;	GOTO	$-1
;	ENDM


BUTTON2_WAIT_UNTIL_PRESSED	MACRO
	BTFSC	BUTTON2
	GOTO	$-1
	ENDM

BUTTON2_WAIT_UNTIL_NOT_PRESSED	MACRO
	BTFSS	BUTTON2
	GOTO	$-1
	ENDM


;BUTTON1_CALL_IF_PRESSED MACRO ADDRESS
;	BTFSS	BUTTON1
;	CALL	ADDRESS
;	ENDM

;BUTTON1_CALL_IF_NOT_PRESSED MACRO ADDRESS
;	BTFSC	BUTTON1
;	CALL	ADDRESS
;	ENDM

;BUTTON1_GOTO_IF_PRESSED MACRO ADDRESS
;	BTFSS	BUTTON1
;	GOTO	ADDRESS
;	ENDM

;BUTTON1_GOTO_IF_NOT_PRESSED MACRO ADDRESS
;	BTFSC	BUTTON1
;	GOTO	ADDRESS
;	ENDM


BUTTON2_CALL_IF_PRESSED MACRO ADDRESS
	BTFSS	BUTTON2
	CALL	ADDRESS
	ENDM

BUTTON2_CALL_IF_NOT_PRESSED MACRO ADDRESS
	BTFSC	BUTTON2
	CALL	ADDRESS
	ENDM

BUTTON2_GOTO_IF_PRESSED MACRO ADDRESS
	BTFSS	BUTTON2
	GOTO	ADDRESS
	ENDM

BUTTON2_GOTO_IF_NOT_PRESSED MACRO ADDRESS
	BTFSC	BUTTON2
	GOTO	ADDRESS
	ENDM


	#ENDIF