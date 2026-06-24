import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Shield, AlertTriangle, Loader2, RotateCcw,
  Search, X, ShieldCheck, ShieldOff, Users,
} from 'lucide-react';
import {
  useAdminSettings, useUpdateAdminSettings,
  useAdminUsers, useUpdateUserSecurity,
} from '../../hooks/useAdmin';
import CustomSelect from '../../components/CustomSelect';
import { SettingsSkeleton, TableSkeleton } from '../../components/AdminSkeleton';
import './AdminSecurityPage.css';

/* ── helpers ── */
const AVATAR_COLORS = ['#7c5cff','#0d9488','#ea580c','#16a34a','#dc2626','#2563eb'];
function avatarBg(name) { return AVATAR_COLORS[(name?.charCodeAt(0) ?? 0) % AVATAR_COLORS.length]; }

function UserAvatar({ name, avatarUrl, size = 28 }) {
  const [imgFailed, setImgFailed] = useState(false);
  const initials = name?.trim().split(/\s+/).map(n => n[0]).join('').slice(0, 2).toUpperCase() || '?';
  if (avatarUrl && !imgFailed) {
    return (
      <img
        src={avatarUrl} alt={name}
        className="sec-avatar sec-avatar--img"
        style={{ width: size, height: size }}
        onError={() => setImgFailed(true)}
      />
    );
  }
  return (
    <div className="sec-avatar" style={{ width: size, height: size, background: avatarBg(name), fontSize: size * 0.36 }}>
      {initials}
    </div>
  );
}

function RoleBadge({ role }) {
  return <span className={`sec-role sec-role--${role}`}>{role}</span>;
}

function TwoFaBadge({ enabled }) {
  return (
    <span className={`sec-2fa sec-2fa--${enabled ? 'on' : 'off'}`}>
      {enabled ? <><ShieldCheck size={11} /> Activé</> : <><ShieldOff size={11} /> Désactivé</>}
    </span>
  );
}

function Toggle({ checked, onChange, disabled }) {
  return (
    <label className="sec-toggle">
      <input type="checkbox" checked={checked} onChange={onChange} disabled={disabled} />
      <span className="sec-toggle-track" />
    </label>
  );
}

function SettingCard({ setting, value, onChange, disabled }) {
  return (
    <div className="sec-setting-card">
      <div className="sec-setting-ico"><Shield size={17} /></div>
      <div className="sec-setting-body">
        <div className="sec-setting-name">{setting.label}</div>
        <div className="sec-setting-desc">{setting.description}</div>
      </div>
      <Toggle
        checked={value ?? false}
        onChange={e => onChange(setting.key, e.target.checked)}
        disabled={disabled}
      />
    </div>
  );
}

function ResetModal({ user, onClose, onConfirm, isPending }) {
  return (
    <div className="sec-backdrop" onClick={onClose}>
      <motion.div
        className="sec-modal"
        initial={{ opacity: 0, scale: 0.96, y: 12 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        exit={{ opacity: 0, scale: 0.96, y: 12 }}
        transition={{ duration: 0.18 }}
        onClick={e => e.stopPropagation()}
      >
        <div className="sec-modal-head">
          <div className="sec-modal-ico"><AlertTriangle size={18} /></div>
          <div>
            <div className="sec-modal-title">Réinitialiser la 2FA</div>
            <div className="sec-modal-sub">{user.name}</div>
          </div>
          <button className="sec-modal-close" onClick={onClose} disabled={isPending}><X size={15} /></button>
        </div>
        <div className="sec-modal-body">
          <div className="sec-warn">
            <AlertTriangle size={14} />
            <span>
              La configuration 2FA de <strong>{user.name}</strong> sera supprimée.
              Il devra reconfigurer son application d'authentification à sa prochaine connexion.
            </span>
          </div>
          <div className="sec-user-info">
            <span className="sec-user-email">{user.email}</span>
            <RoleBadge role={user.role} />
          </div>
        </div>
        <div className="sec-modal-foot">
          <button className="sec-btn-cancel" onClick={onClose} disabled={isPending}>Annuler</button>
          <button className="sec-btn-danger" onClick={onConfirm} disabled={isPending}>
            {isPending
              ? <><Loader2 size={13} className="sec-spin" /> Réinitialisation…</>
              : <><RotateCcw size={13} /> Réinitialiser</>}
          </button>
        </div>
      </motion.div>
    </div>
  );
}

/* ═══════════════════════════════════════════════════ */
export default function AdminSecurityPage() {
  const { data: globalData, isLoading: isLoadingGlobal } = useAdminSettings();
  const updateSettings = useUpdateAdminSettings();
  const [localSettings, setLocalSettings] = useState({});

  const [search,         setSearch]         = useState('');
  const [debouncedSearch, setDebouncedSearch] = useState('');
  const [role,           setRole]           = useState('');
  const [page,           setPage]           = useState(1);
  const [resetTarget,    setResetTarget]    = useState(null);

  useEffect(() => {
    const t = setTimeout(() => setDebouncedSearch(search), 300);
    return () => clearTimeout(t);
  }, [search]);

  const userParams = { page, ...(debouncedSearch && { search: debouncedSearch }), ...(role && { role }) };
  const { data: usersData, isLoading: isLoadingUsers, isFetching } = useAdminUsers(userParams);
  const updateSecurity = useUpdateUserSecurity();

  const users = Array.isArray(usersData?.data) ? usersData.data : (usersData?.data?.data ?? []);
  const meta  = usersData?.meta ?? {};

  useEffect(() => {
    if (globalData?.data?.security) {
      setLocalSettings(globalData.data.security.reduce((acc, s) => ({ ...acc, [s.key]: s.value }), {}));
    }
  }, [globalData]);

  const handleGlobalChange = (key, value) => {
    const next = { ...localSettings, [key]: value };
    setLocalSettings(next);
    updateSettings.mutate(next);
  };

  const handleRequire2fa = (userId, value) => {
    updateSecurity.mutate({ userId, data: { require_2fa: value } });
  };

  const confirmReset = () => {
    if (!resetTarget) return;
    updateSecurity.mutate(
      { userId: resetTarget.id, data: { reset_2fa: true } },
      { onSuccess: () => setResetTarget(null) },
    );
  };

  const secSettings  = globalData?.data?.security ?? [];
  const rangeStart   = meta.current_page ? (meta.current_page - 1) * 20 + 1 : 1;
  const rangeEnd     = meta.current_page ? Math.min(meta.current_page * 20, meta.total ?? 0) : users.length;

  return (
    <div className="sec-page">

      {/* Header */}
      <motion.div className="sec-head"
        initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.25 }}
      >
        <div className="sec-head-ico"><Shield size={20} /></div>
        <div>
          <h1 className="sec-head-title">Sécurité & 2FA</h1>
          <p className="sec-head-sub">Politiques d'authentification globales et gestion 2FA par utilisateur</p>
        </div>
      </motion.div>

      {/* Global policies */}
      <motion.section className="sec-section"
        initial={{ opacity: 0, y: 6 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.06, duration: 0.25 }}
      >
        <div className="sec-section-head">
          <span className="sec-section-title">Politiques globales</span>
          <span className="sec-section-count">{secSettings.length} politique{secSettings.length !== 1 ? 's' : ''}</span>
        </div>
        {isLoadingGlobal ? (
          <div className="sec-skeleton-wrap"><SettingsSkeleton rows={2} /></div>
        ) : (
          <div className="sec-settings-list">
            {secSettings.map((s, idx) => (
              <motion.div key={s.key}
                initial={{ opacity: 0, y: 4 }} animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.08 + idx * 0.05 }}
              >
                <SettingCard
                  setting={s}
                  value={localSettings[s.key]}
                  onChange={handleGlobalChange}
                  disabled={updateSettings.isPending}
                />
              </motion.div>
            ))}
          </div>
        )}
      </motion.section>

      {/* Per-user 2FA */}
      <motion.section className="sec-section"
        initial={{ opacity: 0, y: 6 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.1, duration: 0.25 }}
      >
        <div className="sec-section-head">
          <span className="sec-section-title">Gestion 2FA par utilisateur</span>
          <span className="sec-section-count">{(meta.total ?? users.length).toLocaleString('fr-FR')} utilisateur{(meta.total ?? users.length) !== 1 ? 's' : ''}</span>
        </div>

        {/* Toolbar */}
        <div className="sec-toolbar">
          <div className="sec-search-wrap">
            <Search size={13} className="sec-search-ico" />
            <input
              className="sec-search"
              placeholder="Rechercher par nom ou email…"
              value={search}
              onChange={e => { setSearch(e.target.value); setPage(1); }}
            />
            {search && (
              <button className="sec-search-clear" onClick={() => { setSearch(''); setPage(1); }}>
                <X size={12} />
              </button>
            )}
          </div>
          <div className="sec-select-wrap">
            <CustomSelect
              value={role}
              onChange={e => { setRole(e.target.value); setPage(1); }}
              placeholder="Tous les rôles"
              options={[
                { value: '',      label: 'Tous les rôles' },
                { value: 'user',   label: 'Utilisateur' },
                { value: 'expert', label: 'Médecin' },
                { value: 'admin',  label: 'Admin' },
              ]}
            />
          </div>
        </div>

        {/* Fetching progress bar */}
        {isFetching && !isLoadingUsers && (
          <div className="sec-fetch-bar"><div className="sec-fetch-bar-inner" /></div>
        )}

        {/* Table */}
        <div className="sec-table-wrap">
          {isLoadingUsers ? (
            <TableSkeleton rows={6} cols={5} />
          ) : users.length === 0 ? (
            <div className="sec-empty">
              <Users size={28} className="sec-empty-ico" />
              <p>Aucun utilisateur trouvé</p>
            </div>
          ) : (
            <table className="sec-table">
              <thead>
                <tr>
                  <th>Utilisateur</th>
                  <th>Email</th>
                  <th>Rôle</th>
                  <th>Statut 2FA</th>
                  <th className="sec-th-center">Exiger 2FA</th>
                  <th className="sec-th-right">Actions</th>
                </tr>
              </thead>
              <tbody>
                <AnimatePresence mode="popLayout" initial={false}>
                  {users.map((u, idx) => (
                    <motion.tr key={u.id}
                      initial={{ opacity: 0, y: 6 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0 }}
                      transition={{ delay: idx * 0.03, duration: 0.2 }}
                    >
                      <td>
                        <div className="sec-ucell">
                          <UserAvatar name={u.name} avatarUrl={u.avatar_url} />
                          <span className="sec-uname">{u.name}</span>
                        </div>
                      </td>
                      <td className="sec-email">{u.email}</td>
                      <td><RoleBadge role={u.role} /></td>
                      <td><TwoFaBadge enabled={u.two_factor_enabled} /></td>
                      <td className="sec-td-center">
                        <Toggle
                          checked={u.require_2fa}
                          onChange={e => handleRequire2fa(u.id, e.target.checked)}
                          disabled={updateSecurity.isPending}
                        />
                      </td>
                      <td className="sec-td-right">
                        <button
                          className="sec-btn-reset"
                          onClick={() => setResetTarget(u)}
                          disabled={updateSecurity.isPending || !u.two_factor_enabled}
                        >
                          <RotateCcw size={12} />
                          Réinitialiser
                        </button>
                      </td>
                    </motion.tr>
                  ))}
                </AnimatePresence>
              </tbody>
            </table>
          )}
        </div>

        {/* Pagination */}
        {meta.last_page > 1 && (
          <div className="sec-pagination">
            <span className="sec-pag-info">
              Affichage <strong>{rangeStart}–{rangeEnd}</strong> sur {(meta.total ?? 0).toLocaleString('fr-FR')}
            </span>
            <div className="sec-pag-btns">
              <button className="sec-pbtn" disabled={page <= 1} onClick={() => setPage(p => p - 1)}>‹</button>
              {Array.from({ length: meta.last_page }, (_, i) => i + 1)
                .filter(p => p === 1 || p === meta.last_page || Math.abs(p - page) <= 1)
                .reduce((acc, p, i, arr) => { if (i > 0 && p - arr[i-1] > 1) acc.push('…'); acc.push(p); return acc; }, [])
                .map((p, i) => p === '…'
                  ? <span key={`e${i}`} className="sec-pellipsis">…</span>
                  : <button key={p} className={`sec-pbtn ${page === p ? 'sec-pbtn--on' : ''}`} onClick={() => setPage(p)}>{p}</button>
                )}
              <button className="sec-pbtn" disabled={page >= meta.last_page} onClick={() => setPage(p => p + 1)}>›</button>
            </div>
          </div>
        )}
      </motion.section>

      {/* Confirm modal */}
      <AnimatePresence>
        {resetTarget && (
          <ResetModal
            user={resetTarget}
            onClose={() => setResetTarget(null)}
            onConfirm={confirmReset}
            isPending={updateSecurity.isPending}
          />
        )}
      </AnimatePresence>
    </div>
  );
}
