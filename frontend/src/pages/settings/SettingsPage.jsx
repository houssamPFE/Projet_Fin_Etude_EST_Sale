import { useEffect, useState, useRef } from 'react';
import { QRCodeSVG } from 'qrcode.react';
import {
  Loader2, Save, Camera, ShieldCheck, ShieldOff, QrCode,
  Eye, EyeOff, User, Phone, Mail, Trash2,
  KeyRound, Lock, Palette,
} from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import toast from 'react-hot-toast';
import useAuthStore from '../../stores/authStore';
import { useUpdateProfile, useUploadAvatar } from '../../hooks/useProfile';
import AvatarCropModal from '../../components/AvatarCropModal';
import useThemeStore from '../../stores/themeStore';
import './SettingsPage.css';

export default function SettingsPage() {
  const { user, logout } = useAuthStore();
  const { theme, setTheme } = useThemeStore();
  const navigate         = useNavigate();
  const fileRef = useRef();
  const [cropSrc, setCropSrc] = useState(null);

  const [name, setName]         = useState(user?.name ?? '');
  const [phone, setPhone]       = useState(user?.phone ?? '');
  const [language, setLanguage] = useState(user?.language ?? 'fr');
  const [onlineVisible, setOnlineVisible] = useState(user?.is_online_visible ?? true);
  const [deletePass, setDeletePass] = useState('');
  const [showDelete, setShowDelete] = useState(false);


  const [currentPwd, setCurrentPwd]         = useState('');
  const [newPwd, setNewPwd]                 = useState('');
  const [confirmPwd, setConfirmPwd]         = useState('');
  const [pwdLoading, setPwdLoading]         = useState(false);
  const [showCurrentPwd, setShowCurrentPwd] = useState(false);
  const [showNewPwd, setShowNewPwd]         = useState(false);
  const [showConfirmPwd, setShowConfirmPwd] = useState(false);

  const [qrCode, setQrCode]           = useState(null);
  const [twoFaCode, setTwoFaCode]     = useState('');
  const [disablePass, setDisablePass] = useState('');
  const [twoFaLoading, setTwoFaLoading] = useState(false);
  const twoFaEnabled = user?.two_factor_enabled ?? false;

  const { mutateAsync: updateProfile, isPending: saving }  = useUpdateProfile();
  const { mutateAsync: uploadAvatar,  isPending: uploading } = useUploadAvatar();

  useEffect(() => {
    setName(user?.name ?? '');
    setPhone(user?.phone ?? '');
    setLanguage(user?.language ?? 'fr');
    setOnlineVisible(user?.is_online_visible ?? true);
  }, [user?.name, user?.phone, user?.language, user?.is_online_visible]);

  const handleSave = async (e) => {
    e.preventDefault();
    try {
      await updateProfile({ name, phone: phone || null, language });
      toast.success('Profil mis à jour.');
    } catch { toast.error('Impossible de mettre à jour le profil.'); }
  };

  const handleFileSelect = (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setCropSrc(URL.createObjectURL(file));
    e.target.value = '';
  };

  const handleCropConfirm = async (blob) => {
    setCropSrc(null);
    try {
      await uploadAvatar(new File([blob], 'avatar.jpg', { type: 'image/jpeg' }));
      toast.success('Photo de profil mise à jour.');
    } catch { toast.error("Impossible de mettre à jour la photo."); }
  };

  const handleOnlineVisibleToggle = async (value) => {
    setOnlineVisible(value);
    try {
      await updateProfile({ is_online_visible: value });
      toast.success(value ? 'Statut en ligne activé.' : 'Statut en ligne masqué.');
    } catch { setOnlineVisible(!value); toast.error('Impossible de mettre à jour le statut.'); }
  };

  const handleChangePassword = async (e) => {
    e.preventDefault();
    if (newPwd !== confirmPwd) { toast.error('Les mots de passe ne correspondent pas.'); return; }
    if (newPwd.length < 8)     { toast.error('Minimum 8 caractères requis.'); return; }
    setPwdLoading(true);
    try {
      const api = (await import('../../lib/api')).default;
      await api.put('/users/password', {
        current_password: currentPwd, password: newPwd, password_confirmation: confirmPwd,
      });
      toast.success('Mot de passe modifié avec succès.');
      setCurrentPwd(''); setNewPwd(''); setConfirmPwd('');
    } catch (err) {
      toast.error(err.response?.data?.message || 'Erreur lors du changement.');
    } finally { setPwdLoading(false); }
  };

  const handleEnable2fa = async () => {
    setTwoFaLoading(true);
    try {
      const api = (await import('../../lib/api')).default;
      const { data } = await api.post('/auth/2fa/enable');
      setQrCode(data.data.qr_code_url);
    } catch { toast.error("Impossible d'activer le 2FA."); }
    finally { setTwoFaLoading(false); }
  };

  const handleConfirm2fa = async () => {
    if (!twoFaCode) return;
    setTwoFaLoading(true);
    try {
      const api = (await import('../../lib/api')).default;
      await api.post('/auth/2fa/confirm', { code: twoFaCode });
      toast.success('2FA activé.');
      setQrCode(null); setTwoFaCode('');
      await useAuthStore.getState().init();
    } catch { toast.error('Code invalide.'); }
    finally { setTwoFaLoading(false); }
  };

  const handleDisable2fa = async () => {
    if (!disablePass) return;
    setTwoFaLoading(true);
    try {
      const api = (await import('../../lib/api')).default;
      await api.post('/auth/2fa/disable', { code: disablePass });
      toast.success('2FA désactivé.');
      setDisablePass('');
      await useAuthStore.getState().init();
    } catch { toast.error('Code invalide.'); }
    finally { setTwoFaLoading(false); }
  };

  const handleDeleteAccount = async () => {
    if (!deletePass) return;
    try {
      const api = (await import('../../lib/api')).default;
      await api.delete('/users/account', { data: { password: deletePass } });
      toast.success('Compte supprimé.');
      await logout(); navigate('/login');
    } catch (err) { toast.error(err.response?.data?.message || 'Mot de passe incorrect.'); }
  };

  const pwdStrength = (pwd) => {
    if (!pwd) return null;
    let s = 0;
    if (pwd.length >= 8)           s++;
    if (pwd.length >= 12)          s++;
    if (/[A-Z]/.test(pwd))         s++;
    if (/[0-9]/.test(pwd))         s++;
    if (/[^A-Za-z0-9]/.test(pwd))  s++;
    if (s <= 1) return { w: '33%',  label: 'Faible',  color: '#EF4444' };
    if (s <= 3) return { w: '66%',  label: 'Moyen',   color: '#F59E0B' };
    return             { w: '100%', label: 'Fort',    color: '#22C55E' };
  };
  const strength   = pwdStrength(newPwd);
  const roleLabel  = { user: 'Patient', expert: 'Expert', admin: 'Administrateur' }[user?.role] ?? user?.role;
  const isVerified = user?.role === 'expert' || user?.role === 'admin';
  const memberSince = user?.created_at
    ? new Date(user.created_at).toLocaleDateString('fr-FR', { month: 'short', year: 'numeric' })
    : '—';

  return (
    <>
      {cropSrc && <AvatarCropModal imageSrc={cropSrc} onConfirm={handleCropConfirm} onClose={() => setCropSrc(null)} />}
      <div className="settings-page">

        {/* ── Page Header ── */}
        <div className="settings-header">
          <div className="settings-header-bg" />
          <div className="settings-header-decor">
            {[48, 32, 56, 24, 40].map((h, i) => <span key={i} style={{ width: 3, height: h }} />)}
          </div>
          <div className="settings-header-content">
            <div className="settings-header-text">
              <div className="settings-header-eyebrow">
                <span className="settings-header-eyebrow-dot" />
                Espace personnel
              </div>
              <h1 className="settings-header-title">Paramètres</h1>
              <p className="settings-header-subtitle">Gérez votre compte, sécurité et préférences</p>
            </div>
            <div className="settings-header-stats">
              <div className="settings-stat">
                <span className="settings-stat-value">{roleLabel}</span>
                <span className="settings-stat-label">Rôle</span>
              </div>
              <div className="settings-stat">
                <span className="settings-stat-value">{memberSince}</span>
                <span className="settings-stat-label">Membre depuis</span>
              </div>
              <div className="settings-stat">
                <span className="settings-stat-value" style={{ color: isVerified ? '#86EFAC' : '#475569' }}>
                  {isVerified ? '✓' : '—'}
                </span>
                <span className="settings-stat-label">Vérifié</span>
              </div>
            </div>
          </div>
        </div>

        <div className="settings-divider" />
        <div className="settings-body">

          {/* ══ SECTION: COMPTE ══ */}
          <div className="settings-section-label"><span>Informations du compte</span></div>

          <form className="settings-card" onSubmit={handleSave}>
            <div className="settings-card-header">
              <div className="settings-card-icon"><User size={15} /></div>
              <div style={{ flex: 1 }}>
                <h2 className="settings-card-title">Informations personnelles</h2>
                <p className="settings-card-desc">Mettez à jour vos informations de base</p>
              </div>
              <div className="settings-avatar-wrap">
                <div className="settings-avatar">
                  {user?.avatar_url
                    ? <img src={user.avatar_url} alt={user.name} />
                    : <span>{user?.name?.charAt(0)?.toUpperCase() || 'U'}</span>}
                </div>
                <button type="button" className="settings-avatar-edit" onClick={() => fileRef.current?.click()} disabled={uploading} title="Changer la photo">
                  {uploading ? <Loader2 size={13} className="spin" /> : <Camera size={13} />}
                </button>
                <input ref={fileRef} type="file" accept="image/jpg,image/jpeg,image/png,image/webp" style={{ display: 'none' }} onChange={handleFileSelect} />
              </div>
            </div>
            <div className="settings-form-grid">
              <div className="form-group">
                <label className="form-label">Nom complet</label>
                <div className="form-input-wrap">
                  <User size={14} className="form-input-icon" />
                  <input className="form-input" value={name} onChange={e => setName(e.target.value)} placeholder="Votre nom" required />
                </div>
              </div>
              <div className="form-group">
                <label className="form-label">Téléphone</label>
                <div className="form-input-wrap">
                  <Phone size={14} className="form-input-icon" />
                  <input className="form-input" value={phone} onChange={e => setPhone(e.target.value)} placeholder="+212 6XX XXX XXX" />
                </div>
              </div>
              <div className="form-group" style={{ gridColumn: '1 / -1' }}>
                <label className="form-label">E-mail</label>
                <div className="form-input-wrap form-input-wrap--readonly">
                  <Mail size={14} className="form-input-icon" />
                  <input className="form-input form-input--readonly" value={user?.email ?? ''} readOnly aria-readonly="true" />
                </div>
              </div>
            </div>
            <div className="settings-card-footer">
              <button type="submit" className="settings-save-btn" disabled={saving}>
                {saving ? <Loader2 size={15} className="spin" /> : <Save size={15} />}
                {saving ? 'Enregistrement…' : 'Enregistrer les modifications'}
              </button>
            </div>
          </form>

          {/* ══ SECTION: APPARENCE ══ */}
          <div className="settings-section-label"><span>Apparence</span></div>

          <div className="settings-card">
            <div className="settings-card-header">
              <div className="settings-card-icon"><Palette size={15} /></div>
              <div>
                <h2 className="settings-card-title">Thème de l'application</h2>
                <p className="settings-card-desc">Sélectionnez la palette de couleurs de votre espace</p>
              </div>
            </div>
            <div className="theme-selector-grid">
              <div 
                className={`theme-card ${theme === 'cream' ? 'theme-card--active' : ''}`}
                onClick={() => setTheme('cream')}
              >
                <div className="theme-preview-circle theme-preview--cream" />
                <span className="theme-name">Menthe Crème (Par défaut)</span>
              </div>

              <div 
                className={`theme-card ${theme === 'default' ? 'theme-card--active' : ''}`}
                onClick={() => setTheme('default')}
              >
                <div className="theme-preview-circle theme-preview--default" />
                <span className="theme-name">Sombre</span>
              </div>
            </div>
          </div>

          {/* ══ SECTION: SÉCURITÉ ══ */}
          <div className="settings-section-label"><span>Sécurité</span></div>

          {/* Change password + 2FA side by side */}
          <div className="settings-security-row">

            <form className="settings-card" onSubmit={handleChangePassword}>
              <div className="settings-card-header">
                <div className="settings-card-icon settings-card-icon--key"><KeyRound size={15} /></div>
                <div>
                  <h2 className="settings-card-title">Changer le mot de passe</h2>
                  <p className="settings-card-desc">Mettez à jour votre mot de passe de connexion</p>
                </div>
              </div>
              <div className="form-group">
                <label className="form-label">Mot de passe actuel</label>
                <div className="form-input-wrap">
                  <Lock size={14} className="form-input-icon" />
                  <input className="form-input" type={showCurrentPwd ? 'text' : 'password'} placeholder="Entrez votre mot de passe" value={currentPwd} onChange={e => setCurrentPwd(e.target.value)} required />
                  <button type="button" className="pwd-eye" onClick={() => setShowCurrentPwd(v => !v)}>
                    {showCurrentPwd ? <EyeOff size={14} /> : <Eye size={14} />}
                  </button>
                </div>
              </div>
              <div className="form-group">
                <label className="form-label">Nouveau mot de passe</label>
                <div className="form-input-wrap">
                  <Lock size={14} className="form-input-icon" />
                  <input className="form-input" type={showNewPwd ? 'text' : 'password'} placeholder="Min. 8 caractères" value={newPwd} onChange={e => setNewPwd(e.target.value)} required />
                  <button type="button" className="pwd-eye" onClick={() => setShowNewPwd(v => !v)}>
                    {showNewPwd ? <EyeOff size={14} /> : <Eye size={14} />}
                  </button>
                </div>
                {strength && (
                  <div className="pwd-strength">
                    <div className="pwd-strength-bar">
                      <div className="pwd-strength-fill" style={{ width: strength.w, background: strength.color }} />
                    </div>
                    <span className="pwd-strength-label" style={{ color: strength.color }}>{strength.label}</span>
                  </div>
                )}
              </div>
              <div className="form-group">
                <label className="form-label">Confirmer le nouveau mot de passe</label>
                <div className={`form-input-wrap ${confirmPwd && confirmPwd !== newPwd ? 'form-input-wrap--error' : ''}`}>
                  <Lock size={14} className="form-input-icon" />
                  <input className="form-input" type={showConfirmPwd ? 'text' : 'password'} placeholder="Entrez votre mot de passe" value={confirmPwd} onChange={e => setConfirmPwd(e.target.value)} required />
                  <button type="button" className="pwd-eye" onClick={() => setShowConfirmPwd(v => !v)}>
                    {showConfirmPwd ? <EyeOff size={14} /> : <Eye size={14} />}
                  </button>
                </div>
                {confirmPwd && confirmPwd !== newPwd && <span className="pwd-mismatch">Les mots de passe ne correspondent pas</span>}
              </div>
              <div className="settings-card-footer">
                <button type="submit" className="settings-save-btn" disabled={pwdLoading || !currentPwd || !newPwd || !confirmPwd}>
                  {pwdLoading ? <Loader2 size={15} className="spin" /> : <KeyRound size={15} />}
                  {pwdLoading ? 'Modification…' : 'Modifier le mot de passe'}
                </button>
              </div>
            </form>

            <div className="settings-security-right">

              {/* Privacy */}
              <div className="settings-card">
                <div className="settings-card-header">
                  <div className={`settings-card-icon settings-card-icon--eye`}>
                    {onlineVisible ? <Eye size={15} /> : <EyeOff size={15} />}
                  </div>
                  <div>
                    <h2 className="settings-card-title">Confidentialité</h2>
                    <p className="settings-card-desc">Visibilité de votre présence en ligne</p>
                  </div>
                </div>
                <div className="settings-toggle-row">
                  <div className="settings-toggle-info">
                    <p className="settings-toggle-label">Statut en ligne visible</p>
                    <p className="settings-toggle-hint">{onlineVisible ? 'Les autres voient quand vous êtes connecté.' : 'Votre statut est masqué pour tous.'}</p>
                  </div>
                  <button role="switch" aria-checked={onlineVisible} className={`settings-toggle-switch ${onlineVisible ? 'settings-toggle-switch--on' : ''}`} onClick={() => handleOnlineVisibleToggle(!onlineVisible)}>
                    <span className="settings-toggle-thumb" />
                  </button>
                </div>
              </div>

              {/* 2FA */}
              <div className="settings-card">
                <div className="settings-card-header">
                  <div className={`settings-card-icon ${twoFaEnabled ? 'settings-card-icon--green' : 'settings-card-icon--muted'}`}>
                    {twoFaEnabled ? <ShieldCheck size={15} /> : <Lock size={15} />}
                  </div>
                  <div>
                    <h2 className="settings-card-title">Double authentification</h2>
                    <p className="settings-card-desc">Couche de sécurité supplémentaire</p>
                  </div>
                </div>
                {twoFaEnabled ? (
                  <div className="twofa-section">
                    <div className="twofa-status twofa-status--on"><ShieldCheck size={13} /> 2FA activé</div>
                    <p className="settings-toggle-hint">Entrez le code de votre application d'authentification pour désactiver.</p>
                    <div className="twofa-input-row">
                      <input className="form-input" type="text" inputMode="numeric" placeholder="Code à 6 chiffres" maxLength={6} value={disablePass} onChange={e => setDisablePass(e.target.value.replace(/\D/g, ''))} style={{ letterSpacing: '0.2em', textAlign: 'center' }} />
                      <button className="twofa-btn twofa-btn--disable" onClick={handleDisable2fa} disabled={twoFaLoading || disablePass.length !== 6}>
                        {twoFaLoading ? <Loader2 size={13} className="spin" /> : <ShieldOff size={13} />} Désactiver
                      </button>
                    </div>
                  </div>
                ) : qrCode ? (
                  <div className="twofa-section">
                    <p className="settings-toggle-hint">Scannez avec <strong style={{ color: 'var(--text-secondary)' }}>Google Authenticator</strong> puis entrez le code.</p>
                    <div className="twofa-qr"><QRCodeSVG value={qrCode} size={140} bgColor="#ffffff" fgColor="#000000" /></div>
                    <div className="twofa-input-row">
                      <input className="form-input" type="text" placeholder="Code à 6 chiffres" value={twoFaCode} onChange={e => setTwoFaCode(e.target.value)} maxLength={6} style={{ letterSpacing: '0.2em', textAlign: 'center' }} />
                      <button className="twofa-btn twofa-btn--confirm" onClick={handleConfirm2fa} disabled={twoFaLoading}>
                        {twoFaLoading ? <Loader2 size={13} className="spin" /> : <ShieldCheck size={13} />} Confirmer
                      </button>
                    </div>
                  </div>
                ) : (
                  <div className="twofa-section">
                    <div className="twofa-status twofa-status--off"><ShieldOff size={13} /> 2FA désactivé</div>
                    <p className="settings-toggle-hint">Protégez votre compte avec Google Authenticator.</p>
                    <button className="twofa-btn twofa-btn--enable" onClick={handleEnable2fa} disabled={twoFaLoading}>
                      {twoFaLoading ? <Loader2 size={13} className="spin" /> : <QrCode size={13} />} Activer le 2FA
                    </button>
                  </div>
                )}
              </div>

            </div>
          </div>

          {/* ══ SECTION: DANGER ══ */}
          <div className="settings-section-label settings-section-label--danger"><span>Zone de danger</span></div>

          <div className="settings-card danger-zone">
            <div className="settings-card-header">
              <div className="settings-card-icon settings-card-icon--danger"><Trash2 size={15} /></div>
              <div>
                <h2 className="settings-card-title">Supprimer mon compte</h2>
                <p className="settings-card-desc">Action définitive et irréversible</p>
              </div>
            </div>
            <p className="danger-text">
              La suppression est permanente. Toutes vos données médicales, conversations et documents seront effacés sans possibilité de récupération.
            </p>
            {!showDelete ? (
              <button className="danger-btn" onClick={() => setShowDelete(true)}>
                <Trash2 size={14} /> Supprimer mon compte
              </button>
            ) : (
              <div className="danger-confirm">
                <input className="form-input" type="password" placeholder="Confirmez votre mot de passe" value={deletePass} onChange={e => setDeletePass(e.target.value)} />
                <div className="danger-confirm-actions">
                  <button className="danger-btn" onClick={handleDeleteAccount}>Confirmer la suppression</button>
                  <button className="cancel-btn" onClick={() => { setShowDelete(false); setDeletePass(''); }}>Annuler</button>
                </div>
              </div>
            )}
          </div>

        </div>
      </div>
    </>
  );
}
