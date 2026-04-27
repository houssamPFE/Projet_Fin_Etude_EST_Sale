import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { ArrowLeft, Loader2, Stethoscope } from 'lucide-react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useCategories } from '../../hooks/useExperts';
import { useCreateConversation } from '../../hooks/useMessages';
import toast from 'react-hot-toast';
import './NewConversationPage.css';

export default function NewConversationPage() {
  const navigate = useNavigate();
  const location = useLocation();
  const expertId = location.state?.expert_id ?? '';

  const { data: categories = [] } = useCategories();
  const { mutateAsync: createConversation, isPending } = useCreateConversation();

  const [title, setTitle] = useState('');
  const [categoryId, setCategoryId] = useState('');
  const [message, setMessage] = useState('');

  useEffect(() => {
    if (categories.length > 0) {
      setCategoryId(categories[0].id);
    }
  }, [categories]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!categoryId) { toast.error('Catégorie non disponible, réessayez.'); return; }
    if (!message.trim()) { toast.error('Veuillez écrire votre message initial.'); return; }
    try {
      const response = await createConversation({
        category_id: categoryId,
        title: title || undefined,
        expert_id: expertId || undefined,
        message: message.trim(),
      });
      const conversationId = response.data?.data?.conversation?.id;
      if (!conversationId) throw new Error('No conversation ID returned');
      navigate(`/conversations/${conversationId}`);
    } catch {
      toast.error('Impossible de créer la conversation.');
    }
  };

  return (
    <div className="new-conv-page">
      <button className="back-btn" onClick={() => navigate(-1)}>
        <ArrowLeft size={16} /> Retour
      </button>

      <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.5 }} style={{ width: '100%', maxWidth: 560 }}>
        <div className="new-conv-card card">
          <div className="new-conv-icon">
            <Stethoscope size={28} />
          </div>
          <h1 className="new-conv-title">Consultation médicale</h1>
          <p className="new-conv-subtitle">
            Décrivez vos symptômes ou votre question. Notre IA médicale vous répond immédiatement et escalade vers un médecin si nécessaire.
          </p>

          <form onSubmit={handleSubmit} className="new-conv-form">
            <div className="form-group">
              <label className="form-label">Titre (optionnel)</label>
              <input
                type="text"
                className="form-input"
                placeholder="Ex: Douleurs abdominales depuis 3 jours"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                maxLength={255}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Décrivez votre problème *</label>
              <textarea
                className="form-input"
                placeholder="Décrivez vos symptômes, depuis quand, vos antécédents médicaux si pertinents..."
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                rows={5}
                maxLength={5000}
                required
              />
            </div>

            {expertId && (
              <p className="new-conv-expert-hint">
                Un médecin spécifique a été sélectionné pour cette consultation.
              </p>
            )}

            <button type="submit" className="btn btn-primary btn-full" disabled={isPending}>
              {isPending ? <Loader2 size={18} className="spin" /> : <Stethoscope size={18} />}
              {isPending ? 'Création...' : 'Démarrer la consultation'}
            </button>
          </form>
        </div>

      </motion.div>
    </div>
  );
}
