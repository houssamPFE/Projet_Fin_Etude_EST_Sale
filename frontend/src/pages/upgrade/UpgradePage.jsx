import { useState, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { loadStripe } from '@stripe/stripe-js';
import { Elements, CardElement, useStripe, useElements } from '@stripe/react-stripe-js';
import {
  Check, Zap, Crown, Sparkles, X, Loader2,
  CreditCard, Shield, ChevronRight, Star,
} from 'lucide-react';
import toast from 'react-hot-toast';
import {
  usePlan, useCreatePaymentIntent, useConfirmPayment,
  useInitiateCmi, PLANS_META, EXTRA_CREDIT_PRICE,
} from '../../hooks/usePlan';
import './UpgradePage.css';

const stripePromise = loadStripe(import.meta.env.VITE_STRIPE_KEY || '');

// ─── Plan config ──────────────────────────────────────────────────────────────

const PLANS = [
  {
    key: 'free',
    icon: Sparkles,
    label: 'Gratuit',
    price: 0,
    period: '',
    consultations: 0,
    features: [
      'Assistant IA médical 24/7',
      'Triage des symptômes',
      'Support français & arabe',
      'Historique illimité',
      'Messages vocaux',
    ],
    locked: [
      'Consultations avec médecin',
      'Accès aux spécialistes',
    ],
    cta: 'Votre plan actuel',
    highlight: false,
  },
  {
    key: 'pro',
    icon: Zap,
    label: 'Pro',
    price: 249,
    period: '/mois',
    consultations: 3,
    features: [
      'Tout ce qui est dans Gratuit',
      '3 consultations médecin/mois',
      'Médecins certifiés & vérifiés',
      'Réponse sous 15 minutes',
      'Paiement sécurisé',
    ],
    locked: [],
    cta: "S'abonner au Pro",
    highlight: false,
    badge: 'Populaire',
  },
  {
    key: 'premium',
    icon: Crown,
    label: 'Premium',
    price: 449,
    period: '/mois',
    consultations: 6,
    features: [
      'Tout ce qui est dans Pro',
      '6 consultations médecin/mois',
      'Médecins prioritaires (top rating)',
      'Réponse sous 5 minutes',
      'Support dédié',
    ],
    locked: [],
    cta: "S'abonner au Premium",
    highlight: true,
    badge: 'Meilleure valeur',
  },
];

// ─── Stripe payment form ──────────────────────────────────────────────────────

function StripeForm({ planKey, clientSecret, onSuccess, onCancel }) {
  const stripe    = useStripe();
  const elements  = useElements();
  const confirm   = useConfirmPayment();
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!stripe || !elements) return;

    setLoading(true);
    try {
      const { error, paymentIntent } = await stripe.confirmCardPayment(clientSecret, {
        payment_method: { card: elements.getElement(CardElement) },
      });

      if (error) {
        toast.error(error.message || 'Paiement échoué.');
        setLoading(false);
        return;
      }

      if (paymentIntent.status === 'succeeded') {
        await confirm.mutateAsync(paymentIntent.id);
        toast.success('Abonnement activé !');
        onSuccess();
      }
    } catch {
      toast.error('Erreur lors du paiement.');
    } finally {
      setLoading(false);
    }
  };

  const plan = PLANS.find(p => p.key === planKey);

  return (
    <form onSubmit={handleSubmit} className="upg-stripe-form">
      <div className="upg-stripe-header">
        <h3>Paiement sécurisé</h3>
        <p>Plan {plan?.label} — {plan?.price} MAD/mois</p>
      </div>

      <div className="upg-card-wrapper">
        <CardElement options={{
          style: {
            base: {
              fontSize: '15px',
              color: '#e2e8f0',
              fontFamily: 'Inter, sans-serif',
              '::placeholder': { color: '#64748b' },
            },
            invalid: { color: '#f87171' },
          },
          hidePostalCode: true,
        }} />
      </div>

      <div className="upg-stripe-trust">
        <Shield size={13} />
        <span>Paiement chiffré SSL · Stripe · Aucune donnée stockée</span>
      </div>

      <div className="upg-stripe-actions">
        <button type="button" className="upg-btn-ghost" onClick={onCancel} disabled={loading}>
          Annuler
        </button>
        <button type="submit" className="upg-btn-pay" disabled={loading || !stripe}>
          {loading ? <Loader2 size={16} className="upg-spin" /> : <CreditCard size={16} />}
          Payer {plan?.price} MAD
        </button>
      </div>
    </form>
  );
}

// ─── Payment modal ────────────────────────────────────────────────────────────

function PaymentModal({ planKey, onClose, onSuccess }) {
  const [method, setMethod]         = useState(null); // 'stripe' | 'cmi'
  const [clientSecret, setSecret]   = useState(null);
  const [cmiData, setCmiData]       = useState(null);
  const createIntent                = useCreatePaymentIntent();
  const initiateCmi                 = useInitiateCmi();

  const plan = PLANS.find(p => p.key === planKey);

  const handleStripe = async () => {
    try {
      const result = await createIntent.mutateAsync(planKey);
      setSecret(result.client_secret);
      setMethod('stripe');
    } catch {
      toast.error('Erreur lors de la préparation du paiement.');
    }
  };

  const handleCmi = async () => {
    try {
      const result = await initiateCmi.mutateAsync(planKey);
      setCmiData(result);
      setMethod('cmi');
      // Submit CMI form automatically
      setTimeout(() => {
        document.getElementById('cmi-form')?.submit();
      }, 300);
    } catch {
      toast.error('Erreur CMI. Réessayez.');
    }
  };

  return (
    <div className="upg-modal-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="upg-modal">
        <button className="upg-modal-close" onClick={onClose}>
          <X size={18} />
        </button>

        {!method && (
          <>
            <div className="upg-modal-header">
              <h2>Choisir le mode de paiement</h2>
              <p>Plan {plan?.label} — <strong>{plan?.price} MAD/mois</strong></p>
            </div>

            <div className="upg-payment-methods">
              <button
                className="upg-method-btn"
                onClick={handleStripe}
                disabled={createIntent.isPending}
              >
                {createIntent.isPending
                  ? <Loader2 size={20} className="upg-spin" />
                  : <CreditCard size={20} />}
                <span>
                  <strong>Carte internationale</strong>
                  <small>Visa, Mastercard via Stripe</small>
                </span>
                <ChevronRight size={16} className="upg-method-arrow" />
              </button>

              <button
                className="upg-method-btn"
                onClick={handleCmi}
                disabled={initiateCmi.isPending}
              >
                {initiateCmi.isPending
                  ? <Loader2 size={20} className="upg-spin" />
                  : <Star size={20} />}
                <span>
                  <strong>Carte marocaine (CMI)</strong>
                  <small>CIH, Attijariwafa, BMCE…</small>
                </span>
                <ChevronRight size={16} className="upg-method-arrow" />
              </button>
            </div>
          </>
        )}

        {method === 'stripe' && clientSecret && (
          <Elements stripe={stripePromise} options={{ clientSecret }}>
            <StripeForm
              planKey={planKey}
              clientSecret={clientSecret}
              onSuccess={onSuccess}
              onCancel={() => setMethod(null)}
            />
          </Elements>
        )}

        {/* Hidden CMI form — auto-submits to CMI gateway */}
        {cmiData && (
          <form id="cmi-form" action={cmiData.cmi_url} method="POST" style={{ display: 'none' }}>
            {Object.entries(cmiData.params).map(([k, v]) => (
              <input key={k} type="hidden" name={k} value={v} />
            ))}
          </form>
        )}
      </div>
    </div>
  );
}

// ─── Plan card ────────────────────────────────────────────────────────────────

function PlanCard({ plan, currentPlan, credits, onSubscribe }) {
  const isCurrent  = currentPlan === plan.key;
  const isUpgrade  = plan.key !== 'free' && !isCurrent;
  const meta       = PLANS_META[plan.key];
  const Icon       = plan.icon;

  return (
    <div className={`upg-card ${plan.highlight ? 'upg-card--highlight' : ''} ${isCurrent ? 'upg-card--current' : ''}`}>
      {plan.highlight && (
        <div className="upg-card-glow" />
      )}

      {plan.badge && !isCurrent && (
        <div className="upg-badge" style={{ background: meta.gradient }}>
          {plan.badge}
        </div>
      )}
      {isCurrent && (
        <div className="upg-badge upg-badge--current">
          Plan actuel
        </div>
      )}

      <div className="upg-card-inner">
        <div className="upg-card-icon" style={{ background: meta.gradient }}>
          <Icon size={20} />
        </div>

        <h2 className="upg-card-name">{plan.label}</h2>

        <div className="upg-card-price">
          {plan.price === 0 ? (
            <span className="upg-price-free">Gratuit</span>
          ) : (
            <>
              <span className="upg-price-amount">{plan.price}</span>
              <span className="upg-price-currency">MAD</span>
              <span className="upg-price-period">{plan.period}</span>
            </>
          )}
        </div>

        {plan.consultations > 0 && (
          <div className="upg-consult-badge">
            <Zap size={12} />
            {plan.consultations} consultations médecin / mois
          </div>
        )}

        <ul className="upg-features">
          {plan.features.map(f => (
            <li key={f} className="upg-feature upg-feature--included">
              <span className="upg-feature-icon" style={{ background: meta.gradient }}>
                <Check size={10} />
              </span>
              {f}
            </li>
          ))}
          {plan.locked.map(f => (
            <li key={f} className="upg-feature upg-feature--locked">
              <span className="upg-feature-icon upg-feature-icon--locked">
                <X size={10} />
              </span>
              {f}
            </li>
          ))}
        </ul>

        {isCurrent && plan.key !== 'free' && (
          <div className="upg-credits-info">
            <span className="upg-credits-count">{credits}</span>
            <span className="upg-credits-label">crédit{credits !== 1 ? 's' : ''} restant{credits !== 1 ? 's' : ''}</span>
          </div>
        )}

        <button
          className={`upg-cta ${isCurrent ? 'upg-cta--current' : isUpgrade ? 'upg-cta--upgrade' : 'upg-cta--free'}`}
          style={isUpgrade ? { background: meta.gradient } : undefined}
          onClick={() => isUpgrade && onSubscribe(plan.key)}
          disabled={isCurrent || plan.key === 'free'}
        >
          {isCurrent ? (
            <><Check size={15} /> Plan actuel</>
          ) : plan.key === 'free' ? (
            'Plan de base'
          ) : (
            <>{plan.cta} <ChevronRight size={15} /></>
          )}
        </button>
      </div>
    </div>
  );
}

// ─── Main page ────────────────────────────────────────────────────────────────

export default function UpgradePage() {
  const navigate              = useNavigate();
  const { data: planData, isLoading } = usePlan();
  const [modalPlan, setModal] = useState(null);

  const currentPlan = planData?.plan ?? 'free';
  const credits     = planData?.consultation_credits ?? 0;

  const handleSuccess = useCallback(() => {
    setModal(null);
    toast.success('🎉 Bienvenue dans Nexora ' + (modalPlan === 'premium' ? 'Premium' : 'Pro') + ' !');
    navigate('/dashboard');
  }, [modalPlan, navigate]);

  return (
    <div className="upg-page">
      <div className="upg-header">
        <h1 className="upg-title">
          Choisissez votre <span className="upg-title-gradient">plan</span>
        </h1>
        <p className="upg-subtitle">
          L'IA est toujours gratuite. Passez à Pro ou Premium pour consulter de vrais médecins.
        </p>
      </div>

      {isLoading ? (
        <div className="upg-loading">
          <Loader2 size={32} className="upg-spin" />
        </div>
      ) : (
        <>
          <div className="upg-grid">
            {PLANS.map(plan => (
              <PlanCard
                key={plan.key}
                plan={plan}
                currentPlan={currentPlan}
                credits={credits}
                onSubscribe={setModal}
              />
            ))}
          </div>

          {/* Extra credit section */}
          <div className="upg-extra">
            <div className="upg-extra-inner">
              <div className="upg-extra-text">
                <h3>Crédit supplémentaire</h3>
                <p>Vous avez utilisé tous vos crédits ? Achetez une consultation supplémentaire sans changer de plan.</p>
              </div>
              <div className="upg-extra-price">
                <span className="upg-extra-amount">{EXTRA_CREDIT_PRICE} MAD</span>
                <span className="upg-extra-label">/ consultation</span>
              </div>
              <button
                className="upg-extra-btn"
                onClick={() => setModal('extra')}
                disabled={!planData?.is_active}
              >
                Acheter un crédit
              </button>
            </div>
            {!planData?.is_active && (
              <p className="upg-extra-note">
                * Disponible uniquement pour les abonnés Pro et Premium.
              </p>
            )}
          </div>

          {/* Trust badges */}
          <div className="upg-trust">
            {['Paiement 100% sécurisé', 'Médecins certifiés CNOM', 'Remboursement sous 24h', 'Sans engagement'].map(t => (
              <div key={t} className="upg-trust-item">
                <Check size={13} />
                {t}
              </div>
            ))}
          </div>
        </>
      )}

      {modalPlan && (
        <PaymentModal
          planKey={modalPlan}
          onClose={() => setModal(null)}
          onSuccess={handleSuccess}
        />
      )}
    </div>
  );
}
