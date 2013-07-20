{Object_Title_and_Purpose}


CON
        _clkmode = xtal1 + pll16x                                               'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 5_000_000
        COL0 = 16
        COL1 = 18
        COL2 = 20
        COL3 = 22
        ROW0 = 24
        ROW1 = 26
        ROW2 = 29
        ROW3 = 28
VAR
  long  stack[100]
  byte  row[4]
  byte  col[4]
   
OBJ
  lcd : "hd44780.spin"

PUB init(buffer)
  cognew(run(buffer), @stack)  
  
PUB run(buffer) | i, c, next2nd
  row[0] := ROW0
  row[1] := ROW1
  row[2] := ROW2
  row[3] := ROW3
  col[0] := COL0
  col[1] := COL1
  col[2] := COL2
  col[3] := COL3
  repeat i from 0 to 3
    dira[ROW0] := 0
    dira[col[i]] := 1
    outa[col[i]] := 1

  repeat
    repeat i from 0 to 3
      outa[col[i]] := 0
      waitcnt(clkfreq/100 + 5 + cnt)
      repeat c from 0 to 3
        if ina[row[c]] == 0
           if next2nd == 1
              repeat until byte[buffer][1] == 0
              byte[buffer][0] := byte[@k2nd][(i*4) + c]
              byte[buffer][1] := 1
              next2nd := 0
           else
              if(i == 2) AND (c == 3)
                next2nd := 1
             repeat until byte[buffer][1] == 0
             byte[buffer][0] := byte[@kpad][(i*4) + c]
             byte[buffer][1] := 1
          repeat while ina[row[c]] == 0
      outa[col[i]] := 1
        

DAT
kpad    byte  "123u456d789nx0hw",0
k2nd    byte  "ABClDEFriiiixihw",0        
        