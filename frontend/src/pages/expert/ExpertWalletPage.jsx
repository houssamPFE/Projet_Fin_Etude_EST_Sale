import { useState } from 'react';
import { motion } from 'framer-motion';
import { Wallet, TrendingUp, ArrowDownCircle, Loader2, ArrowUpCircle, Clock } from 'lucide-react';
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
    <div className="ewallet-page">
      {/* Header */}
      <div className="ewallet-header">
        <div className="ewallet-header-bg" />
        <div className="ewallet-header-content">
          <div>
            <p className="ewallet-eyebrow">Finances</p>
            <h1 className="ewallet-title">Mon portefeuille</h1>
            <p className="ewallet-subtitle">Suivi de vos gains et transactions</p>
          </div>
        </div>
      </div>

      <div className="ewallet-body">
        {walletLoading ? (
          <div className="ewallet-loading">
            <Loader2 size={32} className="spin" />
          </div>
        ) : (
          <>
            {/* KPI Cards */}
            <div className="ewallet-cards">
              {[
                { key: 'balance',   label: 'Solde disponible', value: wallet?.balance,         icon: <Wallet size={22} />,          mod: 'balance'   },
                { key: 'earned',    label: 'Total gagné',      value: wallet?.total_earned,     icon: <TrendingUp size={22} />,      mod: 'earned'    },
                { key: 'withdrawn', label: 'Total retiré',     value: wallet?.total_withdrawn,  icon: <ArrowDownCircle size={22} />, mod: 'withdrawn' },
              ].map(({ key, label, value, icon, mod }, i) => (
                <motion.div
                  key={key}
                  className={`ewallet-card ewallet-card--${mod}`}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: i * 0.08 }}
                >
                  <div className="ewallet-card-icon">{icon}</div>
                  <div className="ewallet-card-body">
                    <p className="ewallet-card-label">{label}</p>
                    <p className="ewallet-card-value">{value ?? '0.00'} <span className="ewallet-card-currency">MAD</span></p>
                  </div>
                </motion.div>
              ))}
            </div>

            {/* Transactions */}
            <div className="ewallet-section">
              <div className="ewallet-section-head">
                <Clock size={15} />
                <span>Historique des transactions</span>
              </div>

              {txLoading ? (
                <div className="ewallet-loading">
                  <Loader2 size={24} className="spin" />
                </div>
              ) : transactions.length === 0 ? (
                <div className="ewallet-empty">
                  <Wallet size={32} className="ewallet-empty-icon" />
                  <p>Aucune transaction pour le moment.</p>
                </div>
              ) : (
                <>
                  <div className="tx-list">
                    {transactions.map((tx) => <TransactionRow key={tx.id} tx={tx} />)}
                  </div>
                  {txData?.meta?.last_page > 1 && (
                    <div className="ewallet-pagination">
                      <button className="ewallet-pag-btn" disabled={page === 1} onClick={() => setPage(p => p - 1)}>Précédent</button>
                      <span className="ewallet-pag-info">Page {page} / {txData.meta.last_page}</span>
                      <button className="ewallet-pag-btn" disabled={page === txData.meta.last_page} onClick={() => setPage(p => p + 1)}>Suivant</button>
                    </div>
                  )}
                </>
              )}
            </div>
          </>
        )}
      </div>
    </div>
  );
}
