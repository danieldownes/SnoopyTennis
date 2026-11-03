/* The QBasic simulation, independent of drawing, input and wall-clock speed. */
(function (root) {
  "use strict";
  const TICK_MS = 90;
  const STAGES = Object.freeze([155, 110, 80, 40, 5]);
  // x velocity, initial y velocity, gravity divisor: STennis.BAS lines 358–402.
  const PATHS = Object.freeze({
    1: [5, -1, 700], 2: [5, -2, 700], 3: [6, -4, 250],
    4: [6, -4, 500], 5: [6, -7, 170],
    11: [-6, -6, 200], 12: [-6, -6, 100], 13: [-6, -4, 150],
    14: [-6, -2, 258], 15: [-6, 0, 330],
    21: [9, -1, 240], 22: [9, 0, 413], 23: [9, 0, 623],
    24: [9, -2, 583], 25: [9, -2, 1983],
  });

  // QBasic integer assignment uses ties-to-even, unlike Math.round.
  function qbInteger(value) {
    const floor = Math.floor(value);
    const fraction = value - floor;
    return fraction === 0.5 ? (floor % 2 === 0 ? floor : floor + 1) : Math.round(value);
  }

  class Game {
    constructor(random = Math.random) {
      this.random = random;
      this.reset();
      this.status = "ready";
    }

    reset() {
      this.status = "playing";
      this.score = 0;
      this.lives = 3;
      this.stage = 1;
      this.tick = 0;
      this.balls = [];
      this.swing = 0;
      this.swingTicks = 0;
      this.charlie = 0;
      this.charlieTicks = 0;
      this.lucyReady = false;
      this.lastServe = -40;
      this.events = [];
      this.missTicks = 0;
      this.spawn();
    }

    spawn() {
      if (this.balls.length >= 40) return;
      this.balls.push({ x: 10, y: 160, type: Math.floor(this.random() * 5) + 1, n: 0 });
      this.charlie = 1;
      this.charlieTicks = 0;
      this.events.push({ type: "serve" });
    }

    move(direction) {
      if (this.status !== "playing") return;
      this.stage = Math.max(1, Math.min(5, this.stage + direction));
    }

    hit() {
      if (this.status !== "playing" || this.swing !== 0) return;
      this.swing = 1;
      this.swingTicks = 0;
    }

    pause() {
      if (this.status === "playing") this.status = "paused";
      else if (this.status === "paused") this.status = "playing";
    }

    quit() {
      this.status = "ready";
      this.balls = [];
      this.swing = 0;
    }

    get snoopyY() { return STAGES[this.stage - 1]; }
    get activeBalls() { return this.balls.length; }

    step() {
      if (this.status !== "playing") return [];
      this.events = [];
      this.tick++;
      if (this.missTicks > 0) this.missTicks--;
      if (this.swing && ++this.swingTicks > (this.swing === 1 ? 3 : 2)) {
        this.swing = this.swing === 1 ? 2 : 0;
        this.swingTicks = 0;
      }
      if (this.charlie && ++this.charlieTicks > 5) {
        this.charlie = this.charlie === 1 ? 2 : 0;
        this.charlieTicks = 0;
      }

      const n = this.tick;
      // Keep the original tick thresholds and per-tick random serve odds.
      if (this.charlie === 0 && this.lastServe < n) {
        this.lastServe = n + 30;
        let force = false, chance = 0;
        if (n > 1200) { force = this.activeBalls <= 5; chance = 69; }
        else if (n >= 900) chance = 99;
        else if (n >= 600) { force = this.activeBalls <= 2; chance = 49; }
        else if (n >= 200) { force = this.activeBalls <= 1; chance = 19; }
        if (force || (chance && this.random() * 1000 < chance)) this.spawn();
      }

      let returnChance = 0;
      if (n > 1201) returnChance = 29;
      else if (n >= 901 && n <= 1200) returnChance = 24;
      else if (n >= 601 && n <= 900) returnChance = 14;
      else if (n >= 201 && n <= 300) returnChance = 19;
      if (n < 200) this.lucyReady = false;
      else if (returnChance && this.random() * 1000 < returnChance) {
        this.lucyReady = true;
        this.lastServe = n;
      }

      let extraServe = false;
      for (const ball of this.balls) {
        ball.n++;
        const [dx, dy, gravity] = PATHS[ball.type];
        ball.x += dx;
        ball.y = qbInteger(ball.y + dy + ball.n * ball.n / gravity);

        const incoming = ball.type <= 5 || ball.type > 20;
        const lane = ball.type > 20 ? ball.type - 20 : ball.type;
        if (incoming && ball.x > 225 && ball.x < 249 && lane === this.stage && this.swing === 1) {
          const lucyReturn = ball.type > 20;
          ball.type += lucyReturn ? -10 : 10;
          ball.n = 0;
          this.score += lucyReturn ? 3 : 2;
          this.events.push({ type: "hit", points: lucyReturn ? 3 : 2, x: ball.x, y: ball.y });
          if (!lucyReturn && this.charlie === 0) {
            if (n < 300 || (n > 301 && n < 600 && this.random() < 0.49)) extraServe = true;
          }
        }

        if (ball.x > 307) {
          this.lives--;
          this.balls = [];
          this.missTicks = 8;
          this.events.push({ type: "miss" });
          if (this.lives === 0) {
            this.status = "over";
            this.events.push({ type: "over", score: this.score });
          } else this.spawn();
          return this.events;
        }
        if (ball.x < 20 && ball.type > 10) ball.type = 0;
        else if (ball.x < 54 && ball.type > 10 && ball.type < 20 && this.lucyReady) {
          // Deliberately retain n: Lucy's original paths continue the ball age.
          ball.type += 10;
          this.lucyReady = false;
          this.events.push({ type: "lucy" });
        }
      }
      this.balls = this.balls.filter(ball => ball.type !== 0);
      if (extraServe || this.balls.length === 0) this.spawn();
      return this.events;
    }
  }
  const api = { Game, TICK_MS, STAGES, PATHS, qbInteger };
  if (typeof module !== "undefined" && module.exports) module.exports = api;
  else root.SnoopyEngine = api;
})(globalThis);
