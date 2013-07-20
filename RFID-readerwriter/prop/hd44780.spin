{Object_Title_and_Purpose}


CON
        _clkmode = xtal1 + pll16x                                               'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 5_000_000
        #8, DAT5, DAT4, DAT7, DAT6
        RW = 3
        RS = 0
        EN = 2
        CTRL = 0
        DA = 1

VAR
  long  stack[10] 

PUB start
  coginit(1, init, @stack)
PUB init
  dira[23] := 1
  dira[DAT7] := 1
  dira[DAT6] := 1
  dira[DAT5] := 1
  dira[DAT4] := 1
  dira[RS] := 1
  dira[EN] := 1
  outa[EN] := 0
  dira[RW] := 1


  waitcnt((clkfreq/1000) + 40 + cnt) 'wait 40ms for init
  dowrite($33, CTRL) 
  waitcnt((clkfreq/1000) + 4 + cnt) 'wait 4.1ms for init
  dowrite($32, CTRL)
  waitcnt((clkfreq/10000) + cnt) 'wait 100us for init
  dowrite($28, CTRL)
  dowrite($8, CTRL)
  dowrite($1, CTRL)
  dowrite($6, CTRL)
  dowrite($f, CTRL)

  'Set up 2nd up arrow
  dowrite($40, CTRL)
  dowrite(132, DA)
  dowrite(142, DA)
  dowrite(149, DA)
  dowrite(132, DA)
  dowrite(132, DA)
  dowrite(132, DA)
  dowrite(132, DA)

  dowrite($80, CTRL)


PUB writestring(line, str) | i
  dowrite(($80 + (line * $40)), CTRL)
  repeat i from 0 to 23
    dowrite(byte[str+i], DA)
    
PUB dowrite(data, lcdrs) | i, c
  repeat c from 0 to 1
     
    outa[RW] := outa[RS] := 0
    outa[DAT7] := (data >> 7)    
    outa[DAT6] := (data >> 6)
    outa[DAT5] := (data >> 5) 
    outa[DAT4] := (data >> 4)  
  ''outa[DAT7..DAT3] := ((data & $f0) >> 4)
    outa[RS] := lcdrs
    
    repeat i from 0 to 1
      !outa[EN] 'assert clk
      waitcnt((clkfreq/200000) + cnt) 'sleep 5us, minimum amount of time spin can handle
    data <<= 4

  waitcnt((clkfreq/1000) + cnt) 'wait 1ms for the command to be processed
PUB doread(readrs) | i, c, retval
  dira[DAT7] := 0
  dira[DAT6] := 0
  dira[DAT5] := 0
  dira[DAT4] := 0
  outa[RW] := 1
  outa[RS] := readrs
  retval := 0

  repeat c from 0 to 1
    'repeat i from 0 to 1
      '!outa[EN]
      'waitcnt((clkfreq/200000) + cnt)
    !outa[EN]
    !outa[23]
    waitcnt((clkfreq/200000) + cnt)
    'waitcnt((clkfreq/1000) + 200 + cnt) 'wait for data to be stable
    retval |= (ina[DAT7] << 3)
    retval |= (ina[DAT6] << 2)
    retval |= (ina[DAT5] << 1)
    retval |= (ina[DAT4] << 0)
    if c == 0
      retval <<= 4
    !outa[EN]
    !outa[23]
    waitcnt((clkfreq/200000) + cnt)
    
  dira[DAT7] := 1
  dira[DAT6] := 1
  dira[DAT5] := 1
  dira[DAT4] := 1

  return retval


PRI private_method_name


DAT
name    byte  "string_data",0