# Original music path and Windows playback trial

## Evidence in this release

The Visual Basic launcher's `cmdPlay_Click` and the supplied `Play.bat` run
`sbmidi`, `sbsim.com`, then `st2-1.exe`, with no MIDI command-line overrides.
The bundled `Sbmidi.exe` identifies itself as **Creative MIDI Driver 1.22**.
Its own embedded help states these defaults:

- `/E`: Extended MIDI, rather than `/G`: General MIDI.
- `/1`: Sound Blaster Music Synthesizer, rather than the external synth outputs
  `/2` or `/3` (MPU-401).

The Qmidi `LoadAndPlayMIDI` routine passes the file's memory address to INT 80h,
functions BX=4 and BX=5. It is using the resident MIDI driver; the game does not
contain a synthesizer or a named sample bank. The optional large-file routine
uses INT 81h, but the main game invokes the in-memory routine.

`Sbsim.cfg` specifies `MidiMap=0`. `CTMIDI.DRV` is also present and identifies
itself as Creative Loadable MIDI Driver 1.20 / Creative Sound Blaster 16, but its
presence alone does not prove that this game's in-memory MIDI path uses it.
There are no SF2, SBK or ECW sound banks in the supplied game folders.

Taken together, the strongest default target is **Creative's Sound Blaster FM
instrument set**, typically OPL3 on the SB16 / SB Pro 2 generation. This is an
inference from the shipped setup; a particular machine, compatible card, driver
already resident in DOS, or Windows/DOS emulator could have changed the sound.
The files cannot identify the author's exact original sound card.

Creative's manual describes Extended MIDI as channels 1–10, with drums on 10;
General MIDI enables all 16. This song uses only 1, 2, 3 and 10, so simply changing
`/E` to `/G` would not explain its different timbres in the initial HTML5 port.

## What the actual MIDI requests

`peanuts.mid` is a nine-track format-1 file with 2,337 note events and a total
timeline of about 127 seconds. Its named instrument tracks are:

| MIDI channel | Track name | Program byte (zero-based) | Standard GM instrument |
| --- | --- | --- | --- |
| 1 | Piano Lead | 1 | Bright Acoustic Piano (displayed program 2) |
| 2 | Piano | 1 | Bright Acoustic Piano (displayed program 2) |
| 3 | Fretless Bass | 35 | Fretless Bass (displayed program 36) |
| 10 | Standard Drum Set | 0 | Standard kit |

The drum notes are 36, 37, 40, 42, 44, 46, 49, 57 and 69: kick, side stick,
electric snare, three hi-hats, two crash cymbals and cabasa. Bank selects are
zero. The file includes volume, centered pan, reverb and chorus controllers,
and no SysEx messages. Its instrument names are explicit in the file itself.

The initial port decoded the notes but used a sine wave for the piano, a triangle
for the bass, and two pitched triangle tones for all drums. It did not reproduce
a Windows GS or Creative FM instrument table. That was the main audible mismatch.

## Requested Windows MIDI trial

At the user's request, a local Windows version was built using samples from the installed
`C:\Windows\System32\drivers\gm.dls`, the Windows GS/GM bank, rather than the
placeholder oscillators. The MIDI file itself remains byte-identical.

`tools/extract_windows_midi.py` reads the bank's RIFF DLS structures and retains
23 PCM waves referenced by the required piano/bass regions and nine drum notes.
The original Roland/Microsoft sound-set notice is retained in the data. The
bank remains a local asset in this build; no external service is used to play it.

The browser sampler applies note/velocity regions, root pitches, fine tuning,
sample attenuation, loop points, DLS attack/decay/release parameters, and hi-hat
exclusive groups. MIDI volume, pan and effect amounts are retained. Reverb and
chorus use browser effects. Every note in the score resolves to a sample.

This is a **Windows GS sample-based approximation**, not a bit-identical emulator
of Microsoft's GS Wavetable/DirectMusic engine. Its effects, envelope details,
resampling, and voice allocation can differ. It is also a different target from
the original release's default Creative FM setup. Faithful DOS FM playback would
require the Creative patches and an OPL emulator, or a recording of that setup.

## Sources

The later public GitHub build uses a sample subset from **GeneralUser GS** by
S. Christian Collins, with the upstream license included. The Windows sample
data, local Windows preview recording and Windows-only standalone file are
ignored by Git and are not part of that public build. The original archive and
MIDI bytes remain unchanged. See `assets/GM-NOTICE.md` for public sample provenance.

- The supplied `Play.bat`, `Sbsim.cfg`, QBasic source, VB launcher and driver
  binaries are the primary evidence for this game.
- [Creative's Using PC Sounds manual](https://machut.net/files/manuals/dos_compatibility/0306637APCSNDDOSCD.PDF), printed page 11, documents SBMIDI formats/defaults.
- [Microsoft's MIDI documentation](https://learn.microsoft.com/en-us/windows/apps/develop/media-authoring-processing/midi) identifies GS Wavetable Synth and the system `gm.dls` bank.
- [Microsoft's built-in GM synth explanation](https://microsoft.github.io/MIDI/kb/in-box-general-midi-synth/) identifies the original Roland GS/GM sound set and distinguishes the new engine from the older GS Wavetable Synth.
- [Microsoft DLS download support](https://learn.microsoft.com/en-us/windows-hardware/drivers/audio/dls-download-support) describes instruments, PCM waves and articulation data.
