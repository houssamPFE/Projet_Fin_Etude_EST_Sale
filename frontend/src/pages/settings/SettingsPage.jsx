import { useState, useRef } from 'react';
import { QRCodeSVG } from 'qrcode.react';
import { Loader2, Save, Camera, ShieldCheck, ShieldOff, QrCode } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import toast from 'react-hot-toast';
import useAuthStore from '../../stores/authStore';
import { useUpdateProfile, useUploadAvatar } from '../../hooks/useProfile';
import CustomSelect from '../../components/CustomSelect';
import './SettingsPage.css';

export default function SettingsPage() {
  const { user, logout } = useAuthStore();
  const navigate         = useNavigate();
  const fileRef          = useRef();

  const [name, setName]         = useState(user?.name ?? '');
  const [phone, setPhone]       = useState(user?.phone ?? '');
  const [language, setLanguage] = useState(user?.language ?? 'fr');
  const [deletePass, setDeletePass] = useState('');
  const [showDelete, setShowDelete] = useState(false);

  const [qrCode, setQrCode]         = useState(null);
  const [twoFaCode, setTwoFaCode]   = useState('');
  const [disablePass, setDisablePass] = useState('');
  const [twoFaLoading, setTwoFaLoading] = useState(false);
  const twoFaEnabled = user?.two_factor_enabled ?? false;

  const { mutateAsync: updateProfile, isPending: saving }   = useUpdateProfile();
  const { mutateAsync: uploadAvatar, isPending: uploading }  = useUploadAvatar();

  const handleSave = async (e) => {
    e.preventDefault();
    try {
      await updateProfile({ name, phone: phone || null, language });
      toast.success('Profil mis à jour.');
    } catch {
      toast.error('Impossible de mettre à jour le profil.');
    }
  };

  const handleAvatar = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    try {
      await uploadAvatar(file);
      toast.success('Avatar mis à jour.');
    } catch {
      toast.error('Impossible de mettre à jour l\'avatar.');
    }
  };

  const handleEnable2fa = async () => {
    setTwoFaLoading(true);
    try {
      const api = (await import('../../lib/api')).default;
      const { data } = await api.post('/auth/2fa/enable');
      setQrCode(data.data.qr_code_url);
    } catch {
      toast.error('Impossible d\'activer le 2FA.');
    } finally {
      setTwoFaLoading(false);
    }
  };

  const handleConfirm2fa = async () => {
    if (!twoFaCode) return;
    setTwoFaLoading(true);
    try {
      const api = (await import('../../lib/api')).default;
      await api.post('/auth/2fa/confirm', { code: twoFaCode });
      toast.success('Authentification à deux facteurs activée.');
      setQrCode(null);
      setTwoFaCode('');
      await useAuthStore.getState().init();
    } catch {
      toast.error('Code invalide.');
    } finally {
      setTwoFaLoading(false);
    }
  };

  const handleDisable2fa = async () => {
    if (!disablePass) return;
    setTwoFaLoading(true);
    try {
      const api = (await import('../../lib/api')).default;
      await api.post('/auth/2fa/disable', { password: disablePass });
      toast.success('2FA désactivé.');
      setDisablePass('');
      await useAuthStore.getState().init();
    } catch {
      toast.error('Mot de passe incorrect.');
    } finally {
      setTwoFaLoading(false);
    }
  };

  const handleDeleteAccount = async () => {
    if (!deletePass) return;
    try {
      const api = (await import('../../lib/api')).default;
      await api.delete('/users/account', { data: { password: deletePass } });
      toast.success('Compte supprimé.');
      await logout();
      navigate('/login');
    } catch (err) {
      toast.error(err.response?.data?.message || 'Mot de passe incorrect.');
    }
  };

  return (
    <div className="settings-page">
      <h1>Paramètres</h1>

      <div className="settings-card">
        <h2 className="settings-card-title">Photo de profil</h2>
        <div className="avatar-row">
          <div className="avatar-preview">
            {user?.avatar_url
              ? <img src={user.avatar_url} alt="avatar" />
              : user?.name?.charAt(0)?.toUpperCase()
            }
          </div>
          <input
            ref={fileRef}
            type="file"
            accept="image/jpg,image/jpeg,image/png,image/webp"
            style={{ display: 'none' }}
            onChange={handleAvatar}
          />
          <button
            className="avatar-upload-btn"
            onClick={() => fileRef.current?.click()}
            disabled={uploading}
          >
            {uploading ? <Loader2 size={14} className="spin" /> : <Camera size={14} />}
            &nbsp;{uploading ? 'Envoi...' : 'Changer l\'avatar'}
          </button>
        </div>
      </div>

      <form className="settings-card" onSubmit={handleSave}>
        <h2 className="settings-card-title">Informations personnelles</h2>

        <div className="form-group">
          <label className="form-label">Nom complet</label>
          <input
            className="form-input"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Votre nom"
            required
          />
        </div>

        <div className="form-group">
          <label className="form-label">Téléphone</label>
          <input
            className="form-input"
            value={phone}
            onChange={(e) => setPhone(e.target.value)}
            placeholder="+212 6XX XXX XXX"
          />
        </div>

        <div className="form-group">
          <label className="form-label">Langue</label>
          <CustomSelect
            value={language}
            onChange={(e) => setLanguage(e.target.value)}
            options={[{ value: 'fr', label: 'Français' }, { value: 'ar', label: 'العربية' }]}
          />
        </div>

        <button type="submit" className="settings-save-btn" disabled={saving}>
          {saving ? <Loader2 size={16} className="spin" /> : <Save size={16} />}
          {saving ? 'Enregistrement...' : 'Enregistrer'}
        </button>
      </form>

      <div className="settings-card">
        <h2 className="settings-card-title">Authentification à deux facteurs (2FA)</h2>

        {twoFaEnabled ? (
          <div className="twofa-enabled-row">
            <div className="twofa-status twofa-status--on">
              <ShieldCheck size={16} /> 2FA activé
            </div>
            <p className="danger-text" style={{ margin: 0 }}>
              Entrez votre mot de passe pour désactiver le 2FA.
            </p>
            <div style={{ display: 'flex', gap: 8 }}>
              <input
                className="form-input"
                type="password"
                placeholder="Mot de passe"
                value={disablePass}
                onChange={(e) => setDisablePass(e.target.value)}
                style={{ maxWidth: 260 }}
              />
              <button className="twofa-btn twofa-btn--disable" onClick={handleDisable2fa} disabled={twoFaLoading}>
                {twoFaLoading ? <Loader2 size={14} className="spin" /> : <ShieldOff size={14} />}
                Désactiver
              </button>
            </div>
          </div>
        ) : qrCode ? (
          <div className="twofa-setup">
            <p style={{ fontSize: 13, color: 'var(--text-muted)', margin: 0 }}>
              Scannez ce QR code avec <strong style={{ color: 'var(--text-secondary)' }}>Google Authenticator</strong>, puis entrez le code généré.
            </p>
            <div className="twofa-qr">
              <QRCodeSVG value={qrCode} size={160} bgColor="#ffffff" fgColor="#000000" />
            </div>
            <div style={{ display: 'flex', gap: 8 }}>
              <input
                className="form-input"
                type="text"
                placeholder="Code à 6 chiffres"
                value={twoFaCode}
                onChange={(e) => setTwoFaCode(e.target.value)}
                maxLength={6}
                style={{ maxWidth: 180, letterSpacing: '0.2em', textAlign: 'center' }}
              />
              <button className="twofa-btn twofa-btn--confirm" onClick={handleConfirm2fa} disabled={twoFaLoading}>
                {twoFaLoading ? <Loader2 size={14} className="spin" /> : <ShieldCheck size={14} />}
                Confirmer
              </button>
            </div>
          </div>
        ) : (
          <div className="twofa-disabled-row">
            <div className="twofa-status twofa-status--off">
              <ShieldOff size={16} /> 2FA désactivé
            </div>
            <p style={{ fontSize: 13, color: 'var(--text-muted)', margin: 0 }}>
              Protégez votre compte avec Google Authenticator.
            </p>
            <button className="twofa-btn twofa-btn--enable" onClick={handleEnable2fa} disabled={twoFaLoading}>
              {twoFaLoading ? <Loader2 size={14} className="spin" /> : <QrCode size={14} />}
              Activer le 2FA
            </button>
          </div>
        )}
      </div>

      <div className="settings-card danger-zone">
        <h2 className="settings-card-title">Zone de danger</h2>
        <p className="danger-text">
          La suppression de votre compte est irréversible. Toutes vos données seront effacées.
        </p>
        {!showDelete ? (
          <button className="danger-btn" onClick={() => setShowDelete(true)}>
            Supprimer mon compte
          </button>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            <input
              className="form-input"
              type="password"
              placeholder="Confirmez votre mot de passe"
              value={deletePass}
              onChange={(e) => setDeletePass(e.target.value)}
            />
            <div style={{ display: 'flex', gap: 8 }}>
              <button className="danger-btn" onClick={handleDeleteAccount}>
                Confirmer la suppression
              </button>
              <button
                style={{ padding: '10px 24px', background: 'none', border: '1px solid var(--border-default)', borderRadius: 'var(--radius-md)', color: 'var(--text-muted)', cursor: 'pointer', fontSize: 14 }}
                onClick={() => { setShowDelete(false); setDeletePass(''); }}
              >
                Annuler
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
