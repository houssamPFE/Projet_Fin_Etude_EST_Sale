<?php

namespace App\Services;

use Illuminate\Http\Client\PendingRequest;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class N8nService
{
    private PendingRequest $client;

    public function __construct()
    {
        $this->client = Http::baseUrl(config('services.n8n.base_url'))
            ->withHeaders([
                'X-N8N-Secret' => config('services.n8n.secret'),
                'Content-Type' => 'application/json',
            ])
            ->timeout(30);
    }

    /**
     * Analyze a user message: classify intent, generate AI response,
     * determine if escalation to human expert is needed.
     *
     * @return array{
     *   response: string,
     *   confidence: float,
     *   escalate: bool,
     *   category: string|null,
     *   model: string,
     *   tokens_used: int,
     * }
     */
    public function analyze(array $payload): array
    {
        return $this->callWebhook('analyze', $payload);
    }

    /**
     * Moderate content for inappropriate or harmful material.
     *
     * @return array{
     *   flagged: bool,
     *   categories: array,
     *   action: string,
     *   reason: string|null,
     * }
     */
    public function moderate(array $payload): array
    {
        return $this->callWebhook('moderate', $payload);
    }

    /**
     * Trigger audio transcription via n8n Workflow 4 (Whisper).
     */
    public function transcribe(array $payload): array
    {
        return $this->callWebhook('transcribe', $payload);
    }

    /**
     * Trigger text-to-speech via n8n Workflow 5 (ElevenLabs).
     */
    public function tts(array $payload): array
    {
        return $this->callWebhook('tts', $payload);
    }

    /**
     * Summarize a conversation (called on close).
     *
     * @return array{
     *   summary: string,
     *   key_topics: array,
     *   model: string,
     *   tokens_used: int,
     * }
     */
    public function summarize(array $payload): array
    {
        return $this->callWebhook('summarize', $payload);
    }

    /**
     * Call an n8n webhook by name.
     */
    private function callWebhook(string $name, array $payload): array
    {
        $url = config("services.n8n.webhooks.{$name}");

        if (! $url) {
            Log::warning("n8n webhook '{$name}' not configured.");
            return $this->fallbackResponse($name);
        }

        try {
            $response = $this->client->post($url, $payload);

            if ($response->successful()) {
                return $response->json();
            }

            Log::error("n8n webhook '{$name}' failed", [
                'status' => $response->status(),
                'body'   => $response->body(),
            ]);

            return $this->fallbackResponse($name);
        } catch (\Throwable $e) {
            Log::error("n8n webhook '{$name}' exception", [
                'error' => $e->getMessage(),
            ]);

            return $this->fallbackResponse($name);
        }
    }

    /**
     * Return a safe fallback when n8n is unreachable.
     */
    private function fallbackResponse(string $name): array
    {
        return match ($name) {
            'analyze' => [
                'response'    => 'Je ne suis pas en mesure de traiter votre demande pour le moment. Un expert va prendre le relais.',
                'confidence'  => 0.0,
                'escalate'    => true,
                'category'    => null,
                'model'       => 'fallback',
                'tokens_used' => 0,
            ],
            'moderate' => [
                'flagged'    => false,
                'categories' => [],
                'action'     => 'allow',
                'reason'     => null,
            ],
            'summarize' => [
                'summary'     => '',
                'key_topics'  => [],
                'model'       => 'fallback',
                'tokens_used' => 0,
            ],
            default => [],
        };
    }
}
