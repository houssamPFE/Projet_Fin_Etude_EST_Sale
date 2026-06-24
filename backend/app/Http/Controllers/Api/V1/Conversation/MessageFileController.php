<?php

namespace App\Http\Controllers\Api\V1\Conversation;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Conversation\SendFileRequest;
use App\Http\Resources\MessageResource;
use App\Models\Conversation;
use App\Services\MessageService;
use Illuminate\Http\JsonResponse;

class MessageFileController extends Controller
{
    public function __construct(private MessageService $messageService) {}

    /**
     * Send a file (image or document) in a conversation.
     *
     * POST /api/v1/conversations/{conversation}/messages/file
     */
    public function __invoke(SendFileRequest $request, Conversation $conversation): JsonResponse
    {
        $user = $request->user();

        if (! $this->canSend($user, $conversation)) {
            return response()->json(['message' => 'Non autorisé.'], 403);
        }

        if ($conversation->status->value === 'closed') {
            return response()->json([
                'message' => 'Impossible d\'envoyer un fichier dans une conversation fermée.',
            ], 422);
        }

        $message = $this->messageService->sendFile(
            $conversation,
            $user,
            $request->file('file')
        );

        return response()->json([
            'data' => new MessageResource($message),
        ], 201);
    }

    private function canSend($user, $conversation): bool
    {
        return $user->id === $conversation->user_id
            || ($conversation->expert && $conversation->expert->user_id === $user->id);
    }
}
