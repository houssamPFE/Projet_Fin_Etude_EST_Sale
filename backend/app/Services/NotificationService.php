<?php

namespace App\Services;

use App\Events\NotificationReceived;
use App\Models\Notification;
use App\Models\User;

class NotificationService
{
    /**
     * Create and broadcast a notification.
     */
    public function send(User $user, string $type, string $title, string $body, ?array $data = null): Notification
    {
        $notification = Notification::create([
            'user_id' => $user->id,
            'type'    => $type,
            'title'   => $title,
            'body'    => $body,
            'data'    => $data,
        ]);

        // Broadcast real-time
        event(new NotificationReceived(
            userId: $user->id,
            type: $type,
            title: $title,
            body: $body,
            data: $data,
        ));

        return $notification;
    }

    /**
     * Convenience: notify about expert application status.
     */
    public function expertValidated(User $user): Notification
    {
        return $this->send(
            $user,
            'expert.validated',
            'Candidature approuvée',
            'Félicitations ! Votre candidature d\'expert a été approuvée.',
        );
    }

    public function expertRejected(User $user, ?string $reason = null): Notification
    {
        return $this->send(
            $user,
            'expert.rejected',
            'Candidature refusée',
            $reason ?? 'Votre candidature d\'expert a été refusée.',
        );
    }

    /**
     * Notify about new conversation assignment.
     */
    public function conversationAssigned(User $expertUser, int $conversationId): Notification
    {
        return $this->send(
            $expertUser,
            'conversation.assigned',
            'Nouvelle conversation',
            'Vous avez été assigné à une nouvelle conversation.',
            ['conversation_id' => $conversationId],
        );
    }

    /**
     * Notify about a new review.
     */
    public function newReview(User $expertUser, int $rating, ?string $comment = null): Notification
    {
        return $this->send(
            $expertUser,
            'review.received',
            'Nouvel avis reçu',
            "Vous avez reçu un avis de {$rating}/5.",
            ['rating' => $rating, 'comment' => $comment],
        );
    }

    /**
     * Notify admins about a new expert application.
     */
    public function newExpertApplication(User $admin, User $applicant): Notification
    {
        return $this->send(
            $admin,
            'admin.expert_application',
            'Nouvelle candidature',
            "L'utilisateur {$applicant->name} a soumis une candidature.",
            ['applicant_id' => $applicant->id],
        );
    }
}
