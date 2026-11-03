# Snoopy Tennis — HTML5 original edition

Open **SnoopyTennis.html** in the parent folder for the single-file distribution,
or **index.html** here for the editable version. Everything is local: no installation,
account, build, internet connection, or external fonts are needed. Keep the files
in this folder together. Sound begins after a click or key press.

For a local preview, run `node tools/serve.cjs` from this folder, then visit
http://127.0.0.1:4173. Stop the preview with Ctrl+C. The optional npm equivalents
are `npm start`, `npm test`, and `npm run check`; npm is not required.

## Controls

The game now opens on the original black 640×480 menu: **Start Game**,
**About/Help**, and **Exit**. Use Up/Down and Enter, or click/tap a choice.
About/Help scrolls the original instructions and credits upward, starting with
the menu itself scrolling away, as in the QBasic program. Press any key or tap
the screen to return; Pause freezes the text for reading. The Menu button and
Q return from gameplay. Exit shows the original farewell screen; in a browser,
a key or tap returns to the menu instead of closing the tab.

| Action | Keyboard | Touch |
| --- | --- | --- |
| Climb up | Up arrow or P | Up |
| Climb down | Down arrow or L | Down |
| Swing | Space | Swing |
| Pause / resume | Esc | Pause / Resume |
| Start / play again | Enter | Start game / Play again |
| End current game | Q | — |

Meet a ball at the correct one of five branches and swing while it reaches the
racket. A normal return scores 2 points; a fast Lucy return scores 3. Three
misses end the game. Serves become more frequent as time passes. Your best score
is saved in this browser when local storage is available. Switching to another
window or tab automatically pauses a live game; resume explicitly to continue.
The Sound switch mutes all audio; Music switches just the original tune.

## Original edition and future HD graphics

The original edition uses the actual release artwork, including all eight
character animation frames, the background, and title. Canvas draws at 320×200
with smoothing disabled. The five positions, integer ball paths, swing timing,
Lucy returns, and progression thresholds come from `ST_src/STennis.BAS`.
Simulation advances every 90 ms, independent of display refresh rate.

The HD choice is visibly reserved and disabled. Adding it requires a renderer
with the same `load()` / `render(game)` interface as `OriginalRenderer`, registered
in `SnoopyGraphics`; game rules and input do not need to change. HD assets and HD
rendering have deliberately not been implemented in this first version.

Music uses the byte-for-byte original `peanuts.mid`, decoded into a tempo-aware,
polyphonic Web Audio timeline. The public build uses GeneralUser GS by
S. Christian Collins, with a sampled piano, fretless bass and drum kit.
See `assets/GM-NOTICE.md` and the accompanying upstream license. The earlier
Windows GS trial is available as a separate, ignored local build using this PC's
installed `gm.dls`; those sample bytes are excluded from the public repository.
Neither sampler is an exact emulation of the DOS Sound Blaster. Muting and
music playback do not affect the simulation. Browser full screen is offered only
when supported. Mobile has visible controls; its 320×200 picture is scaled to fit.

## Files

- `engine.js`: game rules, with no browser dependency.
- `graphics.js`: original pixel renderer and renderer registry.
- `audio.js`: MIDI reader, synthesizer, and sound effects.
- `sample-bank.js`: PCM sampling, tuning, loops and envelopes.
- `app.js`: keyboard/touch input, screen states, timing, and best-score storage.
- `menu.js`: original 640×480 menu, circle lettering, scrolling help and exit screen.
- `assets/`: recovered PNG artwork and the original MIDI score.
- `tools/extract_assets.py`: reproducible recovery from the distributable's DATs.
- `tools/extract_gm_midi.py`: extracts the public sample subset from GeneralUser GS.
- `tools/package.cjs`: builds the standalone `../SnoopyTennis.html` distribution.
- `dist/index.html`: identical standalone build for a static web host or preview.
- `tests/`: game-rule and MIDI checks using Node's built-in test runner.
- `REVIEW.md`: findings from the original source and deliberate port differences.
- `MIDI-REVIEW.md`: driver evidence, instrument map, and Windows playback changes.

## Verification

Run `node --test tests/engine.test.cjs tests/audio.test.cjs tests/menu.test.cjs tests/sample-bank.test.cjs tests/distribution.test.cjs` from this folder.
Syntax checks: `node --check engine.js`, `node --check graphics.js`,
`node --check audio.js`, `node --check sample-bank.js`, `node --check menu.js`, and `node --check app.js`.

To regenerate the included assets, install Pillow if necessary and run
`python tools/extract_assets.py`. Python and Pillow are only needed for recovery,
not to play or serve the game. The supplied source and distributable are left intact.
After editing the HTML5 source, run `node tools/package.cjs` to refresh the
single-file distribution (or use `npm run build` if npm is installed).
To rebuild the local Windows instrument asset, run
`python tools/extract_windows_midi.py` on Windows. It reads the installed GS
sound bank; `--dls <path>` can select that same bank at a different location.
Then run `node tools/package.cjs --windows-local` to build the ignored
`../SnoopyTennis-Windows-local.html` without replacing the public build.
For the public bank, obtain the pinned GeneralUser GS revision listed in
`assets/GM-NOTICE.md` and run `python tools/extract_gm_midi.py <path-to-sf2>`.
The full source soundfont is not needed to play or package the already generated subset.
The test page `tests/audio-preview.html` renders a 12-second preview and checks
the resulting signal for silence, non-finite samples and clipping.

## Original credits

Game/menu and artwork modifications: Daniel Downes (formerly Daniel Vincent).
Original DOS graphics: Andrew Ayers, Blast. MIDI support: Jesse Dorland, Qmidi.
MIDI sequence: D. W. Barnes. Gravity formula: Andrew Bellchambers.

Original Ex-D Software Development game © 2000–02. Peanuts characters belong to
their respective rights holders. The original credits attribute the game design
to Nintendo's 1982 Snoopy Tennis Game & Watch. This port retains those credits.
VGA bitmap lettering: IBM VGA character set preserved in VileR's
[font collection](https://github.com/viler-int10h/vga-text-mode-fonts).
See `assets/FONT-NOTICE.md` for its source.
