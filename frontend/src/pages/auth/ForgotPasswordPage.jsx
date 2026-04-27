import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Mail, ArrowRight, ArrowLeft } from 'lucide-react';
import toast from 'react-hot-toast';
import api from '../../lib/api';
import './Auth.css';

export default function ForgotPasswordPage() {
  const navigate = useNavigate();

  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      await api.post('/auth/forgot-password', { email });
      toast.success('Code envoyé. Vérifiez votre boîte mail.');
      navigate(`/reset-password?email=${encodeURIComponent(email)}`);
    } catch (err) {
      const msg =
        err.response?.data?.message ??
        'Impossible d\'envoyer le code. Vérifiez votre adresse email.';
      setError(msg);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-page">
      <h2 className="auth-title">Mot de passe oublié</h2>
      <p className="auth-subtitle">
        Entrez votre email — nous vous enverrons un code à 6 chiffres pour
        réinitialiser votre mot de passe.
      </p>

      <form onSubmit={handleSubmit} className="auth-form">
        <div className="form-group">
          <label className="form-label">Email</label>
          <div className="input-wrapper">
            <Mail size={18} className="input-icon" />
            <input
              type="email"
              className="form-input input-with-icon"
              placeholder="votre@email.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
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
              Envoyer le code
              <ArrowRight size={18} />
            </>
          )}
        </button>
      </form>

      <p className="auth-switch">
        <Link to="/login" className="auth-back">
          <ArrowLeft size={14} /> Retour à la connexion
        </Link>
      </p>
    </div>
  );
}
