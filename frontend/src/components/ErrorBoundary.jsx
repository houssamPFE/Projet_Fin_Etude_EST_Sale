import { Component } from 'react';

export default class ErrorBoundary extends Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }

  componentDidCatch(error, info) {
    console.error('[ErrorBoundary]', error, info);
  }

  handleReload = () => {
    this.setState({ hasError: false, error: null });
    window.location.reload();
  };

  render() {
    if (!this.state.hasError) return this.props.children;

    return (
      <div style={styles.wrapper}>
        <div style={styles.card}>
          <div style={styles.icon}>⚠</div>
          <h2 style={styles.title}>Une erreur est survenue</h2>
          <p style={styles.msg}>
            La page a rencontré un problème inattendu. Cela n'affecte pas vos données.
          </p>
          {this.state.error?.message && (
            <code style={styles.code}>{this.state.error.message}</code>
          )}
          <div style={styles.actions}>
            <button style={styles.btnPrimary} onClick={this.handleReload}>
              Recharger la page
            </button>
            <button style={styles.btnSecondary} onClick={() => window.history.back()}>
              Retour
            </button>
          </div>
        </div>
      </div>
    );
  }
}

const styles = {
  wrapper: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: '100vh',
    background: '#f8f9fa',
    padding: '1rem',
  },
  card: {
    background: '#ffffff',
    border: '1px solid #dee2e6',
    borderTop: '4px solid #ef4444',
    borderRadius: 6,
    padding: '2.5rem 2rem',
    maxWidth: 460,
    width: '100%',
    textAlign: 'center',
    boxShadow: '0 4px 24px rgba(0,0,0,0.08)',
  },
  icon: {
    fontSize: '2.5rem',
    marginBottom: '1rem',
    color: '#ef4444',
  },
  title: {
    fontSize: '1.125rem',
    fontWeight: 700,
    color: '#212529',
    margin: '0 0 0.5rem',
  },
  msg: {
    fontSize: '0.875rem',
    color: '#6c757d',
    margin: '0 0 1rem',
    lineHeight: 1.6,
  },
  code: {
    display: 'block',
    background: '#f8f9fa',
    border: '1px solid #dee2e6',
    borderRadius: 3,
    padding: '0.5rem 0.75rem',
    fontSize: '0.75rem',
    color: '#dc2626',
    textAlign: 'left',
    marginBottom: '1.5rem',
    wordBreak: 'break-word',
    fontFamily: 'monospace',
  },
  actions: {
    display: 'flex',
    gap: '0.75rem',
    justifyContent: 'center',
  },
  btnPrimary: {
    padding: '0.5rem 1.25rem',
    background: '#2563eb',
    color: '#fff',
    border: 'none',
    borderRadius: 4,
    fontWeight: 600,
    fontSize: '0.875rem',
    cursor: 'pointer',
  },
  btnSecondary: {
    padding: '0.5rem 1.25rem',
    background: '#f8f9fa',
    color: '#495057',
    border: '1px solid #ced4da',
    borderRadius: 4,
    fontWeight: 600,
    fontSize: '0.875rem',
    cursor: 'pointer',
  },
};
