  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;                                                                          ;;
;;                                                                            ;;
;                   RFID Emulator - MULTI MEMORY-MAP                           ;
;;                                                                            ;;
 ;;                                                                          ;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




	#include "p12f683.inc"	
	#include "RFID_Emulator_multimap.inc"
	#include "../Common/RFID_Emulator_io.inc"
	#include "../Common/RFID_Emulator_misc.inc"
	#include "../Common/RFID_Emulator_rf.inc"



	EXTERN EE_MEMORY_SIZE, EE_CLOCKS_PER_BIT, EE_TAG_MODE, EE_RFID_MEMORY


	EXTERN	_initIO
	EXTERN	_writeEEPROM, _readEEPROM , _pauseX10uS, _pauseX1mS
	EXTERN  _initRF, _ISRTimer1RF, _txManchester1, _txManchester0, _txBiphase1, _txBiphase0
    EXTERN  _drive0, _drive1
	EXTERN	PARAM1

	EXTERN 	FLAGS

	GLOBAL	_start_PLAY

    #DEFINE CAPTURE_MODE       7 ; Flag: If set, we are not using clone function


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                VARIABLES                                   ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	UDATA

		
RFID_MEMORY		RES 	.16 	; Memory map

									; TAG configuration
CONFIG_TAG_MODE RES 	1			; Tag mode
CONFIG_MEMORY_SIZE RES 	1			; Memory size
CONFIG_CLOCKS_PER_BIT RES 1			; Clocks per bit

TMP_COUNTER		RES 	1			; Tmp counters
BYTE_COUNTER	RES 	1
BIT_COUNTER		RES 	1
	
									; Context vars.
W_TEMP			RES 	1
STATUS_TEMP		RES 	1

TX_BYTE			RES 	1			; Byte transmited


TMP				RES		1

;FLAGS			RES		1			; Flags byte



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                  CODE                                      ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	CODE


_start_PLAY

	CALL	_loadConfig				; Load TAG config
	CALL	_initIO					; Init IO
	MOVFW	CONFIG_CLOCKS_PER_BIT	
	CALL	_initRF					; Init RF

	BSF		FLAGS, CAPTURE_MODE
	

_main
    ; We need to send a listen window before anything else
    ; Most EM4450/EM4150 receivers will only listen to 64+-10 RF periods
    ;   NOT bit times.  If we wait too long we could miss sync
    ; Standard EM4100s dont care how long it takes us to send out data

    CALL _play_em4100
    GOTO _main

_send_LIW
    CALL _drive1
    CALL _drive0

    CALL _drive1
    CALL _drive1
    CALL _drive1
    CALL _drive1
    CALL _drive0
    CALL _drive0

    CALL _drive1
    CALL _drive1
    ;Right here is where we want to check to see if the base station is
    ; trying to talk to us.  CMCON0 COUT bit should be a 1, if its a 0
    ; we need to stop transmitting, and listen to data coming in
    ;BTFSS CMCON0,COUT
    

    RETURN

_send_ACK
    CALL _drive1
    CALL _drive0

    CALL _drive1
    CALL _drive1
    CALL _drive1

    CALL _drive0

    CALL _drive1
    CALL _drive1
    CALL _drive1

    CALL _drive0

    RETURN

_send_NAK
    CALL _drive1
    CALL _drive0

    CALL _drive1
    CALL _drive1
    CALL _drive1

    CALL _drive0

    CALL _drive1
    CALL _drive1

    CALL _drive0
    CALL _drive1

    RETURN





_play_em4100

	;Cabecera
	CALL	_tx1
	CALL	_tx1
	CALL	_tx1
	CALL	_tx1
	CALL	_tx1
	CALL	_tx1
	CALL	_tx1
	CALL	_tx1
	CALL	_tx1

	MOVLW	RFID_MEMORY				; INDF points to the beginning of the RFID memory 
	MOVWF	FSR

	;MOVFW	CONFIG_MEMORY_SIZE		; Load the number of bytes to transmit
	MOVLW	.11		; Load the number of bytes to transmit
	MOVWF	BYTE_COUNTER


_byteloop
	
	MOVFW	INDF					; Get the first byte to transmit
	MOVWF	TX_BYTE

	RLF		TX_BYTE, F				; Rotate left thrice-wise
	RLF		TX_BYTE, F
	RLF		TX_BYTE, F

	MOVLW	.5						
	MOVWF	BIT_COUNTER

_bitloop

	RLF		TX_BYTE,F				; Bit shifting

	BTFSC	STATUS, C				; Check if the bit is 1 or 0
	CALL	_tx1
	BTFSS	STATUS, C
	CALL	_tx0

	DECFSZ	BIT_COUNTER, F			; Check if more bits are waiting to be transmited
	GOTO	_bitloop

	INCF	FSR, F					; Next byte
	
	DECFSZ	BYTE_COUNTER, F			; Are there more bytes?
	GOTO	_byteloop



	RETURN


_tx1

	; Check the modulation
	BTFSC	CONFIG_TAG_MODE, TAG_MODE_CODING_BIT
	CALL	_txBiphase1

	BTFSS	CONFIG_TAG_MODE, TAG_MODE_CODING_BIT
	CALL	_txManchester1

	RETURN



_tx0

	; Check the modulation
	BTFSC	CONFIG_TAG_MODE, TAG_MODE_CODING_BIT
	GOTO	_txBiphase0
	
	BTFSS	CONFIG_TAG_MODE, TAG_MODE_CODING_BIT
	GOTO	_txManchester0

	RETURN






;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                                                            ;;
;    Function:  _loadConfig                                                    ;
;    Desc.:     Load the tag configuration                                     ;
;    Vars:      CONFIG_TAG_MODE, CONFIG_TAG_REPETITION, CONFIG_MEMORY_SIZE,    ;
;               CONFIG_S_COUNTER                                               ;
;                                                                              ;
;    Notes:                                                                    ;
;;                                                                            ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_loadConfig

	

	MOVLW	EE_TAG_MODE			; Read the tag mode
	CALL	_readEEPROM
	MOVWF	CONFIG_TAG_MODE

	MOVLW	EE_MEMORY_SIZE		; Read the memory size
	CALL	_readEEPROM
	MOVWF	CONFIG_MEMORY_SIZE

	MOVLW	EE_CLOCKS_PER_BIT	; Read the clocks per bit
	CALL	_readEEPROM
	MOVWF	CONFIG_CLOCKS_PER_BIT



	MOVLW	EE_RFID_MEMORY		; Read the memory map
	CALL	_loadMemoryMap

	RETURN





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                                                            ;;
;    Function:  _loadMemoryMap                                                 ;
;    Desc.:     Load the Memory Map from the EEPROM to the RAM                 ;
;    Params.:   W -> EEPROM ADDRESS                                            ;
;    Vars:      TMP                                                            ;
;                                                                              ;
;;                                                                            ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_loadMemoryMap


	MOVWF	BYTE_COUNTER			; Save the EEPROM ADDRESS (W)

	ADDWF	CONFIG_MEMORY_SIZE, W	; Save in TMP the end of the memory map
	MOVWF	TMP					

	MOVLW	RFID_MEMORY				; INDF points at the beginning of the memory map
	MOVWF	FSR

	

_loadMemoryMap_loop

	MOVFW	BYTE_COUNTER			; Read the EEPROM byte
	CALL	_readEEPROM
	MOVWF	INDF					; Store it in the RAM

	INCF	FSR, F					; Point to the next memory map byte 


	INCF	BYTE_COUNTER, F			; Check if we have copied all the bytes
	MOVFW	TMP
	SUBWF	BYTE_COUNTER, W
	BTFSS	STATUS, Z
	GOTO	_loadMemoryMap_loop

	return



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	END

