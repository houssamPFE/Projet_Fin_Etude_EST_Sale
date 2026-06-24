import { useEffect, useRef, useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Check, CheckCheck, ChevronDown, Loader2,
  MessageSquare, MoreVertical, Pencil, Plus, Search,
  Trash2, Users, X, Archive, SortAsc, Mic,
} from 'lucide-react';
import { Link, useNavigate } from 'react-router-dom';
import { useQueryClient } from '@tanstack/react-query';
import {
  useConversations,
  useDeleteConversation,
  useUpdateConversation,
  useCloseConversation,
} from '../../hooks/useConversations';
import useAuthStore from '../../stores/authStore';
import { getEcho } from '../../lib/echo';
import './ConversationsPage.css';

// ── Helpers ───────────────────────────────────────────────────────────────────

function initials(name) {
  if (!name) return '?';
  const parts = name.trim().split(/\s+/);
  if (parts.length === 1) return parts[0][0].toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
}

const AVATAR_COLORS = [
  '#6366F1','#8B5CF6','#0D9488','#2563EB','#D97706','#DC2626','#0891B2','#7C3AED',
];
function avatarColor(name) {
  if (!name) return AVATAR_COLORS[0];
  let hash = 0;
  for (let i = 0; i < name.length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash);
  return AVATAR_COLORS[Math.abs(hash) % AVATAR_COLORS.length];
}

function convTime(iso) {
  if (!iso) return '';
  const d = new Date(iso);
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const yesterday = new Date(today - 86400000);
  const msgDay = new Date(d.getFullYear(), d.getMonth(), d.getDate());
  if (msgDay >= today) return d.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' });
  if (msgDay >= yesterday) return 'Hier';
  if (today - msgDay < 7 * 86400000) return d.toLocaleDateString('fr-FR', { weekday: 'short' });
  return d.toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit' });
}

function getOtherName(conv, isExpert) {
  if (conv.status === 'ai' || !conv.expert) return 'IA Nexora';
  return isExpert ? (conv.user?.name ?? 'Patient') : (conv.expert?.user?.name ?? 'Expert');
}

function lastMsgPreview(conv, currentUserId, isExpert) {
  const msg = conv.last_message;
  if (!msg) return 'Démarrer la conversation…';
  const isOwn = isExpert
    ? msg.sender_type === 'expert' && msg.sender_id === currentUserId
    : msg.sender_type === 'user' && msg.sender_id === currentUserId;
  let prefix = isOwn ? 'Vous : ' : msg.sender_type === 'ai' ? 'IA : ' : msg.sender_type === 'expert' ? 'Dr : ' : 'Patient : ';
  if (msg.type === 'audio') return `${prefix}🎤 Message vocal`;
  if (msg.type === 'file') return `${prefix}📎 Fichier`;
  return prefix + (msg.content ?? '');
}

const STATUS_CONFIG = {
  ai:     { label: 'IA',       color: '#8B5CF6', bg: 'rgba(139,92,246,0.15)' },
  expert: { label: 'En cours', color: '#0D9488', bg: 'rgba(13,148,136,0.15)' },
  open:   { label: 'Ouvert',   color: '#2563EB', bg: 'rgba(37,99,235,0.15)' },
  closed: { label: 'Fermé',    color: '#64748B', bg: 'rgba(100,116,139,0.15)' },
};

// ── Stat Card ─────────────────────────────────────────────────────────────────

function StatCard({ icon: Icon, value, label, color }) {
  return (
    <div className="cex-stat">
      <div className="cex-stat-icon" style={{ background: `${color}18`, color }}>
        <Icon size={16} />
      </div>
      <div>
        <p className="cex-stat-value">{value}</p>
        <p className="cex-stat-label">{label}</p>
      </div>
    </div>
  );
}

// ── Action Menu ───────────────────────────────────────────────────────────────

function ConvActions({ conv, isExpert, disabled, onRename, onDelete, onClose }) {
  const [open, setOpen] = useState(false);
  const ref = useRef(null);
  const isClosed = conv.status === 'closed';

  useEffect(() => {
    if (!open) return;
    const handler = (e) => { if (ref.current && !ref.current.contains(e.target)) setOpen(false); };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, [open]);

  return (
    <div className="cex-menu" ref={ref}>
      <button
        type="button"
        className="cex-menu-btn"
        disabled={disabled}
        aria-expanded={open}
        onClick={(e) => { e.preventDefault(); e.stopPropagation(); setOpen(v => !v); }}
      >
        <MoreVertical size={15} />
      </button>
      <AnimatePresence>
        {open && (
          <motion.div
            className="cex-menu-panel"
            initial={{ opacity: 0, scale: 0.94, y: -6 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.94, y: -6 }}
            transition={{ duration: 0.14 }}
          >
            {!isExpert && (
              <button type="button" className="cex-menu-item" onClick={(e) => { e.stopPropagation(); setOpen(false); onRename(conv); }}>
                <Pencil size={13} /> Renommer
              </button>
            )}
            {!isClosed && (
              <button type="button" className="cex-menu-item" onClick={(e) => { e.stopPropagation(); setOpen(false); onClose(conv); }}>
                <Archive size={13} /> Clôturer
              </button>
            )}
            <button type="button" className="cex-menu-item cex-menu-item--danger" onClick={(e) => { e.stopPropagation(); setOpen(false); onDelete(conv); }}>
              <Trash2 size={13} /> Supprimer
            </button>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

// ── Main Page ─────────────────────────────────────────────────────────────────

const FILTERS = ['Tous', 'Non lus', 'Actifs', 'Fermés'];
const SORTS   = [
  { key: 'recent', label: 'Plus récents' },
  { key: 'oldest', label: 'Plus anciens' },
  { key: 'az',     label: 'A → Z' },
  { key: 'unread', label: 'Non lus d\'abord' },
];

export default function ConversationsPage() {
  const navigate = useNavigate();
  const user = useAuthStore((s) => s.user);
  const isExpert = user?.role === 'expert';
  const qc = useQueryClient();

  const [page, setPage]                   = useState(1);
  const [search, setSearch]               = useState('');
  const [activeFilter, setActiveFilter]   = useState('Tous');
  const [sortKey, setSortKey]             = useState('recent');
  const [showSort, setShowSort]           = useState(false);
  const [renaming, setRenaming]           = useState(null);
  const [newTitle, setNewTitle]           = useState('');
  const [confirmDelete, setConfirmDelete] = useState(null);
  const [confirmClose, setConfirmClose]   = useState(null);
  const [onlineOverrides, setOnlineOverrides] = useState({});
  const subscribedIdsRef = useRef(new Set());
  const sortRef = useRef(null);

  const { data, isLoading, isFetching } = useConversations({ page, per_page: 20 });
  const updateConv  = useUpdateConversation();
  const deleteConv  = useDeleteConversation();
  const closeConv   = useCloseConversation();

  const allConversations = data?.data ?? [];
  const meta = data?.meta ?? {};

  // Real-time deletion listener
  useEffect(() => {
    if (!user?.id) return;
    const echo = getEcho();
    const ch = echo.private(`user.${user.id}`);
    ch.listen('.conversation.deleted', () => qc.invalidateQueries({ queryKey: ['conversations'] }));
    return () => ch.stopListening('.conversation.deleted');
  }, [user?.id, qc]);

  // Presence subscriptions
  useEffect(() => {
    if (!allConversations.length) return;
    const echo = getEcho();
    allConversations.forEach((conv) => {
      if (subscribedIdsRef.current.has(conv.id)) return;
      subscribedIdsRef.current.add(conv.id);
      echo.private(`conversation.${conv.id}`).listen('.user.presence', (e) => {
        if (e.user_id === user?.id) return;
        setOnlineOverrides(prev => ({ ...prev, [conv.id]: e.is_online }));
      });
    });
    return () => {
      subscribedIdsRef.current.forEach((id) => {
        if (!allConversations.some(c => c.id === id)) {
          echo.leave(`conversation.${id}`);
          subscribedIdsRef.current.delete(id);
        }
      });
    };
  }, [allConversations, user?.id]);

  useEffect(() => () => {
    const echo = getEcho();
    subscribedIdsRef.current.forEach(id => echo.leave(`conversation.${id}`));
    subscribedIdsRef.current.clear();
  }, []);

  // Close sort dropdown on outside click
  useEffect(() => {
    if (!showSort) return;
    const handler = (e) => { if (sortRef.current && !sortRef.current.contains(e.target)) setShowSort(false); };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, [showSort]);

  // Auto-correct page
  useEffect(() => {
    if (!isLoading && page > 1 && allConversations.length === 0) setPage(p => Math.max(1, p - 1));
  }, [allConversations.length, isLoading, page]);

  // Stats
  const stats = useMemo(() => {
    const total  = allConversations.length;
    const unread = allConversations.filter(c => (c.unread_count ?? 0) > 0).length;
    const active = allConversations.filter(c => c.status !== 'closed').length;
    return { total, unread, active };
  }, [allConversations]);

  // Filter + sort
  const filtered = useMemo(() => {
    let list = allConversations;

    // Tab filter
    if (activeFilter === 'Non lus') list = list.filter(c => (c.unread_count ?? 0) > 0);
    else if (activeFilter === 'Actifs') list = list.filter(c => c.status !== 'closed');
    else if (activeFilter === 'Fermés') list = list.filter(c => c.status === 'closed');

    // Search
    if (search.trim()) {
      const q = search.toLowerCase();
      list = list.filter(c => {
        const name = getOtherName(c, isExpert).toLowerCase();
        const preview = (c.last_message?.content ?? '').toLowerCase();
        const title = (c.title ?? '').toLowerCase();
        return name.includes(q) || preview.includes(q) || title.includes(q);
      });
    }

    // Sort
    list = [...list].sort((a, b) => {
      if (sortKey === 'oldest') return new Date(a.updated_at) - new Date(b.updated_at);
      if (sortKey === 'az') return getOtherName(a, isExpert).localeCompare(getOtherName(b, isExpert));
      if (sortKey === 'unread') return (b.unread_count ?? 0) - (a.unread_count ?? 0);
      return new Date(b.updated_at) - new Date(a.updated_at); // recent
    });

    return list;
  }, [allConversations, activeFilter, search, sortKey, isExpert]);

  const actionsBusy = updateConv.isPending || deleteConv.isPending || closeConv.isPending;

  const submitRename = (e) => {
    e.preventDefault();
    if (!renaming || !newTitle.trim()) return;
    updateConv.mutate({ id: renaming.id, title: newTitle.trim() }, { onSuccess: () => setRenaming(null) });
  };

  const submitDelete = () => {
    if (!confirmDelete) return;
    deleteConv.mutate(confirmDelete.id, { onSuccess: () => setConfirmDelete(null) });
  };

  const submitClose = () => {
    if (!confirmClose) return;
    closeConv.mutate(confirmClose.id, { onSuccess: () => setConfirmClose(null) });
  };

  const currentSortLabel = SORTS.find(s => s.key === sortKey)?.label ?? 'Trier';

  return (
    <div className="cex-page">
      <motion.div initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.35 }}>

        {/* ── Header ─────────────────────────────────────────────────── */}
        <div className="cex-header">
          <div>
            <h1 className="cex-title">
              {isExpert ? 'Mes consultations' : 'Conversations'}
            </h1>
            <p className="cex-subtitle">
              {isExpert ? 'Gérez vos patients et consultations en cours' : 'Toutes vos conversations avec l\'IA et les experts'}
            </p>
          </div>
          {!isExpert && (
            <button type="button" className="btn btn-primary" onClick={() => navigate('/conversations/new')}>
              <Plus size={16} /> Nouvelle conversation
            </button>
          )}
        </div>

        {/* ── Stats ──────────────────────────────────────────────────── */}
        <div className="cex-stats">
          <StatCard icon={Users}        value={stats.total}  label="Total"          color="#6366F1" />
          <StatCard icon={MessageSquare} value={stats.unread} label="Non lus"        color="#F59E0B" />
          <StatCard icon={CheckCheck}   value={stats.active} label="Actives"        color="#10B981" />
        </div>

        {/* ── Toolbar ────────────────────────────────────────────────── */}
        <div className="cex-toolbar">
          <div className="cex-search-wrap">
            <Search size={15} className="cex-search-icon" />
            <input
              className="cex-search"
              placeholder={isExpert ? 'Rechercher un patient…' : 'Rechercher…'}
              value={search}
              onChange={e => setSearch(e.target.value)}
            />
            {search && (
              <button type="button" className="cex-search-clear" onClick={() => setSearch('')}>
                <X size={13} />
              </button>
            )}
          </div>

          <div className="cex-filters">
            {FILTERS.map(f => (
              <button
                key={f}
                type="button"
                className={`cex-filter-btn ${activeFilter === f ? 'cex-filter-btn--active' : ''}`}
                onClick={() => setActiveFilter(f)}
              >
                {f}
                {f === 'Non lus' && stats.unread > 0 && (
                  <span className="cex-filter-badge">{stats.unread}</span>
                )}
              </button>
            ))}
          </div>

          <div className="cex-sort-wrap" ref={sortRef}>
            <button type="button" className="cex-sort-btn" onClick={() => setShowSort(v => !v)}>
              <SortAsc size={14} /> {currentSortLabel} <ChevronDown size={12} />
            </button>
            <AnimatePresence>
              {showSort && (
                <motion.div
                  className="cex-sort-panel"
                  initial={{ opacity: 0, scale: 0.94, y: -6 }}
                  animate={{ opacity: 1, scale: 1, y: 0 }}
                  exit={{ opacity: 0, scale: 0.94, y: -6 }}
                  transition={{ duration: 0.14 }}
                >
                  {SORTS.map(s => (
                    <button
                      key={s.key}
                      type="button"
                      className={`cex-sort-item ${sortKey === s.key ? 'cex-sort-item--active' : ''}`}
                      onClick={() => { setSortKey(s.key); setShowSort(false); }}
                    >
                      {sortKey === s.key && <Check size={12} />}
                      {s.label}
                    </button>
                  ))}
                </motion.div>
              )}
            </AnimatePresence>
          </div>
        </div>

        {/* ── Count ──────────────────────────────────────────────────── */}
        {!isLoading && (
          <p className="cex-count">
            {filtered.length} conversation{filtered.length !== 1 ? 's' : ''}
            {search && ` pour "${search}"`}
          </p>
        )}

        {/* ── List ───────────────────────────────────────────────────── */}
        {isLoading ? (
          <div className="cex-loading">
            {[...Array(4)].map((_, i) => <div key={i} className="cex-skeleton" />)}
          </div>
        ) : filtered.length === 0 ? (
          <motion.div className="cex-empty" initial={{ opacity: 0 }} animate={{ opacity: 1 }}>
            <div className="cex-empty-icon">
              {search ? <Search size={28} /> : <MessageSquare size={28} />}
            </div>
            <p className="cex-empty-title">
              {search ? 'Aucun résultat' : activeFilter === 'Non lus' ? 'Aucun message non lu' : activeFilter === 'Fermés' ? 'Aucune consultation fermée' : 'Aucune conversation'}
            </p>
            <p className="cex-empty-sub">
              {search ? `Aucun résultat pour "${search}"` : isExpert ? 'Les consultations de vos patients apparaîtront ici.' : 'Commencez une nouvelle conversation avec l\'IA ou un expert.'}
            </p>
            {search && <button type="button" className="btn btn-secondary btn-sm" onClick={() => setSearch('')}>Effacer la recherche</button>}
            {!isExpert && !search && (
              <button type="button" className="btn btn-primary" onClick={() => navigate('/conversations/new')}>
                <Plus size={15} /> Nouvelle conversation
              </button>
            )}
          </motion.div>
        ) : (
          <div className="cex-list">
            <AnimatePresence initial={false}>
              {filtered.map((conv, i) => {
                const otherName  = getOtherName(conv, isExpert);
                const isAiConv   = conv.status === 'ai' || !conv.expert;
                const otherUser  = isExpert ? conv.user : conv.expert?.user;
                const isOnline   = onlineOverrides[conv.id] !== undefined
                  ? onlineOverrides[conv.id]
                  : (otherUser?.is_online ?? false);
                const unread     = conv.unread_count ?? 0;
                const preview    = lastMsgPreview(conv, user?.id, isExpert);
                const time       = convTime(conv.last_message?.created_at ?? conv.updated_at);
                const color      = isAiConv ? '#6366F1' : avatarColor(otherName);
                const status     = STATUS_CONFIG[conv.status] ?? STATUS_CONFIG.open;
                const isClosed   = conv.status === 'closed';

                return (
                  <motion.div
                    key={conv.id}
                    layout
                    initial={{ opacity: 0, y: 8 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, x: -20 }}
                    transition={{ duration: 0.22, delay: Math.min(i * 0.025, 0.2) }}
                  >
                    <div className={`cex-item ${unread > 0 ? 'cex-item--unread' : ''} ${isClosed ? 'cex-item--closed' : ''}`}>
                      <Link to={`/conversations/${conv.id}`} className="cex-link">

                        {/* Avatar */}
                        <div className="cex-avatar-wrap">
                          {isAiConv ? (
                            <div className="cex-avatar cex-avatar--ai">
                              <img src="/nexora1.png" alt="IA Nexora" className="cex-avatar-logo" />
                            </div>
                          ) : (
                            <div className="cex-avatar" style={{ background: `${color}22`, borderColor: `${color}44` }}>
                              {otherUser?.avatar_url
                                ? <img src={otherUser.avatar_url} alt={otherName} className="cex-avatar-photo"
                                    onError={(e) => { e.currentTarget.style.display = 'none'; e.currentTarget.nextElementSibling.style.display = 'flex'; }}
                                  />
                                : null
                              }
                              <span style={{ color, display: otherUser?.avatar_url ? 'none' : 'flex' }}>{initials(otherName)}</span>
                            </div>
                          )}
                          {isOnline && <span className="cex-online-dot" />}
                        </div>

                        {/* Content */}
                        <div className="cex-content">
                          <div className="cex-row-top">
                            <div className="cex-name-wrap">
                              <span className="cex-name">{otherName}</span>
                              <span className="cex-status-badge" style={{ color: status.color, background: status.bg }}>
                                {status.label}
                              </span>
                            </div>
                            <span className={`cex-time ${unread > 0 ? 'cex-time--unread' : ''}`}>{time}</span>
                          </div>
                          {isExpert && conv.category?.name && (
                            <p className="cex-specialty">{conv.category.name}</p>
                          )}
                          <div className="cex-row-bottom">
                            {conv.last_message?.type === 'audio' ? (
                              <span className="cex-audio-preview">
                                <span className="cex-audio-sender">{
                                  (() => {
                                    const msg = conv.last_message;
                                    const isOwn = isExpert
                                      ? msg.sender_type === 'expert' && msg.sender_id === user?.id
                                      : msg.sender_type === 'user' && msg.sender_id === user?.id;
                                    return isOwn ? 'Vous :' : msg.sender_type === 'ai' ? 'IA :' : msg.sender_type === 'expert' ? 'Dr :' : 'Patient :';
                                  })()
                                }</span>
                                <Mic size={11} />
                                Message vocal
                              </span>
                            ) : (
                            <p className={`cex-preview ${unread > 0 ? 'cex-preview--unread' : ''}`}>{preview}</p>
                            )}
                            {unread > 0 && (
                              <span className="cex-badge">{unread > 99 ? '99+' : unread}</span>
                            )}
                          </div>
                        </div>
                      </Link>

                      <ConvActions
                        conv={conv}
                        isExpert={isExpert}
                        disabled={actionsBusy}
                        onRename={(c) => { setRenaming(c); setNewTitle(c.title ?? `Conversation #${c.id}`); }}
                        onDelete={setConfirmDelete}
                        onClose={setConfirmClose}
                      />
                    </div>
                  </motion.div>
                );
              })}
            </AnimatePresence>
          </div>
        )}

        {/* ── Pagination ─────────────────────────────────────────────── */}
        {meta.last_page > 1 && (
          <div className="cex-pagination">
            <button type="button" className="btn btn-secondary btn-sm" disabled={page === 1 || isFetching} onClick={() => setPage(p => p - 1)}>
              Précédent
            </button>
            <span className="cex-page-info">Page {meta.current_page ?? page} / {meta.last_page}</span>
            <button type="button" className="btn btn-secondary btn-sm" disabled={page === meta.last_page || isFetching} onClick={() => setPage(p => p + 1)}>
              Suivant
            </button>
          </div>
        )}
      </motion.div>

      {/* ── Rename Modal ────────────────────────────────────────────── */}
      <AnimatePresence>
        {renaming && (
          <motion.div className="cex-overlay" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
            onClick={() => setRenaming(null)}>
            <motion.form className="cex-modal" initial={{ opacity: 0, scale: 0.95, y: 16 }} animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 16 }} transition={{ duration: 0.2 }}
              onClick={e => e.stopPropagation()} onSubmit={submitRename}>
              <div className="cex-modal-header">
                <div className="cex-modal-icon" style={{ background: 'rgba(99,102,241,0.15)', color: '#818CF8' }}><Pencil size={18} /></div>
                <div>
                  <h3>Renommer</h3>
                  <p>Donnez un nom à cette conversation</p>
                </div>
                <button type="button" className="cex-modal-close" onClick={() => setRenaming(null)}><X size={16} /></button>
              </div>
              <input type="text" className="cex-modal-input" value={newTitle} maxLength={255} autoFocus
                onChange={e => setNewTitle(e.target.value)} placeholder="Nom de la conversation…" />
              <div className="cex-modal-actions">
                <button type="button" className="btn btn-secondary" onClick={() => setRenaming(null)}>Annuler</button>
                <button type="submit" className="btn btn-primary" disabled={updateConv.isPending || !newTitle.trim()}>
                  {updateConv.isPending ? <Loader2 size={14} className="spin" /> : <Check size={14} />} Enregistrer
                </button>
              </div>
            </motion.form>
          </motion.div>
        )}
      </AnimatePresence>

      {/* ── Close Modal ─────────────────────────────────────────────── */}
      <AnimatePresence>
        {confirmClose && (
          <motion.div className="cex-overlay" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
            onClick={() => setConfirmClose(null)}>
            <motion.div className="cex-modal" initial={{ opacity: 0, scale: 0.95, y: 16 }} animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 16 }} transition={{ duration: 0.2 }}
              onClick={e => e.stopPropagation()}>
              <div className="cex-modal-header">
                <div className="cex-modal-icon" style={{ background: 'rgba(245,158,11,0.15)', color: '#F59E0B' }}><Archive size={18} /></div>
                <div>
                  <h3>Clôturer la consultation</h3>
                  <p>Cette action est irréversible</p>
                </div>
                <button type="button" className="cex-modal-close" onClick={() => setConfirmClose(null)}><X size={16} /></button>
              </div>
              <p className="cex-modal-text">
                La consultation avec <strong>{getOtherName(confirmClose, isExpert)}</strong> sera marquée comme terminée.
                Le patient ne pourra plus envoyer de messages.
              </p>
              <div className="cex-modal-actions">
                <button type="button" className="btn btn-secondary" onClick={() => setConfirmClose(null)}>Annuler</button>
                <button type="button" className="btn btn-warning" disabled={closeConv.isPending} onClick={submitClose}>
                  {closeConv.isPending ? <Loader2 size={14} className="spin" /> : <Archive size={14} />} Clôturer
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* ── Delete Modal ─────────────────────────────────────────────── */}
      <AnimatePresence>
        {confirmDelete && (
          <motion.div className="cex-overlay" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
            onClick={() => setConfirmDelete(null)}>
            <motion.div className="cex-modal" initial={{ opacity: 0, scale: 0.95, y: 16 }} animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 16 }} transition={{ duration: 0.2 }}
              onClick={e => e.stopPropagation()}>
              <div className="cex-modal-header">
                <div className="cex-modal-icon" style={{ background: 'rgba(220,38,38,0.15)', color: '#F87171' }}><Trash2 size={18} /></div>
                <div>
                  <h3>Supprimer la conversation</h3>
                  <p>Cette action est irréversible</p>
                </div>
                <button type="button" className="cex-modal-close" onClick={() => setConfirmDelete(null)}><X size={16} /></button>
              </div>
              <p className="cex-modal-text">
                La conversation avec <strong>{getOtherName(confirmDelete, isExpert)}</strong> sera définitivement supprimée avec tous ses messages.
              </p>
              <div className="cex-modal-actions">
                <button type="button" className="btn btn-secondary" onClick={() => setConfirmDelete(null)}>Annuler</button>
                <button type="button" className="btn btn-danger" disabled={deleteConv.isPending} onClick={submitDelete}>
                  {deleteConv.isPending ? <Loader2 size={14} className="spin" /> : <Trash2 size={14} />} Supprimer
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
