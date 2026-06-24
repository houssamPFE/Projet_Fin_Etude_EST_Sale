import { useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Search, ChevronUp, ChevronDown, ChevronsUpDown,
  X, Pencil, ShieldCheck, UserCheck, UserX,
  Users, CheckCircle, XCircle, Clock, Ban, AlertTriangle,
  Zap, Crown, Sparkles,
} from 'lucide-react';
import CustomSelect from '../../components/CustomSelect';
import {
  useAdminUsers, useAdminUserStats, useToggleUser,
  useUpdateUser, useBulkSuspendUsers, useAdminChangePlan,
} from '../../hooks/useAdmin';
import { TableSkeleton } from '../../components/AdminSkeleton';
import './AdminUsersPage.css';

const AVATAR_COLORS = ['#2563eb', '#7c3aed', '#0d9488', '#ea580c', '#16a34a', '#dc2626', '#ca8a04'];

function UserAvatar({ name, avatarUrl, size = 32 }) {
  const [imgFailed, setImgFailed] = useState(false);
  const initials = name.trim().split(/\s+/).map(n => n[0]).join('').slice(0, 2).toUpperCase();
  const bg = AVATAR_COLORS[name.charCodeAt(0) % AVATAR_COLORS.length];
  if (avatarUrl && !imgFailed) {
    return <img src={avatarUrl} alt={name} className="u-avatar" style={{ width: size, height: size }} onError={() => setImgFailed(true)} />;
  }
  return (
    <div className="u-avatar u-avatar--initials" style={{ width: size, height: size, background: bg, fontSize: size * 0.38 }}>
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

function GoogleIcon() {
  return (
    <svg width="12" height="12" viewBox="0 0 24 24" className="oauth-icon" title="Google">
      <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
      <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
      <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
      <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
    </svg>
  );
}

function FacebookIcon() {
  return (
    <svg width="12" height="12" viewBox="0 0 24 24" className="oauth-icon" title="Facebook">
      <path fill="#1877F2" d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
    </svg>
  );
}

const STATUS_CONFIG = {
  active:    { label: 'Actif',      dot: '#16a34a', bg: '#dcfce7', color: '#15803d' },
  suspended: { label: 'Suspendu',   dot: '#dc2626', bg: '#fee2e2', color: '#991b1b' },
  pending:   { label: 'En attente', dot: '#f59e0b', bg: '#fef3c7', color: '#92400e' },
};

function StatusDot({ status }) {
  const cfg = STATUS_CONFIG[status] ?? STATUS_CONFIG.active;
  return (
    <span className="status-dot-wrap" style={{ background: cfg.bg, color: cfg.color }}>
      <span className="status-dot" style={{ background: cfg.dot }} />
      {cfg.label}
    </span>
  );
}

const PLAN_CFG = {
  free:    { label: 'Gratuit', color: '#9ca3af', bg: 'rgba(156,163,175,0.18)', border: 'rgba(156,163,175,0.3)' },
  pro:     { label: 'Pro',     color: '#60a5fa', bg: 'rgba(37,99,235,0.18)',   border: 'rgba(37,99,235,0.35)'  },
  premium: { label: 'Premium', color: '#c4b5fd', bg: 'rgba(124,58,237,0.18)', border: 'rgba(124,58,237,0.35)' },
};

function PlanBadge({ plan }) {
  const cfg = PLAN_CFG[plan] ?? PLAN_CFG.free;
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center',
      padding: '3px 10px', borderRadius: 99, fontSize: 11, fontWeight: 600,
      background: cfg.bg, color: cfg.color,
      border: `1px solid ${cfg.border}`,
    }}>
      {cfg.label}
    </span>
  );
}

function KpiCard({ icon: Icon, label, value, color, isLoading }) {
  return (
    <div className={`u-kpi-card u-kpi-card--${color}`}>
      <div className="u-kpi-icon"><Icon size={18} /></div>
      <div className="u-kpi-info">
        <div className="u-kpi-value">
          {isLoading ? <span className="sk-block" style={{ width: 32, height: 20 }} /> : (value ?? 0)}
        </div>
        <div className="u-kpi-label">{label}</div>
      </div>
    </div>
  );
}

function formatActivityDate(iso) {
  if (!iso) return null;
  const d = new Date(iso);
  const now = new Date();
  const diff = Math.floor((now - d) / 1000);
  if (diff < 60) return "A l'instant";
  if (diff < 3600) return `Il y a ${Math.floor(diff / 60)} min`;
  if (diff < 86400) return `Il y a ${Math.floor(diff / 3600)} h`;
  if (diff < 604800) return `Il y a ${Math.floor(diff / 86400)} j`;
  return d.toLocaleDateString('fr-FR');
}

export default function AdminUsersPage() {
  const [search, setSearch]         = useState('');
  const [role, setRole]             = useState('');
  const [status, setStatus]         = useState('');
  const [source, setSource]         = useState('');
  const [plan, setPlan]             = useState('');
  const [sortBy, setSortBy]         = useState('created_at');
  const [sortDir, setSortDir]       = useState('desc');
  const [page, setPage]             = useState(1);
  const [selected, setSelected]     = useState(new Set());
  const [modal, setModal]           = useState(null);
  const [form, setForm]             = useState({});
  const [planForm, setPlanForm]     = useState({ plan: 'free', credits: 0, expiresAt: '' });
  const [planModal, setPlanModal]   = useState(null); // user object
  const [confirmSuspend, setConfirmSuspend] = useState(false);

  const { data, isLoading }                  = useAdminUsers({ search, role, status, source, plan, page });
  const { data: kpi, isLoading: kpiLoading } = useAdminUserStats();
  const toggleUser  = useToggleUser();
  const updateUser  = useUpdateUser();
  const bulkSuspend = useBulkSuspendUsers();
  const changePlan  = useAdminChangePlan();

  const meta = data?.meta ?? {};

  const users = useMemo(() => {
    const raw = Array.isArray(data?.data) ? data.data : (data?.data?.data ?? []);
    return [...raw].sort((a, b) => {
      const valA = a[sortBy] ?? '';
      const valB = b[sortBy] ?? '';
      const cmp  = String(valA).localeCompare(String(valB), 'fr', { sensitivity: 'base' });
      return sortDir === 'asc' ? cmp : -cmp;
    });
  }, [data, sortBy, sortDir]);

  const toggleSort = (col) => {
    if (sortBy === col) setSortDir(d => d === 'asc' ? 'desc' : 'asc');
    else { setSortBy(col); setSortDir('asc'); }
    setPage(1);
  };

  const allSelected  = users.length > 0 && users.every(u => selected.has(u.id));
  const someSelected = selected.size > 0;

  const toggleAll = () => {
    if (allSelected) setSelected(new Set());
    else setSelected(new Set(users.map(u => u.id)));
  };

  const toggleOne = (id) => {
    setSelected(prev => {
      const next = new Set(prev);
      next.has(id) ? next.delete(id) : next.add(id);
      return next;
    });
  };

  const openEdit = (user) => {
    setModal(user);
    setForm({ name: user.name, email: user.email, phone: user.phone ?? '', role: user.role, language: user.language ?? 'fr' });
  };

  const saveEdit = () => {
    if (!modal) return;
    updateUser.mutate({ id: modal.id, payload: form }, { onSuccess: () => setModal(null) });
  };

  const openPlanModal = (user) => {
    setPlanModal(user);
    setPlanForm({
      plan: user.plan ?? 'free',
      credits: user.consultation_credits ?? 0,
      expiresAt: user.plan_expires_at ? user.plan_expires_at.slice(0, 10) : '',
    });
  };

  const savePlan = () => {
    if (!planModal) return;
    changePlan.mutate({
      userId: planModal.id,
      plan: planForm.plan,
      credits: parseInt(planForm.credits, 10),
      expiresAt: planForm.expiresAt || null,
    }, { onSuccess: () => setPlanModal(null) });
  };

  const handleBulkSuspend = () => {
    bulkSuspend.mutate([...selected], {
      onSuccess: () => { setSelected(new Set()); setConfirmSuspend(false); },
    });
  };

  return (
    <div className="admin-users">
      <motion.div className="page-header-row" initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.3 }}>
        <div>
          <h1>Gestion des utilisateurs</h1>
          <p className="page-subtitle">{kpi?.total ?? meta.total ?? '--'} utilisateurs inscrits sur la plateforme</p>
        </div>
      </motion.div>

      <motion.div className="u-kpi-row" initial={{ opacity: 0, y: -6 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.05, duration: 0.25 }}>
        <KpiCard icon={Users}       label="Total"      value={kpi?.total}           color="blue"   isLoading={kpiLoading} />
        <KpiCard icon={CheckCircle} label="Actifs"     value={kpi?.active}          color="green"  isLoading={kpiLoading} />
        <KpiCard icon={Clock}       label="En attente" value={kpi?.pending}         color="orange" isLoading={kpiLoading} />
        <KpiCard icon={Ban}         label="Suspendus"  value={kpi?.suspended}       color="red"    isLoading={kpiLoading} />
      </motion.div>
      <motion.div className="u-kpi-row" style={{ marginTop: 0 }} initial={{ opacity: 0, y: -4 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.08, duration: 0.25 }}>
        <KpiCard icon={Sparkles}    label="Plan Gratuit" value={kpi?.plans?.free}    color="gray"   isLoading={kpiLoading} />
        <KpiCard icon={Zap}         label="Plan Pro"     value={kpi?.plans?.pro}     color="blue"   isLoading={kpiLoading} />
        <KpiCard icon={Crown}       label="Plan Premium" value={kpi?.plans?.premium} color="violet" isLoading={kpiLoading} />
      </motion.div>

      <motion.div className="filters-bar" initial={{ opacity: 0, y: -6 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.1, duration: 0.25 }}>
        <div className="search-box">
          <Search size={15} color="#94a3b8" />
          <input placeholder="Rechercher par nom ou email..." value={search} onChange={(e) => { setSearch(e.target.value); setPage(1); }} />
        </div>
        <div className="filter-divider" />
        <div className="filter-select-wrap">
          <CustomSelect value={role} onChange={(e) => { setRole(e.target.value); setPage(1); }} placeholder="Tous les roles"
            options={[{ value: '', label: 'Tous les roles' }, { value: 'user', label: 'Utilisateur' }, { value: 'expert', label: 'Expert' }, { value: 'admin', label: 'Admin' }]} />
        </div>
        <div className="filter-select-wrap">
          <CustomSelect value={status} onChange={(e) => { setStatus(e.target.value); setPage(1); }} placeholder="Tous les statuts"
            options={[{ value: '', label: 'Tous les statuts' }, { value: 'active', label: 'Actif' }, { value: 'suspended', label: 'Suspendu' }, { value: 'pending', label: 'En attente' }]} />
        </div>
        <div className="filter-select-wrap">
          <CustomSelect value={source} onChange={(e) => { setSource(e.target.value); setPage(1); }} placeholder="Toutes les sources"
            options={[{ value: '', label: 'Toutes les sources' }, { value: 'email', label: 'Email' }, { value: 'google', label: 'Google' }, { value: 'facebook', label: 'Facebook' }]} />
        </div>
        <div className="filter-select-wrap">
          <CustomSelect value={plan} onChange={(e) => { setPlan(e.target.value); setPage(1); }} placeholder="Tous les plans"
            options={[{ value: '', label: 'Tous les plans' }, { value: 'free', label: '✦ Gratuit' }, { value: 'pro', label: '⚡ Pro' }, { value: 'premium', label: '👑 Premium' }]} />
        </div>
        <span className="results-count">{meta.total ?? users.length} resultats</span>
      </motion.div>

      <AnimatePresence>
        {someSelected && (
          <motion.div className="bulk-bar" initial={{ opacity: 0, y: -8 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -8 }} transition={{ duration: 0.2 }}>
            <span className="bulk-count">{selected.size} sélectionné{selected.size > 1 ? 's' : ''}</span>
            <button className="bulk-btn bulk-btn--ghost" onClick={() => setSelected(new Set())}>
              <X size={13} /> Annuler
            </button>
            <div className="bulk-spacer" />
            <button className="bulk-btn bulk-btn--danger" onClick={() => setConfirmSuspend(true)}>
              <Ban size={13} /> Suspendre
            </button>
          </motion.div>
        )}
      </AnimatePresence>

      {isLoading ? (
        <TableSkeleton rows={8} cols={9} />
      ) : users.length === 0 ? (
        <div className="table-empty">Aucun utilisateur trouve.</div>
      ) : (
        <>
          <div className="table-wrap">
            <table className="data-table">
              <thead>
                <tr>
                  <th style={{ width: 36, padding: '0.5rem 0.5rem 0.5rem 0.75rem' }}>
                    <input type="checkbox" className="row-checkbox" checked={allSelected} onChange={toggleAll} />
                  </th>
                  <th style={{ width: 40 }}>#</th>
                  <th className="th-sort" onClick={() => toggleSort('name')}><span className="th-label">Nom <SortIcon col="name" sortBy={sortBy} sortDir={sortDir} /></span></th>
                  <th className="th-sort" onClick={() => toggleSort('email')}><span className="th-label">Email <SortIcon col="email" sortBy={sortBy} sortDir={sortDir} /></span></th>
                  <th className="th-sort" onClick={() => toggleSort('role')}><span className="th-label">Role <SortIcon col="role" sortBy={sortBy} sortDir={sortDir} /></span></th>
                  <th>Plan</th>
                  <th>Statut</th>
                  <th className="th-sort" onClick={() => toggleSort('last_activity_at')}><span className="th-label">Derniere activite <SortIcon col="last_activity_at" sortBy={sortBy} sortDir={sortDir} /></span></th>
                  <th className="th-sort" onClick={() => toggleSort('created_at')}><span className="th-label">Inscrit le <SortIcon col="created_at" sortBy={sortBy} sortDir={sortDir} /></span></th>
                  <th style={{ width: 80 }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {users.map((u, i) => (
                  <motion.tr key={u.id} className={selected.has(u.id) ? 'row-selected' : ''} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.03, duration: 0.2 }}>
                    <td style={{ padding: '0.5rem 0.5rem 0.5rem 0.75rem' }}>
                      <input type="checkbox" className="row-checkbox" checked={selected.has(u.id)} onChange={() => toggleOne(u.id)} />
                    </td>
                    <td className="cell-id">{u.id}</td>
                    <td>
                      <div className="cell-name-wrap">
                        <UserAvatar name={u.name} avatarUrl={u.avatar_url} />
                        <div className="cell-name-info">
                          <div className="cell-name-row">
                            <span className="cell-name">{u.name}</span>
                            {u.oauth_provider === 'google'   && <GoogleIcon />}
                            {u.oauth_provider === 'facebook' && <FacebookIcon />}
                          </div>
                          {u.two_factor_enabled && (
                            <span className="micro-badge micro-badge--2fa" title="2FA actif"><ShieldCheck size={9} /> 2FA</span>
                          )}
                        </div>
                      </div>
                    </td>
                    <td>
                      <div className="cell-email-wrap">
                        <span className="cell-muted">{u.email}</span>
                        {u.email_verified_at
                          ? <CheckCircle size={12} className="icon-verified"   title="Email verifie" />
                          : <XCircle    size={12} className="icon-unverified" title="Email non verifie" />}
                      </div>
                    </td>
                    <td><span className={`role-badge role-${u.role}`}>{u.role.toUpperCase()}</span></td>
                    <td>
                      {u.role === 'user' ? (
                        <button
                          className="icon-action"
                          title={`Plan: ${u.plan ?? 'free'} — Modifier`}
                          onClick={() => openPlanModal(u)}
                          style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 0 }}
                        >
                          <PlanBadge plan={u.plan ?? 'free'} />
                        </button>
                      ) : <span className="cell-muted">—</span>}
                    </td>
                    <td><StatusDot status={u.user_status} /></td>
                    <td>
                      <div className="cell-activity">
                        <span className="cell-activity-time">{formatActivityDate(u.last_activity_at) ?? '--'}</span>
                        {u.last_activity_type && <span className="cell-activity-type">{u.last_activity_type}</span>}
                      </div>
                    </td>
                    <td className="cell-muted">{new Date(u.created_at).toLocaleDateString('fr-FR')}</td>
                    <td>
                      <div className="cell-actions">
                        <button className="icon-action" title="Modifier" onClick={() => openEdit(u)}><Pencil size={14} /></button>
                        <button
                          className={`icon-action ${u.is_active ? 'icon-action--danger' : 'icon-action--success'}`}
                          title={u.is_active ? 'Suspendre' : 'Reactiver'}
                          onClick={() => toggleUser.mutate(u.id)}
                          disabled={toggleUser.isPending}
                        >
                          {u.is_active ? <UserX size={14} /> : <UserCheck size={14} />}
                        </button>
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
                .reduce((acc, p, idx, arr) => {
                  if (idx > 0 && p - arr[idx - 1] > 1) acc.push('...');
                  acc.push(p);
                  return acc;
                }, [])
                .map((p, i) =>
                  p === '...'
                    ? <span key={`e-${i}`} className="pagination-ellipsis">...</span>
                    : <button key={p} className={p === page ? 'active' : ''} onClick={() => setPage(p)}>{p}</button>
                )}
              <button disabled={page >= meta.last_page} onClick={() => setPage(p => p + 1)}>Suiv.</button>
            </div>
          )}
        </>
      )}

      {modal && (
        <div className="modal-overlay" onClick={() => setModal(null)}>
          <div className="modal-box" onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <div className="modal-header-left">
                <UserAvatar name={modal.name} avatarUrl={modal.avatar_url} size={38} />
                <div>
                  <div className="modal-title">Modifier utilisateur</div>
                  <div className="modal-subtitle">{modal.email}</div>
                </div>
              </div>
              <button className="modal-close" onClick={() => setModal(null)}><X size={16} /></button>
            </div>
            <div className="modal-body">
              <div className="form-row-2">
                <label className="form-field"><span>Nom complet</span><input value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} /></label>
                <label className="form-field"><span>Telephone</span><input value={form.phone} onChange={e => setForm({ ...form, phone: e.target.value })} placeholder="+212..." /></label>
              </div>
              <label className="form-field"><span>Email</span><input type="email" value={form.email} onChange={e => setForm({ ...form, email: e.target.value })} /></label>
              <div className="form-row-2">
                <label className="form-field">
                  <span>Role</span>
                  <select value={form.role} onChange={e => setForm({ ...form, role: e.target.value })}>
                    <option value="user">Utilisateur</option>
                    <option value="expert">Expert</option>
                    <option value="admin">Admin</option>
                  </select>
                </label>
                <label className="form-field">
                  <span>Langue</span>
                  <select value={form.language} onChange={e => setForm({ ...form, language: e.target.value })}>
                    <option value="fr">Francais</option>
                    <option value="ar">Arabe</option>
                  </select>
                </label>
              </div>
            </div>
            <div className="modal-footer">
              <button className="btn-ghost" onClick={() => setModal(null)}>Annuler</button>
              <button className="btn-primary" onClick={saveEdit} disabled={updateUser.isPending}>Enregistrer</button>
            </div>
          </div>
        </div>
      )}

      {/* Plan change modal */}
      {planModal && (
        <div className="modal-overlay" onClick={() => setPlanModal(null)}>
          <motion.div className="modal-box" onClick={e => e.stopPropagation()} initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} transition={{ duration: 0.15 }}>
            <div className="modal-header">
              <div className="modal-header-left">
                <div style={{ width: 38, height: 38, borderRadius: '50%', background: 'linear-gradient(135deg,#2563eb,#7c3aed)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff' }}>
                  <Crown size={18} />
                </div>
                <div>
                  <div className="modal-title">Modifier le plan</div>
                  <div className="modal-subtitle">{planModal.name} — {planModal.email}</div>
                </div>
              </div>
              <button className="modal-close" onClick={() => setPlanModal(null)}><X size={16} /></button>
            </div>
            <div className="modal-body">
              <label className="form-field">
                <span>Plan</span>
                <select value={planForm.plan} onChange={e => {
                  const p = e.target.value;
                  const defaultCredits = p === 'pro' ? 3 : p === 'premium' ? 6 : 0;
                  const defaultExpiry = p !== 'free'
                    ? new Date(Date.now() + 30 * 86400000).toISOString().slice(0, 10)
                    : '';
                  setPlanForm({ plan: p, credits: defaultCredits, expiresAt: defaultExpiry });
                }}>
                  <option value="free">✦ Gratuit (0 consultation)</option>
                  <option value="pro">⚡ Pro (249 MAD/mois — 3 consultations)</option>
                  <option value="premium">👑 Premium (449 MAD/mois — 6 consultations)</option>
                </select>
              </label>
              <div className="form-row-2">
                <label className="form-field">
                  <span>Crédits consultations</span>
                  <input
                    type="number" min="0" max="100"
                    value={planForm.credits}
                    onChange={e => setPlanForm({ ...planForm, credits: e.target.value })}
                    disabled={planForm.plan === 'free'}
                  />
                </label>
                <label className="form-field">
                  <span>Expiration</span>
                  <input
                    type="date"
                    value={planForm.expiresAt}
                    onChange={e => setPlanForm({ ...planForm, expiresAt: e.target.value })}
                    disabled={planForm.plan === 'free'}
                  />
                </label>
              </div>
              <p style={{ fontSize: 12, color: 'var(--text-secondary)', margin: '8px 0 0', lineHeight: 1.5 }}>
                {planForm.plan === 'free'
                  ? 'Le plan Gratuit n\'inclut pas de consultations avec médecin.'
                  : `L'utilisateur aura ${planForm.credits} crédit(s) jusqu'au ${planForm.expiresAt || 'date non définie'}.`}
              </p>
            </div>
            <div className="modal-footer">
              <button className="btn-ghost" onClick={() => setPlanModal(null)}>Annuler</button>
              <button className="btn-primary" onClick={savePlan} disabled={changePlan.isPending}>
                Enregistrer le plan
              </button>
            </div>
          </motion.div>
        </div>
      )}

      {confirmSuspend && (
        <div className="modal-overlay" onClick={() => setConfirmSuspend(false)}>
          <motion.div className="modal-box modal-box--sm" onClick={e => e.stopPropagation()} initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} transition={{ duration: 0.15 }}>
            <div className="modal-header">
              <div className="modal-header-left">
                <div className="confirm-icon-wrap"><AlertTriangle size={20} color="#f59e0b" /></div>
                <div>
                  <div className="modal-title">Confirmer la suspension</div>
                  <div className="modal-subtitle">{selected.size} compte{selected.size > 1 ? 's' : ''} selectionne{selected.size > 1 ? 's' : ''}</div>
                </div>
              </div>
              <button className="modal-close" onClick={() => setConfirmSuspend(false)}><X size={16} /></button>
            </div>
            <div className="modal-body">
              <p className="confirm-text">
                Ces utilisateurs ne pourront plus se connecter tant que leur compte restera suspendu.
                Vous pouvez reactiver leur acces a tout moment depuis cette page.
              </p>
            </div>
            <div className="modal-footer">
              <button className="btn-ghost" onClick={() => setConfirmSuspend(false)}>Annuler</button>
              <button className="btn-danger" onClick={handleBulkSuspend} disabled={bulkSuspend.isPending}>
                <Ban size={14} /> Suspendre {selected.size} compte{selected.size > 1 ? 's' : ''}
              </button>
            </div>
          </motion.div>
        </div>
      )}
    </div>
  );
}
