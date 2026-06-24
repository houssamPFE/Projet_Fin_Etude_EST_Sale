<?php

namespace App\Jobs;

use App\Enums\ConversationStatus;
use App\Models\Conversation;
use App\Services\NotificationService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class CloseConversationJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $backoff = 15;

    /**
     * @param Conversation $conversation  The conversation to close.
     * @param string       $closedBy      'patient' | 'expert' | 'system' — drives notification logic.
     * @param bool         $summarize     Whether to trigger an AI summary after closing.
     */
    public function __construct(
        private Conversation $conversation,
        private string $closedBy = 'system',
        private bool $summarize = true,
    ) {}

    public function handle(NotificationService $notifications): void
    {
        // Reload to avoid stale state
        $conversation = $this->conversation->fresh(['user', 'expert.user']);

        if (! $conversation) {
            return;
        }

        // Idempotent — skip if already closed
        if ($conversation->status === ConversationStatus::Closed) {
            Log::info('[CloseConversationJob] Already closed, skipping.', [
                'conversation_id' => $conversation->id,
            ]);
            return;
        }

        // 1. Close the conversation
        $conversation->update([
            'status'    => ConversationStatus::Closed,
            'closed_at' => now(),
        ]);

        Log::info('[CloseConversationJob] Conversation closed', [
            'conversation_id' => $conversation->id,
            'closed_by'       => $this->closedBy,
        ]);

        // 2. AI summary (async — doesn't block this job)
        if ($this->summarize) {
            SummarizeConversationJob::dispatch($conversation)
                ->delay(now()->addSeconds(5)); // slight delay so messages are all saved
        }

        // 3. Notifications based on who closed it
        $this->sendNotifications($conversation, $notifications);
    }

    private function sendNotifications(Conversation $conversation, NotificationService $notifications): void
    {
        $patient     = $conversation->user;
        $expertUser  = $conversation->expert?->user;

        switch ($this->closedBy) {
            // Doctor closed it → notify patient
            case 'expert':
                if ($patient && $expertUser) {
                    $notifications->send(
                        $patient,
                        'conversation.closed_by_expert',
                        'Consultation terminée',
                        "Dr. {$expertUser->name} a clôturé la consultation. Vous pouvez laisser un avis.",
                        ['conversation_id' => $conversation->id],
                    );
                }
                break;

            // Patient closed it → notify doctor
            case 'patient':
                if ($expertUser) {
                    $notifications->send(
                        $expertUser,
                        'conversation.closed_by_patient',
                        'Consultation terminée',
                        "{$patient?->name} a clôturé la consultation.",
                        ['conversation_id' => $conversation->id],
                    );
                }
                break;

            // System/auto-close (inactivity, etc.) → notify both
            case 'system':
                if ($patient) {
                    $notifications->send(
                        $patient,
                        'conversation.closed_auto',
                        'Consultation clôturée',
                        'Votre consultation a été clôturée automatiquement pour inactivité.',
                        ['conversation_id' => $conversation->id],
                    );
                }
                if ($expertUser) {
                    $notifications->send(
                        $expertUser,
                        'conversation.closed_auto',
                        'Consultation clôturée',
                        'Une consultation vous a été assignée et a été clôturée automatiquement.',
                        ['conversation_id' => $conversation->id],
                    );
                }
                break;
        }
    }

    public function failed(\Throwable $e): void
    {
        Log::error('[CloseConversationJob] Failed', [
            'conversation_id' => $this->conversation->id,
            'error'           => $e->getMessage(),
        ]);
    }
}
