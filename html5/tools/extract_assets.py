"""Recover the DOS art without redrawing it. Run from any working directory.

Requires Pillow only when regenerating assets; the game itself has no dependencies.
The original BMP loader shifts pixels two columns right and one row down. Reproduce
that before taking the exact GET rectangles used by STennis.BAS.
"""
from pathlib import Path
import base64
import json
import re
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "html5" / "assets"
DIST = ROOT / "SnoopyTennis_v2-1"
OUT.mkdir(exist_ok=True)
palette = Image.open(DIST / "SNDATA8.DAT").getpalette()


def dos_image(filename, size, box=None, transparent=False):
    source = Image.open(DIST / filename)
    # All sprites are drawn using the palette installed by the final background.
    source.putpalette(palette if transparent else source.getpalette())
    shifted = Image.new("P", size, 0)
    shifted.putpalette(source.getpalette())
    shifted.paste(source, (2, 1))
    if box:
        shifted = shifted.crop(box)
    result = shifted.convert("RGBA")
    if transparent:
        indices = list(shifted.tobytes())
        raw = result.tobytes()
        rgba = [raw[i:i + 4] for i in range(0, len(raw), 4)]
        result.putdata([(*color[:3], 0 if index == 0 else 255)
                        for index, color in zip(indices, rgba)])
    return result


sprites = {
    "snoopy-idle": ("SNDATA9.DAT", (0, 0, 59, 47)),
    "snoopy-hit": ("SNDATAa.DAT", (0, 0, 59, 47)),
    "snoopy-follow": ("SNDATA2.DAT", (0, 0, 59, 47)),
    "lucy-ready": ("SNDATA3.DAT", (0, 0, 47, 85)),
    "lucy-idle": ("SNDATA4.DAT", (0, 0, 47, 85)),
    "charlie-idle": ("SNDATA5.DAT", (0, 26, 64, 102)),
    "charlie-hit": ("SNDATA6.DAT", (0, 26, 64, 102)),
    "charlie-follow": ("SNDATA7.DAT", (0, 26, 64, 102)),
}
for name, (filename, box) in sprites.items():
    dos_image(filename, (320, 200), box, True).save(OUT / f"{name}.png")
background = dos_image("SNDATA8.DAT", (320, 200))
# GET captures rows 0..198; the remaining buffer row is empty.
background.paste((0, 0, 0, 255), (0, 199, 320, 200))
background.save(OUT / "background.png")
dos_image("SNDATAb.DAT", (640, 94)).save(OUT / "title.png")
(OUT / "peanuts.mid").write_bytes((DIST / "peanuts.mid").read_bytes())
# Embedding MIDI also lets audio work when index.html is opened directly.
midi = base64.b64encode((DIST / "peanuts.mid").read_bytes()).decode("ascii")
(OUT / "music-data.js").write_text(
    "// Original peanuts.mid, embedded for offline/file:// playback.\n"
    "globalThis.SNOOPY_MIDI = " + json.dumps(midi) + ";\n", encoding="utf-8")
lines = []
for line in (DIST / "SNDATA1.DAT").read_text(encoding="cp437").splitlines():
    match = re.fullmatch(r'\s*"([^"]*)"\s*', line)
    if not match:
        raise ValueError(f"Unexpected help data: {line!r}")
    lines.append(match.group(1))
font = (OUT / "vga8.f16").read_bytes()
if len(font) != 256 * 16:
    raise ValueError("The VGA font must contain 256 eight-by-sixteen glyphs")
menu_data = {"lines": lines, "font": base64.b64encode(font).decode("ascii")}
(OUT / "menu-data.js").write_text(
    "// Original SNDATA1.DAT transcript and IBM VGA bitmap lettering. See FONT-NOTICE.md.\n"
    "globalThis.SNOOPY_MENU_DATA = " + json.dumps(menu_data) + ";\n", encoding="utf-8")
print(f"Recovered {len(sprites)} sprites, background, title, MIDI and menu data into {OUT}")
