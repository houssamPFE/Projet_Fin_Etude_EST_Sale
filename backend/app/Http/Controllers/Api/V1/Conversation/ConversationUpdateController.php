<?php

namespace App\Http\Controllers\Api\V1\Conversation;

use App\Http\Controllers\Controller;
use App\Http\Resources\ConversationResource;
use App\Models\Conversation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ConversationUpdateController extends Controller
{
    /**
     * Update a conversation (rename).
     *
     * PATCH /api/v1/conversations/{conversation}
     */
    public function __invoke(Request $request, Conversation $conversation): JsonResponse
    {
        $user = $request->user();

        if ($user->id !== $conversation->user_id && ! $user->isAdmin()) {
            return response()->json(['message' => 'Non autorisé.'], 403);
        }

        $validated = $request->validate([
            'title' => ['required', 'string', 'max:255'],
        ]);

        $conversation->update($validated);

        return response()->json([
            'message' => 'Conversation renommée.',
            'data'    => new ConversationResource($conversation->fresh(['category', 'expert.user'])),
        ]);
    }
}
