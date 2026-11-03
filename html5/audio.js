(function (root) {
  "use strict";
  // Decode the original format-1 MIDI into a shared, tempo-correct timeline.
  function parseMidi(bytes) {
    const data = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
    let pos = 0;
    const u16 = () => { const v = data.getUint16(pos); pos += 2; return v; };
    const u32 = () => { const v = data.getUint32(pos); pos += 4; return v; };
    const tag = () => String.fromCharCode(...bytes.slice(pos, pos += 4));
    const variable = () => {
      let value = 0, byte;
      do { byte = bytes[pos++]; value = (value << 7) | (byte & 127); } while (byte & 128);
      return value;
    };
    if (tag() !== "MThd") throw new Error("Invalid MIDI header");
    const headerLength = u32(), headerEnd = pos + headerLength;
    const format = u16(), tracks = u16(), division = u16();
    if (format > 1 || division & 0x8000) throw new Error("Unsupported MIDI timing");
    pos = headerEnd;
    const events = [];
    let lastTick = 0;
    for (let track = 0; track < tracks; track++) {
      if (tag() !== "MTrk") throw new Error("Invalid MIDI track");
      const length = u32(), end = pos + length;
      let tick = 0, running = 0;
      while (pos < end) {
        tick += variable();
        lastTick = Math.max(lastTick, tick);
        let status = bytes[pos];
        if (status & 128) pos++;
        else status = running;
        if (status === 0xff) {
          const type = bytes[pos++], size = variable();
          if (type === 0x51 && size === 3)
            events.push({ tick, tempo: bytes[pos] * 65536 + bytes[pos + 1] * 256 + bytes[pos + 2] });
          pos += size;
        } else if (status === 0xf0 || status === 0xf7) {
          const size = variable(); pos += size;
        } else {
          if (status < 0x80 || status > 0xef) throw new Error("Invalid MIDI status");
          running = status;
          const kind = status >> 4, channel = status & 15, a = bytes[pos++];
          const b = (kind === 12 || kind === 13) ? 0 : bytes[pos++];
          events.push({ tick, kind, channel, a, b });
        }
      }
      pos = end;
    }
    events.sort((a, b) => a.tick - b.tick);
    const notes = [], active = new Map(), sustained = Array.from({ length: 16 }, () => []);
    const programs = Array(16).fill(0), volume = Array(16).fill(100), pedal = Array(16).fill(false);
    const pan = Array(16).fill(64), reverb = Array(16).fill(40), chorus = Array(16).fill(0);
    let tick = 0, seconds = 0, tempo = 500000;
    const finish = (note, time) => { note.duration = Math.max(0.04, time - note.time); notes.push(note); };
    for (const event of events) {
      seconds += (event.tick - tick) * tempo / division / 1e6;
      tick = event.tick;
      if (event.tempo) { tempo = event.tempo; continue; }
      const { channel, kind, a, b } = event;
      if (kind === 12) programs[channel] = a;
      if (kind === 11 && a === 7) volume[channel] = b;
      if (kind === 11 && a === 10) pan[channel] = b;
      if (kind === 11 && a === 91) reverb[channel] = b;
      if (kind === 11 && a === 93) chorus[channel] = b;
      if (kind === 11 && a === 64) {
        pedal[channel] = b >= 64;
        if (!pedal[channel]) {
          sustained[channel].forEach(note => finish(note, seconds));
          sustained[channel] = [];
        }
      }
      const key = channel * 128 + a;
      if (kind === 9 && b > 0) {
        if (active.has(key)) finish(active.get(key), seconds);
        active.set(key, { time: seconds, pitch: a, channel, program: programs[channel],
          velocity: b / 127 * volume[channel] / 127, rawVelocity: b / 127,
          volume: volume[channel] / 127, pan: Math.max(-1, (pan[channel] - 64) / 63),
          reverb: reverb[channel] / 127, chorus: chorus[channel] / 127 });
      } else if (kind === 8 || (kind === 9 && b === 0)) {
        const note = active.get(key);
        if (note) {
          if (pedal[channel]) sustained[channel].push(note);
          else finish(note, seconds);
          active.delete(key);
        }
      }
    }
    seconds += (lastTick - tick) * tempo / division / 1e6;
    active.forEach(note => finish(note, seconds));
    sustained.flat().forEach(note => finish(note, seconds));
    notes.sort((a, b) => a.time - b.time);
    return { notes, duration: Math.max(seconds, ...notes.map(n => n.time + n.duration)) + 0.5 };
  }

  class AudioEngine {
    constructor() {
      this.enabled = true;
      this.musicEnabled = true;
      this.paused = false;
      this.voices = new Set();
      this.drumGroups = new Map();
      this.timer = null;
    }
    async unlock() {
      try {
        if (!this.context) {
          const Context = root.AudioContext || root.webkitAudioContext;
          if (!Context) return;
          this.context = new Context();
          this.master = this.context.createGain();
          this.master.gain.value = this.enabled ? 0.5 : 0;
          this.master.connect(this.context.destination);
          const bank = root.SNOOPY_MIDI_BANK || root.SNOOPY_WINDOWS_MIDI;
          if (bank && root.SnoopySamples) {
            this.sampleBank = new root.SnoopySamples.SampleBank(this.context, bank);
            this.createEffects();
          }
          const bytes = Uint8Array.from(atob(root.SNOOPY_MIDI), c => c.charCodeAt(0));
          this.song = parseMidi(bytes);
        }
        if (!this.paused) await this.context.resume();
        if (this.musicEnabled && !this.timer) this.startMusic();
      } catch (error) {
        console.info("Audio is unavailable; the game can still be played.", error.message);
      }
    }
    setEnabled(value) {
      this.enabled = value;
      if (this.master) this.master.gain.setTargetAtTime(value ? 0.5 : 0, this.context.currentTime, 0.02);
    }
    setMusic(value) {
      this.musicEnabled = value;
      if (value) this.unlock();
      else this.stopMusic();
    }
    setPaused(value) {
      this.paused = value;
      if (!this.context) return;
      (value ? this.context.suspend() : this.context.resume()).catch(() => {});
    }
    startMusic() {
      if (!this.context || !this.song) return;
      this.songStart = this.context.currentTime + 0.1;
      this.nextNote = 0;
      const schedule = () => {
        const horizon = this.context.currentTime + 0.18;
        while (this.nextNote < this.song.notes.length &&
          this.songStart + this.song.notes[this.nextNote].time <= horizon) {
          const note = this.song.notes[this.nextNote++];
          this.playNote(note, Math.max(this.context.currentTime, this.songStart + note.time));
        }
        if (this.nextNote === this.song.notes.length && horizon >= this.songStart + this.song.duration) {
          this.songStart += this.song.duration;
          this.nextNote = 0;
        }
      };
      schedule();
      this.timer = setInterval(schedule, 50);
    }
    stopMusic() {
      clearInterval(this.timer);
      this.timer = null;
      for (const voice of this.voices) { try { voice.stop(); } catch (_) {} }
      this.voices.clear();
      this.drumGroups.clear();
    }
    createEffects() {
      const ctx = this.context;
      this.reverb = ctx.createConvolver();
      const impulse = ctx.createBuffer(2, Math.floor(ctx.sampleRate * 1.2), ctx.sampleRate);
      let seed = 4721;
      for (let channel = 0; channel < 2; channel++) {
        const pcm = impulse.getChannelData(channel);
        for (let i = 0; i < pcm.length; i++) {
          seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
          pcm[i] = (seed / 2 ** 31 - 1) * (1 - i / pcm.length) ** 3;
        }
      }
      this.reverb.buffer = impulse;
      this.reverb.connect(this.master);
      this.chorus = ctx.createDelay(0.1);
      this.chorus.delayTime.value = 0.019;
      const lfo = ctx.createOscillator(), depth = ctx.createGain();
      lfo.frequency.value = 0.8; depth.gain.value = 0.0025;
      lfo.connect(depth); depth.connect(this.chorus.delayTime);
      this.chorus.connect(this.master); lfo.start();
      this.chorusLfo = lfo;
    }
    playNote(note, when) {
      if (this.sampleBank) {
        const voice = this.sampleBank.createVoice(note, when, this.master, this.reverb, this.chorus);
        if (voice) {
          if (voice.group) {
            const previous = this.drumGroups.get(voice.group);
            if (previous) {
              previous.gain.gain.cancelAndHoldAtTime(when);
              previous.gain.gain.setTargetAtTime(0.00001, when, 0.003);
              try { previous.source.stop(when + 0.015); } catch (_) {}
            }
            this.drumGroups.set(voice.group, voice);
          }
          this.voices.add(voice.source);
          const cleanup = voice.source.onended;
          voice.source.onended = () => {
            cleanup(); this.voices.delete(voice.source);
            if (this.drumGroups.get(voice.group) === voice) this.drumGroups.delete(voice.group);
          };
          return;
        }
      }
      const ctx = this.context, osc = ctx.createOscillator(), gain = ctx.createGain();
      const percussion = note.channel === 9;
      const bass = note.program >= 32 && note.program <= 39;
      osc.type = percussion ? "triangle" : bass ? "triangle" : note.program >= 56 ? "sawtooth" : "sine";
      osc.frequency.value = percussion ? (note.pitch < 40 ? 85 : 330) : 440 * 2 ** ((note.pitch - 69) / 12);
      const duration = percussion ? 0.08 : Math.min(note.duration, 4);
      const level = Math.max(0.001, note.velocity * (percussion ? 0.06 : bass ? 0.1 : 0.065));
      gain.gain.setValueAtTime(0, when);
      gain.gain.linearRampToValueAtTime(level, when + 0.008);
      gain.gain.exponentialRampToValueAtTime(Math.max(0.001, level * 0.35), when + Math.max(0.02, duration));
      gain.gain.linearRampToValueAtTime(0, when + duration + 0.08);
      osc.connect(gain); gain.connect(this.master);
      osc.start(when); osc.stop(when + duration + 0.1);
      this.voices.add(osc);
      osc.onended = () => { this.voices.delete(osc); osc.disconnect(); gain.disconnect(); };
    }
    effect(type) {
      if (!this.context || !this.enabled || this.paused) return;
      const ctx = this.context, osc = ctx.createOscillator(), gain = ctx.createGain(), now = ctx.currentTime;
      const miss = type === "miss";
      osc.type = "square";
      osc.frequency.setValueAtTime(miss ? 300 : type === "lucy" ? 900 : 640, now);
      osc.frequency.exponentialRampToValueAtTime(miss ? 100 : 280, now + 0.09);
      gain.gain.setValueAtTime(0.045, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + (miss ? 0.25 : 0.08));
      osc.connect(gain); gain.connect(this.master);
      osc.start(); osc.stop(now + 0.3);
      osc.onended = () => { osc.disconnect(); gain.disconnect(); };
    }
  }
  const api = { AudioEngine, parseMidi };
  if (typeof module !== "undefined" && module.exports) module.exports = api;
  else root.SnoopyAudio = api;
})(globalThis);
