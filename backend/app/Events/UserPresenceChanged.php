<?php

namespace App\Events;

use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

/**
 * ShouldBroadcastNow bypasses the Redis queue and broadcasts
 * synchronously inside the heartbeat/logout HTTP request.
 * This is critical for presence events — they must arrive in < 1 s.
 */
class UserPresenceChanged implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public int $userId,
        public ?int $conversationId,
        public bool $isOnline,
        public ?int $expertId = null,
    ) {}

    public function broadcastOn(): array
    {
        if ($this->conversationId !== null) {
            return [new PrivateChannel("conversation.{$this->conversationId}")];
        }

        // Expert-presence channel: lets any authenticated patient subscribed to
        // expert-presence.{expertId} receive instant online/offline updates.
        return [new PrivateChannel("expert-presence.{$this->expertId}")];
    }

    public function broadcastAs(): string
    {
        return 'user.presence';
    }

    public function broadcastWith(): array
    {
        return [
            'user_id'   => $this->userId,
            'is_online' => $this->isOnline,
        ];
    }
}
