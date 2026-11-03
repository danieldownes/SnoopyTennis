(function (root) {
  "use strict";
  const MIN_TIME = -2147483648;
  function timecents(value) {
    return value <= MIN_TIME + 1 ? 0 : Math.min(100, 2 ** (value / 65536 / 1200));
  }
  function gainFromAttenuation(value) { return 10 ** (value / 65536 / 200); }

  function regionFor(bank, note) {
    const regions = bank.instruments[note.channel === 9 ? "drums" : String(note.program)] || [];
    const velocity = Math.round((note.rawVelocity ?? note.velocity) * 127);
    return regions.find(region => note.pitch >= region.low && note.pitch <= region.high &&
      velocity >= region.velocityLow && velocity <= region.velocityHigh);
  }

  function envelope(region, note) {
    const destinations = new Map();
    for (const [source, control, destination, transform, scale] of region.art) {
      if (control !== 0 || transform !== 0 || ![0, 2, 3].includes(source)) continue;
      const amount = source === 0 ? 1 : source === 2 ? (note.rawVelocity ?? note.velocity) : note.pitch / 127;
      destinations.set(destination, (destinations.get(destination) || 0) + scale * amount);
    }
    return {
      attack: timecents(destinations.get(0x206) ?? MIN_TIME),
      decay: timecents(destinations.get(0x207) ?? MIN_TIME),
      release: timecents(destinations.get(0x209) ?? MIN_TIME),
      sustain: Math.max(0, Math.min(1, (destinations.get(0x20a) ?? 65536000) / 65536000)),
    };
  }

  class SampleBank {
    constructor(context, data) {
      this.context = context;
      this.data = data;
      this.buffers = new Map();
    }
    buffer(id) {
      if (this.buffers.has(id)) return this.buffers.get(id);
      const sample = this.data.samples[id];
      const bytes = Uint8Array.from(atob(sample.pcm), char => char.charCodeAt(0));
      const view = new DataView(bytes.buffer);
      const width = sample.bits / 8;
      const frames = bytes.length / width / sample.channels;
      const buffer = this.context.createBuffer(sample.channels, frames, sample.rate);
      for (let ch = 0; ch < sample.channels; ch++) {
        const output = buffer.getChannelData(ch);
        for (let i = 0; i < frames; i++) {
          const pos = (i * sample.channels + ch) * width;
          output[i] = width === 2 ? view.getInt16(pos, true) / 32768 : (bytes[pos] - 128) / 128;
        }
      }
      this.buffers.set(id, buffer);
      return buffer;
    }
    createVoice(note, when, destination, reverb, chorus) {
      const region = regionFor(this.data, note);
      if (!region) return null;
      const ctx = this.context, source = ctx.createBufferSource(), gain = ctx.createGain();
      const pan = ctx.createStereoPanner();
      source.buffer = this.buffer(region.wave);
      source.playbackRate.value = 2 ** ((note.pitch - region.root + region.fine / 100) / 12);
      const loop = region.loops[0];
      if (loop) {
        source.loop = true;
        source.loopStart = loop.start / source.buffer.sampleRate;
        source.loopEnd = (loop.start + loop.length) / source.buffer.sampleRate;
      }
      pan.pan.value = note.pan || 0;
      const env = envelope(region, note);
      const percussion = note.channel === 9;
      const attack = Math.max(0.002, Math.min(env.attack, 0.5));
      const decay = Math.max(0.01, env.decay);
      const release = Math.max(0.025, Math.min(env.release, 3));
      const amplitude = gainFromAttenuation(region.attenuation) *
        (note.rawVelocity ?? note.velocity) ** 1.5 * (note.volume ?? 1) * 0.8;
      const duration = percussion ? Math.min(6, source.buffer.duration / source.playbackRate.value + (loop ? 2 : 0)) : note.duration;
      const sustain = Math.max(0.0001, env.sustain);
      gain.gain.setValueAtTime(0, when);
      gain.gain.linearRampToValueAtTime(amplitude, when + attack);
      // DLS decay times describe a 96 dB fall. Hold/release can interrupt it.
      const decayEnd = when + attack + decay;
      const noteEnd = when + Math.max(attack, duration);
      const valueAt = time => {
        const progress = Math.max(0, (time - when - attack) / decay);
        return amplitude * Math.max(sustain, 10 ** (-4.8 * progress));
      };
      if (decayEnd < noteEnd) gain.gain.exponentialRampToValueAtTime(Math.max(0.00001, amplitude * sustain), decayEnd);
      gain.gain.exponentialRampToValueAtTime(Math.max(0.00001, valueAt(noteEnd)), noteEnd);
      gain.gain.exponentialRampToValueAtTime(0.00001, noteEnd + release);
      source.connect(gain); gain.connect(pan); pan.connect(destination);
      const nodes = [gain, pan];
      for (const [effect, send] of [[reverb, note.reverb ?? 0], [chorus, note.chorus ?? 0]]) {
        if (effect && send > 0) {
          const level = ctx.createGain();
          level.gain.value = send * 0.22;
          pan.connect(level); level.connect(effect); nodes.push(level);
        }
      }
      source.start(when); source.stop(noteEnd + release + 0.03);
      source.onended = () => { source.disconnect(); nodes.forEach(node => node.disconnect()); };
      return { source, group: percussion ? region.group : 0, gain, when };
    }
  }
  const api = { SampleBank, regionFor, timecents, gainFromAttenuation, envelope };
  if (typeof module !== "undefined" && module.exports) module.exports = api;
  else root.SnoopySamples = api;
})(globalThis);
