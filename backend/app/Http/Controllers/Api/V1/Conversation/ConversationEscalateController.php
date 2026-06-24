<?php

namespace App\Http\Controllers\Api\V1\Conversation;

use App\Http\Controllers\Controller;
use App\Http\Resources\ConversationResource;
use App\Models\Conversation;
use App\Services\ConversationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ConversationEscalateController extends Controller
{
    public function __construct(private ConversationService $conversationService) {}

    /**
     * Escalate a conversation from AI to a human expert.
     *
     * POST /api/v1/conversations/{conversation}/escalate
     */
    public function __invoke(Request $request, Conversation $conversation): JsonResponse
    {
        if ($request->user()->id !== $conversation->user_id) {
            return response()->json(['message' => 'Non autorisé.'], 403);
        }

        if ($conversation->status->value === 'closed') {
            return response()->json([
                'message' => 'Impossible d\'escalader une conversation fermée.',
            ], 422);
        }

        if ($conversation->status->value === 'expert') {
            return response()->json([
                'message' => 'Cette conversation est déjà assignée à un expert.',
            ], 422);
        }

        $conversation = $this->conversationService->escalate(
            $conversation,
            $request->string('specialty')->toString() ?: null,
            $request->integer('expert_id') ?: null,
        );

        $message = $conversation->expert_id
            ? 'Conversation transférée à un expert.'
            : 'Aucun expert disponible pour le moment. Vous serez notifié dès qu\'un expert sera disponible.';

        return response()->json([
            'message' => $message,
            'data'    => new ConversationResource($conversation),
        ]);
    }
}
