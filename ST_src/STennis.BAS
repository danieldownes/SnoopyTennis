DECLARE SUB fadein ()
DECLARE SUB fadeout ()
DECLARE SUB gameover (s%)
DECLARE SUB allblack ()
DECLARE SUB about ()
DECLARE FUNCTION DSPVersion! ()
DECLARE SUB loadbmp (data$)
' Declare our procedures
'
DECLARE SUB BlastGet (dsegment%, doffset%, ssegment%, soffset%, x1%, y1%, x2%, y2%)
DECLARE SUB BlastPut (dsegment%, doffset%, ssegment%, soffset%, xpos%, ypos%, icol%)
DECLARE SUB BlastPset (Segment%, Offset%, xpos%, ypos%, col%)
DECLARE FUNCTION BlastPoint% (Segment%, Offset%, xpos%, ypos%)
DECLARE SUB BlastCopy (fsegment%, foffset%, tsegment%, toffset%)
DECLARE SUB BlastScroll (fsegment%, foffset%, tsegment%, toffset%, xoffset%, yoffset%)
DECLARE SUB BlastCLS (Segment%, Offset%, col%)
DECLARE SUB BlastPrint (Segment%, Offset%, xpos%, ypos%, text$, col%)
DECLARE SUB BlastLine (dsegment%, doffset%, x1%, y1%, x2%, y2%, colr%)
DECLARE SUB InitLib ()

DECLARE FUNCTION BytesRequired& (Filename$)
DECLARE FUNCTION DriverLoaded% (DriverFN$)
DECLARE SUB LoadAndPlayLarge (Filename$)
DECLARE SUB LoadAndPlayMIDI (Filename$, MIDISegment%, MIDIOffset%)
DECLARE SUB LoadLarge (Filename$)
DECLARE SUB LoadMIDI (Filename$, MIDISegment%, MIDIOffset%)
DECLARE FUNCTION MIDIError$ ()
DECLARE SUB PlayLarge ()
DECLARE SUB PlayMIDI (MIDISegment%, MIDIOffset%)
DECLARE SUB stopmidi ()
DECLARE FUNCTION TimeMIDI! ()
DEFINT A-Z
DECLARE SUB menu ()
DECLARE SUB neatfont (txt$, sx%, sy%, clr%, sty%, size%)
DIM SHARED txt AS STRING, sx%, sy%, clr%, sty%, size%
DIM SHARED palhold(0 TO 255, 1 TO 3) AS INTEGER
DECLARE SUB Zoom (x)
DECLARE SUB endst ()

restart:

'GOTO misslogo

SCREEN 13
CLS

pause! = TIMER + 1
DO WHILE pause! > TIMER
LOOP

x = 50: Xdelta = 8: R = 32: B = 0: G = 32

DO WHILE x < 680 AND x > 1
     
PALETTE 72, 65536 * B
     
      x = x + Xdelta
      CALL Zoom(x)
        FOR I = 1 TO 4000
        NEXT I
   
        B = B + 1
           IF B > 63 THEN B = 63

     'D
    LINE (-135, 100)-(-210, 100), 0
    LINE (-135, 100)-(-135, -100), 0
    LINE (-135, -100)-(-210, -100), 0
    LINE (-200, 100)-(-200, -100), 0
   
   

    'A
    LINE (-50, 100)-(25, 100), 0
    LINE (-50, 100)-(-50, -100), 0
    LINE (-50, 0)-(25, 0), 0
    LINE (25, 100)-(25, -100), 0
    'N
    LINE (105, 100)-(180, -100), 0
    LINE (180, 100)-(180, -100), 0
   
    LINE (105, 100)-(105, -100), 0

LOOP

B = 1

FOR a = 75 TO 1 STEP -1

    PALETTE B, 256 * B + B
    PALETTE 100, 18
    PALETTE 101, 10

    CIRCLE (-500, 0), a, B
    
COLOR B
LOCATE 7, 15
PRINT "Extravaganza"
LOCATE 19, 17
PRINT "Presents..."
   
    PAINT (-500, 0), B

    LINE (-420, -10)-(450, 5), 101, BF
    LINE (-415, -3)-(445, -3), 100

    CALL Zoom(x)

    B = B + 1
        IF B > 63 THEN B = 63

            
            

NEXT

CALL Zoom(x)
start! = TIMER + 2
rretime:
finish! = TIMER
IF finish! < start! THEN GOTO rretime

CALL fadeout

misslogo:

'GOTO missqmidi



DIM SHARED MIDI.PLAYTIME AS SINGLE
DIM SHARED MIDI.ERROR AS INTEGER
DIM SHARED MIDI.LOADED AS INTEGER
MIDI.PLAYTIME = 0
MIDI.ERROR = 0
MIDI.LOADED = 0

'INSERT YOUR OWN CODE BEGINNING HERE - SEE SAMPLE.BAS FOR A QMIDI DEMO

DIM MIDI%(16000)
LoadAndPlayMIDI "peanuts.mid", VARSEG(MIDI%(0)), VARPTR(MIDI%(0))
missqmidi:




'
' Reserve assembler routine code memory
'
DIM SHARED code1%(14), code2%(21), code3%(91), code4%(76), code6%(17), code7%(25), code8%(118), code9%(14)
DEFINT A-Z
DIM byte AS STRING * 1

'
' Initilize Assembler Routines
'
CALL InitLib
'
'****************************************************************************
'
' Reserve memory for two off-screen buffers, sprites and demo variables
' Use REDIM so that we may de-allocate the memory at the end of the program
'
REDIM buffer1%(31999) ' This is an off-screen buffer
REDIM buffer2%(31999) ' This is another...
REDIM sbuffer%(2000)  ' This is the ball
REDIM snoopy%(2668)   ' Snoopy in stand-by possition
REDIM snoopy1%(2668)  ' Snoopy in a hitting possition
REDIM snoopy2%(2668)  ' Snoopy in a swung possition
REDIM lucy(3000)      ' Lucy, holding racket above
REDIM lucy2(3000)      ' Lucy, holding racket below
REDIM charly1(3000)   ' Charly in stand-by possition
REDIM charly2(3000)   ' Charly in a hitting possition
REDIM charly3(3000)   ' Charly in a swung possition

'
DIM bx%(40), by%(40), bt%(40), dx%(40), dy%(40)' Variables for demo


'
'****************************************************************************
'
' Initialize Balls
'
  t% = 1
  'DO
    dx% = 1: dy% = 1
  'LOOP UNTIL dx% <> 0 AND dy% <> 0
'
SCREEN 12
CALL menu

'
'
'
SCREEN 13
'
' Clear the background
'
CALL BlastCLS(VARSEG(buffer2%(0)), VARPTR(buffer2%(0)), 0)
'
x1% = 159: y1% = 99: colr% = 0
'
'
'
CALL loadbmp("SNDATA9.DAT")
GET (0, 0)-(58, 46), snoopy

CALL loadbmp("SNDATAa.DAT")
GET (0, 0)-(58, 46), snoopy1

CALL loadbmp("sndata2.dat")
GET (0, 0)-(58, 46), snoopy2

CALL loadbmp("SNDATA3.dat")
GET (0, 0)-(46, 84), lucy

CALL loadbmp("SNDATA4.DAT")
GET (0, 0)-(46, 84), lucy2

CALL loadbmp("SNDATA5.DAT")
GET (0, 26)-(63, 101), charly1

CALL loadbmp("SNDATA6.DAT")
GET (0, 26)-(63, 101), charly2

CALL loadbmp("SNDATA7.DAT")
GET (0, 26)-(63, 101), charly3

CALL loadbmp("SNDATA8.DAT")
GET (0, 0)-(319, 198), buffer2%

SCREEN 13

'
COLOR 2
LOCATE 1, 1: PRINT "Ready? Hit any key to begin.            "
COLOR 15

score = 0
lives = 3
DO: LOOP UNTIL INKEY$ <> ""

CLS
'
' Create a 32 x 32 sprite for us to use
'
o = 0
FOR t% = 6 TO 0 STEP -1
  c% = 31 - t%
  CIRCLE (6, 6), t%, c%
  PAINT (6, 6), c%
  NEXT t%
'
' Get our sprites
'
CALL BlastGet(&HA000, 0, VARSEG(sbuffer%(0)), VARPTR(sbuffer%(0)), 0, 0, 31, 31)
'
'
CALL BlastGet(&HA000, 0, VARSEG(sbuffer%(0)), VARPTR(sbuffer%(514)), 7, 7, 22, 22)
'
' Initialize Demo Variables
'
 done% = 0
'te = TIMER

TYPE ballt
 x AS INTEGER
 y AS INTEGER
 balltype AS INTEGER
 n AS INTEGER
END TYPE
DIM SHARED ball(40) AS ballt

lastn = -40
stage = 1
ysnoopy = 155

fromlucy:
IF lastn + 30 > n THEN GOTO startdo

serve:
bio = bio + 1
cwing = 1
IF balls = 0 THEN GOTO noballs
FOR ah = 1 TO balls
IF ball(ah).balltype = 0 THEN ball(ah).balltype = INT(RND * 5) + 1: ball(ah).n = 0: ball(ah).x = 10: ball(ah).y = 160: GOTO startdo
NEXT ah

noballs:
balls = balls + 1
ball(balls).balltype = INT(RND * 5) + 1
ball(balls).x = 10
ball(balls).y = 160
ball(balls).n = 0
startdo:
n = n + 1
IF cwing = 0 AND tyi = 0 AND lastn < n THEN
    lastn = n + 30
    SELECT CASE n
        CASE IS > 1200
        IF bio <= 5 THEN GOTO serve
        IF INT(RND * 1000) + 1 < 70 THEN tyi = 1: GOTO serve
        CASE 900 TO 1199
        IF INT(RND * 1000) + 1 < 100 THEN tyi = 1: GOTO serve
        CASE 600 TO 899
        IF bio <= 2 THEN GOTO serve
        IF INT(RND * 1000) + 1 < 50 THEN tyi = 1: GOTO serve
        CASE 200 TO 599
        IF bio <= 1 THEN GOTO serve
        IF INT(RND * 1000) + 1 < 20 THEN tyi = 1: GOTO serve
    END SELECT
END IF
 
  ' background
CALL BlastCopy(VARSEG(buffer2%(0)), VARPTR(buffer2%(0)), VARSEG(buffer1%(0)), VARPTR(buffer1%(0)))
tyi = 0
    SELECT CASE n
        CASE IS > 1201
        IF INT(RND * 1000) + 1 < 30 THEN lastn = n: lret = 1
        CASE 901 TO 1200
        IF INT(RND * 1000) + 1 < 25 THEN lastn = n: lret = 1
        CASE 601 TO 900
        IF INT(RND * 1000) + 1 < 15 THEN lastn = n: lret = 1
        CASE 201 TO 300
        IF INT(RND * 1000) + 1 < 20 THEN lastn = n: lret = 1
        CASE IS < 200     'With lastn, don't forget to reset when n is reset!!
        lret = 0
    END SELECT

' Animation for swinging
IF swing = 1 THEN swingtime = swingtime + 1
IF swing = 2 THEN swingtime1 = swingtime1 + 1
IF swingtime > 3 THEN swing = 2: swingtime = 0
IF swingtime1 > 2 THEN swing = 0: swingtime1 = 0
SELECT CASE swing
    CASE 0
CALL BlastPut(VARSEG(buffer1%(0)), VARPTR(buffer1%(0)), VARSEG(snoopy%(0)), VARPTR(snoopy%(bt% * 514)), 215, ysnoopy, 0)
    CASE 1
CALL BlastPut(VARSEG(buffer1%(0)), VARPTR(buffer1%(0)), VARSEG(snoopy1%(0)), VARPTR(snoopy1%(bt% * 514)), 215, ysnoopy, 0)
    CASE 2
CALL BlastPut(VARSEG(buffer1%(0)), VARPTR(buffer1%(0)), VARSEG(snoopy2%(0)), VARPTR(snoopy2%(bt% * 514)), 215, ysnoopy, 0)
END SELECT


IF lret = 0 THEN CALL BlastPut(VARSEG(buffer1%(0)), VARPTR(buffer1%(0)), VARSEG(lucy2(0)), VARPTR(lucy2(bt% * 514)), 20, 1, 0)
IF lret = 1 THEN CALL BlastPut(VARSEG(buffer1%(0)), VARPTR(buffer1%(0)), VARSEG(lucy(0)), VARPTR(lucy(bt% * 514)), 20, 1, 0)



FOR nn = 1 TO balls
ball(nn).n = ball(nn).n + 1
SELECT CASE ball(nn).balltype
       CASE 1
ball(nn).x = ball(nn).x + 5
ball(nn).y = ball(nn).y - 1 + ((ball(nn).n * ball(nn).n) / 700)
       CASE 2
ball(nn).x = ball(nn).x + 5
ball(nn).y = ball(nn).y - 2 + ((ball(nn).n * ball(nn).n) / 700)
       CASE 3
ball(nn).x = ball(nn).x + 6
ball(nn).y = ball(nn).y - 4 + ((ball(nn).n * ball(nn).n) / 250)
       CASE 4
ball(nn).x = ball(nn).x + 6
ball(nn).y = ball(nn).y - 4 + ((ball(nn).n * ball(nn).n) / 500)
       CASE 5
ball(nn).x = ball(nn).x + 6
ball(nn).y = ball(nn).y - 7 + ((ball(nn).n * ball(nn).n) / 170)
       CASE 11
ball(nn).x = ball(nn).x - 6
ball(nn).y = ball(nn).y - 6 + ((ball(nn).n * ball(nn).n) / 200)
       CASE 12
ball(nn).x = ball(nn).x - 6
ball(nn).y = ball(nn).y - 6 + ((ball(nn).n * ball(nn).n) / 100)
       CASE 13
ball(nn).x = ball(nn).x - 6
ball(nn).y = ball(nn).y - 4 + ((ball(nn).n * ball(nn).n) / 150)
       CASE 14
ball(nn).x = ball(nn).x - 6
ball(nn).y = ball(nn).y - 2 + ((ball(nn).n * ball(nn).n) / 258)
       CASE 15
ball(nn).x = ball(nn).x - 6
ball(nn).y = ball(nn).y + ((ball(nn).n * ball(nn).n) / 330)
       CASE 21
ball(nn).x = ball(nn).x + 9
ball(nn).y = ball(nn).y - 1 + ((ball(nn).n * ball(nn).n) / 240)
       CASE 22
ball(nn).x = ball(nn).x + 9
ball(nn).y = ball(nn).y + ((ball(nn).n * ball(nn).n) / 413)
       CASE 23
ball(nn).x = ball(nn).x + 9
ball(nn).y = ball(nn).y + ((ball(nn).n * ball(nn).n) / 623)
       CASE 24
ball(nn).x = ball(nn).x + 9
ball(nn).y = ball(nn).y - 2 + ((ball(nn).n * ball(nn).n) / 583)
       CASE 25
ball(nn).x = ball(nn).x + 9
ball(nn).y = ball(nn).y - 2 + ((ball(nn).n * ball(nn).n) / 1983)

END SELECT


'Check if there are ball on the screen, if not then serve
IF bio = 0 THEN GOTO serve

'Check if the ball is being hit...
IF ball(nn).x > 225 AND ball(nn).x < 249 AND ball(nn).balltype <= 5 AND ball(nn).balltype = stage AND swing = 1 THEN
    ball(nn).balltype = ball(nn).balltype + 10
    ball(nn).n = 0
    
    score = score + 2

    IF n < 300 AND cwing = 0 THEN tyi = 1: GOTO serve
    IF n > 301 AND n < 600 AND cwing = 0 THEN IF INT(RND * 100) + 1 < 50 THEN GOTO serve
END IF

IF ball(nn).x > 225 AND ball(nn).x < 249 AND ball(nn).balltype > 20 AND ball(nn).balltype = stage + 20 AND swing = 1 THEN
    ball(nn).balltype = ball(nn).balltype - 10
    ball(nn).n = 0
   
    score = score + 3

    '''''''''IF n > 301 AND n < 600 AND cwing = 0 THEN IF INT(RND * 100) + 1 < 50 THEN GOTO serve
END IF

'If ball has been missed
IF ball(nn).x > 307 AND ball(nn).balltype <> 0 THEN

'FOR fg = 100 TO 500 STEP 50
'SOUND fg, 1
'NEXT fg
BEEP

lives = lives - 1
IF lives < 0 THEN CALL gameover(score): CLEAR : GOTO restart
FOR bb = 1 TO balls
ball(bb).balltype = 0
NEXT bb
bio = 0
GOTO serve
END IF

 IF ball(nn).x < 20 AND ball(nn).balltype > 10 THEN ball(nn).balltype = 0: ball(nn).n = 0: bio = bio - 1

'Return from Lucy?
 IF ball(nn).x < 54 AND ball(nn).balltype > 10 AND lret = 1 THEN
  ball(nn).balltype = ball(nn).balltype + 10
  lret = 0
 END IF

IF ball(nn).balltype = 0 THEN GOTO missnn
CALL BlastPut(VARSEG(buffer1%(0)), VARPTR(buffer1%(0)), VARSEG(sbuffer%(0)), VARPTR(sbuffer%(bt% * 514)), ball(nn).x, ball(nn).y, 0)
missnn:
tyi = 0
NEXT nn
                                           
IF cwing = 1 THEN cwingtime = cwingtime + 1
IF cwing = 2 THEN cwingtime1 = cwingtime1 + 1
IF cwingtime > 5 THEN cwing = 2: cwingtime = 0
IF cwingtime1 > 5 THEN cwing = 0: cwingtime1 = 0
SELECT CASE cwing
    CASE 0
CALL BlastPut(VARSEG(buffer1%(0)), VARPTR(buffer1%(0)), VARSEG(charly1(0)), VARPTR(charly1(bt% * 514)), 12, 143, 0)
    CASE 1
CALL BlastPut(VARSEG(buffer1%(0)), VARPTR(buffer1%(0)), VARSEG(charly2(0)), VARPTR(charly2(bt% * 514)), 12, 143, 0)
    CASE 2
CALL BlastPut(VARSEG(buffer1%(0)), VARPTR(buffer1%(0)), VARSEG(charly3(0)), VARPTR(charly3(bt% * 514)), 12, 143, 0)
END SELECT
'
' Copy the off-screen buffer to the visible screen
CALL BlastCopy(VARSEG(buffer1%(0)), VARPTR(buffer1%(2)), &HA000, 0)

stscore$ = STR$(score)
CALL BlastPrint(VARSEG(buffer1%(0)), VARPTR(buffer1%(0)), 1, 1, stscore$, 15)
'LOCATE 1, 1: PRINT "Score,"; score
LOCATE 1, 14: PRINT "Lives,"; lives


start! = TIMER + .09
retime:
finish! = TIMER   'VAL(fin$)
IF finish! < start! THEN GOTO retime


a$ = INKEY$
SELECT CASE a$
    CASE "p", "P", CHR$(0) + CHR$(72)
    IF stage >= 5 THEN GOTO getout
    stage = stage + 1
    CASE "l", "L", CHR$(0) + CHR$(80)
    IF stage <= 1 THEN GOTO getout
    stage = stage - 1
    CASE " "
    IF swing <> 0 THEN GOTO getout
    swing = 1
  END SELECT
getout:
 SELECT CASE stage
   CASE 1
   ysnoopy = 155
   CASE 2
   ysnoopy = 110
   CASE 3
   ysnoopy = 80
   CASE 4
   ysnoopy = 40
   CASE 5
   ysnoopy = 5
 END SELECT

GOTO startdo
'
CLS
'
' Deallocate our large buffers, using REDIM to size to zero
'
REDIM buffer1%(0) ' This is an off-screen buffer
REDIM buffer2%(0) ' This is another...
REDIM sbuffer%(0) ' This is our sprite buffer
'
'****************************************************************************

SUB about
REDIM aboute(2000)
COLOR 15
OPEN "sndata1.dat" FOR INPUT AS #2
wh = 1
DO
FOR y = 2 TO 479 STEP 1
GET (0, y + 1)-(639, y + 1), aboute
PUT (0, y - 1), aboute, PSET
NEXT y
IF wh = 9 THEN
    wh = 1
    INPUT #2, txt$
    LOCATE 26, 1
    PRINT txt$
END IF
wh = wh + 1
LOOP UNTIL EOF(2) OR INKEY$ <> ""
'pause
CLOSE #2
REDIM aboute(0)
END SUB

DEFSNG A-Z
SUB allblack
FOR pal = 1 TO 15
PALETTE pal, 0
NEXT pal
END SUB

SUB BlastCLS (Segment%, Offset%, col%)
  '
  ' Clear the screen!
  '
  DEF SEG = VARSEG(code6%(0))
  '
  CALL ABSOLUTE(BYVAL Segment%, BYVAL Offset%, BYVAL col%, VARPTR(code6%(0)))
  '
  DEF SEG
  '
END SUB

SUB BlastCopy (fsegment%, foffset%, tsegment%, toffset%)
  '
  ' No error checking is done for this routine, so be careful when
  ' you set the from and to segements and offsets - you could crash
  ' your machine...
  '
  ' I have noticed on slower machines running QuickBASIC that the following
  ' line slows the code down. Comment this line out if you notice it. For
  ' some reason QBASIC is unaffected. This line is only used to cut down on
  ' screen shearing at the time of the copy, and isn't needed unless you need
  ' the most solid display anyhow...
  '
  IF tsegment% = &HA000 THEN WAIT &H3DA, 8            ' Wait for vertical retrace
  '
  ' Copy!
  '
  DEF SEG = VARSEG(code1%(0))
  '
  CALL ABSOLUTE(BYVAL fsegment%, BYVAL foffset%, BYVAL tsegment%, BYVAL toffset%, VARPTR(code1%(0)))
 
DEF SEG
  '
END SUB

SUB BlastGet (dsegment%, doffset%, ssegment%, soffset%, x1%, y1%, x2%, y2%)
  '
  ' No error checking is done for X and Y coordinates, nor for any segments
  ' and offsets into memory. Therefore, use care when setting them so you
  ' don't crash your machine.
  '
  DEF SEG = VARSEG(code4%(0))
  '
  CALL ABSOLUTE(BYVAL dsegment%, BYVAL doffset%, BYVAL ssegment%, BYVAL soffset%, BYVAL x1%, BYVAL y1%, BYVAL x2%, BYVAL y2%, VARPTR(code4%(0)))
  '
  DEF SEG
  '
END SUB

SUB BlastLine (dsegment%, doffset%, x1%, y1%, x2%, y2%, colr%)
  '
  ' This is a simple routine which uses the traditional
  ' Bresenham Algorithm to draw a line between two points.
  '
  ' No error checking is performed for endpoints in this routine,
  ' so be careful not to let the ends fall out of bounds, since
  ' doing so may cause your machine to crash...
  '
  DEF SEG = VARSEG(code8%(0))
  '
  CALL ABSOLUTE(BYVAL dsegment%, BYVAL doffset%, BYVAL x1%, BYVAL y1%, BYVAL x2%, BYVAL y2%, BYVAL colr%, VARPTR(code8%(0)))
  '
  DEF SEG
  '
END SUB

FUNCTION BlastPoint% (Segment%, Offset%, xpos%, ypos%)
  '
  ' No error checking is done for X and Y coordinates, nor for any segments
  ' and offsets into memory. Therefore, use care when setting them so you
  ' don't crash your machine.
  '
  ' Get the pixel!
  '
  col% = 0
  '
  DEF SEG = VARSEG(code7%(0))
  '
  CALL ABSOLUTE(BYVAL Segment%, BYVAL Offset%, BYVAL xpos%, BYVAL ypos%, BYVAL VARSEG(col%), BYVAL VARPTR(col%), VARPTR(code7%(0)))
  '
  DEF SEG
  '
  BlastPoint% = col%
  '
END FUNCTION

SUB BlastPrint (Segment%, Offset%, xpos%, ypos%, text$, col%)
  '
  ' CGA Character Set (8 x 8)
  '
  xx% = xpos% - 1
  yy% = ypos%
  '
  FOR chr% = 1 TO LEN(text$)
    xx% = xx% + 8
    ptr% = 8 * ASC(MID$(text$, chr%, 1)) + &HE
    FOR l% = 0 TO 7
      DEF SEG = &HFFA6: BitPattern% = PEEK(ptr% + l%): DEF SEG
      IF BitPattern% AND 1 THEN CALL BlastPset(Segment%, Offset%, xx%, yy% + l%, col%)
      IF BitPattern% AND 2 THEN CALL BlastPset(Segment%, Offset%, xx% - 1, yy% + l%, col%)
      IF BitPattern% AND 4 THEN CALL BlastPset(Segment%, Offset%, xx% - 2, yy% + l%, col%)
      IF BitPattern% AND 8 THEN CALL BlastPset(Segment%, Offset%, xx% - 3, yy% + l%, col%)
      IF BitPattern% AND 16 THEN CALL BlastPset(Segment%, Offset%, xx% - 4, yy% + l%, col%)
      IF BitPattern% AND 32 THEN CALL BlastPset(Segment%, Offset%, xx% - 5, yy% + l%, col%)
      IF BitPattern% AND 64 THEN CALL BlastPset(Segment%, Offset%, xx% - 6, yy% + l%, col%)
      IF BitPattern% AND 128 THEN CALL BlastPset(Segment%, Offset%, xx% - 7, yy% + l%, col%)
    NEXT
  NEXT
  '
  DEF SEG
  '
END SUB

SUB BlastPset (Segment%, Offset%, xpos%, ypos%, col%)
  '
  ' No error checking is done for X and Y coordinates, nor for any segments
  ' and offsets into memory. Therefore, use care when setting them so you
  ' don't crash your machine.
  '
  ' Plot the pixel!
  '
  DEF SEG = VARSEG(code2%(0))
  '
  CALL ABSOLUTE(BYVAL Segment%, BYVAL Offset%, BYVAL xpos%, BYVAL ypos%, BYVAL col%, VARPTR(code2%(0)))
  '
  DEF SEG
  '
END SUB

SUB BlastPut (dsegment%, doffset%, ssegment%, soffset%, xpos%, ypos%, icol%)
  '
  ' No error checking is done for X and Y coordinates, nor for any segments
  ' and offsets into memory. Therefore, use care when setting them so you
  ' don't crash your machine.
  '
  DEF SEG = VARSEG(code3%(0))
  '
  CALL ABSOLUTE(BYVAL dsegment%, BYVAL doffset%, BYVAL ssegment%, BYVAL soffset%, BYVAL xpos%, BYVAL ypos%, BYVAL icol%, VARPTR(code3%(0)))
  '
  DEF SEG
  '
END SUB

SUB BlastScroll (fsegment%, foffset%, tsegment%, toffset%, xoffset%, yoffset%)
  '
  ' Scroll the screen!
  '
  NumBytes% = &HFA00 ' 64000 Bytes
  '
  OffsetBytes% = (ABS(yoffset%) * 320)
  NumBytes% = NumBytes% - OffsetBytes%
  '
  IF yoffset% >= 0 THEN
    foffset% = foffset% + OffsetBytes%
  ELSE
    toffset% = toffset% + OffsetBytes%
  END IF
  '
  OffsetBytes% = ABS(xoffset%)
  NumBytes% = NumBytes% - OffsetBytes%
  '
  IF xoffset% >= 0 THEN
    foffset% = foffset% + OffsetBytes%
  ELSE
    toffset% = toffset% + OffsetBytes%
  END IF
  '
  DEF SEG = VARSEG(code9%(0))
  '
  CALL ABSOLUTE(BYVAL fsegment%, BYVAL foffset%, BYVAL tsegment%, BYVAL toffset%, BYVAL NumBytes%, VARPTR(code9%(0)))
  '
  DEF SEG
  '
END SUB

'BytesRequired - Returns the amount of memory needed to store a file.
FUNCTION BytesRequired& (Filename$)
'Open the file.
FF% = FREEFILE
OPEN Filename$ FOR BINARY AS #FF%
'Store the length of the file.
FileLen& = LOF(FF%)
'Close the file.
CLOSE FF%
'If the length of the file is 0, assume it does not exist and delete it.
IF FileLen& = 0 THEN KILL Filename$
'Return the length of the file as the number of bytes required.
BytesRequired& = FileLen&
MIDI.ERROR = 0
END FUNCTION

'DriverLoaded - Primitive function to detect if sound driver is loaded
FUNCTION DriverLoaded% (DriverFN$)
'See if a filename for the SBMIDI driver has been supplied.
IF DriverFN$ <> "" THEN
        'If so, check to see if a file extension was supplied.
        IF INSTR(DriverFN$, ".") <> 0 THEN
                'If an extension was supplied, remove it.
                DriverFN$ = LEFT$(DriverFN$, LEN(DriverFN$) - 4)
        END IF
'If no filename was supplied, use the default
ELSE DriverFN$ = "SBMIDI"
END IF
'Call the MEM command with the /CLASSIFY option, and save the output
'to a temporary file.
SHELL "MEM /CLASSIFY > QMIDIMEM.TMP"

'Open the temporary file.
FF% = FREEFILE
OPEN "QMIDIMEM.TMP" FOR INPUT AS #FF%
'See if the file is valid.
LINE INPUT #1, a$: LINE INPUT #1, a$
LINE INPUT #1, B$: LINE INPUT #1, B$
'If not, exit now.
IF a$ <> "Modules using memory below 1 MB:" OR B$ <> "  Name           Total       =   Conventional   +   Upper Memory" THEN
        'Return an error
        DriverLoaded% = 2
        EXIT FUNCTION
END IF
'Otherwise, begin searching the file
DriverFound% = 0
LINE INPUT #1, a$
DO UNTIL EOF(FF%)
LINE INPUT #1, a$
IF a$ = "" THEN EXIT DO
IF RTRIM$(MID$(a$, 3, 8)) = UCASE$(DriverFN$) THEN DriverFound% = 1
LOOP
'Close the temporary file.
CLOSE #FF%
'Delete it.
KILL "QMIDIMEM.TMP"

'Return whether or not the drivers are loaded.
DriverLoaded% = DriverFound%
MIDI.ERROR = 0
END FUNCTION

DEFINT A-Z
SUB endst
CALL neatfont("Snoopy Tennis v2.00.10", -1, 50, 15, 4, 3)
CALL neatfont("By Daniel Vincent", -1, 100, 15, 4, 2)
CALL neatfont("Comments/suggestions:-", -1, 175, 15, 4, 3)
CALL neatfont("Daniel@vincent99.freeserve.co.uk", -1, 225, 15, 4, 2)
CALL neatfont("Updates/info", -1, 300, 15, 4, 3)
CALL neatfont("WWW.vincent99.freeserve.co.uk", -1, 350, 15, 4, 2)
COLOR 15
LOCATE 25, 1
PRINT "(When there click on topics then Extravagaza DAN and then Snoopy Tennis)"

CALL fadein
start! = TIMER + 3
reeetime:
finish! = TIMER
IF finish! < start! THEN GOTO reeetime

PRINT : PRINT "Press any key to end"
DO
LOOP UNTIL INKEY$ <> ""
CALL stopmidi
END SUB

DEFSNG A-Z
SUB fadein

FOR fina = 1 TO 62
FOR finc = 0 TO 255
OUT &H3C7, finc: rgg = INP(&H3C9): ggg = INP(&H3C9): bgg = INP(&H3C9)
IF rgg < palhold(finc, 1) THEN rgg = rgg + 1
IF ggg < palhold(finc, 2) THEN ggg = ggg + 1
IF bgg < palhold(finc, 3) THEN bgg = bgg + 1
OUT &H3C8, finc: OUT &H3C9, rgg: OUT &H3C9, ggg: OUT &H3C9, bgg
NEXT finc
WAIT &H3DA, 8
NEXT fina

END SUB

SUB fadeout

FOR fout = 0 TO 255
OUT &H3C7, fout: rgg = INP(&H3C9): ggg = INP(&H3C9): bgg = INP(&H3C9)
palhold(fout, 1) = rgg
palhold(fout, 2) = ggg
palhold(fout, 3) = bgg
NEXT fout

FOR foutq = 1 TO 62
FOR foutc = 0 TO 255
OUT &H3C7, foutc: rgg = INP(&H3C9): ggg = INP(&H3C9): bgg = INP(&H3C9)
IF rgg > 0 THEN rgg = rgg - 1
IF ggg > 0 THEN ggg = ggg - 1
IF bgg > 0 THEN bgg = bgg - 1
OUT &H3C8, foutc: OUT &H3C9, rgg: OUT &H3C9, ggg: OUT &H3C9, bgg
NEXT foutc
WAIT &H3DA, 8
NEXT foutq

END SUB

DEFINT A-Z
SUB gameover (s)
CALL neatfont("Game Over!", 50, 10, 150, 4, 2)
COLOR 15
LOCATE 10, 1
sc$ = STR$(s)
SELECT CASE s
    CASE IS < 49
    result$ = "You have an appalling score of " + sc$
    CASE IS > 50, IS < 149
    result$ = sc$ + ", Slightly more pratice needed!!"
    CASE IS > 150, IS < 199
    result$ = sc$ + " Quite good!                "
    CASE IS > 200, IS < 299
    result$ = sc$ + " very good!                 "
    CASE IS > 300
    result$ = "Excellent, you scroed          " + sh$
END SELECT
COLOR 15: LOCATE 1, 1: PRINT result$
DO
LOOP UNTIL INKEY$ <> ""
END SUB

DEFSNG A-Z
SUB InitLib
  '
  ' BlastCopy! (BLSTCOPY.ASM)
  '
  code$ = "1E5589E58B460E8ED88B760C8B460A8EC08B7E08B9007DF3A55D1FCA0800"
  '
  DEF SEG = VARSEG(code1%(0))
  '
  FOR I% = 0 TO 29
    d% = VAL("&h" + MID$(code$, I% * 2 + 1, 2))
    POKE VARPTR(code1%(0)) + I%, d%
  NEXT I%
  '
  DEF SEG
  '
  ' BlastPset! (BLSTPSET.ASM)
  '
  code$ = "1E5589E58B46108ED88B760AB106D3E689F3B102D3E601DE8B5E0C01DE8B5E0E01DE8A460888045D1FCA0A00"
  '
  DEF SEG = VARSEG(code2%(0))
  '
  FOR I% = 0 TO 43
    d% = VAL("&h" + MID$(code$, I% * 2 + 1, 2))
    POKE VARPTR(code2%(0)) + I%, d%
  NEXT I%
  '
  DEF SEG
  '
  ' BlastPut! (BLASTPUT.ASM)
  '
  code$ = "1E5589E58B460C508B460A508B46108ED88B760E8B04B103D3E8508B5EFE"
  code$ = code$ + "01C3895EFE8B4402508B5EFC01C3895EFC83C60489760E89E58B46188ED8"
  code$ = code$ + "8B76168A04468976163A4610743DBB0000395E147C35395E127C30BB3F01"
  code$ = code$ + "395E147F28BBC700395E127F208B5E1C8EDB8B7612B106D3E689F3B102"
  code$ = code$ + "D3E601DE8B5E1401DE8B5E1A01DE88048B4614408946148B460639461475"
  code$ = code$ + "A18B46142B46028946148B4612408946128B46043946127589585858585D"
  code$ = code$ + "1FCA0E00"
  '
  DEF SEG = VARSEG(code3%(0))
  '
  FOR I% = 0 TO 182
    d% = VAL("&h" + MID$(code$, I% * 2 + 1, 2))
    POKE VARPTR(code3%(0)) + I%, d%
  NEXT I%
  '
  DEF SEG
  '
  ' BlastGet! (BLASTGET.ASM)
  '
  code$ = "1E5589E58B460A508B4608508B460A2B460E40508B46082B460C40508B46128ED8"
  code$ = code$ + "8B76108B46FABB0800F7E3890446468B46F88904464689761089E58B5E"
  code$ = code$ + "1E8EDB8B7614B106D3E689F3B102D3E601DE8B5E1601DE8B5E1C01DE8A"
  code$ = code$ + "048B5E1A8EDB8B76188804468976188B4616408946168B460639461676"
  code$ = code$ + "C38B46162B46028946168B4614408946148B460439461476AB58585858"
  code$ = code$ + "5D1FCA1000"
  '
  DEF SEG = VARSEG(code4%(0))
  '
  FOR I% = 0 TO 153
    d% = VAL("&h" + MID$(code$, I% * 2 + 1, 2))
    POKE VARPTR(code4%(0)) + I%, d%
  NEXT I%
  '
  DEF SEG
  '
  ' BlastCLS! (BLASTCLS.ASM)
  '
  code$ = "1E5589E58B460C8ED88B760A8B460888C4B900FA890483C60283E90275F65D1FCA0600"
  '
  DEF SEG = VARSEG(code6%(0))
  '
  FOR I% = 0 TO 34
    d% = VAL("&h" + MID$(code$, I% * 2 + 1, 2))
    POKE VARPTR(code6%(0)) + I%, d%
  NEXT I%
  '
  DEF SEG
  '
  ' BlastPoint! (BLASTPNT.ASM)
  '
  code$ = "1E5589E58B46128ED88B760CB106D3E689F3B102D3E601DE8B5E0C01DE8B5E100"
  code$ = code$ + "1DE8A1C8B460A8ED88B7608881C5D1FCA0C00"
  '
  DEF SEG = VARSEG(code7%(0))
  '
  FOR I% = 0 TO 50
    d% = VAL("&h" + MID$(code$, I% * 2 + 1, 2))
    POKE VARPTR(code7%(0)) + I%, d%
  NEXT I%
  '
  DEF SEG
  '
  ' BlastLine! (BLSTLINE.ASM)
  '
  code$ = "1E5589E58B460C2B4610508B460A2B460E50B8010050B840015089E58B46188B5E1439"
  code$ = code$ + "D87E168B4602BBFFFFF7E38946028B4606BBFFFFF7E38946068B46168B5E"
  code$ = code$ + "1239D87E168B4600BBFFFFF7E38946008B4604BBFFFFF7E38946048B46"
  code$ = code$ + "1C8ED88B7616B106D3E689F3B102D3E601DE8B5E1801DE8B5E1A01DE"
  code$ = code$ + "8B46068B5E0439D87E2FBB000089C13D00007F07B9FFFFF7E189C18A46"
  code$ = code$ + "108804037602035E043B5E067C060376002B5E064983F9007DE4EB32B8"
  code$ = code$ + "000089D983FB007F0C89D8B9FFFFF7E189C1B800008A5E10881C037600"
  code$ = code$ + "0346063B46047C060376022B46044983F9007DE4585858585D1FCA0E00"
  '
  DEF SEG = VARSEG(code8%(0))
  '
  FOR I% = 0 TO 237
    d% = VAL("&h" + MID$(code$, I% * 2 + 1, 2))
    POKE VARPTR(code8%(0)) + I%, d%
  NEXT I%
  '
  DEF SEG
  '
  ' BlastScroll! (BLSTSCRL.ASM)
  '
  code$ = "1E5589E58B46108ED88B760E8B460C8EC08B7E0A8B4E08F3A45D1FCA0A00"
  '
  DEF SEG = VARSEG(code9%(0))
  '
  FOR I% = 0 TO 29
    d% = VAL("&h" + MID$(code$, I% * 2 + 1, 2))
    POKE VARPTR(code9%(0)) + I%, d%
  NEXT I%
  '
  DEF SEG
  '
END SUB

SUB InputSource (InputSrc%, GetSrc%)
OUT BasePort% + 4, &HC
IF GetSrc% THEN
   InputSrc% = INP(BasePort% + 5) AND 2 + INP(BasePort% + 5) AND 4
ELSE
   OUT BasePort% + 5, InputSrc% AND 7
END IF
END SUB

SUB LoadAndPlayLarge (Filename$) STATIC
'See if an extension was supplied, and if not, add one.
IF INSTR(Filename$, ".") = 0 THEN Filename$ = Filename$ + ".MID"
'The sound driver needs an ASCIIZ string (a string that ends with
'character 0) for a file name.
IF RIGHT$(Filename$, 1) <> CHR$(0) THEN Filename$ = Filename$ + CHR$(0)
'Initialize the MIDI driver and load the file in memory
IF LoadCodeLoaded% = 0 THEN
        Lasm$ = ""
        Lasm$ = Lasm$ + CHR$(&H55)
        Lasm$ = Lasm$ + CHR$(&H89) + CHR$(&HE5)
        Lasm$ = Lasm$ + CHR$(&H8B) + CHR$(&H5E) + CHR$(&H8)
        Lasm$ = Lasm$ + CHR$(&H8B) + CHR$(&H7)
        Lasm$ = Lasm$ + CHR$(&H8B) + CHR$(&H5E) + CHR$(&H6)
        Lasm$ = Lasm$ + CHR$(&H8B) + CHR$(&H17)
        Lasm$ = Lasm$ + CHR$(&HBB) + CHR$(&H0) + CHR$(&H5)
        Lasm$ = Lasm$ + CHR$(&HCD) + CHR$(&H81)
        Lasm$ = Lasm$ + CHR$(&H5D)
        Lasm$ = Lasm$ + CHR$(&HCB)
        LoadCodeLoaded% = 1
END IF
DEF SEG = VARSEG(Lasm$)
Offset% = SADD(Lasm$)
CALL ABSOLUTE(SADD(Filename$), VARSEG(Filename$), Offset%)

'Start the music!!
IF PlayCodeLoaded% = 0 THEN
        Pasm$ = ""
        Pasm$ = Pasm$ + CHR$(&HB8) + CHR$(&H1) + CHR$(&H0)
        Pasm$ = Pasm$ + CHR$(&HBA) + CHR$(&H1) + CHR$(&H0)
        Pasm$ = Pasm$ + CHR$(&HBB) + CHR$(&H1) + CHR$(&H5)
        Pasm$ = Pasm$ + CHR$(&HCD) + CHR$(&H81)
        Pasm$ = Pasm$ + CHR$(&HCB)
        PlayCodeLoaded% = 1
END IF
DEF SEG = VARSEG(Pasm$)
Offset% = SADD(Pasm$)
CALL ABSOLUTE(Offset%)
MIDI.ERROR = 0
MIDI.LOADED = 1
MIDI.PLAYTIME = TIMER
END SUB

'LoadAndPlayMIDI - Loads a MIDI file into memory and plays it
SUB LoadAndPlayMIDI (Filename$, MIDISegment%, MIDIOffset%)
'See if an extension was supplied, and if not, add one.
IF INSTR(Filename$, ".") = 0 THEN Filename$ = Filename$ + ".MID"
'Open the file
FF% = FREEFILE
OPEN Filename$ FOR BINARY AS #FF%
FileLen& = LOF(FF%)
CLOSE #FF%
'If the file is empty, delete it and exit now.
IF FileLen& = 0 THEN KILL Filename$: MIDI.ERROR = 1: EXIT SUB
'If the file is too large, exit now.
IF FileLen& > 65536 THEN MIDI.ERROR = 2: EXIT SUB
'Make the filename an ASCIIZ string.
Filename$ = Filename$ + CHR$(0)
'Check if the MIDI loading code has already been loaded;
'if not, do it now.
IF LoadCodeLoaded% = 0 THEN
        asm1$ = asm1$ + CHR$(&H1E)
        asm1$ = asm1$ + CHR$(&H55)
        asm1$ = asm1$ + CHR$(&H89) + CHR$(&HE5)
        asm1$ = asm1$ + CHR$(&HB8) + CHR$(&H0) + CHR$(&H3D)
        asm1$ = asm1$ + CHR$(&H8B) + CHR$(&H5E) + CHR$(&HE)
        asm1$ = asm1$ + CHR$(&H8B) + CHR$(&H17)
        asm1$ = asm1$ + CHR$(&H8B) + CHR$(&H5E) + CHR$(&H10)
        asm1$ = asm1$ + CHR$(&H8E) + CHR$(&H1F)
        asm1$ = asm1$ + CHR$(&HCD) + CHR$(&H21)
        asm1$ = asm1$ + CHR$(&H89) + CHR$(&HC6)
        asm1$ = asm1$ + CHR$(&HB4) + CHR$(&H3F)
        asm1$ = asm1$ + CHR$(&H8B) + CHR$(&H5E) + CHR$(&H8)
        asm1$ = asm1$ + CHR$(&H8B) + CHR$(&HF)
        asm1$ = asm1$ + CHR$(&H8B) + CHR$(&H5E) + CHR$(&HA)
        asm1$ = asm1$ + CHR$(&H8B) + CHR$(&H17)
        asm1$ = asm1$ + CHR$(&H8B) + CHR$(&H5E) + CHR$(&HC)
        asm1$ = asm1$ + CHR$(&H8E) + CHR$(&H1F)
        asm1$ = asm1$ + CHR$(&H89) + CHR$(&HF3)
        asm1$ = asm1$ + CHR$(&HCD) + CHR$(&H21)
        asm1$ = asm1$ + CHR$(&HB4) + CHR$(&H3E)
        asm1$ = asm1$ + CHR$(&HCD) + CHR$(&H21)
        asm1$ = asm1$ + CHR$(&H5D)
        asm1$ = asm1$ + CHR$(&H1F)
        asm1$ = asm1$ + CHR$(&HCA) + CHR$(&HA) + CHR$(&H0)
        LoadCodeLoaded% = 1
END IF
'Call the assembly language routine.
DEF SEG = VARSEG(asm1$)
CALL ABSOLUTE(VARSEG(Filename$), SADD(Filename$), MIDISegment%, MIDIOffset%, &HFFFF, SADD(asm1$))
MIDI.ERROR = 0
'Check to see if the MIDI playing code has previously been loaded.
'If not, load it now.
IF PlayCodeLoaded% = 0 THEN
        'Load the machine codes into a string.
        asm2$ = asm2$ + CHR$(&H55)
        asm2$ = asm2$ + CHR$(&H89) + CHR$(&HE5)
        asm2$ = asm2$ + CHR$(&H8B) + CHR$(&H5E) + CHR$(&H8)
        asm2$ = asm2$ + CHR$(&H8B) + CHR$(&H17)
        asm2$ = asm2$ + CHR$(&H8B) + CHR$(&H5E) + CHR$(&H6)
        asm2$ = asm2$ + CHR$(&H8B) + CHR$(&H7)
        asm2$ = asm2$ + CHR$(&HBB) + CHR$(&H4) + CHR$(&H0)
        asm2$ = asm2$ + CHR$(&HCD) + CHR$(&H80)
        asm2$ = asm2$ + CHR$(&HBB) + CHR$(&H5) + CHR$(&H0)
        asm2$ = asm2$ + CHR$(&HCD) + CHR$(&H80)
        asm2$ = asm2$ + CHR$(&H5D)
        asm2$ = asm2$ + CHR$(&HCA) + CHR$(&H4) + CHR$(&H0)
        'Indicate that the code has been loaded.
        PlayCodeLoaded% = 1
END IF
'Call the machine language routine to play the music.
DEF SEG = VARSEG(asm2$)
CALL ABSOLUTE(MIDISegment%, MIDIOffset%, SADD(asm2$))
'Start the MIDI timer.
MIDI.PLAYTIME = TIMER
END SUB

DEFINT A-Z
SUB loadbmp (data$)
CLS
IF LTRIM$(RTRIM$(data$)) = "" THEN END
CLOSE #1
OPEN data$ FOR BINARY AS #1
IF LOF(1) = 0 THEN PRINT "File not found!": CLOSE : KILL data$: END

table$ = INPUT$(54, #1)
DIM table&(30)
DEF SEG = VARSEG(table&(1))
pointer% = VARPTR(table&(1))

FOR bmpX% = 0 TO 51
 POKE pointer% + bmpX%, ASC(MID$(table$, bmpX% + 3, 1))
NEXT
DEF SEG

IF MID$(table$, 1, 2) <> "BM" OR table&(4) <> 40 THEN
   PRINT "Not a valid *.BMP file!": END
END IF
IF table&(8) <> 0 THEN
   PRINT "This program will not diplay RLE encoded files": END
END IF

CLS
CALL allblack
'IF (table&(5) < 321) AND (table&(6) < 201) THEN
'   SCREEN 13
'ELSE
'   SCREEN 12
'END IF

'LOCATE 2, 1
'PRINT " Loading images, please wait."

thecolors$ = INPUT$(table&(3) - 54, #1)

DEF SEG = VARSEG(pal&)
pointer% = VARPTR(pal&)



FOR bmpX% = 0 TO 63 STEP 4
 POKE pointer%, (ASC(MID$(thecolors$, bmpX% + 3, 1))) \ 4
 POKE pointer% + 1, (ASC(MID$(thecolors$, bmpX% + 2, 1))) \ 4
 POKE pointer% + 2, (ASC(MID$(thecolors$, bmpX% + 1, 1))) \ 4
 POKE pointer% + 3, 0
'PALETTE bmpX% \ 4, pal&
NEXT
DEF SEG

bmpY% = table&(6) 'Put number of vertical pixels into bmpY%
DO
  data$ = INPUT$((((table&(5) - 1) OR 7) + 1) \ 2, #1)
    IF (table&(5) \ 2) < LEN(data$) THEN
       linelength% = table&(5) \ 2
    ELSE
      linelength% = LEN(data$)
    END IF
    FOR bmpX% = 1 TO linelength%
      pixel% = ASC(MID$(data$, bmpX%, 1))
      PSET (bmpX% * 2 + 1, bmpY%), pixel% AND 15
      PSET (bmpX% * 2, bmpY%), pixel% \ 16
     NEXT
    bmpY% = bmpY% - 1
LOOP UNTIL EOF(1)

FOR bmpX% = 0 TO 63 STEP 4
 POKE pointer%, (ASC(MID$(thecolors$, bmpX% + 3, 1))) \ 4
 POKE pointer% + 1, (ASC(MID$(thecolors$, bmpX% + 2, 1))) \ 4
 POKE pointer% + 2, (ASC(MID$(thecolors$, bmpX% + 1, 1))) \ 4
 POKE pointer% + 3, 0
PALETTE bmpX% \ 4, pal&
NEXT

END SUB

DEFSNG A-Z
SUB LoadLarge (Filename$) STATIC
'See if an extension was supplied, and if not, add one.
IF INSTR(Filename$, ".") = 0 THEN Filename$ = Filename$ + ".MID"
'The sound driver needs an ASCIIZ string (a string that ends with
'character 0) for a file name.
IF RIGHT$(Filename$, 1) <> CHR$(0) THEN Filename$ = Filename$ + CHR$(0)
'Initialize the MIDI driver and load the file in memory
IF CodeLoaded% = 0 THEN
        asm$ = ""
        asm$ = asm$ + CHR$(&H55)
        asm$ = asm$ + CHR$(&H89) + CHR$(&HE5)
        asm$ = asm$ + CHR$(&H8B) + CHR$(&H5E) + CHR$(&H8)
        asm$ = asm$ + CHR$(&H8B) + CHR$(&H7)
        asm$ = asm$ + CHR$(&H8B) + CHR$(&H5E) + CHR$(&H6)
        asm$ = asm$ + CHR$(&H8B) + CHR$(&H17)
        asm$ = asm$ + CHR$(&HBB) + CHR$(&H0) + CHR$(&H5)
        asm$ = asm$ + CHR$(&HCD) + CHR$(&H81)
        asm$ = asm$ + CHR$(&H5D)
        asm$ = asm$ + CHR$(&HCB)
        CodeLoaded% = 1
END IF
DEF SEG = VARSEG(asm$)
Offset% = SADD(asm$)
CALL ABSOLUTE(SADD(Filename$), VARSEG(Filename$), Offset%)
MIDI.ERROR = 0
MIDI.LOADED = 1
END SUB

'LoadMIDI - loads a MIDI file into memory
SUB LoadMIDI (Filename$, MIDISegment%, MIDIOffset%) STATIC
'See if an extension was supplied, and if not, add one.%)
CLOSE #FF%
'If the file is empty, delete it and exit now.
IF FileLen& = 0 THEN KILL Filename$: MIDI.ERROR = 1: EXIT SUB
'If the file is too large, exit now.
IF FileLen& > 65536 THEN MIDI.ERROR = 2: EXIT SUB
'Make the filename an ASCIIZ string.
Filename$ = Filename$ + CHR$(0)
'Check if the assembly language code has already been loaded;
'if not, do it now.
IF CodeLoaded% = 0 THEN
        asm$ = asm$ + CHR$(&H1E)
        asm$ = asm$ + CHR$(&H55)
        asm$ = asm$ + CHR$(&H89) + CHR$(&HE5)
        asm$ = asm$ + CHR$(&HB8) + CHR$(&H0) + CHR$(&H3D)
        asm$ = asm$ + CHR$(&H8B) + CHR$(&H5E) + CHR$(&HE)
        asm$ = asm$ + CHR$(&H8B) + CHR$(&H17)
        asm$ = asm$ + CHR$(&H8B) + CHR$(&H5E) + CHR$(&H10)
        asm$ = asm$ + CHR$(&H8E) + CHR$(&H1F)
        asm$ = asm$ + CHR$(&HCD) + CHR$(&H21)
        asm$ = asm$ + CHR$(&H89) + CHR$(&HC6)
        asm$ = asm$ + CHR$(&HB4) + CHR$(&H3F)
        asm$ = asm$ + CHR$(&H8B) + CHR$(&H5E) + CHR$(&H8)
        asm$ = asm$ + CHR$(&H8B) + CHR$(&HF)
        asm$ = asm$ + CHR$(&H8B) + CHR$(&H5E) + CHR$(&HA)
        asm$ = asm$ + CHR$(&H8B) + CHR$(&H17)
        asm$ = asm$ + CHR$(&H8B) + CHR$(&H5E) + CHR$(&HC)
        asm$ = asm$ + CHR$(&H8E) + CHR$(&H1F)
        asm$ = asm$ + CHR$(&H89) + CHR$(&HF3)
        asm$ = asm$ + CHR$(&HCD) + CHR$(&H21)
        asm$ = asm$ + CHR$(&HB4) + CHR$(&H3E)
        asm$ = asm$ + CHR$(&HCD) + CHR$(&H21)
        asm$ = asm$ + CHR$(&H5D)
        asm$ = asm$ + CHR$(&H1F)
        asm$ = asm$ + CHR$(&HCA) + CHR$(&HA) + CHR$(&H0)
        CodeLoaded% = 1
END IF
'Call the assembly language routine.
DEF SEG = VARSEG(asm$)
CALL ABSOLUTE(VARSEG(Filename$), SADD(Filename$), MIDISegment%, MIDIOffset%, &HFFFF, SADD(asm$))
MIDI.ERROR = 0
END SUB

SUB menu
SCREEN 12
CALL loadbmp("SNDATAb.DAT")
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
'CALL fadein
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

start! = TIMER + .002
reetime:
finish! = TIMER   'VAL(fin$)
IF finish! < start! THEN GOTO reetime

LOOP

choiced:
SELECT CASE sel
    CASE 1
    CALL fadeout
    CASE 2
    CALL about
    CALL fadeout
    CALL menu
    CASE 3
    CALL fadeout
    CLS
    CALL endst
    END
END SELECT

END SUB

FUNCTION MIDIError$
SELECT CASE MIDI.ERROR
        CASE 0: MIDIError$ = "NO ERROR"
        CASE 1: MIDIError$ = "FILE CONTAINS NO DATA"
        CASE 2: MIDIError$ = "FILE IS TOO LARGE"
        CASE 3: MIDIError$ = "NO MIDI FILE PLAYING"
        CASE ELSE: MIDIError$ = "UNKNOWN ERROR"
END SELECT
END FUNCTION

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

DEFSNG A-Z
SUB PlayLarge STATIC
'If no MIDI file is loaded, exit now
IF MIDI.LOADED = 0 THEN EXIT SUB
'Start the music!!
IF CodeLoaded% = 0 THEN
        asm$ = ""
        asm$ = asm$ + CHR$(&HB8) + CHR$(&H1) + CHR$(&H0)
        asm$ = asm$ + CHR$(&HBA) + CHR$(&H1) + CHR$(&H0)
        asm$ = asm$ + CHR$(&HBB) + CHR$(&H1) + CHR$(&H5)
        asm$ = asm$ + CHR$(&HCD) + CHR$(&H81)
        asm$ = asm$ + CHR$(&HCB)
        CodeLoaded% = 1
END IF
DEF SEG = VARSEG(asm$)
Offset% = SADD(asm$)
CALL ABSOLUTE(Offset%)
MIDI.PLAYTIME = TIMER
MIDI.ERROR = 0
MIDI.PLAYTIME = TIMER
END SUB

'PlayMIDI - Begins playing a MIDI file in the background.
SUB PlayMIDI (MIDISegment%, MIDIOffset%) STATIC
'Check to see if the MIDI playing code has previously been loaded.
'If not, load it now.
IF CodeLoaded% = 0 THEN
        'Load the machine codes into a string.
        asm$ = asm$ + CHR$(&H55)
        asm$ = asm$ + CHR$(&H89) + CHR$(&HE5)
        asm$ = asm$ + CHR$(&H8B) + CHR$(&H5E) + CHR$(&H8)
        asm$ = asm$ + CHR$(&H8B) + CHR$(&H17)
        asm$ = asm$ + CHR$(&H8B) + CHR$(&H5E) + CHR$(&H6)
        asm$ = asm$ + CHR$(&H8B) + CHR$(&H7)
        asm$ = asm$ + CHR$(&HBB) + CHR$(&H4) + CHR$(&H0)
        asm$ = asm$ + CHR$(&HCD) + CHR$(&H80)
        asm$ = asm$ + CHR$(&HBB) + CHR$(&H5) + CHR$(&H0)
        asm$ = asm$ + CHR$(&HCD) + CHR$(&H80)
        asm$ = asm$ + CHR$(&H5D)
        asm$ = asm$ + CHR$(&HCA) + CHR$(&H4) + CHR$(&H0)
        'Indicate that the code has been loaded.
        CodeLoaded% = 1
END IF
'Call the machine language routine to play the music.
DEF SEG = VARSEG(asm$)
Offset% = SADD(asm$)
CALL ABSOLUTE(MIDISegment%, MIDIOffset%, Offset%)
'Start the MIDI timer.
MIDI.PLAYTIME = TIMER
MIDI.ERROR = 0
END SUB

'StopMIDI - Stops playing MIDI file
SUB stopmidi
'Stop the music!!
asm$ = asm$ + CHR$(&HBB) + CHR$(&H4) + CHR$(&H0)
asm$ = asm$ + CHR$(&HCD) + CHR$(&H80)
asm$ = asm$ + CHR$(&HCB)
'These next commented lines are for using the converted code.
DEF SEG = VARSEG(asm$)
Offset% = SADD(asm$)
CALL ABSOLUTE(Offset%)
'No MIDI file is playing, so reset the timer
MIDI.PLAYTIME = 0
MIDI.ERROR = 0
END SUB

FUNCTION TimeMIDI!
'If a MIDI file is playing, carry out the timing routine
IF MIDI.PLAYTIME THEN
'Get the current time
CurrentTime! = TIMER
'If midnight has come since the MIDI file started playing, change
'CurrentTime! accordingly
IF CurrentTime! - MIDI.PLAYTIME < 0 THEN
CurrentTime! = 86400 + CurrentTime!
END IF
'Get the final result
TimeMIDI! = CurrentTime! - MIDI.PLAYTIME
MIDI.ERROR = 0
ELSE
MIDI.ERROR = 3
END IF
END FUNCTION

DEFINT A-Z
SUB Zoom (x) STATIC
   WINDOW (-x, -x)-(x, x)
    'D
    LINE (-135, 100)-(-210, 100), 72
    LINE (-135, 100)-(-135, -100), 72
    LINE (-135, -100)-(-210, -100), 72
    LINE (-200, 100)-(-200, -100), 72
   
    'A
    LINE (-50, 100)-(25, 100), 72
    LINE (-50, 100)-(-50, -100), 72
    LINE (-50, 0)-(25, 0), 72
    LINE (25, -100)-(25, 100), 72
    'N
    LINE (105, 100)-(180, -100), 72
    LINE (180, 100)-(180, -100), 72
    
    LINE (105, 100)-(105, -100), 72

END SUB

