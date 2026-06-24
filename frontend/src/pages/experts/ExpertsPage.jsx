import { useState, useEffect, useRef } from 'react';
import { motion } from 'framer-motion';
import { Search, Star, Loader2, Users, Award, BadgeCheck } from 'lucide-react';
import { Link } from 'react-router-dom';
import { useExperts, useCategories } from '../../hooks/useExperts';
import { getEcho } from '../../lib/echo';
import './ExpertsPage.css';

function getInitials(name) {
  if (!name) return 'DR';
  const parts = name.trim().split(/\s+/);
  if (parts.length === 1) return parts[0][0].toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
}

function ExpertAvatar({ avatarUrl, name }) {
  const [failed, setFailed] = useState(false);
  const initials = getInitials(name);

  if (avatarUrl && !failed) {
    return (
      <img
        src={avatarUrl}
        alt={name}
        onError={() => setFailed(true)}
      />
    );
  }
  return <span>{initials}</span>;
}

function ExpertCard({ expert, index, isOnline }) {
  return (
    <motion.div
      className="ec-card"
      initial={{ opacity: 0, y: 16 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3, delay: index * 0.05 }}
    >
      {/* Availability badge */}
      <span className={`ec-avail ${expert.is_available ? 'ec-avail--on' : 'ec-avail--off'}`}>
        <span className="ec-avail-dot" />
        {expert.is_available ? 'Disponible' : 'Occupé'}
      </span>

      {/* Avatar */}
      <div className="ec-avatar-wrap">
        <div className="ec-avatar">
          <ExpertAvatar avatarUrl={expert.user?.avatar_url} name={expert.user?.name} />
        </div>
        {isOnline && <span className="ec-online-dot" />}
      </div>

      {/* Identity */}
      <div className="ec-identity">
        <h3 className="ec-name">
          Dr. {expert.user?.name}
          <BadgeCheck size={14} className="ec-verified" />
        </h3>
        <span className="ec-specialty">{expert.category?.name}</span>
      </div>

      {/* Rating */}
      <div className="ec-rating">
        <Star size={13} className="ec-star" />
        <span className="ec-rating-val">{Number(expert.rating_avg ?? 0).toFixed(1)}</span>
        <span className="ec-rating-count">({expert.total_reviews ?? 0} avis)</span>
        {expert.certifications?.length > 0 && (
          <span className="ec-cert-count">
            <Award size={11} /> {expert.certifications.length}
          </span>
        )}
      </div>

      {/* Bio */}
      {expert.bio && <p className="ec-bio">{expert.bio}</p>}

      {/* Footer */}
      <div className="ec-footer">
        <Link to={`/experts/${expert.id}`} className="ec-btn">
          Consulter
        </Link>
      </div>
    </motion.div>
  );
}

export default function ExpertsPage() {
  const [search,     setSearch]     = useState('');
  const [categoryId, setCategoryId] = useState('');
  const [available,  setAvailable]  = useState('');
  const [page,       setPage]       = useState(1);
  // { [expertId]: true/false } — set instantly by WebSocket, overrides API value
  const [onlineMap,  setOnlineMap]  = useState({});
  const subscribedRef = useRef(new Set());

  const { data: experts,    isLoading } = useExperts({
    search:      search      || undefined,
    category_id: categoryId  || undefined,
    available:   available   || undefined,
    page,
    per_page: 12,
  });
  const { data: categories = [] } = useCategories();

  // Subscribe to expert-presence.{id} for every expert on the current page
  useEffect(() => {
    const list = experts?.data ?? [];
    if (list.length === 0) return;
    const echo = getEcho();
    const newIds = [];

    list.forEach(({ id }) => {
      if (subscribedRef.current.has(id)) return;
      subscribedRef.current.add(id);
      newIds.push(id);
      echo.private(`expert-presence.${id}`).listen('.user.presence', (event) => {
        setOnlineMap(prev => ({ ...prev, [id]: event.is_online === true }));
      });
    });

    return () => {
      newIds.forEach(id => {
        subscribedRef.current.delete(id);
        try {
          echo.private(`expert-presence.${id}`).stopListening('.user.presence');
          echo.leave(`expert-presence.${id}`);
        } catch (_) {}
      });
    };
  }, [experts?.data]);

  const handleSearch = (e) => { setSearch(e.target.value); setPage(1); };

  const total = experts?.meta?.total ?? experts?.data?.length ?? 0;

  return (
    <div className="ep-page">

      {/* ── Header ── */}
      <div className="ep-header">
        <div className="ep-header-bg" />
        <div className="ep-header-content">
          <div>
            <p className="ep-eyebrow">Annuaire médical</p>
            <h1 className="ep-title">Nos Médecins</h1>
            <p className="ep-subtitle">Consultez un médecin qualifié selon votre spécialité</p>
          </div>
          {!isLoading && (
            <div className="ep-header-stat">
              <span className="ep-stat-val">{total}</span>
              <span className="ep-stat-lbl"><Users size={11} /> Médecins</span>
            </div>
          )}
        </div>
      </div>

      <div className="ep-divider" />

      <div className="ep-body">

        {/* ── Filters ── */}
        <div className="ep-filters">
          <div className="ep-search-wrap">
            <Search size={15} className="ep-search-icon" />
            <input
              type="text"
              placeholder="Rechercher par nom, spécialité…"
              className="ep-search"
              value={search}
              onChange={handleSearch}
            />
          </div>

          <div className="ep-filter-pills">
            <button
              className={`ep-pill ${categoryId === '' ? 'ep-pill--active' : ''}`}
              onClick={() => { setCategoryId(''); setPage(1); }}
            >
              Toutes
            </button>
            {categories.map(cat => (
              <button
                key={cat.id}
                className={`ep-pill ${categoryId == cat.id ? 'ep-pill--active' : ''}`}
                onClick={() => { setCategoryId(cat.id); setPage(1); }}
              >
                {cat.name}
              </button>
            ))}
          </div>

          <button
            className={`ep-avail-toggle ${available === '1' ? 'ep-avail-toggle--on' : ''}`}
            onClick={() => { setAvailable(available === '1' ? '' : '1'); setPage(1); }}
          >
            <span className="ep-avail-toggle-dot" />
            Disponibles
          </button>
        </div>

        {/* ── Results ── */}
        {isLoading ? (
          <div className="ep-loading"><Loader2 size={28} className="spin" /></div>
        ) : experts?.data?.length === 0 ? (
          <div className="ep-empty">
            <Users size={36} />
            <h3>Aucun médecin trouvé</h3>
            <p>Essayez d'autres critères de recherche.</p>
          </div>
        ) : (
          <>
            <div className="ep-grid">
              {experts.data.map((expert, i) => (
                <ExpertCard
                  key={expert.id}
                  expert={expert}
                  index={i}
                  isOnline={onlineMap[expert.id] !== undefined
                    ? onlineMap[expert.id]
                    : (expert.user?.is_online ?? false)}
                />
              ))}
            </div>

            {experts?.meta?.last_page > 1 && (
              <div className="ep-pagination">
                <button className="ep-page-btn" disabled={page === 1} onClick={() => setPage(p => p - 1)}>
                  ← Précédent
                </button>
                <span className="ep-page-info">
                  {experts.meta.current_page} / {experts.meta.last_page}
                </span>
                <button className="ep-page-btn" disabled={page === experts.meta.last_page} onClick={() => setPage(p => p + 1)}>
                  Suivant →
                </button>
              </div>
            )}
          </>
        )}

      </div>
    </div>
  );
}
