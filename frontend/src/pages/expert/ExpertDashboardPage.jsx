import { useMemo } from 'react';
import { motion } from 'framer-motion';
import {
  Star, MessageSquare, Wallet, Loader2, TrendingUp,
  ArrowRight, Clock, CheckCircle2, XCircle, Pencil,
  BadgeCheck, MapPin,
} from 'lucide-react';
import { Link } from 'react-router-dom';
import { useExpertDashboard, useToggleAvailability, useExpertProfile } from '../../hooks/useExpertPanel';
import { useConversations } from '../../hooks/useConversations';
import useAuthStore from '../../stores/authStore';
import toast from 'react-hot-toast';
import './ExpertDashboardPage.css';

const STATUS_META = {
  open:   { label: 'Ouverte',   color: '#60A5FA', bg: 'rgba(37,99,235,0.1)'   },
  ai:     { label: 'En attente', color: '#A78BFA', bg: 'rgba(124,58,237,0.1)' },
  expert: { label: 'En cours',  color: '#34D399', bg: 'rgba(16,185,129,0.1)'  },
  closed: { label: 'Fermée',    color: '#64748B', bg: 'rgba(100,116,139,0.1)' },
};

function timeAgo(iso) {
  if (!iso) return '';
  const diff = (Date.now() - new Date(iso).getTime()) / 1000;
  if (diff < 60)    return 'À l\'instant';
  if (diff < 3600)  return `${Math.floor(diff / 60)} min`;
  if (diff < 86400) return `${Math.floor(diff / 3600)} h`;
  return `${Math.floor(diff / 86400)} j`;
}

function StarRating({ value }) {
  const stars = Math.round(value ?? 0);
  return (
    <span className="edash-stars">
      {[1,2,3,4,5].map(i => (
        <Star key={i} size={13} className={i <= stars ? 'edash-star--on' : 'edash-star--off'} />
      ))}
    </span>
  );
}

export default function ExpertDashboardPage() {
  const user        = useAuthStore((s) => s.user);
  const { data: stats,   isLoading }           = useExpertDashboard();
  const { data: profile, isLoading: profLoad } = useExpertProfile();
  const { data: convsData }                    = useConversations({ per_page: 5 });
  const { mutateAsync: toggleAvailability, isPending: toggling } = useToggleAvailability();

  const handleToggle = async () => {
    try {
      await toggleAvailability(!stats?.is_available);
      toast.success(stats?.is_available ? 'Vous êtes maintenant occupé.' : 'Vous êtes maintenant disponible.');
    } catch {
      toast.error('Impossible de mettre à jour la disponibilité.');
    }
  };

  const conversations = convsData?.data ?? [];
  const firstName     = user?.name?.split(' ')[0] ?? 'Docteur';

  const statItems = useMemo(() => [
    { label: 'Consultations totales',  value: stats?.total_conversations ?? '—',  icon: MessageSquare },
    { label: 'Consultations actives',  value: stats?.active_conversations ?? '—', icon: TrendingUp    },
    { label: 'Note moyenne',           value: stats?.rating_avg ? `${Number(stats.rating_avg).toFixed(1)} ★` : '—', icon: Star },
    { label: 'Solde disponible',       value: stats?.wallet_balance ? `${Number(stats.wallet_balance).toFixed(0)} MAD` : '0 MAD', icon: Wallet },
  ], [stats]);

  return (
    <div className="edash-page">

      {/* ── Header ── */}
      <div className="edash-header">
        <div className="edash-header-content">
          <div>
            <p className="edash-eyebrow">Tableau de bord</p>
            <h1 className="edash-title">Bonjour, Dr. {firstName}</h1>
            <p className="edash-subtitle">
              {isLoading
                ? 'Chargement…'
                : `${stats?.active_conversations ?? 0} consultation${(stats?.active_conversations ?? 0) !== 1 ? 's' : ''} active${(stats?.active_conversations ?? 0) !== 1 ? 's' : ''} en cours`
              }
            </p>
          </div>
          <button
            className={`edash-toggle ${stats?.is_available ? 'edash-toggle--on' : 'edash-toggle--off'}`}
            onClick={handleToggle}
            disabled={toggling || isLoading}
          >
            {toggling
              ? <Loader2 size={15} className="spin" />
              : stats?.is_available ? <CheckCircle2 size={15} /> : <XCircle size={15} />
            }
            {stats?.is_available ? 'Disponible' : 'Occupé'}
          </button>
        </div>
      </div>

      <div className="edash-divider" />

      <div className="edash-body">
        {isLoading ? (
          <div className="edash-loading"><Loader2 size={28} className="spin" /></div>
        ) : (
          <>
            {/* ── Stats ── */}
            <div className="edash-section-label"><span>Vue d'ensemble</span></div>
            <div className="edash-stats-grid">
              {statItems.map(({ label, value, icon: Icon }, i) => (
                <motion.div
                  key={label}
                  className="edash-stat"
                  initial={{ opacity: 0, y: 12 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.3, delay: i * 0.07 }}
                >
                  <div className="edash-stat-icon-wrap"><Icon size={17} /></div>
                  <span className="edash-stat-value">{value}</span>
                  <span className="edash-stat-label">{label}</span>
                </motion.div>
              ))}
            </div>

            {/* ── Main grid ── */}
            <div className="edash-section-label"><span>Activité</span></div>
            <div className="edash-grid">

              {/* ── Conversations ── */}
              <motion.div className="edash-card" initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.3, delay: 0.1 }}>
                <div className="edash-card-head">
                  <h3 className="edash-card-title">Conversations récentes</h3>
                  <Link to="/conversations" className="edash-link-sm">
                    Voir tout <ArrowRight size={12} />
                  </Link>
                </div>

                {conversations.length === 0 ? (
                  <p className="edash-empty">Aucune conversation assignée.</p>
                ) : (
                  <ul className="edash-conv-list">
                    {conversations.map((conv) => {
                      const sm = STATUS_META[conv.status] ?? STATUS_META.open;
                      return (
                        <li key={conv.id}>
                          <Link to={`/conversations/${conv.id}`} className="edash-conv-item">
                            <div className="edash-conv-avatar">
                              {conv.title?.charAt(0)?.toUpperCase() ?? '#'}
                            </div>
                            <div className="edash-conv-info">
                              <span className="edash-conv-title">{conv.title ?? `Consultation #${conv.id}`}</span>
                              <span className="edash-conv-meta">
                                {conv.category?.name && <span>{conv.category.name}</span>}
                                <span className="edash-conv-time"><Clock size={10} /> {timeAgo(conv.updated_at)}</span>
                              </span>
                            </div>
                            <span className="edash-status-pill" style={{ color: sm.color, background: sm.bg }}>
                              {sm.label}
                            </span>
                          </Link>
                        </li>
                      );
                    })}
                  </ul>
                )}
              </motion.div>

              {/* ── Expert profile card ── */}
              <motion.div className="edash-card" initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.3, delay: 0.15 }}>
                <div className="edash-card-head">
                  <h3 className="edash-card-title">Mon profil</h3>
                  <Link to="/expert/profile" className="edash-link-sm">
                    <Pencil size={12} /> Modifier
                  </Link>
                </div>

                {profLoad ? (
                  <div className="edash-loading" style={{ padding: '24px 0' }}><Loader2 size={20} className="spin" /></div>
                ) : (
                  <div className="edash-profile-card">

                    {/* Avatar + name */}
                    <div className="edash-profile-top">
                      <div className="edash-profile-avatar">
                        {user?.avatar_url
                          ? <img src={user.avatar_url} alt={user.name} />
                          : user?.name?.charAt(0)?.toUpperCase()
                        }
                      </div>
                      <div className="edash-profile-identity">
                        <span className="edash-profile-name">
                          Dr. {user?.name}
                          <BadgeCheck size={14} className="edash-profile-badge" />
                        </span>
                        <span className="edash-profile-specialty">
                          {profile?.category?.name ?? 'Spécialité non renseignée'}
                        </span>
                      </div>
                    </div>

                    {/* Rating */}
                    <div className="edash-profile-row">
                      <StarRating value={stats?.rating_avg} />
                      <span className="edash-profile-rating-val">
                        {stats?.rating_avg ? Number(stats.rating_avg).toFixed(1) : '0.0'}
                        <span className="edash-profile-rating-count">({stats?.total_reviews ?? 0} avis)</span>
                      </span>
                    </div>

                    {/* Bio */}
                    {profile?.bio && (
                      <p className="edash-profile-bio">{profile.bio}</p>
                    )}

                    {/* Meta */}
                    <div className="edash-profile-meta">
                      <span className="edash-profile-meta-item">
                        <MapPin size={12} /> Maroc
                      </span>
                    </div>

                    {/* Wallet shortcut */}
                    <Link to="/expert/wallet" className="edash-wallet-row">
                      <div className="edash-wallet-left">
                        <Wallet size={14} />
                        <span>Solde disponible</span>
                      </div>
                      <span className="edash-wallet-amount">
                        {stats?.wallet_balance ? `${Number(stats.wallet_balance).toFixed(2)} MAD` : '0.00 MAD'}
                      </span>
                    </Link>

                  </div>
                )}
              </motion.div>

            </div>
          </>
        )}
      </div>
    </div>
  );
}
