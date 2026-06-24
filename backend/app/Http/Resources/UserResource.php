<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Cache;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        // A user is "online" if:
        // 1. They have opted-in to show online status (is_online_visible = true)
        // 2. Their heartbeat Redis key is alive (sent within 90 s)
        $isOnlineRaw = Cache::has("user_online_{$this->id}");
        $isOnline    = $this->is_online_visible && $isOnlineRaw;

        // Last seen text (only shown when offline and visible)
        $lastSeen = null;
        if (! $isOnlineRaw && $this->last_seen_at) {
            $lastSeen = $this->last_seen_at->toISOString();
        }

        $userStatus = 'active';
        if (! $this->is_active) {
            $userStatus = 'suspended';
        } elseif (! $this->email_verified_at) {
            $userStatus = 'pending';
        }

        return [
            'id'               => $this->id,
            'name'             => $this->name,
            'email'            => $this->email,
            'phone'            => $this->phone,
            'role'             => $this->role->value,
            'avatar_url'       => $this->avatar_url,
            'language'         => $this->language,
            'is_active'        => $this->is_active,
            'user_status'      => $userStatus,
            'is_online'        => $isOnline,
            'is_online_visible'=> (bool) $this->is_online_visible,
            'last_seen_at'     => $this->last_seen_at?->toISOString(),
            'email_verified_at'=> $this->email_verified_at?->toISOString(),
            'two_factor_enabled' => $this->two_factor_confirmed_at !== null,
            'require_2fa'      => (bool) $this->require_2fa,
            'oauth_provider'   => $this->google_id ? 'google' : ($this->facebook_id ? 'facebook' : null),
            'last_activity_at' => $this->last_activity_at?->toISOString(),
            'last_activity_type' => $this->last_activity_type,
            'created_at'         => $this->created_at->toISOString(),
            // Subscription
            'plan'                  => $this->plan ?? 'free',
            'consultation_credits'  => $this->consultation_credits ?? 0,
            'plan_expires_at'       => $this->plan_expires_at?->toISOString(),
            'plan_is_active'        => $this->hasPaidPlan(),
        ];
    }
}
