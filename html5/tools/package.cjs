"use strict";
// Produce a portable distribution with all art, music, styles, and code embedded.
const fs = require("node:fs");
const path = require("node:path");
const root = path.resolve(__dirname, "..");
const windowsLocal = process.argv.includes("--windows-local");
const read = file => fs.readFileSync(path.join(root, file), "utf8");
const images = {};
for (const file of fs.readdirSync(path.join(root, "assets"))) {
  if (file.endsWith(".png")) images[path.basename(file, ".png")] =
    "data:image/png;base64," + fs.readFileSync(path.join(root, "assets", file)).toString("base64");
}
let html = read("index.html")
  .replace(/<link rel="stylesheet" href="styles\.css">/, () => `<style>\n${read("styles.css")}\n</style>`)
  .replace(/\s*<script defer src="[^"]+"><\/script>/g, "")
  .replace(/(src|href)="assets\/([^"]+)\.png"/g, (_, attribute, name) => `${attribute}="${images[name]}"`);
const bankScript = windowsLocal ? "assets/windows-midi-data.js" : "assets/gm-midi-data.js";
const scripts = ["assets/music-data.js", "assets/menu-data.js", bankScript, "engine.js", "graphics.js", "audio.js", "sample-bank.js", "menu.js", "app.js"];
let code = "globalThis.SNOOPY_IMAGES = " + JSON.stringify(images) + ";\n" + scripts.map(read).join("\n");
code = code.replace(/<\/script/gi, "<\\/script");
html = html.replace("</body>", () => `<script>\n${code}\n</script>\n</body>`);
const output = path.join(root, "..", windowsLocal ? "SnoopyTennis-Windows-local.html" : "SnoopyTennis.html");
fs.writeFileSync(output, html);
if (!windowsLocal) {
  fs.mkdirSync(path.join(root, "dist"), { recursive: true });
  fs.writeFileSync(path.join(root, "dist", "index.html"), html);
}
console.log(`Standalone game: ${output} (${Buffer.byteLength(html).toLocaleString()} bytes)`);
