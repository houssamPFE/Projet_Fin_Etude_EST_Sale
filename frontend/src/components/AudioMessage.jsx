import { useEffect, useRef, useState, useMemo } from 'react';
import { Play, Pause } from 'lucide-react';
import './AudioMessage.css';

const BAR_COUNT = 32;

function seedFromUrl(url) {
  let h = 0;
  for (let i = 0; i < url.length; i++) {
    h = (h * 31 + url.charCodeAt(i)) | 0;
  }
  return Math.abs(h);
}

function buildBars(url) {
  const seed = seedFromUrl(url ?? '');
  const bars = [];
  let x = seed;
  for (let i = 0; i < BAR_COUNT; i++) {
    x = (x * 9301 + 49297) % 233280;
    const norm = x / 233280;
    const height = 0.25 + norm * 0.75;
    bars.push(height);
  }
  return bars;
}

function formatTime(seconds) {
  if (!Number.isFinite(seconds)) return '0:00';
  const m = Math.floor(seconds / 60);
  const s = Math.floor(seconds % 60).toString().padStart(2, '0');
  return `${m}:${s}`;
}

export default function AudioMessage({ src, variant = 'own' }) {
  const audioRef = useRef(null);
  const wrapRef = useRef(null);
  const [playing, setPlaying] = useState(false);
  const [current, setCurrent] = useState(0);
  const [duration, setDuration] = useState(0);
  const [ready, setReady] = useState(false);

  const bars = useMemo(() => buildBars(src), [src]);

  useEffect(() => {
    const audio = audioRef.current;
    if (!audio) return;

    const onLoaded = () => {
      setDuration(audio.duration);
      setReady(true);
    };
    const onTime = () => setCurrent(audio.currentTime);
    const onEnd = () => {
      setPlaying(false);
      setCurrent(0);
      audio.currentTime = 0;
    };

    audio.addEventListener('loadedmetadata', onLoaded);
    audio.addEventListener('timeupdate', onTime);
    audio.addEventListener('ended', onEnd);
    return () => {
      audio.removeEventListener('loadedmetadata', onLoaded);
      audio.removeEventListener('timeupdate', onTime);
      audio.removeEventListener('ended', onEnd);
    };
  }, [src]);

  const toggle = () => {
    const audio = audioRef.current;
    if (!audio) return;
    if (playing) {
      audio.pause();
      setPlaying(false);
    } else {
      audio.play().then(() => setPlaying(true)).catch(() => setPlaying(false));
    }
  };

  const seek = (e) => {
    const wrap = wrapRef.current;
    const audio = audioRef.current;
    if (!wrap || !audio || !duration) return;
    const rect = wrap.getBoundingClientRect();
    const x = (e.clientX - rect.left) / rect.width;
    const next = Math.max(0, Math.min(1, x)) * duration;
    audio.currentTime = next;
    setCurrent(next);
  };

  const progress = duration > 0 ? current / duration : 0;
  const elapsed = playing || current > 0 ? current : duration;

  return (
    <div className={`am am--${variant}`}>
      <button
        className="am-btn"
        onClick={toggle}
        disabled={!ready}
        aria-label={playing ? 'Pause' : 'Lire'}
      >
        {playing ? <Pause size={16} /> : <Play size={16} style={{ marginLeft: 1 }} />}
      </button>

      <div
        className="am-wave"
        ref={wrapRef}
        onClick={seek}
        role="slider"
        aria-valuemin={0}
        aria-valuemax={duration || 0}
        aria-valuenow={current}
      >
        {bars.map((h, i) => {
          const filled = i / BAR_COUNT < progress;
          return (
            <span
              key={i}
              className={`am-bar ${filled ? 'am-bar--filled' : ''} ${playing ? 'am-bar--live' : ''}`}
              style={{
                height: `${Math.round(h * 100)}%`,
                animationDelay: playing ? `${(i % 8) * 60}ms` : undefined,
              }}
            />
          );
        })}
      </div>

      <span className="am-time">{formatTime(elapsed)}</span>

      <audio ref={audioRef} src={src} preload="metadata" />
    </div>
  );
}
