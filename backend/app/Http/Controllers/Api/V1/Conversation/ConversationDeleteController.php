<?php

namespace App\Http\Controllers\Api\V1\Conversation;

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

        if ($user->id !== $conversation->user_id && ! $user->isAdmin()) {
            return response()->json(['message' => 'Non autorisé.'], 403);
        }

        $conversation->delete();

        return response()->json(['message' => 'Conversation supprimée.']);
    }
}
