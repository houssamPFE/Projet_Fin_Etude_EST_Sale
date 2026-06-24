import { useState, useMemo } from 'react';
import {
  Bell, Check, CheckCheck, Loader2,
  MessageSquare, ShieldCheck, CreditCard,
  UserCheck, AlertTriangle, Info, Stethoscope,
  BellOff, Sparkles,
} from 'lucide-react';
import { useNotifications, useMarkAsRead, useMarkAllAsRead } from '../hooks/useNotifications';
import './NotificationsPage.css';

function timeAgo(iso) {
  if (!iso) return '';
  const diff = (Date.now() - new Date(iso).getTime()) / 1000;
  if (diff < 60)     return 'À l\'instant';
  if (diff < 3600)   return `Il y a ${Math.floor(diff / 60)} min`;
  if (diff < 86400)  return `Il y a ${Math.floor(diff / 3600)} h`;
  if (diff < 604800) return `Il y a ${Math.floor(diff / 86400)} j`;
  return new Date(iso).toLocaleDateString('fr-FR', { day: 'numeric', month: 'short', year: 'numeric' });
}

function groupByDate(items) {
  const today     = new Date(); today.setHours(0,0,0,0);
  const yesterday = new Date(today); yesterday.setDate(today.getDate() - 1);
  const weekAgo   = new Date(today); weekAgo.setDate(today.getDate() - 7);

  const groups = { "Aujourd'hui": [], 'Hier': [], 'Cette semaine': [], 'Plus ancien': [] };
  items.forEach((n) => {
    const d = new Date(n.created_at); d.setHours(0,0,0,0);
    if (d >= today)          groups["Aujourd'hui"].push(n);
    else if (d >= yesterday) groups['Hier'].push(n);
    else if (d >= weekAgo)   groups['Cette semaine'].push(n);
    else                     groups['Plus ancien'].push(n);
  });
  return Object.entries(groups).filter(([, v]) => v.length > 0);
}

const TYPE_META = {
  'conversation.assigned': { icon: MessageSquare, color: '#60A5FA', bg: 'rgba(37,99,235,0.12)',  border: 'rgba(37,99,235,0.22)'  },
  'conversation.message':  { icon: MessageSquare, color: '#60A5FA', bg: 'rgba(37,99,235,0.12)',  border: 'rgba(37,99,235,0.22)'  },
  'expert.validated':      { icon: ShieldCheck,   color: '#86EFAC', bg: 'rgba(34,197,94,0.12)',  border: 'rgba(34,197,94,0.22)'  },
  'expert.rejected':       { icon: AlertTriangle, color: '#FCA5A5', bg: 'rgba(239,68,68,0.12)',  border: 'rgba(239,68,68,0.22)'  },
  'payment.received':      { icon: CreditCard,    color: '#FCD34D', bg: 'rgba(245,158,11,0.12)', border: 'rgba(245,158,11,0.22)' },
  'user.approved':         { icon: UserCheck,     color: '#86EFAC', bg: 'rgba(34,197,94,0.12)',  border: 'rgba(34,197,94,0.22)'  },
  'consultation.new':      { icon: Stethoscope,   color: '#C4B5FD', bg: 'rgba(124,58,237,0.12)', border: 'rgba(124,58,237,0.22)' },
};

function getTypeMeta(type) {
  if (!type) return { icon: Bell, color: '#94A3B8', bg: 'rgba(148,163,184,0.08)', border: 'rgba(148,163,184,0.15)' };
  const key = Object.keys(TYPE_META).find(k => type.includes(k.split('.')[0]) && type.includes(k.split('.')[1] ?? ''));
  return TYPE_META[key] ?? { icon: Info, color: '#93C5FD', bg: 'rgba(37,99,235,0.1)', border: 'rgba(37,99,235,0.2)' };
}

export default function NotificationsPage() {
  const { data, isLoading }              = useNotifications({ per_page: 50 });
  const { mutate: markOne }              = useMarkAsRead();
  const { mutate: markAll, isPending: markingAll } = useMarkAllAsRead();
  const [filter, setFilter]              = useState('all');

  const items       = data?.data ?? [];
  const unreadCount = items.filter(n => !n.read_at).length;
  const filtered    = filter === 'unread' ? items.filter(n => !n.read_at) : items;
  const groups      = useMemo(() => groupByDate(filtered), [filtered]);

  return (
    <div className="notif-page">

      {/* ── Header ── */}
      <div className="notif-header">
        <div className="notif-header-bg" />
        <div className="notif-header-content">
          <div className="notif-header-left">
            <div className="notif-header-eyebrow">
              <span className="notif-eyebrow-dot" />
              Centre de notifications
            </div>
            <h1 className="notif-header-title">Notifications</h1>
            <p className="notif-header-sub">
              {unreadCount > 0
                ? <><span className="notif-unread-pill">{unreadCount}</span> non lue{unreadCount > 1 ? 's' : ''}</>
                : 'Tout est à jour — aucune notification en attente'}
            </p>
          </div>
          <div className="notif-header-right">
            <div className="notif-stat">
              <span className="notif-stat-value">{items.length}</span>
              <span className="notif-stat-label">Total</span>
            </div>
            <div className="notif-stat">
              <span className="notif-stat-value" style={{ color: unreadCount > 0 ? '#93C5FD' : '#475569' }}>{unreadCount}</span>
              <span className="notif-stat-label">Non lues</span>
            </div>
          </div>
        </div>
      </div>

      <div className="notif-divider" />

      <div className="notif-body">

        {/* ── Toolbar ── */}
        <div className="notif-toolbar">
          <div className="notif-filters">
            <button className={`notif-filter-btn ${filter === 'all' ? 'active' : ''}`} onClick={() => setFilter('all')}>
              Tout <span className="notif-filter-count">{items.length}</span>
            </button>
            <button className={`notif-filter-btn ${filter === 'unread' ? 'active' : ''}`} onClick={() => setFilter('unread')}>
              Non lues {unreadCount > 0 && <span className="notif-filter-count notif-filter-count--unread">{unreadCount}</span>}
            </button>
          </div>
          {unreadCount > 0 && (
            <button className="notif-mark-all" onClick={() => markAll()} disabled={markingAll}>
              {markingAll ? <Loader2 size={14} className="spin" /> : <CheckCheck size={14} />}
              Tout marquer comme lu
            </button>
          )}
        </div>

        {/* ── Content ── */}
        {isLoading ? (
          <div className="notif-loading">
            <Loader2 size={32} className="spin notif-loading-icon" />
            <p>Chargement des notifications…</p>
          </div>
        ) : filtered.length === 0 ? (
          <div className="notif-empty">
            <div className="notif-empty-icon">
              {filter === 'unread' ? <BellOff size={36} /> : <Sparkles size={36} />}
            </div>
            <h3>{filter === 'unread' ? 'Aucune notification non lue' : 'Aucune notification'}</h3>
            <p>{filter === 'unread'
              ? 'Vous êtes à jour. Revenez plus tard.'
              : 'Vous serez notifié ici de toute activité sur votre compte.'}
            </p>
          </div>
        ) : (
          <div className="notif-groups">
            {groups.map(([label, groupItems]) => (
              <div key={label} className="notif-group">
                <div className="notif-group-label"><span>{label}</span></div>
                <ul className="notif-list">
                  {groupItems.map((n) => {
                    const meta = getTypeMeta(n.type);
                    const Icon = meta.icon;
                    return (
                      <li
                        key={n.id}
                        className={`notif-card ${!n.read_at ? 'notif-card--unread' : ''}`}
                        onClick={() => !n.read_at && markOne(n.id)}
                        style={{ cursor: !n.read_at ? 'pointer' : 'default' }}
                      >
                        {!n.read_at && <span className="notif-card-dot" />}
                        <div
                          className="notif-card-icon"
                          style={{ background: meta.bg, border: `1px solid ${meta.border}`, color: meta.color }}
                        >
                          <Icon size={17} />
                        </div>
                        <div className="notif-card-body">
                          <div className="notif-card-title">{n.title}</div>
                          {n.body && <div className="notif-card-text">{n.body}</div>}
                          <div className="notif-card-time">{timeAgo(n.created_at)}</div>
                        </div>
                        {!n.read_at && (
                          <button
                            className="notif-card-check"
                            onClick={(e) => { e.stopPropagation(); markOne(n.id); }}
                            title="Marquer comme lu"
                          >
                            <Check size={13} />
                          </button>
                        )}
                      </li>
                    );
                  })}
                </ul>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
