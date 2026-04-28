import { useEffect, useRef, useState } from 'react';
import { motion } from 'framer-motion';
import {
  Check,
  ChevronRight,
  Loader2,
  MessageSquare,
  MoreVertical,
  Pencil,
  Plus,
  Trash2,
  X,
} from 'lucide-react';
import { Link, useNavigate } from 'react-router-dom';
import {
  useConversations,
  useDeleteConversation,
  useUpdateConversation,
} from '../../hooks/useConversations';
import useAuthStore from '../../stores/authStore';
import './ConversationsPage.css';

function StatusBadge({ status }) {
  const labels = {
    ai: 'IA',
    expert: 'Medecin',
    open: 'Ouvert',
    closed: 'Fermee',
  };

  return (
    <span className={`conv-status conv-status--${status ?? 'open'}`}>
      {labels[status] ?? labels.open}
    </span>
  );
}

function ConversationActions({ conv, disabled, onRename, onDelete }) {
  const [open, setOpen] = useState(false);
  const ref = useRef(null);

  useEffect(() => {
    if (!open) return undefined;

    const handlePointerDown = (event) => {
      if (ref.current && !ref.current.contains(event.target)) {
        setOpen(false);
      }
    };

    document.addEventListener('mousedown', handlePointerDown);
    return () => document.removeEventListener('mousedown', handlePointerDown);
  }, [open]);

  return (
    <div className="conv-menu" ref={ref}>
      <button
        type="button"
        className="conv-menu-btn"
        aria-label="Options"
        aria-expanded={open}
        disabled={disabled}
        onClick={(event) => {
          event.preventDefault();
          event.stopPropagation();
          setOpen((value) => !value);
        }}
      >
        <MoreVertical size={16} />
      </button>

      {open && (
        <div className="conv-menu-panel">
          <button
            type="button"
            className="conv-menu-item"
            onClick={(event) => {
              event.preventDefault();
              event.stopPropagation();
              setOpen(false);
              onRename(conv);
            }}
          >
            <Pencil size={14} />
            Renommer
          </button>
          <button
            type="button"
            className="conv-menu-item conv-menu-item--danger"
            onClick={(event) => {
              event.preventDefault();
              event.stopPropagation();
              setOpen(false);
              onDelete(conv);
            }}
          >
            <Trash2 size={14} />
            Supprimer
          </button>
        </div>
      )}
    </div>
  );
}

export default function ConversationsPage() {
  const navigate = useNavigate();
  const user = useAuthStore((state) => state.user);
  const [page, setPage] = useState(1);
  const [renaming, setRenaming] = useState(null);
  const [newTitle, setNewTitle] = useState('');
  const [confirmingDelete, setConfirmingDelete] = useState(null);

  const { data, isLoading, isFetching } = useConversations({ page, per_page: 12 });
  const updateConversation = useUpdateConversation();
  const deleteConversation = useDeleteConversation();

  const conversations = data?.data ?? [];
  const meta = data?.meta ?? {};
  const actionsBusy = updateConversation.isPending || deleteConversation.isPending;

  useEffect(() => {
    if (!isLoading && page > 1 && conversations.length === 0) {
      setPage((currentPage) => Math.max(1, currentPage - 1));
    }
  }, [conversations.length, isLoading, page]);

  const canManageConversation = (conversation) => {
    return user?.role === 'admin' || conversation.user?.id === user?.id;
  };

  const openRename = (conversation) => {
    setRenaming(conversation);
    setNewTitle(conversation.title ?? `Conversation #${conversation.id}`);
  };

  const submitRename = (event) => {
    event.preventDefault();
    if (!renaming || !newTitle.trim()) return;

    updateConversation.mutate(
      { id: renaming.id, title: newTitle.trim() },
      { onSuccess: () => setRenaming(null) }
    );
  };

  const submitDelete = () => {
    if (!confirmingDelete) return;

    deleteConversation.mutate(confirmingDelete.id, {
      onSuccess: () => setConfirmingDelete(null),
    });
  };

  return (
    <div className="convs-page">
      <motion.div
        className="convs-shell"
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4 }}
      >
        <div className="convs-header">
          <div>
            <h1 className="page-title">Conversations</h1>
            <p className="page-subtitle">Toutes vos conversations avec l&apos;IA et les experts</p>
          </div>
          <button type="button" className="btn btn-primary" onClick={() => navigate('/conversations/new')}>
            <Plus size={18} />
            Nouvelle conversation
          </button>
        </div>

        {isLoading ? (
          <div className="convs-loading">
            <Loader2 size={32} className="spin" style={{ color: 'var(--primary-500)' }} />
          </div>
        ) : conversations.length === 0 ? (
          <div className="convs-empty card">
            <MessageSquare size={48} style={{ color: 'var(--text-muted)', marginBottom: 16 }} />
            <p style={{ color: 'var(--text-muted)', margin: 0 }}>Aucune conversation pour le moment.</p>
            <button
              type="button"
              className="btn btn-primary"
              style={{ marginTop: 16 }}
              onClick={() => navigate('/conversations/new')}
            >
              Commencer une conversation
            </button>
          </div>
        ) : (
          <>
            <div className="convs-list">
              {conversations.map((conversation, index) => {
                const metaParts = [
                  conversation.category?.name,
                  conversation.expert?.user?.name,
                ].filter(Boolean);

                return (
                  <motion.div
                    key={conversation.id}
                    initial={{ opacity: 0, x: -10 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ duration: 0.3, delay: Math.min(index * 0.03, 0.3) }}
                  >
                    <div className="conv-item">
                      <Link to={`/conversations/${conversation.id}`} className="conv-link">
                        <div className="conv-icon">
                          <MessageSquare size={20} />
                        </div>
                        <div className="conv-info">
                          <p className="conv-title">{conversation.title ?? `Conversation #${conversation.id}`}</p>
                          <p className="conv-meta">
                            {metaParts.length > 0
                              ? metaParts.join(' - ')
                              : 'Aucune information supplementaire'}
                          </p>
                        </div>
                        <div className="conv-right">
                          <StatusBadge status={conversation.status} />
                          <ChevronRight size={16} className="conv-chevron" />
                        </div>
                      </Link>

                      {canManageConversation(conversation) && (
                        <ConversationActions
                          conv={conversation}
                          disabled={actionsBusy}
                          onRename={openRename}
                          onDelete={setConfirmingDelete}
                        />
                      )}
                    </div>
                  </motion.div>
                );
              })}
            </div>

            {meta.last_page > 1 && (
              <div className="pagination">
                <button
                  type="button"
                  className="btn btn-secondary btn-sm"
                  disabled={page === 1 || isFetching}
                  onClick={() => setPage((currentPage) => currentPage - 1)}
                >
                  Precedent
                </button>
                <span className="pagination-info">
                  Page {meta.current_page ?? page} / {meta.last_page}
                </span>
                <button
                  type="button"
                  className="btn btn-secondary btn-sm"
                  disabled={page === meta.last_page || isFetching}
                  onClick={() => setPage((currentPage) => currentPage + 1)}
                >
                  Suivant
                </button>
              </div>
            )}
          </>
        )}
      </motion.div>

      {renaming && (
        <div className="conv-modal-overlay" onClick={() => setRenaming(null)}>
          <form className="conv-modal" onClick={(event) => event.stopPropagation()} onSubmit={submitRename}>
            <div className="conv-modal-header">
              <h3>Renommer la conversation</h3>
              <button type="button" className="conv-modal-close" onClick={() => setRenaming(null)}>
                <X size={18} />
              </button>
            </div>

            <input
              type="text"
              className="conv-modal-input"
              value={newTitle}
              maxLength={255}
              autoFocus
              onChange={(event) => setNewTitle(event.target.value)}
            />

            <div className="conv-modal-actions">
              <button type="button" className="btn btn-secondary" onClick={() => setRenaming(null)}>
                Annuler
              </button>
              <button
                type="submit"
                className="btn btn-primary"
                disabled={updateConversation.isPending || !newTitle.trim()}
              >
                {updateConversation.isPending ? <Loader2 size={14} className="spin" /> : <Check size={14} />}
                Enregistrer
              </button>
            </div>
          </form>
        </div>
      )}

      {confirmingDelete && (
        <div className="conv-modal-overlay" onClick={() => setConfirmingDelete(null)}>
          <div className="conv-modal" onClick={(event) => event.stopPropagation()}>
            <div className="conv-modal-header">
              <h3>Supprimer cette conversation ?</h3>
              <button type="button" className="conv-modal-close" onClick={() => setConfirmingDelete(null)}>
                <X size={18} />
              </button>
            </div>

            <p className="conv-modal-text">
              Vous etes sur le point de supprimer &quot;
              {confirmingDelete.title ?? `Conversation #${confirmingDelete.id}`}
              &quot;. Cette action est irreversible.
            </p>

            <div className="conv-modal-actions">
              <button type="button" className="btn btn-secondary" onClick={() => setConfirmingDelete(null)}>
                Annuler
              </button>
              <button
                type="button"
                className="btn btn-danger"
                disabled={deleteConversation.isPending}
                onClick={submitDelete}
              >
                {deleteConversation.isPending ? <Loader2 size={14} className="spin" /> : <Trash2 size={14} />}
                Supprimer
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
