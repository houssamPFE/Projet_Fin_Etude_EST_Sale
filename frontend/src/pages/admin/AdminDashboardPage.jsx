import { motion } from 'framer-motion';
import {
  Users, Briefcase, Clock, MessageSquare, TrendingUp, DollarSign,
  TrendingDown, ArrowRight, Bot, UserCheck, AlertTriangle, CheckCircle,
} from 'lucide-react';
import { Link } from 'react-router-dom';
import {
  AreaChart, Area, XAxis, YAxis, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, Legend,
} from 'recharts';
import { useAdminDashboard } from '../../hooks/useAdmin';
import { useAdminTheme } from '../../hooks/useAdminTheme';
import { ChartSkeleton, DonutSkeleton, MiniTableSkeleton } from '../../components/AdminSkeleton';
import './AdminDashboardPage.css';

const CARDS = [
  { key: 'total_users',          trendKey: 'users',   label: 'Utilisateurs',       icon: Users,         color: 'blue',   pulse: false },
  { key: 'total_experts',        trendKey: null,       label: 'Experts validés',     icon: Briefcase,     color: 'purple', pulse: false },
  { key: 'pending_experts',      trendKey: null,       label: 'En attente',          icon: Clock,         color: 'orange', pulse: false },
  { key: 'total_conversations',  trendKey: 'convs',   label: 'Conversations',       icon: MessageSquare, color: 'teal',   pulse: false },
  { key: 'active_conversations', trendKey: null,       label: 'Conv. actives',       icon: TrendingUp,    color: 'green',  pulse: true  },
  { key: 'total_revenue',        trendKey: 'revenue', label: 'Revenus (MAD)',        icon: DollarSign,    color: 'gold',   pulse: false },
];

const DONUT_COLORS = ['#2563eb', '#0d9488', '#7c3aed'];

const STATUS_LABELS = {
  open:   { label: 'Ouverte',  cls: 'badge-open'   },
  ai:     { label: 'IA',       cls: 'badge-ai'     },
  expert: { label: 'Expert',   cls: 'badge-expert' },
  closed: { label: 'Fermée',   cls: 'badge-closed' },
};

const PAYMENT_STATUS = {
  completed: { label: 'Payé',     cls: 'badge-paid'    },
  pending:   { label: 'En att.',  cls: 'badge-pending' },
  failed:    { label: 'Échoué',   cls: 'badge-failed'  },
  refunded:  { label: 'Remboursé',cls: 'badge-refunded'},
};

function TrendBadge({ trend }) {
  if (!trend) return null;
  const Icon = trend.up ? TrendingUp : TrendingDown;
  return (
    <span className={`trend-badge ${trend.up ? 'trend-up' : 'trend-down'}`}>
      <Icon size={10} />
      {trend.pct > 0 ? '+' : ''}{trend.pct}% cette sem.
    </span>
  );
}

function SectionCard({ title, action, to, children }) {
  return (
    <div className="dash-card">
      <div className="dash-card-header">
        <span className="dash-card-title">{title}</span>
        {to && (
          <Link to={to} className="dash-card-link">
            {action} <ArrowRight size={12} />
          </Link>
        )}
      </div>
      {children}
    </div>
  );
}

export default function AdminDashboardPage() {
  const { data: stats, isLoading, isError, refetch } = useAdminDashboard();
  const [adminDark] = useAdminTheme();
  const tooltipStyle = adminDark
    ? { fontSize: '0.75rem', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 6, background: '#1e293b', color: '#f8fafc', boxShadow: '0 4px 12px rgba(0,0,0,0.4)' }
    : { fontSize: '0.75rem', border: '1px solid #dee2e6', borderRadius: 3, background: '#fff', boxShadow: '0 2px 8px rgba(0,0,0,0.12)' };
  const tooltipLabelStyle = adminDark ? { color: '#94a3b8' } : { color: '#6c757d' };
  const tooltipItemStyle  = adminDark ? { color: '#f8fafc' } : { color: '#212529' };
  const axisTickStyle = adminDark ? '#475569' : '#9ca3af';

  const daily       = Array.isArray(stats?.daily_conversations)  ? stats.daily_conversations  : [];
  const routing     = (Array.isArray(stats?.routing_split)       ? stats.routing_split        : []).filter(r => r.value > 0);
  const recentConvs = Array.isArray(stats?.recent_conversations) ? stats.recent_conversations : [];
  const recentPays  = Array.isArray(stats?.recent_payments)      ? stats.recent_payments      : [];
  const pending     = Array.isArray(stats?.pending_applications) ? stats.pending_applications : [];
  const specialties = Array.isArray(stats?.top_specialties)      ? stats.top_specialties      : [];
  const trends      = stats?.trends ?? {};

  return (
    <div className="admin-dashboard">
      <div className="dash-page-header">
        <div>
          <h1>Tableau de bord</h1>
          <p>Vue d'ensemble de la plateforme</p>
        </div>
        <span className="dash-date">
          {new Date().toLocaleDateString('fr-FR', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' })}
        </span>
      </div>

      {/* ── Error state ── */}
      {isError && (
        <div className="dash-error">
          <span>Impossible de charger les données du tableau de bord.</span>
          <button onClick={() => refetch()} className="dash-retry-btn">Réessayer</button>
        </div>
      )}

      {/* ── KPI Cards ── */}
      <div className="stats-grid">
        {CARDS.map(({ key, trendKey, label, icon: Icon, color, pulse }, i) => (
          <motion.div
            key={key}
            className={`stat-card stat-card--${color}`}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: i * 0.07, type: 'spring', stiffness: 260, damping: 20 }}
          >
            <div className="stat-icon"><Icon size={22} /></div>
            <div className="stat-info">
              <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                <span className="stat-value">
                  {isLoading
                    ? <span className="sk-block" style={{ width: 48, height: 30 }} />
                    : key === 'total_revenue'
                      ? parseFloat(stats?.[key] || 0).toFixed(2)
                      : (stats?.[key] ?? 0)}
                </span>
                {pulse && !isLoading && (stats?.[key] ?? 0) > 0 && (
                  <span style={{ width: 8, height: 8, borderRadius: '50%', background: '#16a34a', display: 'inline-block', boxShadow: '0 0 0 0 rgba(22,163,74,0.4)', animation: 'livepulse 1.8s ease-out infinite' }} />
                )}
              </div>
              <span className="stat-label">{label}</span>
              {!isLoading && trendKey && <TrendBadge trend={trends[trendKey]} />}
            </div>
          </motion.div>
        ))}
      </div>

      {/* ── Pending alert ── */}
      {!isLoading && pending.length > 0 && (
        <div className="pending-alert">
          <AlertTriangle size={15} />
          <span>
            <strong>{pending.length} médecin{pending.length > 1 ? 's' : ''}</strong> en attente de validation
          </span>
          <div className="pending-names">
            {pending.map(e => (
              <span key={e.id} className="pending-chip">{e.user?.name} · {e.category?.name}</span>
            ))}
          </div>
          <Link to="/admin/experts" className="pending-btn">
            Valider maintenant <ArrowRight size={12} />
          </Link>
        </div>
      )}

      {/* ── Charts row ── */}
      <div className="dash-row">
        <SectionCard title="Conversations — 7 derniers jours">
          {isLoading ? <ChartSkeleton height={180} /> : (
            <div className="chart-wrap">
              <ResponsiveContainer width="100%" height={180}>
                <AreaChart data={daily} margin={{ top: 8, right: 8, left: -28, bottom: 0 }}>
                  <defs>
                    <linearGradient id="convGrad" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%"  stopColor="#2563eb" stopOpacity={0.15} />
                      <stop offset="95%" stopColor="#2563eb" stopOpacity={0}    />
                    </linearGradient>
                  </defs>
                  <XAxis dataKey="date" tick={{ fontSize: 11, fill: axisTickStyle }} axisLine={false} tickLine={false} />
                  <YAxis tick={{ fontSize: 11, fill: axisTickStyle }} axisLine={false} tickLine={false} allowDecimals={false} />
                  <Tooltip
                    contentStyle={tooltipStyle}
                    itemStyle={tooltipItemStyle}
                    labelStyle={tooltipLabelStyle}
                    formatter={(v) => [v, 'Conversations']}
                  />
                  <Area type="monotone" dataKey="total" stroke="#2563eb" strokeWidth={2} fill="url(#convGrad)" dot={{ r: 4, fill: '#2563eb', stroke: adminDark ? '#1e293b' : '#fff', strokeWidth: 2 }} />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          )}
        </SectionCard>

        <SectionCard title="Répartition IA / Expert">
          {isLoading ? <DonutSkeleton /> : routing.length === 0 ? (
            <div className="dash-empty">Aucune conversation pour l'instant.</div>
          ) : routing.length === 1 ? (
            <div className="routing-single">
              <div className="routing-single-circle" style={{ background: `linear-gradient(135deg, ${DONUT_COLORS[0]}, #60a5fa)` }}>
                <span>100%</span>
              </div>
              <span className="routing-single-label">{routing[0].name}</span>
            </div>
          ) : (
            <div className="chart-wrap" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <ResponsiveContainer width="100%" height={180}>
                <PieChart>
                  <Pie data={routing} cx="50%" cy="50%" innerRadius={52} outerRadius={76} paddingAngle={3} dataKey="value">
                    {routing.map((_, i) => (
                      <Cell key={i} fill={DONUT_COLORS[i % DONUT_COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip contentStyle={tooltipStyle} itemStyle={tooltipItemStyle} labelStyle={tooltipLabelStyle} formatter={(v, name) => [v, name]} />
                  <Legend iconType="circle" iconSize={8} wrapperStyle={{ fontSize: '0.75rem', color: adminDark ? '#94a3b8' : '#6b7280' }} />
                </PieChart>
              </ResponsiveContainer>
            </div>
          )}
        </SectionCard>
      </div>

      {/* ── Tables row ── */}
      <div className="dash-row">
        <SectionCard title="Dernières conversations" action="Voir tout" to="/admin/conversations">
          {isLoading ? <MiniTableSkeleton /> : recentConvs.length === 0 ? (
            <div className="dash-empty">Aucune conversation.</div>
          ) : (
            <table className="dash-table">
              <thead>
                <tr>
                  <th>Patient</th>
                  <th>Spécialité</th>
                  <th>Statut</th>
                  <th>Date</th>
                </tr>
              </thead>
              <tbody>
                {recentConvs.map(c => (
                  <tr key={c.id}>
                    <td className="td-name">{c.patient}</td>
                    <td>{c.category ?? '—'}</td>
                    <td>
                      <span className={`mini-badge ${STATUS_LABELS[c.status]?.cls ?? ''}`}>
                        {c.channel === 'ai' ? <Bot size={10} /> : <UserCheck size={10} />}
                        {STATUS_LABELS[c.status]?.label ?? c.status}
                      </span>
                    </td>
                    <td className="td-muted">{new Date(c.date).toLocaleDateString('fr-FR')}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </SectionCard>

        <SectionCard title="Derniers paiements" action="Voir tout" to="/admin/payments">
          {isLoading ? <MiniTableSkeleton /> : recentPays.length === 0 ? (
            <div className="dash-empty">Aucun paiement.</div>
          ) : (
            <table className="dash-table">
              <thead>
                <tr>
                  <th>Patient</th>
                  <th>Montant</th>
                  <th>Statut</th>
                  <th>Date</th>
                </tr>
              </thead>
              <tbody>
                {recentPays.map(p => (
                  <tr key={p.id}>
                    <td className="td-name">{p.patient}</td>
                    <td className="td-amount">{parseFloat(p.amount).toFixed(2)} {p.currency}</td>
                    <td>
                      <span className={`mini-badge ${PAYMENT_STATUS[p.status]?.cls ?? ''}`}>
                        {PAYMENT_STATUS[p.status]?.label ?? p.status}
                      </span>
                    </td>
                    <td className="td-muted">{new Date(p.date).toLocaleDateString('fr-FR')}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </SectionCard>
      </div>

      {/* ── Top specialties ── */}
      {specialties.length > 0 && (
        <SectionCard title="Top spécialités par activité">
          <div className="specialty-bars">
            {specialties.map((s, i) => {
              const max = specialties[0].total;
              return (
                <div key={i} className="spec-row">
                  <span className="spec-name">{s.name}</span>
                  <div className="spec-bar-wrap">
                    <div className="spec-bar" style={{ width: `${(s.total / max) * 100}%` }} />
                  </div>
                  <span className="spec-count">{s.total}</span>
                </div>
              );
            })}
          </div>
        </SectionCard>
      )}
    </div>
  );
}
