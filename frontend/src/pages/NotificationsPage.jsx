import { Bell, Check, CheckCheck, Loader2 } from 'lucide-react';
import { useNotifications, useMarkAsRead, useMarkAllAsRead } from '../hooks/useNotifications';
import './NotificationsPage.css';

function timeAgo(iso) {
  if (!iso) return '';
  const diff = (Date.now() - new Date(iso).getTime()) / 1000;
  if (diff < 60) return 'à l\'instant';
  if (diff < 3600) return `il y a ${Math.floor(diff / 60)} min`;
  if (diff < 86400) return `il y a ${Math.floor(diff / 3600)} h`;
  if (diff < 604800) return `il y a ${Math.floor(diff / 86400)} j`;
  return new Date(iso).toLocaleDateString('fr-FR', {
    day: 'numeric', month: 'short', year: 'numeric',
  });
}

export default function NotificationsPage() {
  const { data, isLoading } = useNotifications({ per_page: 50 });
  const { mutate: markOne } = useMarkAsRead();
  const { mutate: markAll, isPending: markingAll } = useMarkAllAsRead();

  const items = data?.data ?? [];
  const unreadCount = items.filter((n) => !n.read_at).length;

  return (
    <div className="notif-page">
      <div className="notif-page-header">
        <div>
          <h1 className="notif-page-title">Notifications</h1>
          <p className="notif-page-sub">
            {unreadCount > 0
              ? `${unreadCount} non lue${unreadCount > 1 ? 's' : ''}`
              : 'Tout est à jour.'}
          </p>
        </div>
        {unreadCount > 0 && (
          <button
            className="notif-page-mark-all"
            onClick={() => markAll()}
            disabled={markingAll}
          >
            <CheckCheck size={16} />
            Tout marquer comme lu
          </button>
        )}
      </div>

      {isLoading ? (
        <div className="notif-page-loading">
          <Loader2 size={28} className="spin" style={{ color: 'var(--primary-500)' }} />
        </div>
      ) : items.length === 0 ? (
        <div className="notif-page-empty">
          <Bell size={48} style={{ opacity: 0.25, marginBottom: 16 }} />
          <h3>Aucune notification</h3>
          <p>Vous serez prévenu ici de toute nouvelle activité sur votre compte.</p>
        </div>
      ) : (
        <ul className="notif-page-list">
          {items.map((n) => (
            <li
              key={n.id}
              className={`notif-card ${!n.read_at ? 'notif-card--unread' : ''}`}
            >
              <div className={`notif-card-icon ${!n.read_at ? 'notif-card-icon--unread' : ''}`}>
                <Bell size={18} />
              </div>
              <div className="notif-card-body">
                <div className="notif-card-title">{n.title}</div>
                {n.body && <div className="notif-card-text">{n.body}</div>}
                <div className="notif-card-time">{timeAgo(n.created_at)}</div>
              </div>
              {!n.read_at && (
                <button
                  className="notif-card-action"
                  onClick={() => markOne(n.id)}
                  title="Marquer comme lu"
                >
                  <Check size={16} />
                </button>
              )}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
