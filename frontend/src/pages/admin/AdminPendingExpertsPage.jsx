import { useState, useMemo, useEffect, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Search, FileText, X, Download, Eye, ShieldCheck,
  Clock, Loader2, CheckCircle, XCircle, AlertTriangle,
  BadgeCheck,
} from 'lucide-react';
import api from '../../lib/api';
import CustomSelect from '../../components/CustomSelect';
import { useAdminPendingExperts, useValidateExpert, useRejectExpert, useAdminCategories } from '../../hooks/useAdmin';
import { TableSkeleton } from '../../components/AdminSkeleton';
import './AdminExpertsPage.css';

const AVATAR_COLORS = ['#2563eb', '#7c3aed', '#0d9488', '#ea580c', '#16a34a', '#dc2626', '#ca8a04'];

function avatarBg(name) {
  return AVATAR_COLORS[(name?.charCodeAt(0) ?? 0) % AVATAR_COLORS.length];
}

function ExpertAvatar({ name, avatarUrl, size = 34 }) {
  const [fail, setFail] = useState(false);
  const initials = name?.trim().split(/\s+/).map(n => n[0]).join('').slice(0, 2).toUpperCase() || '?';
  if (avatarUrl && !fail)
    return <img src={avatarUrl} alt={name} className="q-avatar" style={{ width: size, height: size }} onError={() => setFail(true)} />;
  return (
    <div className="q-avatar q-avatar--init" style={{ width: size, height: size, background: avatarBg(name), fontSize: size * 0.36 }}>
      {initials}
    </div>
  );
}

/* ── Status pill ── */
function StatusPill({ status }) {
  if (status === 'pending')   return <span className="q-pill q-pill--amber"><span className="q-pill-dot" />En attente</span>;
  if (status === 'rejected')  return <span className="q-pill q-pill--rose"><span className="q-pill-dot" />Rejeté</span>;
  if (status === 'validated') return <span className="q-pill q-pill--green"><span className="q-pill-dot" />Approuvé</span>;
  return null;
}

/* ── Time since ── */
function timeSince(iso) {
  const diff = Date.now() - new Date(iso).getTime();
  const h = Math.floor(diff / 3600000);
  if (h < 1) return 'il y a < 1h';
  if (h < 24) return `il y a ${h}h`;
  const d = Math.floor(h / 24);
  return `il y a ${d}j`;
}

/* ─────────── Document preview modal ─────────── */
function PreviewModal({ doc, onClose }) {
  const [blobUrl, setBlobUrl] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);

  useEffect(() => {
    let objectUrl;
    const path = doc.stream_url.replace(/^.*\/api\/v1\//, '');
    api.get(path, { responseType: 'blob' })
      .then(res => { objectUrl = URL.createObjectURL(res.data); setBlobUrl(objectUrl); })
      .catch(() => setError(true))
      .finally(() => setLoading(false));
    return () => { if (objectUrl) URL.revokeObjectURL(objectUrl); };
  }, [doc.stream_url]);

  const handleDownload = () => {
    if (!blobUrl) return;
    const a = document.createElement('a'); a.href = blobUrl; a.download = doc.original_name; a.click();
  };

  return (
    <div className="docs-overlay" onClick={onClose}>
      <div className="preview-modal" onClick={e => e.stopPropagation()}>
        <div className="preview-modal-header">
          <span className="preview-modal-name"><FileText size={15} /> {doc.original_name}</span>
          <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
            <button className="doc-btn doc-btn--download" onClick={handleDownload} disabled={!blobUrl}><Download size={13} /> Télécharger</button>
            <button className="docs-close" onClick={onClose}><X size={18} /></button>
          </div>
        </div>
        <div className="preview-modal-body">
          {loading && <div className="preview-loading"><Loader2 size={28} className="spin" /><span>Chargement...</span></div>}
          {error && <div className="preview-loading" style={{ color: '#ef4444' }}>Impossible de charger le document.</div>}
          {blobUrl && <iframe src={blobUrl} title={doc.original_name} className="preview-iframe" />}
        </div>
      </div>
    </div>
  );
}

/* ─────────── Detail Drawer ─────────── */
const DOC_TYPE_LABELS = { diploma: 'Diplôme', id_card: 'Carte identité', certificate: 'Certificat', other: 'Autre' };

function DetailDrawer({ expert, onClose, onValidate, onReject, validating }) {
  const [previewDoc, setPreviewDoc] = useState(null);

  useEffect(() => {
    const onKey = e => { if (e.key === 'Escape') onClose(); };
    document.addEventListener('keydown', onKey);
    return () => document.removeEventListener('keydown', onKey);
  }, [onClose]);

  if (previewDoc) return <PreviewModal doc={previewDoc} onClose={() => setPreviewDoc(null)} />;

  const docs = expert.documents ?? [];
  const isRejected = expert.status === 'rejected';
  const isPending  = expert.status === 'pending';

  return (
    <>
      <motion.div
        className="drawer-backdrop"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        transition={{ duration: 0.2 }}
        onClick={onClose}
      />
      <motion.div
        className="drawer"
        initial={{ x: '100%' }}
        animate={{ x: 0 }}
        exit={{ x: '100%' }}
        transition={{ duration: 0.28, ease: [0.4, 0, 0.2, 1] }}
      >
        <div className="drawer-head">
          <div className="drawer-head-title">
            Détails de la candidature
          </div>
          <button className="drawer-close" onClick={onClose}><X size={16} /></button>
        </div>

        <div className="drawer-body">
          {/* Profile */}
          <div className="drawer-profile">
            <ExpertAvatar name={expert.user?.name} avatarUrl={expert.user?.avatar_url} size={56} />
            <div>
              <div className="drawer-profile-name">{expert.user?.name}</div>
              <div className="drawer-profile-email">{expert.user?.email}</div>
              <div className="drawer-profile-chips">
                <span className="q-spec-chip">{expert.category?.name ?? '--'}</span>
                <StatusPill status={expert.status} />
              </div>
            </div>
          </div>

          {/* Rejection reason */}
          {isRejected && (
            <div className="drawer-section">
              <div className="drawer-rejection-callout">
                <div className="drawer-rejection-eyebrow">Documents incomplets</div>
                <div className="drawer-rejection-text">
                  {expert.rejection_reason ?? 'Aucune raison précisée.'}
                </div>
                <div className="drawer-rejection-meta">
                  Rejeté · {expert.updated_at ? new Date(expert.updated_at).toLocaleDateString('fr-FR') : '--'}
                </div>
              </div>
            </div>
          )}

          {/* Professional info */}
          <div className="drawer-section">
            <h3 className="drawer-section-title">Informations professionnelles</h3>
            <div className="drawer-info-grid">
              <div><div className="drawer-info-lab">Spécialité</div><div className="drawer-info-val">{expert.category?.name ?? '--'}</div></div>
              <div><div className="drawer-info-lab">Téléphone</div><div className="drawer-info-val drawer-info-val--mono">{expert.user?.phone ?? '--'}</div></div>
              <div><div className="drawer-info-lab">Ville</div><div className="drawer-info-val">{expert.city ?? '--'}</div></div>
              <div><div className="drawer-info-lab">Soumis le</div><div className="drawer-info-val drawer-info-val--mono">{new Date(expert.created_at).toLocaleDateString('fr-FR')}</div></div>
              <div><div className="drawer-info-lab">Délai d'attente</div><div className="drawer-info-val drawer-info-val--mono">{timeSince(expert.created_at)}</div></div>
            </div>
          </div>

          {/* Documents */}
          <div className="drawer-section">
            <h3 className="drawer-section-title">Documents soumis</h3>
            {docs.length === 0 ? (
              <div className="drawer-docs-empty"><FileText size={24} style={{ opacity: 0.2 }} /><span>Aucun document soumis.</span></div>
            ) : (
              <div className="drawer-docs-grid">
                {docs.map(doc => (
                  <div key={doc.id} className="drawer-doc-card" onClick={() => setPreviewDoc(doc)}>
                    <div className="drawer-doc-thumb">
                      <FileText size={22} style={{ color: '#9ea3bd' }} />
                      <div className={`drawer-doc-scan-dot drawer-doc-scan-dot--${doc.verified ? 'ok' : 'pending'}`} />
                    </div>
                    <div className="drawer-doc-name">{doc.original_name}</div>
                    <div className="drawer-doc-meta">{DOC_TYPE_LABELS[doc.type] ?? doc.type}</div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        <div className="drawer-foot">
          {isPending && (
            <button className="drawer-foot-btn drawer-foot-btn--reject" onClick={onReject}>
              <XCircle size={14} /> Rejeter
            </button>
          )}
          <button
            className="drawer-foot-btn drawer-foot-btn--approve"
            onClick={onValidate}
            disabled={validating}
          >
            <BadgeCheck size={14} /> {isRejected ? 'Re-valider' : 'Approuver'}
          </button>
        </div>
      </motion.div>
    </>
  );
}

/* ─────────── Pipeline card ─────────── */
function PipelineCard({ experts }) {
  const bySpec = useMemo(() => {
    const map = {};
    experts.forEach(e => {
      const name = e.category?.name ?? 'Autre';
      if (!map[name]) map[name] = { pending: 0, approved: 0, rejected: 0 };
      if (e.status === 'pending')   map[name].pending++;
      if (e.status === 'validated') map[name].approved++;
      if (e.status === 'rejected')  map[name].rejected++;
    });
    return Object.entries(map)
      .map(([name, v]) => ({ name, ...v, total: v.pending + v.approved + v.rejected }))
      .sort((a, b) => b.total - a.total)
      .slice(0, 5);
  }, [experts]);

  const SPEC_COLORS = ['#7c5cff','#14b8a6','#f59e0b','#ef4444','#10b981'];

  return (
    <div className="q-card">
      <div className="q-card-head">
        <h3>Pipeline par spécialité</h3>
      </div>
      <div className="q-card-body">
        {bySpec.length === 0 ? (
          <div className="pipeline-empty">Aucune donnée disponible.</div>
        ) : bySpec.map((row, i) => {
          const max = row.total || 1;
          return (
            <div key={row.name} className="pipe-row">
              <div className="pipe-name">
                <div className="pipe-dot" style={{ background: SPEC_COLORS[i % SPEC_COLORS.length] }} />
                {row.name}
              </div>
              <div className="pipe-bar">
                {row.pending  > 0 && <span className="pipe-seg pipe-seg--amber" style={{ flex: row.pending / max }} />}
                {row.approved > 0 && <span className="pipe-seg pipe-seg--green" style={{ flex: row.approved / max }} />}
                {row.rejected > 0 && <span className="pipe-seg pipe-seg--rose"  style={{ flex: row.rejected / max }} />}
              </div>
              <div className="pipe-count">{row.total}</div>
            </div>
          );
        })}
        <div className="pipe-foot">
          <span className="pipe-leg"><span className="pipe-sw pipe-sw--amber" />En attente</span>
          <span className="pipe-leg"><span className="pipe-sw pipe-sw--green" />Approuvés</span>
          <span className="pipe-leg"><span className="pipe-sw pipe-sw--rose"  />Rejetés</span>
        </div>
      </div>
    </div>
  );
}

/* ─────────── SLA card ─────────── */
function SlaCard({ experts }) {
  const oldest = useMemo(() => {
    const pending = experts.filter(e => e.status === 'pending');
    if (!pending.length) return null;
    return pending.reduce((a, b) => new Date(a.created_at) < new Date(b.created_at) ? a : b);
  }, [experts]);

  const waitHours = oldest
    ? Math.round((new Date().getTime() - new Date(oldest.created_at).getTime()) / 3600000)
    : 0;

  const inTime = waitHours < 24;

  return (
    <div className="q-sla-card">
      <div className="q-sla-top">
        <div className="q-sla-ico"><Clock size={18} /></div>
        <div>
          <div className="q-sla-lab">Plus ancienne en attente</div>
          <div className="q-sla-val">{oldest ? `${waitHours} h` : '—'}</div>
        </div>
      </div>
      <div className="q-sla-sub">
        Cible &lt; 24 h ·{' '}
        <span style={{ color: inTime ? '#10b981' : '#ef4444', fontWeight: 600 }}>
          {inTime ? 'vous êtes dans les temps' : 'délai dépassé'}
        </span>.
        {!inTime && oldest && (
          <> La candidature de <b>{oldest.user?.name}</b> dépasse le seuil.</>
        )}
      </div>
    </div>
  );
}

/* ─────────── Main page ─────────── */
export default function AdminPendingExpertsPage() {
  const [search, setSearch]       = useState('');
  const [categoryId, setCategoryId] = useState('');
  const [statusTab, setStatusTab] = useState('all');
  const [drawerExpert, setDrawerExpert] = useState(null);
  const [rejectModal, setRejectModal]   = useState(null);
  const [rejectReason, setRejectReason] = useState('');

  const { data, isLoading } = useAdminPendingExperts();
  const { data: categoriesRaw } = useAdminCategories();
  const validateExpert = useValidateExpert();
  const rejectExpert   = useRejectExpert();

  const allExperts = useMemo(() => data?.all ?? [], [data]);
  const categories = Array.isArray(categoriesRaw) ? categoriesRaw : [];

  const pendingCount  = allExperts.filter(e => e.status === 'pending').length;
  const approvedCount = allExperts.filter(e => e.status === 'validated').length;
  const rejectedCount = allExperts.filter(e => e.status === 'rejected').length;

  const avgDelay = useMemo(() => {
    const validated = allExperts.filter(e => e.status === 'validated' && e.validated_at);
    if (!validated.length) return null;
    const avg = validated.reduce((sum, e) => {
      return sum + (new Date(e.validated_at) - new Date(e.created_at));
    }, 0) / validated.length;
    return Math.round(avg / 3600000);
  }, [allExperts]);

  const experts = useMemo(() => {
    const statusMap = { all: null, pending: 'pending', rejected: 'rejected', approved: 'validated' };
    const filterStatus = statusMap[statusTab];
    return allExperts.filter(e => {
      const matchStatus = !filterStatus || e.status === filterStatus;
      const matchSearch = !search ||
        e.user?.name?.toLowerCase().includes(search.toLowerCase()) ||
        e.user?.email?.toLowerCase().includes(search.toLowerCase());
      const matchCat = !categoryId || String(e.category?.id) === categoryId;
      return matchStatus && matchSearch && matchCat;
    });
  }, [allExperts, statusTab, search, categoryId]);

  const handleReject = () => {
    if (!rejectModal) return;
    rejectExpert.mutate({ id: rejectModal.id, reason: rejectReason }, {
      onSuccess: () => { setRejectModal(null); setRejectReason(''); setDrawerExpert(null); },
    });
  };

  const handleValidate = useCallback((expert) => {
    validateExpert.mutate(expert.id, {
      onSuccess: () => setDrawerExpert(null),
    });
  }, [validateExpert]);

  const openReject = useCallback((expert) => {
    setRejectModal(expert);
    setRejectReason('');
  }, []);

  const TABS = [
    { key: 'all',      label: 'Tous',        count: allExperts.length },
    { key: 'pending',  label: 'En attente',  count: pendingCount  },
    { key: 'rejected', label: 'Rejetés',     count: rejectedCount },
    { key: 'approved', label: 'Approuvés',   count: approvedCount },
  ];

  return (
    <div className="admin-experts-v2 queue-page">

      {/* Page header */}
      <motion.div className="queue-page-head" initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.3 }}>
        <div className="queue-page-head-left">
          <div className="queue-title-row">
            <h1>Candidatures en attente</h1>
            {pendingCount > 0 && (
              <span className="live-pill">
                <span className="live-dot" />
                {pendingCount} à examiner
              </span>
            )}
          </div>
          <p className="queue-page-sub">Validez l'inscription des médecins — vérifiez documents et spécialité</p>
        </div>
      </motion.div>

      {/* 4 KPI strip */}
      <motion.div className="queue-kpis" initial={{ opacity: 0, y: -6 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.05, duration: 0.25 }}>
        <div className="queue-kpi">
          <div className="queue-kpi-ico queue-kpi-ico--amber"><Clock size={16} /></div>
          <div className="queue-kpi-body">
            <div className="queue-kpi-value">
              {isLoading ? <span className="sk-block" style={{ width: 28, height: 20 }} /> : pendingCount}
              {!isLoading && pendingCount > 0 && <span className="kpi-delta kpi-delta--up">+{pendingCount}</span>}
            </div>
            <div className="queue-kpi-label">En attente de revue</div>
          </div>
        </div>
        <div className="queue-kpi">
          <div className="queue-kpi-ico queue-kpi-ico--green"><BadgeCheck size={16} /></div>
          <div className="queue-kpi-body">
            <div className="queue-kpi-value">
              {isLoading ? <span className="sk-block" style={{ width: 28, height: 20 }} /> : approvedCount}
              {!isLoading && approvedCount > 0 && <span className="kpi-delta kpi-delta--up">▲ {approvedCount}</span>}
            </div>
            <div className="queue-kpi-label">Approuvés (total)</div>
          </div>
        </div>
        <div className="queue-kpi">
          <div className="queue-kpi-ico queue-kpi-ico--rose"><XCircle size={16} /></div>
          <div className="queue-kpi-body">
            <div className="queue-kpi-value">
              {isLoading ? <span className="sk-block" style={{ width: 28, height: 20 }} /> : rejectedCount}
              {!isLoading && rejectedCount === 0 && <span className="kpi-delta kpi-delta--flat">— stable</span>}
            </div>
            <div className="queue-kpi-label">Rejetés (total)</div>
          </div>
        </div>
        <div className="queue-kpi">
          <div className="queue-kpi-ico queue-kpi-ico--violet"><Clock size={16} /></div>
          <div className="queue-kpi-body">
            <div className="queue-kpi-value">
              {isLoading ? <span className="sk-block" style={{ width: 28, height: 20 }} /> : (avgDelay !== null ? `${avgDelay} h` : '—')}
            </div>
            <div className="queue-kpi-label">Délai moyen de revue</div>
          </div>
        </div>
      </motion.div>

      {/* Main card */}
      <motion.div className="q-card" initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.1, duration: 0.25 }}>
        {/* Tabs */}
        <div className="q-tabs">
          {TABS.map(tab => (
            <button
              key={tab.key}
              className={`q-tab ${statusTab === tab.key ? 'q-tab--active' : ''}`}
              onClick={() => setStatusTab(tab.key)}
            >
              {tab.label}
              <span className="q-tab-count">{tab.count}</span>
            </button>
          ))}
        </div>

        {/* Toolbar */}
        <div className="q-toolbar">
          <div className="q-search">
            <Search size={14} color="#9ea3bd" />
            <input
              placeholder="Rechercher par nom ou email…"
              value={search}
              onChange={e => setSearch(e.target.value)}
            />
          </div>
          <div className="filter-select-wrap">
            <CustomSelect
              value={categoryId}
              onChange={e => setCategoryId(e.target.value)}
              placeholder="Toutes les spécialités"
              options={[{ value: '', label: 'Toutes les spécialités' }, ...categories.map(c => ({ value: String(c.id), label: c.name }))]}
            />
          </div>
          <div className="q-toolbar-right">{experts.length} résultat{experts.length !== 1 ? 's' : ''}</div>
        </div>

        {/* Table / Empty */}
        {isLoading ? (
          <TableSkeleton rows={4} cols={7} />
        ) : experts.length === 0 ? (
          <div className="q-empty">
            <div className="q-empty-ico">
              <CheckCircle size={28} />
            </div>
            <h4>Tout est à jour 🎉</h4>
            <p>Aucune candidature ne nécessite votre attention pour le moment.</p>
            <div className="q-empty-tips">
              <div className="q-tip"><span className="q-tip-num">1</span><span>Les médecins postulent depuis le formulaire public d'inscription.</span></div>
              <div className="q-tip"><span className="q-tip-num">2</span><span>Leurs documents (diplôme, ordre, ID) sont soumis à la validation.</span></div>
              <div className="q-tip"><span className="q-tip-num">3</span><span>Vous validez ou rejetez ici — délai cible : <b>moins de 24 h</b>.</span></div>
            </div>
          </div>
        ) : (
          <div className="q-table-wrap">
            <table className="q-table">
              <thead>
                <tr>
                  <th className="col-num">#</th>
                  <th>Médecin</th>
                  <th>Spécialité</th>
                  <th>Statut</th>
                  <th>Soumis le</th>
                  <th>Docs</th>
                  <th className="col-actions">Actions</th>
                </tr>
              </thead>
              <tbody>
                {experts.map((expert, i) => (
                  <motion.tr
                    key={expert.id}
                    initial={{ opacity: 0, y: 8 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: i * 0.035, duration: 0.2 }}
                    onClick={() => setDrawerExpert(expert)}
                    className="q-row"
                  >
                    <td className="col-num">{expert.id}</td>
                    <td>
                      <div className="q-ucell">
                        <ExpertAvatar name={expert.user?.name} avatarUrl={expert.user?.avatar_url} />
                        <div>
                          <div className="q-uname">{expert.user?.name}</div>
                          <div className="q-uemail">{expert.user?.email}</div>
                        </div>
                      </div>
                    </td>
                    <td><span className="q-spec-chip">{expert.category?.name ?? '--'}</span></td>
                    <td><StatusPill status={expert.status} /></td>
                    <td>
                      <div className="col-date">{new Date(expert.created_at).toLocaleDateString('fr-FR')}</div>
                      <div className="col-date-sub">{timeSince(expert.created_at)}</div>
                    </td>
                    <td>
                      <span
                        className="q-doc-chip"
                        onClick={e => e.stopPropagation()}
                      >
                        <FileText size={12} />
                        {expert.documents?.length ?? 0} doc{(expert.documents?.length ?? 0) !== 1 ? 's' : ''}
                      </span>
                    </td>
                    <td className="col-actions" onClick={e => e.stopPropagation()}>
                      <div className="q-row-actions">
                        {expert.status !== 'validated' && (
                          <button
                            className="rbtn rbtn--approve"
                            onClick={() => handleValidate(expert)}
                            disabled={validateExpert.isPending}
                          >
                            <CheckCircle size={12} />
                            {expert.status === 'rejected' ? 'Re-valider' : 'Approuver'}
                          </button>
                        )}
                        {expert.status === 'pending' && (
                          <button
                            className="rbtn rbtn--reject"
                            onClick={() => openReject(expert)}
                          >
                            <XCircle size={12} /> Rejeter
                          </button>
                        )}
                      </div>
                    </td>
                  </motion.tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </motion.div>

      {/* Secondary row */}
      {!isLoading && allExperts.length > 0 && (
        <motion.div className="queue-secondary" initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.18, duration: 0.25 }}>
          <SlaCard experts={allExperts} />
          <PipelineCard experts={allExperts} />
        </motion.div>
      )}

      {/* Detail Drawer */}
      <AnimatePresence>
        {drawerExpert && (
          <DetailDrawer
            expert={drawerExpert}
            onClose={() => setDrawerExpert(null)}
            onValidate={() => handleValidate(drawerExpert)}
            onReject={() => openReject(drawerExpert)}
            validating={validateExpert.isPending}
          />
        )}
      </AnimatePresence>

      {/* Reject modal */}
      <AnimatePresence>
        {rejectModal && (
          <div className="modal-overlay" onClick={() => setRejectModal(null)}>
            <motion.div
              className="modal-box modal-box--sm"
              onClick={e => e.stopPropagation()}
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              transition={{ duration: 0.15 }}
            >
              <div className="modal-header">
                <div className="modal-header-left">
                  <div className="confirm-icon-wrap"><AlertTriangle size={20} color="#f59e0b" /></div>
                  <div>
                    <div className="modal-title">Rejeter la candidature</div>
                    <div className="modal-subtitle">{rejectModal.user?.name} · {rejectModal.category?.name}</div>
                  </div>
                </div>
                <button className="modal-close" onClick={() => setRejectModal(null)}><X size={16} /></button>
              </div>
              <div className="modal-body">
                <label className="form-field">
                  <span>Raison du rejet</span>
                  <input
                    value={rejectReason}
                    onChange={e => setRejectReason(e.target.value)}
                    placeholder="Ex : Documents incomplets, diplôme non reconnu…"
                    autoFocus
                  />
                </label>
              </div>
              <div className="modal-footer">
                <button className="btn-ghost" onClick={() => setRejectModal(null)}>Annuler</button>
                <button
                  className="btn-danger"
                  onClick={handleReject}
                  disabled={rejectExpert.isPending || !rejectReason.trim()}
                >
                  <XCircle size={14} /> Confirmer le rejet
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
}
