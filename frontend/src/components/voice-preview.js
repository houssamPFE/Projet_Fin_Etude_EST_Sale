/*
 * <voice-preview> — Direction A ("Mono")
 * A dependency-free Web Component for previewing a recorded voice note
 * before sending. Vanilla JS — drops into any site (plain HTML, React,
 * Vue, Svelte, etc.). No build step, no framework, no dependencies.
 */
(function () {
  const ICON = {
    play: '<svg viewBox="0 0 24 24" width="20" height="20"><path d="M8 5.5v13l11-6.5-11-6.5Z" fill="currentColor" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"/></svg>',
    pause: '<svg viewBox="0 0 24 24" width="20" height="20"><rect x="7" y="5" width="3.4" height="14" rx="1" fill="currentColor"/><rect x="13.6" y="5" width="3.4" height="14" rx="1" fill="currentColor"/></svg>',
    trash: '<svg viewBox="0 0 24 24" width="18" height="18" fill="none"><path d="M5 7h14M10 7V5h4v2M6.5 7l.8 12h9.4l.8-12" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/></svg>',
    send: '<svg viewBox="0 0 24 24" width="18" height="18"><path d="M4.4 11.4 19.2 4.2c.5-.24 1 .26.78.78L12.9 19.6c-.25.55-1.05.5-1.23-.08l-1.78-5.6-5.6-1.78c-.58-.18-.62-.97-.09-1.22Z" fill="currentColor"/></svg>',
  };

  const BARS = 64;
  const WAVE_H = 40;

  function injectStyles() {
    if (document.getElementById('vp-styles')) return;
    const s = document.createElement('style');
    s.id = 'vp-styles';
    s.textContent = `
      voice-preview{
        --vp-ink:#161513; --vp-bg:#ffffff; --vp-track:rgba(0,0,0,.14);
        --vp-radius:16px; --vp-font:'Hanken Grotesk',system-ui,-apple-system,sans-serif;
        --vp-mono:'Space Mono',ui-monospace,SFMono-Regular,Menlo,monospace;
        --vp-border:1px solid rgba(0,0,0,.09);
        --vp-shadow:0 1px 2px rgba(0,0,0,.04),0 8px 24px -16px rgba(0,0,0,.25);
        display:block; font-family:var(--vp-font);
      }
      voice-preview *{box-sizing:border-box}
      voice-preview .vp-bar{
        display:flex; align-items:center; gap:18px; width:100%;
        background:var(--vp-bg); border:var(--vp-border); border-radius:var(--vp-radius);
        padding:12px 14px 12px 12px; box-shadow:var(--vp-shadow);
      }
      voice-preview button{border:none;background:none;font:inherit;cursor:pointer;padding:0;
        color:inherit;display:flex;align-items:center;justify-content:center;flex:0 0 auto;
        transition:all .16s ease}
      voice-preview .vp-play{width:46px;height:46px;border-radius:50%;background:var(--vp-ink);color:#fff}
      voice-preview .vp-play:hover{background:#000;transform:scale(1.04)}
      voice-preview .vp-play:disabled{opacity:.45;cursor:default;transform:none;background:var(--vp-ink)}
      voice-preview .vp-wave{flex:1 1 auto;min-width:0;display:flex;align-items:center;gap:3px;
        height:${WAVE_H}px;cursor:pointer;touch-action:none}
      voice-preview .vp-wave[data-empty]{cursor:default}
      voice-preview .vp-wave i{flex:1 1 0;min-width:0;max-width:3px;border-radius:2px;
        background:var(--vp-track);transition:height .12s ease,background .15s ease;height:30%}
      voice-preview .vp-time{font-family:var(--vp-mono);font-size:15px;color:var(--vp-ink);
        letter-spacing:-.01em;font-variant-numeric:tabular-nums;flex:0 0 auto;white-space:nowrap}
      voice-preview .vp-time .vp-tot{opacity:.32}
      voice-preview .vp-sep{width:1px;height:28px;background:rgba(0,0,0,.08);flex:0 0 auto}
      voice-preview .vp-del{width:40px;height:40px;border-radius:50%;color:rgba(0,0,0,.4)}
      voice-preview .vp-del:hover{background:rgba(0,0,0,.05);color:rgba(0,0,0,.7)}
      voice-preview .vp-send{height:40px;border-radius:999px;background:var(--vp-ink);color:#fff;
        padding:0 18px 0 16px;gap:7px;font-size:15px;font-weight:600}
      voice-preview .vp-send:hover{background:#000;transform:translateY(-1px)}
      voice-preview .vp-send:disabled{opacity:.4;cursor:default;transform:none}
      @media (prefers-reduced-motion: reduce){voice-preview *{transition:none!important}}
    `;
    document.head.appendChild(s);
  }

  class VoicePreview extends HTMLElement {
    static get observedAttributes() { return ['src', 'send-label']; }

    constructor() {
      super();
      this._peaks = null;
      this._progress = 0;
      this._objUrl = null;
      this.audioBlob = null;
      this._audio = new Audio();
      this._audio.preload = 'metadata';
      this._built = false;
    }

    connectedCallback() {
      injectStyles();
      if (!this._built) { this._build(); this._wire(); this._built = true; }
      const src = this.getAttribute('src');
      if (src) this.setAudio(src);
      else this._renderEmpty();
    }

    disconnectedCallback() {
      if (this._objUrl) URL.revokeObjectURL(this._objUrl);
      this._audio.pause();
    }

    attributeChangedCallback(name, _o, v) {
      if (!this._built) return;
      if (name === 'src' && v) this.setAudio(v);
      if (name === 'send-label' && this._sendTxt) this._sendTxt.textContent = ' ' + (v || 'Send');
    }

    _build() {
      this.innerHTML =
        `<div class="vp-bar">
           <button class="vp-play" title="Play" disabled>${ICON.play}</button>
           <div class="vp-wave" data-empty></div>
           <span class="vp-time"><span class="vp-cur">0:00</span><span class="vp-tot"> / 0:00</span></span>
           <div class="vp-sep"></div>
           <button class="vp-del" title="Delete">${ICON.trash}</button>
           <button class="vp-send" title="Send" disabled>${ICON.send}<span class="vp-sendtxt"> ${this.getAttribute('send-label') || 'Send'}</span></button>
         </div>`;
      const $ = (s) => this.querySelector(s);
      this._play = $('.vp-play'); this._wave = $('.vp-wave');
      this._cur = $('.vp-cur'); this._tot = $('.vp-tot');
      this._del = $('.vp-del'); this._send = $('.vp-send'); this._sendTxt = $('.vp-sendtxt');
      for (let i = 0; i < BARS; i++) this._wave.appendChild(document.createElement('i'));
      this._barsEls = [...this._wave.querySelectorAll('i')];
    }

    _wire() {
      this._play.onclick = () => (this._audio.paused ? this.play() : this.pause());
      this._del.onclick = () => { this.reset(); this._emit('vp-delete'); };
      this._send.onclick = () => this._emit('vp-send', {
        blob: this.audioBlob, src: this.getAttribute('src') || null,
        duration: this._audio.duration || 0,
      });

      this._audio.addEventListener('timeupdate', () => this._sync());
      this._audio.addEventListener('loadedmetadata', () => this._sync());
      this._audio.addEventListener('ended', () => { this._progress = 0; this._setPlaying(false); this._sync(true); });
      this._audio.addEventListener('play', () => { this._setPlaying(true); this._emit('vp-play', { duration: this._audio.duration }); });
      this._audio.addEventListener('pause', () => { this._setPlaying(false); this._emit('vp-pause', { currentTime: this._audio.currentTime }); });

      let dragging = false;
      const frac = (e) => {
        const r = this._wave.getBoundingClientRect();
        const x = (e.touches ? e.touches[0].clientX : e.clientX) - r.left;
        return Math.max(0, Math.min(1, x / r.width));
      };
      const seek = (f) => { if (this._audio.duration) this._audio.currentTime = f * this._audio.duration; this._progress = f; this._paint(); this._clock(); };
      this._wave.addEventListener('pointerdown', (e) => { if (this._wave.hasAttribute('data-empty')) return; dragging = true; seek(frac(e)); });
      window.addEventListener('pointermove', (e) => { if (dragging) seek(frac(e)); });
      window.addEventListener('pointerup', () => { dragging = false; });
    }

    play() { this._audio.play().catch(() => {}); }
    pause() { this._audio.pause(); }

    async setAudio(input) {
      if (input == null) return;
      this.reset();
      let url = input, blob = null;
      if (input instanceof Blob) { blob = input; this.audioBlob = blob; url = this._objUrl = URL.createObjectURL(blob); }
      this._audio.src = url;
      this._play.disabled = false; this._send.disabled = false;
      this._wave.removeAttribute('data-empty');
      try {
        const buf = await (blob ? blob.arrayBuffer() : fetch(url).then((r) => r.arrayBuffer()));
        this._peaks = await this._extractPeaks(buf.slice(0));
      } catch (e) {
        this._peaks = this._fallbackPeaks();
      }
      this._paint();
      this._sync();
    }

    reset() {
      this._audio.pause(); this._audio.removeAttribute('src'); this._audio.load();
      if (this._objUrl) { URL.revokeObjectURL(this._objUrl); this._objUrl = null; }
      this.audioBlob = null; this._peaks = null; this._progress = 0;
      this._setPlaying(false);
      if (this._wave) {
        this._wave.setAttribute('data-empty', '');
        this._play.disabled = true; this._send.disabled = true;
        this._renderEmpty();
      }
    }

    async _extractPeaks(arrayBuffer) {
      const Ctx = window.AudioContext || window.webkitAudioContext;
      const ctx = new Ctx();
      const audio = await ctx.decodeAudioData(arrayBuffer);
      const data = audio.getChannelData(0);
      const block = Math.floor(data.length / BARS) || 1;
      const peaks = new Array(BARS);
      let max = 0;
      for (let i = 0; i < BARS; i++) {
        let sum = 0;
        for (let j = 0; j < block; j++) { const v = data[i * block + j] || 0; sum += v * v; }
        const rms = Math.sqrt(sum / block);
        peaks[i] = rms; if (rms > max) max = rms;
      }
      ctx.close && ctx.close();
      return peaks.map((p) => Math.max(0.08, max ? p / max : 0.08));
    }

    _fallbackPeaks() {
      const out = []; let s = 7;
      for (let i = 0; i < BARS; i++) {
        s = (s * 1103515245 + 12345) % 2147483648;
        const env = Math.sin((i / (BARS - 1)) * Math.PI) * 0.55 + 0.35;
        out.push(Math.max(0.1, env * (0.4 + (s / 2147483648) * 0.7)));
      }
      return out;
    }

    _renderEmpty() {
      const flat = this._fallbackPeaks();
      this._barsEls && this._barsEls.forEach((b, i) => {
        b.style.height = Math.max(2, flat[i] * WAVE_H * 0.5) + 'px';
        b.style.background = 'var(--vp-track)';
      });
      if (this._cur) { this._cur.textContent = '0:00'; this._tot.textContent = ' / 0:00'; }
    }

    _paint() {
      if (!this._peaks) return;
      this._barsEls.forEach((b, i) => {
        const played = (i + 0.5) / BARS <= this._progress;
        b.style.height = Math.max(2, this._peaks[i] * WAVE_H) + 'px';
        b.style.background = played ? 'var(--vp-ink)' : 'var(--vp-track)';
      });
    }

    _sync(forceZero) {
      const d = this._audio.duration || 0;
      if (!forceZero && d) this._progress = (this._audio.currentTime || 0) / d;
      this._paint(); this._clock();
    }

    _clock() {
      const d = this._audio.duration || 0;
      this._cur.textContent = fmt(this._progress * d);
      this._tot.textContent = ' / ' + fmt(d);
    }

    _setPlaying(p) {
      if (!this._play) return;
      this._play.innerHTML = p ? ICON.pause : ICON.play;
      this._play.title = p ? 'Pause' : 'Play';
    }

    _emit(name, detail) { this.dispatchEvent(new CustomEvent(name, { detail: detail || {}, bubbles: true, composed: true })); }
  }

  function fmt(sec) {
    const s = Math.max(0, Math.round(sec || 0));
    return Math.floor(s / 60) + ':' + String(s % 60).padStart(2, '0');
  }

  if (!customElements.get('voice-preview')) customElements.define('voice-preview', VoicePreview);
})();
