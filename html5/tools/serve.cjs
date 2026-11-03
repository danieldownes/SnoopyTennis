"use strict";
const http = require("node:http");
const fs = require("node:fs");
const path = require("node:path");
const root = path.resolve(__dirname, "..");
const port = Number(process.env.PORT || 4173);
const types = { ".html": "text/html; charset=utf-8", ".css": "text/css; charset=utf-8",
  ".js": "text/javascript; charset=utf-8", ".png": "image/png", ".mid": "audio/midi" };
const server = http.createServer((req, res) => {
  let file;
  try {
    const pathname = decodeURIComponent(new URL(req.url, "http://localhost").pathname);
    file = path.resolve(root, "." + (pathname === "/" ? "/index.html" : pathname));
  } catch (_) { res.writeHead(400); res.end("Bad request"); return; }
  if (!file.startsWith(root + path.sep)) { res.writeHead(403); res.end("Forbidden"); return; }
  fs.readFile(file, (error, content) => {
    if (error) { res.writeHead(404); res.end("Not found"); return; }
    res.writeHead(200, { "Content-Type": types[path.extname(file)] || "application/octet-stream",
      "Cache-Control": "no-cache" });
    res.end(content);
  });
});
server.listen(port, "127.0.0.1", () => console.log(`Snoopy Tennis: http://127.0.0.1:${port}`));
server.on("error", error => { console.error(error.message); process.exitCode = 1; });
