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

The excerpts below come from the preserved source. The `qbasic` fences use
GitHub's QuickBASIC syntax highlighting. Some examples omit unrelated lines;
their links lead to the full routines.

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

### Background MIDI playback and a clock that crosses midnight

[Starting the music](ST_src/STennis.BAS#L131-L141):

```qbasic
DIM MIDI%(16000)
LoadAndPlayMIDI "peanuts.mid", VARSEG(MIDI%(0)), VARPTR(MIDI%(0))
```

The array reserves storage for the file. `VARSEG` and `VARPTR` pass a real-mode
segment and offset into the Qmidi routines. The musical events are scheduled by
Creative's resident MIDI driver; the game does not need to play each note in
its drawing loop.

[Calling the driver and starting the elapsed-time clock](ST_src/STennis.BAS#L1453-L1459):

```qbasic
DEF SEG = VARSEG(asm$)
Offset% = SADD(asm$)
CALL ABSOLUTE(MIDISegment%, MIDIOffset%, Offset%)
'Start the MIDI timer.
MIDI.PLAYTIME = TIMER
MIDI.ERROR = 0
```

The embedded machine-code string calls interrupt `80h`, using functions 4 and 5
to hand over the in-memory MIDI and start playback. The `MIDI.PLAYTIME` assignment
records when playback started; it does not drive the notes themselves.

[The complete elapsed-time function](ST_src/STennis.BAS#L1477-L1493):

```qbasic
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
```

Adding 86,400 seconds handles one midnight rollover. This protection is present
in the MIDI elapsed-time helper, while the short game-loop wait above has no
equivalent check. The helper is supplied by Qmidi; the main game starts the music
but does not use `TimeMIDI!` to synchronize ball movement.

**About recording:** the supplied code has background MIDI playback and playback
time measurement, but no gameplay recording/replay system or audio-recording
routine. The unused [`InputSource` routine](ST_src/STennis.BAS#L1004-L1011) reads
or selects a Sound Blaster mixer input; it does not capture or store audio. The
note sequence is already recorded in `peanuts.mid`. There is no replay timing
format to reconstruct from these source files.

### BASIC as a host for tiny assembly routines

[Blast initialization](ST_src/STennis.BAS#L877-L895), excerpt:

```qbasic
' BlastCopy! (BLSTCOPY.ASM)
code$ = "1E5589E58B460E8ED88B760C8B460A8EC08B7E08B9007DF3A55D1FCA0800"
DEF SEG = VARSEG(code1%(0))
FOR I% = 0 TO 29
  d% = VAL("&h" + MID$(code$, I% * 2 + 1, 2))
  POKE VARPTR(code1%(0)) + I%, d%
NEXT I%
DEF SEG
```

Andrew Ayers's Blast engine packs machine code into hexadecimal strings. BASIC
decodes those strings into reserved arrays with `POKE`; wrappers later execute
the bytes with `CALL ABSOLUTE`. This brings fast blitting into a program whose
game logic and menu are still ordinary BASIC.

The game also reserves two 64,000-byte buffers as arrays of 16-bit integers:

```qbasic
REDIM buffer1%(31999) ' This is an off-screen buffer
REDIM buffer2%(31999) ' This is another...
```

It copies the saved background to the working buffer, draws the actors there,
then presents the result at VGA memory segment `&HA000`. The presentation call
starts at `buffer1%(2)`, skipping the four-byte image header used by BASIC's
graphics array format. See [the main drawing loop](ST_src/STennis.BAS#L320-L472).

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
of the movement.

A return then requires the ball to enter a narrow x window, its path type to
match Snoopy's selected stage, and the swing to be in its active pose. The game
does not need a general collision engine to make its five-position design work.

## Reconstructed archive history

The first **54 commits import one archived file each**. Both the author date and
committer date match that file's preserved last-modified time, expressed in UTC.
The following current-date commit adds the browser restoration and documentation.

These are reconstructed **import commits**, not recovered development commits.
Only one surviving snapshot of each file was supplied. Original timestamps can
be misleading: the bundled SBSIM support files carry 1979/1980 dates, while some
packaging files carry 2014 dates. Those values are retained as metadata, not
presented as dates when Snoopy Tennis was written.

The first-party artwork and audio include 1999 dates. The surviving `MENU.BAS`
is dated **29 January 2000**, and `STennis.BAS` **30 June 2000**, using UTC dates.
They have not been artificially changed to 1999.

[`archive/file-dates.csv`](archive/file-dates.csv) records every path, size,
timestamp, SHA-256 and import commit. Git checkouts do not normally restore
filesystem modification times; the history and manifest retain those dates.

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
