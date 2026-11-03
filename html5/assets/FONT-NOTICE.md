# VGA menu lettering

`vga8.f16` is the raw 8×16 IBM VGA bitmap character set from VileR's
[VGA text mode font collection](https://github.com/viler-int10h/vga-text-mode-fonts/blob/master/FONTS/PC-IBM/VGA8.F16).
It is 256 glyphs × 16 bytes. Each byte represents one eight-pixel scanline.
The binary glyph data is unchanged; `menu-data.js` embeds it for offline use.

The original QBasic menu obtains its letters from the video BIOS. This bitmap
recreates that lettering without depending on a browser or installed system font.
The menu's outlined-circle enlargement is implemented from the original
`neatfont` routine in `STennis.BAS`; it does not use a modern outline font.

Collection information and raw-bitmap provenance:
[The Oldschool PC Font Resource](https://int10h.org/oldschool-pc-fonts/readme/).
