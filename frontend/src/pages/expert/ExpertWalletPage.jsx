import { useState } from 'react';
import { motion } from 'framer-motion';
import { Wallet, TrendingUp, ArrowDownCircle, Loader2, ArrowUpCircle } from 'lucide-react';
import { useExpertWallet, useExpertTransactions } from '../../hooks/useExpertPanel';
import './ExpertWalletPage.css';

function TransactionRow({ tx }) {
  const isCredit = tx.type === 'credit';
  return (
    <div className="tx-row">
      <div className={`tx-icon ${isCredit ? 'tx-icon--credit' : 'tx-icon--debit'}`}>
        {isCredit ? <ArrowUpCircle size={18} /> : <ArrowDownCircle size={18} />}
      </div>
      <div className="tx-info">
        <p className="tx-desc">{tx.description}</p>
        <p className="tx-ref">{tx.reference ?? '—'}</p>
      </div>
      <span className={`tx-amount ${isCredit ? 'tx-amount--credit' : 'tx-amount--debit'}`}>
        {isCredit ? '+' : '-'}{tx.amount} MAD
      </span>
    </div>
  );
}

export default function ExpertWalletPage() {
  const [page, setPage] = useState(1);
  const { data: wallet, isLoading: walletLoading } = useExpertWallet();
  const { data: txData, isLoading: txLoading } = useExpertTransactions(page);

  const transactions = txData?.data ?? [];

  return (
    <div className="expert-wallet-page">
      <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.4 }}>

        <div style={{ marginBottom: 'var(--space-lg)' }}>
          <h1 className="page-title">Mon portefeuille</h1>
          <p className="page-subtitle">Suivi de vos gains et transactions</p>
        </div>

        {walletLoading ? (
          <div style={{ display: 'flex', justifyContent: 'center', padding: 60 }}>
            <Loader2 size={32} className="spin" style={{ color: 'var(--primary-500)' }} />
          </div>
        ) : (
          <>
            <div className="wallet-cards">
              <motion.div className="wallet-card wallet-card--balance" initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0 }}>
                <div className="wallet-card-icon"><Wallet size={24} /></div>
                <div>
                  <p className="wallet-card-label">Solde disponible</p>
                  <p className="wallet-card-value">{wallet?.balance ?? '0.00'} MAD</p>
                </div>
              </motion.div>
              <motion.div className="wallet-card wallet-card--earned" initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.08 }}>
                <div className="wallet-card-icon"><TrendingUp size={24} /></div>
                <div>
                  <p className="wallet-card-label">Total gagné</p>
                  <p className="wallet-card-value">{wallet?.total_earned ?? '0.00'} MAD</p>
                </div>
              </motion.div>
              <motion.div className="wallet-card wallet-card--withdrawn" initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.16 }}>
                <div className="wallet-card-icon"><ArrowDownCircle size={24} /></div>
                <div>
                  <p className="wallet-card-label">Total retiré</p>
                  <p className="wallet-card-value">{wallet?.total_withdrawn ?? '0.00'} MAD</p>
                </div>
              </motion.div>
            </div>

            <div className="card" style={{ marginTop: 'var(--space-lg)' }}>
              <h3 style={{ fontWeight: 600, margin: '0 0 var(--space-md)' }}>Historique des transactions</h3>

              {txLoading ? (
                <div style={{ display: 'flex', justifyContent: 'center', padding: 40 }}>
                  <Loader2 size={24} className="spin" style={{ color: 'var(--primary-500)' }} />
                </div>
              ) : transactions.length === 0 ? (
                <p style={{ color: 'var(--text-muted)', fontSize: 14, textAlign: 'center', padding: '40px 0', margin: 0 }}>
                  Aucune transaction pour le moment.
                </p>
              ) : (
                <>
                  <div className="tx-list">
                    {transactions.map((tx) => <TransactionRow key={tx.id} tx={tx} />)}
                  </div>

                  {txData?.meta?.last_page > 1 && (
                    <div className="pagination" style={{ marginTop: 'var(--space-md)' }}>
                      <button className="btn btn-secondary btn-sm" disabled={page === 1} onClick={() => setPage(p => p - 1)}>Précédent</button>
                      <span style={{ fontSize: 13, color: 'var(--text-muted)' }}>Page {page} / {txData.meta.last_page}</span>
                      <button className="btn btn-secondary btn-sm" disabled={page === txData.meta.last_page} onClick={() => setPage(p => p + 1)}>Suivant</button>
                    </div>
                  )}
                </>
              )}
            </div>
          </>
        )}
      </motion.div>
    </div>
  );
}
