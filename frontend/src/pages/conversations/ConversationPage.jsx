import { useEffect, useRef, useState, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ArrowLeft, Send, Loader2, Bot, User, UserCheck, ShieldAlert, Phone, Mic, Square, X, Star, BadgeCheck, Search, Crown, MessageCircle, Lock, Stethoscope, PhoneCall, Check, Zap, Shield, Clock, Paperclip, FileText, Image, FileDown, ClipboardList } from 'lucide-react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQueryClient } from '@tanstack/react-query';
import { useConversation, useRateConversation } from '../../hooks/useConversations';
import { useMessages, useSendMessage, useSendAudio, useSendFile, useMarkAllRead } from '../../hooks/useMessages';
import useAudioRecorder from '../../hooks/useAudioRecorder';
import AudioMessage from '../../components/AudioMessage';
import '../../components/voice-preview.js';
import { getEcho } from '../../lib/echo';
import useAuthStore from '../../stores/authStore';
import api from '../../lib/api';
import toast from 'react-hot-toast';
import './ConversationPage.css';

function formatDuration(seconds) {
  const m = Math.floor(seconds / 60).toString().padStart(2, '0');
  const s = (seconds % 60).toString().padStart(2, '0');
  return `${m}:${s}`;
}

const BAR_COUNT = 80;
const SAMPLE_INTERVAL_MS = 60;

function LiveWaveform({ stream }) {
  const canvasRef = useRef(null);
  const rafRef = useRef(null);
  const historyRef = useRef([]); // rolling array of amplitude values 0..1

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas || !stream) return;

    const dpr = window.devicePixelRatio || 1;

    // Set size immediately + on resize
    const resize = () => {
      const { width, height } = canvas.getBoundingClientRect();
      canvas.width = width * dpr;
      canvas.height = height * dpr;
    };
    resize();
    const ro = new ResizeObserver(resize);
    ro.observe(canvas);

    const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    const analyser = audioCtx.createAnalyser();
    analyser.fftSize = 256;
    analyser.smoothingTimeConstant = 0.6;
    const source = audioCtx.createMediaStreamSource(stream);
    source.connect(analyser);

    const freqData = new Uint8Array(analyser.frequencyBinCount);

    // Sample amplitude at regular intervals and push to history
    const sampleTimer = setInterval(() => {
      analyser.getByteFrequencyData(freqData);
      // RMS of lower half of spectrum (voice range)
      let sum = 0;
      const half = Math.floor(freqData.length / 2);
      for (let i = 0; i < half; i++) sum += (freqData[i] / 255) ** 2;
      const rms = Math.sqrt(sum / half);
      historyRef.current.push(Math.min(1, rms * 2.5));
      if (historyRef.current.length > BAR_COUNT) historyRef.current.shift();
    }, SAMPLE_INTERVAL_MS);

    const draw = () => {
      rafRef.current = requestAnimationFrame(draw);
      const W = canvas.width;
      const H = canvas.height;
      const ctx = canvas.getContext('2d');
      ctx.clearRect(0, 0, W, H);

      const bars = historyRef.current;
      if (bars.length === 0) return;

      const barW = Math.max(1.5 * dpr, (W / BAR_COUNT) * 0.35);
      const step = W / BAR_COUNT;

      // Draw unrecorded slots as tiny dots
      for (let i = bars.length; i < BAR_COUNT; i++) {
        const x = i * step + step / 2;
        ctx.fillStyle = 'rgba(255,255,255,0.12)';
        ctx.beginPath();
        ctx.arc(x, H / 2, 1.5 * dpr, 0, Math.PI * 2);
        ctx.fill();
      }

      // Draw recorded bars
      for (let i = 0; i < bars.length; i++) {
        const norm = bars[i];
        const barH = Math.max(H * 0.18, norm * H * 0.88);
        const x = i * step + (step - barW) / 2;
        const y = (H - barH) / 2;

        const grad = ctx.createLinearGradient(0, y, 0, y + barH);
        grad.addColorStop(0, 'rgba(216,180,254,0.95)');
        grad.addColorStop(1, 'rgba(124,58,237,0.95)');
        ctx.fillStyle = grad;
        ctx.beginPath();
        ctx.roundRect(x, y, barW, barH, barW / 2);
        ctx.fill();
      }

    };

    draw();

    return () => {
      cancelAnimationFrame(rafRef.current);
      clearInterval(sampleTimer);
      ro.disconnect();
      source.disconnect();
      audioCtx.close();
      historyRef.current = [];
    };
  }, [stream]);

  return <canvas ref={canvasRef} className="rec-live-wave" />;
}

const SENDER_ICONS = {
  user: User,
  ai: Bot,
  expert: UserCheck,
};

const SENDER_LABELS = {
  user: 'Vous',
  ai: 'IA Nexora',
  expert: 'Expert',
};

const FREE_FEATURES = [
  { text: 'Assistant IA médical 24/7',     included: true  },
  { text: 'Triage des symptômes',           included: true  },
  { text: 'Réponses instantanées',          included: true  },
  { text: '3 conversations par mois',       included: true  },
  { text: 'Consultation médecin réel',      included: false },
  { text: 'Messages vocaux & fichiers',     included: false },
  { text: 'Ordonnances numériques',         included: false },
];

const PREMIUM_FEATURES = [
  { text: 'Conversations illimitées',             icon: Zap    },
  { text: 'Médecin disponible en < 15 min',       icon: Clock  },
  { text: 'Consultation avec un vrai médecin',    icon: Stethoscope },
  { text: 'Messages vocaux & fichiers',           icon: Mic    },
  { text: 'Historique médical complet',           icon: Shield },
  { text: 'Ordonnances numériques',               icon: BadgeCheck },
  { text: 'Support prioritaire 24/7',             icon: Crown  },
];

function PremiumModal({ onClose }) {
  return (
    <motion.div
      className="premium-overlay"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.2 }}
      onMouseDown={(e) => { if (e.target === e.currentTarget) onClose(); }}
    >
      <motion.div
        className="premium-modal"
        initial={{ opacity: 0, scale: 0.93, y: 32 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        exit={{ opacity: 0, scale: 0.93, y: 32 }}
        transition={{ type: 'spring', damping: 28, stiffness: 340 }}
      >
        {/* ── Close ── */}
        <button className="premium-close" onClick={onClose} aria-label="Fermer">
          <X size={17} />
        </button>

        {/* ── Hero ── */}
        <div className="premium-hero">
          <div className="premium-crown-ring">
            <Crown size={30} />
          </div>
          <h2 className="premium-title">Nexora <span>Premium</span></h2>
          <p className="premium-subtitle">Consultez un vrai médecin en moins de 15 minutes, depuis chez vous.</p>
        </div>

        {/* ── Plans grid ── */}
        <div className="premium-plans">

          {/* Free card */}
          <div className="premium-plan premium-plan--free">
            <div className="premium-plan-top">
              <p className="premium-plan-name">Gratuit</p>
              <div className="premium-plan-price">
                <span className="premium-plan-amount">0</span>
                <span className="premium-plan-currency"> MAD</span>
              </div>
            </div>
            <ul className="premium-feature-list">
              {FREE_FEATURES.map((f, i) => (
                <li key={i} className={`premium-feature-item ${f.included ? 'pfi--yes' : 'pfi--no'}`}>
                  {f.included
                    ? <span className="pfi-icon pfi-icon--yes"><Check size={11} /></span>
                    : <span className="pfi-icon pfi-icon--no"><X size={11} /></span>
                  }
                  {f.text}
                </li>
              ))}
            </ul>
            <button className="premium-plan-cta premium-plan-cta--free" onClick={onClose}>
              Continuer gratuitement
            </button>
          </div>

          {/* Premium card */}
          <div className="premium-plan premium-plan--pro">
            <div className="premium-plan-glow" />
            <div className="premium-plan-badge-top">
              <Crown size={11} /> Recommandé
            </div>
            <div className="premium-plan-top">
              <p className="premium-plan-name">Premium</p>
              <div className="premium-plan-price">
                <span className="premium-plan-amount">99</span>
                <span className="premium-plan-currency"> MAD<span className="premium-plan-period">/mois</span></span>
              </div>
            </div>
            <ul className="premium-feature-list">
              {PREMIUM_FEATURES.map((f, i) => {
                const Icon = f.icon;
                return (
                  <li key={i} className="premium-feature-item pfi--pro">
                    <span className="pfi-icon pfi-icon--pro"><Icon size={11} /></span>
                    {f.text}
                  </li>
                );
              })}
            </ul>
            <button className="premium-plan-cta premium-plan-cta--pro">
              <Crown size={14} /> Passer à Premium
            </button>
            <p className="premium-plan-note">Annulable à tout moment · Paiement sécurisé 🔒</p>
          </div>

        </div>

        {/* ── Trust strip ── */}
        <div className="premium-trust">
          <span><Shield size={12} /> Données protégées</span>
          <span><BadgeCheck size={12} /> Médecins certifiés</span>
          <span><Clock size={12} /> Disponible 24/7</span>
        </div>
      </motion.div>
    </motion.div>
  );
}

function DoctorCardsPanel({ specialty, experts, onClose, onUpgrade, onConsult }) {
  const isEmpty = !experts?.length;
  const [consulting, setConsulting] = useState(null); // expert id being booked

  const handleConsultClick = async (expert) => {
    setConsulting(expert.id);
    await onConsult(expert.id, specialty);
    setConsulting(null);
  };

  return (
    <motion.div
      className="doctor-cards-panel"
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3 }}
    >
      <div className="doctor-cards-header">
        <Stethoscope size={15} />
        <span>Médecins disponibles</span>
        <button className="doctor-cards-close" onClick={onClose}><X size={14} /></button>
      </div>

      {isEmpty ? (
        <p className="doctor-cards-empty">Aucun médecin disponible pour cette spécialité pour le moment.</p>
      ) : (
        <div className="doctor-cards-list">
          {experts.map((expert) => (
            <div key={expert.id} className="doctor-card">
              <div className="doctor-card-avatar">
                {expert.user?.avatar_url
                  ? <img src={expert.user.avatar_url} alt={expert.user?.name} />
                  : <span>{(expert.user?.name ?? '?')[0].toUpperCase()}</span>
                }
              </div>
              <div className="doctor-card-info">
                <p className="doctor-card-name">Dr. {expert.user?.name ?? '—'}</p>
                <p className="doctor-card-specialty">{expert.category?.name ?? specialty}</p>
                <div className="doctor-card-meta">
                  {expert.rating_avg > 0 && (
                    <span className="doctor-card-rating">★ {Number(expert.rating_avg).toFixed(1)}</span>
                  )}
                </div>
              </div>
              <button
                className="doctor-card-consult-btn"
                onClick={() => handleConsultClick(expert)}
                disabled={consulting !== null}
              >
                {consulting === expert.id
                  ? <Loader2 size={13} className="spin" />
                  : <><Stethoscope size={13} /> Consulter</>
                }
              </button>
            </div>
          ))}
        </div>
      )}

      <div className="doctor-cards-footer">
        <a className="doctor-cards-more-link" href="/experts" target="_blank" rel="noreferrer">
          <Search size={12} /> Voir plus de médecins
        </a>
        <button className="action-btn action-btn--ghost doctor-cards-continue-btn" onClick={onClose}>
          Continuer avec l'IA
        </button>
      </div>
    </motion.div>
  );
}

const ACTION_ICONS = {
  find_expert: Stethoscope,
  continue_ai: Bot,
  call_samu:   PhoneCall,
};

const ACTION_VARIANTS = {
  find_expert: 'action-btn--primary',
  continue_ai: 'action-btn--ghost',
  call_samu:   'action-btn--danger',
};

function ActionButtons({ actions, onAction, userPlan }) {
  if (!actions?.length) return null;

  const hasFindExpert = actions.some((a) => a.type === 'find_expert');
  const isFree = userPlan === 'free' || !userPlan;

  // Free user + doctor suggestion → show an inline upgrade card instead of the normal buttons
  if (hasFindExpert && isFree) {
    const otherActions = actions.filter((a) => a.type !== 'find_expert');
    return (
      <motion.div
        className="msg-actions msg-actions--col"
        initial={{ opacity: 0, y: 8 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.3, delay: 0.1 }}
      >
        <div className="upgrade-nudge">
          <div className="upgrade-nudge-top">
            <Crown size={16} className="upgrade-nudge-crown" />
            <span className="upgrade-nudge-label">Fonctionnalité Pro</span>
          </div>
          <p className="upgrade-nudge-text">
            La consultation avec un médecin est réservée aux abonnés Pro et Premium.
          </p>
          <button
            className="upgrade-nudge-btn"
            onClick={() => onAction({ type: 'find_expert' })}
          >
            <Crown size={13} />
            Passer au plan Pro
          </button>
        </div>
        {otherActions.map((action, i) => {
          const Icon = ACTION_ICONS[action.type] ?? Bot;
          const variant = ACTION_VARIANTS[action.type] ?? 'action-btn--ghost';
          return (
            <button key={i} className={`action-btn ${variant}`} onClick={() => onAction(action)}>
              <Icon size={14} />
              {action.label}
            </button>
          );
        })}
      </motion.div>
    );
  }

  return (
    <motion.div
      className="msg-actions"
      initial={{ opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.25, delay: 0.1 }}
    >
      {actions.map((action, i) => {
        const Icon = ACTION_ICONS[action.type] ?? Stethoscope;
        const variant = ACTION_VARIANTS[action.type] ?? 'action-btn--ghost';
        return (
          <button
            key={i}
            className={`action-btn ${variant}`}
            onClick={() => onAction(action)}
          >
            <Icon size={14} />
            {action.label}
          </button>
        );
      })}
    </motion.div>
  );
}

function MessageBubble({ message, currentUser, isDeleted, isLastAiMessage, onAction, expertName }) {
  const isExpert = currentUser?.role === 'expert';

  // "own" = the current user sent this message
  // — patient: their messages have sender_type='user' and sender_id matches
  // — expert: their messages have sender_type='expert' and sender_id matches
  const isOwn = isExpert
    ? message.sender_type === 'expert' && message.sender_id === currentUser?.id
    : message.sender_type === 'user' && message.sender_id === currentUser?.id;

  const Icon = SENDER_ICONS[message.sender_type] ?? User;

  // Context-aware sender label
  const getSenderLabel = () => {
    if (message.sender_type === 'user') return isExpert ? 'Patient' : 'Vous';
    if (message.sender_type === 'ai') return 'IA Nexora';
    if (message.sender_type === 'expert') return expertName ? `Dr. ${expertName}` : 'Expert';
    return '';
  };

  return (
    <motion.div
      className={`msg-row ${isOwn ? 'msg-row--own' : ''} ${message.sender_type === 'ai' ? 'msg-row--ai' : ''}`}
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.25 }}
    >
      {!isOwn && (
        <div className={`msg-avatar msg-avatar--${message.sender_type}`}>
          <Icon size={16} />
        </div>
      )}
      <div className="msg-bubble-wrap">
        {!isOwn && (
          <span className="msg-sender-label">{getSenderLabel()}</span>
        )}

        {isDeleted ? (
          <div className="msg-bubble msg-bubble--deleted">
            <span className="msg-deleted-icon">🚫</span>
            <em>Ce message a été supprimé</em>
          </div>
        ) : (
          <>
            <div className={`msg-bubble msg-bubble--${isOwn ? 'own' : message.sender_type}`}>
              {message.type === 'audio' ? (
                <div className="msg-audio">
                  {message.audio_url ? (
                    <AudioMessage
                      src={message.audio_url}
                      variant={isOwn ? 'own' : message.sender_type}
                    />
                  ) : (
                    <span className="msg-audio-pending">Audio en cours d'envoi…</span>
                  )}
                  {message.transcription && (
                    <p className="msg-transcription">{message.transcription}</p>
                  )}
                </div>
              ) : message.type === 'file' ? (
                <div className="msg-file">
                  {(message._isImage || /\.(jpe?g|png|gif|webp)$/i.test(message.content ?? '')) ? (
                    <a href={message.media_url} target="_blank" rel="noreferrer" className="msg-file-img-link">
                      <img
                        src={message.media_url}
                        alt={message.content}
                        className="msg-file-img"
                        onError={(e) => { e.target.style.display = 'none'; }}
                      />
                    </a>
                  ) : (
                    <a
                      href={message.media_url}
                      target="_blank"
                      rel="noreferrer"
                      className="msg-file-doc"
                    >
                      <FileText size={18} />
                      <span className="msg-file-name">{message.content ?? 'Fichier'}</span>
                    </a>
                  )}
                </div>
              ) : (
                <p className="msg-content">{message.content}</p>
              )}
            </div>
            {isLastAiMessage && message.sender_type === 'ai' && (
              <ActionButtons
                actions={message.metadata?.actions}
                onAction={onAction}
                userPlan={currentUser?.plan}
              />
            )}
          </>
        )}
      </div>
    </motion.div>
  );
}

function TypingIndicator({ label }) {
  const displayLabel = label || 'IA Nexora';
  const isAi = !label;
  return (
    <motion.div
      className={`msg-row ${isAi ? 'msg-row--ai' : 'msg-row--expert'}`}
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: 8 }}
      transition={{ duration: 0.2 }}
    >
      <div className={`msg-avatar msg-avatar--${isAi ? 'ai' : 'expert'}`}>
        {isAi ? <Bot size={16} /> : <UserCheck size={16} />}
      </div>
      <div className="msg-bubble-wrap">
        <span className="msg-sender-label">{displayLabel}</span>
        <div className={`msg-bubble msg-bubble--${isAi ? 'ai' : 'expert'} msg-bubble--typing`}>
          <span className="typing-dot" />
          <span className="typing-dot" />
          <span className="typing-dot" />
        </div>
      </div>
    </motion.div>
  );
}

function RatingCard({ conversationId }) {
  const [hovered, setHovered] = useState(0);
  const [selected, setSelected] = useState(0);
  const [comment, setComment] = useState('');
  const [submitted, setSubmitted] = useState(false);
  const { mutateAsync: rate, isPending } = useRateConversation();

  const handleSubmit = async () => {
    if (!selected) return;
    await rate({ id: conversationId, rating: selected, comment: comment.trim() || undefined });
    setSubmitted(true);
  };

  if (submitted) {
    return (
      <div className="conv-rating-card conv-rating-card--done">
        <span className="conv-rating-done-icon">✓</span>
        <span>Merci pour votre évaluation !</span>
      </div>
    );
  }

  return (
    <div className="conv-rating-card">
      <p className="conv-rating-title">Comment s'est passée votre consultation ?</p>
      <div className="conv-rating-stars">
        {[1, 2, 3, 4, 5].map((n) => (
          <button
            key={n}
            type="button"
            className={`conv-rating-star ${n <= (hovered || selected) ? 'conv-rating-star--on' : ''}`}
            onMouseEnter={() => setHovered(n)}
            onMouseLeave={() => setHovered(0)}
            onClick={() => setSelected(n)}
          >
            <Star size={28} fill={n <= (hovered || selected) ? '#FCD34D' : 'none'} />
          </button>
        ))}
      </div>
      {selected > 0 && (
        <textarea
          className="conv-rating-comment"
          placeholder="Commentaire facultatif…"
          value={comment}
          onChange={(e) => setComment(e.target.value)}
          maxLength={2000}
          rows={2}
        />
      )}
      <button
        className="conv-rating-submit"
        disabled={!selected || isPending}
        onClick={handleSubmit}
      >
        {isPending ? <Loader2 size={15} className="spin" /> : 'Envoyer'}
      </button>
    </div>
  );
}

// ── Consultation Summary Card ─────────────────────────────────────────────────
function ConsultationSummaryCard({ summary, conversationId, onDownload, downloading }) {
  return (
    <motion.div
      className="conv-summary-card"
      initial={{ opacity: 0, y: 16 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.35 }}
    >
      <div className="conv-summary-header">
        <ClipboardList size={16} className="conv-summary-icon" />
        <span className="conv-summary-title">Résumé de consultation</span>
        <button
          className="conv-summary-download"
          onClick={onDownload}
          disabled={downloading}
          title="Télécharger le rapport PDF"
        >
          {downloading
            ? <Loader2 size={14} className="spin" />
            : <><FileDown size={14} /> Rapport PDF</>
          }
        </button>
      </div>
      {summary
        ? <p className="conv-summary-text">{summary}</p>
        : <p className="conv-summary-empty">Résumé en cours de génération…</p>
      }
      <div className="conv-summary-footer">
        <Bot size={11} />
        Généré automatiquement par l&apos;IA après clôture
      </div>
    </motion.div>
  );
}

export default function ConversationPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const user = useAuthStore((s) => s.user);
  const isExpert = user?.role === 'expert';
  const queryClient = useQueryClient();

  // Poll every 20 s as a fallback — WS presence events (ShouldBroadcastNow) update the
  // dot instantly, but the poll catches any missed events within 20 s.
  const { data: conversation } = useConversation(id, { refetchInterval: 20_000 });
  const { data: messagesData, isLoading: messagesLoading } = useMessages(id);
  const { mutateAsync: sendMessage, isPending: sending } = useSendMessage(id);
  const { mutateAsync: sendAudio, isPending: sendingAudio } = useSendAudio(id);
  const { mutateAsync: sendFile, isPending: sendingFile } = useSendFile(id);
  const { mutate: markAllRead } = useMarkAllRead(id);

  const recorder = useAudioRecorder();

  const [input, setInput] = useState('');
  const [aiTyping, setAiTyping] = useState(false);
  const [downloadingReport, setDownloadingReport] = useState(false);
  const [doctorCards, setDoctorCards] = useState(null); // { specialty, experts[] }
  const [showPremium, setShowPremium] = useState(false);
  const [peerTyping, setPeerTyping] = useState(false);   // other person is typing
  const [peerTypingName, setPeerTypingName] = useState('');
  // Real-time online override — null means "use value from conversation query"
  const [presenceOverride, setPresenceOverride] = useState(null);
  // Header avatar fallback state
  const [headerAvatarFailed, setHeaderAvatarFailed] = useState(false);
  // Track real-time deleted message IDs (WS push while page is open)
  const [deletedIds, setDeletedIds] = useState(new Set());
  const bottomRef = useRef(null);
  const doctorCardsRef = useRef(null);
  const inputRef = useRef(null);
  const fileInputRef = useRef(null);
  const vpRef = useRef(null);
  const typingTimerRef = useRef(null);     // debounce: stop-typing after 2s idle
  const isTypingRef = useRef(false);       // avoid duplicate API calls
  const peerTypingTimerRef = useRef(null); // auto-clear peer typing after 5s if stop event missed

  // ── Derived state — declared early so all hooks below can reference them ──
  const messages = messagesData?.data ?? [];
  const conv = conversation ?? null;
  const hasEmergency = messages.some(
    (m) => m.metadata?.urgency_level === 'emergency'
  );
  const lastAiMessageId = [...messages].reverse().find((m) => m.sender_type === 'ai')?.id ?? null;

  const scrollToBottom = useCallback(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, []);

  useEffect(() => {
    scrollToBottom();
  }, [messagesData, aiTyping, scrollToBottom]);

  // Mark all incoming messages as read whenever the messages list updates
  // (covers both the initial load and new messages arriving via WS)
  useEffect(() => {
    if (messagesData?.data?.length) {
      markAllRead();
    }
  }, [messagesData, markAllRead]);

  // Real-time Echo subscription
  useEffect(() => {
    const echo = getEcho();
    const channel = echo.private(`conversation.${id}`);

    // MessageSent uses broadcastAs('message.sent')
    channel.listen('.message.sent', () => {
      // Always refetch messages — replaces temp optimistic message with real one.
      // Do NOT call setAiTyping(false) here — the safety net useEffect handles it
      // precisely when the new message data arrives, so there's no gap between
      // the indicator disappearing and the message appearing.
      queryClient.invalidateQueries({ queryKey: ['messages', id] });
    });

    // AIResponseReady uses broadcastAs('ai.response')
    channel.listen('.ai.response', () => {
      // Refetch only — aiTyping cleared by safety net when data arrives.
      queryClient.invalidateQueries({ queryKey: ['messages', id] });
    });

    // Cross-platform sync: message deleted on mobile → disappears on web instantly
    channel.listen('.message.deleted', (event) => {
      const deletedId = event.message_id;
      if (deletedId) {
        setDeletedIds((prev) => new Set([...prev, String(deletedId)]));
      }
    });

    // Typing indicator from the other participant
    channel.listen('.user.typing', (event) => {
      if (event.user_id === user?.id) return; // ignore own events
      if (event.is_typing) {
        setPeerTyping(true);
        setPeerTypingName(event.user_name ?? '');
        // Safety net: auto-clear after 5 s if the "stop typing" event is missed
        clearTimeout(peerTypingTimerRef.current);
        peerTypingTimerRef.current = setTimeout(() => setPeerTyping(false), 5000);
      } else {
        clearTimeout(peerTypingTimerRef.current);
        setPeerTyping(false);
      }
    });

    // Real-time presence — instantly update online dot from heartbeat / logout broadcasts
    channel.listen('.user.presence', (event) => {
      if (event.user_id === user?.id) return; // ignore own presence events
      // true  → came online (heartbeat fired)
      // false → went offline (logged out — clear Redis key broadcasted false immediately)
      setPresenceOverride(event.is_online === true ? true : false);
    });

    return () => {
      channel.stopListening('.message.sent');
      channel.stopListening('.ai.response');
      channel.stopListening('.message.deleted');
      channel.stopListening('.user.typing');
      channel.stopListening('.user.presence');
      echo.leave(`conversation.${id}`);
    };
  }, [id, user?.id, queryClient]);

  // When the conversation query re-fetches it brings a fresh is_online value.
  // Only wipe the WS override if the fresh DB value matches what WS already told us,
  // so the dot never flickers back to "online" after a logout broadcast.
  useEffect(() => {
    if (!conversation) return;
    const isExpertInConv = user?.role === 'expert';
    const otherUser = isExpertInConv ? conversation.user : conversation.expert?.user;
    const freshOnline = otherUser?.is_online ?? false;
    setPresenceOverride((prev) => {
      // If WS told us "offline" but DB still hasn't caught up → keep WS value
      if (prev === false && freshOnline === true) return false;
      // Otherwise trust the fresh DB value (removes stale override)
      return null;
    });
  }, [conversation, user?.role]);

  // Safety net 1: clear typing indicator as soon as the last message is from AI/expert
  useEffect(() => {
    const list = messagesData?.data ?? [];
    const last = list[list.length - 1];
    if (last && last.sender_type !== 'user') {
      setAiTyping(false);
    }
  }, [messagesData]);

  // Auto-show doctor cards whenever the last AI message has a find_expert action.
  // This runs on mount AND on re-entry so clicking is never needed to restore the panel.
  useEffect(() => {
    if (conv?.status === 'expert' || conv?.status === 'closed') {
      setDoctorCards(null); // clear any stale panel when doctor is already assigned
      return;
    }

    // Don't run until the conversation is fully loaded
    if (!conv?.status) return;

    // Free users see the inline upgrade card instead — no panel needed
    if (user?.plan === 'free' || !user?.plan) return;

    const lastAiMsg = messages.find((m) => m.id === lastAiMessageId);
    const findAction = lastAiMsg?.metadata?.actions?.find((a) => a.type === 'find_expert');
    if (!findAction) return;

    const specialty = conv?.category?.slug || findAction.specialty || 'medecine-generale';

    api.get(`/experts?available=1&specialty=${specialty}&per_page=3`)
      .then(async (res) => {
        let experts = res.data.data ?? [];
        if (!experts.length) {
          const fallback = await api.get(`/experts?available=1&per_page=3`);
          experts = fallback.data.data ?? [];
        }
        setDoctorCards({ specialty, experts });
      })
      .catch(() => {});
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [lastAiMessageId, conv?.status, conv?.category?.slug]);

  // Scroll doctor cards panel into view whenever it appears
  useEffect(() => {
    if (!doctorCards) return;
    const timer = setTimeout(() => {
      doctorCardsRef.current?.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }, 150);
    return () => clearTimeout(timer);
  }, [doctorCards]);

  // Safety net 2: hard timeout — never let typing indicator linger more than 20s
  useEffect(() => {
    if (!aiTyping) return;
    const timer = setTimeout(() => setAiTyping(false), 20000);
    return () => clearTimeout(timer);
  }, [aiTyping]);

  const handleSend = async () => {
    const text = input.trim();
    if (!text || sending) return;
    setInput('');
    clearTimeout(typingTimerRef.current);
    sendTypingStop();
    // Show AI typing indicator whenever a patient sends a message
    // (conv may be null on first send — treat null status as 'ai' which should show indicator)
    const status = conv?.status;
    if (!isExpert && status !== 'expert' && status !== 'closed') {
      setAiTyping(true);
    }
    try {
      await sendMessage(text);
    } catch {
      toast.error('Impossible d\'envoyer le message.');
      setAiTyping(false);
    }
    inputRef.current?.focus();
  };

  const handleKeyDown = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  const handleFilePick = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    // Reset so same file can be re-selected
    e.target.value = '';
    try {
      await sendFile(file);
    } catch {
      toast.error('Impossible d\'envoyer le fichier.');
    }
  };

  // ── Typing events ────────────────────────────────────────────────────────
  const sendTypingStart = useCallback(() => {
    if (isTypingRef.current) return;
    isTypingRef.current = true;
    api.post(`/conversations/${id}/typing`, { is_typing: true }).catch(() => {});
  }, [id]);

  const sendTypingStop = useCallback(() => {
    if (!isTypingRef.current) return;
    isTypingRef.current = false;
    api.post(`/conversations/${id}/typing`, { is_typing: false }).catch(() => {});
  }, [id]);

  const handleInputChange = (e) => {
    setInput(e.target.value);
    sendTypingStart();
    // Auto-stop typing after 2 seconds of idle
    clearTimeout(typingTimerRef.current);
    typingTimerRef.current = setTimeout(sendTypingStop, 2000);
  };

  // Stop typing on unmount / send; also clear peer-typing safety timer
  useEffect(() => () => {
    clearTimeout(typingTimerRef.current);
    clearTimeout(peerTypingTimerRef.current);
    sendTypingStop();
  }, [sendTypingStop]);

  useEffect(() => {
    if (recorder.error) toast.error(recorder.error);
  }, [recorder.error]);

  // Load blob into the <voice-preview> web component whenever a recording is ready
  useEffect(() => {
    const el = vpRef.current;
    if (!el) return;
    if (recorder.blob) {
      el.setAudio(recorder.blob);
    }
  }, [recorder.blob]);

  // Wire vp-send / vp-delete events (re-register when blob changes for fresh closures)
  useEffect(() => {
    const el = vpRef.current;
    if (!el || !recorder.blob) return;

    const onSend = async (e) => {
      const blob = e.detail.blob;
      if (!blob) return;
      recorder.reset();
      try {
        if (!isExpert && conv?.status !== 'expert' && conv?.status !== 'closed') {
          setAiTyping(true);
        }
        await sendAudio(blob);
      } catch {
        toast.error("Échec de l'envoi du message vocal.");
        setAiTyping(false);
      }
    };

    const onDelete = () => recorder.reset();

    el.addEventListener('vp-send', onSend);
    el.addEventListener('vp-delete', onDelete);
    return () => {
      el.removeEventListener('vp-send', onSend);
      el.removeEventListener('vp-delete', onDelete);
    };
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [recorder.blob]);

  const handleAction = useCallback(async (action) => {
    if (action.type === 'call_samu') {
      window.open('tel:15');
      return;
    }

    if (action.type === 'find_expert') {
      // Free users go straight to the upgrade page — no point showing the doctor list
      if (user?.plan === 'free') {
        navigate('/upgrade', { state: { reason: 'no_plan' } });
        return;
      }
      // Use the conversation's chosen specialty first, then AI suggestion, then fallback
      const specialty = conv?.category?.slug || action.specialty || 'medecine-generale';
      try {
        let res = await api.get(`/experts?available=1&specialty=${specialty}&per_page=5`);
        if (!res.data.data?.length) {
          res = await api.get(`/experts?available=1&per_page=5`);
        }
        setDoctorCards({ specialty, experts: res.data.data ?? [] });
      } catch (err) {
        toast.error('Impossible de charger les médecins disponibles.');
      }
      return;
    }

    // continue_ai: send label as user message
    const label = action.label;
    if (!label) return;
    if (!isExpert && conv?.status !== 'expert' && conv?.status !== 'closed') {
      setAiTyping(true);
    }
    try {
      await sendMessage(label);
    } catch {
      toast.error('Impossible d\'envoyer le message.');
      setAiTyping(false);
    }
  }, [sendMessage, isExpert, conv?.status, scrollToBottom]);

  // Patient picked a specific doctor from the cards panel
  const handleConsult = useCallback(async (expertId, specialty) => {
    try {
      setDoctorCards(null);
      const res = await api.post(`/conversations/${id}/escalate`, { expert_id: expertId, specialty });
      // 'conversations' (plural) matches the query key used in useConversation hook
      queryClient.invalidateQueries({ queryKey: ['conversations', String(id)] });
      queryClient.invalidateQueries({ queryKey: ['conversations'] });
      queryClient.invalidateQueries({ queryKey: ['messages', id] });
      const msg = res.data?.message ?? '';
      if (msg.includes('Aucun expert')) {
        toast.error('Ce médecin n\'est plus disponible. Veuillez en choisir un autre.');
        // Re-fetch doctor cards so patient can pick someone else
        const fallback = await api.get(`/experts?available=1&per_page=3`);
        setDoctorCards({ specialty, experts: fallback.data.data ?? [] });
      } else {
        toast.success('Médecin assigné — la consultation commence !');
      }
    } catch (err) {
      if (err.response?.status === 402) {
        // No plan or no credits → send to upgrade screen
        const reason = err.response?.data?.reason ?? 'no_plan';
        navigate('/upgrade', { state: { reason } });
      } else {
        toast.error('Impossible d\'assigner ce médecin. Réessayez.');
      }
    }
  }, [id, queryClient, navigate]);

  const handleDownloadReport = async () => {
    if (downloadingReport) return;
    setDownloadingReport(true);
    try {
      const response = await api.get(`/conversations/${id}/report`, {
        responseType: 'blob',
      });
      const blob = new Blob([response.data], { type: 'application/pdf' });
      const url  = URL.createObjectURL(blob);
      const a    = document.createElement('a');
      a.href     = url;
      a.download = `rapport-consultation-${id}.pdf`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    } catch {
      toast.error('Impossible de télécharger le rapport.');
    } finally {
      setDownloadingReport(false);
    }
  };

  return (
    <div className="conv-page">
      {/* Header */}
      {(() => {
        const otherUser  = isExpert ? conv?.user : conv?.expert?.user;
        const isAiConv   = conv?.status === 'ai' || !conv?.expert;
        const expertId   = conv?.expert?.id;
        const isOnline   = presenceOverride !== null ? presenceOverride : (otherUser?.is_online ?? false);
        const headerName = isExpert
          ? (conv?.user?.name ?? `Conversation #${id}`)
          : isAiConv
            ? 'IA Nexora'
            : (conv?.expert?.user?.name ? `Dr. ${conv.expert.user.name}` : `Conversation #${id}`);

        const initials = (name) => {
          if (!name) return '?';
          const parts = name.trim().split(/\s+/);
          return parts.length === 1
            ? parts[0][0].toUpperCase()
            : (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
        };

        const canViewProfile = !isAiConv && !isExpert && expertId;

        return (
          <div className="conv-page-header">
            <button className="back-btn" onClick={() => navigate('/conversations')}>
              <ArrowLeft size={18} />
            </button>

            {/* Avatar */}
            <div
              className={`conv-hdr-avatar-wrap${canViewProfile ? ' conv-hdr-avatar-wrap--link' : ''}`}
              onClick={() => canViewProfile && navigate(`/experts/${expertId}`)}
              title={canViewProfile ? 'Voir le profil' : undefined}
            >
              {isAiConv ? (
                <div className="conv-hdr-avatar conv-hdr-avatar--ai">
                  <img src="/nexora1.png" alt="IA" className="conv-hdr-avatar-logo" />
                </div>
              ) : (
                <div className="conv-hdr-avatar">
                  {otherUser?.avatar_url && !headerAvatarFailed ? (
                    <img
                      src={otherUser.avatar_url}
                      alt={otherUser.name}
                      className="conv-hdr-avatar-photo"
                      onError={() => setHeaderAvatarFailed(true)}
                    />
                  ) : (
                    <span className="conv-hdr-avatar-initials">{initials(otherUser?.name)}</span>
                  )}
                </div>
              )}
            </div>

            {/* Name + status */}
            <div className="conv-page-header-info">
              <div className="conv-hdr-title-row">
                <h2 className="conv-page-title">{headerName}</h2>
                {!isAiConv && conv?.expert?.validated_at && (
                  <BadgeCheck size={14} className="conv-hdr-verified" />
                )}
              </div>
              <AnimatePresence mode="wait">
                {peerTyping ? (
                  <motion.span
                    key="typing"
                    className="conv-page-status"
                    style={{ color: '#A78BFA' }}
                    initial={{ opacity: 0, y: 4 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: -4 }}
                    transition={{ duration: 0.2 }}
                  >
                    <span className="typing-dots"><span/><span/><span/></span>
                    en train d&apos;écrire…
                  </motion.span>
                ) : isOnline ? (
                  <motion.span
                    key="online"
                    className="conv-page-status conv-page-status--online"
                    initial={{ opacity: 0, y: 4 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: -4 }}
                    transition={{ duration: 0.3 }}
                  >
                    <span className="conv-online-dot-sm" /> En ligne
                  </motion.span>
                ) : (
                  <motion.span
                    key="offline"
                    className="conv-page-status"
                    initial={{ opacity: 0, y: 4 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: -4 }}
                    transition={{ duration: 0.3 }}
                  >
                    {isAiConv ? 'Assistant médical IA' : (conv?.category?.name ?? '')}
                  </motion.span>
                )}
              </AnimatePresence>
            </div>

            {conv?.status && (
              <span className={`conv-page-badge conv-page-badge--${conv.status}`}>
                {conv.status === 'ai' ? 'IA' : conv.status === 'expert' ? 'En cours' : conv.status === 'closed' ? 'Fermé' : 'Ouvert'}
              </span>
            )}
          </div>
        );
      })()}

      {hasEmergency && (
        <div className="conv-emergency-banner" role="alert">
          <ShieldAlert size={18} />
          <div>
            <strong>Urgence détectée.</strong> Si vos symptômes s'aggravent,
            appelez immédiatement le SAMU au <a href="tel:15"><Phone size={12} /> 15</a> ou
            rendez-vous aux urgences les plus proches.
          </div>
        </div>
      )}

      {/* Messages */}
      <div className="conv-messages">
        <div className="conv-disclaimer">
          <Bot size={14} />
          Les informations fournies par l'IA sont à titre informatif uniquement et
          ne remplacent pas une consultation médicale. En cas d'urgence, appelez le 15.
        </div>

        {messagesLoading ? (
          <div className="conv-messages-loading">
            <Loader2 size={28} className="spin" style={{ color: 'var(--primary-500)' }} />
          </div>
        ) : messages.length === 0 ? (
          <div className="conv-messages-empty">
            <Bot size={40} style={{ color: 'var(--text-muted)', marginBottom: 12 }} />
            <p style={{ color: 'var(--text-muted)', margin: 0 }}>
              Décrivez votre symptôme ou posez votre question médicale.
              L'assistant IA vous répondra immédiatement.
            </p>
          </div>
        ) : (
          <div className="conv-messages-list">
            {messages.map((msg) => (
              <MessageBubble
                key={msg.id}
                message={msg}
                currentUser={user}
                isDeleted={deletedIds.has(String(msg.id))}
                isLastAiMessage={msg.id === lastAiMessageId}
                onAction={handleAction}
                expertName={conv?.expert?.user?.name}
              />
            ))}
            <AnimatePresence>
              {aiTyping && <TypingIndicator key="ai-typing" />}
              {peerTyping && !aiTyping && (
                <TypingIndicator key="peer-typing" label={peerTypingName} />
              )}
            </AnimatePresence>
          </div>
        )}
        {doctorCards && (
          <div ref={doctorCardsRef}>
            <DoctorCardsPanel
              specialty={doctorCards.specialty}
              experts={doctorCards.experts}
              onClose={() => setDoctorCards(null)}
              onUpgrade={() => setShowPremium(true)}
              onConsult={handleConsult}
            />
          </div>
        )}

        {/* Summary card — only for closed conversations */}
        {conv?.status === 'closed' && (
          <ConsultationSummaryCard
            summary={conv.summary}
            conversationId={id}
            onDownload={handleDownloadReport}
            downloading={downloadingReport}
          />
        )}

        <div ref={bottomRef} />
      </div>

      {/* Input */}
      {recorder.recording ? (
        <div className="conv-input-bar conv-input-bar--recording">
          <div className="rec-pill">
            <button className="rec-cancel-btn" onClick={recorder.cancel} title="Annuler">
              <X size={16} />
            </button>
            <span className="rec-time">{formatDuration(recorder.seconds)}</span>
            <LiveWaveform stream={recorder.stream} />
            <button className="rec-stop-btn" onClick={recorder.stop} title="Arrêter">
              <Square size={16} fill="currentColor" />
            </button>
          </div>
        </div>
      ) : recorder.blob ? (
        <div className="conv-input-bar conv-input-bar--preview">
          <voice-preview ref={vpRef} send-label="Envoyer" />
        </div>
      ) : (
        <div className="conv-input-bar">
          {/* File upload — only available in doctor conversations (expert or escalated), not AI-only */}
          {(() => {
            const withDoctor = (conv?.status === 'expert' || conv?.channel === 'expert' || conv?.channel === 'hybrid' || isExpert)
              && (isExpert || user?.plan !== 'free');
            return withDoctor ? (
              <>
                <input
                  ref={fileInputRef}
                  type="file"
                  accept="image/jpeg,image/png,image/gif,image/webp,application/pdf,.doc,.docx,.xls,.xlsx,.txt"
                  style={{ display: 'none' }}
                  onChange={handleFilePick}
                />
                <button
                  className="conv-icon-btn"
                  onClick={() => fileInputRef.current?.click()}
                  disabled={conv?.status === 'closed' || sendingFile}
                  title="Joindre un fichier ou une image"
                >
                  {sendingFile ? <Loader2 size={18} className="spin" /> : <Paperclip size={18} />}
                </button>
              </>
            ) : null;
          })()}
          <textarea
            ref={inputRef}
            className="conv-input"
            placeholder={isExpert ? 'Répondre au patient…' : 'Décrivez votre symptôme…'}
            value={input}
            onChange={handleInputChange}
            onKeyDown={handleKeyDown}
            rows={1}
            disabled={conv?.status === 'closed'}
          />
          <button
            className="conv-icon-btn"
            onClick={recorder.start}
            disabled={conv?.status === 'closed'}
            title="Enregistrer un message vocal"
          >
            <Mic size={18} />
          </button>
          <button
            className="conv-send-btn"
            onClick={handleSend}
            disabled={!input.trim() || sending || conv?.status === 'closed'}
          >
            {sending ? <Loader2 size={20} className="spin" /> : <Send size={20} />}
          </button>
        </div>
      )}
      {conv?.status === 'closed' && conv?.expert_id && !conv?.rating && !isExpert && (
        <RatingCard conversationId={id} />
      )}
      {conv?.status === 'closed' && (
        <p className="conv-closed-note">Cette conversation est terminée.</p>
      )}

      {/* ── Premium modal ── */}
      <AnimatePresence>
        {showPremium && <PremiumModal onClose={() => setShowPremium(false)} />}
      </AnimatePresence>
    </div>
  );
}
