<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8" />
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
  <title>Rapport de Consultation — Nexora</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }

    body {
      font-family: DejaVu Sans, Arial, sans-serif;
      font-size: 12px;
      color: #1a1a2e;
      background: #ffffff;
      padding: 0;
    }

    /* ── Header ── */
    .header {
      background: linear-gradient(135deg, #0f0c29, #302b63, #24243e);
      color: #ffffff;
      padding: 28px 40px 24px;
    }
    .header-top {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 16px;
    }
    .brand {
      font-size: 22px;
      font-weight: 700;
      letter-spacing: 1px;
      color: #a78bfa;
    }
    .brand-sub {
      font-size: 10px;
      color: rgba(255,255,255,0.55);
      margin-top: 2px;
      letter-spacing: 0.5px;
    }
    .report-label {
      background: rgba(167,139,250,0.18);
      border: 1px solid rgba(167,139,250,0.4);
      color: #c4b5fd;
      font-size: 10px;
      padding: 4px 12px;
      border-radius: 20px;
      letter-spacing: 0.5px;
      text-transform: uppercase;
    }
    .header-title {
      font-size: 17px;
      font-weight: 600;
      color: #ffffff;
    }
    .header-date {
      font-size: 10px;
      color: rgba(255,255,255,0.5);
      margin-top: 4px;
    }

    /* ── Body ── */
    .body {
      padding: 32px 40px;
    }

    /* ── Info grid ── */
    .info-grid {
      display: table;
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 28px;
    }
    .info-col {
      display: table-cell;
      width: 50%;
      vertical-align: top;
      padding-right: 20px;
    }
    .info-col:last-child { padding-right: 0; }

    .info-card {
      background: #f8f7ff;
      border: 1px solid #ede9fe;
      border-radius: 8px;
      padding: 14px 16px;
    }
    .info-card-title {
      font-size: 9px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.8px;
      color: #7c3aed;
      margin-bottom: 8px;
    }
    .info-row {
      margin-bottom: 5px;
      font-size: 11px;
      color: #374151;
    }
    .info-label {
      color: #6b7280;
      font-size: 10px;
    }
    .info-value {
      font-weight: 600;
      color: #111827;
    }

    /* ── Divider ── */
    .divider {
      border: none;
      border-top: 1px solid #ede9fe;
      margin: 0 0 24px;
    }

    /* ── Summary section ── */
    .section-title {
      font-size: 11px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.8px;
      color: #7c3aed;
      margin-bottom: 12px;
      display: flex;
      align-items: center;
      gap: 6px;
    }
    .section-title::after {
      content: '';
      flex: 1;
      height: 1px;
      background: #ede9fe;
    }

    .summary-box {
      background: #f8f7ff;
      border-left: 3px solid #7c3aed;
      border-radius: 0 8px 8px 0;
      padding: 16px 20px;
      font-size: 12px;
      line-height: 1.7;
      color: #374151;
      margin-bottom: 28px;
    }
    .no-summary {
      color: #9ca3af;
      font-style: italic;
      font-size: 11px;
      padding: 12px 0;
    }

    /* ── Stats row ── */
    .stats-row {
      display: table;
      width: 100%;
      border-collapse: separate;
      border-spacing: 12px 0;
      margin: 0 -12px 28px;
    }
    .stat-cell {
      display: table-cell;
      width: 33.33%;
      background: #f8f7ff;
      border: 1px solid #ede9fe;
      border-radius: 8px;
      padding: 12px 16px;
      text-align: center;
      vertical-align: middle;
    }
    .stat-value {
      font-size: 20px;
      font-weight: 700;
      color: #7c3aed;
    }
    .stat-label {
      font-size: 9px;
      color: #6b7280;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      margin-top: 3px;
    }

    /* ── Disclaimer ── */
    .disclaimer {
      background: #fff7ed;
      border: 1px solid #fed7aa;
      border-radius: 8px;
      padding: 12px 16px;
      font-size: 10px;
      color: #92400e;
      line-height: 1.6;
      margin-bottom: 24px;
    }
    .disclaimer strong { color: #78350f; }

    /* ── Footer ── */
    .footer {
      border-top: 1px solid #ede9fe;
      padding: 16px 40px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      font-size: 9px;
      color: #9ca3af;
    }
    .footer-brand { color: #7c3aed; font-weight: 600; }

    /* ── Badge ── */
    .status-badge {
      display: inline-block;
      background: #dcfce7;
      color: #166534;
      font-size: 9px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      padding: 3px 10px;
      border-radius: 20px;
    }

    .specialty-badge {
      display: inline-block;
      background: #ede9fe;
      color: #5b21b6;
      font-size: 9px;
      font-weight: 600;
      padding: 3px 10px;
      border-radius: 20px;
    }
  </style>
</head>
<body>

  <!-- ── Header ── -->
  <div class="header">
    <div class="header-top">
      <div>
        <div class="brand">NEXORA</div>
        <div class="brand-sub">Plateforme de téléconsultation médicale</div>
      </div>
      <div class="report-label">Rapport de consultation</div>
    </div>
    <div class="header-title">
      {{ $conversation->title ?? 'Consultation #' . $conversation->id }}
    </div>
    <div class="header-date">
      Généré le {{ now()->locale('fr')->isoFormat('D MMMM YYYY [à] HH:mm') }}
    </div>
  </div>

  <!-- ── Body ── -->
  <div class="body">

    <!-- Info grid -->
    <div class="info-grid">
      <!-- Patient -->
      <div class="info-col">
        <div class="info-card">
          <div class="info-card-title">Patient</div>
          <div class="info-row">
            <span class="info-label">Nom : </span>
            <span class="info-value">{{ $conversation->user->name ?? 'N/A' }}</span>
          </div>
          <div class="info-row">
            <span class="info-label">Email : </span>
            <span class="info-value">{{ $conversation->user->email ?? 'N/A' }}</span>
          </div>
          <div class="info-row">
            <span class="info-label">Statut : </span>
            <span class="status-badge">Consultation terminée</span>
          </div>
        </div>
      </div>

      <!-- Médecin -->
      <div class="info-col">
        <div class="info-card">
          <div class="info-card-title">Médecin</div>
          @if($conversation->expert)
            <div class="info-row">
              <span class="info-label">Nom : </span>
              <span class="info-value">Dr. {{ $conversation->expert->user->name ?? 'N/A' }}</span>
            </div>
            <div class="info-row">
              <span class="info-label">Spécialité : </span>
              <span class="specialty-badge">{{ $conversation->category->name ?? 'N/A' }}</span>
            </div>
            <div class="info-row">
              <span class="info-label">Note : </span>
              <span class="info-value">{{ number_format($conversation->expert->rating_avg, 1) }} / 5</span>
            </div>
          @else
            <div class="info-row">
              <span class="info-label">Type : </span>
              <span class="info-value">Assistant IA Nexora</span>
            </div>
            <div class="info-row">
              <span class="info-label">Spécialité : </span>
              <span class="specialty-badge">{{ $conversation->category->name ?? 'N/A' }}</span>
            </div>
          @endif
        </div>
      </div>
    </div>

    <!-- Stats -->
    <div class="stats-row">
      <div class="stat-cell">
        <div class="stat-value">{{ $conversation->messages->count() }}</div>
        <div class="stat-label">Messages échangés</div>
      </div>
      <div class="stat-cell">
        <div class="stat-value">
          {{ $conversation->created_at->locale('fr')->isoFormat('D MMM') }}
        </div>
        <div class="stat-label">Date de début</div>
      </div>
      <div class="stat-cell">
        <div class="stat-value">
          {{ $conversation->closed_at ? $conversation->closed_at->locale('fr')->isoFormat('D MMM') : 'N/A' }}
        </div>
        <div class="stat-label">Date de clôture</div>
      </div>
    </div>

    <hr class="divider" />

    <!-- Summary -->
    <div class="section-title">Résumé de la consultation</div>
    @if($conversation->summary)
      <div class="summary-box">{{ $conversation->summary }}</div>
    @else
      <div class="summary-box">
        <span class="no-summary">Résumé non disponible — la consultation n'a pas encore été analysée par l'IA.</span>
      </div>
    @endif

    <!-- Disclaimer -->
    <div class="disclaimer">
      <strong>⚠ Avertissement médical :</strong> Ce rapport est fourni à titre informatif uniquement
      et ne remplace pas une consultation médicale en personne. Les informations contenues dans ce
      document ne constituent pas un diagnostic médical. En cas d'urgence ou si votre état de santé
      s'aggrave, appelez immédiatement le <strong>141 (SAMU Maroc)</strong> ou rendez-vous aux
      urgences les plus proches.
    </div>

  </div>

  <!-- ── Footer ── -->
  <div class="footer">
    <div>
      <span class="footer-brand">Nexora</span> — Plateforme de téléconsultation médicale &copy; {{ date('Y') }}
    </div>
    <div>Consultation #{{ $conversation->id }} — Document confidentiel</div>
  </div>

</body>
</html>
