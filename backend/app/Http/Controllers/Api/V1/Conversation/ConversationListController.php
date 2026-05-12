<?php

namespace App\Http\Controllers\Api\V1\Conversation;

use App\Http\Controllers\Controller;
use App\Http\Resources\ConversationResource;
use App\Models\Conversation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ConversationListController extends Controller
{
    /**
     * List conversations for the authenticated user.
     *
     * GET /api/v1/conversations
     */
    public function __invoke(Request $request): JsonResponse
    {
        $user     = $request->user();
        $isExpert = $user->role->value === 'expert';

        // Unread = messages from the OTHER party that haven't been read yet.
        // Without this filter, the expert's own sent messages (read_at = null) would
        // incorrectly inflate the badge count.
        $unreadSenderTypes = $isExpert ? ['user'] : ['expert', 'ai'];

        $query = Conversation::forUser($user)
            ->with(['user', 'category', 'expert.user', 'lastMessage'])
            ->withCount([
                'messages',
                // Use the relationship name alias so ConversationResource::whenCounted('unreadMessages') works
                'unreadMessages' => fn ($q) => $q
                    ->whereIn('sender_type', $unreadSenderTypes),
            ]);

        // Filter by status
        if ($request->filled('status')) {
            $query->where('status', $request->input('status'));
        }

        // Filter open only
        if ($request->boolean('open')) {
            $query->open();
        }

        $conversations = $query->orderByDesc('updated_at')
            ->paginate($request->integer('per_page', 15));

        return response()->json([
            'data' => ConversationResource::collection($conversations),
            'meta' => [
                'current_page' => $conversations->currentPage(),
                'last_page'    => $conversations->lastPage(),
                'per_page'     => $conversations->perPage(),
                'total'        => $conversations->total(),
            ],
        ]);
    }
}
