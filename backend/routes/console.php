<?php

use App\Events\UserPresenceChanged;
use App\Models\Conversation;
use App\Models\User;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Broadcast offline events for users whose Redis presence key has expired.
// Runs every minute. Catches cases where the browser/app was killed hard
// without calling POST /users/offline (no visibilitychange/paused event fired).
Schedule::call(function () {
    // Users who sent a heartbeat in the last 5 minutes but not in the last 95 s
    // (90 s = Redis TTL, +5 s grace) — their key may have just expired.
    $candidates = User::whereBetween('last_seen_at', [
        now()->subMinutes(5),
        now()->subSeconds(95),
    ])->get();

    foreach ($candidates as $user) {
        // Skip if Redis key still alive — they are still heartbeating
        if (Cache::has("user_online_{$user->id}")) {
            continue;
        }

        // Key expired — broadcast offline to all their active conversations
        $query = Conversation::whereNotIn('status', ['closed']);
        if ($user->role->value === 'user') {
            $query->where('user_id', $user->id);
        } elseif ($user->role->value === 'expert' && $user->expert) {
            $query->where('expert_id', $user->expert->id);
        } else {
            continue;
        }

        foreach ($query->pluck('id') as $convId) {
            broadcast(new UserPresenceChanged($user->id, $convId, false));
        }
    }
})->everyMinute()->name('broadcast-offline-presence');
