import { useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowRight, Loader2, Lock } from 'lucide-react';
import { QRCodeSVG } from 'qrcode.react';
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
  const [show2fa, setShow2fa] = useState(false);
  const [is2faSetup, setIs2faSetup] = useState(false);
  const [setupData, setSetupData] = useState(null);
  const [twoFactorToken, setTwoFactorToken] = useState('');
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

      if (payload.get('requires_2fa') === '1' || payload.get('requires_2fa_setup') === '1') {
        setTwoFactorToken(payload.get('two_factor_token') || '');
        setShow2fa(true);
        if (payload.get('requires_2fa_setup') === '1') {
          setIs2faSetup(true);
          try {
            setSetupData(JSON.parse(payload.get('setup_data') || '{}'));
          } catch(e) {}
        }
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

  if (show2fa) {
    return (
      <div className="auth-page">
        <h2 className="auth-title">Vérification 2FA</h2>
        <p className="auth-subtitle">
          {is2faSetup
            ? "L'authentification à deux facteurs est obligatoire pour votre compte."
            : "Entrez le code de votre application d'authentification"}
        </p>

        {is2faSetup && setupData && (
          <div style={{ textAlign: 'center', marginBottom: '1.5rem' }}>
            <p style={{ fontSize: '0.875rem', color: '#495057', marginBottom: '1rem' }}>
              Scannez ce QR Code avec Google Authenticator ou Authy :
            </p>
            <div style={{ display: 'inline-block', background: 'white', padding: '0.5rem', borderRadius: '8px', border: '1px solid #dee2e6' }}>
              <QRCodeSVG value={setupData.qr_code_url} size={160} bgColor="#ffffff" fgColor="#020617" />
            </div>
            <p style={{ fontSize: '0.8125rem', color: '#6c757d', marginTop: '0.75rem', fontFamily: 'monospace', letterSpacing: '1px' }}>
              {setupData.secret}
            </p>
            <p style={{ fontSize: '0.8125rem', color: '#495057', marginTop: '1rem', fontWeight: 500 }}>
              Puis entrez le code à 6 chiffres généré ci-dessous pour confirmer :
            </p>
          </div>
        )}

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
                onChange={(e) => setOtpCode(e.target.value)}
                maxLength={6}
                autoFocus
                required
              />
            </div>
          </div>
          {error && <p className="form-error">{error}</p>}
          <button type="submit" className="btn btn-primary btn-lg w-full" disabled={loading}>
            {loading ? <span className="spinner" /> : (is2faSetup ? 'Confirmer la configuration' : 'Vérifier')}
          </button>
        </form>
      </div>
    );
  }

  return null;
}
