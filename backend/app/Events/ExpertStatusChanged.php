<?php

namespace App\Events;

use App\Models\Expert;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class ExpertStatusChanged implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public Expert $expert,
        public bool $isAvailable,
    ) {}

    public function broadcastOn(): array
    {
        return [
            new PresenceChannel('experts.online'),
        ];
    }

    public function broadcastAs(): string
    {
        return 'expert.status';
    }

    public function broadcastWith(): array
    {
        return [
            'expert_id'    => $this->expert->id,
            'user_id'      => $this->expert->user_id,
            'is_available' => $this->isAvailable,
            'category_id'  => $this->expert->category_id,
        ];
    }
}
