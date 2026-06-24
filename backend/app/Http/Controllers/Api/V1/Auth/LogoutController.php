<?php

namespace App\Http\Controllers\Api\V1\Auth;

use App\Events\UserPresenceChanged;
use App\Http\Controllers\Controller;
use App\Models\Conversation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class LogoutController extends Controller
{
    public function __invoke(Request $request): JsonResponse
    {
        $user = $request->user();

        // Immediately mark user as offline — clear Redis key before token deletion
        Cache::forget("user_online_{$user->id}");
        $user->update(['last_seen_at' => now()]);

        // Broadcast offline status to all active conversations so other participants
        // see the dot go grey instantly without waiting for the Redis TTL to expire
        $this->broadcastOffline($user);

        // Also broadcast on the expert-presence channel so ExpertDetailPage updates instantly.
        if ($user->role->value === 'expert' && $user->expert) {
            broadcast(new UserPresenceChanged($user->id, null, false, $user->expert->id));
        }

        // Revoke all tokens
        $user->tokens()->delete();

        return response()->json(['message' => 'Déconnexion réussie.'])
            ->withoutCookie('refresh_token');
    }

    private function broadcastOffline(\App\Models\User $user): void
    {
        $query = Conversation::whereNotIn('status', ['closed']);

        // $user->role is an enum — compare with ->value (not ===  'string')
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
