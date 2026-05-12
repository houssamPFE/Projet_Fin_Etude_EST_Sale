import { useState, useEffect } from 'react';
import { Loader2, Save } from 'lucide-react';
import { useAdminSettings, useUpdateAdminSettings } from '../../hooks/useAdmin';
import './AdminSettingsPage.css';

export default function AdminSettingsPage() {
  const { data, isLoading } = useAdminSettings();
  const updateSettings = useUpdateAdminSettings();
  const [localSettings, setLocalSettings] = useState({});

  useEffect(() => {
    if (data?.flat) {
      setLocalSettings(data.flat);
    }
  }, [data]);

  const handleChange = (key, value) => {
    setLocalSettings(prev => ({ ...prev, [key]: value }));
  };

  const handleSave = () => {
    updateSettings.mutate(localSettings);
  };

  if (isLoading) {
    return (
      <div className="admin-settings">
        <div className="page-header">
          <h1>Paramètres système</h1>
        </div>
        <div className="settings-loading"><Loader2 className="spin" size={24} /></div>
      </div>
    );
  }

  const groupedSettings = data?.data || {};

  return (
    <div className="admin-settings">
      <div className="page-header">
        <h1>Paramètres système</h1>
        <p>Gérez la configuration globale de la plateforme Nexora.</p>
      </div>

      {Object.entries(groupedSettings)
        .filter(([group]) => !['ai', 'security', 'platform'].includes(group))
        .map(([group, settings]) => (
        <div key={group} className="settings-group">
          <div className="settings-group-header">
            {group === 'general' ? 'Général' :
             group === 'security' ? 'Sécurité' :
             group === 'ai' ? 'Intelligence Artificielle' :
             group === 'financial' ? 'Finances' : group}
          </div>
          <div className="settings-list">
            {settings.map((setting) => (
              <div key={setting.key} className="setting-item">
                <div className="setting-info">
                  <span className="setting-label">{setting.label}</span>
                  <span className="setting-desc">{setting.description}</span>
                </div>
                <div className="setting-control">
                  {setting.type === 'boolean' ? (
                    <label className="switch">
                      <input
                        type="checkbox"
                        checked={localSettings[setting.key] ?? setting.value}
                        onChange={(e) => handleChange(setting.key, e.target.checked)}
                        disabled={updateSettings.isPending}
                      />
                      <span className="slider"></span>
                    </label>
                  ) : (
                    <input
                      type={setting.type === 'integer' || setting.type === 'decimal' ? 'number' : 'text'}
                      className="setting-input"
                      value={localSettings[setting.key] ?? setting.value}
                      onChange={(e) => {
                        let val = e.target.value;
                        if (setting.type === 'integer') val = parseInt(val, 10);
                        else if (setting.type === 'decimal') val = parseFloat(val);
                        handleChange(setting.key, val);
                      }}
                      disabled={updateSettings.isPending}
                    />
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      ))}

      <div className="settings-save-bar">
        <button
          className="btn-save-settings"
          onClick={handleSave}
          disabled={updateSettings.isPending}
        >
          {updateSettings.isPending ? <Loader2 className="spin" size={16} /> : <Save size={16} />}
          Enregistrer les modifications
        </button>
      </div>
    </div>
  );
}
