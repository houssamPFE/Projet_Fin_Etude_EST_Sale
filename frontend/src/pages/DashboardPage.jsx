import { motion } from 'framer-motion';
import { MessageSquare, Users, Zap, ShieldCheck, Mic, ChevronRight, Loader2, Bell } from 'lucide-react';
import { Link, useNavigate, Navigate } from 'react-router-dom';
import useAuthStore from '../stores/authStore';
import { useConversations } from '../hooks/useConversations';
import { useNotifications } from '../hooks/useNotifications';
import './DashboardPage.css';

const features = [
  { icon: Zap,         title: 'IA intelligente',   desc: 'Réponses instantanées grâce à l\'intelligence artificielle avancée', bg: 'rgba(139,92,246,0.1)',  color: '#a78bfa' },
  { icon: Users,       title: 'Experts qualifiés', desc: 'Réseau d\'experts vérifiés dans chaque domaine',                    bg: 'rgba(20,184,166,0.1)',  color: '#2dd4bf' },
  { icon: ShieldCheck, title: 'Sécurité',          desc: 'Données chiffrées et confidentialité garantie',                    bg: 'rgba(59,130,246,0.1)',  color: '#60a5fa' },
  { icon: Mic,         title: 'Audio & Texte',     desc: 'Communiquez par message texte ou vocal',                           bg: 'rgba(245,158,11,0.1)', color: '#fbbf24' },
];

function StatusBadge({ status }) {
  const map = {
    ai:     { label: 'IA',      bg: '#FFF7ED', color: '#C4752A' },
    expert: { label: 'Expert',  bg: '#F0FDF4', color: '#16A34A' },
    open:   { label: 'Ouvert',  bg: '#EFF6FF', color: '#2563EB' },
    closed: { label: 'Fermé',   bg: '#F5F5F4', color: '#78716C' },
  };
  const s = map[status] ?? map.open;
  return (
    <span style={{ padding: '2px 10px', borderRadius: 20, fontSize: 12, fontWeight: 600, color: s.color, background: s.bg }}>
      {s.label}
    </span>
  );
}

export default function DashboardPage() {
  const user = useAuthStore((s) => s.user);
  const navigate = useNavigate();

  // Experts and admins have their own dashboards — send them there immediately.
  if (user?.role === 'expert') return <Navigate to="/expert/dashboard" replace />;
  if (user?.role === 'admin')  return <Navigate to="/admin/dashboard"  replace />;
  const { data: convsData, isLoading: convsLoading } = useConversations();
  const { data: notifsData, isLoading: notifsLoading } = useNotifications({ per_page: 5 });

  const conversations = convsData?.data ?? [];
  const notifications = notifsData?.data ?? [];
  const unreadCount   = notifsData?.meta?.unread_count ?? 0;

  return (
    <div className="dashboard">

      {/* ── Hero ── */}
      <motion.div className="dashboard-hero" initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.5 }}>
        <div className="dashboard-hero-badge">
          <Zap size={14} />
          Plateforme d'expertise intelligente
        </div>
        <h1 className="dashboard-hero-title">
          Bonjour, <span className="dashboard-hero-accent">{user?.name?.split(' ')[0]}</span>
        </h1>
        <p className="dashboard-hero-subtitle">
          Posez vos questions et obtenez des réponses fiables grâce à l'intelligence artificielle et à un réseau d'experts qualifiés.
        </p>
        <div className="dashboard-hero-actions">
          <button className="btn btn-primary btn-lg" onClick={() => navigate('/conversations/new')}>
            <MessageSquare size={18} />
            Démarrer une conversation
          </button>
          <Link to="/experts" className="btn btn-secondary btn-lg">
            Voir les experts <ChevronRight size={18} />
          </Link>
        </div>
      </motion.div>

      {/* ── Features ── */}
      <motion.div className="dashboard-features" initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.5, delay: 0.1 }}>
        <h2 className="dashboard-section-title">Pourquoi Nexora ?</h2>
        <div className="dashboard-features-grid">
          {features.map(({ icon: Icon, title, desc, bg, color }) => (
            <div key={title} className="feature-card">
              <div className="feature-card-icon" style={{ background: bg, color }}>
                <Icon size={22} />
              </div>
              <h3 className="feature-card-title">{title}</h3>
              <p className="feature-card-desc">{desc}</p>
            </div>
          ))}
        </div>
      </motion.div>

      {/* ── Recent activity ── */}
      <motion.div className="dashboard-grid" initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.5, delay: 0.2 }}>

        {/* Conversations */}
        <div className="card">
          <div className="card-header">
            <h3>Conversations récentes</h3>
            <Link to="/conversations" className="card-link">
              Voir tout <ChevronRight size={14} />
            </Link>
          </div>
          {convsLoading ? (
            <div className="card-loading"><Loader2 size={24} className="spin" style={{ color: 'var(--primary-500)' }} /></div>
          ) : conversations.length === 0 ? (
            <p className="card-empty">Aucune conversation pour le moment.<br />Commencez pour obtenir de l'aide.</p>
          ) : (
            <ul className="card-list">
              {conversations.map((conv) => (
                <li key={conv.id}>
                  <Link to={`/conversations/${conv.id}`} className="card-list-item">
                    <div style={{ flex: 1 }}>
                      <p style={{ margin: 0, fontWeight: 500, fontSize: 14, color: 'var(--text-primary)' }}>{conv.title ?? `Conversation #${conv.id}`}</p>
                      <p style={{ margin: 0, fontSize: 12, color: 'var(--text-muted)' }}>{conv.category?.name}</p>
                    </div>
                    <StatusBadge status={conv.status} />
                  </Link>
                </li>
              ))}
            </ul>
          )}
        </div>

        {/* Notifications */}
        <div className="card">
          <div className="card-header">
            <h3>
              Notifications
              {unreadCount > 0 && <span className="notif-count">{unreadCount}</span>}
            </h3>
            <Link to="/notifications" className="card-link">
              Voir tout <ChevronRight size={14} />
            </Link>
          </div>
          {notifsLoading ? (
            <div className="card-loading"><Loader2 size={24} className="spin" style={{ color: 'var(--primary-500)' }} /></div>
          ) : notifications.length === 0 ? (
            <p className="card-empty">Aucune notification.</p>
          ) : (
            <ul className="card-list">
              {notifications.map((notif) => (
                <li key={notif.id} className={`notif-item ${!notif.read_at ? 'notif-item--unread' : ''}`}>
                  <p style={{ margin: 0, fontWeight: 500, fontSize: 14 }}>{notif.title}</p>
                  <p style={{ margin: 0, fontSize: 12, color: 'var(--text-muted)' }}>{notif.body}</p>
                </li>
              ))}
            </ul>
          )}
        </div>
      </motion.div>

      {/* ── CTA Banner ── */}
      <motion.div className="dashboard-cta-banner" initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.5, delay: 0.3 }}>
        <h2>Prêt à obtenir des réponses ?</h2>
        <p>Rejoignez Nexora et accédez à l'expertise dont vous avez besoin, quand vous en avez besoin.</p>
        <button className="btn btn-lg" style={{ background: '#fff', color: 'var(--primary-600)', fontWeight: 700 }} onClick={() => navigate('/conversations/new')}>
          <MessageSquare size={18} />
          Commencer maintenant
        </button>
      </motion.div>

    </div>
  );
}
