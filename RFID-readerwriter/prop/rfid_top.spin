{Object_Title_and_Purpose}


CON
        _clkmode = xtal1 + pll16x                                               'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 5_000_000

OBJ
  lcd : "hd44780.spin"
  kpad : "matrixkpad.spin"
VAR
  byte kpadbuffer[2]
  byte inbuf[24]
  byte bufpos          
PUB init | read
  kpadbuffer[0] := kpadbuffer[1] := 0
  lcd.init
  'lcd.dowrite("G", 1)
  lcd.writestring(1, string("This is a test string   "))
  lcd.dowrite($80, 0)
  kpad.init(@kpadbuffer)
  bytefill(@inbuf, " ", 24)

  repeat
    'mode
    'recv input from kpad
    if kpadbuffer[1] == 1
      case kpadbuffer[0]
        "i", "l", "u", "r", "d":
          lcd.dowrite(" ", 1)
          lcd.dowrite($4, 0)
          lcd.dowrite(" ", 1)
          lcd.dowrite($6, 0)
        "x" :
          if(bufpos <> 0)
           inbuf[--bufpos] := " "
           lcd.dowrite($4, 0)
           lcd.dowrite(" ", 1)
           lcd.dowrite($6, 0)
           lcd.dowrite(" ", 1)
           lcd.dowrite($4, 0)
           lcd.dowrite(" ", 1)
           lcd.dowrite($6, 0)
        "n" :
          lcd.dowrite(0, 1)
          lcd.dowrite($4, 0)
          lcd.dowrite(" ", 1)
          lcd.dowrite($6, 0)
        "w" :
          lcd.writestring(1, @inbuf)
          bytefill(@inbuf, " ", 24)
          lcd.writestring(0, @inbuf)
          lcd.dowrite($80, 0)
          bufpos := 0
        other:
          inbuf[bufpos++] := kpadbuffer[0]
          lcd.dowrite(kpadbuffer[0], 1)
      kpadbuffer[1] := 0
