import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Cpu, Save, Loader2, Wrench, UserPlus, Settings, AlertTriangle } from 'lucide-react';
import { useAdminSettings, useUpdateAdminSettings } from '../../hooks/useAdmin';
import { SettingsSkeleton } from '../../components/AdminSkeleton';
import './AdminAIPage.css';
import './AdminSystemPage.css';

const KEY_ICONS = {
  maintenance: Wrench,
  registration: UserPlus,
  inscription: UserPlus,
  signup: UserPlus,
};
function settingIcon(key = '') {
  const lower = key.toLowerCase();
  for (const [k, Ic] of Object.entries(KEY_ICONS)) if (lower.includes(k)) return Ic;
  return Settings;
}

const DANGER_KEYS = ['maintenance'];
function isDanger(key = '') { return DANGER_KEYS.some(k => key.toLowerCase().includes(k)); }

function SettingCard({ setting, value, onChange, disabled }) {
  const Icon   = settingIcon(setting.key);
  const danger = isDanger(setting.key);
  const current = value !== undefined ? value : setting.value;
  return (
    <div className={`ai-setting-card${danger ? ' sys-card--danger' : ''}`}>
      <div className={`ai-setting-ico${danger ? ' sys-ico--danger' : ''}`}><Icon size={17} /></div>
      <div className="ai-setting-body">
        <div className="ai-setting-name">
          {setting.label}
          {danger && <span className="sys-danger-tag"><AlertTriangle size={10} /> Critique</span>}
        </div>
        <div className="ai-setting-desc">{setting.description}</div>
      </div>
      <div className="ai-setting-control">
        {setting.type === 'boolean' ? (
          <label className={`ai-toggle${danger ? ' sys-toggle--danger' : ''}`}>
            <input
              type="checkbox"
              checked={Boolean(current)}
              onChange={e => onChange(setting.key, e.target.checked)}
              disabled={disabled}
            />
            <span className="ai-toggle-track" />
          </label>
        ) : (
          <input
            type="number"
            className="ai-num-input"
            value={current ?? ''}
            step={setting.type === 'decimal' ? '0.01' : '1'}
            min={0}
            onChange={e => {
              let val = e.target.value;
              if (setting.type === 'integer') val = parseInt(val, 10);
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

export default function AdminSystemPage() {
  const { data, isLoading } = useAdminSettings();
  const updateSettings = useUpdateAdminSettings();
  const [local, setLocal] = useState({});

  useEffect(() => {
    if (data?.data?.platform) {
      setLocal(data.data.platform.reduce((acc, s) => ({ ...acc, [s.key]: s.value }), {}));
    }
  }, [data]);

  const handleChange = (key, value) => setLocal(p => ({ ...p, [key]: value }));
  const handleSave   = () => updateSettings.mutate(local);

  const platSettings = data?.data?.platform ?? [];

  return (
    <div className="ai-page">

      {/* Header */}
      <motion.div className="ai-head"
        initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.25 }}
      >
        <div className="ai-head-ico sys-head-ico"><Cpu size={20} /></div>
        <div>
          <h1 className="ai-head-title">Système & Maintenance</h1>
          <p className="ai-head-sub">État global de la plateforme, mode maintenance et accès utilisateurs</p>
        </div>
      </motion.div>

      {/* Settings */}
      <motion.section className="ai-section"
        initial={{ opacity: 0, y: 6 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.06, duration: 0.25 }}
      >
        <div className="ai-section-head">
          <span className="ai-section-title">Paramètres</span>
          <span className="ai-section-count">{platSettings.length} paramètre{platSettings.length !== 1 ? 's' : ''}</span>
        </div>

        {isLoading ? (
          <div className="ai-skeleton-wrap"><SettingsSkeleton rows={2} /></div>
        ) : platSettings.length === 0 ? (
          <div className="ai-empty">Aucun paramètre disponible.</div>
        ) : (
          <div className="ai-settings-list">
            {platSettings.map((s, idx) => (
              <motion.div key={s.key}
                initial={{ opacity: 0, y: 4 }} animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.08 + idx * 0.05, duration: 0.2 }}
              >
                <SettingCard
                  setting={s}
                  value={local[s.key]}
                  onChange={handleChange}
                  disabled={updateSettings.isPending}
                />
              </motion.div>
            ))}
          </div>
        )}

        <div className="ai-save-row">
          <button className="ai-btn-save" onClick={handleSave} disabled={updateSettings.isPending || isLoading}>
            {updateSettings.isPending
              ? <><Loader2 size={14} className="ai-spin" /> Enregistrement…</>
              : <><Save size={14} /> Enregistrer les modifications</>}
          </button>
        </div>
      </motion.section>

    </div>
  );
}
