<?php

namespace App\Jobs;

use App\Models\Message;
use App\Services\N8nService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Storage;

class TranscribeAudioJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $backoff = 10;

    public function __construct(private Message $message) {}

    public function handle(N8nService $n8nService): void
    {
        // Generate a presigned S3 URL valid for 15 minutes so n8n can download the file.
        // media_url stores the S3 path (e.g. conversations/1/audio/abc.webm), not a URL.
        $audioUrl = Storage::disk('s3')->temporaryUrl(
            $this->message->media_url,
            now()->addMinutes(15)
        );

        $n8nService->transcribe([
            'message_id'      => $this->message->id,
            'conversation_id' => $this->message->conversation_id,
            'audio_url'       => $audioUrl,
            'language'        => $this->message->conversation?->user?->language ?? 'fr',
        ]);
    }
}
