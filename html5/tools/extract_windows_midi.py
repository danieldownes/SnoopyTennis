"""Build the song's sample set from this PC's installed Windows GS DLS bank.

Only PCM waves referenced by bright piano, fretless bass and this song's drum
notes are retained. Run on Windows to rebuild the local audio asset.
"""
from pathlib import Path
import argparse
import base64
import hashlib
import json
import os
import struct

ROOT = Path(__file__).resolve().parents[1]
DRUM_NOTES = {36, 37, 40, 42, 44, 46, 49, 57, 69}


def extract(bank_path):
    data = Path(bank_path).read_bytes()
    if data[:4] != b"RIFF" or data[8:12] != b"DLS ":
        raise ValueError("Expected a RIFF DLS sound bank")

    def chunks(start, end):
        while start + 8 <= end:
            tag = data[start:start + 4].decode("ascii")
            length, = struct.unpack_from("<I", data, start + 4)
            body = start + 8
            if body + length > end:
                raise ValueError("Invalid DLS chunk length")
            yield tag, body, body + length
            start = body + length + (length & 1)

    def lists(start, end):
        for tag, body, limit in chunks(start, end):
            if tag == "LIST":
                yield data[body:body + 4].decode("ascii"), body + 4, limit

    def articulation(start, end):
        connections = []
        for kind, body, limit in lists(start, end):
            if kind not in ("lart", "lar2"):
                continue
            for tag, pos, stop in chunks(body, limit):
                if tag not in ("art1", "art2"):
                    continue
                header, count = struct.unpack_from("<II", data, pos)
                for i in range(count):
                    connections.append(struct.unpack_from("<HHHHi", data, pos + header + i * 12))
        return connections

    def wave_parameters(pos):
        header, unity, fine, attenuation, options, count = struct.unpack_from("<IHhiII", data, pos)
        loops = []
        for i in range(count):
            size, kind, start, length = struct.unpack_from("<IIII", data, pos + header + i * 16)
            loops.append({"start": start, "length": length})
        return {"root": unity, "fine": fine, "attenuation": attenuation, "loops": loops}

    top = list(chunks(12, min(len(data), 8 + struct.unpack_from("<I", data, 4)[0])))
    list_top = {kind: (body, limit) for kind, body, limit in lists(12, len(data))}
    ptbl = next(body for tag, body, _ in top if tag == "ptbl")
    header, count = struct.unpack_from("<II", data, ptbl)
    offsets = struct.unpack_from(f"<{count}I", data, ptbl + header)
    pool, pool_end = list_top["wvpl"]
    wave_locations = {}
    for tag, body, limit in chunks(pool, pool_end):
        if tag == "LIST" and data[body:body + 4] == b"wave":
            wave_locations[body - 8 - pool] = (body + 4, limit)

    instruments = {}
    needed_waves = set()
    start, end = list_top["lins"]
    for kind, body, limit in lists(start, end):
        if kind != "ins ":
            continue
        fields = {tag: (pos, stop) for tag, pos, stop in chunks(body, limit)}
        _, bank, program = struct.unpack_from("<III", data, fields["insh"][0])
        if (bank, program) not in ((0, 1), (0, 35), (0x80000000, 0)):
            continue
        percussion = bool(bank & 0x80000000)
        common_art = articulation(body, limit)
        regions = []
        for group, a, b in lists(body, limit):
            if group != "lrgn":
                continue
            for _, region_start, region_end in lists(a, b):
                fields = {tag: (pos, stop) for tag, pos, stop in chunks(region_start, region_end)}
                low, high, vlo, vhi, options, exclusive = struct.unpack_from("<HHHHHH", data, fields["rgnh"][0])
                if percussion and not any(low <= note <= high for note in DRUM_NOTES):
                    continue
                _, _, _, wave_index = struct.unpack_from("<HHII", data, fields["wlnk"][0])
                needed_waves.add(wave_index)
                wave_start, wave_end = wave_locations[offsets[wave_index]]
                wave_fields = {tag: (pos, stop) for tag, pos, stop in chunks(wave_start, wave_end)}
                wsmp = fields.get("wsmp", wave_fields.get("wsmp"))
                if not wsmp:
                    raise ValueError("Missing wave tuning parameters")
                regions.append({"low": low, "high": high, "velocityLow": vlo, "velocityHigh": vhi,
                                "group": exclusive, "wave": str(wave_index), **wave_parameters(wsmp[0]),
                                "art": common_art + articulation(region_start, region_end)})
        instruments["drums" if percussion else str(program)] = regions

    samples = {}
    for wave_index in sorted(needed_waves):
        start, end = wave_locations[offsets[wave_index]]
        fields = {tag: (pos, stop) for tag, pos, stop in chunks(start, end)}
        pos = fields["fmt "][0]
        fmt, channels, rate, byte_rate, block, bits = struct.unpack_from("<HHIIHH", data, pos)
        if fmt != 1 or bits not in (8, 16):
            raise ValueError(f"Unsupported sample format {fmt}/{bits}")
        a, b = fields["data"]
        samples[str(wave_index)] = {"rate": rate, "channels": channels, "bits": bits,
                                   "pcm": base64.b64encode(data[a:b]).decode("ascii")}
    return {"name": "Windows GS", "source": "Installed Windows gm.dls",
            "copyright": "Roland GS Sound Set / Microsoft (P) 1996 Roland Corporation U.S.",
            "sha256": hashlib.sha256(data).hexdigest(), "instruments": instruments, "samples": samples}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dls", default=str(Path(os.environ.get("WINDIR", "C:/Windows")) / "System32/drivers/gm.dls"))
    args = parser.parse_args()
    result = extract(args.dls)
    output = ROOT / "assets/windows-midi-data.js"
    output.write_text("// Locally installed Windows GS samples; original sound-set notice retained below.\n"
                      "globalThis.SNOOPY_WINDOWS_MIDI = " + json.dumps(result, separators=(",", ":")) + ";\n", encoding="utf-8")
    print(f"Extracted {len(result['samples'])} PCM waves for piano, bass and drums ({output.stat().st_size:,} bytes)")
