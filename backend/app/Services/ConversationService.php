<?php

namespace App\Services;

use App\Enums\ConversationChannel;
use App\Enums\ConversationStatus;
use App\Events\ConversationAssigned;
use App\Events\ConversationEscalated;
use App\Jobs\UpdateExpertRatingJob;
use App\Models\Category;
use App\Models\Conversation;
use App\Models\Expert;
use App\Models\Review;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\HttpException;

class ConversationService
{
    public function __construct(
        private NotificationService $notificationService,
        private PaymentService      $paymentService,
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

            // Gate: starting a direct doctor consultation requires a paid plan with credits
            if (! $user->canConsult()) {
                throw new HttpException(402, $user->hasPaidPlan()
                    ? 'Vous n\'avez plus de crédits de consultation. Achetez un crédit supplémentaire pour continuer.'
                    : 'Les consultations avec un médecin nécessitent un abonnement Pro ou Premium.'
                );
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
            // Deduct 1 credit for a direct doctor consultation
            $this->paymentService->consumeCredit($user);
            event(new ConversationAssigned($conversation));
            $this->notificationService->conversationAssigned($expert->user, $conversation->id);
        }

        return $conversation;
    }

    /**
     * Escalate a conversation from AI to a human expert.
     * Requires the patient to have an active plan with credits.
     * If $expertId is provided, assign that specific expert (patient chose).
     * Otherwise auto-assign the best available expert for the specialty.
     */
    public function escalate(Conversation $conversation, ?string $specialtySlug = null, ?int $expertId = null): Conversation
    {
        $patient = $conversation->user;

        // Gate: free users or users with no credits cannot escalate
        if (! $patient->canConsult()) {
            throw new HttpException(402, $patient->hasPaidPlan()
                ? 'Vous n\'avez plus de crédits de consultation. Achetez un crédit supplémentaire pour continuer.'
                : 'Les consultations avec un médecin nécessitent un abonnement Pro ou Premium.'
            );
        }

        // Patient chose a specific doctor → use them directly
        if ($expertId) {
            $expert = Expert::validated()
                ->available()
                ->where('id', $expertId)
                ->first();
        } else {
            $suggestedCategory = $this->resolveSuggestedCategory($specialtySlug);
            $expert = $this->findAvailableExpertForCategory($suggestedCategory?->id)
                ?? $this->findAvailableExpertForCategory($conversation->category_id);
        }

        if (! $expert) {
            return $conversation->fresh(['user', 'category', 'expert.user']);
        }

        $conversation->update([
            'expert_id'   => $expert->id,
            'category_id' => $expert->category_id,
            'status'      => ConversationStatus::Expert,
            'channel'     => $conversation->channel === ConversationChannel::Ai
                ? ConversationChannel::Hybrid
                : $conversation->channel,
        ]);

        $freshConversation = $conversation->fresh(['user', 'category', 'expert.user']);

        // Deduct 1 credit and broadcast events
        $this->paymentService->consumeCredit($patient);
        event(new ConversationAssigned($freshConversation));
        event(new ConversationEscalated($freshConversation));
        $this->notificationService->conversationAssigned($expert->user, $conversation->id);

        return $freshConversation;
    }

    private function resolveSuggestedCategory(?string $specialtySlug): ?Category
    {
        if (! $specialtySlug) {
            return null;
        }

        return Category::query()
            ->where('slug', trim($specialtySlug))
            ->where('is_active', true)
            ->first();
    }

    private function findAvailableExpertForCategory(?int $categoryId): ?Expert
    {
        if (! $categoryId) {
            return null;
        }

        return Expert::validated()
            ->available()
            ->where('category_id', $categoryId)
            ->orderByDesc('rating_avg')
            ->first();
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

                // Dispatch async rating recalculation (non-blocking)
                UpdateExpertRatingJob::dispatch($conversation->expert_id);
            }

            return $conversation->fresh(['review']);
        });
    }
}
