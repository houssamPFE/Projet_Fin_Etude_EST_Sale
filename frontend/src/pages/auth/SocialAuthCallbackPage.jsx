import { useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowRight, Loader2, Lock } from 'lucide-react';
import toast from 'react-hot-toast';
import useAuthStore from '../../stores/authStore';
import './Auth.css';

function parseHashPayload(hash) {
  const fragment = hash.startsWith('#') ? hash.slice(1) : hash;
  return new URLSearchParams(fragment);
}

export default function SocialAuthCallbackPage() {
  const navigate = useNavigate();
  const { completeAuth, verify2fa, error, clearError } = useAuthStore();

  const payload = useMemo(() => parseHashPayload(window.location.hash), []);
  const [loading, setLoading] = useState(true);
  const [twoFactorToken, setTwoFactorToken] = useState('');
  const [show2fa, setShow2fa] = useState(false);
  const [otpCode, setOtpCode] = useState('');

  const redirectAfterAuth = (user) => {
    navigate(user?.role === 'admin' ? '/admin/dashboard' : '/dashboard', { replace: true });
  };

  useEffect(() => {
    const finishSocialAuth = async () => {
      clearError();

      const errorMessage = payload.get('error');
      if (errorMessage) {
        toast.error(errorMessage);
        navigate('/login', { replace: true });
        return;
      }

      if (payload.get('requires_2fa') === '1') {
        setTwoFactorToken(payload.get('two_factor_token') ?? '');
        setShow2fa(true);
        setLoading(false);
        return;
      }

      const accessToken = payload.get('access_token');
      const refreshToken = payload.get('refresh_token');

      if (!accessToken || !refreshToken) {
        toast.error('Reponse Google incomplete.');
        navigate('/login', { replace: true });
        return;
      }

      const result = await completeAuth(accessToken, refreshToken);
      if (result.success) {
        toast.success('Connexion Google reussie.');
        redirectAfterAuth(result.user);
        return;
      }

      toast.error(result.error ?? 'Connexion sociale impossible.');
      navigate('/login', { replace: true });
    };

    finishSocialAuth();
  }, [clearError, completeAuth, navigate, payload]);

  const handle2faVerify = async (event) => {
    event.preventDefault();
    setLoading(true);

    const result = await verify2fa(twoFactorToken, otpCode);

    if (result.success) {
      toast.success('Bienvenue !');
      redirectAfterAuth(result.user);
      return;
    }

    setLoading(false);
  };

  if (loading && !show2fa) {
    return (
      <div className="auth-page">
        <h2 className="auth-title">
          {payload.get('provider') === 'facebook' ? 'Connexion Facebook' : 'Connexion Google'}
        </h2>
        <p className="auth-subtitle">Finalisation de votre connexion...</p>
        <div style={{ display: 'flex', justifyContent: 'center' }}>
          <Loader2 size={28} className="spin" />
        </div>
      </div>
    );
  }

  return (
    <div className="auth-page">
      <h2 className="auth-title">Verification 2FA</h2>
      <p className="auth-subtitle">Entrez le code de votre application d&apos;authentification.</p>

      <form onSubmit={handle2faVerify} className="auth-form">
        <div className="form-group">
          <label className="form-label">Code TOTP</label>
          <div className="input-wrapper">
            <Lock size={18} className="input-icon" />
            <input
              type="text"
              className="form-input input-with-icon"
              placeholder="000000"
              value={otpCode}
              onChange={(event) => setOtpCode(event.target.value.replace(/\D/g, '').slice(0, 6))}
              maxLength={6}
              autoFocus
              required
            />
          </div>
        </div>

        {error && <p className="form-error">{error}</p>}

        <button type="submit" className="btn btn-primary btn-lg w-full" disabled={loading}>
          {loading ? (
            <span className="spinner" />
          ) : (
            <>
              Verifier
              <ArrowRight size={18} />
            </>
          )}
        </button>
      </form>
    </div>
  );
}
