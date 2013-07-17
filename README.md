DC21-darknet-RFID
=================

Software, schematics, board, etc. for the DEF CON21 darknet ARG in the HHV

This project is based on the RFID_Emulator from http://www.kukata86.com/en/description-and-development-RFID-emulator

The RFID-emulator/ folder contains sources for the pic12f683 microcontroller to act as two types of LF RFID cards.  A standard EM4100, as well as EM4450/EM4150 to be compatible with the RFID reader and RFID reader/writer module from Parallax.  

The RFID-readerwriter/ folder contains spin sources for a Parallax reader/writer module connected to a Propeller, using a 4x4 matrix keypad interface, and an HD44780 LCD screen.
