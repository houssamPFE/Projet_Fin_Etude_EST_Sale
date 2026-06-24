<?php

namespace App\Events;

use App\Http\Resources\ConversationResource;
use App\Models\Conversation;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class ConversationEscalated implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public Conversation $conversation,
    ) {}

    public function broadcastOn(): array
    {
        $channels = [];

        // Notify the assigned expert
        if ($this->conversation->expert_id) {
            $channels[] = new PrivateChannel("expert.{$this->conversation->expert_id}");
        }

        return $channels;
    }

    public function broadcastAs(): string
    {
        return 'conversation.escalated';
    }

    public function broadcastWith(): array
    {
        $this->conversation->load(['user', 'category']);

        return [
            'conversation' => (new ConversationResource($this->conversation))->resolve(),
        ];
    }
}
