  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;                                                                          ;;
;;                                                                            ;;
;                   RFID Emulator - RF LIBRARY                                 ;
;;                                                                            ;;
 ;;                                                                          ;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;






	#INCLUDE "p12f683.inc"
	#INCLUDE "RFID_Emulator_rf.inc"


	GLOBAL	_initRF, _ISRTimer1RF
	GLOBAL  _txManchester1, _txManchester0, _txBiphase1, _txBiphase0



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                VARIABLES                                   ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



	UDATA

RF_FLAGS	RES 1
TMP_CLOCKS_PER_BIT	RES 1


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                  CODE                                      ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	CODE



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                                                            ;;
;    Function:  _initRF                                                        ;
;    Desc.:     Initialize the RF                                              ;
;    Params.:   W -> CARRIER CLOCKS PER BIT                                    ;
;    Vars:      TMP                                                            ;
;                                                                              ;
;    Notes:     The TMR1 interruption is activated.                            ; 
;;                                                                            ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_initRF


	MOVWF	TMP_CLOCKS_PER_BIT	; Backup of the CLOCK_PER_BIT value stored in W

	BANKSEL	PIE1				; Bank 1

	BSF		COIL1_TRIS			; Coil pins as input
	BSF		COIL2_TRIS			

	CLRF	PIE1				; Activate the Timer1 Interruption
	BSF		PIE1, TMR1IE				

	BANKSEL	PIR1				; Bank 0

	BCF		COIL1				; COIL1 connected to GND (if COIL1_TRIS = 0)	

	BCF	PIR1, TMR1IF			; Clear the TMR1IF flag
	MOVLW	b'11000000'			; Activate GIE and PEIE
	MOVWF	INTCON
	
	
	MOVLW	0xFF				; Write the Timer1 upper byte
	MOVWF	TMR1H

	; Write the Timer1 lower byte. TMR1L = 0 - CLOCKS_PER_BIT/2
	BCF		STATUS, C					
	RRF		TMP_CLOCKS_PER_BIT, W		; CLOCKS_PER_BIT / 2 -> W
	ADDLW	-2							; Tuning. 
	CLRF	TMR1L						; TMR1L = 0
	SUBWF	TMR1L, F

	IFDEF	DEBUG
	MOVLW	b'00110001'					; Timer1: internal clock source, synchronous, prescalerx8.
	ELSE
	MOVLW	b'00000111'					; Timer1: external clock source, synchronous, no prescaler.
	ENDIF
	MOVWF	T1CON						; Timer1 config


	CLRF	RF_FLAGS					; Clear the RF flags


	RETURN




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                                                            ;;
;    Function:  _ISRTimer1RF                                                   ;
;    Desc.:     Timer1 Interruption Service Routine                            ;
;    Vars:                                                                     ;
;                                                                              ;
;    Notes:                                                                    ; 
;;                                                                            ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_ISRTimer1RF

	BCF		PIR1, TMR1IF			; Cleart the TMR1F flag

	BANKSEL	PIE1					; Bank 1

	BTFSS	PIE1, TMR1IE			; Check for ghost interrupts
	RETURN							; WARNING! Return with the Bank 1 selected

	BANKSEL	TMR1H					; Bank 0	
	



	MOVLW	0xFF				; Write the Timer1 upper byte
	MOVWF	TMR1H

	; Write the Timer1 lower byte. TMR1L = 0 - CLOCKS_PER_BIT/2
	BCF		STATUS, C					
	RRF		TMP_CLOCKS_PER_BIT, W		; CLOCKS_PER_BIT / 2 -> W
	ADDLW	-2							; Tuning.
	CLRF	TMR1L						; TMR1L = 0
	SUBWF	TMR1L, F

	
	BSF		RF_FLAGS, FLAG_OUTPUT_READY
	
	RETURN







;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                                                            ;;
;    Function:  _txManchester1                                                 ;
;    Desc.:     Transmit a Manchester encoded 1 bit                            ;
;    Vars:                                                                     ;
;                                                                              ;
;    Notes:                                                                    ; 
;;                                                                            ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_txManchester1

	WAIT_RF_IS_READY
	RF_0
	

	WAIT_RF_IS_READY
	RF_1

	return




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                                                            ;;
;    Function:  _txManchester0                                                 ;
;    Desc.:     Transmit a Manchester encoded 0 bit                            ;
;    Vars:                                                                     ;
;                                                                              ;
;    Notes:                                                                    ;
;;                                                                            ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_txManchester0

	WAIT_RF_IS_READY
	RF_1
	

	WAIT_RF_IS_READY
	RF_0

	return




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                                                            ;;
;    Function:  _txBiphase1                                                    ;
;    Desc.:     Transmit a Manchester encoded 1 bit                            ;
;    Vars:                                                                     ;
;                                                                              ;
;    Notes:                                                                    ;
;;                                                                            ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_txBiphase1

	WAIT_RF_IS_READY
	RF_TOGGLE

	WAIT_RF_IS_READY

	return




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                                                            ;;
;    Function:  _txBiphase0                                                    ;
;    Desc.:     Transmit a Manchester encoded 0 bit                            ;
;    Vars:                                                                     ;
;                                                                              ;
;    Notes:                                                                    ;
;;                                                                            ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_txBiphase0

	WAIT_RF_IS_READY
	RF_TOGGLE

	WAIT_RF_IS_READY
	RF_TOGGLE

	return


	END