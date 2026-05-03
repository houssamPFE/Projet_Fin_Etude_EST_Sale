import { useState } from 'react';
import { motion } from 'framer-motion';
import { Search, Star, Clock, Filter, Loader2 } from 'lucide-react';
import { Link } from 'react-router-dom';
import { useExperts, useCategories } from '../../hooks/useExperts';
import CustomSelect from '../../components/CustomSelect';
import './ExpertsPage.css';

function ExpertCard({ expert, index }) {
  return (
    <motion.div
      className="expert-card"
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.35, delay: index * 0.06 }}
    >
      <div className="expert-card-header">
        <div className="expert-avatar">
          {expert.user?.name?.charAt(0)?.toUpperCase() ?? 'E'}
        </div>
        <div className="expert-card-meta">
          <h3 className="expert-name">{expert.user?.name}</h3>
          <span className="expert-category">{expert.category?.name}</span>
        </div>
        <span className={`expert-badge ${expert.is_available ? 'expert-badge--available' : 'expert-badge--busy'}`}>
          {expert.is_available ? 'Disponible' : 'Occupé'}
        </span>
      </div>

      {expert.bio && (
        <p className="expert-bio">{expert.bio}</p>
      )}

      <div className="expert-card-footer">
        <div className="expert-stat">
          <Star size={14} fill="currentColor" />
          <span>{Number(expert.rating_avg).toFixed(1)}</span>
          <span className="text-muted">({expert.total_reviews})</span>
        </div>
        {expert.hourly_rate && (
          <div className="expert-stat">
            <Clock size={14} />
            <span>{expert.hourly_rate} MAD/h</span>
          </div>
        )}
        <Link to={`/experts/${expert.id}`} className="btn btn-primary btn-sm">
          Voir le profil
        </Link>
      </div>
    </motion.div>
  );
}

export default function ExpertsPage() {
  const [search, setSearch] = useState('');
  const [categoryId, setCategoryId] = useState('');
  const [available, setAvailable] = useState('');
  const [page, setPage] = useState(1);

  const { data: experts, isLoading } = useExperts({
    search: search || undefined,
    category_id: categoryId || undefined,
    available: available || undefined,
    page,
    per_page: 12,
  });

  const { data: categories = [] } = useCategories();

  const handleSearch = (e) => {
    setSearch(e.target.value);
    setPage(1);
  };

  return (
    <div className="experts-page">
      <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.4 }}>

        <div className="experts-header">
          <div>
            <h1 className="page-title">Nos Experts</h1>
            <p className="page-subtitle">Trouvez l'expert qui correspond à votre besoin</p>
          </div>
        </div>

        {/* Filters */}
        <div className="experts-filters">
          <div className="search-input-wrap">
            <Search size={16} className="search-icon" />
            <input
              type="text"
              placeholder="Rechercher un expert..."
              className="search-input"
              value={search}
              onChange={handleSearch}
            />
          </div>

          <div className="filter-group">
            <Filter size={16} />
            <CustomSelect
              value={categoryId}
              onChange={(e) => { setCategoryId(e.target.value); setPage(1); }}
              placeholder="Toutes les catégories"
              options={categories.map((cat) => ({ value: cat.id, label: cat.name }))}
            />
          </div>

          <CustomSelect
            value={available}
            onChange={(e) => { setAvailable(e.target.value); setPage(1); }}
            placeholder="Tous"
            options={[{ value: '1', label: 'Disponibles uniquement' }]}
          />
        </div>

        {/* Results */}
        {isLoading ? (
          <div className="experts-loading">
            <Loader2 size={32} className="spin" style={{ color: 'var(--primary-500)' }} />
          </div>
        ) : experts?.data?.length === 0 ? (
          <div className="experts-empty">
            <p>Aucun expert trouvé pour ces critères.</p>
          </div>
        ) : (
          <>
            <div className="experts-grid">
              {experts?.data?.map((expert, i) => (
                <ExpertCard key={expert.id} expert={expert} index={i} />
              ))}
            </div>

            {/* Pagination */}
            {experts?.meta?.last_page > 1 && (
              <div className="pagination">
                <button
                  className="btn btn-secondary btn-sm"
                  disabled={page === 1}
                  onClick={() => setPage((p) => p - 1)}
                >
                  Précédent
                </button>
                <span className="pagination-info">
                  Page {experts.meta.current_page} / {experts.meta.last_page}
                </span>
                <button
                  className="btn btn-secondary btn-sm"
                  disabled={page === experts.meta.last_page}
                  onClick={() => setPage((p) => p + 1)}
                >
                  Suivant
                </button>
              </div>
            )}
          </>
        )}
      </motion.div>
    </div>
  );
}
