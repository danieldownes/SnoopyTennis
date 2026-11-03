# Public General MIDI sample bank

The public browser build uses a subset of **GeneralUser GS**, by
**S. Christian Collins**. The complete upstream license is included in
[GENERALUSER-LICENSE.txt](GENERALUSER-LICENSE.txt).

- Upstream project: https://github.com/mrbumpy409/GeneralUser-GS
- Pinned revision: `684543d5e5efaef08d02be50dcda8d552478fa60`
- Source bank: `GeneralUser-GS.sf2` from that revision.
- Author's site: https://www.schristiancollins.com/generaluser
- Generated subset: `gm-midi-data.js`.

`tools/extract_gm_midi.py` retains only the piano, fretless bass and drum samples
used by the supplied MIDI, together with tuning, loop and envelope information.
The subset is a repackaging of the upstream bank; it is not a new soundfont by
this project's author. No Microsoft/Roland Windows `gm.dls` samples are included
in the public build. The earlier local Windows trial is kept separately.
