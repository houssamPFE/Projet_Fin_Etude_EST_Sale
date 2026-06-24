import { useEffect, useRef, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ArrowLeft, Loader2, Sparkles, Stethoscope, ChevronDown, Check } from 'lucide-react';
import { useLocation, useNavigate } from 'react-router-dom';
import toast from 'react-hot-toast';
import { useCategories } from '../../hooks/useExperts';
import { useCreateConversation } from '../../hooks/useMessages';
import useAuthStore from '../../stores/authStore';
import './NewConversationPage.css';

// ── Custom animated specialty picker ─────────────────────────────────────
function SpecialtyPicker({ categories, value, onChange }) {
  const [open, setOpen] = useState(false);
  const ref = useRef(null);
  const listRef = useRef(null);

  const selected = categories.find((c) => String(c.id) === String(value));

  // Close on outside click
  useEffect(() => {
    const handler = (e) => {
      if (ref.current && !ref.current.contains(e.target)) setOpen(false);
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  return (
    <div className="sp-picker" ref={ref}>
      {/* Trigger */}
      <button
        type="button"
        className={`sp-trigger ${open ? 'sp-trigger--open' : ''}`}
        onClick={() => {
          setOpen((v) => !v);
          // Reset scroll to top so selected item is always visible
          setTimeout(() => { if (listRef.current) listRef.current.scrollTop = 0; }, 10);
        }}
      >
        <span className="sp-trigger-label">{selected?.name ?? 'Sélectionner…'}</span>
        <motion.span
          animate={{ rotate: open ? 180 : 0 }}
          transition={{ duration: 0.2 }}
          style={{ display: 'flex' }}
        >
          <ChevronDown size={16} />
        </motion.span>
      </button>

      {/* Dropdown */}
      <AnimatePresence>
        {open && (
          <motion.ul
            ref={listRef}
            className="sp-list"
            initial={{ opacity: 0, y: -8, scale: 0.97 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -8, scale: 0.97 }}
            transition={{ duration: 0.18, ease: [0.16, 1, 0.3, 1] }}
          >
            {categories.map((c, i) => {
              const isSelected = String(c.id) === String(value);
              return (
                <motion.li
                  key={c.id}
                  className={`sp-option ${isSelected ? 'sp-option--selected' : ''}`}
                  onClick={() => { onChange(c.id); setOpen(false); }}
                  initial={{ opacity: 0, x: -6 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: i * 0.03, duration: 0.15 }}
                >
                  <span>{c.name}</span>
                  {isSelected && <Check size={14} className="sp-check" />}
                </motion.li>
              );
            })}
          </motion.ul>
        )}
      </AnimatePresence>
    </div>
  );
}

// ── Page ─────────────────────────────────────────────────────────────────
export default function NewConversationPage() {
  const navigate  = useNavigate();
  const location  = useLocation();
  const expertId  = location.state?.expert_id ?? '';
  const user      = useAuthStore((s) => s.user);

  // If a specific doctor is requested, redirect free/creditless users to upgrade
  useEffect(() => {
    if (!expertId) return;
    const canConsult = user?.plan !== 'free' && (user?.consultation_credits ?? 0) > 0;
    if (!canConsult) {
      navigate('/upgrade', {
        replace: true,
        state: { reason: user?.plan === 'free' ? 'no_plan' : 'no_credits' },
      });
    }
  }, [expertId, user, navigate]);

  const { data: categories = [] } = useCategories();
  const { mutateAsync: createConversation, isPending } = useCreateConversation();

  const [categoryId, setCategoryId] = useState('');

  useEffect(() => {
    if (categories.length > 0 && !categoryId) {
      setCategoryId(String(categories[0].id));
    }
  }, [categories, categoryId]);

  const handleStart = async () => {
    if (!categoryId) {
      toast.error('Sélectionnez une spécialité.');
      return;
    }
    try {
      const response = await createConversation({
        category_id: categoryId,
        expert_id: expertId || undefined,
      });
      const conversationId = response.data?.data?.conversation?.id;
      if (!conversationId) throw new Error('No ID');
      navigate(`/conversations/${conversationId}`, { replace: true });
    } catch (err) {
      if (err?.response?.status === 402) {
        navigate('/upgrade', { state: { reason: 'no_credits' } });
      } else {
        toast.error('Impossible de démarrer la consultation.');
      }
    }
  };

  return (
    <div className="new-conv-page">
      <button type="button" className="new-conv-back" onClick={() => navigate(-1)}>
        <ArrowLeft size={15} />
        <span>Retour</span>
      </button>

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.35, ease: [0.16, 1, 0.3, 1] }}
        style={{ width: '100%', maxWidth: 480 }}
      >
        <div className="new-conv-card">

          <div className="new-conv-icon">
            <Stethoscope size={26} />
          </div>

          <h1 className="new-conv-title">Nouvelle consultation</h1>
          <p className="new-conv-subtitle">
            Choisissez votre spécialité et commencez à décrire vos symptômes directement dans le chat.
          </p>

          {categories.length > 0 && (
            <div className="ncf-group" style={{ marginBottom: 28 }}>
              <label className="ncf-label">Spécialité médicale</label>
              <SpecialtyPicker
                categories={categories}
                value={categoryId}
                onChange={(id) => setCategoryId(String(id))}
              />
            </div>
          )}

          <button
            type="button"
            className="ncf-submit"
            disabled={isPending || !categoryId}
            onClick={handleStart}
          >
            {isPending
              ? <><Loader2 size={17} className="spin" /> Démarrage…</>
              : <><Sparkles size={17} /> Démarrer la consultation</>
            }
          </button>

          <p className="ncf-disclaimer-inline">
            Les informations fournies ne remplacent pas une consultation médicale.
            En cas d'urgence, appelez le <strong>15</strong>.
          </p>
        </div>
      </motion.div>
    </div>
  );
}
