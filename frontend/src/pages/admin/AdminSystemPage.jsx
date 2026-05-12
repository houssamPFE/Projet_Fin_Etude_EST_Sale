import { useState, useEffect } from 'react';
import { Save } from 'lucide-react';
import { useAdminSettings, useUpdateAdminSettings } from '../../hooks/useAdmin';
import { SettingsSkeleton } from '../../components/AdminSkeleton';
import './AdminConfigPage.css';

export default function AdminSystemPage() {
  const { data, isLoading } = useAdminSettings();
  const updateSettings = useUpdateAdminSettings();
  const [localSettings, setLocalSettings] = useState({});

  useEffect(() => {
    if (data?.data?.platform) {
      const platSettings = data.data.platform.reduce((acc, curr) => {
        acc[curr.key] = curr.value;
        return acc;
      }, {});
      setLocalSettings(platSettings);
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
      <div className="admin-config-page">
        <div className="page-header"><div><h1>Système & Maintenance</h1></div></div>
        <SettingsSkeleton rows={2} />
      </div>
    );
  }

  const platSettingsArray = data?.data?.platform || [];

  return (
    <div className="admin-config-page">
      <div className="page-header">
        <div>
          <h1>Système & Maintenance</h1>
          <p>Gérez l'état global et les accès de la plateforme.</p>
        </div>
      </div>

      <div className="table-wrap">
        <table className="config-table">
          <thead>
            <tr>
              <th>Paramètre</th>
              <th className="control-cell">Valeur</th>
            </tr>
          </thead>
          <tbody>
            {platSettingsArray.map((setting) => (
              <tr key={setting.key}>
                <td>
                  <span className="setting-name">{setting.label}</span>
                  <span className="setting-desc">{setting.description}</span>
                </td>
                <td className="control-cell">
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
                      className="config-input"
                      value={localSettings[setting.key] ?? setting.value}
                      step={setting.type === 'decimal' ? '0.01' : '1'}
                      onChange={(e) => {
                        let val = e.target.value;
                        if (setting.type === 'integer') val = parseInt(val, 10);
                        else if (setting.type === 'decimal') val = parseFloat(val);
                        handleChange(setting.key, val);
                      }}
                      disabled={updateSettings.isPending}
                    />
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
        <button
          className="btn-save-inline"
          onClick={handleSave}
          disabled={updateSettings.isPending}
        >
          {updateSettings.isPending ? <Loader2 className="spin" size={14} /> : <Save size={14} />}
          Enregistrer les modifications
        </button>
      </div>
    </div>
  );
}
