<?php

namespace App\Http\Controllers\Api\V1\Conversation;

use App\Events\MessageDeleted;
use App\Http\Controllers\Controller;
use App\Models\Conversation;
use App\Models\Message;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MessageDeleteController extends Controller
{
    /**
     * Soft-delete a message.
     *
     * DELETE /api/v1/conversations/{conversation}/messages/{message}
     *
     * Only the original sender can delete their own message.
     * Admins can delete any message.
     */
    public function __invoke(Request $request, Conversation $conversation, Message $message): JsonResponse
    {
        $user = $request->user();

        // Authorization: must belong to this conversation and be the sender
        if ($message->conversation_id !== $conversation->id) {
            return response()->json(['message' => 'Message introuvable.'], 404);
        }

        $isOwner    = $message->sender_id === $user->id;
        $isAdmin    = $user->role === 'admin';
        $isExpertInConversation = $conversation->expert?->user_id === $user->id;

        if (! $isOwner && ! $isAdmin && ! $isExpertInConversation) {
            return response()->json(['message' => 'Non autorisé.'], 403);
        }

        $messageId      = $message->id;
        $conversationId = $message->conversation_id;

        // Soft delete — medical records are never hard-deleted
        $message->delete();

        // Broadcast to all participants in real time
        broadcast(new MessageDeleted($messageId, $conversationId, $user->id))->toOthers();

        return response()->json(['message' => 'Message supprimé.']);
    }
}
