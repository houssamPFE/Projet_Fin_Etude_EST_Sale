import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';
import { useEffect } from 'react';
import useAuthStore from './stores/authStore';

// Layouts
import AuthLayout from './layouts/AuthLayout';
import AppLayout from './layouts/AppLayout';

// Auth pages
import LoginPage from './pages/auth/LoginPage';
import RegisterPage from './pages/auth/RegisterPage';
import ForgotPasswordPage from './pages/auth/ForgotPasswordPage';
import ResetPasswordPage from './pages/auth/ResetPasswordPage';
import SocialAuthCallbackPage from './pages/auth/SocialAuthCallbackPage';

// App pages
import DashboardPage from './pages/DashboardPage';
import ExpertsPage from './pages/experts/ExpertsPage';
import ExpertDetailPage from './pages/experts/ExpertDetailPage';
import ConversationsPage from './pages/conversations/ConversationsPage';
import ConversationPage from './pages/conversations/ConversationPage';
import NewConversationPage from './pages/conversations/NewConversationPage';
import LandingPage from './pages/LandingPage';
import ExpertDashboardPage from './pages/expert/ExpertDashboardPage';
import ExpertProfilePage from './pages/expert/ExpertProfilePage';
import ExpertWalletPage from './pages/expert/ExpertWalletPage';
import AdminDashboardPage from './pages/admin/AdminDashboardPage';
import AdminUsersPage from './pages/admin/AdminUsersPage';
import AdminExpertsPage from './pages/admin/AdminExpertsPage';
import AdminConversationsPage from './pages/admin/AdminConversationsPage';
import AdminCategoriesPage from './pages/admin/AdminCategoriesPage';
import AdminPaymentsPage from './pages/admin/AdminPaymentsPage';
import AdminKnowledgeBasePage from './pages/admin/AdminKnowledgeBasePage';
import SettingsPage from './pages/settings/SettingsPage';
import ApplyExpertPage from './pages/settings/ApplyExpertPage';
// import NotificationsPage from './pages/NotificationsPage'; // TODO: S19

// Route guards
function PrivateRoute({ children }) {
  const { isAuthenticated, isLoading } = useAuthStore();
  if (isLoading) return <LoadingScreen />;
  return isAuthenticated ? children : <Navigate to="/login" replace />;
}

function GuestRoute({ children }) {
  const { isAuthenticated, isLoading, user } = useAuthStore();
  if (isLoading) return <LoadingScreen />;
  if (isAuthenticated) {
    return <Navigate to={user?.role === 'admin' ? '/admin/dashboard' : '/dashboard'} replace />;
  }
  return children;
}

function AdminRoute({ children }) {
  const { isAuthenticated, isLoading, user } = useAuthStore();
  if (isLoading) return <LoadingScreen />;
  if (!isAuthenticated) return <Navigate to="/login" replace />;
  if (user?.role !== 'admin') return <Navigate to="/dashboard" replace />;
  return children;
}

function LoadingScreen() {
  return (
    <div style={{
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      height: '100vh',
      background: 'var(--bg-primary)',
    }}>
      <div className="spinner" style={{ width: '2.5rem', height: '2.5rem', color: 'var(--primary-500)' }} />
    </div>
  );
}

export default function App() {
  const init = useAuthStore((s) => s.init);

  useEffect(() => {
    init();
  }, [init]);

  return (
    <BrowserRouter>
      <Toaster
        position="top-right"
        toastOptions={{
          style: {
            background: 'var(--bg-card)',
            color: 'var(--text-primary)',
            border: '1px solid var(--border-default)',
            borderRadius: 'var(--radius-lg)',
          },
        }}
      />
      <Routes>
        {/* Auth routes */}
        <Route element={<GuestRoute><AuthLayout /></GuestRoute>}>
          <Route path="/login" element={<LoginPage />} />
          <Route path="/register" element={<RegisterPage />} />
          <Route path="/forgot-password" element={<ForgotPasswordPage />} />
          <Route path="/reset-password" element={<ResetPasswordPage />} />
          <Route path="/auth/social/callback" element={<SocialAuthCallbackPage />} />
        </Route>

        <Route path="/" element={<GuestRoute><LandingPage /></GuestRoute>} />

        {/* App routes */}
        <Route element={<PrivateRoute><AppLayout /></PrivateRoute>}>
          <Route path="/dashboard" element={<DashboardPage />} />
          <Route path="/experts" element={<ExpertsPage />} />
          <Route path="/experts/:id" element={<ExpertDetailPage />} />
          <Route path="/conversations" element={<ConversationsPage />} />
          <Route path="/conversations/new" element={<NewConversationPage />} />
          <Route path="/conversations/:id" element={<ConversationPage />} />
          <Route path="/expert/dashboard" element={<ExpertDashboardPage />} />
          <Route path="/expert/profile" element={<ExpertProfilePage />} />
          <Route path="/expert/wallet" element={<ExpertWalletPage />} />
          <Route path="/settings" element={<SettingsPage />} />
          <Route path="/apply-expert" element={<ApplyExpertPage />} />
          {/* <Route path="/notifications" element={<NotificationsPage />} /> */}
        </Route>

        {/* Admin routes */}
        <Route element={<AdminRoute><AppLayout /></AdminRoute>}>
          <Route path="/admin/dashboard"     element={<AdminDashboardPage />} />
          <Route path="/admin/users"         element={<AdminUsersPage />} />
          <Route path="/admin/experts"       element={<AdminExpertsPage />} />
          <Route path="/admin/conversations" element={<AdminConversationsPage />} />
          <Route path="/admin/categories"    element={<AdminCategoriesPage />} />
          <Route path="/admin/payments"      element={<AdminPaymentsPage />} />
          <Route path="/admin/knowledge"     element={<AdminKnowledgeBasePage />} />
        </Route>

        {/* Default redirect */}
        <Route path="*" element={<Navigate to="/login" replace />} />
      </Routes>
    </BrowserRouter>
  );
}
