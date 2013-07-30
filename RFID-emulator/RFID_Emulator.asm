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

__CONFIG _CP_ON & _CPD_OFF & _WDT_OFF & _BOD_OFF & _PWRTE_ON & _INTRC_OSC_NOCLKOUT & _MCLRE_ON & _IESO_OFF & _FCMEN_OFF

EXTERN  _initIO
EXTERN  _pauseX10uS, _pauseX1mS
EXTERN  _initRF
EXTERN  _writeEEPROM, PARAM1
EXTERN  _ISRTimer1RF, _start_PLAY

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                GLOBALS                                     ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GLOBAL  EE_MEMORY_SIZE, EE_CLOCKS_PER_BIT, EE_TAG_MODE, EE_RFID_MEMORY
GLOBAL  FLAGS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                LITERALS                                    ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#DEFINE NUM_BIT_MANCHESTER 2 ; Flag: Which manchester bit are we on?
#DEFINE BASE_BIT           3 ; Flag: Value of received bit.
#DEFINE PROCESS_BASE_BIT   4 ; Flag: Are we ready to process?
#DEFINE BIT                5 ; Flag: Does this bit need to be demodulated?
#DEFINE RECORD             0 ; Flag: Are we writing to RFID Memory?
#DEFINE CAPTURE_MODE       7 ; Flag: If set, we are not using clone function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                VARIABLES                                   ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    UDATA
RFID_MEMORY             RES .11

    UDATA_SHR
FLAGS                   RES .1  ; Flags defined above.

TMP                     RES .1
W_TEMP                  RES .1
STATUS_TEMP             RES .1

EEPROM_ADDRESS          RES .1

MANCHESTER_PACKET       RES .1  ; Contains two baseband bits
MANCHESTER_BIT_IDX      RES .1  ; Manchester bit index
PACKET                  RES .1

NIBBLE_CNT              RES .1  ; Number of Nibbles remaining to receive
TMP2                    RES .1
PARITY                  RES .1
COLUMN_PARITY           RES .1
FLAGS2                  RES .1
CONFIG_CLOCKS_PER_BIT   RES .1

TRASH   UDATA   0xA0

TRASH                   RES .32 ; WARNING! We reserve all the GPRs in the BANK1
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


RST_VECTOR      CODE    0x0000

    GOTO      _start


INT_VECTOR      CODE    0X0004

    ; Save the actual context
    MOVWF   W_TEMP
    SWAPF   STATUS,W
    BCF     STATUS,RP0
    MOVWF   STATUS_TEMP

    BTFSC   FLAGS, CAPTURE_MODE
    GOTO    _ISR_PLAY

    ; Check the TMR1 interruption
    BTFSC   PIR1, TMR1IF
    CALL    _ISRTimer1RF_RX
    GOTO    _ISR_exit


_ISR_PLAY

    ; Check the TMR1 interruption
    BTFSC   PIR1, TMR1IF
    CALL    _ISRTimer1RF


_ISR_exit

    BANKSEL STATUS_TEMP                 ; _ISR_TIMER1RF can return in BANK 1

    ; Restore the context
    SWAPF   STATUS_TEMP,W
    MOVWF   STATUS
    SWAPF   W_TEMP,F
    SWAPF   W_TEMP,W

    RETFIE



_start

;We need to follow the EM4100 and EM4150/EM4450 standards to be read by a normal
; EM4100 RFID reader as well as the EM4095 reader/writer frontend chip
;
;
    CALL    _initIO             ; Init IO

    MOVLW   .50                 ; Wait for debouncing
    CALL    _pauseX10uS
    ;BUTTON1_GOTO_IF_NOT_PRESSED _start_PLAY
    ;Current PCB rev does not support cloning in the way that this code base
    ; does.  There is no button on board to put in "clone" mode, a real
    ; EM4095 base station will eventually be needed for writing to the card
    GOTO _start_PLAY


    CLRF    FLAGS2


    MOVLW   .64
    CALL    _initRF_RX          ; Init RF

_main
    ;LED1_OFF
    CALL    _stopRX             ; For error handling, we always return to main,
                                ; so we always stopRX because of this.

    CLRF    TMP                 ; Clear variables
    CLRF    FLAGS
    CLRF    MANCHESTER_PACKET

    ; Wait for the comparator to cycle from 0 to 1 (why?)
    BANKSEL CMCON0
    BTFSC   CMCON0, COUT        ; Esperamos que baje el flanco
    GOTO    $-1
    BTFSS   CMCON0, COUT        ; Esperamos que suba el flanco
    GOTO    $-1

    ; Short Delay, spin for 10 clock cycles
    BANKSEL TMP
    MOVLW   .10
    MOVWF   TMP
    DECFSZ  TMP, F
    GOTO    $-1

    CALL    _startRX            ; Initializes interrupt for RX

    MOVLW   .8                  ; Prepare to receive header (8 bits)
    MOVWF   NIBBLE_CNT

; Check if we receive 01 pair eight times. Return on error.
_check_header

    BTFSS   FLAGS, PROCESS_BASE_BIT     ; Wait for bit received.
    GOTO    $-1
    BCF     FLAGS, PROCESS_BASE_BIT     ; Consume bit.
    BTFSC   FLAGS, BASE_BIT             ; 0 expected
    GOTO    _main                       ; If not, error, start over.

    BTFSS   FLAGS, PROCESS_BASE_BIT     ; Wait for bit received.
    GOTO    $-1
    BCF     FLAGS, PROCESS_BASE_BIT
    BTFSS   FLAGS, BASE_BIT             ; 1 expected
    GOTO    _main                       ; If not, error, start over.

    DECFSZ  NIBBLE_CNT, F
    GOTO    _check_header

;LED1_ON
_test
;BTFSS  FLAGS, PROCESS_BASE_BIT
;GOTO   $-1
;BCF        FLAGS, PROCESS_BASE_BIT
;BTFSC  FLAGS, BASE_BIT
;LED1_ON
;BTFSS  FLAGS, BASE_BIT
;LED1_OFF
;LED1_TOGGLE
;GOTO _test

    ; Point FSR to where we store RFID memory.
    MOVLW   RFID_MEMORY
    MOVWF   FSR

    ; We receive 10 data packets and 1 parity packet
    MOVLW   .11
    MOVWF   NIBBLE_CNT

    ; Each packet has 4 data bits and one parity bit.
    MOVLW   .5
    MOVWF   MANCHESTER_BIT_IDX   ; Reset index for next packet (5 bits)

    CLRF    PACKET               ; Clear all variables
    CLRF    PARITY
    CLRF    COLUMN_PARITY


; Wait for next bit (RX interrupt), then process it
_wait_for_base_bit
    ; Wait for the bit...
    BTFSS   FLAGS, PROCESS_BASE_BIT
    GOTO    _wait_for_base_bit
    ; Once we have the bit, we go ahead and process it
    GOTO    _process_base_bit


; If we reach this point, we have a bit to process
_process_manchester_bit


; So let's get to it...


_process_packet

    ; Set status flag to received bit.
    BCF     STATUS, C
    BTFSC   FLAGS, BIT
    BSF     STATUS, C

    ; Add bit to processed packet.
    RLF     PACKET, F       ; Rotate packet left to make room.
    BTFSC   FLAGS, BIT      ; If bit is 1...
    INCF    PARITY, F       ; We increment the parity bit.

    DECFSZ  MANCHESTER_BIT_IDX, F   ; If we still have more bits,
    GOTO    _wait_for_base_bit      ; wait for the next one.

    ; The packet is complete.

    ; XOR the packet with the column parity.
    ;     Vamos xoreando los paquetes para comprobar la paridad de columnas
    ;     "So what does -eando mean? we're doing it?"
    MOVFW   PACKET
    XORWF   COLUMN_PARITY, F

    ; If this is the last packet, we don't need to save it.
    DECF    NIBBLE_CNT, W
    BTFSC   STATUS, Z
    GOTO    _save_packet

    ; Check the parity.
    BTFSC   PARITY, 0
    GOTO    _main                   ; Parity is not even! Error!


_save_packet

    ; Save packet, discard parity bit.
    BANKISEL RFID_MEMORY            ; Indirect access to bank 0
    MOVFW   PACKET
    MOVWF   INDF                    ;<- Do not lose carry bit
    ;BCF        STATUS, C               ; Clear the carry to rotate the register
    ;RRF        INDF, F                 ; Lose the parity bit
    INCF    FSR,F

    ; Reset the variables for the next packet.
    MOVLW   .5
    MOVWF   MANCHESTER_BIT_IDX
    CLRF    PACKET
    CLRF    PARITY

    ; Check if we have more packets.
    DECFSZ  NIBBLE_CNT, F       ; If we have more nibs, wait for them.
    GOTO    _wait_for_base_bit

    ; Otherwise, we have received all the packets.

    ; Stop interruptions.
    CALL    _stopRX
    BCF     INTCON,GIE ;Disable INTs

    ; Check the parity for our received data.
    MOVFW   COLUMN_PARITY
    ANDLW   b'11111110'
    BTFSS   STATUS, Z               ;
    GOTO    _main                   ; Error! We do not have parity!

    ; Check if we need to write to RFID memory
    BTFSS   FLAGS2, RECORD
    CALL    write_RFID

    ; If not, we're done.
    GOTO    _main


write_RFID

    MOVLW   RFID_MEMORY
    MOVWF   FSR

    ;clrf   EEPROM_ADDRESS
    MOVLW   EE_RFID_MEMORY
    MOVWF   EEPROM_ADDRESS

    BANKISEL    RFID_MEMORY

_write_RFID_BUCLE

    MOVFW   EEPROM_ADDRESS
    MOVWF   PARAM1

    MOVFW   INDF

    CALL    _writeEEPROM

    INCF    EEPROM_ADDRESS, F
    INCF    FSR,F


    MOVLW   RFID_MEMORY+.11
    SUBWF   FSR, W
    BTFSS   STATUS, Z
    GOTO    _write_RFID_BUCLE


    BANKSEL FLAGS2
    BSF     FLAGS2, RECORD


    LED1_ON                 ; Stop execution and turn on LED.
    GOTO    $-1

    RETURN







;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;                                                                       ;;;;
;;                             _process_base_bit                             ;;
;;                                                                           ;;
;;    Process the received baseband bit.                                     ;;
;;                                                                           ;;
;;    ENTRADA: FLAGS:PROCESS_BASE_BIT ; FLAGS:BASE_BIT                      ;;
;;    VARIABLES:                                                             ;;
;;    RETORNO:                                                               ;;
;;                                                                           ;;
;;;;                                                                       ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_process_base_bit

    BCF     FLAGS, PROCESS_BASE_BIT        ; Clear process flag

    ;BTFSC  FLAGS, BASE_BIT
    ;LED1_ON
    ;BTFSS  FLAGS, BASE_BIT
    ;LED1_OFF

    ; Set the bit in the Manchester packet
    BCF     STATUS, C
    BTFSC   FLAGS, BASE_BIT
    BSF     STATUS, C
    RLF     MANCHESTER_PACKET, F

    BTFSC   FLAGS, NUM_BIT_MANCHESTER     ; If this is the second bit...
    GOTO    _demodulate_manchester_packet ; We have both bits, demodulate.

    ; This was only the first bit, prepare to receive the second.
    BSF     FLAGS, NUM_BIT_MANCHESTER     ; Set Manchester flag for second bit.
    GOTO    _wait_for_base_bit            ; Return and wait for next bit.


_demodulate_manchester_packet

    BCF     FLAGS, NUM_BIT_MANCHESTER     ; Clear Mancehster flag for next packet.

    ; Check which bit is set, and demodulate accordingly.
    MOVLW   b'00000001'
    SUBWF   MANCHESTER_PACKET, W
    BTFSC   STATUS, Z
    GOTO    _demodulate_manchester_bit_1

    MOVLW   b'00000010'
    SUBWF   MANCHESTER_PACKET, W
    BTFSC   STATUS, Z
    GOTO    _demodulate_manchester_bit_0

    ; ERROR! Neither manchester bit was set. Something bad happened!
    ;LED1_OFF
    GOTO    _main                   ; Get out.

_demodulate_manchester_bit_1
    CLRF    MANCHESTER_PACKET
    BSF     FLAGS, BIT
    GOTO    _process_manchester_bit ; Return and wait for next bit.


_demodulate_manchester_bit_0
    CLRF    MANCHESTER_PACKET
    BCF     FLAGS, BIT
    GOTO    _process_manchester_bit ; Return and wait for next bit.





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


    MOVWF   CONFIG_CLOCKS_PER_BIT   ; Backup of the CLOCK_PER_BIT value stored in W



    ;MOVLW  b'00010100'         ; Comparator Output Inverted. CIN- == GP1 ; CIN+ == CVref
    MOVLW   b'00000011'         ; Comparator Output NOT Inverted. CIN- == GP1 ; CIN+ == CVref; COUT PIN enabled
    MOVWF   CMCON0

    BANKSEL TRISIO              ; Bank 1

    MOVLW   b'00000010'         ; GP1 as analog input. Rest as digital
    MOVWF   ANSEL

    ;MOVLW  b'10100011'         ; Voltage Regulator ON; Low range; 0.625 volts (Vdd=5V)
    MOVLW   b'10100000'         ; Voltage Regulator ON; Low range; 0.04 Vdd
    ;MOVLW  b'10000000'         ; Voltage Regulator ON; HIGH range; 0.750 Vdd
    MOVWF   VRCON

    BSF     DEMODULATOR_TRIS    ; Demodulator pin as input


    BSF     COIL1_TRIS          ; Coil pins as input
    BSF     COIL2_TRIS

    BCF     TRISIO, GP2         ; Set COUT pin to output

    BANKSEL GPIO                ; Bank 0

    BCF     COIL1               ; COIL1 connected to GND (if COIL1_TRIS = 0)


    RETURN


_startRX

    BCF PIR1, TMR1IF            ; Clear the TMR1IF flag

    BANKSEL PIE1

    CLRF    PIE1                ; Activate the Timer1 Interruption
    BSF     PIE1, TMR1IE

    BANKSEL PIR1

    MOVLW   b'11000000'         ; Activate GIE and PEIE
    MOVWF   INTCON


    MOVLW   0xFF                ; Write the Timer1 upper byte
    MOVWF   TMR1H

    ; Write the Timer1 lower byte. TMR1L = 0 - CLOCKS_PER_BIT/2
    BCF     STATUS, C
    RRF     CONFIG_CLOCKS_PER_BIT, W    ; CLOCKS_PER_BIT / 2 -> W
    ADDLW   -2                          ; Tuning.
    CLRF    TMR1L                       ; TMR1L = 0
    SUBWF   TMR1L, F

    ;IFDEF  DEBUG
    ;MOVLW  b'00110001'                 ; Timer1: internal clock source, asynchronous, prescalerx8.
    ;ELSE
    ;MOVLW  b'00000111'                 ; Timer1: external clock source, asynchronous, no prescaler.
    MOVLW   b'00000011'                 ; Timer1: external clock source, asynchronous, no prescaler.
    ;ENDIF
    MOVWF   T1CON                       ; Timer1 config

    RETURN


_stopRX


    BANKSEL PIE1

    ; DeActivate the Timer1 Interruption
    BCF     PIE1, TMR1IE

    BANKSEL PIR1

    BCF PIR1, TMR1IF            ; Clear the TMR1IF flag

    MOVLW   b'01000000'         ; Activate GIE and PEIE
    MOVWF   INTCON



    RETURN



_ISRTimer1RF_RX

    BCF     PIR1, TMR1IF            ; Cleart the TMR1F flag

    BANKSEL PIE1                    ; Bank 1

    BTFSS   PIE1, TMR1IE            ; Check for ghost interrupts
    RETURN                          ; WARNING! Return with the Bank 1 selected

    BANKSEL TMR1H                   ; Bank 0




    MOVLW   0xFF                ; Write the Timer1 upper byte
    MOVWF   TMR1H

    ; Write the Timer1 lower byte. TMR1L = 0 - CLOCKS_PER_BIT/2
    BCF     STATUS, C
    RRF     CONFIG_CLOCKS_PER_BIT, W        ; CLOCKS_PER_BIT / 2 -> W
    NOP                         ;TUNING
    ;NOP
    ;NOP
    ADDLW   -3                          ; Tuning. <- good for 64 CPB
    CLRF    TMR1L                       ; TMR1L = 0
    SUBWF   TMR1L, F

    BSF     FLAGS, PROCESS_BASE_BIT     ; Mark bit as ready to process


    BTFSC   CMCON0, COUT                ; Muestreado un 1
    GOTO    _uno


; Not called anywhere else...
;_cero
;   ;LED1_OFF
;   BCF     FLAGS, BASE_BIT
;   RETURN

_uno
    ;LED1_ON
    BSF     FLAGS, BASE_BIT

    RETURN




ORG 0x2100

; This is where the data is stored.
; We have memory size of 11 bytes, the tag mode (Manchester or BiPhase),
; and the 11 byte data in EE_RFID_MEMORY.
; We use 11 bytes, left 0 padded, one for each 5bits that would be transmitted
; on a single row.  This is more human readable than putting all of the bits
; together and ending up with a string of nonsense.
EE_MEMORY_SIZE      DE .11
EE_CLOCKS_PER_BIT   DE .64
EE_TAG_MODE         DE TAG_MODE_CODING_MANCHESTER
EE_RFID_MEMORY      DE  0x0c, 0x05, 0x0f, 0x0a, 0x0c, 0x1d, 0x0c, 0x1d, 0x0c, 0x12, 0x12


END

