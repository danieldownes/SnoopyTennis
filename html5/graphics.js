(function (root) {
  "use strict";
  const ASSETS = ["background", "title", "snoopy-idle", "snoopy-hit", "snoopy-follow",
    "lucy-idle", "lucy-ready", "charlie-idle", "charlie-hit", "charlie-follow"];
  // A tiny bitmap HUD keeps letters on the same pixel grid as the DOS artwork.
  const FONT = {
    "0": [14,17,19,21,25,17,14], "1": [4,12,4,4,4,4,14],
    "2": [14,17,1,2,4,8,31], "3": [30,1,1,14,1,1,30],
    "4": [2,6,10,18,31,2,2], "5": [31,16,16,30,1,1,30],
    "6": [14,16,16,30,17,17,14], "7": [31,1,2,4,8,8,8],
    "8": [14,17,17,14,17,17,14], "9": [14,17,17,15,1,1,14],
    "S": [15,16,16,14,1,1,30], "C": [14,17,16,16,16,17,14],
    "O": [14,17,17,17,17,17,14], "R": [30,17,17,30,20,18,17],
    "E": [31,16,16,30,16,16,31], "L": [16,16,16,16,16,16,31],
    "I": [14,4,4,4,4,4,14], "V": [17,17,17,17,17,10,4],
    ":": [0,4,4,0,4,4,0], " ": [0,0,0,0,0,0,0],
  };
  function text(ctx, str, x, y, color) {
    ctx.fillStyle = color;
    for (const char of str) {
      const rows = FONT[char] || FONT[" "];
      for (let row = 0; row < 7; row++)
        for (let col = 0; col < 5; col++)
          if (rows[row] & (1 << (4 - col))) ctx.fillRect(x + col, y + row, 1, 1);
      x += 6;
    }
  }
  class OriginalRenderer {
    constructor(canvas) {
      this.canvas = canvas;
      this.ctx = canvas.getContext("2d", { alpha: false });
      this.ctx.imageSmoothingEnabled = false;
      this.images = {};
    }
    async load() {
      await Promise.all(ASSETS.map(name => new Promise((resolve, reject) => {
        const image = new Image();
        image.onload = () => { this.images[name] = image; resolve(); };
        image.onerror = () => reject(new Error(`Could not load original artwork: ${name}`));
        image.src = root.SNOOPY_IMAGES?.[name] || `assets/${name}.png`;
      })));
    }
    render(game) {
      const ctx = this.ctx;
      ctx.drawImage(this.images.background, 0, 0);
      const snoopy = ["idle", "hit", "follow"][game.swing];
      ctx.drawImage(this.images[`snoopy-${snoopy}`], 215, game.snoopyY);
      ctx.drawImage(this.images[game.lucyReady ? "lucy-ready" : "lucy-idle"], 20, 1);
      for (const ball of game.balls) {
        // Original concentric circles, centered six pixels into the ball sprite.
        for (let radius = 6; radius >= 0; radius--) {
          const shade = Math.round((31 - radius - 16) * 255 / 15);
          ctx.fillStyle = `rgb(${shade},${shade},${shade})`;
          const cx = ball.x + 6, cy = ball.y + 6;
          for (let y = -radius; y <= radius; y++) {
            const dx = Math.floor(Math.sqrt(radius * radius - y * y));
            ctx.fillRect(cx - dx, cy + y, dx * 2 + 1, 1);
          }
        }
      }
      const charlie = ["idle", "hit", "follow"][game.charlie];
      ctx.drawImage(this.images[`charlie-${charlie}`], 12, 143);
      ctx.fillStyle = "#000";
      ctx.fillRect(0, 0, 177, 10);
      text(ctx, `SCORE ${game.score}`, 3, 1, "#fff");
      text(ctx, `LIVES ${game.lives}`, 106, 1, "#fff");
      if (game.missTicks > 4) {
        ctx.fillStyle = "rgba(255, 40, 40, 0.18)";
        ctx.fillRect(0, 0, 320, 200);
      }
    }
  }
  // HD can implement this same load/render interface without changing the rules.
  root.SnoopyGraphics = { original: OriginalRenderer };
})(globalThis);
