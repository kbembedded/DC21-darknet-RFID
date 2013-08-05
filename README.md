DC21-darknet-RFID
=================

A Note to Those Who Bought the Kits at DEF CON:  This project will be on a short hiatus, I have some personal matters to attend to.  Rest assured, I will implement all of the functionality I originally imagined.  I am planning to continue development before the end of the month.  If anyone steps in and decides to work on it, awesome, send me patches and I will put them in for others.

Send any quesions to kris@kbembedded.com

Software, schematics, board, etc. for the DEF CON21 darknet ARG in the HHV

This project is based on the RFID_Emulator from http://www.kukata86.com/en/description-and-development-RFID-emulator

The RFID-emulator/ folder contains sources for the pic12f683 microcontroller to act as two types of LF RFID cards.  A standard EM4100, as well as EM4450/EM4150 to be compatible with the RFID reader and RFID reader/writer module from Parallax.  

The RFID-readerwriter/ folder contains spin sources for a Parallax reader/writer module connected to a Propeller, using a 4x4 matrix keypad interface, and an HD44780 LCD screen.
