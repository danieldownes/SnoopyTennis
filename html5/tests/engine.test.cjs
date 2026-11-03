"use strict";
const { test } = require("node:test");
const assert = require("node:assert/strict");
const { Game, qbInteger, STAGES } = require("../engine.js");
const quietGame = () => { const game = new Game(() => 0.99); game.reset(); game.charlie = 0; return game; };

test("five tree positions clamp at both ends", () => {
  const game = quietGame();
  game.move(-1); assert.equal(game.stage, 1);
  for (let i = 0; i < 9; i++) game.move(1);
  assert.equal(game.stage, 5); assert.equal(game.snoopyY, 5);
  assert.deepEqual(STAGES, [155, 110, 80, 40, 5]);
});
test("QBasic integer assignment rounds half to even, including negative values", () => {
  assert.deepEqual([0.5, 1.5, 2.5, -1.5, -2.5, 3.6].map(qbInteger), [0, 2, 2, -2, -2, 4]);
});
test("all five original serve paths reach the corresponding tree branch", () => {
  // Positions at the first x > 225, from the source's integer gravity formulas.
  const yAtRacket = [157, 113, 79, 47, 3];
  for (let type = 1; type <= 5; type++) {
    const game = quietGame();
    game.balls = [{ x: 10, y: 160, type, n: 0 }];
    while (game.balls[0].x <= 225) game.step();
    assert.equal(game.balls[0].y, yAtRacket[type - 1], `serve ${type}`);
  }
});
test("returning an original serve earns two points and reverses the path", () => {
  const game = quietGame(); game.stage = 2;
  game.balls = [{ x: 225, y: 130, type: 2, n: 40 }]; game.hit();
  const events = game.step();
  assert.equal(game.score, 2); assert.equal(game.balls[0].type, 12); assert.equal(game.balls[0].n, 0);
  assert.equal(events.find(e => e.type === "hit").points, 2);
});
test("a wrong branch, an idle racket, and a late swing cannot return a serve", () => {
  for (const [stage, swing] of [[3, 1], [2, 0], [2, 2]]) {
    const game = quietGame(); game.stage = stage; game.swing = swing;
    game.balls = [{ x: 225, y: 130, type: 2, n: 40 }]; game.step();
    assert.equal(game.score, 0); assert.equal(game.balls[0].type, 2);
  }
});
test("Lucy returns an outgoing ball once, preserving its age; Snoopy earns three points", () => {
  const game = quietGame(); game.tick = 400; game.lucyReady = true;
  game.balls = [{ x: 59, y: 20, type: 13, n: 28 }];
  assert.ok(game.step().some(e => e.type === "lucy"));
  assert.equal(game.balls[0].type, 23); assert.equal(game.balls[0].n, 29); assert.equal(game.lucyReady, false);
  game.stage = 3; game.balls[0].x = 220; game.hit(); game.step();
  assert.equal(game.score, 3); assert.equal(game.balls[0].type, 13);
});
test("exactly three misses end the game and each miss clears simultaneous balls", () => {
  const game = quietGame();
  for (let miss = 1; miss <= 3; miss++) {
    game.balls = [{ x: 305, y: 100, type: 1, n: 60 }, { x: 306, y: 20, type: 4, n: 50 }];
    game.step(); assert.equal(game.lives, 3 - miss);
    assert.equal(game.status, miss === 3 ? "over" : "playing");
    assert.equal(game.balls.length, miss === 3 ? 0 : 1);
  }
});
test("pause freezes the simulation; quit and restart clear session state", () => {
  const game = quietGame(); game.score = 42; game.pause();
  const before = JSON.stringify(game); game.move(1); game.hit(); game.step();
  assert.equal(JSON.stringify(game), before);
  game.pause(); game.step(); assert.equal(game.tick, 1);
  game.quit(); assert.equal(game.status, "ready"); assert.equal(game.balls.length, 0);
  game.reset(); assert.equal(game.score, 0); assert.equal(game.lives, 3); assert.equal(game.tick, 0);
});
test("the racket has an active window and a recovery window; holding swing cannot reset it", () => {
  const game = quietGame(); game.hit();
  game.step(); game.hit(); assert.equal(game.swingTicks, 1);
  game.step(); game.step(); assert.equal(game.swing, 1);
  game.step(); assert.equal(game.swing, 2);
  game.step(); game.step(); game.step(); assert.equal(game.swing, 0);
});
test("a seeded long session stays within the original 40-ball capacity", () => {
  let seed = 17;
  const game = new Game(() => ((seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0) / 2 ** 32));
  game.reset();
  for (let i = 0; i < 25000; i++) {
    const target = game.balls.filter(b => b.type < 6 || b.type > 20).sort((a, b) => b.x - a.x)[0];
    if (target) {
      game.stage = target.type % 10;
      if (target.x > 206 && target.x < 240) game.hit();
    }
    game.step();
    assert.ok(game.balls.length <= 40);
    for (const ball of game.balls) assert.ok(Number.isFinite(ball.x) && Number.isFinite(ball.y));
    if (game.status === "over") game.reset();
  }
});
