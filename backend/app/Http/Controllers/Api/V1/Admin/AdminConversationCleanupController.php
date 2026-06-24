<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Admin\AdminConversationCleanupRequest;
use App\Models\Conversation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminConversationCleanupController extends Controller
{
    /**
     * GET /api/v1/admin/conversations/cleanup/preview
     * Returns how many conversations would be deleted.
     */
    public function preview(Request $request): JsonResponse
    {
        $ageDays = (int) $request->input('age_days', 90);
        $state   = $request->input('state', 'closed');

        $count = $this->buildQuery($ageDays, $state)->count();

        return response()->json(['count' => $count]);
    }

    /**
     * DELETE /api/v1/admin/conversations/cleanup
     * Soft-deletes matching conversations.
     */
    public function destroy(AdminConversationCleanupRequest $request): JsonResponse
    {
        $ageDays = (int) $request->input('age_days');
        $state   = $request->input('state');

        $count = $this->buildQuery($ageDays, $state)->count();
        $this->buildQuery($ageDays, $state)->delete();

        return response()->json([
            'message' => "{$count} conversation(s) supprimée(s) avec succès.",
            'deleted' => $count,
        ]);
    }

    private function buildQuery(int $ageDays, string $state)
    {
        $cutoff = now()->subDays($ageDays);

        $query = Conversation::query()->where('created_at', '<=', $cutoff);

        if ($state === 'closed') {
            $query->where('status', 'closed');
        } else {
            // 'all' excludes only explicitly open/active conversations
            $query->whereNotIn('status', ['open']);
        }

        return $query;
    }
}
