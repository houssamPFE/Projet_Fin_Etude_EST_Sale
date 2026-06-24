import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Settings, Save, Loader2,
  Bot, Target, Cpu, Wrench, UserPlus,
  AlertTriangle, Shield, Zap, Clock, Users,
  ChevronRight,
} from 'lucide-react';
import { useAdminSettings, useUpdateAdminSettings } from '../../hooks/useAdmin';
import { SettingsSkeleton } from '../../components/AdminSkeleton';
import './AdminAIPage.css';

/* ── Icon map ── */
const KEY_ICONS = {
  ai:           Bot,
  tts:          Zap,
  seuil:        Target,
  threshold:    Target,
  escalade:     Target,
  maintenance:  Wrench,
  registration: UserPlus,
  inscription:  UserPlus,
  signup:       UserPlus,
  timeout:      Clock,
  max:          Users,
  security:     Shield,
};
function settingIcon(key = '') {
  const lower = key.toLowerCase();
  for (const [k, Ic] of Object.entries(KEY_ICONS)) if (lower.includes(k)) return Ic;
  return Settings;
}

const DANGER_KEYS = ['maintenance'];
function isDanger(key = '') { return DANGER_KEYS.some(k => key.toLowerCase().includes(k)); }

/* ── Setting card ── */
function SettingCard({ setting, value, onChange, disabled }) {
  const Icon    = settingIcon(setting.key);
  const danger  = isDanger(setting.key);
  const current = value !== undefined ? value : setting.value;
  return (
    <div className={`cfg-card${danger ? ' cfg-card--danger' : ''}`}>
      <div className={`cfg-card-ico${danger ? ' cfg-card-ico--danger' : ''}`}>
        <Icon size={17} />
      </div>
      <div className="cfg-card-body">
        <div className="cfg-card-name">
          {setting.label}
          {danger && (
            <span className="cfg-danger-tag">
              <AlertTriangle size={9} /> Critique
            </span>
          )}
        </div>
        <div className="cfg-card-desc">{setting.description}</div>
      </div>
      <div className="cfg-card-ctrl">
        {setting.type === 'boolean' ? (
          <label className={`cfg-toggle${danger ? ' cfg-toggle--danger' : ''}`}>
            <input
              type="checkbox"
              checked={Boolean(current)}
              onChange={e => onChange(setting.key, e.target.checked)}
              disabled={disabled}
            />
            <span className="cfg-toggle-track" />
          </label>
        ) : (
          <input
            type="number"
            className="cfg-num"
            value={current ?? ''}
            step={setting.type === 'decimal' ? '0.01' : '1'}
            min={0}
            max={setting.type === 'decimal' ? 1 : undefined}
            onChange={e => {
              let val = e.target.value;
              if (setting.type === 'integer')      val = parseInt(val, 10);
              else if (setting.type === 'decimal') val = parseFloat(val);
              onChange(setting.key, val);
            }}
            disabled={disabled}
          />
        )}
      </div>
    </div>
  );
}

/* ── Info card (static) ── */
function InfoCard({ icon: Icon, label, value, color = 'violet' }) {
  return (
    <div className={`cfg-info-card cfg-info-card--${color}`}>
      <div className="cfg-info-ico"><Icon size={16} /></div>
      <div className="cfg-info-body">
        <div className="cfg-info-label">{label}</div>
        <div className="cfg-info-value">{value}</div>
      </div>
      <ChevronRight size={14} className="cfg-info-arrow" />
    </div>
  );
}

/* ── Tabs ── */
const TABS = [
  { key: 'platform', label: 'Plateforme',            icon: Cpu },
  { key: 'ai',       label: 'Intelligence Artificielle', icon: Bot },
];

export default function AdminConfigPage() {
  const { data, isLoading }     = useAdminSettings();
  const updateSettings          = useUpdateAdminSettings();
  const [tab, setTab]           = useState('platform');
  const [local, setLocal]       = useState({});

  /* Merge all groups into local state */
  useEffect(() => {
    if (!data?.data) return;
    const merged = {};
    Object.values(data.data).forEach(group => {
      if (Array.isArray(group)) group.forEach(s => { merged[s.key] = s.value; });
    });
    setLocal(merged);
  }, [data]);

  const handleChange = (key, value) => setLocal(p => ({ ...p, [key]: value }));
  const handleSave   = () => updateSettings.mutate(local);

  const platSettings = (data?.data?.platform ?? []);
  const aiSettings   = (data?.data?.ai ?? []).filter(s => s.key !== 'tts_enabled').map(s => ({
    ...s,
    description: s.description?.replace('GPT-4', 'Groq (Llama / Mixtral)'),
  }));

  const activeSettings = tab === 'platform' ? platSettings : aiSettings;
  const isPending = updateSettings.isPending;

  return (
    <div className="cfg-page">

      {/* ── Header ── */}
      <motion.div className="cfg-head"
        initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.25 }}
      >
        <div className="cfg-head-left">
          <div className="cfg-head-ico">
            <Settings size={22} />
          </div>
          <div>
            <h1 className="cfg-head-title">Configuration</h1>
            <p className="cfg-head-sub">Gestion de la plateforme, du comportement IA et des paramètres système</p>
          </div>
        </div>
      </motion.div>

      {/* ── Tabs ── */}
      <motion.div className="cfg-tabs"
        initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.05, duration: 0.2 }}
      >
        {TABS.map(t => {
          const Icon = t.icon;
          return (
            <button
              key={t.key}
              className={`cfg-tab${tab === t.key ? ' cfg-tab--active' : ''}`}
              onClick={() => setTab(t.key)}
            >
              <Icon size={14} />
              {t.label}
            </button>
          );
        })}
      </motion.div>

      {/* ── Content ── */}
      <AnimatePresence mode="wait">
        <motion.div key={tab}
          initial={{ opacity: 0, y: 6 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -4 }}
          transition={{ duration: 0.18 }}
        >

          {/* Info cards (static) */}
          {tab === 'ai' && (
            <div className="cfg-info-row">
              <InfoCard icon={Bot}    label="Modèle LLM"       value="Groq — Llama 3 / Mixtral"      color="violet" />
              <InfoCard icon={Zap}    label="Transcription"    value="Groq Whisper API"               color="blue"   />
              <InfoCard icon={Target} label="Seuil par défaut" value="0.75 (escalade automatique)"   color="green"  />
            </div>
          )}

          {tab === 'platform' && (
            <div className="cfg-info-row">
              <InfoCard icon={Users}  label="Stack"      value="Laravel 11 + React + Flutter"  color="blue"   />
              <InfoCard icon={Shield} label="Auth"       value="Sanctum JWT + 2FA TOTP"        color="green"  />
              <InfoCard icon={Clock}  label="Cache"      value="Redis 7"                        color="violet" />
            </div>
          )}

          {/* Settings section */}
          <div className="cfg-section">
            <div className="cfg-section-head">
              <span className="cfg-section-title">Paramètres</span>
              <span className="cfg-section-count">
                {isLoading ? '…' : `${activeSettings.length} paramètre${activeSettings.length !== 1 ? 's' : ''}`}
              </span>
            </div>

            {isLoading ? (
              <div className="cfg-skeleton-wrap"><SettingsSkeleton rows={3} /></div>
            ) : activeSettings.length === 0 ? (
              <div className="cfg-empty">Aucun paramètre disponible.</div>
            ) : (
              <div className="cfg-list">
                {activeSettings.map((s, idx) => (
                  <motion.div key={s.key}
                    initial={{ opacity: 0, y: 4 }} animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: idx * 0.04, duration: 0.18 }}
                  >
                    <SettingCard
                      setting={s}
                      value={local[s.key]}
                      onChange={handleChange}
                      disabled={isPending}
                    />
                  </motion.div>
                ))}
              </div>
            )}

            <div className="cfg-save-row">
              <button className="cfg-btn-save" onClick={handleSave} disabled={isPending || isLoading}>
                {isPending
                  ? <><Loader2 size={14} className="cfg-spin" /> Enregistrement…</>
                  : <><Save size={14} /> Enregistrer les modifications</>}
              </button>
            </div>
          </div>

        </motion.div>
      </AnimatePresence>
    </div>
  );
}
