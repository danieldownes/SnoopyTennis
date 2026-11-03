"""Extract this song's GM voices from the redistributable GeneralUser GS SF2.

Uses only the standard library. Download the upstream bank separately, retain
its license, and pass its path. The generated subset is embedded in public builds.
"""
from pathlib import Path
import argparse
import base64
import hashlib
import json
import struct

ROOT = Path(__file__).resolve().parents[1]
DRUM_NOTES = {36, 37, 40, 42, 44, 46, 49, 57, 69}


def extract(font_path):
    data = Path(font_path).read_bytes()
    if data[:4] != b"RIFF" or data[8:12] != b"sfbk":
        raise ValueError("Expected a SoundFont 2 bank")

    def chunks(start, end):
        while start + 8 <= end:
            tag = data[start:start + 4].decode("ascii")
            size = struct.unpack_from("<I", data, start + 4)[0]
            yield tag, start + 8, start + 8 + size
            start += 8 + size + (size & 1)

    groups = {}
    for tag, start, end in chunks(12, len(data)):
        if tag == "LIST":
            groups[data[start:start + 4].decode("ascii")] = {tag: (a, b) for tag, a, b in chunks(start + 4, end)}
    pdta = groups["pdta"]

    def records(tag, size):
        start, end = pdta[tag]
        return [data[pos:pos + size] for pos in range(start, end, size)]

    presets, preset_bags, preset_gens = records("phdr", 38), records("pbag", 4), records("pgen", 4)
    insts, inst_bags, inst_gens = records("inst", 22), records("ibag", 4), records("igen", 4)
    samples = records("shdr", 46)
    sample_start, sample_end = groups["sdta"]["smpl"]

    def generators(bags, gens, index):
        lo = struct.unpack_from("<H", bags[index])[0]
        hi = struct.unpack_from("<H", bags[index + 1])[0]
        return {struct.unpack_from("<H", value)[0]: struct.unpack_from("<H", value, 2)[0] for value in gens[lo:hi]}

    def signed(value):
        return value - 65536 if value >= 32768 else value

    def range_of(zones, key):
        low, high = 0, 127
        for zone in zones:
            if key in zone:
                value = zone[key]
                low, high = max(low, value & 255), min(high, value >> 8)
        return low, high

    def amount(preset, instrument, key, default=0):
        return signed(instrument.get(key, default & 65535)) + signed(preset.get(key, 0))

    waves, result = {}, {}
    for preset_id, header in enumerate(presets[:-1]):
        program, bank, bag = struct.unpack_from("<HHH", header, 20)
        if (bank, program) not in ((0, 1), (0, 35), (128, 0)):
            continue
        preset_end = struct.unpack_from("<H", presets[preset_id + 1], 24)[0]
        global_preset, output, seen = {}, [], set()
        for pbag in range(bag, preset_end):
            pg = generators(preset_bags, preset_gens, pbag)
            if 41 not in pg:
                global_preset.update(pg)
                continue
            preset_zone = {**global_preset, **pg}
            inst_id = preset_zone[41]
            ibag = struct.unpack_from("<H", insts[inst_id], 20)[0]
            inst_end = struct.unpack_from("<H", insts[inst_id + 1], 20)[0]
            global_inst = {}
            for inst_bag in range(ibag, inst_end):
                ig = generators(inst_bags, inst_gens, inst_bag)
                if 53 not in ig:
                    global_inst.update(ig)
                    continue
                instrument_zone = {**global_inst, **ig}
                low, high = range_of([preset_zone, instrument_zone], 43)
                vlo, vhi = range_of([preset_zone, instrument_zone], 44)
                if low > high or vlo > vhi:
                    continue
                if bank == 128 and not any(low <= note <= high for note in DRUM_NOTES):
                    continue
                sample_id = instrument_zone[53]
                s = samples[sample_id]
                start, end, loop_start, loop_end, rate = struct.unpack_from("<IIIII", s, 20)
                pitch = s[40]
                correction = struct.unpack_from("<b", s, 41)[0]
                link, kind = struct.unpack_from("<HH", s, 42)
                stereo = kind & 7 in (2, 4)
                wave_id = str(min(sample_id, link) if stereo else sample_id)
                if wave_id not in waves:
                    ids = [sample_id]
                    if stereo:
                        ids = [sample_id, link] if kind & 7 == 4 else [link, sample_id]
                    channels = []
                    for index in ids:
                        a, b = struct.unpack_from("<II", samples[index], 20)
                        channels.append(data[sample_start + a * 2:sample_start + b * 2])
                    if len(channels) == 1:
                        pcm = channels[0]
                    else:
                        length = min(map(len, channels)) // 2
                        pcm = bytearray(length * 4)
                        for frame in range(length):
                            pcm[frame * 4:frame * 4 + 2] = channels[0][frame * 2:frame * 2 + 2]
                            pcm[frame * 4 + 2:frame * 4 + 4] = channels[1][frame * 2:frame * 2 + 2]
                    waves[wave_id] = {"rate": rate, "channels": len(channels), "bits": 16,
                                      "pcm": base64.b64encode(pcm).decode("ascii")}
                root = instrument_zone.get(58, pitch)
                if instrument_zone.get(56, 100) == 0 and low == high:
                    root = low
                root -= amount(preset_zone, instrument_zone, 51)
                fine = correction + amount(preset_zone, instrument_zone, 52)
                attenuation = -amount(preset_zone, instrument_zone, 48) * 65536
                loops = []
                if instrument_zone.get(54, 0) & 3 in (1, 3) and loop_end > loop_start:
                    loops.append({"start": loop_start - start, "length": loop_end - loop_start})
                attack = amount(preset_zone, instrument_zone, 34, -12000)
                decay = amount(preset_zone, instrument_zone, 36, -12000)
                release = amount(preset_zone, instrument_zone, 38, -12000)
                key_decay = amount(preset_zone, instrument_zone, 40)
                sustain = 10 ** (-amount(preset_zone, instrument_zone, 37) / 200)
                art = [[0, 0, 0x206, 0, attack * 65536],
                       [0, 0, 0x207, 0, (decay + key_decay * 60) * 65536],
                       [3, 0, 0x207, 0, -key_decay * 127 * 65536],
                       [0, 0, 0x209, 0, release * 65536],
                       [0, 0, 0x20a, 0, round(min(1, sustain) * 65536000)]]
                region = {"low": low, "high": high, "velocityLow": vlo, "velocityHigh": vhi,
                          "group": instrument_zone.get(57, 0), "wave": wave_id, "root": root,
                          "fine": fine, "attenuation": attenuation, "loops": loops, "art": art}
                signature = json.dumps(region, sort_keys=True)
                if signature not in seen:
                    seen.add(signature)
                    output.append(region)
        result["drums" if bank == 128 else str(program)] = output
    return {"name": "GeneralUser GS", "source": "GeneralUser GS by S. Christian Collins",
            "copyright": "GeneralUser GS by S. Christian Collins; see GENERALUSER-LICENSE.txt",
            "sha256": hashlib.sha256(data).hexdigest(), "instruments": result, "samples": waves}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("soundfont", type=Path)
    args = parser.parse_args()
    bank = extract(args.soundfont)
    output = ROOT / "assets/gm-midi-data.js"
    output.write_text("// GeneralUser GS sample subset. S. Christian Collins; see GENERALUSER-LICENSE.txt.\n"
                      "globalThis.SNOOPY_MIDI_BANK = " + json.dumps(bank, separators=(",", ":")) + ";\n", encoding="utf-8")
    print(f"Extracted {len(bank['samples'])} GM PCM waves ({output.stat().st_size:,} bytes)")
