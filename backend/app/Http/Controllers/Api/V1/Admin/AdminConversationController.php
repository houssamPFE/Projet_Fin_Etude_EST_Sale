<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\ConversationResource;
use App\Models\Conversation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AdminConversationController extends Controller
{
    /**
     * GET /api/v1/admin/conversations
     */
    public function __invoke(Request $request): JsonResponse
    {
        $stats = $this->getStats();

        $conversations = Conversation::query()
            ->with(['user', 'expert.user', 'category'])
            ->withCount('messages')
            ->when($request->status, fn ($q) => $q->where('status', $request->status))
            ->when($request->channel, fn ($q) => $q->where('channel', $request->channel))
            ->when($request->tab === 'expert', fn ($q) => $q->whereNotNull('expert_id'))
            ->when($request->tab === 'ai',     fn ($q) => $q->whereNull('expert_id'))
            ->when($request->category_id, fn ($q) => $q->where('category_id', $request->category_id))
            ->when($request->search, fn ($q) => $q->whereHas(
                'user',
                fn ($u) => $u->where('name', 'like', "%{$request->search}%")
                              ->orWhere('email', 'like', "%{$request->search}%")
            ))
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return response()->json([
            'data'  => ConversationResource::collection($conversations),
            'meta'  => [
                'total'        => $conversations->total(),
                'current_page' => $conversations->currentPage(),
                'last_page'    => $conversations->lastPage(),
            ],
            'stats' => $stats,
        ]);
    }

    private function getStats(): array
    {
        $total       = Conversation::count();
        $ai          = Conversation::where('channel', 'ai')->count();
        $expert      = Conversation::where('channel', 'expert')->count();
        $hybrid      = Conversation::where('channel', 'hybrid')->count();
        $closed      = Conversation::where('status', 'closed')->count();
        $withExpert    = Conversation::whereNotNull('expert_id')->count();
        $withoutExpert = Conversation::whereNull('expert_id')->count();
        $avgRating = round((float) Conversation::whereNotNull('rating')->avg('rating'), 1);
        $avgDurationMinutes = round((float) Conversation::whereNotNull('closed_at')
            ->selectRaw('AVG(TIMESTAMPDIFF(MINUTE, created_at, closed_at)) as avg_dur')
            ->value('avg_dur'), 1);

        $topCategories = Conversation::select('category_id', DB::raw('COUNT(*) as total'))
            ->with('category')
            ->groupBy('category_id')
            ->orderByDesc('total')
            ->limit(5)
            ->get()
            ->map(fn ($c) => [
                'name'  => $c->category?->name ?? 'N/A',
                'icon'  => $c->category?->icon,
                'total' => (int) $c->total,
            ])
            ->values()
            ->toArray();

        return [
            'total'               => $total,
            'ai'                  => $ai,
            'expert'              => $expert,
            'hybrid'              => $hybrid,
            'closed'              => $closed,
            'open'                => $total - $closed,
            'with_expert'         => $withExpert,
            'without_expert'      => $withoutExpert,
            'avg_rating'          => $avgRating,
            'avg_duration_minutes'=> $avgDurationMinutes,
            'top_categories'      => $topCategories,
        ];
    }
}
