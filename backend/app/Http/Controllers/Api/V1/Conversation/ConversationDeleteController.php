<?php

namespace App\Http\Controllers\Api\V1\Conversation;

use App\Events\ConversationDeleted;
use App\Http\Controllers\Controller;
use App\Models\Conversation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ConversationDeleteController extends Controller
{
    /**
     * Delete a conversation.
     *
     * DELETE /api/v1/conversations/{conversation}
     */
    public function __invoke(Request $request, Conversation $conversation): JsonResponse
    {
        $user = $request->user();

        $isOwner  = $user->id === $conversation->user_id;
        $isExpert = $user->expert && $user->expert->id === $conversation->expert_id;

        if (! $isOwner && ! $isExpert && ! $user->isAdmin()) {
            return response()->json(['message' => 'Non autorisé.'], 403);
        }

        $conversationId = $conversation->id;
        $userId = $conversation->user_id;

        $conversation->delete();

        broadcast(new ConversationDeleted($conversationId, $userId))->toOthers();

        return response()->json(['message' => 'Conversation supprimée.']);
    }
}
