import {
  Star, Clock, ArrowLeft, CheckCircle, Loader2, MessageSquare,
  ShieldCheck, MapPin, Languages, Award, Calendar, Activity,
} from 'lucide-react';
import { useParams, useNavigate } from 'react-router-dom';
import { useExpert, useExpertReviews } from '../../hooks/useExperts';
import './ExpertDetailPage.css';

function StarRow({ rating }) {
  return (
    <span className="star-row">
      {[1, 2, 3, 4, 5].map((s) => (
        <Star key={s} size={14} fill={s <= rating ? '#f59e0b' : 'none'} stroke="#f59e0b" />
      ))}
    </span>
  );
}

function relativeTime(iso) {
  if (!iso) return '';
  const diff = (Date.now() - new Date(iso).getTime()) / 1000;
  if (diff < 86400) return 'aujourd\'hui';
  if (diff < 604800) return `il y a ${Math.floor(diff / 86400)} j`;
  if (diff < 2592000) return `il y a ${Math.floor(diff / 604800)} sem`;
  return new Date(iso).toLocaleDateString('fr-FR', { day: 'numeric', month: 'short', year: 'numeric' });
}

export default function ExpertDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { data: expert, isLoading } = useExpert(id);
  const { data: reviewsData, isLoading: reviewsLoading } = useExpertReviews(id);

  if (isLoading) {
    return (
      <div className="ed-loading">
        <Loader2 size={32} className="spin" />
      </div>
    );
  }

  if (!expert) {
    return <div className="ed-empty">Médecin introuvable.</div>;
  }

  const reviews = reviewsData?.data ?? [];
  const initials = expert.user?.name?.split(' ').map((p) => p[0]).slice(0, 2).join('').toUpperCase() ?? 'D';

  return (
    <div className="ed">
      <button className="ed-back" onClick={() => navigate(-1)}>
        <ArrowLeft size={16} /> Retour
      </button>

      <motion.div
        className="ed-hero"
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4 }}
      >
        <div className="ed-hero-glow" />

        <div className="ed-hero-main">
          <div className="ed-avatar-wrap">
            <div className="ed-avatar">{initials}</div>
            {expert.is_available && <span className="ed-avatar-pulse" />}
          </div>

          <div className="ed-hero-info">
            <div className="ed-hero-tags">
              {expert.category?.icon && (
                <span className="ed-chip ed-chip--specialty">
                  <span>{expert.category.icon}</span>
                  {expert.category.name}
                </span>
              )}
              {expert.validated_at && (
                <span className="ed-chip ed-chip--verified">
                  <ShieldCheck size={13} />
                  Vérifié INPE
                </span>
              )}
              <span className={`ed-chip ${expert.is_available ? 'ed-chip--available' : 'ed-chip--busy'}`}>
                <span className="ed-dot" />
                {expert.is_available ? 'Disponible maintenant' : 'Indisponible'}
              </span>
            </div>

            <h1 className="ed-name">{expert.user?.name}</h1>
            <p className="ed-tagline">
              {expert.category?.description ?? 'Médecin diplômé'}
            </p>
          </div>
        </div>

        <div className="ed-hero-cta">
          <button
            className="ed-cta"
            disabled={!expert.is_available}
            onClick={() => navigate('/conversations/new', {
              state: {
                expert_id: expert.id,
              },
            })}
          >
            <MessageSquare size={18} />
            Démarrer une consultation
          </button>
          <div className="ed-cta-meta">
            <Clock size={13} />
            Réponse en moyenne sous 5 min
          </div>
        </div>
      </motion.div>

      <div className="ed-stats">
        <div className="ed-stat">
          <div className="ed-stat-icon ed-stat-icon--star"><Star size={18} /></div>
          <div className="ed-stat-value">{Number(expert.rating_avg ?? 0).toFixed(1)}</div>
          <div className="ed-stat-label">{expert.total_reviews} avis</div>
        </div>
        <div className="ed-stat">
          <div className="ed-stat-icon ed-stat-icon--rate"><Activity size={18} /></div>
          <div className="ed-stat-value">{expert.hourly_rate ?? '—'}<span className="ed-stat-unit"> MAD</span></div>
          <div className="ed-stat-label">par heure</div>
        </div>
        <div className="ed-stat">
          <div className="ed-stat-icon ed-stat-icon--cal"><Calendar size={18} /></div>
          <div className="ed-stat-value">{relativeTime(expert.validated_at)}</div>
          <div className="ed-stat-label">membre depuis</div>
        </div>
        <div className="ed-stat">
          <div className="ed-stat-icon ed-stat-icon--lang"><Languages size={18} /></div>
          <div className="ed-stat-value">FR · AR</div>
          <div className="ed-stat-label">langues parlées</div>
        </div>
      </div>

      <div className="ed-grid">
        <section className="ed-card">
          <h2 className="ed-section-title">À propos</h2>
          <p className="ed-bio">
            {expert.bio ?? 'Aucune biographie renseignée.'}
          </p>
        </section>

        {Array.isArray(expert.certifications) && expert.certifications.length > 0 && (
          <section className="ed-card">
            <h2 className="ed-section-title">
              <Award size={16} /> Diplômes & certifications
            </h2>
            <ul className="ed-certs">
              {expert.certifications.map((cert, i) => (
                <li key={i}>
                  <CheckCircle size={14} />
                  {cert}
                </li>
              ))}
            </ul>
          </section>
        )}

        <section className="ed-card">
          <h2 className="ed-section-title">
            <MapPin size={16} /> Cabinet
          </h2>
          <p className="ed-cabinet">
            Consultations en ligne uniquement via la plateforme Nexora.
            Échanges sécurisés et confidentiels.
          </p>
        </section>
      </div>

      <section className="ed-reviews">
        <div className="ed-reviews-head">
          <h2 className="ed-section-title">Avis des patients</h2>
          {reviews.length > 0 && (
            <span className="ed-reviews-count">{reviews.length} avis</span>
          )}
        </div>

        {reviewsLoading ? (
          <div className="ed-loading"><Loader2 size={20} className="spin" /></div>
        ) : reviews.length === 0 ? (
          <div className="ed-card ed-reviews-empty">
            Aucun avis pour le moment. Soyez le premier à partager votre expérience.
          </div>
        ) : (
          <div className="ed-reviews-list">
            {reviews.map((review) => (
              <motion.div
                key={review.id}
                className="ed-review"
                initial={{ opacity: 0, y: 6 }}
                animate={{ opacity: 1, y: 0 }}
              >
                <div className="ed-review-head">
                  <div className="ed-review-avatar">
                    {review.user?.name?.charAt(0)?.toUpperCase()}
                  </div>
                  <div className="ed-review-meta">
                    <p className="ed-review-author">{review.user?.name}</p>
                    <div className="ed-review-stars">
                      <StarRow rating={review.rating} />
                      <span className="ed-review-time">{relativeTime(review.created_at)}</span>
                    </div>
                  </div>
                </div>
                {review.comment && <p className="ed-review-text">{review.comment}</p>}
              </motion.div>
            ))}
          </div>
        )}
      </section>
    </div>
  );
}
