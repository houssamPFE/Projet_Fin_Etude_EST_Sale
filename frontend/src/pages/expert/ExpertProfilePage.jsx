import { useState, useEffect, useRef } from 'react';
import {
  Loader2, Save, Plus, X, Camera, BadgeCheck,
  Star, Award, FileText, ShieldCheck, MapPin,
} from 'lucide-react';
import { useExpertProfile, useUpdateExpertProfile } from '../../hooks/useExpertPanel';
import { useCategories } from '../../hooks/useExperts';
import { useUploadAvatar } from '../../hooks/useProfile';
import useAuthStore from '../../stores/authStore';
import CustomSelect from '../../components/CustomSelect';
import AvatarCropModal from '../../components/AvatarCropModal';
import toast from 'react-hot-toast';
import './ExpertProfilePage.css';

function StarRating({ value }) {
  const n = Math.round(value ?? 0);
  return (
    <span className="eprof-stars">
      {[1,2,3,4,5].map(i => (
        <Star key={i} size={13} className={i <= n ? 'eprof-star--on' : 'eprof-star--off'} />
      ))}
    </span>
  );
}

export default function ExpertProfilePage() {
  const user = useAuthStore((s) => s.user);
  const { data: expert, isLoading } = useExpertProfile();
  const { data: categories = [] }   = useCategories();
  const { mutateAsync: updateProfile, isPending } = useUpdateExpertProfile();

  const fileRef = useRef(null);
  const [cropSrc, setCropSrc] = useState(null);
  const { mutateAsync: uploadAvatar, isPending: uploading } = useUploadAvatar();

  const [bio,          setBio]          = useState('');
  const [city,         setCity]         = useState('');
  const [categoryId,   setCategoryId]   = useState('');
  const [certifications, setCertifications] = useState([]);
  const [newCert,      setNewCert]      = useState('');

  useEffect(() => {
    if (expert) {
      setBio(expert.bio ?? '');
      setCity(expert.city ?? '');
      setCategoryId(expert.category?.id ?? '');
      const c = expert.certifications;
      if (Array.isArray(c)) setCertifications(c);
      else if (typeof c === 'string') {
        try { setCertifications(JSON.parse(c)); } catch { setCertifications([]); }
      }
    }
  }, [expert]);

  const handleFileSelect = (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setCropSrc(URL.createObjectURL(file));
    e.target.value = '';
  };

  const handleCropConfirm = async (blob) => {
    setCropSrc(null);
    try {
      await uploadAvatar(new File([blob], 'avatar.jpg', { type: 'image/jpeg' }));
      toast.success('Photo de profil mise à jour.');
    } catch { toast.error("Impossible de mettre à jour la photo."); }
  };

  const addCert = () => {
    const val = newCert.trim();
    if (val && !certifications.includes(val)) {
      setCertifications([...certifications, val]);
      setNewCert('');
    }
  };
  const removeCert = (i) => setCertifications(certifications.filter((_, idx) => idx !== i));

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      await updateProfile({
        bio:            bio || undefined,
        city:           city || undefined,
        category_id:    categoryId || undefined,
        certifications: certifications.length ? certifications : undefined,
      });
      toast.success('Profil mis à jour avec succès.');
    } catch {
      toast.error('Impossible de mettre à jour le profil.');
    }
  };

  const selectedCategory = categories.find(c => c.id == categoryId);

  if (isLoading) {
    return <div className="eprof-page-loading"><Loader2 size={28} className="spin" /></div>;
  }

  return (
    <>
    {cropSrc && <AvatarCropModal imageSrc={cropSrc} onConfirm={handleCropConfirm} onClose={() => setCropSrc(null)} />}
    <div className="eprof-page">

      {/* ── Header ── */}
      <div className="eprof-header">
        <div className="eprof-header-bg" />
        <div className="eprof-header-content">
          <div>
            <p className="eprof-eyebrow">Mon espace</p>
            <h1 className="eprof-title">Profil expert</h1>
            <p className="eprof-subtitle">Vos informations visibles par les patients</p>
          </div>
          <div className="eprof-header-badges">
            <span className={`eprof-status-badge eprof-status-badge--${expert?.status ?? 'pending'}`}>
              <ShieldCheck size={13} />
              {expert?.status === 'validated' ? 'Profil validé' : expert?.status === 'rejected' ? 'Refusé' : 'En attente'}
            </span>
          </div>
        </div>
      </div>

      <div className="eprof-divider" />

      <div className="eprof-body">

        {/* ── Profile preview card ── */}
        <div className="eprof-section-label"><span>Aperçu public</span></div>

        <div className="eprof-preview-card">
          {/* Avatar */}
          <div className="eprof-avatar-wrap">
            <div className="eprof-avatar">
              {user?.avatar_url
                ? <img src={user.avatar_url} alt={user.name} />
                : user?.name?.charAt(0)?.toUpperCase()
              }
            </div>
            <button
              type="button"
              className="eprof-avatar-btn"
              onClick={() => fileRef.current?.click()}
              disabled={uploading}
              title="Changer la photo"
            >
              {uploading ? <Loader2 size={13} className="spin" /> : <Camera size={14} />}
            </button>
            <input ref={fileRef} type="file" accept="image/jpg,image/jpeg,image/png,image/webp" className="eprof-hidden-input" onChange={handleFileSelect} />
          </div>

          {/* Identity */}
          <div className="eprof-preview-identity">
            <div className="eprof-preview-name">
              Dr. {user?.name}
              {expert?.status === 'validated' && <BadgeCheck size={16} className="eprof-verified" />}
            </div>
            <div className="eprof-preview-specialty">
              {selectedCategory?.name ?? expert?.category?.name ?? 'Spécialité non renseignée'}
            </div>
            <div className="eprof-preview-rating">
              <StarRating value={expert?.rating_avg} />
              <span className="eprof-rating-val">{expert?.rating_avg ? Number(expert.rating_avg).toFixed(1) : '0.0'}</span>
              <span className="eprof-rating-count">({expert?.total_reviews ?? 0} avis)</span>
            </div>
            {bio && <p className="eprof-preview-bio">{bio}</p>}
          </div>

          {/* Stats */}
          <div className="eprof-preview-stats">
            <div className="eprof-preview-stat">
              <Award size={14} />
              <span>{certifications.length} certification{certifications.length !== 1 ? 's' : ''}</span>
            </div>
            <div className="eprof-preview-stat">
              <FileText size={14} />
              <span>{bio ? `${bio.length} car.` : 'Pas de bio'}</span>
            </div>
          </div>
        </div>

        {/* ── Form ── */}
        <form onSubmit={handleSubmit}>

          <div className="eprof-section-label"><span>Informations professionnelles</span></div>

          <div className="eprof-card">
            <div className="eprof-form-row">
              <div className="eprof-form-group">
                <label className="eprof-label">Spécialité médicale</label>
                <CustomSelect
                  value={categoryId}
                  onChange={e => setCategoryId(e.target.value)}
                  placeholder="Sélectionner une spécialité..."
                  options={categories.map(cat => ({ value: cat.id, label: cat.name }))}
                />
              </div>
              <div className="eprof-form-group">
                <label className="eprof-label">Ville</label>
                <div className="eprof-input-wrap">
                  <MapPin size={15} className="eprof-input-icon" />
                  <input
                    type="text"
                    className="eprof-input"
                    placeholder="Ex: Casablanca"
                    value={city}
                    onChange={e => setCity(e.target.value)}
                  />
                </div>
              </div>
            </div>

            <div className="eprof-form-group">
              <label className="eprof-label">Bio / À propos</label>
              <textarea
                className="eprof-input eprof-textarea"
                rows={4}
                placeholder="Décrivez votre expertise, votre parcours, votre approche..."
                value={bio}
                onChange={e => setBio(e.target.value)}
              />
              <span className="eprof-char-count">{bio.length} caractères</span>
            </div>
          </div>

          <div className="eprof-section-label" style={{ marginTop: 'var(--space-lg)' }}><span>Certifications</span></div>

          <div className="eprof-card">
            {certifications.length > 0 && (
              <div className="eprof-cert-tags">
                {certifications.map((cert, i) => (
                  <span key={i} className="eprof-cert-tag">
                    <Award size={12} />
                    {cert}
                    <button type="button" className="eprof-cert-remove" onClick={() => removeCert(i)}>
                      <X size={11} />
                    </button>
                  </span>
                ))}
              </div>
            )}
            <div className="eprof-cert-add">
              <input
                type="text"
                className="eprof-input"
                placeholder="Ex: Diplôme de psychiatrie, Université de Casablanca…"
                value={newCert}
                onChange={e => setNewCert(e.target.value)}
                onKeyDown={e => { if (e.key === 'Enter') { e.preventDefault(); addCert(); } }}
              />
              <button type="button" className="eprof-cert-btn" onClick={addCert}>
                <Plus size={16} />
              </button>
            </div>
            <p className="eprof-cert-hint">Appuyez sur Entrée ou + pour ajouter. Ces informations renforcent la confiance des patients.</p>
          </div>

          <div className="eprof-form-actions">
            <button type="submit" className="eprof-save-btn" disabled={isPending}>
              {isPending ? <Loader2 size={15} className="spin" /> : <Save size={15} />}
              {isPending ? 'Enregistrement…' : 'Enregistrer les modifications'}
            </button>
          </div>

        </form>

      </div>
    </div>
    </>
  );
}
