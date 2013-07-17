  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;                                                                          ;;
;;                                                                            ;;
;                     RFID Emulator - RF LIBRARY                               ;
;;                                                                            ;;
 ;;                                                                          ;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



	#include "p12f683.inc"

	#IFNDEF	RF_INC
	
	#DEFINE RF_INC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;								   DEFINITIONS                                ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	;#DEFINE DEBUG 1				; Debugging flag

	; Coil IO
	#DEFINE COIL1		GPIO, GP4
	#DEFINE COIL1_TRIS	TRISIO,GP4
	#DEFINE COIL1_MASK_TRISIO b'00010000'	
	#DEFINE COIL2		GPIO, GP5
	#DEFINE COIL2_TRIS	TRISIO,GP5
	#DEFINE DEMODULATOR	GPIO, GP1
	#DEFINE DEMODULATOR_TRIS TRISIO, GP1
	

	; Flags bits
	#DEFINE FLAG_OUTPUT_READY 0


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;								    MACROS                                    ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


WAIT_RF_IS_READY MACRO

	; Wait for the next Timer1 interruption to transmit
	BTFSS	RF_FLAGS, FLAG_OUTPUT_READY
	GOTO	$-1
	
	BCF		RF_FLAGS, FLAG_OUTPUT_READY	; Clean the flag

	ENDM


RF_0 MACRO
;BCF	GPIO,GP0 ;TEST
	BANKSEL TRISIO
	BSF		COIL1_TRIS			; Coil to High Impedance
	BANKSEL	GPIO
	
	ENDM


RF_1 MACRO
;BSF	GPIO,GP0 ;TEST
	BANKSEL TRISIO
	BCF		COIL1_TRIS			; Coil to GND
	BANKSEL	GPIO
	
	ENDM


RF_TOGGLE MACRO

	BANKSEL TRISIO
	MOVLW	COIL1_MASK_TRISIO
	XORWF	TRISIO, F
	BANKSEL	GPIO

	ENDM


	#ENDIF
