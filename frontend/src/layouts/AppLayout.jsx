import { Outlet, NavLink, useNavigate, useLocation } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import {
  LayoutDashboard, MessageSquare, Users, Bell,
  Settings, LogOut, Menu, X, Wallet, UserCog,
  ShieldCheck, CreditCard, FolderOpen, UserPlus,
  ChevronLeft, ChevronRight, BookOpen, Settings2,
  BadgeCheck, Sparkles, Clock, Sun, Moon, Crown,
} from 'lucide-react';
import { useState, useEffect } from 'react';
import { useAdminTheme } from '../hooks/useAdminTheme';
import { useQueryClient } from '@tanstack/react-query';
import useAuthStore from '../stores/authStore';
import useThemeStore from '../stores/themeStore';
import { usePlan, PLANS_META } from '../hooks/usePlan';
import api from '../lib/api';
import { useHeartbeat } from '../hooks/useHeartbeat';
import NexoraBackground from '../components/NexoraBackground';
import NotificationDropdown from '../components/NotificationDropdown';
import './AppLayout.css';

const userNavItems = [
  { to: '/dashboard', icon: LayoutDashboard, label: 'Tableau de bord' },
  { to: '/conversations', icon: MessageSquare, label: 'Conversations' },
  { to: '/experts', icon: Users, label: 'Experts' },
  { to: '/apply-expert', icon: UserPlus, label: 'Devenir Expert' },
  { to: '/notifications', icon: Bell, label: 'Notifications' },
  { to: '/settings', icon: Settings, label: 'Paramètres' },
];

const expertNavItems = [
  { to: '/expert/dashboard', icon: LayoutDashboard, label: 'Tableau de bord' },
  { to: '/conversations', icon: MessageSquare, label: 'Conversations' },
  { to: '/expert/profile', icon: UserCog, label: 'Mon profil' },
  { to: '/expert/wallet', icon: Wallet, label: 'Portefeuille' },
  { to: '/notifications', icon: Bell, label: 'Notifications' },
  { to: '/settings', icon: Settings, label: 'Paramètres' },
];

const adminNavItems = [
  { to: '/admin/dashboard', icon: LayoutDashboard, label: 'Tableau de bord' },
  { to: '/admin/users', icon: Users, label: 'Utilisateurs' },
  { to: '/admin/experts', icon: BadgeCheck, label: 'Médecins' },
  { to: '/admin/experts/pending', icon: Clock, label: 'En attente', badge: 'pending_experts' },
  { to: '/admin/conversations', icon: MessageSquare, label: 'Conversations' },
  { to: '/admin/categories', icon: FolderOpen, label: 'Spécialités' },
  { to: '/admin/knowledge', icon: BookOpen, label: 'Base de connaissances' },
  { to: '/admin/payments', icon: CreditCard, label: 'Paiements' },
  { type: 'section', label: 'Configuration' },
  { to: '/admin/ai', icon: Settings2, label: 'Configuration' },
  { to: '/admin/security', icon: ShieldCheck, label: 'Sécurité & 2FA' },
];

export default function AppLayout() {
  const { user, logout } = useAuthStore();
  const { theme } = useThemeStore();
  const { data: planData } = usePlan();
  const userPlan = planData?.plan ?? user?.plan ?? 'free';
  const planMeta = PLANS_META[userPlan] ?? PLANS_META.free;
  const navigate = useNavigate();
  const location = useLocation();
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [collapsed, setCollapsed] = useState(false);
  const [adminDark, toggleAdminTheme] = useAdminTheme();

  const isExpert = user?.role === 'expert';
  const isAdmin = user?.role === 'admin';
  const navItems = isAdmin ? adminNavItems : isExpert ? expertNavItems : userNavItems;

  const [pendingCount, setPendingCount] = useState(0);
  useEffect(() => {
    if (!isAdmin) return;
    api.get('/admin/experts/pending').then(r => {
      const arr = Array.isArray(r.data?.data) ? r.data.data : [];
      setPendingCount(arr.length);
    }).catch(() => { });
  }, [isAdmin]);

  // Keep online presence alive — sends heartbeat every 30 seconds
  useHeartbeat();

  const qc = useQueryClient();
  useEffect(() => {
    if (!isAdmin) return;
    const prefetch = (key, url) =>
      qc.prefetchQuery({ queryKey: key, queryFn: () => api.get(url).then(r => r.data), staleTime: 1000 * 60 * 5 });
    prefetch(['admin', 'dashboard'], '/admin/dashboard');
    prefetch(['admin', 'users', {}], '/admin/users');
    prefetch(['admin', 'experts', {}], '/admin/experts');
    prefetch(['admin', 'settings'], '/admin/settings');
    prefetch(['admin', 'categories'], '/admin/categories');
  }, [isAdmin, qc]);

  const handleLogout = async () => {
    await logout();
    navigate('/login');
  };

  return (
    <div className={`app-layout${isAdmin ? ` is-admin${adminDark ? ' admin-dark' : ''}` : ''}`}>
      {!isAdmin && <NexoraBackground />}
      <aside className={`sidebar ${sidebarOpen ? 'sidebar--open' : ''} ${collapsed ? 'sidebar--collapsed' : ''}`}>
        <div className="sidebar-inner">
          <div className="sidebar-header">
            <div className="sidebar-logo">
              <img src="/nexora1.png" alt="Nexora" className="sidebar-logo-img" />
              <span className="sidebar-logo-text">NEXORA</span>
            </div>
            <button className="sidebar-close" onClick={() => setSidebarOpen(false)}>
              <X size={20} />
            </button>
          </div>

          <nav className="sidebar-nav">
            {isAdmin && !collapsed && (
              <span className="sidebar-section-label">Menu administration</span>
            )}
            {navItems.map((item, i) => {
              if (item.type === 'section') {
                return collapsed ? null : <span key={`sec-${i}`} className="sidebar-section-label">{item.label}</span>;
              }
              const Icon = item.icon;
              return (
                <NavLink
                  key={item.to}
                  to={item.to}
                  end={item.to === '/admin/experts'}
                  title={collapsed ? item.label : undefined}
                  className={({ isActive }) => `sidebar-link ${isActive ? 'sidebar-link--active' : ''}`}
                  onClick={() => setSidebarOpen(false)}
                >
                  <Icon size={18} />
                  <span className="sidebar-link-label">{item.label}</span>
                  {item.badge === 'pending_experts' && pendingCount > 0 && (
                    <span className="sidebar-badge">{pendingCount}</span>
                  )}
                </NavLink>
              );
            })}
          </nav>

          {!isAdmin && !isExpert && (
            <div className="sidebar-cta">
              <NavLink to="/conversations/new" className="sidebar-cta-btn" onClick={() => setSidebarOpen(false)}>
                <Sparkles size={16} />
                <span>Consulter l'IA</span>
              </NavLink>
            </div>
          )}

          <div className="sidebar-footer">
            <div className="sidebar-user">
              <div className="sidebar-avatar" title={collapsed ? user?.name : undefined}>
                {user?.avatar_url
                  ? <img src={user.avatar_url} alt={user.name} style={{ width: '100%', height: '100%', borderRadius: '50%', objectFit: 'cover' }} />
                  : user?.name?.charAt(0)?.toUpperCase() || 'U'
                }
              </div>
              <div className="sidebar-user-info">
                <span className="sidebar-user-name">
                  {user?.name}
                  {(user?.role === 'expert' || user?.role === 'admin') && (
                    <BadgeCheck size={13} className="sidebar-verified-icon" />
                  )}
                </span>
                {user?.role === 'expert' && <span className="sidebar-user-role">Médecin</span>}
                {user?.role === 'admin' && <span className="sidebar-user-role">Administrateur</span>}
                {user?.role === 'user' && (
                  <NavLink to="/upgrade" className="sidebar-plan-badge" style={{ background: planMeta.gradient }}>
                    {planMeta.label}
                  </NavLink>
                )}
              </div>
            </div>
            <button className="sidebar-link sidebar-logout" title={collapsed ? 'Déconnexion' : undefined} onClick={handleLogout}>
              <LogOut size={20} />
              <span className="sidebar-link-label">Déconnexion</span>
            </button>
          </div>
        </div>

        {isAdmin && (
          <button
            className="sidebar-rail-toggle"
            onClick={() => setCollapsed(!collapsed)}
            title={collapsed ? 'Ouvrir le menu' : 'Réduire le menu'}
          >
            <motion.div
              animate={{ rotate: collapsed ? 180 : 0 }}
              transition={{ duration: 0.28, ease: [0.4, 0, 0.2, 1] }}
              style={{ display: 'flex', alignItems: 'center' }}
            >
              <ChevronLeft size={14} />
            </motion.div>
          </button>
        )}
      </aside>
      {sidebarOpen && <div className="sidebar-overlay" onClick={() => setSidebarOpen(false)} />}

      <main className={`app-main ${collapsed ? 'app-main--collapsed' : ''}`}>
        <header className="app-header">
          <button className="app-menu-btn" onClick={() => setSidebarOpen(true)}>
            <Menu size={22} />
          </button>
          {isAdmin && (
            <span className="admin-header-brand">Panneau d'administration</span>
          )}
          <div style={{ flex: 1 }} />
          <div className="app-header-actions">
            {isAdmin && (
              <button
                className="admin-theme-toggle"
                onClick={toggleAdminTheme}
                title={adminDark ? 'Passer en mode clair' : 'Passer en mode sombre'}
              >
                {adminDark ? <Sun size={16} /> : <Moon size={16} />}
              </button>
            )}
            {userPlan === 'free' && !isAdmin && !isExpert && location.pathname !== '/upgrade' && (
              <NavLink to="/upgrade" className="gopro-header-btn">
                <Crown size={14} />
                <span>Passer Pro</span>
              </NavLink>
            )}
            <NotificationDropdown />
          </div>
        </header>

        <motion.div
          className="app-content"
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -16 }}
          transition={{ duration: 0.35, ease: [0.4, 0, 0.2, 1] }}
        >
          <Outlet />
        </motion.div>


      </main>
    </div>
  );
}
