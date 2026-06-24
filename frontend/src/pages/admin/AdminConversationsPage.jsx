import { useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Search, Star, ChevronLeft, ChevronRight,
  Bot, Trash2, AlertTriangle, X, Loader2,
  MessageSquare, Clock, Activity, Zap,
} from 'lucide-react';
import CustomSelect from '../../components/CustomSelect';
import { useAdminConversations, useAdminCategories, useConversationCleanupPreview, useConversationCleanup } from '../../hooks/useAdmin';
import { TableSkeleton } from '../../components/AdminSkeleton';
import './AdminConversationsPage.css';

/* ── helpers ── */
const AVATAR_COLORS = ['#7c5cff','#0d9488','#ea580c','#16a34a','#dc2626','#ca8a04','#2563eb'];
function avatarBg(name) { return AVATAR_COLORS[(name?.charCodeAt(0) ?? 0) % AVATAR_COLORS.length]; }

function UserAvatar({ name, avatarUrl, size = 32 }) {
  const [fail, setFail] = useState(false);
  const initials = name?.trim().split(/\s+/).map(n => n[0]).join('').slice(0, 2).toUpperCase() || '?';
  if (avatarUrl && !fail)
    return <img src={avatarUrl} alt={name} className="cv-avatar" style={{ width: size, height: size }} onError={() => setFail(true)} />;
  return (
    <div className="cv-avatar cv-avatar--init" style={{ width: size, height: size, background: avatarBg(name), fontSize: size * 0.35 }}>
      {initials}
    </div>
  );
}

function StatusPill({ status }) {
  const active  = ['ai','expert','open'].includes(status);
  return active
    ? <span className="cv-pill cv-pill--active"><span className="cv-pill-dot" />Active</span>
    : <span className="cv-pill cv-pill--closed"><span className="cv-pill-dot" />Terminée</span>;
}

function StarRow({ value }) {
  const n = Math.round(parseFloat(value) || 0);
  return (
    <span className="cv-stars">
      {[1,2,3,4,5].map(i => (
        <Star key={i} size={12} className={i <= n ? 'cv-star--on' : 'cv-star--off'} fill={i <= n ? 'currentColor' : 'none'} />
      ))}
    </span>
  );
}

function relTime(iso) {
  if (!iso) return '';
  const d = Math.floor((Date.now() - new Date(iso).getTime()) / 86400000);
  if (d === 0) return "aujourd'hui";
  if (d === 1) return 'hier';
  if (d < 30) return `il y a ${d}j`;
  return `il y a ${Math.floor(d / 30)}mo`;
}

function formatDuration(createdAt, closedAt) {
  if (!closedAt) return <span className="cv-dur-live">En cours</span>;
  const mins = Math.round((new Date(closedAt) - new Date(createdAt)) / 60000);
  if (mins < 60) return `${mins} min`;
  return `${Math.floor(mins / 60)}h${mins % 60 > 0 ? ` ${mins % 60}m` : ''}`;
}

function formatAvgDuration(minutes) {
  if (!minutes) return '—';
  const m = parseFloat(minutes);
  if (m < 60) return m.toFixed(1);
  return (m / 60).toFixed(1);
}

function formatAvgUnit(minutes) {
  if (!minutes) return '';
  return parseFloat(minutes) < 60 ? 'min' : 'h';
}

const SPEC_COLORS = ['cv-spec--violet','cv-spec--cyan','cv-spec--green','cv-spec--amber','cv-spec--rose','cv-spec--orange'];
function specColor(id) { return SPEC_COLORS[(id ?? 0) % SPEC_COLORS.length]; }

/* ── Category bar ── */
function CategoryBar({ name, icon, total, max }) {
  const pct = max > 0 ? Math.round((total / max) * 100) : 0;
  return (
    <div className="cv-catrow">
      <div className="cv-catrow-name">
        {icon && <span className="cv-catrow-icon">{icon}</span>}
        <span className="cv-catrow-label">{name}</span>
      </div>
      <div className="cv-catrow-bar"><span style={{ width: `${pct}%` }} /></div>
      <span className="cv-catrow-count">{total}</span>
    </div>
  );
}

/* ── Cleanup modal ── */
const AGE_OPTS   = [{v:30,l:'Plus de 30 jours'},{v:90,l:'Plus de 90 jours'},{v:180,l:'Plus de 180 jours'},{v:365,l:'Plus de 1 an'}];
const STATE_OPTS = [{v:'closed',l:'Terminées uniquement'},{v:'all',l:'Toutes (sauf actives)'}];

function CleanupModal({ onClose }) {
  const [age, setAge]     = useState(90);
  const [state, setState] = useState('closed');

  const { data: count = 0, isLoading: previewLoading } = useConversationCleanupPreview({ age_days: age, state });
  const { mutate: doCleanup, isPending }               = useConversationCleanup();

  const handleConfirm = () => {
    doCleanup({ age_days: age, state }, { onSuccess: onClose });
  };

  return (
    <div className="cv-modal-backdrop" onClick={onClose}>
      <motion.div className="cv-modal"
        initial={{ opacity: 0, scale: .96, y: 10 }}
        animate={{ opacity: 1, scale: 1,   y: 0  }}
        exit={{    opacity: 0, scale: .96, y: 10  }}
        transition={{ duration: .18 }}
        onClick={e => e.stopPropagation()}
      >
        <div className="cv-modal-head">
          <div className="cv-modal-ico"><Trash2 size={18} /></div>
          <div>
            <div className="cv-modal-title">Nettoyer les conversations</div>
            <div className="cv-modal-sub">Supprimer les anciennes conversations archivées</div>
          </div>
          <button className="cv-modal-close" onClick={onClose}><X size={15} /></button>
        </div>
        <div className="cv-modal-body">
          <p className="cv-modal-oplabel">Ancienneté</p>
          <div className="cv-modal-opts">
            {AGE_OPTS.map(o => (
              <button key={o.v} className={`cv-modal-opt ${age === o.v ? 'cv-modal-opt--on' : ''}`} onClick={() => setAge(o.v)}>{o.l}</button>
            ))}
          </div>
          <p className="cv-modal-oplabel" style={{ marginTop: 16 }}>Statut</p>
          <div className="cv-modal-opts">
            {STATE_OPTS.map(o => (
              <button key={o.v} className={`cv-modal-opt ${state === o.v ? 'cv-modal-opt--on' : ''}`} onClick={() => setState(o.v)}>{o.l}</button>
            ))}
          </div>
          <div className="cv-modal-summary">
            <div className="cv-modal-sum-row">
              <span>Conversations concernées</span>
              <strong>{previewLoading ? '…' : count.toLocaleString('fr-FR')}</strong>
            </div>
            <div className="cv-modal-sum-row">
              <span>Espace libéré (estimé)</span>
              <strong>~ {previewLoading ? '…' : Math.round(count * 0.45)} Mo</strong>
            </div>
            <div className="cv-modal-warn">
              <AlertTriangle size={13} />
              Cette action est <strong>irréversible</strong>. Les statistiques anonymisées sont conservées.
            </div>
          </div>
        </div>
        <div className="cv-modal-foot">
          <button className="cv-modal-cancel" onClick={onClose} disabled={isPending}>Annuler</button>
          <button className="cv-modal-confirm" onClick={handleConfirm} disabled={isPending || count === 0}>
            {isPending ? <Loader2 size={13} className="spin" /> : <Trash2 size={13} />}
            {isPending ? 'Suppression…' : `Supprimer ${count.toLocaleString('fr-FR')} conversations`}
          </button>
        </div>
      </motion.div>
    </div>
  );
}

/* ═══════════════════════════════════════════════════ */
const TABS = [
  { id: '',       label: 'Toutes'  },
  { id: 'expert', label: 'Expert'  },
  { id: 'ai',     label: 'IA'      },
];

export default function AdminConversationsPage() {
  const [activeTab,    setActiveTab]    = useState('');
  const [search,       setSearch]       = useState('');
  const [categoryId,   setCategoryId]   = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [page,         setPage]         = useState(1);
  const [cleanup,      setCleanup]      = useState(false);

  const { data: categoriesData = [] } = useAdminCategories();
  const queryParams = useMemo(() => {
    const p = { page };
    if (activeTab)     p.tab         = activeTab;
    if (statusFilter)  p.status      = statusFilter;
    if (search)        p.search      = search;
    if (categoryId)    p.category_id = categoryId;
    return p;
  }, [activeTab, statusFilter, search, categoryId, page]);

  const { data, isLoading } = useAdminConversations(queryParams);

  const conversations = useMemo(() => {
    if (!data) return [];
    const raw = data.data;
    return Array.isArray(raw) ? raw : (raw?.data ?? []);
  }, [data]);

  const meta  = data?.meta  ?? {};
  const stats = data?.stats ?? {};
  const topCats = stats.top_categories ?? [];
  const maxCat  = topCats[0]?.total ?? 1;

  const tabCounts = {
    '':       stats.total          ?? 0,
    'expert': stats.with_expert    ?? 0,
    'ai':     stats.without_expert ?? 0,
  };

  const rangeStart = meta.current_page ? (meta.current_page - 1) * 20 + 1 : 1;
  const rangeEnd   = meta.current_page ? Math.min(meta.current_page * 20, meta.total ?? 0) : conversations.length;

  const reset = () => setPage(1);

  return (
    <div className="cv-page">

      {/* ── Header ── */}
      <div className="cv-head">
        <div>
          <h1 className="cv-head-title">
            Conversations
            {(stats.open ?? 0) > 0 && (
              <span className="cv-live-pill">
                <span className="cv-live-dot" />
                {stats.open} en direct
              </span>
            )}
          </h1>
          <p className="cv-head-sub">Toutes les sessions entre patients, experts et l'IA — modérez et analysez l'activité</p>
        </div>
        <button className="cv-cleanup-btn" onClick={() => setCleanup(true)}>
          <Trash2 size={14} />
          Nettoyer
        </button>
      </div>

      {/* ── KPI strip ── */}
      <div className="cv-kpis">

        <div className="cv-kpi">
          <div className="cv-kpi-ico cv-kpi-ico--violet"><MessageSquare size={18} /></div>
          <div className="cv-kpi-body">
            <div className="cv-kpi-val">{(stats.total ?? 0).toLocaleString('fr-FR')}</div>
            <div className="cv-kpi-lbl">Conversations (30j)</div>
          </div>
        </div>

        <div className="cv-kpi">
          <div className="cv-kpi-ico cv-kpi-ico--split"><Zap size={18} /></div>
          <div className="cv-kpi-body" style={{ flex: 1 }}>
            {(() => {
              const total  = stats.total || 1;
              const aiPct  = Math.round(((stats.ai ?? 0) / total) * 100);
              const expPct = 100 - aiPct;
              return (
                <>
                  <div className="cv-kpi-val" style={{ fontSize: 18 }}>
                    {aiPct}% <span className="cv-kpi-unit">IA</span>
                    <span className="cv-kpi-sep">·</span>
                    {expPct}% <span className="cv-kpi-unit">Expert</span>
                  </div>
                  <div className="cv-splitbar">
                    <span className="cv-splitbar-ai"  style={{ flex: aiPct  }} />
                    <span className="cv-splitbar-exp" style={{ flex: expPct }} />
                  </div>
                  <div className="cv-split-legend">
                    <span><span className="cv-split-sw cv-split-sw--ai"  />IA</span>
                    <span><span className="cv-split-sw cv-split-sw--exp" />Expert</span>
                  </div>
                </>
              );
            })()}
          </div>
        </div>

        <div className="cv-kpi">
          <div className="cv-kpi-ico cv-kpi-ico--green"><Clock size={18} /></div>
          <div className="cv-kpi-body">
            <div className="cv-kpi-val">
              {formatAvgDuration(stats.avg_duration_minutes)}
              {stats.avg_duration_minutes ? <span className="cv-kpi-unit">{formatAvgUnit(stats.avg_duration_minutes)}</span> : ''}
            </div>
            <div className="cv-kpi-lbl">Durée moyenne</div>
          </div>
        </div>

        <div className="cv-kpi">
          <div className="cv-kpi-ico cv-kpi-ico--amber"><Star size={18} /></div>
          <div className="cv-kpi-body">
            <div className="cv-kpi-val">
              {stats.avg_rating ? stats.avg_rating : '—'}
              {stats.avg_rating ? <span className="cv-kpi-unit">/5</span> : ''}
            </div>
            <div className="cv-kpi-lbl" style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
              Satisfaction ·
              {stats.avg_rating ? <StarRow value={stats.avg_rating} /> : null}
            </div>
          </div>
        </div>

      </div>

      {/* ── Main layout ── */}
      <div className="cv-layout">

        {/* ── Table card ── */}
        <div className="cv-card">

          {/* Tabs — underline style */}
          <div className="cv-tabs">
            {TABS.map(t => (
              <button
                key={t.id}
                className={`cv-tab ${activeTab === t.id ? 'cv-tab--on' : ''}`}
                onClick={() => { setActiveTab(t.id); reset(); }}
              >
                {t.label}
                <span className="cv-tab-badge">{(tabCounts[t.id] ?? 0).toLocaleString('fr-FR')}</span>
              </button>
            ))}
          </div>

          {/* Toolbar */}
          <div className="cv-toolbar">
            <div className="cv-search-wrap">
              <Search size={13} className="cv-search-ico" />
              <input
                type="text"
                className="cv-search"
                placeholder="Rechercher utilisateur, expert ou mot-clé…"
                value={search}
                onChange={e => { setSearch(e.target.value); reset(); }}
              />
            </div>

            <div className="cv-select-wrap">
              <CustomSelect
                value={categoryId}
                onChange={e => { setCategoryId(e.target.value); reset(); }}
                placeholder="Toutes catégories"
                options={categoriesData.map(c => ({ value: c.id, label: c.name }))}
              />
            </div>

            <div className="cv-select-wrap">
              <CustomSelect
                value={statusFilter}
                onChange={e => { setStatusFilter(e.target.value); reset(); }}
                placeholder="Tous les statuts"
                options={[
                  { value: 'open',   label: 'Actives'   },
                  { value: 'closed', label: 'Terminées' },
                ]}
              />
            </div>

            <span className="cv-result-count">
              {(meta.total ?? conversations.length).toLocaleString('fr-FR')} résultat{(meta.total ?? conversations.length) !== 1 ? 's' : ''}
            </span>
          </div>

          {/* Table */}
          <div className="cv-table-wrap">
            {isLoading ? (
              <TableSkeleton rows={8} cols={8} />
            ) : conversations.length === 0 ? (
              <div className="cv-empty">
                <MessageSquare size={28} className="cv-empty-ico" />
                <p>Aucune conversation trouvée</p>
              </div>
            ) : (
              <table className="cv-table">
                <thead>
                  <tr>
                    <th className="cv-th-id">#</th>
                    <th>Utilisateur</th>
                    <th>Expert / IA</th>
                    <th>Catégorie</th>
                    <th>Messages</th>
                    <th>Durée</th>
                    <th>Note</th>
                    <th>Statut</th>
                    <th>Date</th>
                  </tr>
                </thead>
                <tbody>
                  {conversations.map((c, idx) => (
                    <motion.tr
                      key={c.id}
                      initial={{ opacity: 0, y: 4 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ delay: idx * 0.025 }}
                    >
                      <td className="cv-td-id">#{c.id}</td>

                      <td>
                        <div className="cv-ucell">
                          <UserAvatar name={c.user?.name} avatarUrl={c.user?.avatar_url} size={28} />
                          <div>
                            <div className="cv-uname">{c.user?.name ?? '—'}</div>
                            <div className="cv-uemail">{c.user?.email ?? ''}</div>
                          </div>
                        </div>
                      </td>

                      <td>
                        {c.expert ? (
                          <div className="cv-ucell">
                            <UserAvatar name={c.expert?.user?.name} avatarUrl={c.expert?.user?.avatar_url} size={24} />
                            <span className="cv-expert-name">{c.expert?.user?.name ?? '—'}</span>
                          </div>
                        ) : (
                          <span className="cv-ai-chip">
                            <Activity size={10} />
                            IA Nexora
                          </span>
                        )}
                      </td>

                      <td>
                        {c.category && (
                          <span className={`cv-spec ${specColor(c.category.id)}`}>
                            {c.category.icon && <span>{c.category.icon}</span>}
                            {c.category.name}
                          </span>
                        )}
                      </td>

                      <td>
                        <span className="cv-msg">
                          <MessageSquare size={11} className="cv-msg-ico" />
                          {c.messages_count ?? '—'}
                        </span>
                      </td>

                      <td className="cv-td-mono">{formatDuration(c.created_at, c.closed_at)}</td>

                      <td>
                        {c.rating ? <StarRow value={c.rating} /> : <span className="cv-dash">—</span>}
                      </td>

                      <td><StatusPill status={c.status} /></td>

                      <td>
                        <div className="cv-date">{new Date(c.created_at).toLocaleDateString('fr-FR')}</div>
                        <div className="cv-date-rel">{relTime(c.created_at)}</div>
                      </td>
                    </motion.tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>

          {/* Pagination */}
          {meta.last_page > 1 && (
            <div className="cv-pagination">
              <span className="cv-pag-info">
                Affichage <strong>{rangeStart}–{rangeEnd}</strong> sur {(meta.total ?? 0).toLocaleString('fr-FR')}
              </span>
              <div className="cv-pag-btns">
                <button className="cv-pbtn" disabled={page <= 1} onClick={() => setPage(p => p - 1)}>
                  <ChevronLeft size={14} />
                </button>
                {Array.from({ length: meta.last_page }, (_, i) => i + 1)
                  .filter(p => p === 1 || p === meta.last_page || Math.abs(p - page) <= 1)
                  .reduce((acc, p, i, arr) => { if (i > 0 && p - arr[i-1] > 1) acc.push('…'); acc.push(p); return acc; }, [])
                  .map((p, i) => p === '…'
                    ? <span key={`e${i}`} className="cv-pellipsis">…</span>
                    : <button key={p} className={`cv-pbtn ${page === p ? 'cv-pbtn--on' : ''}`} onClick={() => setPage(p)}>{p}</button>
                  )}
                <button className="cv-pbtn" disabled={page >= meta.last_page} onClick={() => setPage(p => p + 1)}>
                  <ChevronRight size={14} />
                </button>
              </div>
            </div>
          )}
        </div>

        {/* ── Sidebar ── */}
        <div className="cv-side">

          <div className="cv-side-card cv-side-card--full">
            <div className="cv-side-head">
              <h3 className="cv-side-title">Top catégories (30j)</h3>
            </div>
            <div className="cv-side-body">
              {isLoading
                ? <div className="cv-side-loading"><Loader2 size={18} className="spin" /></div>
                : topCats.length === 0
                  ? <p className="cv-side-empty">Aucune donnée</p>
                  : topCats.map((cat, i) => <CategoryBar key={i} name={cat.name} icon={cat.icon} total={cat.total} max={maxCat} />)
              }
            </div>
          </div>

        </div>
      </div>

      <AnimatePresence>
        {cleanup && <CleanupModal onClose={() => setCleanup(false)} />}
      </AnimatePresence>
    </div>
  );
}
