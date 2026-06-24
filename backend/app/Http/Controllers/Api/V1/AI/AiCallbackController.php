<?php

namespace App\Http\Controllers\Api\V1\AI;

use App\Enums\MessageSenderType;
use App\Enums\MessageType;
use App\Events\AIResponseReady;
use App\Http\Controllers\Controller;
use App\Models\AiLog;
use App\Models\Conversation;
use App\Models\Message;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AiCallbackController extends Controller
{
    /**
     * POST /api/v1/ai/callback
     * Called by n8n after AI workflow completes (async path).
     */
    public function __invoke(Request $request): JsonResponse
    {
        if ($request->header('X-N8N-Secret') !== config('services.n8n.secret')) {
            return response()->json(['message' => 'Unauthorized.'], 401);
        }

        $validated = $request->validate([
            'message_id'          => ['required', 'exists:messages,id'],
            'conversation_id'     => ['required', 'exists:conversations,id'],
            'response'            => ['required', 'string'],
            'confidence'          => ['required', 'numeric', 'min:0', 'max:1'],
            'escalate'            => ['required', 'boolean'],
            'urgency_level'       => ['required', 'in:low,moderate,urgent,emergency'],
            'specialty_suggested' => ['nullable', 'string'],
            'intent'              => ['nullable', 'string'],
            'suggest_expert'      => ['nullable', 'boolean'],
            'requires_premium'    => ['nullable', 'boolean'],
            'actions'             => ['nullable', 'array'],
            'actions.*.type'      => ['required_with:actions', 'string'],
            'actions.*.label'     => ['nullable', 'string'],
            'actions.*.specialty' => ['nullable', 'string'],
            'actions.*.locked'             => ['nullable', 'boolean'],
            'model'                        => ['required', 'string'],
            'tokens_used'                  => ['required', 'integer', 'min:0'],
            'expert_recommendation'        => ['nullable', 'array'],
            'expert_recommendation.id'     => ['nullable', 'integer'],
            'expert_recommendation.name'   => ['nullable', 'string'],
            'expert_recommendation.specialty' => ['nullable', 'string'],
            'expert_recommendation.rating' => ['nullable', 'numeric'],
        ]);

        $conversation = Conversation::findOrFail($validated['conversation_id']);
        $originalMessage = Message::findOrFail($validated['message_id']);

        // Create AI response message
        $aiMessage = Message::create([
            'conversation_id' => $conversation->id,
            'sender_type'     => MessageSenderType::Ai,
            'sender_id'       => null,
            'type'            => MessageType::Text,
            'content'         => $validated['response'],
            'metadata'        => array_merge(
                [
                    'confidence'           => $validated['confidence'],
                    'urgency_level'        => $validated['urgency_level'],
                    'specialty_suggested'  => $validated['specialty_suggested'] ?? null,
                    'intent'               => $validated['intent'] ?? null,
                    'suggest_expert'       => $validated['suggest_expert'] ?? false,
                    'requires_premium'     => $validated['requires_premium'] ?? false,
                    'actions'              => $validated['actions'] ?? [],
                    'escalate_recommended' => $validated['escalate'],
                    'model'                => $validated['model'],
                    'tokens_used'          => $validated['tokens_used'],
                ],
                // Expert recommendation card — Flutter _RichActionCard renders when type == 'expert_recommendation'
                isset($validated['expert_recommendation']) ? [
                    'type'   => 'expert_recommendation',
                    'expert' => $validated['expert_recommendation'],
                ] : []
            ),
        ]);

        // Log the AI interaction
        AiLog::create([
            'conversation_id' => $conversation->id,
            'message_id'      => $originalMessage->id,
            'workflow'        => 'analyze',
            'prompt'          => $originalMessage->content ?? '[audio]',
            'response'        => $validated['response'],
            'model'           => $validated['model'],
            'confidence'      => $validated['confidence'],
            'tokens_used'     => $validated['tokens_used'],
            'escalated'       => $validated['escalate'],
        ]);

        // Broadcast to the patient via Reverb
        event(new AIResponseReady($aiMessage));

        return response()->json(['message' => 'Callback processed.']);
    }
}
