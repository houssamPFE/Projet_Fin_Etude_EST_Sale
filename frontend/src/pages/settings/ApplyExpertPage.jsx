import { useState, useRef } from 'react';
import {
  Loader2, Upload, X, CheckCircle2, FileText,
  ImageIcon, ShieldCheck, Clock, Star, MapPin,
  AlertCircle, Info, Stethoscope,
} from 'lucide-react';
import toast from 'react-hot-toast';
import { useCategories } from '../../hooks/useExperts';
import { useApplyExpert } from '../../hooks/useProfile';
import CustomSelect from '../../components/CustomSelect';
import './ApplyExpertPage.css';

const DOC_TYPES = [
  { value: 'diploma',     label: 'Diplôme de médecine' },
  { value: 'id_card',     label: 'Pièce d\'identité' },
  { value: 'certificate', label: 'Certificat / Attestation' },
  { value: 'other',       label: 'Autre document' },
];

function FileIcon({ name }) {
  if (name?.match(/\.(jpg|jpeg|png|webp)$/i)) return <ImageIcon size={15} />;
  return <FileText size={15} />;
}

function formatSize(bytes) {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(0)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

export default function ApplyExpertPage() {
  const { data: categories = [] }        = useCategories();
  const { mutateAsync: apply, isPending } = useApplyExpert();

  const [categoryId,  setCategoryId]  = useState('');
  const [bio,         setBio]         = useState('');
  const [city,        setCity]        = useState('');
  const [documents,   setDocuments]   = useState([]);
  const [docType,     setDocType]     = useState('diploma');
  const [submitted,   setSubmitted]   = useState(false);
  const fileRef = useRef();

  const handleFileAdd = (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setDocuments(prev => [...prev, { file, type: docType }]);
    e.target.value = '';
  };
  const removeDoc = (i) => setDocuments(prev => prev.filter((_, idx) => idx !== i));

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!categoryId)          { toast.error('Veuillez sélectionner une spécialité.'); return; }
    if (documents.length === 0) { toast.error('Au moins un document justificatif est requis.'); return; }

    const formData = new FormData();
    formData.append('category_id', categoryId);
    if (bio)        formData.append('bio', bio);
    if (city)       formData.append('city', city);
    documents.forEach((doc, i) => {
      formData.append(`documents[${i}][file]`, doc.file);
      formData.append(`documents[${i}][type]`, doc.type);
    });

    try {
      await apply(formData);
      setSubmitted(true);
    } catch (err) {
      toast.error(err.response?.data?.message || 'Erreur lors de la soumission.');
    }
  };

  if (submitted) {
    return (
      <div className="aep-page">
        <div className="aep-success">
          <div className="aep-success-icon">
            <CheckCircle2 size={40} />
          </div>
          <h2 className="aep-success-title">Candidature envoyée !</h2>
          <p className="aep-success-sub">Notre équipe examine votre dossier sous 24–48 h.</p>
          <div className="aep-success-steps">
            {[
              { icon: FileText,     label: 'Dossier reçu',         desc: 'Votre candidature est en file d\'attente' },
              { icon: ShieldCheck,  label: 'Vérification CNOM',    desc: 'Validation de votre numéro INPE' },
              { icon: CheckCircle2, label: 'Validation finale',    desc: 'Activation de votre compte médecin' },
            ].map(({ icon: Icon, label, desc }, i) => (
              <div key={i} className="aep-success-step">
                <div className="aep-success-step-icon"><Icon size={18} /></div>
                <div>
                  <p className="aep-success-step-label">{label}</p>
                  <p className="aep-success-step-desc">{desc}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="aep-page">

      {/* ── Header ── */}
      <div className="aep-header">
        <div className="aep-header-bg" />
        <div className="aep-header-content">
          <div>
            <p className="aep-eyebrow"><Stethoscope size={11} /> Espace médecin</p>
            <h1 className="aep-title">Rejoindre Nexora</h1>
            <p className="aep-subtitle">Soumettez votre candidature pour rejoindre notre réseau de médecins</p>
          </div>
        </div>
      </div>

      <div className="aep-divider" />

      <div className="aep-body">
        <div className="aep-layout">

          {/* ── Form ── */}
          <form className="aep-form" onSubmit={handleSubmit}>

            {/* Step 1 */}
            <div className="aep-section-label"><span>1 — Informations professionnelles</span></div>

            <div className="aep-card">
              <div className="aep-form-group">
                <label className="aep-label">Spécialité médicale <span className="aep-required">*</span></label>
                <CustomSelect
                  value={categoryId}
                  onChange={e => setCategoryId(e.target.value)}
                  placeholder="Sélectionnez votre spécialité..."
                  options={categories.map(c => ({ value: c.id, label: c.name }))}
                />
              </div>

              <div className="aep-form-row">
                <div className="aep-form-group">
                  <label className="aep-label">Ville</label>
                  <div className="aep-input-wrap">
                    <MapPin size={14} className="aep-input-icon" />
                    <input
                      type="text"
                      className="aep-input"
                      placeholder="Ex: Casablanca"
                      value={city}
                      onChange={e => setCity(e.target.value)}
                    />
                  </div>
                </div>
              </div>

              <div className="aep-form-group">
                <label className="aep-label">Biographie professionnelle</label>
                <textarea
                  className="aep-input aep-textarea"
                  rows={4}
                  placeholder="Décrivez votre parcours, vos spécialisations, votre approche avec les patients…"
                  value={bio}
                  onChange={e => setBio(e.target.value)}
                  maxLength={2000}
                />
                <span className="aep-char">{bio.length}/2000</span>
              </div>
            </div>

            {/* Step 2 */}
            <div className="aep-section-label" style={{ marginTop: 'var(--space-md)' }}>
              <span>2 — Documents justificatifs <span className="aep-required">*</span></span>
            </div>

            <div className="aep-card">
              {documents.length > 0 && (
                <ul className="aep-doc-list">
                  {documents.map((doc, i) => (
                    <li key={i} className="aep-doc-item">
                      <div className="aep-doc-icon"><FileIcon name={doc.file.name} /></div>
                      <div className="aep-doc-info">
                        <span className="aep-doc-name">{doc.file.name}</span>
                        <span className="aep-doc-meta">
                          {DOC_TYPES.find(t => t.value === doc.type)?.label} · {formatSize(doc.file.size)}
                        </span>
                      </div>
                      <button type="button" className="aep-doc-remove" onClick={() => removeDoc(i)}>
                        <X size={13} />
                      </button>
                    </li>
                  ))}
                </ul>
              )}

              <div className="aep-doc-add">
                <CustomSelect
                  value={docType}
                  onChange={e => setDocType(e.target.value)}
                  options={DOC_TYPES}
                />
                <input
                  ref={fileRef}
                  type="file"
                  accept=".pdf,.jpg,.jpeg,.png"
                  style={{ display: 'none' }}
                  onChange={handleFileAdd}
                />
                <button type="button" className="aep-upload-btn" onClick={() => fileRef.current?.click()}>
                  <Upload size={14} /> Ajouter un fichier
                </button>
              </div>
              <p className="aep-doc-hint">
                Formats acceptés : PDF, JPG, PNG · Taille max : 5 MB par fichier
              </p>
            </div>

            <div className="aep-actions">
              <button type="submit" className="aep-submit-btn" disabled={isPending}>
                {isPending ? <Loader2 size={16} className="spin" /> : <CheckCircle2 size={16} />}
                {isPending ? 'Envoi en cours…' : 'Soumettre ma candidature'}
              </button>
            </div>

          </form>

          {/* ── Sidebar info ── */}
          <aside className="aep-sidebar">

            <div className="aep-info-card">
              <h3 className="aep-info-title">Comment ça marche ?</h3>
              <div className="aep-steps">
                {[
                  { icon: FileText,     label: 'Soumettez votre dossier',   desc: 'Remplissez le formulaire et joignez vos documents médicaux.' },
                  { icon: ShieldCheck,  label: 'Vérification CNOM',          desc: 'Notre équipe vérifie votre INPE sur le registre de l\'Ordre National des Médecins du Maroc.' },
                  { icon: Star,         label: 'Activation du compte',       desc: 'Une fois validé, vous recevez vos accès et commencez à recevoir des consultations.' },
                ].map(({ icon: Icon, label, desc }, i) => (
                  <div key={i} className="aep-step">
                    <div className="aep-step-num">{i + 1}</div>
                    <div>
                      <p className="aep-step-label">{label}</p>
                      <p className="aep-step-desc">{desc}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <div className="aep-info-card">
              <h3 className="aep-info-title"><Info size={14} /> Documents requis</h3>
              <ul className="aep-doc-reqs">
                <li><CheckCircle2 size={13} /> Doctorat en Médecine (obligatoire)</li>
                <li><CheckCircle2 size={13} /> Carte nationale d'identité ou passeport</li>
                <li><CheckCircle2 size={13} /> Numéro INPE (Ordre des Médecins du Maroc)</li>
                <li><CheckCircle2 size={13} /> Certificat de spécialité (si applicable)</li>
              </ul>
            </div>

            <div className="aep-notice">
              <AlertCircle size={14} />
              <p>Délai de traitement : <strong>24 à 48 heures</strong> ouvrables après réception de votre dossier complet.</p>
            </div>

            <div className="aep-earnings">
              <div>
                <p className="aep-earnings-label">Rémunération par consultation</p>
                <p className="aep-earnings-val">70 MAD</p>
                <p className="aep-earnings-sub">versés directement sur votre wallet</p>
              </div>
              <Clock size={16} className="aep-earnings-icon aep-earnings-icon--right" />
            </div>

          </aside>

        </div>
      </div>
    </div>
  );
}
