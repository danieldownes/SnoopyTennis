"use strict";
const { test } = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const standalone = fs.readFileSync(path.join(__dirname, "../../SnoopyTennis.html"), "utf8");
test("the portable HTML contains all runtime assets and syntactically valid inline code", () => {
  assert.doesNotMatch(standalone, /<script[^>]+src=/i);
  assert.doesNotMatch(standalone, /<link[^>]+rel="stylesheet"/i);
  for (const match of standalone.matchAll(/<(?:img|link)[^>]+(?:src|href)="([^"]+)"/gi))
    assert.ok(match[1].startsWith("data:image/png;base64,"), "images must be embedded");
  const scripts = [...standalone.matchAll(/<script>([\s\S]*?)<\/script>/gi)];
  assert.equal(scripts.length, 1);
  assert.doesNotThrow(() => new vm.Script(scripts[0][1]));
  assert.ok(standalone.includes("globalThis.SNOOPY_IMAGES ="));
  assert.ok(standalone.includes("globalThis.SNOOPY_MIDI ="));
  assert.ok(standalone.includes("globalThis.SNOOPY_MIDI_BANK ="));
  assert.ok(standalone.includes('"name":"GeneralUser GS"'));
  assert.ok(!standalone.includes("globalThis.SNOOPY_WINDOWS_MIDI ="), "public build must exclude the local Windows bank");
});
test("the preview distribution and the portable file are identical", () => {
  assert.equal(fs.readFileSync(path.join(__dirname, "../dist/index.html"), "utf8"), standalone);
});
