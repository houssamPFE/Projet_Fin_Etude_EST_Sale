<?php

namespace App\Services;

use App\Events\NotificationReceived;
use App\Jobs\SendPushNotificationJob;
use App\Models\Notification;
use App\Models\User;

class NotificationService
{
    /**
     * Notification types that warrant high-priority FCM push (e.g. emergency).
     */
    private const HIGH_PRIORITY_TYPES = [
        'conversation.emergency',
        'conversation.assigned',
    ];

    /**
     * Create a DB notification, broadcast via Reverb, and queue an FCM push.
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

        // Real-time broadcast (WebSocket — only works when app is open)
        event(new NotificationReceived(
            userId: $user->id,
            type:   $type,
            title:  $title,
            body:   $body,
            data:   $data,
        ));

        // FCM push (works even when app is closed)
        dispatch(new SendPushNotificationJob(
            user:         $user,
            title:        $title,
            body:         $body,
            data:         array_merge($data ?? [], ['type' => $type]),
            highPriority: in_array($type, self::HIGH_PRIORITY_TYPES),
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
     * Notify expert about new conversation assignment.
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
     * Notify patient that the AI escalated to a doctor (emergency).
     */
    public function conversationEmergency(User $patientUser, int $conversationId): Notification
    {
        return $this->send(
            $patientUser,
            'conversation.emergency',
            '🚨 Situation d\'urgence détectée',
            'Un médecin a été alerté. En cas d\'urgence vitale, appelez le 141 (SAMU).',
            ['conversation_id' => $conversationId],
        );
    }

    /**
     * Notify patient that a doctor replied.
     */
    public function doctorReplied(User $patientUser, string $doctorName, int $conversationId): Notification
    {
        return $this->send(
            $patientUser,
            'message.doctor_reply',
            "Dr. {$doctorName} vous a répondu",
            'Appuyez pour lire le message.',
            ['conversation_id' => $conversationId],
        );
    }

    /**
     * Notify about a new review received.
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
