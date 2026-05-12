<?php

namespace App\Http\Controllers\Api\V1\Conversation;

use App\Http\Controllers\Controller;
use App\Http\Resources\ConversationResource;
use App\Models\Conversation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ConversationShowController extends Controller
{
    /**
     * Show a single conversation with details.
     *
     * GET /api/v1/conversations/{conversation}
     */
    public function __invoke(Request $request, Conversation $conversation): JsonResponse
    {
        $user     = $request->user();
        $isExpert = $user->role->value === 'expert';

        // Authorization check
        if (! $this->canAccess($user, $conversation)) {
            return response()->json(['message' => 'Non autorisé.'], 403);
        }

        // Unread = only messages from the OTHER party (not the viewer's own messages)
        $unreadSenderTypes = $isExpert ? ['user'] : ['expert', 'ai'];

        $conversation->load(['user', 'category', 'expert.user', 'review'])
            ->loadCount([
                'messages',
                'unreadMessages' => fn ($q) => $q->whereIn('sender_type', $unreadSenderTypes),
            ]);

        return response()->json([
            'data' => new ConversationResource($conversation),
        ]);
    }

    private function canAccess($user, $conversation): bool
    {
        return $user->id === $conversation->user_id
            || ($conversation->expert && $conversation->expert->user_id === $user->id)
            || $user->isAdmin();
    }
}
