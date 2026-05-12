import { useEffect, useRef, useState, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ArrowLeft, Send, Loader2, Bot, User, UserCheck, ShieldAlert, Phone, Mic, Square, X } from 'lucide-react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQueryClient } from '@tanstack/react-query';
import { useConversation } from '../../hooks/useConversations';
import { useMessages, useSendMessage, useSendAudio, useMarkAllRead } from '../../hooks/useMessages';
import useAudioRecorder from '../../hooks/useAudioRecorder';
import AudioMessage from '../../components/AudioMessage';
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

function MessageBubble({ message, currentUser, isDeleted }) {
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
    if (message.sender_type === 'expert') return 'Expert';
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
            ) : (
              <p className="msg-content">{message.content}</p>
            )}
          </div>
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
  const { mutate: markAllRead } = useMarkAllRead(id);

  const recorder = useAudioRecorder();

  const [input, setInput] = useState('');
  const [aiTyping, setAiTyping] = useState(false);
  const [peerTyping, setPeerTyping] = useState(false);   // other person is typing
  const [peerTypingName, setPeerTypingName] = useState('');
  // Real-time online override — null means "use value from conversation query"
  const [presenceOverride, setPresenceOverride] = useState(null);
  // Track real-time deleted message IDs (WS push while page is open)
  const [deletedIds, setDeletedIds] = useState(new Set());
  const bottomRef = useRef(null);
  const inputRef = useRef(null);
  const typingTimerRef = useRef(null);   // debounce: stop-typing after 2s idle
  const isTypingRef = useRef(false);     // avoid duplicate API calls

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
    channel.listen('.message.sent', (event) => {
      if (event.message?.sender_id !== user?.id) {
        queryClient.invalidateQueries({ queryKey: ['messages', id] });
      }
      setAiTyping(false);
    });

    // AIResponseReady uses broadcastAs('ai.response')
    channel.listen('.ai.response', () => {
      queryClient.invalidateQueries({ queryKey: ['messages', id] });
      setAiTyping(false);
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
      } else {
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
    // Only show AI typing when a patient sends in an AI/open conversation
    if (!isExpert && conv?.status !== 'expert' && conv?.status !== 'closed') {
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

  // Stop typing on unmount / send
  useEffect(() => () => {
    clearTimeout(typingTimerRef.current);
    sendTypingStop();
  }, [sendTypingStop]);

  useEffect(() => {
    if (recorder.error) toast.error(recorder.error);
  }, [recorder.error]);

  const handleSendAudio = async () => {
    if (!recorder.blob || sendingAudio) return;
    try {
      if (!isExpert && conv?.status !== 'expert' && conv?.status !== 'closed') {
        setAiTyping(true);
      }
      await sendAudio(recorder.blob);
      recorder.reset();
    } catch {
      toast.error('Échec de l\'envoi du message vocal.');
      setAiTyping(false);
    }
  };

  const messages = messagesData?.data ?? [];
  const conv = conversation ?? null;
  const hasEmergency = messages.some(
    (m) => m.metadata?.urgency_level === 'emergency'
  );

  return (
    <div className="conv-page">
      {/* Header */}
      {(() => {
        const otherUser  = isExpert ? conv?.user : conv?.expert?.user;
        // presenceOverride: set instantly by WS; cleared when query re-fetches with fresh value
        const isOnline   = presenceOverride !== null ? presenceOverride : (otherUser?.is_online ?? false);
        const headerName = isExpert
          ? (conv?.user?.name ?? `Conversation #${id}`)
          : (conv?.status === 'ai' || !conv?.expert)
            ? 'IA Nexora'
            : (conv?.expert?.user?.name ?? `Conversation #${id}`);

        return (
          <div className="conv-page-header">
            <button className="back-btn" onClick={() => navigate('/conversations')}>
              <ArrowLeft size={18} />
            </button>
            <div className="conv-page-header-info">
              <h2 className="conv-page-title">{headerName}</h2>
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
                    {conv?.category?.name ?? ''}
                  </motion.span>
                )}
              </AnimatePresence>
            </div>
            {conv?.status && (
              <span className={`conv-page-badge conv-page-badge--${conv.status}`}>
                {conv.status === 'ai' ? 'IA' : conv.status === 'expert' ? 'Médecin' : conv.status === 'closed' ? 'Fermé' : 'Ouvert'}
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
            appelez immédiatement le SAMU au <a href="tel:141"><Phone size={12} /> 141</a> ou
            rendez-vous aux urgences les plus proches.
          </div>
        </div>
      )}

      {/* Messages */}
      <div className="conv-messages">
        <div className="conv-disclaimer">
          <Bot size={14} />
          Les informations fournies par l'IA sont à titre informatif uniquement et
          ne remplacent pas une consultation médicale. En cas d'urgence, appelez le 141.
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
        <div ref={bottomRef} />
      </div>

      {/* Input */}
      {recorder.recording ? (
        <div className="conv-input-bar conv-input-bar--recording">
          <span className="rec-dot" />
          <span className="rec-time">{formatDuration(recorder.seconds)}</span>
          <span className="rec-label">Enregistrement…</span>
          <button className="conv-icon-btn conv-icon-btn--danger" onClick={recorder.cancel} title="Annuler">
            <X size={18} />
          </button>
          <button className="conv-send-btn" onClick={recorder.stop} title="Arrêter">
            <Square size={18} />
          </button>
        </div>
      ) : recorder.blob ? (
        <div className="conv-input-bar conv-input-bar--preview">
          <div className="rec-preview-wrapper msg-bubble msg-bubble--own">
            <AudioMessage src={URL.createObjectURL(recorder.blob)} variant="own" />
          </div>
          <button className="conv-icon-btn conv-icon-btn--danger" onClick={recorder.reset} title="Annuler">
            <X size={18} />
          </button>
          <button className="conv-send-btn" onClick={handleSendAudio} disabled={sendingAudio}>
            {sendingAudio ? <Loader2 size={20} className="spin" /> : <Send size={20} />}
          </button>
        </div>
      ) : (
        <div className="conv-input-bar">
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
      {conv?.status === 'closed' && (
        <p className="conv-closed-note">Cette conversation est terminée.</p>
      )}
    </div>
  );
}
