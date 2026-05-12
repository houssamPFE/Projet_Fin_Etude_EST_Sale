import { useEffect, useRef, useState } from 'react';
import { motion } from 'framer-motion';
import {
  Bot,
  Check,
  Loader2,
  MessageSquare,
  MoreVertical,
  Pencil,
  Plus,
  Trash2,
  X,
} from 'lucide-react';
import { Link, useNavigate } from 'react-router-dom';
import {
  useConversations,
  useDeleteConversation,
  useUpdateConversation,
} from '../../hooks/useConversations';
import useAuthStore from '../../stores/authStore';
import { getEcho } from '../../lib/echo';
import './ConversationsPage.css';

// ── Helpers ──────────────────────────────────────────────────────────────────

/** Initials from a name — up to 2 chars */
function initials(name) {
  if (!name) return '?';
  const parts = name.trim().split(/\s+/);
  if (parts.length === 1) return parts[0][0].toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
}

/** Consistent accent color from name */
const AVATAR_COLORS = ['#6366F1','#8B5CF6','#0D9488','#2563EB','#D97706','#DC2626','#0891B2'];
function avatarColor(name) {
  if (!name) return AVATAR_COLORS[0];
  let hash = 0;
  for (let i = 0; i < name.length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash);
  return AVATAR_COLORS[Math.abs(hash) % AVATAR_COLORS.length];
}

/** WhatsApp-style time: today → HH:MM, yesterday → "Hier", older → date */
function convTime(iso) {
  if (!iso) return '';
  const d = new Date(iso);
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const yesterday = new Date(today - 86400000);
  const msgDay = new Date(d.getFullYear(), d.getMonth(), d.getDate());
  if (msgDay >= today) return d.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' });
  if (msgDay >= yesterday) return 'Hier';
  return d.toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit' });
}

/** Get the display name for the other participant */
function getOtherName(conv, isExpert) {
  if (conv.status === 'ai' || !conv.expert) return 'IA Nexora';
  return isExpert ? (conv.user?.name ?? 'Patient') : (conv.expert?.user?.name ?? 'Expert');
}

/** Last message preview text — contextual prefix for each sender */
function lastMsgPreview(conv, currentUserId, isExpert) {
  const msg = conv.last_message;
  if (!msg) return 'Démarrer la conversation…';

  const isOwn = isExpert
    ? msg.sender_type === 'expert' && msg.sender_id === currentUserId
    : msg.sender_type === 'user'   && msg.sender_id === currentUserId;

  let prefix;
  if (isOwn) {
    prefix = 'Vous : ';
  } else if (msg.sender_type === 'ai') {
    prefix = 'IA : ';
  } else if (msg.sender_type === 'expert') {
    prefix = 'Dr : ';         // patient sees "Dr : [reply]"
  } else {
    prefix = 'Patient : ';    // expert sees "Patient : [message]"
  }

  if (msg.type === 'audio') return `${prefix}🎤 Message vocal`;
  if (msg.type === 'file')  return `${prefix}📎 Fichier`;
  return prefix + (msg.content ?? '');
}

function ConversationActions({ conv, disabled, onRename, onDelete }) {
  const [open, setOpen] = useState(false);
  const ref = useRef(null);

  useEffect(() => {
    if (!open) return undefined;

    const handlePointerDown = (event) => {
      if (ref.current && !ref.current.contains(event.target)) {
        setOpen(false);
      }
    };

    document.addEventListener('mousedown', handlePointerDown);
    return () => document.removeEventListener('mousedown', handlePointerDown);
  }, [open]);

  return (
    <div className="conv-menu" ref={ref}>
      <button
        type="button"
        className="conv-menu-btn"
        aria-label="Options"
        aria-expanded={open}
        disabled={disabled}
        onClick={(event) => {
          event.preventDefault();
          event.stopPropagation();
          setOpen((value) => !value);
        }}
      >
        <MoreVertical size={16} />
      </button>

      {open && (
        <div className="conv-menu-panel">
          <button
            type="button"
            className="conv-menu-item"
            onClick={(event) => {
              event.preventDefault();
              event.stopPropagation();
              setOpen(false);
              onRename(conv);
            }}
          >
            <Pencil size={14} />
            Renommer
          </button>
          <button
            type="button"
            className="conv-menu-item conv-menu-item--danger"
            onClick={(event) => {
              event.preventDefault();
              event.stopPropagation();
              setOpen(false);
              onDelete(conv);
            }}
          >
            <Trash2 size={14} />
            Supprimer
          </button>
        </div>
      )}
    </div>
  );
}

export default function ConversationsPage() {
  const navigate = useNavigate();
  const user = useAuthStore((state) => state.user);
  const isExpert = user?.role === 'expert';
  const [page, setPage] = useState(1);
  const [renaming, setRenaming] = useState(null);
  const [newTitle, setNewTitle] = useState('');
  const [confirmingDelete, setConfirmingDelete] = useState(null);
  // Real-time online overrides: { [convId]: bool } — updated via WebSocket
  const [onlineOverrides, setOnlineOverrides] = useState({});
  const subscribedIdsRef = useRef(new Set());

  const { data, isLoading, isFetching } = useConversations({ page, per_page: 12 });
  const updateConversation = useUpdateConversation();
  const deleteConversation = useDeleteConversation();

  const conversations = data?.data ?? [];
  const meta = data?.meta ?? {};

  // Subscribe to user.presence events for every conversation on this page
  // so the online dot updates in real-time without entering the conversation.
  useEffect(() => {
    if (!conversations.length) return;
    const echo = getEcho();

    conversations.forEach((conv) => {
      if (subscribedIdsRef.current.has(conv.id)) return; // already listening
      subscribedIdsRef.current.add(conv.id);

      echo.private(`conversation.${conv.id}`)
        .listen('.user.presence', (event) => {
          if (event.user_id === user?.id) return; // ignore own events
          setOnlineOverrides((prev) => ({ ...prev, [conv.id]: event.is_online }));
        });
    });

    // Leave channels that are no longer in the current page
    return () => {
      subscribedIdsRef.current.forEach((id) => {
        const still = conversations.some((c) => c.id === id);
        if (!still) {
          echo.leave(`conversation.${id}`);
          subscribedIdsRef.current.delete(id);
        }
      });
    };
  }, [conversations, user?.id]);

  // Full cleanup on unmount
  useEffect(() => {
    return () => {
      const echo = getEcho();
      subscribedIdsRef.current.forEach((id) => echo.leave(`conversation.${id}`));
      subscribedIdsRef.current.clear();
    };
  }, []);
  const actionsBusy = updateConversation.isPending || deleteConversation.isPending;

  useEffect(() => {
    if (!isLoading && page > 1 && conversations.length === 0) {
      setPage((currentPage) => Math.max(1, currentPage - 1));
    }
  }, [conversations.length, isLoading, page]);

  const canManageConversation = (conversation) => {
    return user?.role === 'admin' || conversation.user?.id === user?.id;
  };

  const openRename = (conversation) => {
    setRenaming(conversation);
    setNewTitle(conversation.title ?? `Conversation #${conversation.id}`);
  };

  const submitRename = (event) => {
    event.preventDefault();
    if (!renaming || !newTitle.trim()) return;

    updateConversation.mutate(
      { id: renaming.id, title: newTitle.trim() },
      { onSuccess: () => setRenaming(null) }
    );
  };

  const submitDelete = () => {
    if (!confirmingDelete) return;

    deleteConversation.mutate(confirmingDelete.id, {
      onSuccess: () => setConfirmingDelete(null),
    });
  };

  return (
    <div className="convs-page">
      <motion.div
        className="convs-shell"
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4 }}
      >
        <div className="convs-header">
          <div>
            <h1 className="page-title">Conversations</h1>
            <p className="page-subtitle">
              {isExpert
                ? 'Toutes vos consultations patients'
                : 'Toutes vos conversations avec l\'IA et les experts'}
            </p>
          </div>
          {!isExpert && (
            <button type="button" className="btn btn-primary" onClick={() => navigate('/conversations/new')}>
              <Plus size={18} />
              Nouvelle conversation
            </button>
          )}
        </div>

        {isLoading ? (
          <div className="convs-loading">
            <Loader2 size={32} className="spin" style={{ color: 'var(--primary-500)' }} />
          </div>
        ) : conversations.length === 0 ? (
          <div className="convs-empty card">
            <MessageSquare size={48} style={{ color: 'var(--text-muted)', marginBottom: 16 }} />
            <p style={{ color: 'var(--text-muted)', margin: 0 }}>
              {isExpert
                ? 'Aucune consultation pour le moment.'
                : 'Aucune conversation pour le moment.'}
            </p>
            {!isExpert && (
              <button
                type="button"
                className="btn btn-primary"
                style={{ marginTop: 16 }}
                onClick={() => navigate('/conversations/new')}
              >
                Commencer une conversation
              </button>
            )}
          </div>
        ) : (
          <>
            <div className="convs-list">
              {conversations.map((conversation, index) => {
                const metaParts = [
                  conversation.category?.name,
                  conversation.expert?.user?.name,
                ].filter(Boolean);

                const otherName    = getOtherName(conversation, isExpert);
                const isAiConv     = conversation.status === 'ai' || !conversation.expert;
                const otherUser    = isExpert ? conversation.user : conversation.expert?.user;
                // WS override takes precedence over stale API value
                const isOnline     = onlineOverrides[conversation.id] !== undefined
                  ? onlineOverrides[conversation.id]
                  : (otherUser?.is_online ?? false);
                const unread       = conversation.unread_count ?? 0;
                const preview      = lastMsgPreview(conversation, user?.id, isExpert);
                const time         = convTime(conversation.last_message?.created_at ?? conversation.updated_at);
                const bg           = isAiConv ? '#6366F1' : avatarColor(otherName);

                return (
                  <motion.div
                    key={conversation.id}
                    initial={{ opacity: 0, x: -10 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ duration: 0.3, delay: Math.min(index * 0.03, 0.3) }}
                  >
                    <div className={`conv-item ${unread > 0 ? 'conv-item--unread' : ''}`}>
                      <Link to={`/conversations/${conversation.id}`} className="conv-link">
                        {/* Avatar */}
                        <div className="conv-avatar-wrap">
                          <div className="conv-avatar" style={{ background: bg }}>
                            {isAiConv
                              ? <Bot size={18} color="#fff" />
                              : <span>{initials(otherName)}</span>}
                          </div>
                          {isOnline && <span className="conv-online-dot" />}
                        </div>

                        {/* Content */}
                        <div className="conv-info">
                          <div className="conv-info-top">
                            <p className="conv-title">{otherName}</p>
                            <span className="conv-time">{time}</span>
                          </div>
                          <div className="conv-info-bottom">
                            <p className="conv-preview">{preview}</p>
                            {unread > 0 && (
                              <span className="conv-unread-badge">
                                {unread > 99 ? '99+' : unread}
                              </span>
                            )}
                          </div>
                        </div>
                      </Link>

                      {canManageConversation(conversation) && (
                        <ConversationActions
                          conv={conversation}
                          disabled={actionsBusy}
                          onRename={openRename}
                          onDelete={setConfirmingDelete}
                        />
                      )}
                    </div>
                  </motion.div>
                );
              })}
            </div>

            {meta.last_page > 1 && (
              <div className="pagination">
                <button
                  type="button"
                  className="btn btn-secondary btn-sm"
                  disabled={page === 1 || isFetching}
                  onClick={() => setPage((currentPage) => currentPage - 1)}
                >
                  Precedent
                </button>
                <span className="pagination-info">
                  Page {meta.current_page ?? page} / {meta.last_page}
                </span>
                <button
                  type="button"
                  className="btn btn-secondary btn-sm"
                  disabled={page === meta.last_page || isFetching}
                  onClick={() => setPage((currentPage) => currentPage + 1)}
                >
                  Suivant
                </button>
              </div>
            )}
          </>
        )}
      </motion.div>

      {renaming && (
        <div className="conv-modal-overlay" onClick={() => setRenaming(null)}>
          <form className="conv-modal" onClick={(event) => event.stopPropagation()} onSubmit={submitRename}>
            <div className="conv-modal-header">
              <h3>Renommer la conversation</h3>
              <button type="button" className="conv-modal-close" onClick={() => setRenaming(null)}>
                <X size={18} />
              </button>
            </div>

            <input
              type="text"
              className="conv-modal-input"
              value={newTitle}
              maxLength={255}
              autoFocus
              onChange={(event) => setNewTitle(event.target.value)}
            />

            <div className="conv-modal-actions">
              <button type="button" className="btn btn-secondary" onClick={() => setRenaming(null)}>
                Annuler
              </button>
              <button
                type="submit"
                className="btn btn-primary"
                disabled={updateConversation.isPending || !newTitle.trim()}
              >
                {updateConversation.isPending ? <Loader2 size={14} className="spin" /> : <Check size={14} />}
                Enregistrer
              </button>
            </div>
          </form>
        </div>
      )}

      {confirmingDelete && (
        <div className="conv-modal-overlay" onClick={() => setConfirmingDelete(null)}>
          <div className="conv-modal" onClick={(event) => event.stopPropagation()}>
            <div className="conv-modal-header">
              <h3>Supprimer cette conversation ?</h3>
              <button type="button" className="conv-modal-close" onClick={() => setConfirmingDelete(null)}>
                <X size={18} />
              </button>
            </div>

            <p className="conv-modal-text">
              Vous etes sur le point de supprimer &quot;
              {confirmingDelete.title ?? `Conversation #${confirmingDelete.id}`}
              &quot;. Cette action est irreversible.
            </p>

            <div className="conv-modal-actions">
              <button type="button" className="btn btn-secondary" onClick={() => setConfirmingDelete(null)}>
                Annuler
              </button>
              <button
                type="button"
                className="btn btn-danger"
                disabled={deleteConversation.isPending}
                onClick={submitDelete}
              >
                {deleteConversation.isPending ? <Loader2 size={14} className="spin" /> : <Trash2 size={14} />}
                Supprimer
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
