"use strict";
const { test } = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const { parseMidi } = require("../audio.js");
const { regionFor, timecents, gainFromAttenuation, envelope } = require("../sample-bank.js");
const data = {};
vm.runInNewContext(fs.readFileSync(path.join(__dirname, "../assets/gm-midi-data.js"), "utf8"), data);
const bank = data.SNOOPY_MIDI_BANK;
const song = parseMidi(fs.readFileSync(path.join(__dirname, "../assets/peanuts.mid")));

test("every note of the original score resolves to a public General MIDI sample", () => {
  for (const note of song.notes) {
    const region = regionFor(bank, note);
    assert.ok(region, `missing channel ${note.channel + 1}, program ${note.program}, note ${note.pitch}`);
    assert.ok(bank.samples[region.wave]);
    const env = envelope(region, note);
    for (const value of Object.values(env)) assert.ok(Number.isFinite(value) && value >= 0);
  }
});
test("sample loop points stay inside their PCM buffers", () => {
  for (const regions of Object.values(bank.instruments)) for (const region of regions) {
    const sample = bank.samples[region.wave];
    const pcm = Buffer.from(sample.pcm, "base64");
    const frames = pcm.length / (sample.bits / 8) / sample.channels;
    assert.ok(frames > 0 && Number.isInteger(frames));
    for (const loop of region.loops) {
      assert.ok(loop.start >= 0 && loop.length > 0);
      assert.ok(loop.start + loop.length <= frames);
    }
  }
});
test("DLS timecents and attenuation use the specified logarithmic scales", () => {
  assert.equal(timecents(-2147483648), 0);
  assert.equal(timecents(0), 1);
  assert.equal(timecents(1200 * 65536), 2);
  assert.ok(Math.abs(gainFromAttenuation(-200 * 65536) - 0.1) < 1e-10);
});
test("the three hi-hat voices share an exclusive choke group", () => {
  const groups = [42, 44, 46].map(pitch => regionFor(bank, { channel: 9, program: 0, pitch, velocity: 1 }).group);
  assert.ok(groups[0] > 0);
  assert.equal(groups[0], groups[1]); assert.equal(groups[1], groups[2]);
});
test("the MIDI decoder retains instrument volume, velocity and effects separately", () => {
  for (const note of song.notes) {
    assert.ok(note.rawVelocity > 0 && note.rawVelocity <= 1);
    assert.ok(note.volume >= 0 && note.volume <= 1);
    assert.ok(note.pan >= -1 && note.pan <= 1);
    assert.ok(note.reverb >= 0 && note.reverb <= 1);
    assert.ok(note.chorus >= 0 && note.chorus <= 1);
  }
  const bass = song.notes.find(note => note.program === 35);
  assert.equal(bass.volume, 100 / 127);
  assert.equal(bass.chorus, 32 / 127);
});
