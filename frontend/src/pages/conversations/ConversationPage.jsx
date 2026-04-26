import { useEffect, useRef, useState, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ArrowLeft, Send, Loader2, Bot, User, UserCheck, ShieldAlert, Phone } from 'lucide-react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQueryClient } from '@tanstack/react-query';
import { useConversation } from '../../hooks/useConversations';
import { useMessages, useSendMessage } from '../../hooks/useMessages';
import { getEcho } from '../../lib/echo';
import useAuthStore from '../../stores/authStore';
import toast from 'react-hot-toast';
import './ConversationPage.css';

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

function MessageBubble({ message, currentUserId }) {
  const isOwn = message.sender_type === 'user' && message.sender_id === currentUserId;
  const Icon = SENDER_ICONS[message.sender_type] ?? User;

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
          <span className="msg-sender-label">{SENDER_LABELS[message.sender_type]}</span>
        )}
        <div className={`msg-bubble msg-bubble--${isOwn ? 'own' : message.sender_type}`}>
          <p className="msg-content">{message.content}</p>
        </div>
      </div>
    </motion.div>
  );
}

function TypingIndicator() {
  return (
    <div className="msg-row msg-row--ai">
      <div className="msg-avatar msg-avatar--ai">
        <Bot size={16} />
      </div>
      <div className="msg-bubble-wrap">
        <span className="msg-sender-label">IA Nexora</span>
        <div className="msg-bubble msg-bubble--ai msg-bubble--typing">
          <span className="typing-dot" />
          <span className="typing-dot" />
          <span className="typing-dot" />
        </div>
      </div>
    </div>
  );
}

export default function ConversationPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const user = useAuthStore((s) => s.user);
  const queryClient = useQueryClient();

  const { data: conversation } = useConversation(id);
  const { data: messagesData, isLoading: messagesLoading } = useMessages(id);
  const { mutateAsync: sendMessage, isPending: sending } = useSendMessage(id);

  const [input, setInput] = useState('');
  const [aiTyping, setAiTyping] = useState(false);
  const bottomRef = useRef(null);
  const inputRef = useRef(null);

  const scrollToBottom = useCallback(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, []);

  useEffect(() => {
    scrollToBottom();
  }, [messagesData, aiTyping, scrollToBottom]);

  // Real-time Echo subscription
  useEffect(() => {
    const echo = getEcho();
    const channel = echo.private(`conversation.${id}`);

    channel.listen('.MessageSent', (event) => {
      if (event.message?.sender_id !== user?.id) {
        queryClient.invalidateQueries({ queryKey: ['messages', id] });
      }
      setAiTyping(false);
    });

    channel.listen('.AIResponseReady', () => {
      queryClient.invalidateQueries({ queryKey: ['messages', id] });
      setAiTyping(false);
    });

    return () => {
      channel.stopListening('.MessageSent');
      channel.stopListening('.AIResponseReady');
      echo.leave(`conversation.${id}`);
    };
  }, [id, user?.id, queryClient]);

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
    setAiTyping(true);
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

  const messages = messagesData?.data ?? [];
  const conv = conversation?.data ?? null;
  const hasEmergency = messages.some(
    (m) => m.metadata?.urgency_level === 'emergency'
  );

  return (
    <div className="conv-page">
      {/* Header */}
      <div className="conv-page-header">
        <button className="back-btn" onClick={() => navigate('/conversations')}>
          <ArrowLeft size={18} />
        </button>
        <div className="conv-page-header-info">
          <h2 className="conv-page-title">
            {conv?.title ?? `Conversation #${id}`}
          </h2>
          <span className="conv-page-meta">
            {conv?.category?.name}
            {conv?.expert && ` · ${conv.expert.user?.name}`}
          </span>
        </div>
        {conv?.status && (
          <span className={`conv-page-badge conv-page-badge--${conv.status}`}>
            {conv.status === 'ai' ? 'IA' : conv.status === 'expert' ? 'Médecin' : conv.status === 'closed' ? 'Fermé' : 'Ouvert'}
          </span>
        )}
      </div>

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

      <div className="conv-disclaimer">
        Les informations fournies par l'IA sont à titre informatif uniquement et
        ne remplacent pas une consultation médicale. En cas d'urgence, appelez le 141.
      </div>

      {/* Messages */}
      <div className="conv-messages">
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
              <MessageBubble key={msg.id} message={msg} currentUserId={user?.id} />
            ))}
            <AnimatePresence>
              {aiTyping && <TypingIndicator key="typing" />}
            </AnimatePresence>
          </div>
        )}
        <div ref={bottomRef} />
      </div>

      {/* Input */}
      <div className="conv-input-bar">
        <textarea
          ref={inputRef}
          className="conv-input"
          placeholder="Décrivez votre symptôme..."
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={handleKeyDown}
          rows={1}
          disabled={conv?.status === 'closed'}
        />
        <button
          className="conv-send-btn"
          onClick={handleSend}
          disabled={!input.trim() || sending || conv?.status === 'closed'}
        >
          {sending ? <Loader2 size={20} className="spin" /> : <Send size={20} />}
        </button>
      </div>
      {conv?.status === 'closed' && (
        <p className="conv-closed-note">Cette conversation est terminée.</p>
      )}
    </div>
  );
}
