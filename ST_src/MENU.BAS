DEFINT A-Z
DECLARE SUB menu ()
DECLARE SUB neatfont (txt$, sx%, sy%, clr%, sty%, size%)
DIM SHARED txt AS STRING, sx%, sy%, clr%, sty%, size%

CALL menu

DEFSNG A-Z
SUB menu
CALL bmp("logo.bmp")
PALETTE 13, 18
PALETTE 12, 18
PALETTE 14, 18

sel = 1
sel1 = 18
sel2 = 18
sel3 = 18
CALL neatfont("Start Game", -1, 200, 13, 3, 4)
CALL neatfont("About/Help", -1, 280, 12, 3, 4)
CALL neatfont("Exit", -1, 360, 14, 3, 4)

backtodo:
DO

SELECT CASE sel

  CASE 1
  IF sel1 < 60 THEN sel1 = sel1 + 1
  IF sel2 > 20 THEN sel2 = sel2 - 1
  IF sel3 > 20 THEN sel3 = sel3 - 1

  CASE 2
  IF sel1 > 20 THEN sel1 = sel1 - 1
  IF sel2 < 60 THEN sel2 = sel2 + 1
  IF sel3 > 20 THEN sel3 = sel3 - 1

  CASE 3
  IF sel1 > 20 THEN sel1 = sel1 - 1
  IF sel2 > 20 THEN sel2 = sel2 - 1
  IF sel3 < 60 THEN sel3 = sel3 + 1
END SELECT

LOCATE 1, 1: COLOR 13: PRINT sel

PALETTE 13, 65536 * sel1 + 256 * sel1 + sel1
PALETTE 12, 65536 * sel2 + 256 * sel2 + sel2
PALETTE 14, 65536 * sel3 + 256 * sel3 + sel3

        Choice$ = INKEY$
    ' Handle ASCII keys
        SELECT CASE Choice$

CASE CHR$(0) + CHR$(72)
  IF sel <= 1 THEN sel = 3 ELSE sel = sel - 1
 
  CASE CHR$(0) + CHR$(80)

  IF sel >= 3 THEN sel = 1 ELSE sel = sel + 1

  CASE CHR$(13)
  GOTO choiced

  CASE ELSE
 
END SELECT

LOOP

choiced:
SELECT CASE sel
    CASE 1
    'GOTO endsub

    CASE 2
    'CALL about

    CASE 3
    END
END SELECT

END SUB

DEFINT A-Z
SUB neatfont (txt$, sx%, sy%, clr%, sty%, size%)

 lnh% = LEN(txt$)
 IF sx% = -1 THEN sx% = (640 - ((lnh% * 8) * size%)) / 2
 sx2% = sx%: l% = lnh% * 8
 COLOR 8: LOCATE 1, 1: PRINT txt$

 FOR y% = 0 TO 15
  FOR x% = 0 TO l%
  IF POINT(x%, y%) <> 0 THEN
   IF sty% = 1 THEN LINE (sx2% - size%, sy% - size%)-(sx2%, sy%), clr%, BF
   IF sty% = 2 THEN LINE (sx2% - size%, sy% - size%)-(sx2%, sy%), clr%, B
   IF sty% = 3 THEN CIRCLE (sx2% - (size% / 2), sy% - (size% / 2)), size% / 2, clr%
   IF sty% = 4 THEN
    CIRCLE (sx2% - (size% / 2), sy% - (size% / 2)), size% / 2, clr%
    PAINT (sx2% - (size% / 2), sy% - (size% / 2)), clr%
   END IF
   IF sty% = 5 THEN PSET (sx2% - (size% / 2), sy% - (size% / 2)), clr%
   IF sty% = 6 OR sty% = 7 THEN
    LINE (sx2% - (size% / 2), sy% - size%)-(sx2% - size%, sy%), clr%
    LINE (sx2% - (size% / 2), sy% - size%)-(sx2%, sy%), clr%
    LINE (sx2% - size%, sy%)-(sx2%, sy%), clr%
   END IF
   IF sty% = 7 THEN PAINT (sx2% - (size% / 2), sy% - (size% / 2)), clr%
   IF sty% = 8 THEN LINE (sx2%, sy% - size%)-(sx2% - size%, sy%), clr%
   IF sty% = 9 THEN LINE (sx2% - size%, sy% - size%)-(sx2%, sy%), clr%
  END IF
  sx2% = sx2% + size%
  NEXT x%
  sy% = sy% + size%: sx2% = sx%
 NEXT y%
 LOCATE 1, 1: COLOR 0: PRINT txt$

END SUB

