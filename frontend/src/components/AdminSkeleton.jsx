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
