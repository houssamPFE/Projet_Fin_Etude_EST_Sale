<?php

namespace App\Services;

use App\Enums\ConversationChannel;
use App\Enums\ConversationStatus;
use App\Enums\ExpertStatus;
use App\Events\ConversationAssigned;
use App\Events\ConversationEscalated;
use App\Models\Conversation;
use App\Models\Expert;
use App\Models\Review;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class ConversationService
{
    public function __construct(
        private NotificationService $notificationService,
    ) {}
    /**
     * Create a new conversation. Starts in AI mode by default.
     */
    public function create(User $user, array $data): Conversation
    {
        $expert = null;

        if (! empty($data['expert_id'])) {
            $expert = Expert::validated()
                ->available()
                ->with('user')
                ->find($data['expert_id']);

            if (! $expert) {
                throw ValidationException::withMessages([
                    'expert_id' => 'Le medecin selectionne est indisponible ou invalide.',
                ]);
            }
        }

        $conversation = Conversation::create([
            'user_id'     => $user->id,
            'expert_id'   => $expert?->id,
            'category_id' => $expert?->category_id ?? $data['category_id'],
            'title'       => $data['title'] ?? null,
            'status'      => $expert ? ConversationStatus::Expert : ConversationStatus::Ai,
            'channel'     => $expert ? ConversationChannel::Expert : ConversationChannel::Ai,
        ]);

        $conversation->load(['user', 'category', 'expert.user']);

        if ($expert) {
            event(new ConversationAssigned($conversation));
            $this->notificationService->conversationAssigned($expert->user, $conversation->id);
        }

        return $conversation;
    }

    /**
     * Escalate a conversation from AI to a human expert.
     * Finds the best available expert in the same category.
     */
    public function escalate(Conversation $conversation): Conversation
    {
        $expert = Expert::validated()
            ->available()
            ->where('category_id', $conversation->category_id)
            ->orderByDesc('rating_avg')
            ->first();

        $conversation->update([
            'expert_id' => $expert?->id,
            'status'    => ConversationStatus::Expert,
            'channel'   => $conversation->channel === ConversationChannel::Ai
                ? ConversationChannel::Hybrid
                : $conversation->channel,
        ]);

        $freshConversation = $conversation->fresh(['user', 'category', 'expert.user']);

        // Broadcast events and notify if expert was assigned
        if ($expert) {
            event(new ConversationAssigned($freshConversation));
            event(new ConversationEscalated($freshConversation));
            $this->notificationService->conversationAssigned($expert->user, $conversation->id);
        }

        return $freshConversation;
    }

    /**
     * Close a conversation.
     */
    public function close(Conversation $conversation, ?string $summary = null): Conversation
    {
        $conversation->update([
            'status'    => ConversationStatus::Closed,
            'closed_at' => now(),
            'summary'   => $summary,
        ]);

        return $conversation;
    }

    /**
     * Rate a closed conversation and create/update the review.
     */
    public function rate(Conversation $conversation, int $rating, ?string $comment = null): Conversation
    {
        return DB::transaction(function () use ($conversation, $rating, $comment) {
            $conversation->update(['rating' => $rating]);

            // Create or update review if expert was involved
            if ($conversation->expert_id) {
                Review::updateOrCreate(
                    ['conversation_id' => $conversation->id],
                    [
                        'user_id'   => $conversation->user_id,
                        'expert_id' => $conversation->expert_id,
                        'rating'    => $rating,
                        'comment'   => $comment,
                    ]
                );

                // Recalculate expert rating
                $this->recalculateExpertRating($conversation->expert_id);
            }

            return $conversation->fresh(['review']);
        });
    }

    /**
     * Recalculate an expert's average rating and total reviews.
     */
    private function recalculateExpertRating(int $expertId): void
    {
        $stats = Review::where('expert_id', $expertId)
            ->selectRaw('AVG(rating) as avg_rating, COUNT(*) as total')
            ->first();

        Expert::where('id', $expertId)->update([
            'rating_avg'    => round($stats->avg_rating, 2),
            'total_reviews' => $stats->total,
        ]);
    }
}
