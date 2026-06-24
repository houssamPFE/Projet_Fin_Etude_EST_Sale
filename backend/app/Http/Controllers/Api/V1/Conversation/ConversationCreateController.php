<?php

namespace App\Http\Controllers\Api\V1\Conversation;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Conversation\CreateConversationRequest;
use App\Http\Resources\ConversationResource;
use App\Http\Resources\MessageResource;
use App\Services\ConversationService;
use App\Services\MessageService;
use Illuminate\Http\JsonResponse;

class ConversationCreateController extends Controller
{
    public function __construct(
        private ConversationService $conversationService,
        private MessageService $messageService,
    ) {}

    /**
     * Create a new conversation with an initial message.
     *
     * POST /api/v1/conversations
     */
    public function __invoke(CreateConversationRequest $request): JsonResponse
    {
        $user = $request->user();

        $conversation = $this->conversationService->create($user, $request->validated());

        $data = ['conversation' => new ConversationResource($conversation)];

        // Optionally send an initial message if provided
        if ($request->filled('message')) {
            $message = $this->messageService->sendText(
                $conversation,
                $user,
                $request->validated('message')
            );
            $data['message'] = new MessageResource($message);
        }

        return response()->json([
            'message' => 'Conversation créée.',
            'data'    => $data,
        ], 201);
    }
}
