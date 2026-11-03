/* SCREEN 12 menu and scrolling About/Help, from STennis.BAS. */
(function (root) {
  "use strict";
  const LABELS = Object.freeze(["Start Game", "About/Help", "Exit"]);
  const SCROLL_SPEED = 32; // Readable, hardware-independent pixels per second.

  function wrapSelection(index) { return ((index % LABELS.length) + LABELS.length) % LABELS.length; }

  function aboutLayout(lines, elapsed) {
    // The source shifts two pixels per pass, prints at LOCATE 26 (y=400),
    // inserts the first line on pass 9, and subsequent lines every 8 passes.
    const distance = Math.floor(Math.max(0, elapsed) * SCROLL_SPEED / 2) * 2;
    const visible = [];
    for (let i = 0; i < lines.length; i++) {
      const insertedAt = 18 + i * 16;
      if (distance < insertedAt) break;
      const y = 400 - (distance - insertedAt);
      if (y > -16 && y < 480) visible.push({ text: lines[i], y });
    }
    // Let the last lines leave the screen before returning to the menu.
    return { distance, visible, finished: distance >= 418 + lines.length * 16 };
  }

  class OriginalMenu {
    constructor(canvas, title, data) {
      this.canvas = canvas;
      this.ctx = canvas.getContext("2d", { alpha: false });
      this.ctx.imageSmoothingEnabled = false;
      this.title = title;
      this.lines = data.lines;
      this.font = Uint8Array.from(atob(data.font), char => char.charCodeAt(0));
      this.snapshot = document.createElement("canvas");
      this.snapshot.width = 640; this.snapshot.height = 480;
      this.selection = 0;
      this.colors = [18, 18, 18];
      this.show("menu");
    }

    show(view) {
      if (view === "about") {
        // The original scroll starts with the menu still on screen.
        this.drawMenu();
        this.snapshot.getContext("2d").drawImage(this.canvas, 0, 0);
      }
      this.view = view;
      this.elapsed = 0;
      this.paused = false;
      if (view === "menu") { this.selection = 0; this.colors = [18, 18, 18]; }
    }

    choose(index) { this.selection = wrapSelection(index); }

    bitmapText(text, x, y, color = "#fff") {
      this.ctx.fillStyle = color;
      for (let index = 0; index < text.length; index++) {
        const glyph = (text.charCodeAt(index) & 255) * 16;
        for (let row = 0; row < 16; row++)
          for (let col = 0; col < 8; col++)
            if (this.font[glyph + row] & (128 >> col))
              this.ctx.fillRect(x + index * 8 + col, y + row, 1, 1);
      }
    }

    circle(cx, cy, radius, filled) {
      const ctx = this.ctx;
      if (filled) {
        for (let y = -radius; y <= radius; y++) {
          const dx = Math.floor(Math.sqrt(radius * radius - y * y));
          ctx.fillRect(cx - dx, cy + y, dx * 2 + 1, 1);
        }
        return;
      }
      let x = radius, y = 0, error = 1 - radius;
      while (x >= y) {
        for (const [dx, dy] of [[x,y],[y,x],[-y,x],[-x,y],[-x,-y],[-y,-x],[y,-x],[x,-y]])
          ctx.fillRect(cx + dx, cy + dy, 1, 1);
        y++;
        if (error < 0) error += 2 * y + 1;
        else { x--; error += 2 * (y - x) + 1; }
      }
    }

    neatText(text, y, size, color, filled = false) {
      const x = (640 - text.length * 8 * size) / 2;
      this.ctx.fillStyle = color;
      for (let index = 0; index < text.length; index++) {
        const glyph = (text.charCodeAt(index) & 255) * 16;
        for (let row = 0; row < 16; row++)
          for (let col = 0; col < 8; col++)
            if (this.font[glyph + row] & (128 >> col))
              this.circle(Math.round(x + (index * 8 + col) * size - size / 2),
                Math.round(y + row * size - size / 2), Math.round(size / 2), filled);
      }
    }

    clear() { this.ctx.fillStyle = "#000"; this.ctx.fillRect(0, 0, 640, 480); }

    drawMenu() {
      this.clear();
      this.ctx.drawImage(this.title, 0, 0);
      LABELS.forEach((label, i) => {
        const shade = Math.round(this.colors[i] / 63 * 255);
        this.neatText(label, 200 + i * 80, 4, `rgb(${shade},${shade},${shade})`);
      });
    }

    drawExit() {
      this.clear();
      this.neatText("Snoopy Tennis v2.00.10", 50, 3, "#fff", true);
      this.neatText("By Daniel Vincent", 100, 2, "#fff", true);
      this.neatText("Comments/suggestions:-", 175, 3, "#fff", true);
      this.neatText("Daniel@vincent99.freeserve.co.uk", 225, 2, "#fff", true);
      this.neatText("Updates/info", 300, 3, "#fff", true);
      this.neatText("WWW.vincent99.freeserve.co.uk", 350, 3, "#fff", true);
      this.bitmapText("(When there click on topics then Extravagaza DAN and then Snoopy Tennis)", 0, 384);
      this.bitmapText("Press any key to return to the menu", 0, 432);
    }

    render(delta) {
      if (!this.paused) this.elapsed += delta / 1000;
      if (this.view === "menu") {
        this.colors = this.colors.map((value, i) => {
          const target = i === this.selection ? 60 : 20;
          const step = delta / 2;
          return value < target ? Math.min(target, value + step) : Math.max(target, value - step);
        });
        this.drawMenu();
      } else if (this.view === "about") {
        const layout = aboutLayout(this.lines, this.elapsed);
        this.clear();
        this.ctx.drawImage(this.snapshot, 0, -layout.distance);
        for (const line of layout.visible) {
          this.ctx.fillStyle = "#000";
          this.ctx.fillRect(0, line.y, line.text.length * 8, 16);
          this.bitmapText(line.text, 0, line.y);
        }
        return layout.finished;
      } else this.drawExit();
      return false;
    }
  }
  const api = { OriginalMenu, LABELS, SCROLL_SPEED, aboutLayout, wrapSelection };
  if (typeof module !== "undefined" && module.exports) module.exports = api;
  else root.SnoopyMenu = api;
})(globalThis);
