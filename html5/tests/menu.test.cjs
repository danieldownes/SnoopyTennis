"use strict";
const { test } = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const { LABELS, SCROLL_SPEED, wrapSelection, aboutLayout } = require("../menu.js");

test("the original three menu choices wrap with the arrow keys", () => {
  assert.deepEqual(LABELS, ["Start Game", "About/Help", "Exit"]);
  assert.equal(wrapSelection(-1), 2);
  assert.equal(wrapSelection(3), 0);
});
test("scrolling inserts the first line at the source's LOCATE 26 and spaces subsequent lines by 16 pixels", () => {
  const lines = ["Keys", "----"];
  assert.deepEqual(aboutLayout(lines, 0).visible, []);
  assert.deepEqual(aboutLayout(lines, 18 / SCROLL_SPEED).visible, [{ text: "Keys", y: 400 }]);
  assert.deepEqual(aboutLayout(lines, 34 / SCROLL_SPEED).visible,
    [{ text: "Keys", y: 384 }, { text: "----", y: 400 }]);
});
test("the last credits remain readable until they have scrolled offscreen", () => {
  const lines = ["Programming", "Daniel Downes"];
  assert.equal(aboutLayout(lines, 34 / SCROLL_SPEED).finished, false);
  const end = aboutLayout(lines, (418 + lines.length * 16) / SCROLL_SPEED);
  assert.equal(end.finished, true);
  assert.deepEqual(end.visible, []);
});
test("embedded About/Help preserves every original line, including spacing and the historical disclaimer", () => {
  const data = {};
  vm.runInNewContext(fs.readFileSync(path.join(__dirname, "../assets/menu-data.js"), "utf8"), data);
  const original = fs.readFileSync(path.join(__dirname, "../../SnoopyTennis_v2-1/SNDATA1.DAT"), "utf8")
    .trimEnd().split(/\r?\n/).map(line => line.match(/^\s*"([^"]*)"\s*$/)[1]);
  assert.deepEqual(Array.from(data.SNOOPY_MENU_DATA.lines), original);
  assert.equal(Buffer.from(data.SNOOPY_MENU_DATA.font, "base64").length, 4096);
  assert.ok(original.some(line => line.includes("delete within 48 hours")));
});
