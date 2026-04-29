import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { ArrowLeft, Loader2, Stethoscope } from 'lucide-react';
import { useLocation, useNavigate } from 'react-router-dom';
import toast from 'react-hot-toast';
import { useCategories, useExpert } from '../../hooks/useExperts';
import { useCreateConversation } from '../../hooks/useMessages';
import './NewConversationPage.css';

export default function NewConversationPage() {
  const navigate = useNavigate();
  const location = useLocation();
  const expertId = location.state?.expert_id ?? '';

  const { data: categories = [] } = useCategories();
  const { data: selectedExpert, isLoading: expertLoading } = useExpert(expertId || null);
  const { mutateAsync: createConversation, isPending } = useCreateConversation();

  const [title, setTitle] = useState('');
  const [categoryId, setCategoryId] = useState('');
  const [message, setMessage] = useState('');

  useEffect(() => {
    if (selectedExpert?.category?.id) {
      setCategoryId(selectedExpert.category.id);
      return;
    }

    if (categories.length > 0 && !categoryId) {
      setCategoryId(categories[0].id);
    }
  }, [categories, categoryId, selectedExpert]);

  const handleSubmit = async (event) => {
    event.preventDefault();

    const resolvedCategoryId = selectedExpert?.category?.id ?? categoryId;

    if (expertId && expertLoading) {
      toast.error('Chargement du medecin selectionne...');
      return;
    }

    if (!resolvedCategoryId) {
      toast.error('Categorie non disponible, reessayez.');
      return;
    }

    if (!message.trim()) {
      toast.error('Veuillez ecrire votre message initial.');
      return;
    }

    try {
      const response = await createConversation({
        category_id: resolvedCategoryId,
        title: title || undefined,
        expert_id: expertId || undefined,
        message: message.trim(),
      });

      const conversationId = response.data?.data?.conversation?.id;
      if (!conversationId) throw new Error('No conversation ID returned');

      navigate(`/conversations/${conversationId}`);
    } catch {
      toast.error('Impossible de creer la conversation.');
    }
  };

  return (
    <div className="new-conv-page">
      <button type="button" className="back-btn" onClick={() => navigate(-1)}>
        <ArrowLeft size={16} /> Retour
      </button>

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        style={{ width: '100%', maxWidth: 560 }}
      >
        <div className="new-conv-card card">
          <div className="new-conv-icon">
            <Stethoscope size={28} />
          </div>
          <h1 className="new-conv-title">Consultation medicale</h1>
          <p className="new-conv-subtitle">
            Decrivez vos symptomes ou votre question. Notre IA medicale vous repond
            immediatement et escalade vers un medecin si necessaire.
          </p>

          <form onSubmit={handleSubmit} className="new-conv-form">
            <div className="form-group">
              <label className="form-label">Titre (optionnel)</label>
              <input
                type="text"
                className="form-input"
                placeholder="Ex: Douleurs abdominales depuis 3 jours"
                value={title}
                onChange={(event) => setTitle(event.target.value)}
                maxLength={255}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Decrivez votre probleme *</label>
              <textarea
                className="form-input"
                placeholder="Decrivez vos symptomes, depuis quand, vos antecedents medicaux si pertinents..."
                value={message}
                onChange={(event) => setMessage(event.target.value)}
                rows={5}
                maxLength={5000}
                required
              />
            </div>

            {expertId && (
              <p className="new-conv-expert-hint">
                Consultation adressee a {selectedExpert?.user?.name ?? 'ce medecin'}.
                {selectedExpert?.category?.name ? ` Specialite: ${selectedExpert.category.name}.` : ''}
              </p>
            )}

            <button type="submit" className="btn btn-primary btn-full" disabled={isPending || (expertId && expertLoading)}>
              {isPending ? <Loader2 size={18} className="spin" /> : <Stethoscope size={18} />}
              {isPending ? 'Creation...' : 'Demarrer la consultation'}
            </button>
          </form>
        </div>
      </motion.div>
    </div>
  );
}
