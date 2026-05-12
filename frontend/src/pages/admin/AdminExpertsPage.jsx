import { useState, useEffect } from 'react';
import {
  Search, CheckCircle, XCircle, ToggleLeft, ToggleRight,
  FileText, X, Download, Eye, ShieldCheck, Clock, FileX, Loader2,
} from 'lucide-react';
import api from '../../lib/api';
import { useAdminExperts, useValidateExpert, useRejectExpert, useToggleExpert } from '../../hooks/useAdmin';
import CustomSelect from '../../components/CustomSelect';
import { TableSkeleton } from '../../components/AdminSkeleton';
import './AdminExpertsPage.css';

const DOC_TYPE_LABELS = {
  diploma:     'Diplôme',
  id_card:     'Carte d\'identité',
  certificate: 'Certificat',
  other:       'Autre',
};

const DOC_TYPE_COLORS = {
  diploma:     'doc-type--diploma',
  id_card:     'doc-type--id',
  certificate: 'doc-type--cert',
  other:       'doc-type--other',
};

function PreviewModal({ doc, onClose }) {
  const [blobUrl, setBlobUrl] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError]     = useState(false);

  useEffect(() => {
    let objectUrl;
    const path = doc.stream_url.replace(/^.*\/api\/v1\//, '');
    api.get(path, { responseType: 'blob' })
      .then((res) => {
        objectUrl = URL.createObjectURL(res.data);
        setBlobUrl(objectUrl);
      })
      .catch(() => setError(true))
      .finally(() => setLoading(false));

    return () => { if (objectUrl) URL.revokeObjectURL(objectUrl); };
  }, [doc.stream_url]);

  const handleDownload = () => {
    if (!blobUrl) return;
    const a = document.createElement('a');
    a.href = blobUrl;
    a.download = doc.original_name;
    a.click();
  };

  return (
    <div className="docs-overlay" onClick={onClose}>
      <div className="preview-modal" onClick={(e) => e.stopPropagation()}>
        <div className="preview-modal-header">
          <span className="preview-modal-name"><FileText size={15} /> {doc.original_name}</span>
          <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
            <button className="doc-btn doc-btn--download" onClick={handleDownload} disabled={!blobUrl}>
              <Download size={13} /> Télécharger
            </button>
            <button className="docs-close" onClick={onClose}><X size={18} /></button>
          </div>
        </div>
        <div className="preview-modal-body">
          {loading && (
            <div className="preview-loading">
              <Loader2 size={28} className="spin" style={{ color: '#9ca3af' }} />
              <span>Chargement du document…</span>
            </div>
          )}
          {error && (
            <div className="preview-loading" style={{ color: '#ef4444' }}>
              Impossible de charger le document.
            </div>
          )}
          {blobUrl && (
            <iframe src={blobUrl} title={doc.original_name} className="preview-iframe" />
          )}
        </div>
      </div>
    </div>
  );
}

async function downloadDoc(doc) {
  const path = doc.stream_url.replace(/^.*\/api\/v1\//, '');
  const res = await api.get(`${path}?download=1`, { responseType: 'blob' });
  const url = URL.createObjectURL(res.data);
  const a = document.createElement('a');
  a.href = url;
  a.download = doc.original_name;
  a.click();
  URL.revokeObjectURL(url);
}

function DocumentsModal({ expert, onClose }) {
  const docs = expert.documents ?? [];
  const [previewDoc, setPreviewDoc] = useState(null);

  if (previewDoc) {
    return <PreviewModal doc={previewDoc} onClose={() => setPreviewDoc(null)} />;
  }

  return (
    <div className="docs-overlay" onClick={onClose}>
      <div className="docs-modal" onClick={(e) => e.stopPropagation()}>

        {/* Header */}
        <div className="docs-modal-header">
          <div className="docs-modal-title">
            <FileText size={18} />
            <div>
              <h2>Documents justificatifs</h2>
              <p>{expert.user?.name} · {expert.category?.name}</p>
            </div>
          </div>
          <button className="docs-close" onClick={onClose}><X size={18} /></button>
        </div>

        {/* Status bar */}
        <div className={`docs-status-bar docs-status-bar--${expert.status}`}>
          {expert.status === 'pending'   && <><Clock size={14} /> Candidature en attente de validation</>}
          {expert.status === 'validated' && <><ShieldCheck size={14} /> Médecin validé</>}
          {expert.status === 'rejected'  && <><FileX size={14} /> Candidature rejetée</>}
        </div>

        {/* Documents list */}
        <div className="docs-list">
          {docs.length === 0 ? (
            <div className="docs-empty">
              <FileText size={36} style={{ opacity: 0.2 }} />
              <p>Aucun document soumis.</p>
            </div>
          ) : (
            docs.map((doc) => (
              <div key={doc.id} className="doc-item">
                <div className="doc-item-left">
                  <div className="doc-icon">
                    <FileText size={20} />
                  </div>
                  <div className="doc-info">
                    <span className="doc-name">{doc.original_name}</span>
                    <div className="doc-meta">
                      <span className={`doc-type-badge ${DOC_TYPE_COLORS[doc.type] ?? 'doc-type--other'}`}>
                        {DOC_TYPE_LABELS[doc.type] ?? doc.type}
                      </span>
                      <span className={`doc-verified ${doc.verified ? 'doc-verified--yes' : 'doc-verified--no'}`}>
                        {doc.verified ? <><ShieldCheck size={11} /> Vérifié</> : 'Non vérifié'}
                      </span>
                      <span className="doc-date">
                        {new Date(doc.created_at).toLocaleDateString('fr-FR')}
                      </span>
                    </div>
                  </div>
                </div>
                <div className="doc-item-actions">
                  <button
                    className="doc-btn doc-btn--view"
                    onClick={() => setPreviewDoc(doc)}
                    title="Prévisualiser"
                  >
                    <Eye size={14} /> Voir
                  </button>
                  <button
                    className="doc-btn doc-btn--download"
                    onClick={() => downloadDoc(doc)}
                    title="Télécharger"
                  >
                    <Download size={14} /> Télécharger
                  </button>
                </div>
              </div>
            ))
          )}
        </div>

        {/* Footer */}
        <div className="docs-modal-footer">
          <span className="docs-count">{docs.length} document{docs.length !== 1 ? 's' : ''}</span>
          <button className="docs-btn-close" onClick={onClose}>Fermer</button>
        </div>
      </div>
    </div>
  );
}

export default function AdminExpertsPage() {
  const [search, setSearch]         = useState('');
  const [status, setStatus]         = useState('');
  const [page, setPage]             = useState(1);
  const [rejectingId, setRejectingId] = useState(null);
  const [rejectReason, setRejectReason] = useState('');
  const [docsExpert, setDocsExpert] = useState(null);

  const { data, isLoading } = useAdminExperts({ search, status, page });
  const validateExpert = useValidateExpert();
  const rejectExpert   = useRejectExpert();
  const toggleExpert   = useToggleExpert();

  const experts = Array.isArray(data?.data) ? data.data : (data?.data?.data ?? []);
  const meta    = data?.meta ?? {};
  const stats   = data?.stats ?? { pending: 0, validated: 0, rejected: 0 };

  const handleReject = (id) => {
    rejectExpert.mutate({ id, reason: rejectReason }, {
      onSuccess: () => { setRejectingId(null); setRejectReason(''); },
    });
  };

  return (
    <div className="admin-experts">
      <div className="page-header">
        <h1>Gestion des médecins</h1>
      </div>

      <div className="stats-cards">
        <div className="stat-card stat-card--pending">
          <span className="stat-card-title">En attente</span>
          <span className="stat-card-value">{stats.pending}</span>
        </div>
        <div className="stat-card stat-card--validated">
          <span className="stat-card-title">Validés</span>
          <span className="stat-card-value">{stats.validated}</span>
        </div>
        <div className="stat-card stat-card--rejected">
          <span className="stat-card-title">Rejetés</span>
          <span className="stat-card-value">{stats.rejected}</span>
        </div>
      </div>

      <div className="filters-bar">
        <div className="search-box">
          <Search size={14} />
          <input
            placeholder="Rechercher par nom ou email…"
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(1); }}
          />
        </div>
        <div className="filter-select-wrap">
          <CustomSelect
            value={status}
            onChange={(e) => { setStatus(e.target.value); setPage(1); }}
            placeholder="Tous les statuts"
            options={[
              { value: '',          label: 'Tous les statuts' },
              { value: 'pending',   label: 'En attente' },
              { value: 'validated', label: 'Validé' },
              { value: 'rejected',  label: 'Rejeté' },
            ]}
          />
        </div>
        <span className="cell-muted" style={{ marginLeft: 'auto' }}>
          {meta.total ?? experts.length} résultats
        </span>
      </div>

      {isLoading ? (
        <TableSkeleton rows={8} cols={7} />
      ) : experts.length === 0 ? (
        <div className="table-loading">Aucun médecin trouvé.</div>
      ) : (
        <>
          <div className="table-wrap">
            <table className="data-table">
              <thead>
                <tr>
                  <th style={{ width: 48 }}>#</th>
                  <th>Médecin</th>
                  <th>Spécialité</th>
                  <th>Tarif</th>
                  <th>Statut</th>
                  <th>Disponibilité</th>
                  <th>Documents</th>
                  <th style={{ width: 220 }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {experts.map((expert) => (
                  <tr key={expert.id}>
                    <td className="cell-muted">{expert.id}</td>
                    <td>
                      <div className="cell-name">{expert.user?.name}</div>
                      <div className="cell-muted">{expert.user?.email}</div>
                    </td>
                    <td>{expert.category?.name}</td>
                    <td>{expert.hourly_rate ? `${expert.hourly_rate} MAD` : '—'}</td>
                    <td>
                      <span className={`status-badge ${expert.status}`}>
                        {expert.status === 'pending' ? 'En attente' : expert.status === 'validated' ? 'Validé' : 'Rejeté'}
                      </span>
                    </td>
                    <td>
                      {expert.status === 'validated' ? (
                        <span className={`avail-badge ${expert.is_available ? 'avail-yes' : 'avail-no'}`}>
                          {expert.is_available ? 'Disponible' : 'Indisponible'}
                        </span>
                      ) : (
                        <span className="cell-muted">—</span>
                      )}
                    </td>
                    <td>
                      <button
                        className="doc-count-btn"
                        onClick={() => setDocsExpert(expert)}
                        title="Voir les documents"
                      >
                        <FileText size={13} />
                        {expert.documents?.length ?? 0} doc{(expert.documents?.length ?? 0) !== 1 ? 's' : ''}
                      </button>
                    </td>
                    <td className="cell-actions">
                      {rejectingId === expert.id ? (
                        <div className="reject-form-inline">
                          <input
                            type="text"
                            placeholder="Raison..."
                            value={rejectReason}
                            onChange={(e) => setRejectReason(e.target.value)}
                            autoFocus
                          />
                          <button className="btn-confirm-reject" onClick={() => handleReject(expert.id)} disabled={rejectExpert.isPending}>OK</button>
                          <button className="btn-cancel" onClick={() => setRejectingId(null)}>Annuler</button>
                        </div>
                      ) : (
                        <>
                          {expert.status === 'pending' && (
                            <>
                              <button
                                className="action-btn validate"
                                onClick={() => validateExpert.mutate(expert.id)}
                                disabled={validateExpert.isPending}
                              >
                                <CheckCircle size={13} /> Valider
                              </button>
                              <button
                                className="action-btn reject"
                                onClick={() => setRejectingId(expert.id)}
                              >
                                <XCircle size={13} /> Rejeter
                              </button>
                            </>
                          )}
                          {expert.status === 'validated' && (
                            <button
                              className="action-btn toggle"
                              onClick={() => toggleExpert.mutate(expert.id)}
                              disabled={toggleExpert.isPending}
                            >
                              {expert.is_available
                                ? <><ToggleRight size={13} /> Rendre Indisponible</>
                                : <><ToggleLeft  size={13} /> Rendre Disponible</>}
                            </button>
                          )}
                        </>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {meta.last_page > 1 && (
            <div className="pagination">
              <button disabled={page <= 1} onClick={() => setPage(p => p - 1)}>‹ Préc.</button>
              {Array.from({ length: meta.last_page }, (_, i) => i + 1)
                .filter(p => p === 1 || p === meta.last_page || Math.abs(p - page) <= 1)
                .reduce((acc, p, idx, arr) => {
                  if (idx > 0 && p - arr[idx - 1] > 1) acc.push('…');
                  acc.push(p);
                  return acc;
                }, [])
                .map((p, i) =>
                  p === '…'
                    ? <span key={`ellipsis-${i}`} className="pagination-ellipsis">…</span>
                    : <button key={p} className={p === page ? 'active' : ''} onClick={() => setPage(p)}>{p}</button>
                )}
              <button disabled={page >= meta.last_page} onClick={() => setPage(p => p + 1)}>Suiv. ›</button>
            </div>
          )}
        </>
      )}

      {docsExpert && (
        <DocumentsModal expert={docsExpert} onClose={() => setDocsExpert(null)} />
      )}
    </div>
  );
}
