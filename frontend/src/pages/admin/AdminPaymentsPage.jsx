import { useState, useMemo } from 'react';
import { motion } from 'framer-motion';
import {
  DollarSign, CreditCard, Clock, TrendingUp,
  Search, ChevronLeft, ChevronRight, Zap, Crown, Sparkles,
} from 'lucide-react';
import { useAdminPayments } from '../../hooks/useAdmin';
import CustomSelect from '../../components/CustomSelect';
import { TableSkeleton } from '../../components/AdminSkeleton';
import './AdminPaymentsPage.css';

/* ── helpers ── */
const AVATAR_COLORS = ['#7c5cff','#0d9488','#ea580c','#16a34a','#dc2626','#ca8a04','#2563eb'];
function avatarBg(name) { return AVATAR_COLORS[(name?.charCodeAt(0) ?? 0) % AVATAR_COLORS.length]; }

function UserAvatar({ name, size = 28 }) {
  const initials = name?.trim().split(/\s+/).map(n => n[0]).join('').slice(0, 2).toUpperCase() || '?';
  return (
    <div className="pay-avatar" style={{ width: size, height: size, background: avatarBg(name), fontSize: size * 0.36 }}>
      {initials}
    </div>
  );
}

const STATUS_CFG = {
  completed: { label: 'Complété',    dot: '#16a34a', bg: '#dcfce7', color: '#15803d' },
  pending:   { label: 'En attente',  dot: '#f59e0b', bg: '#fef3c7', color: '#92400e' },
  failed:    { label: 'Échoué',      dot: '#dc2626', bg: '#fee2e2', color: '#991b1b' },
  refunded:  { label: 'Remboursé',   dot: '#2563eb', bg: '#dbeafe', color: '#1d4ed8' },
};

function StatusPill({ status }) {
  const cfg = STATUS_CFG[status] ?? { label: status, dot: '#94a3b8', bg: '#f1f5f9', color: '#475569' };
  return (
    <span className="pay-pill" style={{ background: cfg.bg, color: cfg.color }}>
      <span className="pay-pill-dot" style={{ background: cfg.dot }} />
      {cfg.label}
    </span>
  );
}

function ProviderBadge({ provider }) {
  return (
    <span className={`pay-provider pay-provider--${provider}`}>
      {provider === 'stripe' ? '⚡ Stripe' : '🏦 CMI'}
    </span>
  );
}

const TYPE_CFG = {
  pro:           { label: 'Pro',           icon: Zap,      color: '#2563eb', bg: 'rgba(37,99,235,0.12)' },
  premium:       { label: 'Premium',       icon: Crown,    color: '#7c3aed', bg: 'rgba(124,58,237,0.12)' },
  extra:         { label: 'Crédit extra',  icon: Sparkles, color: '#0d9488', bg: 'rgba(13,148,136,0.12)' },
  doctor_payout: { label: 'Médecin',       icon: DollarSign, color: '#ea580c', bg: 'rgba(234,88,12,0.12)' },
  other:         { label: 'Autre',         icon: DollarSign, color: '#6b7280', bg: 'rgba(107,114,128,0.1)' },
};

function TypeBadge({ type }) {
  const cfg = TYPE_CFG[type] ?? TYPE_CFG.other;
  const Icon = cfg.icon;
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 4,
      padding: '3px 8px', borderRadius: 99, fontSize: 11, fontWeight: 600,
      background: cfg.bg, color: cfg.color,
    }}>
      <Icon size={10} />
      {cfg.label}
    </span>
  );
}

function KpiCard({ label, value, sub, color, icon: Icon, isLoading }) {
  return (
    <div className={`pay-kpi pay-kpi--${color}`}>
      <div className="pay-kpi-ico"><Icon size={18} /></div>
      <div className="pay-kpi-body">
        <div className="pay-kpi-val">{isLoading ? '…' : value}</div>
        {sub && <div className="pay-kpi-sub">{sub}</div>}
        <div className="pay-kpi-lbl">{label}</div>
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════════════ */
export default function AdminPaymentsPage() {
  const [status,      setStatus]      = useState('');
  const [provider,    setProvider]    = useState('');
  const [paymentType, setPaymentType] = useState('');
  const [search,      setSearch]      = useState('');
  const [page,        setPage]        = useState(1);

  const { data, isLoading } = useAdminPayments({ status, provider, payment_type: paymentType, search, page });

  const payments = useMemo(() => {
    const raw = data?.data;
    return Array.isArray(raw) ? raw : (raw?.data ?? []);
  }, [data]);

  const meta  = data?.meta  ?? {};
  const stats = data?.stats ?? {};

  const reset = () => setPage(1);

  const rangeStart = meta.current_page ? (meta.current_page - 1) * 20 + 1 : 1;
  const rangeEnd   = meta.current_page ? Math.min(meta.current_page * 20, meta.total ?? 0) : payments.length;

  const fmt = (n) => parseFloat(n || 0).toLocaleString('fr-FR', { minimumFractionDigits: 2, maximumFractionDigits: 2 });

  return (
    <div className="pay-page">

      {/* Header */}
      <motion.div className="pay-head"
        initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.25 }}
      >
        <div>
          <h1 className="pay-head-title">Paiements</h1>
          <p className="pay-head-sub">Suivi des transactions patients — Stripe &amp; CMI</p>
        </div>
      </motion.div>

      {/* KPIs row 1 */}
      <motion.div className="pay-kpis"
        initial={{ opacity: 0, y: -6 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.05, duration: 0.25 }}
      >
        <KpiCard
          label="Revenus totaux" color="amber"
          value={`${fmt(stats.total_revenue)} MAD`}
          icon={TrendingUp} isLoading={isLoading}
        />
        <KpiCard
          label="Abonnements (Pro+Premium)" color="violet"
          value={`${fmt(stats.subscription_revenue)} MAD`}
          icon={Crown} isLoading={isLoading}
        />
        <KpiCard
          label="Stripe" color="blue"
          value={`${fmt(stats.stripe_revenue)} MAD`}
          icon={CreditCard} isLoading={isLoading}
        />
        <KpiCard
          label="CMI" color="green"
          value={`${fmt(stats.cmi_revenue)} MAD`}
          icon={CreditCard} isLoading={isLoading}
        />
      </motion.div>

      {/* KPIs row 2 — plan breakdown */}
      <motion.div className="pay-kpis"
        style={{ marginTop: 0 }}
        initial={{ opacity: 0, y: -4 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.08, duration: 0.25 }}
      >
        <KpiCard
          label="Abonnements Pro" color="blue"
          value={stats.plan_breakdown?.pro ?? 0}
          sub="transactions"
          icon={Zap} isLoading={isLoading}
        />
        <KpiCard
          label="Abonnements Premium" color="violet"
          value={stats.plan_breakdown?.premium ?? 0}
          sub="transactions"
          icon={Crown} isLoading={isLoading}
        />
        <KpiCard
          label="Crédits extra" color="amber"
          value={stats.plan_breakdown?.extra ?? 0}
          sub={`${fmt(stats.extra_revenue)} MAD`}
          icon={Sparkles} isLoading={isLoading}
        />
        <KpiCard
          label="En attente" color="orange"
          value={stats.pending_count ?? 0}
          sub="transactions"
          icon={Clock} isLoading={isLoading}
        />
      </motion.div>

      {/* Table card */}
      <div className="pay-card">

        {/* Toolbar */}
        <div className="pay-toolbar">
          <div className="pay-search-wrap">
            <Search size={13} className="pay-search-ico" />
            <input
              className="pay-search"
              placeholder="Rechercher un utilisateur…"
              value={search}
              onChange={e => { setSearch(e.target.value); reset(); }}
            />
          </div>
          <div className="pay-select-wrap">
            <CustomSelect
              value={status}
              onChange={e => { setStatus(e.target.value); reset(); }}
              placeholder="Tous les statuts"
              options={[
                { value: 'completed', label: 'Complété'   },
                { value: 'pending',   label: 'En attente' },
                { value: 'failed',    label: 'Échoué'     },
                { value: 'refunded',  label: 'Remboursé'  },
              ]}
            />
          </div>
          <div className="pay-select-wrap">
            <CustomSelect
              value={provider}
              onChange={e => { setProvider(e.target.value); reset(); }}
              placeholder="Tous les providers"
              options={[
                { value: 'stripe', label: '⚡ Stripe' },
                { value: 'cmi',    label: '🏦 CMI'    },
              ]}
            />
          </div>
          <div className="pay-select-wrap">
            <CustomSelect
              value={paymentType}
              onChange={e => { setPaymentType(e.target.value); reset(); }}
              placeholder="Tous les types"
              options={[
                { value: 'pro',     label: '⚡ Pro (249 MAD)'    },
                { value: 'premium', label: '👑 Premium (449 MAD)' },
                { value: 'extra',   label: '✦ Crédit extra (89 MAD)' },
              ]}
            />
          </div>
          <span className="pay-result-count">
            {(meta.total ?? payments.length).toLocaleString('fr-FR')} résultat{(meta.total ?? payments.length) !== 1 ? 's' : ''}
          </span>
        </div>

        {/* Table */}
        <div className="pay-table-wrap">
          {isLoading ? (
            <TableSkeleton rows={8} cols={7} />
          ) : payments.length === 0 ? (
            <div className="pay-empty">
              <DollarSign size={28} className="pay-empty-ico" />
              <p>Aucun paiement trouvé</p>
            </div>
          ) : (
            <table className="pay-table">
              <thead>
                <tr>
                  <th className="pay-th-id">#</th>
                  <th>Utilisateur</th>
                  <th>Type</th>
                  <th>Montant</th>
                  <th>Provider</th>
                  <th>Statut</th>
                  <th>Date</th>
                </tr>
              </thead>
              <tbody>
                {payments.map((p, idx) => (
                  <motion.tr
                    key={p.id}
                    initial={{ opacity: 0, y: 4 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: idx * 0.025 }}
                  >
                    <td className="pay-td-id">#{p.id}</td>

                    <td>
                      <div className="pay-ucell">
                        <UserAvatar name={p.user?.name} />
                        <div>
                          <div className="pay-uname" style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                            {p.user?.name ?? '—'}
                            {p.user?.plan && p.user.plan !== 'free' && (
                              <span style={{
                                fontSize: 10, fontWeight: 700, padding: '1px 6px', borderRadius: 99,
                                background: p.user.plan === 'premium' ? 'rgba(124,58,237,0.15)' : 'rgba(37,99,235,0.15)',
                                color: p.user.plan === 'premium' ? '#7c3aed' : '#2563eb',
                              }}>
                                {p.user.plan.toUpperCase()}
                              </span>
                            )}
                          </div>
                          <div className="pay-uemail">{p.user?.email ?? ''}</div>
                        </div>
                      </div>
                    </td>

                    <td><TypeBadge type={p.payment_type ?? 'other'} /></td>

                    <td>
                      <span className="pay-amount">{fmt(p.amount)}</span>
                      <span className="pay-currency">{p.currency ?? 'MAD'}</span>
                    </td>

                    <td><ProviderBadge provider={p.provider} /></td>
                    <td><StatusPill status={p.status} /></td>

                    <td>
                      <div className="pay-date">{p.paid_at ? new Date(p.paid_at).toLocaleDateString('fr-FR') : '—'}</div>
                      {p.paid_at && (
                        <div className="pay-date-time">{new Date(p.paid_at).toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' })}</div>
                      )}
                    </td>
                  </motion.tr>
                ))}
              </tbody>
            </table>
          )}
        </div>

        {/* Pagination */}
        {meta.last_page > 1 && (
          <div className="pay-pagination">
            <span className="pay-pag-info">
              Affichage <strong>{rangeStart}–{rangeEnd}</strong> sur {(meta.total ?? 0).toLocaleString('fr-FR')}
            </span>
            <div className="pay-pag-btns">
              <button className="pay-pbtn" disabled={page <= 1} onClick={() => setPage(p => p - 1)}>
                <ChevronLeft size={14} />
              </button>
              {Array.from({ length: meta.last_page }, (_, i) => i + 1)
                .filter(p => p === 1 || p === meta.last_page || Math.abs(p - page) <= 1)
                .reduce((acc, p, i, arr) => { if (i > 0 && p - arr[i-1] > 1) acc.push('…'); acc.push(p); return acc; }, [])
                .map((p, i) => p === '…'
                  ? <span key={`e${i}`} className="pay-pellipsis">…</span>
                  : <button key={p} className={`pay-pbtn ${page === p ? 'pay-pbtn--on' : ''}`} onClick={() => setPage(p)}>{p}</button>
                )}
              <button className="pay-pbtn" disabled={page >= meta.last_page} onClick={() => setPage(p => p + 1)}>
                <ChevronRight size={14} />
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
