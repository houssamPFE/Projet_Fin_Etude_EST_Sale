import { useState, useEffect, useRef } from 'react';
import { Link } from 'react-router-dom';
import { Bell, Check, Loader2 } from 'lucide-react';
import { useNotifications, useMarkAsRead, useMarkAllAsRead } from '../hooks/useNotifications';
import './NotificationDropdown.css';

function timeAgo(iso) {
  if (!iso) return '';
  const diff = (Date.now() - new Date(iso).getTime()) / 1000;
  if (diff < 60) return 'à l\'instant';
  if (diff < 3600) return `il y a ${Math.floor(diff / 60)} min`;
  if (diff < 86400) return `il y a ${Math.floor(diff / 3600)} h`;
  if (diff < 604800) return `il y a ${Math.floor(diff / 86400)} j`;
  return new Date(iso).toLocaleDateString('fr-FR');
}

export default function NotificationDropdown() {
  const [open, setOpen] = useState(false);
  const ref = useRef(null);

  const { data, isLoading } = useNotifications({ per_page: 8 });
  const { mutate: markOne } = useMarkAsRead();
  const { mutate: markAll, isPending: markingAll } = useMarkAllAsRead();

  const items = data?.data ?? [];
  const unreadCount = items.filter((n) => !n.read_at).length;

  useEffect(() => {
    if (!open) return;
    const handler = (e) => {
      if (ref.current && !ref.current.contains(e.target)) setOpen(false);
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, [open]);

  const handleItemClick = (notification) => {
    if (!notification.read_at) markOne(notification.id);
  };

  return (
    <div className="notif-dropdown" ref={ref}>
      <button
        className="app-header-notif"
        onClick={() => setOpen((v) => !v)}
        aria-label="Notifications"
      >
        <Bell size={20} />
        {unreadCount > 0 && (
          <span className="notif-badge">{unreadCount > 9 ? '9+' : unreadCount}</span>
        )}
      </button>

      {open && (
        <div className="notif-panel">
          <div className="notif-panel-header">
            <span className="notif-panel-title">Notifications</span>
            {unreadCount > 0 && (
              <button
                className="notif-mark-all"
                onClick={() => markAll()}
                disabled={markingAll}
              >
                <Check size={12} /> Tout marquer comme lu
              </button>
            )}
          </div>

          <div className="notif-panel-list">
            {isLoading ? (
              <div className="notif-empty">
                <Loader2 size={20} className="spin" />
              </div>
            ) : items.length === 0 ? (
              <div className="notif-empty">
                <Bell size={28} style={{ opacity: 0.3, marginBottom: 8 }} />
                <p>Aucune notification</p>
              </div>
            ) : (
              items.map((n) => (
                <button
                  key={n.id}
                  className={`notif-item ${!n.read_at ? 'notif-item--unread' : ''}`}
                  onClick={() => handleItemClick(n)}
                >
                  {!n.read_at && <span className="notif-dot" />}
                  <div className="notif-item-body">
                    <div className="notif-item-title">{n.title}</div>
                    {n.body && <div className="notif-item-text">{n.body}</div>}
                    <div className="notif-item-time">{timeAgo(n.created_at)}</div>
                  </div>
                </button>
              ))
            )}
          </div>

          <div className="notif-panel-footer">
            <Link to="/notifications" onClick={() => setOpen(false)}>
              Voir toutes les notifications
            </Link>
          </div>
        </div>
      )}
    </div>
  );
}
