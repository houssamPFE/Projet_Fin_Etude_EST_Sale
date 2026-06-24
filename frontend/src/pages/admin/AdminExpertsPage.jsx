import { useState, useMemo } from 'react';
import { motion } from 'framer-motion';
import {
  Search, ChevronUp, ChevronDown, ChevronsUpDown,
  FileText, X, Download, Eye, ShieldCheck, Clock,
  FileX, Loader2, Star, UserCheck, UserX, CheckCircle, XCircle,
  BadgeCheck, Wifi, Ban, AlertTriangle,
} from 'lucide-react';
import api from '../../lib/api';
import CustomSelect from '../../components/CustomSelect';
import { useAdminExperts, useToggleExpert, useAdminCategories } from '../../hooks/useAdmin';
import { TableSkeleton } from '../../components/AdminSkeleton';
import './AdminExpertsPage.css';

const AVATAR_COLORS = ['#2563eb', '#7c3aed', '#0d9488', '#ea580c', '#16a34a', '#dc2626', '#ca8a04'];

function ExpertAvatar({ name, avatarUrl, size = 34 }) {
  const [imgFailed, setImgFailed] = useState(false);
  const initials = name?.trim().split(/\s+/).map(n => n[0]).join('').slice(0, 2).toUpperCase() || '?';
  const bg = AVATAR_COLORS[(name?.charCodeAt(0) ?? 0) % AVATAR_COLORS.length];
  if (avatarUrl && !imgFailed) {
    return <img src={avatarUrl} alt={name} className="u-avatar" style={{ width: size, height: size }} onError={() => setImgFailed(true)} />;
  }
  return (
    <div className="u-avatar u-avatar--initials" style={{ width: size, height: size, background: bg, fontSize: size * 0.36 }}>
      {initials}
    </div>
  );
}

function SortIcon({ col, sortBy, sortDir }) {
  if (sortBy !== col) return <ChevronsUpDown size={11} className="sort-icon sort-icon--off" />;
  return sortDir === 'asc'
    ? <ChevronUp size={11} className="sort-icon sort-icon--on" />
    : <ChevronDown size={11} className="sort-icon sort-icon--on" />;
}

function StarRating({ value }) {
  const v = parseFloat(value) || 0;
  return (
    <div className="star-rating">
      <Star size={12} className={v > 0 ? 'star--on' : 'star--off'} fill={v > 0 ? 'currentColor' : 'none'} />
      <span>{v > 0 ? v.toFixed(1) : '--'}</span>
    </div>
  );
}

function KpiCard({ label, value, color, icon: Icon, isLoading }) {
  return (
    <div className={`u-kpi-card u-kpi-card--${color}`}>
      <div className={`u-kpi-icon-circle u-kpi-icon-circle--${color}`}>
        <Icon size={18} />
      </div>
      <div className="u-kpi-info">
        <div className="u-kpi-label">{label}</div>
        <div className="u-kpi-value">
          {isLoading ? <span className="sk-block" style={{ width: 36, height: 24 }} /> : (value ?? 0)}
        </div>
      </div>
    </div>
  );
}

// ── Document modals (reused from existing page) ──────────────────
const DOC_TYPE_LABELS = { diploma: 'Diplome', id_card: 'Carte identite', certificate: 'Certificat', other: 'Autre' };
const DOC_TYPE_COLORS = { diploma: 'doc-type--diploma', id_card: 'doc-type--id', certificate: 'doc-type--cert', other: 'doc-type--other' };

function PreviewModal({ doc, onClose }) {
  const [blobUrl, setBlobUrl] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError]     = useState(false);

  useState(() => {
    let objectUrl;
    const path = doc.stream_url.replace(/^.*\/api\/v1\//, '');
    api.get(path, { responseType: 'blob' })
      .then((res) => { objectUrl = URL.createObjectURL(res.data); setBlobUrl(objectUrl); })
      .catch(() => setError(true))
      .finally(() => setLoading(false));
    return () => { if (objectUrl) URL.revokeObjectURL(objectUrl); };
  }, [doc.stream_url]);

  const handleDownload = () => {
    if (!blobUrl) return;
    const a = document.createElement('a');
    a.href = blobUrl; a.download = doc.original_name; a.click();
  };

  return (
    <div className="docs-overlay" onClick={onClose}>
      <div className="preview-modal" onClick={e => e.stopPropagation()}>
        <div className="preview-modal-header">
          <span className="preview-modal-name"><FileText size={15} /> {doc.original_name}</span>
          <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
            <button className="doc-btn doc-btn--download" onClick={handleDownload} disabled={!blobUrl}><Download size={13} /> Telecharger</button>
            <button className="docs-close" onClick={onClose}><X size={18} /></button>
          </div>
        </div>
        <div className="preview-modal-body">
          {loading && <div className="preview-loading"><Loader2 size={28} className="spin" /><span>Chargement...</span></div>}
          {error   && <div className="preview-loading" style={{ color: '#ef4444' }}>Impossible de charger le document.</div>}
          {blobUrl && <iframe src={blobUrl} title={doc.original_name} className="preview-iframe" />}
        </div>
      </div>
    </div>
  );
}

async function downloadDoc(doc) {
  const path = doc.stream_url.replace(/^.*\/api\/v1\//, '');
  const res = await api.get(`${path}?download=1`, { responseType: 'blob' });
  const url = URL.createObjectURL(res.data);
  const a = document.createElement('a'); a.href = url; a.download = doc.original_name; a.click();
  URL.revokeObjectURL(url);
}

function DocumentsModal({ expert, onClose }) {
  const docs = expert.documents ?? [];
  const [previewDoc, setPreviewDoc] = useState(null);
  if (previewDoc) return <PreviewModal doc={previewDoc} onClose={() => setPreviewDoc(null)} />;
  return (
    <div className="docs-overlay" onClick={onClose}>
      <div className="docs-modal" onClick={e => e.stopPropagation()}>
        <div className="docs-modal-header">
          <div className="docs-modal-title"><FileText size={18} /><div><h2>Documents justificatifs</h2><p>{expert.user?.name} · {expert.category?.name}</p></div></div>
          <button className="docs-close" onClick={onClose}><X size={18} /></button>
        </div>
        <div className={`docs-status-bar docs-status-bar--${expert.status}`}>
          {expert.status === 'pending'   && <><Clock size={14} /> Candidature en attente</>}
          {expert.status === 'validated' && <><ShieldCheck size={14} /> Medecin valide</>}
          {expert.status === 'rejected'  && <><FileX size={14} /> Candidature rejetee</>}
        </div>
        <div className="docs-list">
          {docs.length === 0 ? (
            <div className="docs-empty"><FileText size={36} style={{ opacity: 0.2 }} /><p>Aucun document soumis.</p></div>
          ) : docs.map(doc => (
            <div key={doc.id} className="doc-item">
              <div className="doc-item-left">
                <div className="doc-icon"><FileText size={20} /></div>
                <div className="doc-info">
                  <span className="doc-name">{doc.original_name}</span>
                  <div className="doc-meta">
                    <span className={`doc-type-badge ${DOC_TYPE_COLORS[doc.type] ?? 'doc-type--other'}`}>{DOC_TYPE_LABELS[doc.type] ?? doc.type}</span>
                    <span className={`doc-verified ${doc.verified ? 'doc-verified--yes' : 'doc-verified--no'}`}>
                      {doc.verified ? <><ShieldCheck size={11} /> Verifie</> : 'Non verifie'}
                    </span>
                  </div>
                </div>
              </div>
              <div className="doc-item-actions">
                <button className="doc-btn doc-btn--view" onClick={() => setPreviewDoc(doc)}><Eye size={14} /> Voir</button>
                <button className="doc-btn doc-btn--download" onClick={() => downloadDoc(doc)}><Download size={14} /> Telecharger</button>
              </div>
            </div>
          ))}
        </div>
        <div className="docs-modal-footer">
          <span className="docs-count">{docs.length} document{docs.length !== 1 ? 's' : ''}</span>
          <button className="docs-btn-close" onClick={onClose}>Fermer</button>
        </div>
      </div>
    </div>
  );
}

export default function AdminExpertsPage() {
  const [search, setSearch]       = useState('');
  const [status, setStatus]       = useState('validated');
  const [categoryId, setCategoryId] = useState('');
  const [sortBy, setSortBy]       = useState('created_at');
  const [sortDir, setSortDir]     = useState('desc');
  const [page, setPage]           = useState(1);
  const [docsExpert, setDocsExpert] = useState(null);
  const [toggleConfirmExpert, setToggleConfirmExpert] = useState(null);

  const { data, isLoading } = useAdminExperts({ search, status, category_id: categoryId || undefined, exclude_pending: 1, page });
  const { data: categoriesRaw } = useAdminCategories();
  const categories = Array.isArray(categoriesRaw) ? categoriesRaw : [];
  const toggleExpert = useToggleExpert();

  const handleToggleAvailability = () => {
    if (!toggleConfirmExpert) return;
    toggleExpert.mutate(toggleConfirmExpert.id, {
      onSuccess: () => setToggleConfirmExpert(null),
    });
  };


  const meta   = data?.meta  ?? {};
  const stats  = data?.stats ?? { pending: 0, validated: 0, rejected: 0 };

  const experts = useMemo(() => {
    const raw = Array.isArray(data?.data) ? data.data : (data?.data?.data ?? []);
    return [...raw].sort((a, b) => {
      let valA, valB;
      if (sortBy === 'name')        { valA = a.user?.name ?? ''; valB = b.user?.name ?? ''; }
      else if (sortBy === 'rating') { valA = parseFloat(a.rating_avg) || 0; valB = parseFloat(b.rating_avg) || 0; }
      else                          { valA = a[sortBy] ?? ''; valB = b[sortBy] ?? ''; }
      const cmp = String(valA).localeCompare(String(valB), 'fr', { sensitivity: 'base' });
      return sortDir === 'asc' ? cmp : -cmp;
    });
  }, [data, sortBy, sortDir]);

  const toggleSort = (col) => {
    if (sortBy === col) setSortDir(d => d === 'asc' ? 'desc' : 'asc');
    else { setSortBy(col); setSortDir('asc'); }
    setPage(1);
  };

  const available = experts.filter(e => e.is_available && e.status === 'validated').length;

  return (
    <div className="admin-experts-v2">
      <motion.div className="page-header-row" initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.3 }}>
        <div>
          <h1>Gestion des medecins</h1>
          <p className="page-subtitle">{stats.validated + stats.rejected} medecins enregistres</p>
        </div>
      </motion.div>

      <motion.div className="u-kpi-row" initial={{ opacity: 0, y: -6 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.05, duration: 0.25 }}>
        <KpiCard label="Validés"     value={stats.validated} color="green" icon={BadgeCheck} isLoading={isLoading} />
        <KpiCard label="Disponibles" value={available}       color="blue"  icon={Wifi}       isLoading={isLoading} />
        <KpiCard label="Rejetés"     value={stats.rejected}  color="red"   icon={Ban}        isLoading={isLoading} />
      </motion.div>

      <motion.div className="filters-bar" initial={{ opacity: 0, y: -6 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.1, duration: 0.25 }}>
        <div className="search-box">
          <Search size={15} color="#94a3b8" />
          <input placeholder="Rechercher par nom ou email..." value={search} onChange={e => { setSearch(e.target.value); setPage(1); }} />
        </div>
        <div className="filter-divider" />
        <div className="filter-select-wrap">
          <CustomSelect value={status} onChange={e => { setStatus(e.target.value); setPage(1); }} placeholder="Tous les statuts"
            options={[{ value: '', label: 'Tous les statuts' }, { value: 'validated', label: 'Valide' }, { value: 'rejected', label: 'Rejete' }]} />
        </div>
        <div className="filter-select-wrap">
          <CustomSelect value={categoryId} onChange={e => { setCategoryId(e.target.value); setPage(1); }} placeholder="Toutes les specialites"
            options={[{ value: '', label: 'Toutes les specialites' }, ...categories.map(c => ({ value: String(c.id), label: c.name }))]} />
        </div>
        <span className="results-count">{meta.total ?? experts.length} resultats</span>
      </motion.div>

      {isLoading ? (
        <TableSkeleton rows={6} cols={8} />
      ) : experts.length === 0 ? (
        <div className="table-empty">Aucun medecin trouve.</div>
      ) : (
        <>
          <div className="table-wrap">
            <table className="data-table">
              <thead>
                <tr>
                  <th style={{ width: 40 }}>#</th>
                  <th className="th-sort" onClick={() => toggleSort('name')}><span className="th-label">Medecin <SortIcon col="name" sortBy={sortBy} sortDir={sortDir} /></span></th>
                  <th>Specialite</th>
                  <th className="th-sort" onClick={() => toggleSort('rating')}><span className="th-label">Note <SortIcon col="rating" sortBy={sortBy} sortDir={sortDir} /></span></th>
                  <th>Statut</th>
                  <th>Disponibilite</th>
                  <th>Documents</th>
                  <th style={{ width: 80 }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {experts.map((expert, i) => (
                  <motion.tr key={expert.id} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.03, duration: 0.2 }}>
                    <td className="cell-id">{expert.id}</td>
                    <td>
                      <div className="cell-name-wrap">
                        <ExpertAvatar name={expert.user?.name} avatarUrl={expert.user?.avatar_url} />
                        <div className="cell-name-info">
                          <span className="cell-name">{expert.user?.name}</span>
                          <span className="cell-sub">{expert.user?.email}</span>
                        </div>
                      </div>
                    </td>
                    <td><span className="specialty-tag">{expert.category?.name ?? '--'}</span></td>
                    <td><StarRating value={expert.rating_avg} /></td>
                    <td>
                      <span className={`status-dot-wrap status-dot-wrap--${expert.status === 'validated' ? 'validated' : 'rejected'}`}>
                        <span className="status-dot" />
                        {expert.status === 'validated' ? 'Valide' : 'Rejete'}
                      </span>
                    </td>
                    <td>
                      {expert.status === 'validated' ? (
                        <span className={`status-dot-wrap status-dot-wrap--${expert.is_available ? 'available' : 'unavailable'}`}>
                          <span className="status-dot" />
                          {expert.is_available ? 'Disponible' : 'Indisponible'}
                        </span>
                      ) : <span className="cell-muted">--</span>}
                    </td>
                    <td>
                      <button className="doc-count-btn" onClick={() => setDocsExpert(expert)}>
                        <FileText size={13} /> {expert.documents?.length ?? 0} doc{(expert.documents?.length ?? 0) !== 1 ? 's' : ''}
                      </button>
                    </td>
                    <td>
                      <div className="cell-actions">
                        {expert.status === 'validated' && (
                          <button
                            className={`icon-action ${expert.is_available ? 'icon-action--danger' : 'icon-action--success'}`}
                            title={expert.is_available ? 'Rendre indisponible' : 'Rendre disponible'}
                            onClick={() => setToggleConfirmExpert(expert)}
                            disabled={toggleExpert.isPending}
                          >
                            {expert.is_available ? <UserX size={14} /> : <UserCheck size={14} />}
                          </button>
                        )}
                      </div>
                    </td>
                  </motion.tr>
                ))}
              </tbody>
            </table>
          </div>

          {meta.last_page > 1 && (
            <div className="pagination">
              <button disabled={page <= 1} onClick={() => setPage(p => p - 1)}>Prec.</button>
              {Array.from({ length: meta.last_page }, (_, i) => i + 1)
                .filter(p => p === 1 || p === meta.last_page || Math.abs(p - page) <= 1)
                .reduce((acc, p, idx, arr) => { if (idx > 0 && p - arr[idx - 1] > 1) acc.push('...'); acc.push(p); return acc; }, [])
                .map((p, i) => p === '...'
                  ? <span key={`e-${i}`} className="pagination-ellipsis">...</span>
                  : <button key={p} className={p === page ? 'active' : ''} onClick={() => setPage(p)}>{p}</button>
                )}
              <button disabled={page >= meta.last_page} onClick={() => setPage(p => p + 1)}>Suiv.</button>
            </div>
          )}
        </>
      )}

      {docsExpert && <DocumentsModal expert={docsExpert} onClose={() => setDocsExpert(null)} />}

      {toggleConfirmExpert && (
        <div className="modal-overlay" onClick={() => setToggleConfirmExpert(null)}>
          <motion.div className="modal-box modal-box--sm" onClick={e => e.stopPropagation()} initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} transition={{ duration: 0.15 }}>
            <div className="modal-header">
              <div className="modal-header-left">
                <div className="confirm-icon-wrap"><AlertTriangle size={20} color="#f59e0b" /></div>
                <div>
                  <div className="modal-title">Modifier la disponibilité</div>
                  <div className="modal-subtitle">{toggleConfirmExpert.user?.name}</div>
                </div>
              </div>
              <button className="modal-close" onClick={() => setToggleConfirmExpert(null)}><X size={16} /></button>
            </div>
            <div className="modal-body">
              <p className="confirm-text">
                Voulez-vous vraiment changer la disponibilité de ce médecin ?
                {toggleConfirmExpert.is_available
                  ? " Le médecin passera en statut 'Indisponible' et ne sera plus visible pour de nouvelles consultations."
                  : " Le médecin passera en statut 'Disponible' et sera visible pour les patients."}
              </p>
            </div>
            <div className="modal-footer">
              <button className="btn-ghost" onClick={() => setToggleConfirmExpert(null)}>Annuler</button>
              <button
                className={`btn-${toggleConfirmExpert.is_available ? 'danger' : 'success'}`}
                onClick={handleToggleAvailability}
                disabled={toggleExpert.isPending}
              >
                {toggleConfirmExpert.is_available ? <UserX size={14} /> : <UserCheck size={14} />}
                Confirmer
              </button>
            </div>
          </motion.div>
        </div>
      )}
    </div>
  );
}
