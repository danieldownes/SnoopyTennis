"use strict";
const { test } = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const { parseMidi } = require("../audio.js");
test("the original format-1 MIDI decodes to a finite, ordered, polyphonic score", () => {
  const song = parseMidi(fs.readFileSync(path.join(__dirname, "../assets/peanuts.mid")));
  assert.ok(song.notes.length > 1000);
  assert.ok(song.duration > 30 && song.duration < 600);
  assert.ok(new Set(song.notes.map(n => n.channel)).size >= 4);
  for (let i = 0; i < song.notes.length; i++) {
    const note = song.notes[i];
    assert.ok(note.time >= 0 && Number.isFinite(note.time));
    assert.ok(note.duration > 0 && Number.isFinite(note.duration));
    assert.ok(note.velocity >= 0 && note.velocity <= 1);
    if (i) assert.ok(note.time >= song.notes[i - 1].time);
  }
});
test("the file-friendly embedded MIDI is byte-identical to the original", () => {
  const data = fs.readFileSync(path.join(__dirname, "../assets/music-data.js"), "utf8");
  const base64 = data.match(/SNOOPY_MIDI = "([^"]+)"/)[1];
  assert.deepEqual(Buffer.from(base64, "base64"), fs.readFileSync(path.join(__dirname, "../../SnoopyTennis_v2-1/peanuts.mid")));
});
