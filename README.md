# Snoopy Tennis

**A QBasic game archive, with an HTML5 restoration you can play today.**

This repository preserves Daniel Downes's (formerly Daniel
Vincent) Snoopy Tennis: the original BASIC source, the packaged DOS release and
its Visual Basic launcher, plus a browser port that reuses the original artwork.
It is also a look at how a small game could combine BASIC, hand-tuned animation,
VGA palette tricks and embedded 8086 machine code.

![Original Snoopy Tennis title](html5/assets/title.png)

**[Play in your browser — GitHub Pages](https://danieldownes.github.io/SnoopyTennis/)**

The Pages link is prepared for this repository. It becomes live after the owner
enables **Settings → Pages → Deploy from a branch → main → /(root)**. There is
no build service or server component to configure; the root entry page opens
the bundled game.

## What's here

| Path | Contents |
| --- | --- |
| [`ST_src/`](ST_src/) | Original `STennis.BAS`, menu prototype, art experiments, MIDI and sound files. |
| [`SnoopyTennis_v2-1/`](SnoopyTennis_v2-1/) | Packaged v2.1 DOS game, drivers, installer, original README and VB launcher source. |
| [`html5/`](html5/) | Editable browser port, asset recovery tools, MIDI sampler and tests. |
| [`SnoopyTennis.html`](SnoopyTennis.html) | Self-contained browser game: open it directly, with no installation. |
| [`archive/file-dates.csv`](archive/file-dates.csv) | Original file timestamps, SHA-256 hashes and the corresponding import commits. |

The two archive folders are preserved byte for byte. The source is an earlier
snapshot than the packaged v2.1 executable, so the source and release should not
be assumed to be identical builds. The source's farewell screen identifies
itself as `v2.00.10`.

## Playing the restoration

You are Snoopy. Climb between five positions in the tree and time your swing to
return Charlie Brown's tennis balls. Normal returns earn **2 points**. Lucy can
send a ball back faster; return it for **3 points**. Three misses end the game.

| Action | Keys |
| --- | --- |
| Choose a menu item | Up / Down, then Enter |
| Climb | Up / Down, or P / L |
| Swing | Space |
| Pause / resume | Esc |
| End the current game | Q |

Mouse and touch controls are included. The original black **Start Game /
About/Help / Exit** menu is restored, including the upward-scrolling instructions
and credits. Any key or a tap dismisses the scroll; Pause lets you stop and read.
Original graphics are implemented. HD remains a future renderer.

## Inside the QBasic code

This tour focuses on the game-specific logic and presentation in the preserved
source. The `qbasic` fences use GitHub's QuickBASIC syntax highlighting. Some
examples omit unrelated lines; their links lead to the full routines.

The file also contains borrowed library code: **Jesse Dorland's Qmidi** provides
background MIDI playback and its elapsed-time helper, and **Andrew Ayers's Blast**
provides the assembly graphics routines. Those systems are credited to their
respective authors; the examples below focus on the game, menu and screen effects.
The MIDI integration is described separately in the [MIDI investigation](html5/MIDI-REVIEW.md).

### Timing a frame with `TIMER` and a label

[Game-loop timing](ST_src/STennis.BAS#L479-L482):

```qbasic
start! = TIMER + .09
retime:
finish! = TIMER   'VAL(fin$)
IF finish! < start! THEN GOTO retime
```

`TIMER` measures seconds since midnight. The game sets a deadline about 90 ms
ahead and polls until it passes. This is a busy wait: drawing, ball updates and
input handling happen outside it. The actual frame period includes that work,
so it is not a guaranteed 90 ms fixed timestep. The HTML5 port keeps the intended
pace with a fixed simulation tick and a separate browser rendering loop.

### Reusing inactive ball slots

[Ball records and serving](ST_src/STennis.BAS#L267-L295):

```qbasic
TYPE ballt
 x AS INTEGER
 y AS INTEGER
 balltype AS INTEGER
 n AS INTEGER
END TYPE
DIM SHARED ball(40) AS ballt
```

Each ball carries its own position, path type and age. Before growing the used
part of the array, the serve routine looks for an inactive slot (`balltype = 0`):

```qbasic
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
```

An incoming ball is reset to x=10, y=160, age zero, with one of five random path
types. `balls` tracks the allocated slot range; `bio` separately tracks balls
still in play. This makes reuse possible without shifting the remaining balls
around in the fixed-size array. The original has no explicit capacity guard;
the browser port adds one.

### Varying the pressure using elapsed ticks and balls in play

[Serve scheduling](ST_src/STennis.BAS#L297-L313):

```qbasic
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
```

Difficulty follows the global tick count `n`, rather than the score. A serve
check is gated by Charlie Brown's animation (`cwing`) and a deadline (`lastn`).
Some time bands force a serve if the active-ball count is low, while others add
random serves. The changing thresholds, population checks and cooldown work
together; it is more than a single speed value being increased every level.
The random tests run when this gate is eligible, not on every displayed frame.

### A three-state swing with a recovery period

[Swing animation](ST_src/STennis.BAS#L332-L335):

```qbasic
IF swing = 1 THEN swingtime = swingtime + 1
IF swing = 2 THEN swingtime1 = swingtime1 + 1
IF swingtime > 3 THEN swing = 2: swingtime = 0
IF swingtime1 > 2 THEN swing = 0: swingtime1 = 0
```

`swing = 0` means idle, `1` is the active hitting pose, and `2` is the
follow-through. Separate counters advance the two animated phases. The Space
handler starts a swing only while idle:

```qbasic
    CASE " "
    IF swing <> 0 THEN GOTO getout
    swing = 1
```

A key press cannot continually restart the hitting pose. That gives the racket
an active window and a recovery period, using just three states and two tick
counters. The hit test below accepts only state 1.

### Encoding the rally state in the ball's path number

[Normal return and score](ST_src/STennis.BAS#L407-L415):

```qbasic
IF ball(nn).x > 225 AND ball(nn).x < 249 AND ball(nn).balltype <= 5 AND ball(nn).balltype = stage AND swing = 1 THEN
    ball(nn).balltype = ball(nn).balltype + 10
    ball(nn).n = 0
    
    score = score + 2

    IF n < 300 AND cwing = 0 THEN tyi = 1: GOTO serve
    IF n > 301 AND n < 600 AND cwing = 0 THEN IF INT(RND * 100) + 1 < 50 THEN GOTO serve
END IF
```

[Lucy's faster return](ST_src/STennis.BAS#L417-L424), with an unused commented
serve rule omitted:

```qbasic
IF ball(nn).x > 225 AND ball(nn).x < 249 AND ball(nn).balltype > 20 AND ball(nn).balltype = stage + 20 AND swing = 1 THEN
    ball(nn).balltype = ball(nn).balltype - 10
    ball(nn).n = 0
   
    score = score + 3
END IF
```

The type number does two jobs: 1–5 identifies incoming serve paths, 11–15 is
Snoopy's outgoing return, and 21–25 is a faster ball sent back by Lucy. Adding or
subtracting ten switches the path family while retaining the corresponding tree
position. Normal returns earn two points; the faster return earns three.

The hit test combines a strict x window (225 < x < 249), the selected stage and
the active swing pose. Snoopy moves between just five y positions—155, 110, 80,
40 and 5—so matching a path number to a stage avoids a general collision engine.

### Lucy's return changes the route without creating another ball

[Lucy interception](ST_src/STennis.BAS#L445-L449):

```qbasic
'Return from Lucy?
 IF ball(nn).x < 54 AND ball(nn).balltype > 10 AND lret = 1 THEN
  ball(nn).balltype = ball(nn).balltype + 10
  lret = 0
 END IF
```

`lret` arms one interception. When an outgoing ball reaches Lucy's side, the
same record changes to its fast-return path and the flag clears. The code does
not reset the ball's age `n` here, unlike Snoopy's hit. The new movement formula
therefore picks up that existing age: a small detail that changes the feel of
Lucy's return and is retained in the port.

### Fading a whole screen by editing its palette

[Palette fade-out](ST_src/STennis.BAS#L831-L851), inner loop:

```qbasic
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
```

Pixels store palette indices. Reducing the palette's RGB values darkens every
pixel using those entries without repainting the image. The final `WAIT` polls
the VGA display status for vertical retrace. The menu uses a related technique:
draw each option once in its own palette colour, then brighten or dim that
colour as the selection changes.

### Turning the built-in font into dotted display lettering

[The `neatfont` routine](ST_src/STennis.BAS#L1375-L1409), selected lines:

```qbasic
COLOR 8: LOCATE 1, 1: PRINT txt$
FOR y% = 0 TO 15
  FOR x% = 0 TO l%
  IF POINT(x%, y%) <> 0 THEN
   IF sty% = 3 THEN CIRCLE (sx2% - (size% / 2), sy% - (size% / 2)), size% / 2, clr%
   ' Other drawing styles omitted from this excerpt.
  END IF
  sx2% = sx2% + size%
  NEXT x%
  sy% = sy% + size%: sx2% = sx%
NEXT y%
```

Instead of shipping a large font, the program first prints the normal BIOS
letters, inspects their pixels with `POINT`, and replaces each lit pixel with a
larger shape. Style 3 draws small outlined circles: those are the dotted grey
menu letters. Other styles use filled circles, boxes, diagonal lines or triangles.
The original printed text is erased afterward.

### Scrolling credits by copying scanlines

[Original About/Help](ST_src/STennis.BAS#L523-L545), excerpt:

```qbasic
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
```

Each pass copies screen rows upward by two pixels. After the first insertion,
one new text line arrives every eight passes: 16 pixels of movement for a
16-pixel text row. It starts with the menu still visible, so the menu itself
scrolls away before the instructions and credits. There is no separate text
scroller or graphics asset for the credits.

### Hand-tuned flight paths and a five-position hit test

[Ball movement](ST_src/STennis.BAS#L358-L402), two of the serve cases:

```qbasic
       CASE 3
ball(nn).x = ball(nn).x + 6
ball(nn).y = ball(nn).y - 4 + ((ball(nn).n * ball(nn).n) / 250)
       CASE 4
ball(nn).x = ball(nn).x + 6
ball(nn).y = ball(nn).y - 4 + ((ball(nn).n * ball(nn).n) / 500)
```

`n` is the ball's age in ticks. These are hand-tuned integer update rules;
the squared term is added to the *per-frame displacement*, rather than defining
the ball's absolute height. Changing the divisor creates different routes to
the tree. The original stores the coordinates as `INTEGER`, so rounding is part
of the movement. The original credits name Andrew Bellchambers for the
gravity-formula contribution.

A return then requires the ball to enter a narrow x window, its path type to
match Snoopy's selected stage, and the swing to be in its active pose. The game
does not need a general collision engine to make its five-position design work.

## Reconstructed archive history

The first **54 commits import one archived file each**. Most use the preserved
last-modified time for both the author and committer dates. Four bundled Creative
support files—`Sbsim.com`, `Sbsim.cfg`, `Sbmidi.exe` and `CTMIDI.DRV`—instead use
**3 November 2026**, the actual archive-import date. Their 1979, 1980, 1993 and
1994 file timestamps describe support-file metadata, not this game's development.
Subsequent current-date commits add the browser restoration and documentation.

These are reconstructed **import commits**, not recovered development commits.
Only one surviving snapshot of each file was supplied. Original timestamps can
be misleading: the old support-file dates remain recorded only as original
metadata, while their Git import dates use the archive-import date. Some later
packaging files carry 2014 dates. None of these values is presented as a date
when the game itself was written.

The first-party artwork and audio include 1999 dates. The surviving `MENU.BAS`
is dated **29 January 2000**, and `STennis.BAS` **30 June 2000**, using UTC dates.
They have not been artificially changed to 1999.

[`archive/file-dates.csv`](archive/file-dates.csv) records every path, size,
original timestamp, chosen Git timestamp, date policy, SHA-256 and import commit.
Git checkouts do not normally restore filesystem modification times; the manifest
retains the original values separately from the corrected import dates.

To verify the archive against the committed history:

```sh
python tools/verify_archive.py
```

## Building and checking the browser version

The checked-in game works without installing anything. For development, use a
recent Node.js release:

```sh
cd html5
node tools/serve.cjs
# Open http://127.0.0.1:4173
```

Regenerate the self-contained game and run its checks:

```sh
node tools/package.cjs
node --test tests/*.test.cjs
```

The public music uses **GeneralUser GS by S. Christian Collins**, with a compact
sample subset and its [upstream license](html5/assets/GENERALUSER-LICENSE.txt).
The MIDI score is unchanged. Locally extracted Windows GS samples and the local
Windows audio preview are excluded from this public repository. The optional
Windows-bank extraction tool remains available for local experiments.

See the [HTML5 development notes](html5/README.md), [source review](html5/REVIEW.md),
[MIDI investigation](html5/MIDI-REVIEW.md) and [sample provenance](html5/assets/GM-NOTICE.md).

## Credits and original notices

- **Daniel Downes**, formerly Daniel Vincent: game, menu, background and character modifications.
- **Andrew Ayers**: Blast graphics engine.
- **Jesse Dorland**: Qmidi background MIDI routines.
- **D. W. Barnes**: MIDI sequence.
- **Andrew Bellchambers**: gravity-formula contribution, as credited in the original.
- **S. Christian Collins**: GeneralUser GS bank used by the public browser build.
- **VileR's font collection**: preserved IBM VGA bitmap lettering used to restore the menu.

Original game © 2000–02 Ex-D Software Development. Peanuts characters and the
original Nintendo Game & Watch design retain their respective owners' rights.
The archive's original notices are kept in place. A blanket license is not
asserted over the archived third-party programs, characters, music or other media.
