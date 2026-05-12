<?php

namespace App\Http\Controllers\Api\V1\User;

use App\Events\UserPresenceChanged;
use App\Http\Controllers\Controller;
use App\Models\Conversation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class OfflineController extends Controller
{
    /**
     * Mark the user as offline immediately.
     * Called when the mobile app is backgrounded/paused or when the web
     * tab is closed — so the dot goes grey instantly without waiting for
     * the Redis TTL (90 s) to expire.
     *
     * POST /api/v1/users/offline
     */
    public function __invoke(Request $request): JsonResponse
    {
        $user = $request->user();

        Cache::forget("user_online_{$user->id}");
        $user->update(['last_seen_at' => now()]);

        $this->broadcastOffline($user);

        return response()->json(['ok' => true]);
    }

    private function broadcastOffline(\App\Models\User $user): void
    {
        $query = Conversation::whereNotIn('status', ['closed']);

        if ($user->role->value === 'user') {
            $query->where('user_id', $user->id);
        } elseif ($user->role->value === 'expert' && $user->expert) {
            $query->where('expert_id', $user->expert->id);
        } else {
            return;
        }

        foreach ($query->pluck('id') as $convId) {
            broadcast(new UserPresenceChanged($user->id, $convId, false));
        }
    }
}
