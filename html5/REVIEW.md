# Review of the supplied QBasic game

## What is in the two original folders

`ST_src/` contains the editable `STennis.BAS`, a separate menu prototype
(`MENU.BAS`), graphics experiments, MIDI and WAV files, and a compiled test.
`SnoopyTennis_v2-1/` is the packaged v2.1 release: DOS executables, runtime drivers,
art data, documentation, and a separate Visual Basic Windows launcher with its
source. The actual game is the QBasic program, not that Windows launcher.

The source is not a provably identical v2.1 release snapshot: its exit screen
identifies itself as v2.00.10, while the release title and README identify v2.1.
This port therefore uses the supplied QBasic rules together with the final
release artwork and documented controls. The DOS executables were not run.

## Program structure

`STennis.BAS` starts with a logo animation, initializes Qmidi and Andrew Ayers's
Blast assembly graphics routines, then opens a 640×480 menu. The game switches
to VGA mode 13 (320×200), loads character poses, and runs a double-buffered loop.
Input and a busy wait at the end of each frame set a minimum 0.09-second tick.

The game has five fixed Snoopy positions: y = 155, 110, 80, 40, 5. Balls follow
five integer serve paths, five outgoing paths, and five faster Lucy return paths.
A hit is determined by the ball's path type matching the selected stage, an
x coordinate strictly between 225 and 249, and the active swing pose. The score
increments by 2 for a serve and 3 for a Lucy return. Random serve/return behavior
changes at source tick thresholds around 200, 600, 900 and 1200.

The release's SNDATA2–SNDATA9, SNDATAa and SNDATAb files are ordinary 4-bit BMPs
with DAT extensions. SNDATA1 is the help/credits text. The recoverer preserves
palette-index-zero transparency, applies the source BMP loader's +2 x / +1 y
offsets, and takes its exact character GET rectangles. This includes the Charlie
Brown crop beginning at y = 26. No replacement character art was generated.

## Findings and handling in the HTML5 version

| Finding | Original source | HTML5 handling |
| --- | --- | --- |
| Fourth miss allowed | `lives = 3`, but game over only at `IF lives < 0` (lines 245, 433–434). | End on the third miss, matching both README and help. |
| Documented quit key absent | The gameplay SELECT CASE handles movement and Space, but no Q (lines 485–499). | Q returns to the ready screen. |
| Score drawn after presentation | `BlastCopy` presents the frame before `BlastPrint` writes its score to the offscreen buffer (lines 469–472); the next frame overwrites that buffer with the background. | Render score before presentation and show it in the surrounding HUD. |
| Frame pacing consumes CPU | A TIMER polling loop waits for 0.09 seconds (lines 478–482), and the actual speed also includes drawing time. | Fixed 90 ms simulation ticks, rendered via requestAnimationFrame; clamp catch-up after a stall. |
| No pause or focus protection | The game continues while another window is active. | Pause button, Esc, and automatic pause when focus/visibility is lost. |
| Integer rounding affects paths | QBasic stores y and n in INTEGER fields (lines 267–272). | Explicit ties-to-even rounding retains the integer trajectories. |
| Unbounded allocated ball slots | `ball(40)` has a fixed capacity; serving can allocate another index (lines 273, 289–304). | Track only live balls and cap capacity at 40. |
| Game-over text has broken ranges | `CASE IS > 50, IS < 149` uses alternatives and catches essentially every remaining score; the last result uses `sh$` instead of `sc$` (lines 862–869). | Consistent score and personal-best result text. |
| Platform-specific graphics/audio | Real-mode machine code, direct VGA access, DOS MIDI drivers. | Canvas 2D, browser input, and Web Audio. |

The port retains the characteristic slow frame cadence, five positions, strict
hit window, swing/recovery poses, original trajectories, three characters, and
progression thresholds. It keeps Lucy's existing ball-age value when changing to
a fast-return type, as the original code does. It also retains the source's gaps
in Lucy-return probability bands, rather than inventing difficulty levels.

Browser conveniences include responsive presentation, touch buttons, full screen
where supported, local best-score saving, optional hit sounds, and a floating
point notification. The original SCREEN 12 menu, fading grey circle lettering,
upward-scrolling SNDATA1 About/Help, and farewell screen are also reproduced.
The scroll uses a readable fixed speed, permits pausing, and lets the final lines
scroll completely out before returning; any key still dismisses it immediately.
Exit returns to the menu after a key/tap rather than attempting to close a browser.
The user's separate local Windows MIDI trial uses the installed Windows GS sample bank;
see `MIDI-REVIEW.md` for the original Creative FM evidence and playback limits.
The public build uses credited GeneralUser GS samples with its upstream license.
Original DOS hardware music timbres, DOS startup animations,
Windows installer/launcher behavior, and exact CRT pixel aspect are not emulated.
The scene is displayed in its native 320:200 pixel aspect. HD remains a future
renderer; only original graphics are implemented here.
