<?php

namespace App\Jobs;

use App\Enums\ConversationStatus;
use App\Enums\MessageSenderType;
use App\Models\Message;
use App\Services\N8nService;
use App\Services\VectorSearchService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class ProcessMessageJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 1;

    public function __construct(
        public Message $message,
    ) {}

    /**
     * Fire the n8n analyze webhook and return immediately.
     * The AI response arrives asynchronously via POST /api/v1/ai/callback
     * which is handled by AiCallbackController.
     */
    public function handle(N8nService $n8nService, VectorSearchService $vectorSearch): void
    {
        $message      = $this->message;
        $conversation = $message->conversation;

        // Skip if already handed off to a doctor or closed
        if (in_array($conversation->status, [ConversationStatus::Expert, ConversationStatus::Closed])) {
            return;
        }

        // Detect image messages (dispatched from sendFile for vision analysis)
        $isImage  = ($message->metadata['is_image'] ?? false) === true;
        // Generate a 60-min presigned URL at job-run time so Groq can fetch the
        // image even from a private S3 bucket (works for MinIO too).
        $imageUrl = ($isImage && $message->media_url)
            ? Storage::disk('s3')->temporaryUrl($message->media_url, now()->addMinutes(60))
            : null;

        // Build last 20 turns of conversation history for context
        $history = $conversation->messages()
            ->orderBy('created_at')
            ->take(20)
            ->get()
            ->map(fn (Message $msg) => [
                'role'    => $msg->sender_type === MessageSenderType::User ? 'user' : 'assistant',
                'content' => ($msg->metadata['is_image'] ?? false)
                    ? '[Image médicale]'
                    : ($msg->content ?? $msg->transcription ?? '[audio]'),
            ])
            ->toArray();

        $content = $isImage
            ? '[Image médicale]'
            : ($message->content ?? $message->transcription);

        if (! $content && ! $isImage) {
            Log::warning('ProcessMessageJob skipped empty message content', [
                'message_id'      => $message->id,
                'conversation_id' => $conversation->id,
            ]);

            return;
        }

        // RAG: search Qdrant for the most relevant knowledge base entries.
        // Results are injected into the n8n prompt as medical context.
        // If Qdrant is unavailable or returns nothing, we proceed without RAG.
        $knowledgeContext = '';
        try {
            $categorySlug = $conversation->category?->slug;
            $embedding    = $vectorSearch->embedText($content);

            if (! empty($embedding)) {
                $hits = $vectorSearch->search($embedding, $categorySlug, limit: 5);

                if (! empty($hits)) {
                    $knowledgeContext = collect($hits)
                        ->map(fn (array $hit) => trim($hit['payload']['answer'] ?? ''))
                        ->filter()
                        ->implode("\n---\n");
                }
            }
        } catch (\Throwable $e) {
            Log::warning('RAG search skipped', [
                'message_id' => $message->id,
                'error'      => $e->getMessage(),
            ]);
        }

        // Fire-and-forget — n8n calls Groq and POSTs the result back to
        // AiCallbackController which creates the AI message and broadcasts it.
        $n8nService->analyze([
            'message_id'        => $message->id,
            'conversation_id'   => $conversation->id,
            'category_id'       => $conversation->category_id,
            'content'           => $content,
            'media_url'         => $isImage ? $imageUrl : null,
            'is_image'          => $isImage,
            'history'           => $history,
            'knowledge_context' => $knowledgeContext,
        ]);
    }

    public function failed(\Throwable $exception): void
    {
        Log::error('ProcessMessageJob failed', [
            'message_id'      => $this->message->id,
            'conversation_id' => $this->message->conversation_id,
            'error'           => $exception->getMessage(),
        ]);
    }
}
