import { Wrench } from 'lucide-react';
import './MaintenancePage.css';

export default function MaintenancePage() {
  return (
    <div className="maint-page">
      <div className="maint-card">
        <div className="maint-icon"><Wrench size={32} /></div>
        <h1 className="maint-title">Maintenance en cours</h1>
        <p className="maint-desc">
          La plateforme Nexora est temporairement indisponible pour maintenance.
          Nos équipes travaillent à la remettre en ligne le plus rapidement possible.
        </p>
        <div className="maint-disclaimer">
          En cas d'urgence médicale, appelez le <strong>15</strong> (SAMU Maroc)
          ou rendez-vous aux urgences les plus proches.
        </div>
        <button className="maint-retry" onClick={() => window.location.reload()}>
          Réessayer
        </button>
      </div>
    </div>
  );
}
