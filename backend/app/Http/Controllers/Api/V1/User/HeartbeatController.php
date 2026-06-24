<?php

namespace App\Http\Controllers\Api\V1\User;

use App\Events\UserPresenceChanged;
use App\Http\Controllers\Controller;
use App\Models\Conversation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class HeartbeatController extends Controller
{
    /**
     * Update online presence — called every 30 seconds by clients.
     *
     * POST /api/v1/users/heartbeat
     */
    public function __invoke(Request $request): JsonResponse
    {
        $user = $request->user();

        // Update DB timestamps
        $user->update([
            'last_seen_at'       => now(),
            'last_activity_at'   => now(),
            'last_activity_type' => $user->last_activity_type ?? 'Navigation',
        ]);

        // Fast online check: Redis key expires in 90 seconds
        Cache::put("user_online_{$user->id}", true, now()->addSeconds(90));

        // Broadcast presence update to all active conversations involving this user,
        // so the other participant's online dot updates in real-time without refresh.
        $this->broadcastPresence($user);

        // Also broadcast on the expert-presence channel so ExpertDetailPage updates instantly.
        if ($user->role->value === 'expert' && $user->expert) {
            broadcast(new UserPresenceChanged($user->id, null, true, $user->expert->id));
        }

        return response()->json(['ok' => true]);
    }

    private function broadcastPresence(\App\Models\User $user): void
    {
        // Find all non-closed conversations where this user is a participant
        $query = Conversation::whereNotIn('status', ['closed']);

        // $user->role is a BackedEnum — use ->value for string comparison
        if ($user->role->value === 'user') {
            $query->where('user_id', $user->id);
        } elseif ($user->role->value === 'expert' && $user->expert) {
            $query->where('expert_id', $user->expert->id);
        } else {
            return;
        }

        foreach ($query->pluck('id') as $convId) {
            broadcast(new UserPresenceChanged($user->id, $convId, true));
        }
    }
}
