import { useState } from 'react';
import { Search, ToggleLeft, ToggleRight, Pencil } from 'lucide-react';
import { useAdminUsers, useToggleUser, useUpdateUser } from '../../hooks/useAdmin';
import CustomSelect from '../../components/CustomSelect';
import { TableSkeleton } from '../../components/AdminSkeleton';
import './AdminUsersPage.css';

export default function AdminUsersPage() {
  const [search, setSearch] = useState('');
  const [role, setRole]     = useState('');
  const [page, setPage]     = useState(1);

  const [editingUser, setEditingUser] = useState(null);
  const [editRole, setEditRole]       = useState('');

  const { data, isLoading } = useAdminUsers({ search, role, page });
  const toggleUser          = useToggleUser();
  const updateUser          = useUpdateUser();

  const users = Array.isArray(data?.data) ? data.data : (data?.data?.data ?? []);
  const meta  = data?.meta ?? {};

  const handleEdit = (user) => {
    setEditingUser(user);
    setEditRole(user.role);
  };

  const saveEdit = () => {
    if (!editingUser) return;
    updateUser.mutate({ id: editingUser.id, payload: { role: editRole } }, {
      onSuccess: () => {
        setEditingUser(null);
      }
    });
  };

  return (
    <div className="admin-users">
      <div className="page-header">
        <h1>Gestion des utilisateurs</h1>
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

      {isLoading ? (
        <TableSkeleton rows={8} cols={7} />
      ) : users.length === 0 ? (
        <div className="table-loading">Aucun utilisateur trouvé.</div>
      ) : (
        <>
          <div className="table-wrap">
            <table className="data-table">
              <thead>
                <tr>
                  <th style={{ width: 48 }}>#</th>
                  <th>Nom</th>
                  <th>Email</th>
                  <th>Rôle</th>
                  <th>Statut</th>
                  <th>Inscrit le</th>
                  <th style={{ width: 140 }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {users.map((u) => (
                  <tr key={u.id}>
                    <td className="cell-id">{u.id}</td>
                    <td className="cell-name">{u.name}</td>
                    <td className="cell-muted">{u.email}</td>
                    <td><span className={`role-badge role-${u.role}`}>{u.role}</span></td>
                    <td>
                      <span className={`status-pill ${u.is_active ? 'status-active' : 'status-inactive'}`}>
                        {u.is_active ? 'Actif' : 'Inactif'}
                      </span>
                    </td>
                    <td className="cell-muted">
                      {new Date(u.created_at).toLocaleDateString('fr-FR')}
                    </td>
                    <td className="cell-actions">
                      <button
                        className="action-btn action-btn--edit"
                        title="Modifier le rôle"
                        onClick={() => handleEdit(u)}
                      >
                        <Pencil size={13} />
                        Modifier
                      </button>
                      <button
                        className="action-btn action-btn--toggle"
                        onClick={() => toggleUser.mutate(u.id)}
                        disabled={toggleUser.isPending}
                        title={u.is_active ? 'Désactiver' : 'Activer'}
                      >
                        {u.is_active
                          ? <><ToggleRight size={13} /> Désactiver</>
                          : <><ToggleLeft  size={13} /> Activer</>}
                      </button>
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

      {editingUser && (
        <div className="edit-modal-overlay">
          <div className="edit-modal-content">
            <h3>Modifier l'utilisateur</h3>
            <p className="cell-muted" style={{ marginBottom: '1rem' }}>{editingUser.name} ({editingUser.email})</p>
            <div>
              <label style={{ display: 'block', marginBottom: '0.5rem', fontSize: '0.875rem', color: '#495057', fontWeight: 600 }}>Rôle</label>
              <select 
                value={editRole} 
                onChange={(e) => setEditRole(e.target.value)}
                style={{ width: '100%', padding: '0.5rem', borderRadius: '3px', border: '1px solid #ced4da', color: '#212529', backgroundColor: '#fff' }}
              >
                <option value="user">Utilisateur</option>
                <option value="expert">Expert</option>
                <option value="admin">Admin</option>
              </select>
            </div>
            <div className="edit-modal-actions">
              <button className="btn-cancel" onClick={() => setEditingUser(null)}>Annuler</button>
              <button className="btn-save" onClick={saveEdit} disabled={updateUser.isPending}>Enregistrer</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
