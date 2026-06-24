import { useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Plus, Pencil, Trash2, X, Search, BookOpen,
  Loader2, AlertTriangle, CheckCircle, ToggleLeft, ToggleRight,
  Languages, Hash,
} from 'lucide-react';
import CustomSelect from '../../components/CustomSelect';
import { KbSkeleton } from '../../components/AdminSkeleton';
import {
  useAdminKnowledge, useCreateKnowledge,
  useUpdateKnowledge, useDeleteKnowledge,
  useAdminCategories,
} from '../../hooks/useAdmin';
import './AdminKnowledgeBasePage.css';

const emptyForm = { category_id: '', question: '', answer: '', keywords: '', language: 'fr', is_active: true };

function toForm(e) {
  return {
    category_id: e.category_id ?? '',
    question:    e.question   ?? '',
    answer:      e.answer     ?? '',
    keywords:    Array.isArray(e.keywords) ? e.keywords.join(', ') : '',
    language:    e.language   ?? 'fr',
    is_active:   e.is_active  ?? true,
  };
}

function toPayload(form) {
  return {
    category_id: form.category_id ? Number(form.category_id) : null,
    question:    form.question.trim(),
    answer:      form.answer.trim(),
    keywords:    form.keywords.split(',').map(k => k.trim()).filter(Boolean),
    language:    form.language,
    is_active:   form.is_active,
  };
}

/* ── KPI card ── */
function KpiCard({ label, value, color, icon, isLoading }) {
  return (
    <div className={`kb-kpi kb-kpi--${color}`}>
      <div className="kb-kpi-ico">{icon}</div>
      <div>
        <div className="kb-kpi-val">{isLoading ? '…' : value}</div>
        <div className="kb-kpi-lbl">{label}</div>
      </div>
    </div>
  );
}

/* ── Entry card ── */
function EntryCard({ entry, idx, onEdit, onDelete }) {
  const [expanded, setExpanded] = useState(false);
  const isLong = entry.answer?.length > 220;

  return (
    <motion.div
      className={`kb-card${!entry.is_active ? ' kb-card--inactive' : ''}`}
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: idx * 0.03, duration: 0.22 }}
    >
      <div className={`kb-card-accent kb-card-accent--${entry.language}`} />

      <div className="kb-card-inner">
        <div className="kb-card-top">
          <div className="kb-card-tags">
            {entry.category && (
              <span className="kb-tag kb-tag--cat">
                {entry.category.icon} {entry.category.name}
              </span>
            )}
            <span className={`kb-tag kb-tag--lang kb-tag--lang-${entry.language}`}>
              {entry.language === 'fr' ? '🇫🇷 FR' : '🇲🇦 AR'}
            </span>
            {!entry.is_active && <span className="kb-tag kb-tag--off">Inactif</span>}
          </div>
          <div className="kb-card-actions">
            <button className="kb-act" title="Modifier" onClick={() => onEdit(entry)}>
              <Pencil size={13} />
            </button>
            <button className="kb-act kb-act--del" title="Supprimer" onClick={() => onDelete(entry)}>
              <Trash2 size={13} />
            </button>
          </div>
        </div>

        <h3 className="kb-q">{entry.question}</h3>

        <p className="kb-a">
          {isLong && !expanded ? entry.answer.slice(0, 220) + '…' : entry.answer}
        </p>
        {isLong && (
          <button className="kb-expand" onClick={() => setExpanded(v => !v)}>
            {expanded ? 'Réduire' : 'Voir plus'}
          </button>
        )}

        {entry.keywords?.length > 0 && (
          <div className="kb-keywords">
            <Hash size={10} className="kb-kw-ico" />
            {entry.keywords.map((k, i) => <span key={i} className="kb-kw">{k}</span>)}
          </div>
        )}
      </div>
    </motion.div>
  );
}

/* ── Create / Edit modal ── */
function EntryModal({ mode, form, setForm, categories, onClose, onSubmit, isPending }) {
  const isEdit = mode === 'edit';
  const f = (key, val) => setForm(p => ({ ...p, [key]: val }));

  return (
    <div className="kb-backdrop" onClick={onClose}>
      <motion.div
        className="kb-modal"
        initial={{ opacity: 0, scale: 0.96, y: 12 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        exit={{ opacity: 0, scale: 0.96, y: 12 }}
        transition={{ duration: 0.18 }}
        onClick={e => e.stopPropagation()}
      >
        <div className="kb-modal-head">
          <div className="kb-modal-ico"><BookOpen size={18} /></div>
          <div>
            <div className="kb-modal-title">{isEdit ? "Modifier l'entrée" : 'Nouvelle entrée'}</div>
            <div className="kb-modal-sub">{isEdit ? 'Mettre à jour la question/réponse' : 'Ajouter à la base de connaissances IA'}</div>
          </div>
          <button className="kb-modal-close" onClick={onClose}><X size={15} /></button>
        </div>

        <div className="kb-modal-body">
          <div className="kb-row2">
            <div className="kb-field">
              <label>Spécialité</label>
              <select value={form.category_id} onChange={e => f('category_id', e.target.value)} className="kb-select">
                <option value="">Générale (toutes)</option>
                {categories.map(c => <option key={c.id} value={c.id}>{c.icon} {c.name}</option>)}
              </select>
            </div>
            <div className="kb-field">
              <label>Langue</label>
              <select value={form.language} onChange={e => f('language', e.target.value)} className="kb-select">
                <option value="fr">🇫🇷 Français</option>
                <option value="ar">🇲🇦 العربية</option>
              </select>
            </div>
          </div>

          <div className="kb-field">
            <label>Question *</label>
            <input
              value={form.question}
              onChange={e => f('question', e.target.value)}
              placeholder="Ex : Quels sont les symptômes de la grippe ?"
              maxLength={500}
            />
          </div>

          <div className="kb-field">
            <label>Réponse *</label>
            <textarea
              rows={6}
              value={form.answer}
              onChange={e => f('answer', e.target.value)}
              placeholder="Réponse informative — pas de diagnostic ni prescription. Recommander une consultation si nécessaire."
            />
          </div>

          <div className="kb-field">
            <label>Mots-clés <span className="kb-field-hint">(séparés par des virgules)</span></label>
            <input
              value={form.keywords}
              onChange={e => f('keywords', e.target.value)}
              placeholder="grippe, fièvre, courbatures"
            />
          </div>

          <div className="kb-field">
            <label>Statut</label>
            <button
              type="button"
              className={`kb-toggle ${form.is_active ? 'kb-toggle--on' : ''}`}
              onClick={() => f('is_active', !form.is_active)}
            >
              {form.is_active
                ? <><ToggleRight size={18} /> Active — utilisée par l'IA</>
                : <><ToggleLeft size={18} /> Inactive — ignorée par l'IA</>}
            </button>
          </div>
        </div>

        <div className="kb-modal-foot">
          <button className="kb-btn-cancel" onClick={onClose} disabled={isPending}>Annuler</button>
          <button
            className="kb-btn-confirm"
            onClick={onSubmit}
            disabled={isPending || !form.question.trim() || !form.answer.trim()}
          >
            {isPending
              ? <><Loader2 size={13} className="kb-spin" /> Enregistrement…</>
              : isEdit
                ? <><CheckCircle size={13} /> Enregistrer</>
                : <><Plus size={13} /> Créer l'entrée</>}
          </button>
        </div>
      </motion.div>
    </div>
  );
}

/* ── Delete confirm modal ── */
function DeleteModal({ entry, onClose, onConfirm, isPending }) {
  return (
    <div className="kb-backdrop" onClick={onClose}>
      <motion.div
        className="kb-modal kb-modal--sm"
        initial={{ opacity: 0, scale: 0.96, y: 12 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        exit={{ opacity: 0, scale: 0.96, y: 12 }}
        transition={{ duration: 0.18 }}
        onClick={e => e.stopPropagation()}
      >
        <div className="kb-modal-head">
          <div className="kb-modal-ico kb-modal-ico--red"><AlertTriangle size={18} /></div>
          <div>
            <div className="kb-modal-title">Supprimer l'entrée</div>
            <div className="kb-modal-sub kb-modal-sub--truncate">{entry.question}</div>
          </div>
          <button className="kb-modal-close" onClick={onClose}><X size={15} /></button>
        </div>
        <div className="kb-modal-body">
          <div className="kb-del-warn">
            <AlertTriangle size={14} />
            <span>Cette entrée sera <strong>définitivement supprimée</strong> de la base de connaissances et ne sera plus utilisée par l'IA.</span>
          </div>
        </div>
        <div className="kb-modal-foot">
          <button className="kb-btn-cancel" onClick={onClose} disabled={isPending}>Annuler</button>
          <button className="kb-btn-del" onClick={onConfirm} disabled={isPending}>
            {isPending
              ? <><Loader2 size={13} className="kb-spin" /> Suppression…</>
              : <><Trash2 size={13} /> Supprimer</>}
          </button>
        </div>
      </motion.div>
    </div>
  );
}

/* ═══════════════════════════════════════════════════ */
export default function AdminKnowledgeBasePage() {
  const [search,     setSearch]     = useState('');
  const [language,   setLanguage]   = useState('');
  const [categoryId, setCategoryId] = useState('');
  const [modal,      setModal]      = useState(null);
  const [deleteTarget, setDeleteTarget] = useState(null);
  const [form,       setForm]       = useState(emptyForm);
  const [editId,     setEditId]     = useState(null);

  const params = {
    ...(search     && { search }),
    ...(language   && { language }),
    ...(categoryId && { category_id: categoryId }),
  };

  const { data, isLoading }     = useAdminKnowledge(params);
  const { data: categoriesRaw } = useAdminCategories();
  const categories = Array.isArray(categoriesRaw) ? categoriesRaw : [];

  const createKB = useCreateKnowledge();
  const updateKB = useUpdateKnowledge();
  const deleteKB = useDeleteKnowledge();

  const entries = useMemo(() => data?.data ?? [], [data]);

  const kpi = useMemo(() => ({
    total: entries.length,
    fr:    entries.filter(e => e.language === 'fr').length,
    ar:    entries.filter(e => e.language === 'ar').length,
  }), [entries]);

  const openCreate = () => { setForm(emptyForm); setModal('create'); };
  const openEdit   = (e)  => { setForm(toForm(e)); setEditId(e.id); setModal('edit'); };
  const closeModal = ()   => { setModal(null); setEditId(null); };

  const handleSubmit = () => {
    const payload = toPayload(form);
    if (modal === 'create') createKB.mutate(payload, { onSuccess: closeModal });
    else updateKB.mutate({ id: editId, ...payload }, { onSuccess: closeModal });
  };

  const handleDelete = () => {
    if (!deleteTarget) return;
    deleteKB.mutate(deleteTarget.id, { onSuccess: () => setDeleteTarget(null) });
  };

  const isPending = createKB.isPending || updateKB.isPending;

  return (
    <div className="kb-page">

      {/* Header */}
      <motion.div className="kb-head"
        initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.25 }}
      >
        <div>
          <h1 className="kb-head-title">Base de connaissances</h1>
          <p className="kb-head-sub">Questions/réponses utilisées par l'IA pour répondre aux patients</p>
        </div>
        <button className="kb-btn-new" onClick={openCreate}>
          <Plus size={15} /> Nouvelle entrée
        </button>
      </motion.div>

      {/* KPIs */}
      <motion.div className="kb-kpis"
        initial={{ opacity: 0, y: -6 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.05, duration: 0.25 }}
      >
        <KpiCard label="Total"    value={kpi.total} color="violet" icon={<BookOpen size={18} />}   isLoading={isLoading} />
        <KpiCard label="Français" value={kpi.fr}    color="blue"   icon={<Languages size={18} />}  isLoading={isLoading} />
        <KpiCard label="Arabe"    value={kpi.ar}    color="teal"   icon={<Languages size={18} />}  isLoading={isLoading} />
      </motion.div>

      {/* Filters */}
      <motion.div className="kb-filters"
        initial={{ opacity: 0, y: -6 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.08, duration: 0.25 }}
      >
        <div className="kb-search-wrap">
          <Search size={13} className="kb-search-ico" />
          <input
            className="kb-search"
            placeholder="Rechercher une question…"
            value={search}
            onChange={e => setSearch(e.target.value)}
          />
        </div>
        <div className="kb-select-wrap">
          <CustomSelect
            value={categoryId}
            onChange={e => setCategoryId(e.target.value)}
            placeholder="Toutes les spécialités"
            options={categories.map(c => ({ value: String(c.id), label: `${c.icon ?? ''} ${c.name}` }))}
          />
        </div>
        <div className="kb-select-wrap">
          <CustomSelect
            value={language}
            onChange={e => setLanguage(e.target.value)}
            placeholder="Toutes les langues"
            options={[
              { value: 'fr', label: '🇫🇷 Français' },
              { value: 'ar', label: '🇲🇦 Arabe' },
            ]}
          />
        </div>
        <span className="kb-result-count">
          {entries.length} entrée{entries.length !== 1 ? 's' : ''}
        </span>
      </motion.div>

      {/* List */}
      {isLoading ? (
        <KbSkeleton count={4} />
      ) : entries.length === 0 ? (
        <div className="kb-empty">
          <BookOpen size={34} className="kb-empty-ico" />
          <p>Aucune entrée trouvée</p>
        </div>
      ) : (
        <div className="kb-list">
          {entries.map((entry, idx) => (
            <EntryCard
              key={entry.id}
              entry={entry}
              idx={idx}
              onEdit={openEdit}
              onDelete={setDeleteTarget}
            />
          ))}
        </div>
      )}

      {/* Create / Edit modal */}
      <AnimatePresence>
        {modal && (
          <EntryModal
            mode={modal}
            form={form}
            setForm={setForm}
            categories={categories}
            onClose={closeModal}
            onSubmit={handleSubmit}
            isPending={isPending}
          />
        )}
      </AnimatePresence>

      {/* Delete confirm modal */}
      <AnimatePresence>
        {deleteTarget && (
          <DeleteModal
            entry={deleteTarget}
            onClose={() => setDeleteTarget(null)}
            onConfirm={handleDelete}
            isPending={deleteKB.isPending}
          />
        )}
      </AnimatePresence>
    </div>
  );
}
