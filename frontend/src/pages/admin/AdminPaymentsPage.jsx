import { useState } from 'react';
import { DollarSign, CreditCard } from 'lucide-react';
import { useAdminPayments } from '../../hooks/useAdmin';
import CustomSelect from '../../components/CustomSelect';
import { TableSkeleton, StatCardsSkeleton } from '../../components/AdminSkeleton';
import './AdminPaymentsPage.css';

const STATUS_COLOR = { completed: 'green', pending: 'orange', failed: 'red', refunded: 'blue' };

export default function AdminPaymentsPage() {
  const [status, setStatus]   = useState('');
  const [provider, setProvider] = useState('');
  const [page, setPage]       = useState(1);

  const { data, isLoading } = useAdminPayments({ status, provider, page });
  const payments = Array.isArray(data?.data) ? data.data : (data?.data?.data ?? []);
  const meta     = data?.meta ?? {};
  const stats    = data?.stats ?? {};

  return (
    <div className="admin-payments">
      <div className="page-header">
        <h1>Paiements</h1>
      </div>

      <div className="revenue-cards">
        {[
          { label: 'Revenus totaux',  value: `${parseFloat(stats.total_revenue  || 0).toFixed(2)} MAD`, icon: DollarSign, color: 'gold' },
          { label: 'Via Stripe',      value: `${parseFloat(stats.stripe_revenue || 0).toFixed(2)} MAD`, icon: CreditCard,  color: 'purple' },
          { label: 'Via CMI',         value: `${parseFloat(stats.cmi_revenue    || 0).toFixed(2)} MAD`, icon: CreditCard,  color: 'teal' },
          { label: 'En attente',      value: stats.pending_count   ?? 0,                                icon: DollarSign, color: 'orange' },
        ].map(({ label, value, icon: Icon, color }) => (
          <div key={label} className={`revenue-card revenue-card--${color}`}>
            <div className="revenue-icon"><Icon size={20} /></div>
            <div>
              <span className="revenue-value">{value}</span>
              <span className="revenue-label">{label}</span>
            </div>
          </div>
        ))}
      </div>

      <div className="filters-bar">
        <CustomSelect
          value={status}
          onChange={(e) => { setStatus(e.target.value); setPage(1); }}
          placeholder="Tous les statuts"
          options={[
            { value: 'pending', label: 'En attente' },
            { value: 'completed', label: 'Complété' },
            { value: 'failed', label: 'Échoué' },
            { value: 'refunded', label: 'Remboursé' },
          ]}
        />
        <CustomSelect
          value={provider}
          onChange={(e) => { setProvider(e.target.value); setPage(1); }}
          placeholder="Tous les providers"
          options={[
            { value: 'stripe', label: 'Stripe' },
            { value: 'cmi', label: 'CMI' },
          ]}
        />
      </div>

      {isLoading ? (
        <TableSkeleton rows={8} cols={6} />
      ) : (
        <>
          <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>#</th>
                <th>Utilisateur</th>
                <th>Expert</th>
                <th>Montant</th>
                <th>Provider</th>
                <th>Statut</th>
                <th>Date</th>
              </tr>
            </thead>
            <tbody>
              {payments.map((p) => (
                <tr key={p.id}>
                  <td className="text-muted">{p.id}</td>
                  <td>{p.user?.name}</td>
                  <td>{p.expert?.name ?? '—'}</td>
                  <td className="amount">{parseFloat(p.amount).toFixed(2)} {p.currency}</td>
                  <td><span className={`provider-badge provider-${p.provider}`}>{p.provider?.toUpperCase()}</span></td>
                  <td><span className={`status-badge status-${STATUS_COLOR[p.status] ?? 'gray'}`}>{p.status}</span></td>
                  <td className="text-muted">{p.paid_at ? new Date(p.paid_at).toLocaleDateString('fr-FR') : '—'}</td>
                </tr>
              ))}
            </tbody>
          </table>
          </div>

          {meta.last_page > 1 && (
            <div className="pagination">
              <button disabled={page <= 1} onClick={() => setPage(p => p - 1)}>Préc.</button>
              <span>{page} / {meta.last_page}</span>
              <button disabled={page >= meta.last_page} onClick={() => setPage(p => p + 1)}>Suiv.</button>
            </div>
          )}
        </>
      )}
    </div>
  );
}
