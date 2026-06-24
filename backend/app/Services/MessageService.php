<?php

namespace App\Services;

use App\Enums\ConversationStatus;
use App\Enums\MessageSenderType;
use App\Enums\MessageType;
use App\Events\MessageRead;
use App\Events\MessageSent;
use App\Jobs\ProcessMessageJob;
use App\Jobs\TranscribeAudioJob;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

class MessageService
{
    /**
     * Send a text message in a conversation.
     */
    public function sendText(Conversation $conversation, User $user, string $content): Message
    {
        $senderType = $this->resolveSenderType($conversation, $user);

        $message = Message::create([
            'conversation_id' => $conversation->id,
            'sender_type'     => $senderType,
            'sender_id'       => $user->id,
            'type'            => MessageType::Text,
            'content'         => $content,
        ]);

        if ($senderType === MessageSenderType::User) {
            $user->update([
                'last_activity_at'   => now(),
                'last_activity_type' => 'Conversation',
            ]);
        }

        // Trigger AI processing for user messages in AI-mode conversations
        if ($senderType === MessageSenderType::User && $conversation->status === ConversationStatus::Ai) {
            ProcessMessageJob::dispatch($message);
        }

        event(new MessageSent($message));

        return $message;
    }

    /**
     * Send an audio message. Upload to S3, create message with media_url.
     */
    public function sendAudio(Conversation $conversation, User $user, UploadedFile $audio): Message
    {
        $senderType = $this->resolveSenderType($conversation, $user);

        $path = $audio->store(
            "conversations/{$conversation->id}/audio",
            's3'
        );

        $message = Message::create([
            'conversation_id' => $conversation->id,
            'sender_type'     => $senderType,
            'sender_id'       => $user->id,
            'type'            => MessageType::Audio,
            'media_url'       => $path,
        ]);

        if ($senderType === MessageSenderType::User && $conversation->status === ConversationStatus::Ai) {
            TranscribeAudioJob::dispatch($message);
        }

        event(new MessageSent($message));

        return $message;
    }

    /**
     * Send a file message. Upload to S3, create message with media_url.
     * For image files in AI-mode conversations, dispatch ProcessMessageJob
     * so the vision model can analyse the image and reply to the patient.
     */
    public function sendFile(Conversation $conversation, User $user, UploadedFile $file): Message
    {
        $senderType = $this->resolveSenderType($conversation, $user);

        $path = $file->store(
            "conversations/{$conversation->id}/files",
            's3'
        );

        $mime    = $file->getMimeType() ?? '';
        $isImage = in_array($mime, [
            'image/jpeg', 'image/jpg', 'image/png',
            'image/gif',  'image/webp',
        ], true);

        $metadata = $isImage ? [
            'is_image'  => true,
            'mime_type' => $mime,
        ] : null;

        $message = Message::create([
            'conversation_id' => $conversation->id,
            'sender_type'     => $senderType,
            'sender_id'       => $user->id,
            'type'            => MessageType::File,
            'content'         => $file->getClientOriginalName(),
            'media_url'       => $path,
            'metadata'        => $metadata,
        ]);

        // Trigger AI vision analysis for patient image uploads in AI-mode conversations
        if ($isImage && $senderType === MessageSenderType::User && $conversation->status === ConversationStatus::Ai) {
            ProcessMessageJob::dispatch($message);
        }

        event(new MessageSent($message));

        return $message;
    }

    /**
     * Mark a message as read.
     */
    public function markAsRead(Message $message): Message
    {
        if (! $message->read_at) {
            $message->update(['read_at' => now()]);
            event(new MessageRead($message->fresh()));
        }

        return $message;
    }

    /**
     * Mark all messages in a conversation as read for a given user.
     * Only marks messages NOT sent by the user.
     */
    public function markAllAsRead(Conversation $conversation, User $user): int
    {
        $senderType = $this->resolveSenderType($conversation, $user);

        return Message::where('conversation_id', $conversation->id)
            ->where('sender_type', '!=', $senderType)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);
    }

    /**
     * Determine the sender type based on user's role in the conversation.
     */
    private function resolveSenderType(Conversation $conversation, User $user): MessageSenderType
    {
        if ($conversation->expert_id && $conversation->expert?->user_id === $user->id) {
            return MessageSenderType::Expert;
        }

        return MessageSenderType::User;
    }
}
