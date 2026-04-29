import { Outlet, useLocation } from 'react-router-dom';
import { motion, AnimatePresence, LayoutGroup } from 'framer-motion';
import { ShieldCheck, Stethoscope, Sparkles } from 'lucide-react';
import NexoraBackground from '../components/NexoraBackground';
import './AuthLayout.css';

const SWAP_TRANSITION = { duration: 0.7, ease: [0.32, 0.72, 0, 1] };

const COPY = {
  login: {
    title: 'Bon retour parmi nous.',
    subtitle: 'Votre espace santé sécurisé. Reprenez votre suivi en un clic.',
    accent: 'Vos médecins. Disponibles 24/7.',
    pills: [
      { icon: ShieldCheck, label: 'Consultations confidentielles' },
      { icon: Sparkles,    label: 'Triage IA en français + arabe' },
      { icon: Stethoscope, label: '8 spécialités · médecins INPE' },
    ],
  },
  register: {
    title: 'Créez votre espace santé.',
    subtitle: 'Inscription en moins de 2 minutes. Premier avis IA gratuit.',
    accent: 'Rejoignez 27 000 patients déjà inscrits.',
    pills: [
      { icon: Sparkles,    label: 'Triage médical IA bilingue' },
      { icon: Stethoscope, label: '8 spécialités, expertise nationale' },
      { icon: ShieldCheck, label: 'Données chiffrées · secret médical' },
    ],
  },
};

export default function AuthLayout() {
  const location = useLocation();
  const mode = location.pathname.includes('register') ? 'register' : 'login';
  const formOnLeft = mode === 'register';
  const copy = COPY[mode];

  return (
    <div className="auth-layout">
      <NexoraBackground />

      <LayoutGroup>
        <div className="auth-container">

          {/* ── BRAND PANEL ────────────────────────────────── */}
          <motion.div
            layout
            transition={SWAP_TRANSITION}
            className="auth-branding"
            style={{ order: formOnLeft ? 1 : 0 }}
          >
            <div className="auth-grid-pattern" />
            <div className="auth-brand-glow auth-brand-glow--1" />
            <div className="auth-brand-glow auth-brand-glow--2" />

            {/* Top row: logo only */}
            <div className="auth-brand-top">
              <div className="auth-brand-logo">
                <img src="/logo.png" alt="Nexora" className="auth-brand-img" />
                <div className="auth-brand-text">
                  <h1 className="auth-brand-name">NEXORA</h1>
                  <span className="auth-brand-slogan">Médecine intelligente</span>
                </div>
              </div>
            </div>

            {/* Middle: pitch */}
            <AnimatePresence mode="wait">
              <motion.div
                key={mode}
                initial={{ opacity: 0, y: 16 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -16 }}
                transition={{ duration: 0.45, delay: 0.15 }}
                className="auth-brand-pitch"
              >
                <div className="auth-brand-headline">
                  <h2 className="auth-brand-title">{copy.title}</h2>
                  <p className="auth-brand-tagline">{copy.subtitle}</p>
                </div>

                <div className="auth-brand-bottom">
                  <div className="auth-brand-accent">{copy.accent}</div>

                  <div className="auth-pills">
                    {copy.pills.map((p, i) => {
                      const Icon = p.icon;
                      return (
                        <motion.div
                          key={p.label}
                          className="auth-pill"
                          initial={{ opacity: 0, x: formOnLeft ? 18 : -18 }}
                          animate={{ opacity: 1, x: 0 }}
                          transition={{ delay: 0.25 + i * 0.06 }}
                        >
                          <span className="auth-pill-icon">
                            <Icon size={13} />
                          </span>
                          {p.label}
                        </motion.div>
                      );
                    })}
                  </div>
                </div>
              </motion.div>
            </AnimatePresence>

          </motion.div>

          {/* ── FORM PANEL ─────────────────────────────────── */}
          <motion.div
            layout
            transition={SWAP_TRANSITION}
            className="auth-form-panel"
            style={{ order: formOnLeft ? 0 : 1 }}
          >
            <div className="auth-form-deco" />
            <AnimatePresence mode="wait">
              <motion.div
                key={mode}
                initial={{ opacity: 0, y: 12 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -12 }}
                transition={{ duration: 0.4, delay: 0.2 }}
                className="auth-form-inner"
              >
                <Outlet />
              </motion.div>
            </AnimatePresence>
          </motion.div>

        </div>
      </LayoutGroup>
    </div>
  );
}
