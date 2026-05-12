import { Outlet, NavLink, useNavigate } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import {
  LayoutDashboard, MessageSquare, Users, Bell,
  Settings, LogOut, Menu, X, Wallet, UserCog,
  ShieldCheck, CreditCard, FolderOpen, UserPlus,
  ChevronLeft, ChevronRight, BookOpen, Cpu, Server,
} from 'lucide-react';
import { useState, useEffect } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import useAuthStore from '../stores/authStore';
import api from '../lib/api';
import { useHeartbeat } from '../hooks/useHeartbeat';
import NexoraBackground from '../components/NexoraBackground';
import NotificationDropdown from '../components/NotificationDropdown';
import './AppLayout.css';

const userNavItems = [
  { to: '/dashboard',     icon: LayoutDashboard, label: 'Tableau de bord' },
  { to: '/conversations', icon: MessageSquare,   label: 'Conversations' },
  { to: '/experts',       icon: Users,           label: 'Experts' },
  { to: '/apply-expert',  icon: UserPlus,        label: 'Devenir Expert' },
  { to: '/notifications', icon: Bell,            label: 'Notifications' },
  { to: '/settings',      icon: Settings,        label: 'Paramètres' },
];

const expertNavItems = [
  { to: '/expert/dashboard', icon: LayoutDashboard, label: 'Tableau de bord' },
  { to: '/conversations',    icon: MessageSquare,   label: 'Conversations' },
  { to: '/expert/profile',   icon: UserCog,         label: 'Mon profil' },
  { to: '/expert/wallet',    icon: Wallet,          label: 'Portefeuille' },
  { to: '/notifications',    icon: Bell,            label: 'Notifications' },
  { to: '/settings',         icon: Settings,        label: 'Paramètres' },
];

const adminNavItems = [
  { to: '/admin/dashboard',     icon: LayoutDashboard, label: 'Tableau de bord' },
  { to: '/admin/users',         icon: Users,           label: 'Utilisateurs' },
  { to: '/admin/experts',       icon: ShieldCheck,     label: 'Médecins' },
  { to: '/admin/conversations', icon: MessageSquare,   label: 'Conversations' },
  { to: '/admin/categories',    icon: FolderOpen,      label: 'Spécialités' },
  { to: '/admin/knowledge',     icon: BookOpen,        label: 'Base de connaissances' },
  { to: '/admin/payments',      icon: CreditCard,      label: 'Paiements' },
  { type: 'section', label: 'Configuration' },
  { to: '/admin/ai',            icon: Cpu,             label: 'IA' },
  { to: '/admin/security',      icon: ShieldCheck,     label: 'Sécurité & 2FA' },
  { to: '/admin/system',        icon: Server,          label: 'Système' },
];

export default function AppLayout() {
  const { user, logout } = useAuthStore();
  const navigate = useNavigate();
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [collapsed, setCollapsed] = useState(false);

  const isExpert = user?.role === 'expert';
  const isAdmin  = user?.role === 'admin';
  const navItems = isAdmin ? adminNavItems : isExpert ? expertNavItems : userNavItems;

  // Keep online presence alive — sends heartbeat every 30 seconds
  useHeartbeat();

  const qc = useQueryClient();
  useEffect(() => {
    if (!isAdmin) return;
    const prefetch = (key, url) =>
      qc.prefetchQuery({ queryKey: key, queryFn: () => api.get(url).then(r => r.data), staleTime: 1000 * 60 * 5 });
    prefetch(['admin', 'dashboard'],          '/admin/dashboard');
    prefetch(['admin', 'users',   {}],        '/admin/users');
    prefetch(['admin', 'experts', {}],        '/admin/experts');
    prefetch(['admin', 'settings'],           '/admin/settings');
    prefetch(['admin', 'categories'],         '/admin/categories');
  }, [isAdmin]);

  const handleLogout = async () => {
    await logout();
    navigate('/login');
  };

  return (
    <div className={`app-layout${isAdmin ? ' is-admin' : ''}`}>
      {!isAdmin && <NexoraBackground />}
      <aside className={`sidebar ${sidebarOpen ? 'sidebar--open' : ''} ${collapsed ? 'sidebar--collapsed' : ''}`}>
        <div className="sidebar-header">
          <div className="sidebar-logo">
            <img src="/logo.png" alt="Nexora" className="sidebar-logo-img" />
            <span className="sidebar-logo-text">NEXORA</span>
          </div>
          <button className="sidebar-close" onClick={() => setSidebarOpen(false)}>
            <X size={20} />
          </button>
          <button
            className="sidebar-toggle-btn"
            onClick={() => setCollapsed(!collapsed)}
            title={collapsed ? 'Ouvrir le menu' : 'Réduire le menu'}
          >
            {collapsed ? <ChevronRight size={16} /> : <ChevronLeft size={16} />}
          </button>
        </div>

        <nav className="sidebar-nav">
          {isAdmin && !collapsed && (
            <span className="sidebar-section-label">Menu administration</span>
          )}
          {navItems.map((item, i) => {
            if (item.type === 'section') {
              return <span key={`sec-${i}`} className="sidebar-section-label">{item.label}</span>;
            }
            const Icon = item.icon;
            return (
              <NavLink
                key={item.to}
                to={item.to}
                title={collapsed ? item.label : undefined}
                className={({ isActive }) => `sidebar-link ${isActive ? 'sidebar-link--active' : ''}`}
                onClick={() => setSidebarOpen(false)}
              >
                <Icon size={18} />
                <span className="sidebar-link-label">{item.label}</span>
              </NavLink>
            );
          })}
        </nav>

        {!isAdmin && !isExpert && (
          <div className="sidebar-cta">
            <NavLink to="/conversations/new" className="sidebar-cta-btn" onClick={() => setSidebarOpen(false)}>
              <MessageSquare size={16} />
              <span>Nouvelle conversation</span>
            </NavLink>
          </div>
        )}

        <div className="sidebar-footer">
          <div className="sidebar-user">
            <div className="sidebar-avatar" title={collapsed ? user?.name : undefined}>
              {user?.name?.charAt(0)?.toUpperCase() || 'U'}
            </div>
            <div className="sidebar-user-info">
              <span className="sidebar-user-name">{user?.name}</span>
              <span className="sidebar-user-role">{user?.role}</span>
            </div>
          </div>
          <button className="sidebar-link sidebar-logout" title={collapsed ? 'Déconnexion' : undefined} onClick={handleLogout}>
            <LogOut size={20} />
            <span className="sidebar-link-label">Déconnexion</span>
          </button>
        </div>

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
