(async function () {
  "use strict";
  const $ = id => document.getElementById(id);
  const canvas = $("game"), overlay = $("overlay"), startButton = $("start");
  const game = new SnoopyEngine.Game();
  game.balls = []; game.charlie = 0;
  const audio = new SnoopyAudio.AudioEngine();
  const midiBank = globalThis.SNOOPY_MIDI_BANK || globalThis.SNOOPY_WINDOWS_MIDI;
  if (midiBank) {
    $("music").title = `Original MIDI tune · ${midiBank.name} piano, bass and drums`;
    $("audio-credit").textContent = `Music uses ${midiBank.name}: ${midiBank.source}. Piano, fretless bass and drums are sampled; the original MIDI score is unchanged. HD graphics are reserved for a future edition.`;
  }
  const renderer = new SnoopyGraphics.original(canvas);
  const legacyCanvas = $("original-menu");
  const menuButtons = [...document.querySelectorAll("[data-menu]")];
  let legacy = null, screen = "menu", uiScreen = "";
  const help = $("help");
  const touchButtons = [...document.querySelectorAll("[data-action]")];
  let loaded = false, best = 0, accumulator = 0, previousTime = 0, overlayState = "";
  let helpWasPlaying = false, lastMoveTime = 0, needsResultFocus = false, pauseLabel = "";
  try { best = Math.max(0, Number.parseInt(localStorage.getItem("snoopy-tennis-best"), 10) || 0); } catch (_) {}
  const formatScore = value => String(value).padStart(4, "0");
  $("best").textContent = formatScore(best);

  function announce(message) { $("announcement").textContent = message; }
  function focusGame() { if (game.status === "playing") canvas.focus({ preventScroll: true }); }
  function sync() {
    const inGame = screen === "game";
    $("scorebar").hidden = !inGame;
    canvas.hidden = !inGame;
    legacyCanvas.hidden = inGame;
    $("menu-actions").hidden = screen !== "menu";
    $("original-transcript").hidden = screen !== "about";
    $("menu-back").hidden = screen === "menu";
    $("menu-back").disabled = !loaded;
    $("playfield").dataset.screen = screen;
    $("arcade").classList.toggle("legacy-mode", !inGame);
    if (uiScreen !== screen) {
      const labels = { menu: "MAIN MENU", about: "ABOUT / HELP · ANY KEY TO RETURN", exit: "ANY KEY TO RETURN", game: "PIXEL PERFECT" };
      $("resolution").innerHTML = `<span class="live-dot"></span> ORIGINAL ${inGame ? "320 × 200" : "640 × 480"} <span class="toolbar-divider">/</span> ${labels[screen]}`;
      legacyCanvas.setAttribute("aria-label", screen === "menu"
        ? "Original Snoopy Tennis menu. Up and Down to choose. Enter to select."
        : screen === "about" ? "Original scrolling About/Help and credits. Press any key or tap to return to the menu."
        : "Original exit credits. Press any key or tap to return to the menu.");
      legacyCanvas.textContent = screen === "menu" ? "Original Snoopy Tennis menu: Start Game, About/Help, Exit."
        : screen === "about" ? "Original instructions and credits scroll upward."
        : "Snoopy Tennis v2.00.10. By Daniel Vincent.";
      uiScreen = screen;
    }
    const scoreText = formatScore(game.score);
    if ($("score").textContent !== scoreText) $("score").textContent = scoreText;
    if (game.score > best) {
      best = game.score;
      $("best").textContent = formatScore(best);
      try { localStorage.setItem("snoopy-tennis-best", String(best)); } catch (_) {}
    }
    [...$("lives").children].forEach((life, i) => life.classList.toggle("lost", i >= game.lives));
    $("lives").setAttribute("aria-label", `${game.lives} ${game.lives === 1 ? "life" : "lives"} remaining`);
    const states = { ready: "READY", playing: "IN PLAY", paused: "PAUSED", over: "GAME OVER" };
    $("status-text").textContent = states[game.status];
    $("status").dataset.state = game.status;
    $("pause").disabled = screen !== "about" && (!inGame || !["playing", "paused"].includes(game.status));
    $("pause").title = screen === "about" ? "Pause or resume the scrolling text" : "Pause or resume (Esc)";
    const nextPauseLabel = (screen === "about" ? legacy?.paused : game.status === "paused") ? "resume" : "pause";
    if (pauseLabel !== nextPauseLabel) {
      $("pause").innerHTML = nextPauseLabel === "resume" ? "▶ <span>Resume</span>" : "Ⅱ <span>Pause</span>";
      pauseLabel = nextPauseLabel;
    }
    touchButtons.forEach(button => button.disabled = !inGame || game.status !== "playing");
    const visible = inGame && game.status !== "playing";
    overlay.hidden = !visible;
    if (visible && overlayState !== game.status) {
      const content = {
        ready: ["ORIGINAL EDITION", "Good day for a rally.", "Climb the tree. Time your swing.<br>Keep Charlie Brown’s tennis balls in play.", "Start game  ↗", "or press Enter to start"],
        paused: ["TAKE A BREATHER", "The tree can wait.", "Your rally is right where you left it.<br>Ready when you are.", "Resume game  ↗", "or press Esc / Enter to resume"],
        over: ["THAT’S THE RALLY", "One more game?", `You scored <strong>${game.score} points</strong>.<br>${game.score > 0 && game.score === best ? "A personal best. Nicely played!" : "There’s always another ball to return."}`, "Play again  ↗", "or press Enter to play again"],
      }[game.status];
      $("panel-kicker").textContent = content[0];
      $("panel-title").textContent = content[1];
      $("panel-description").innerHTML = content[2];
      startButton.textContent = loaded ? content[3] : "Loading artwork…";
      $("start-hint").textContent = content[4];
    }
    overlayState = game.status;
  }

  function start() {
    if (!loaded || help.open) return;
    if (game.status === "playing") return;
    screen = "game";
    if (game.status === "paused") game.pause();
    else game.reset();
    accumulator = 0;
    previousTime = performance.now();
    audio.setPaused(false);
    audio.unlock();
    sync(); focusGame();
    announce("Game started. Three lives. Up and Down to climb. Space to swing.");
  }

  function pause() {
    if (screen === "about") {
      legacy.paused = !legacy.paused;
      audio.setPaused(legacy.paused);
      sync();
      announce(legacy.paused ? "Scrolling text paused." : "Scrolling text resumed.");
      return;
    }
    if (!["playing", "paused"].includes(game.status)) return;
    game.pause();
    accumulator = 0;
    audio.setPaused(game.status === "paused");
    sync();
    if (game.status === "paused") startButton.focus({ preventScroll: true });
    else focusGame();
    announce(game.status === "paused" ? "Game paused." : "Game resumed.");
  }

  function action(name) {
    if (screen !== "game" || game.status !== "playing") return;
    if (name === "up") game.move(1);
    if (name === "down") game.move(-1);
    if (name === "hit") game.hit();
    renderer.render(game);
  }

  startButton.addEventListener("click", start);
  function selectMenu(index, focus = false) {
    if (!loaded) return;
    legacy.choose(index);
    menuButtons.forEach((button, i) => {
      if (i === legacy.selection) button.setAttribute("aria-current", "true");
      else button.removeAttribute("aria-current");
    });
    if (focus) menuButtons[legacy.selection].focus({ preventScroll: true });
  }
  function showLegacy(view = "menu") {
    if (!loaded) return;
    game.quit();
    screen = view;
    accumulator = 0;
    needsResultFocus = false;
    legacy.show(view);
    audio.setPaused(false);
    audio.unlock();
    sync();
    if (view === "menu") {
      selectMenu(0, true);
      announce("Original menu. Up and Down to choose. Enter to select.");
    } else {
      legacyCanvas.focus({ preventScroll: true });
      announce(view === "about" ? "Original About and Help. Text scrolls upward. Press any key or tap to return; use Pause to stop the scroll."
        : "Original exit screen. Press any key or tap to return.");
    }
  }
  function activateMenu() {
    if (!loaded || screen !== "menu") return;
    if (legacy.selection === 0) start();
    else showLegacy(legacy.selection === 1 ? "about" : "exit");
  }
  menuButtons.forEach(button => {
    const index = Number(button.dataset.menu);
    button.addEventListener("pointerenter", () => selectMenu(index));
    button.addEventListener("focus", () => selectMenu(index));
    button.addEventListener("click", () => { selectMenu(index); activateMenu(); });
  });
  $("menu-back").addEventListener("click", () => showLegacy());
  legacyCanvas.addEventListener("click", () => { if (screen === "about" || screen === "exit") showLegacy(); });
  $("pause").addEventListener("click", pause);
  $("sound").addEventListener("click", () => {
    audio.setEnabled(!audio.enabled);
    $("sound").setAttribute("aria-pressed", String(audio.enabled));
    $("sound").innerHTML = `${audio.enabled ? "◖))" : "◖×"} <span>Sound ${audio.enabled ? "on" : "off"}</span>`;
    audio.unlock(); focusGame();
  });
  $("music").addEventListener("click", () => {
    audio.setMusic(!audio.musicEnabled);
    $("music").setAttribute("aria-pressed", String(audio.musicEnabled));
    $("music").innerHTML = `♫ <span>Music ${audio.musicEnabled ? "on" : "off"}</span>`;
    focusGame();
  });
  const fullscreenSupported = Boolean($("arcade").requestFullscreen && document.fullscreenEnabled);
  $("fullscreen").hidden = !fullscreenSupported;
  $("fullscreen").addEventListener("click", async () => {
    try {
      if (document.fullscreenElement) await document.exitFullscreen();
      else await $("arcade").requestFullscreen();
      focusGame();
    } catch (_) { announce("Full screen is unavailable in this browser."); }
  });

  touchButtons.forEach(button => {
    // Native click supports touch, pointer, keyboard and assistive technology.
    button.addEventListener("click", () => { action(button.dataset.action); focusGame(); });
  });

  $("help-open").addEventListener("click", () => {
    helpWasPlaying = game.status === "playing";
    if (helpWasPlaying) pause();
    help.showModal();
  });
  $("help-close").addEventListener("click", () => help.close());
  help.addEventListener("click", event => { if (event.target === help) {
    const rect = help.getBoundingClientRect();
    if (event.clientX < rect.left || event.clientX > rect.right || event.clientY < rect.top || event.clientY > rect.bottom) help.close();
  } });
  help.addEventListener("close", () => {
    if (helpWasPlaying && game.status === "paused" && !document.hidden) start();
    helpWasPlaying = false;
  });

  document.addEventListener("keydown", event => {
    if (!loaded || help.open || event.ctrlKey || event.metaKey || event.altKey) return;
    const target = event.target;
    if (target.isContentEditable || ["INPUT", "TEXTAREA", "SELECT"].includes(target.tagName)) return;
    const key = event.key.toLowerCase();
    if (screen === "about" || screen === "exit") {
      if (key === "tab" || ((key === "enter" || key === " ") && target.closest("button,a"))) return;
      event.preventDefault();
      if (!event.repeat) showLegacy();
      return;
    }
    if (screen === "menu") {
      if (key === "arrowup" || key === "arrowdown") {
        event.preventDefault();
        selectMenu(legacy.selection + (key === "arrowup" ? -1 : 1), true);
        audio.unlock();
      } else if (key === "enter" && (!target.closest("button,a") || target.closest("#menu-actions"))) {
        event.preventDefault();
        if (!event.repeat) activateMenu();
      }
      return;
    }
    if (key === "escape") {
      if (event.repeat) return;
      event.preventDefault(); pause(); return;
    }
    // Let focused buttons keep their native Space / Enter activation.
    if ((key === " " || key === "enter") && target.closest("button,a")) return;
    if (key === "enter" && game.status !== "playing") {
      event.preventDefault(); if (!event.repeat) start(); return;
    }
    if (key === "q" && ["playing", "paused", "over"].includes(game.status)) {
      event.preventDefault();
      showLegacy(); return;
    }
    if (game.status !== "playing") return;
    if (["arrowup", "p", "arrowdown", "l"].includes(key)) {
      event.preventDefault();
      const now = performance.now();
      if (!event.repeat || now - lastMoveTime >= SnoopyEngine.TICK_MS) {
        action(key === "arrowup" || key === "p" ? "up" : "down");
        lastMoveTime = now;
      }
    } else if (event.code === "Space" || key === " ") {
      event.preventDefault(); action("hit");
    }
  });

  function autoPause() {
    if (game.status === "playing") pause();
    if (screen === "about") { legacy.paused = true; sync(); }
    audio.setPaused(true);
  }
  function userPaused() {
    return screen === "about" ? Boolean(legacy?.paused) : screen === "game" && game.status === "paused";
  }
  document.addEventListener("visibilitychange", () => {
    if (document.hidden) autoPause();
    else if (!userPaused()) audio.setPaused(false);
  });
  window.addEventListener("blur", autoPause);
  window.addEventListener("focus", () => { if (!userPaused() && !document.hidden) audio.setPaused(false); });
  window.addEventListener("pagehide", () => audio.stopMusic());

  function processEvents(events) {
    for (const event of events) {
      if (["hit", "lucy", "miss"].includes(event.type)) audio.effect(event.type);
      if (event.type === "hit") {
        const flash = $("point-flash");
        flash.textContent = `+${event.points}`;
        flash.classList.remove("show");
        void flash.offsetWidth;
        flash.classList.add("show");
      }
      if (event.type === "miss") announce(`${game.lives} ${game.lives === 1 ? "life" : "lives"} remaining.`);
      if (event.type === "over") {
        announce(`Game over. You scored ${game.score} points.`);
        needsResultFocus = true;
      }
    }
  }

  function frame(time) {
    const elapsed = previousTime ? Math.min(time - previousTime, 270) : 0;
    previousTime = time;
    if (screen === "game" && game.status === "playing") {
      accumulator += elapsed;
      let stepped = false;
      while (accumulator >= SnoopyEngine.TICK_MS && game.status === "playing") {
        processEvents(game.step());
        accumulator -= SnoopyEngine.TICK_MS;
        stepped = true;
      }
      if (stepped) sync();
      if (needsResultFocus) {
        startButton.focus({ preventScroll: true });
        needsResultFocus = false;
      }
    }
    if (screen === "game") renderer.render(game);
    else if (legacy.render(document.hidden || help.open ? 0 : elapsed)) showLegacy();
    requestAnimationFrame(frame);
  }

  sync();
  try {
    await renderer.load();
    legacy = new SnoopyMenu.OriginalMenu(legacyCanvas, renderer.images.title, SNOOPY_MENU_DATA);
    $("original-about-text").textContent = SNOOPY_MENU_DATA.lines.join("\n");
    loaded = true;
    menuButtons.forEach(button => button.disabled = false);
    selectMenu(0);
    startButton.disabled = false;
    overlayState = ""; sync();
    legacy.render(0);
    requestAnimationFrame(frame);
  } catch (error) {
    screen = "game";
    sync();
    $("panel-title").textContent = "The artwork couldn’t load.";
    $("panel-description").textContent = "Keep the assets folder beside index.html, then refresh the page.";
    startButton.textContent = "Artwork unavailable";
    announce(error.message);
    console.error(error);
  }
})();
