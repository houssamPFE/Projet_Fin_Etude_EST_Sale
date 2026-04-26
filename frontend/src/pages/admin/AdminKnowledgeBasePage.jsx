import { useState } from 'react';
import { Plus, Pencil, Trash2, X, Loader2, Search, BookOpen } from 'lucide-react';
import {
  useAdminKnowledge,
  useCreateKnowledge,
  useUpdateKnowledge,
  useDeleteKnowledge,
  useAdminCategories,
} from '../../hooks/useAdmin';
import './AdminKnowledgeBasePage.css';

const emptyForm = {
  category_id: '',
  question: '',
  answer: '',
  keywords: '',
  language: 'fr',
  is_active: true,
};

function toForm(entry) {
  return {
    category_id: entry.category_id ?? '',
    question: entry.question ?? '',
    answer: entry.answer ?? '',
    keywords: Array.isArray(entry.keywords) ? entry.keywords.join(', ') : '',
    language: entry.language ?? 'fr',
    is_active: entry.is_active ?? true,
  };
}

function toPayload(form) {
  return {
    category_id: form.category_id ? Number(form.category_id) : null,
    question: form.question.trim(),
    answer: form.answer.trim(),
    keywords: form.keywords
      .split(',')
      .map((k) => k.trim())
      .filter(Boolean),
    language: form.language,
    is_active: form.is_active,
  };
}

export default function AdminKnowledgeBasePage() {
  const [search, setSearch] = useState('');
  const [language, setLanguage] = useState('');
  const [categoryId, setCategoryId] = useState('');

  const params = {
    ...(search && { search }),
    ...(language && { language }),
    ...(categoryId && { category_id: categoryId }),
  };

  const { data, isLoading } = useAdminKnowledge(params);
  const { data: categories } = useAdminCategories();
  const createKB = useCreateKnowledge();
  const updateKB = useUpdateKnowledge();
  const deleteKB = useDeleteKnowledge();

  const [modal, setModal] = useState(null);
  const [form, setForm] = useState(emptyForm);
  const [editId, setEditId] = useState(null);

  const openCreate = () => { setForm(emptyForm); setModal('create'); };
  const openEdit = (entry) => {
    setForm(toForm(entry));
    setEditId(entry.id);
    setModal('edit');
  };
  const closeModal = () => { setModal(null); setEditId(null); };

  const handleSubmit = (e) => {
    e.preventDefault();
    const payload = toPayload(form);
    if (modal === 'create') {
      createKB.mutate(payload, { onSuccess: closeModal });
    } else {
      updateKB.mutate({ id: editId, ...payload }, { onSuccess: closeModal });
    }
  };

  const entries = data?.data ?? [];

  return (
    <div className="admin-kb">
      <div className="page-header-row">
        <div>
          <h1>Base de connaissances</h1>
          <p className="page-subtitle">
            Questions/réponses utilisées par l'IA pour répondre aux patients.
          </p>
        </div>
        <button className="btn-primary" onClick={openCreate}>
          <Plus size={16} /> Nouvelle entrée
        </button>
      </div>

      <div className="kb-filters">
        <div className="kb-search">
          <Search size={16} />
          <input
            type="text"
            placeholder="Rechercher une question..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
        <select value={categoryId} onChange={(e) => setCategoryId(e.target.value)}>
          <option value="">Toutes les spécialités</option>
          {categories?.map((c) => (
            <option key={c.id} value={c.id}>{c.name}</option>
          ))}
        </select>
        <select value={language} onChange={(e) => setLanguage(e.target.value)}>
          <option value="">Toutes les langues</option>
          <option value="fr">Français</option>
          <option value="ar">العربية</option>
        </select>
      </div>

      {isLoading ? (
        <div className="loading-center"><Loader2 className="spin" size={24} /></div>
      ) : entries.length === 0 ? (
        <div className="kb-empty">
          <BookOpen size={42} style={{ opacity: 0.3, marginBottom: 12 }} />
          <p>Aucune entrée trouvée. Créez la première ci-dessus.</p>
        </div>
      ) : (
        <div className="kb-list">
          {entries.map((entry) => (
            <div key={entry.id} className="kb-card">
              <div className="kb-card-meta">
                {entry.category && (
                  <span className="kb-tag kb-tag--cat">
                    {entry.category.icon} {entry.category.name}
                  </span>
                )}
                <span className={`kb-tag kb-tag--lang kb-tag--lang-${entry.language}`}>
                  {entry.language === 'fr' ? 'FR' : 'AR'}
                </span>
                {!entry.is_active && (
                  <span className="kb-tag kb-tag--inactive">Inactif</span>
                )}
              </div>
              <h3 className="kb-q">{entry.question}</h3>
              <p className="kb-a">{entry.answer}</p>
              {entry.keywords?.length > 0 && (
                <div className="kb-keywords">
                  {entry.keywords.map((k, i) => (
                    <span key={i} className="kb-kw">{k}</span>
                  ))}
                </div>
              )}
              <div className="kb-actions">
                <button className="icon-btn" onClick={() => openEdit(entry)}>
                  <Pencil size={15} />
                </button>
                <button
                  className="icon-btn danger"
                  onClick={() => {
                    if (confirm('Supprimer cette entrée ?')) deleteKB.mutate(entry.id);
                  }}
                >
                  <Trash2 size={15} />
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {modal && (
        <div className="kb-modal-overlay" onClick={closeModal}>
          <form
            className="kb-modal"
            onClick={(e) => e.stopPropagation()}
            onSubmit={handleSubmit}
          >
            <div className="kb-modal-header">
              <h2>{modal === 'create' ? 'Nouvelle entrée' : 'Modifier l\'entrée'}</h2>
              <button type="button" className="icon-btn" onClick={closeModal}>
                <X size={18} />
              </button>
            </div>

            <div className="kb-form-row">
              <label>
                Spécialité
                <select
                  value={form.category_id}
                  onChange={(e) => setForm({ ...form, category_id: e.target.value })}
                >
                  <option value="">Aucune (générale)</option>
                  {categories?.map((c) => (
                    <option key={c.id} value={c.id}>{c.name}</option>
                  ))}
                </select>
              </label>
              <label>
                Langue
                <select
                  value={form.language}
                  onChange={(e) => setForm({ ...form, language: e.target.value })}
                  required
                >
                  <option value="fr">Français</option>
                  <option value="ar">العربية</option>
                </select>
              </label>
            </div>

            <label>
              Question
              <input
                type="text"
                value={form.question}
                onChange={(e) => setForm({ ...form, question: e.target.value })}
                placeholder="Ex: Quels sont les symptômes de la grippe ?"
                maxLength={1000}
                required
              />
            </label>

            <label>
              Réponse
              <textarea
                value={form.answer}
                onChange={(e) => setForm({ ...form, answer: e.target.value })}
                rows={6}
                placeholder="Réponse informative — pas de diagnostic, pas de prescription. Recommander une consultation médicale si nécessaire."
                required
              />
            </label>

            <label>
              Mots-clés (séparés par des virgules)
              <input
                type="text"
                value={form.keywords}
                onChange={(e) => setForm({ ...form, keywords: e.target.value })}
                placeholder="grippe, fièvre, courbatures"
              />
            </label>

            <label className="kb-toggle">
              <input
                type="checkbox"
                checked={form.is_active}
                onChange={(e) => setForm({ ...form, is_active: e.target.checked })}
              />
              <span>Active (utilisée par l'IA)</span>
            </label>

            <div className="kb-modal-actions">
              <button type="button" className="btn-ghost" onClick={closeModal}>
                Annuler
              </button>
              <button
                type="submit"
                className="btn-primary"
                disabled={createKB.isPending || updateKB.isPending}
              >
                {(createKB.isPending || updateKB.isPending) && (
                  <Loader2 size={14} className="spin" />
                )}
                {modal === 'create' ? 'Créer' : 'Enregistrer'}
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
}
