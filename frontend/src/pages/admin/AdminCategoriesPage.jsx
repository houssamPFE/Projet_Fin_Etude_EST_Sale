import { useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Plus, Pencil, Trash2, X, Loader2,
  AlertTriangle, Stethoscope, Users,
  CheckCircle, XCircle, ToggleLeft, ToggleRight,
} from 'lucide-react';
import {
  useAdminCategories, useCreateCategory,
  useUpdateCategory, useDeleteCategory,
} from '../../hooks/useAdmin';
import './AdminCategoriesPage.css';

/* ── Per-index gradient palette ── */
const PALETTES = [
  ['#7c5cff', '#5b6cff'],
  ['#06b6d4', '#0891b2'],
  ['#f43f5e', '#e11d48'],
  ['#f59e0b', '#d97706'],
  ['#ec4899', '#db2777'],
  ['#6366f1', '#4f46e5'],
  ['#3b82f6', '#2563eb'],
  ['#10b981', '#059669'],
];
const gradient = (i) => {
  const [a, b] = PALETTES[i % PALETTES.length];
  return `linear-gradient(135deg, ${a}, ${b})`;
};

const emptyForm = { name: '', icon: '', description: '', sort_order: 0, is_active: true };

/* ── KPI card ── */
function KpiCard({ label, value, color, icon, isLoading }) {
  return (
    <div className={`sp-kpi sp-kpi--${color}`}>
      <div className="sp-kpi-ico">{icon}</div>
      <div>
        <div className="sp-kpi-val">{isLoading ? '…' : value}</div>
        <div className="sp-kpi-lbl">{label}</div>
      </div>
    </div>
  );
}

/* ── Specialty card ── */
function SpecialtyCard({ cat, idx, onEdit, onDelete }) {
  const grad     = gradient(idx);
  const expCount = cat.experts_count ?? 0;
  const maxExp   = 10;

  return (
    <motion.div
      className={`sp-card${!cat.is_active ? ' sp-card--inactive' : ''}`}
      initial={{ opacity: 0, y: 18 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: idx * 0.045, duration: 0.25 }}
      whileHover={{ y: -4 }}
    >
      {/* Gradient band */}
      <div className="sp-band" style={{ background: grad }}>
        <div className="sp-icon-wrap">
          <span className="sp-icon">{cat.icon || '🏥'}</span>
        </div>
        <span className={`sp-badge ${cat.is_active ? 'sp-badge--on' : 'sp-badge--off'}`}>
          {cat.is_active ? 'Actif' : 'Inactif'}
        </span>
      </div>

      {/* Body */}
      <div className="sp-body">
        <h3 className="sp-name">{cat.name}</h3>
        <p className="sp-desc">{cat.description || <span className="sp-no-desc">Aucune description</span>}</p>

        <div className="sp-meta">
          <div className="sp-meta-row">
            <span className="sp-meta-label">
              <Users size={11} />
              {expCount} médecin{expCount !== 1 ? 's' : ''}
            </span>
            <span className="sp-sort-tag">Ordre #{cat.sort_order ?? 0}</span>
          </div>
          <div className="sp-bar-bg">
            <div
              className="sp-bar-fill"
              style={{
                width: `${Math.min((expCount / Math.max(maxExp, expCount || 1)) * 100, 100)}%`,
                background: grad,
              }}
            />
          </div>
        </div>
      </div>

      {/* Footer */}
      <div className="sp-foot">
        <button className="sp-act" title="Modifier" onClick={() => onEdit(cat)}>
          <Pencil size={13} />
        </button>
        <button className="sp-act sp-act--del" title="Supprimer" onClick={() => onDelete(cat)}>
          <Trash2 size={13} />
        </button>
      </div>
    </motion.div>
  );
}

/* ── Create / Edit modal ── */
function CategoryModal({ mode, form, setForm, onClose, onSubmit, isPending }) {
  const isEdit = mode === 'edit';
  return (
    <div className="sp-backdrop" onClick={onClose}>
      <motion.div
        className="sp-modal"
        initial={{ opacity: 0, scale: 0.96, y: 12 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        exit={{ opacity: 0, scale: 0.96, y: 12 }}
        transition={{ duration: 0.18 }}
        onClick={e => e.stopPropagation()}
      >
        <div className="sp-modal-head">
          <div className="sp-modal-ico">
            {form.icon
              ? <span style={{ fontSize: 20, lineHeight: 1 }}>{form.icon}</span>
              : <Stethoscope size={18} />}
          </div>
          <div>
            <div className="sp-modal-title">
              {isEdit ? 'Modifier la spécialité' : 'Nouvelle spécialité'}
            </div>
            <div className="sp-modal-sub">
              {isEdit ? 'Mettre à jour les informations' : 'Ajouter une spécialité médicale'}
            </div>
          </div>
          <button className="sp-modal-close" onClick={onClose}><X size={15} /></button>
        </div>

        <div className="sp-modal-body">
          <div className="sp-row2">
            <div className="sp-field">
              <label>Nom *</label>
              <input
                value={form.name}
                onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
                placeholder="Ex : Cardiologie"
              />
            </div>
            <div className="sp-field">
              <label>Icône (emoji)</label>
              <input
                className="sp-emoji-input"
                value={form.icon}
                onChange={e => setForm(f => ({ ...f, icon: e.target.value }))}
                placeholder="🏥"
                maxLength={8}
              />
            </div>
          </div>

          <div className="sp-field">
            <label>Description</label>
            <textarea
              rows={3}
              value={form.description}
              onChange={e => setForm(f => ({ ...f, description: e.target.value }))}
              placeholder="Description de la spécialité…"
            />
          </div>

          <div className="sp-row2">
            <div className="sp-field">
              <label>Ordre de tri</label>
              <input
                type="number"
                min={0}
                value={form.sort_order}
                onChange={e => setForm(f => ({ ...f, sort_order: +e.target.value }))}
              />
            </div>
            <div className="sp-field">
              <label>Statut</label>
              <button
                type="button"
                className={`sp-toggle ${form.is_active ? 'sp-toggle--on' : ''}`}
                onClick={() => setForm(f => ({ ...f, is_active: !f.is_active }))}
              >
                {form.is_active
                  ? <><ToggleRight size={18} /> Active</>
                  : <><ToggleLeft size={18} /> Inactive</>}
              </button>
            </div>
          </div>
        </div>

        <div className="sp-modal-foot">
          <button className="sp-btn-cancel" onClick={onClose} disabled={isPending}>Annuler</button>
          <button className="sp-btn-confirm" onClick={onSubmit} disabled={isPending || !form.name.trim()}>
            {isPending
              ? <><Loader2 size={13} className="sp-spin" /> Enregistrement…</>
              : isEdit
                ? <><CheckCircle size={13} /> Enregistrer</>
                : <><Plus size={13} /> Créer la spécialité</>}
          </button>
        </div>
      </motion.div>
    </div>
  );
}

/* ── Delete confirm modal ── */
function DeleteModal({ cat, onClose, onConfirm, isPending }) {
  return (
    <div className="sp-backdrop" onClick={onClose}>
      <motion.div
        className="sp-modal sp-modal--sm"
        initial={{ opacity: 0, scale: 0.96, y: 12 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        exit={{ opacity: 0, scale: 0.96, y: 12 }}
        transition={{ duration: 0.18 }}
        onClick={e => e.stopPropagation()}
      >
        <div className="sp-modal-head">
          <div className="sp-modal-ico sp-modal-ico--red"><AlertTriangle size={18} /></div>
          <div>
            <div className="sp-modal-title">Supprimer la spécialité</div>
            <div className="sp-modal-sub">{cat.name}</div>
          </div>
          <button className="sp-modal-close" onClick={onClose}><X size={15} /></button>
        </div>

        <div className="sp-modal-body">
          <div className="sp-del-warn">
            <AlertTriangle size={14} />
            <span>
              Cette action est <strong>irréversible</strong>. Les médecins et conversations liés
              à cette spécialité seront affectés.
            </span>
          </div>
        </div>

        <div className="sp-modal-foot">
          <button className="sp-btn-cancel" onClick={onClose} disabled={isPending}>Annuler</button>
          <button className="sp-btn-del" onClick={onConfirm} disabled={isPending}>
            {isPending
              ? <><Loader2 size={13} className="sp-spin" /> Suppression…</>
              : <><Trash2 size={13} /> Supprimer définitivement</>}
          </button>
        </div>
      </motion.div>
    </div>
  );
}

/* ═══════════════════════════════════════════════════ */
export default function AdminCategoriesPage() {
  const { data: raw, isLoading } = useAdminCategories();
  const categories = Array.isArray(raw) ? raw : [];

  const createCategory = useCreateCategory();
  const updateCategory = useUpdateCategory();
  const deleteCategory = useDeleteCategory();

  const [modal,        setModal]        = useState(null);
  const [deleteTarget, setDeleteTarget] = useState(null);
  const [form,         setForm]         = useState(emptyForm);
  const [editId,       setEditId]       = useState(null);

  const kpi = useMemo(() => ({
    total:    categories.length,
    active:   categories.filter(c => c.is_active).length,
    inactive: categories.filter(c => !c.is_active).length,
  }), [categories]);

  const openCreate = () => { setForm(emptyForm); setModal('create'); };
  const openEdit   = (cat) => {
    setForm({
      name: cat.name, icon: cat.icon ?? '',
      description: cat.description ?? '',
      sort_order: cat.sort_order ?? 0,
      is_active: cat.is_active,
    });
    setEditId(cat.id);
    setModal('edit');
  };
  const closeModal = () => { setModal(null); setEditId(null); };

  const handleSubmit = () => {
    if (modal === 'create') {
      createCategory.mutate(form, { onSuccess: closeModal });
    } else {
      updateCategory.mutate({ id: editId, ...form }, { onSuccess: closeModal });
    }
  };

  const handleDelete = () => {
    if (!deleteTarget) return;
    deleteCategory.mutate(deleteTarget.id, { onSuccess: () => setDeleteTarget(null) });
  };

  const isPending = createCategory.isPending || updateCategory.isPending;

  return (
    <div className="sp-page">

      {/* Header */}
      <motion.div className="sp-head"
        initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.25 }}
      >
        <div>
          <h1 className="sp-head-title">Spécialités médicales</h1>
          <p className="sp-head-sub">Gérez les spécialités disponibles sur la plateforme</p>
        </div>
        <button className="sp-btn-new" onClick={openCreate}>
          <Plus size={15} /> Nouvelle spécialité
        </button>
      </motion.div>

      {/* KPIs */}
      <motion.div className="sp-kpis"
        initial={{ opacity: 0, y: -6 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.05, duration: 0.25 }}
      >
        <KpiCard label="Total"     value={kpi.total}    color="violet" icon={<Stethoscope size={18} />} isLoading={isLoading} />
        <KpiCard label="Actives"   value={kpi.active}   color="green"  icon={<CheckCircle size={18} />} isLoading={isLoading} />
        <KpiCard label="Inactives" value={kpi.inactive} color="red"    icon={<XCircle size={18} />}     isLoading={isLoading} />
      </motion.div>

      {/* Grid */}
      {isLoading ? (
        <div className="sp-loading"><Loader2 size={26} className="sp-spin" /></div>
      ) : categories.length === 0 ? (
        <div className="sp-empty">
          <Stethoscope size={34} className="sp-empty-ico" />
          <p>Aucune spécialité trouvée</p>
        </div>
      ) : (
        <div className="sp-grid">
          {categories.map((cat, idx) => (
            <SpecialtyCard
              key={cat.id}
              cat={cat}
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
          <CategoryModal
            mode={modal}
            form={form}
            setForm={setForm}
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
            cat={deleteTarget}
            onClose={() => setDeleteTarget(null)}
            onConfirm={handleDelete}
            isPending={deleteCategory.isPending}
          />
        )}
      </AnimatePresence>
    </div>
  );
}
