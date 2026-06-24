import './AdminSkeleton.css';

export function TableSkeleton({ rows = 6, cols = 5 }) {
  return (
    <div className="sk-table-wrap">
      <table className="sk-table">
        <thead>
          <tr>
            {Array.from({ length: cols }).map((_, i) => (
              <th key={i}><div className="sk-block sk-th" /></th>
            ))}
          </tr>
        </thead>
        <tbody>
          {Array.from({ length: rows }).map((_, r) => (
            <tr key={r}>
              {Array.from({ length: cols }).map((_, c) => (
                <td key={c}>
                  <div className="sk-block" style={{ width: c === 0 ? '2rem' : c === cols - 1 ? '5rem' : `${60 + Math.random() * 30}%` }} />
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export function StatCardsSkeleton({ count = 4 }) {
  return (
    <div className="sk-cards">
      {Array.from({ length: count }).map((_, i) => (
        <div key={i} className="sk-card">
          <div className="sk-block sk-card-icon" />
          <div className="sk-card-body">
            <div className="sk-block sk-card-val" />
            <div className="sk-block sk-card-label" />
          </div>
        </div>
      ))}
    </div>
  );
}

export function SettingsSkeleton({ rows = 3 }) {
  return (
    <div className="sk-settings">
      {Array.from({ length: rows }).map((_, i) => (
        <div key={i} className="sk-setting-row">
          <div className="sk-setting-info">
            <div className="sk-block sk-setting-label" />
            <div className="sk-block sk-setting-desc" />
          </div>
          <div className="sk-block sk-toggle" />
        </div>
      ))}
    </div>
  );
}

export function ChartSkeleton({ height = 180 }) {
  return (
    <div style={{ padding: '0.75rem 1rem 1rem' }}>
      <div style={{ display: 'flex', alignItems: 'flex-end', gap: 6, height }}>
        {[55, 80, 40, 95, 60, 75, 45].map((h, i) => (
          <div
            key={i}
            className="sk-block"
            style={{ flex: 1, height: `${h}%`, borderRadius: 3 }}
          />
        ))}
      </div>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 8 }}>
        {[...Array(7)].map((_, i) => (
          <div key={i} className="sk-block" style={{ width: 28, height: 10 }} />
        ))}
      </div>
    </div>
  );
}

export function DonutSkeleton() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '1.5rem 1rem', gap: 12 }}>
      <div className="sk-block" style={{ width: 140, height: 140, borderRadius: '50%' }} />
      <div style={{ display: 'flex', gap: 12 }}>
        <div className="sk-block" style={{ width: 60, height: 10 }} />
        <div className="sk-block" style={{ width: 60, height: 10 }} />
      </div>
    </div>
  );
}

export function MiniTableSkeleton({ rows = 4 }) {
  return (
    <div className="sk-mini-wrap">
      <div className="sk-mini-head">
        {[40, 30, 20, 15].map((w, i) => (
          <div key={i} className="sk-block" style={{ flex: w, height: 10 }} />
        ))}
      </div>
      {[...Array(rows)].map((_, r) => (
        <div key={r} className="sk-mini-row">
          {[40, 30, 20, 15].map((w, i) => (
            <div key={i} className="sk-block" style={{ flex: w, height: 12 }} />
          ))}
        </div>
      ))}
    </div>
  );
}

export function KbSkeleton({ count = 4 }) {
  return (
    <div className="sk-kb">
      {Array.from({ length: count }).map((_, i) => (
        <div key={i} className="sk-kb-card">
          <div className="sk-kb-tags">
            <div className="sk-block sk-tag" />
            <div className="sk-block sk-tag" style={{ width: '2rem' }} />
          </div>
          <div className="sk-block sk-kb-q" />
          <div className="sk-block sk-kb-a" />
          <div className="sk-block sk-kb-a" style={{ width: '70%' }} />
        </div>
      ))}
    </div>
  );
}
