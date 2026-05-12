import { useState, useEffect } from 'react';
import { AlertTriangle, Loader2, RotateCcw, Search, X } from 'lucide-react';
import { useAdminSettings, useUpdateAdminSettings, useAdminUsers, useUpdateUserSecurity } from '../../hooks/useAdmin';
import CustomSelect from '../../components/CustomSelect';
import { SettingsSkeleton, TableSkeleton } from '../../components/AdminSkeleton';
import './AdminConfigPage.css';
import './AdminUsersPage.css';
import './AdminSecurityPage.css';

export default function AdminSecurityPage() {
  const { data: globalData, isLoading: isLoadingGlobal } = useAdminSettings();
  const updateSettings = useUpdateAdminSettings();
  const [localSettings, setLocalSettings] = useState({});

  const [search, setSearch] = useState('');
  const [role, setRole]     = useState('');
  const [page, setPage]     = useState(1);
  const [resetTarget, setResetTarget] = useState(null);

  const { data: usersData, isLoading: isLoadingUsers } = useAdminUsers({ search, role, page });
  const updateSecurity = useUpdateUserSecurity();

  const users = Array.isArray(usersData?.data) ? usersData.data : (usersData?.data?.data ?? []);
  const meta  = usersData?.meta ?? {};

  useEffect(() => {
    if (globalData?.data?.security) {
      const secSettings = globalData.data.security.reduce((acc, curr) => {
        acc[curr.key] = curr.value;
        return acc;
      }, {});
      setLocalSettings(secSettings);
    }
  }, [globalData]);

  const handleGlobalChange = (key, value) => {
    const newSettings = { ...localSettings, [key]: value };
    setLocalSettings(newSettings);
    updateSettings.mutate(newSettings);
  };

  const handleRequire2fa = (userId, value) => {
    updateSecurity.mutate({ userId, data: { require_2fa: value } });
  };

  const handleReset2fa = (user) => {
    setResetTarget(user);
  };

  const confirmReset2fa = () => {
    if (!resetTarget) return;

    updateSecurity.mutate(
      { userId: resetTarget.id, data: { reset_2fa: true } },
      { onSuccess: () => setResetTarget(null) },
    );
  };

  if (isLoadingGlobal) {
    return (
      <div className="admin-config-page">
        <div className="page-header"><div><h1>Sécurité & 2FA</h1></div></div>
        <SettingsSkeleton rows={2} />
        <div style={{ marginTop: '2rem' }}><TableSkeleton rows={6} cols={6} /></div>
      </div>
    );
  }

  const secSettingsArray = globalData?.data?.security || [];

  return (
    <div className="admin-config-page admin-users">
      <div className="page-header">
        <div>
          <h1>Sécurité & 2FA</h1>
          <p>Gérez les politiques d'authentification globales et par utilisateur.</p>
        </div>
      </div>

      {/* Global Settings Table */}
      <div className="table-wrap" style={{ marginBottom: '2rem' }}>
        <table className="config-table">
          <thead>
            <tr>
              <th>Politiques Globales</th>
              <th className="control-cell">Statut</th>
            </tr>
          </thead>
          <tbody>
            {secSettingsArray.map((setting) => (
              <tr key={setting.key}>
                <td>
                  <span className="setting-name">{setting.label}</span>
                  <span className="setting-desc">{setting.description}</span>
                </td>
                <td className="control-cell">
                  <label className="switch">
                    <input
                      type="checkbox"
                      checked={localSettings[setting.key] ?? setting.value}
                      onChange={(e) => handleGlobalChange(setting.key, e.target.checked)}
                      disabled={updateSettings.isPending}
                    />
                    <span className="slider"></span>
                  </label>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Users Table Header */}
      <h3 style={{ fontSize: '1rem', color: '#212529', marginBottom: '1rem' }}>Gestion 2FA par Utilisateur</h3>
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
            value={role}
            onChange={(e) => { setRole(e.target.value); setPage(1); }}
            placeholder="Tous les rôles"
            options={[
              { value: '',       label: 'Tous les rôles' },
              { value: 'user',   label: 'Utilisateur' },
              { value: 'expert', label: 'Expert' },
              { value: 'admin',  label: 'Admin' },
            ]}
          />
        </div>
        <span className="results-count">
          {meta.total ?? users.length} résultats
        </span>
      </div>

      {/* Users Data Table */}
      {isLoadingUsers ? (
        <div className="table-loading"><Loader2 className="spin" size={20} /></div>
      ) : users.length === 0 ? (
        <div className="table-loading">Aucun utilisateur trouvé.</div>
      ) : (
        <>
          <div className="table-wrap">
            <table className="data-table config-table">
              <thead>
                <tr>
                  <th>Utilisateur</th>
                  <th>Email</th>
                  <th>Rôle</th>
                  <th>Statut 2FA</th>
                  <th className="control-cell">Exiger 2FA</th>
                  <th style={{ width: 120, textAlign: 'right' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {users.map((u) => (
                  <tr key={u.id}>
                    <td className="cell-name">{u.name}</td>
                    <td className="cell-muted">{u.email}</td>
                    <td><span className={`role-badge role-${u.role}`}>{u.role}</span></td>
                    <td>
                      <span className={`status-pill ${u.two_factor_enabled ? 'status-active' : 'status-inactive'}`}>
                        {u.two_factor_enabled ? 'Activé' : 'Désactivé'}
                      </span>
                    </td>
                    <td className="control-cell">
                      <label className="switch">
                        <input
                          type="checkbox"
                          checked={u.require_2fa}
                          onChange={(e) => handleRequire2fa(u.id, e.target.checked)}
                          disabled={updateSecurity.isPending}
                        />
                        <span className="slider"></span>
                      </label>
                    </td>
                    <td style={{ textAlign: 'right' }}>
                      <button
                        className="btn-save-inline"
                        style={{ backgroundColor: '#dc3545', margin: 0, padding: '0.35rem 0.6rem' }}
                        title="Réinitialiser la 2FA"
                        onClick={() => handleReset2fa(u)}
                        disabled={updateSecurity.isPending || !u.two_factor_enabled}
                      >
                        <RotateCcw size={13} />
                        Réinitialiser
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Pagination */}
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

      {resetTarget && (
        <div className="security-modal-backdrop" role="presentation" onMouseDown={() => setResetTarget(null)}>
          <section
            className="security-confirm-modal"
            role="dialog"
            aria-modal="true"
            aria-labelledby="reset-2fa-title"
            onMouseDown={(e) => e.stopPropagation()}
          >
            <button
              type="button"
              className="security-modal-close"
              aria-label="Fermer"
              onClick={() => setResetTarget(null)}
              disabled={updateSecurity.isPending}
            >
              <X size={16} />
            </button>

            <div className="security-modal-icon">
              <AlertTriangle size={22} />
            </div>

            <div className="security-modal-body">
              <p className="security-modal-eyebrow">Action sensible</p>
              <h2 id="reset-2fa-title">Réinitialiser la 2FA de cet utilisateur ?</h2>
              <p>
                Cette action supprimera la configuration actuelle de double authentification pour{' '}
                <strong>{resetTarget.name}</strong>.
              </p>
              <div className="security-modal-user">
                <span>{resetTarget.email}</span>
                <small>{resetTarget.role}</small>
              </div>
              <p className="security-modal-note">
                Son compte restera actif et son mot de passe ne sera pas modifié. À sa prochaine connexion,
                il devra reconfigurer une nouvelle application 2FA avant d'accéder à son espace.
              </p>
            </div>

            <div className="security-modal-actions">
              <button
                type="button"
                className="security-modal-btn security-modal-btn--ghost"
                onClick={() => setResetTarget(null)}
                disabled={updateSecurity.isPending}
              >
                Annuler
              </button>
              <button
                type="button"
                className="security-modal-btn security-modal-btn--danger"
                onClick={confirmReset2fa}
                disabled={updateSecurity.isPending}
              >
                {updateSecurity.isPending ? <Loader2 className="spin" size={15} /> : <RotateCcw size={15} />}
                Réinitialiser la 2FA
              </button>
            </div>
          </section>
        </div>
      )}
    </div>
  );
}
