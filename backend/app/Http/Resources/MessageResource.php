<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Storage;

class MessageResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'              => $this->id,
            'conversation_id' => $this->conversation_id,
            'sender_type'     => $this->sender_type->value,
            'sender_id'       => $this->sender_id,
            'type'            => $this->type->value,
            'content'         => $this->content,
            'media_url'       => $this->media_url,
            'audio_url'       => $this->audioUrl(),
            'transcription'   => $this->transcription,
            'metadata'        => $this->metadata,
            'read_at'         => $this->read_at?->toISOString(),
            'created_at'      => $this->created_at->toISOString(),
        ];
    }

    private function audioUrl(): ?string
    {
        if (! $this->media_url) {
            return null;
        }
        return Storage::disk('s3')->url($this->media_url);
    }
}
