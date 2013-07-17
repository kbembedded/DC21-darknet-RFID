  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;                                                                          ;;
;;                                                                            ;;
;                      RFID Emulator - MULTI MEMORY-MAP                        ;
;;                                                                            ;;
 ;;                                                                          ;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



	#IFNDEF	MULTIMAP_INC
	
	#DEFINE MULTIMAP_INC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;								   DEFINITIONS                                ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	
	#DEFINE NUM_TAGS .12			; Number of RFID tags


	; TAG modulation modes
	#DEFINE TAG_MODE_CODING_BIT .0
	#DEFINE TAG_MODE_CODING_MANCHESTER b'00000000'
	#DEFINE TAG_MODE_CODING_BIPHASE	b'00000001'
	




	#ENDIF