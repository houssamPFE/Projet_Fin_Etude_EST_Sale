<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\ExpertResource;
use App\Models\Conversation;
use App\Models\Expert;
use App\Models\Message;
use App\Models\Payment;
use App\Models\User;
use App\Enums\ConversationChannel;
use App\Enums\ConversationStatus;
use App\Enums\ExpertStatus;
use App\Enums\PaymentStatus;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class AdminDashboardController extends Controller
{
    /**
     * GET /api/v1/admin/dashboard
     */
    public function __invoke(Request $request): JsonResponse
    {
        $payload = Cache::remember('admin.dashboard', 90, fn () => $this->compute());

        return response()->json(['data' => $payload]);
    }

    private function compute(): array
    {
        $now       = Carbon::now();
        $weekStart = $now->copy()->subDays(6)->startOfDay();
        $prevStart = $now->copy()->subDays(13)->startOfDay();
        $prevEnd   = $now->copy()->subDays(7)->endOfDay();

        // ── KPI stats ──────────────────────────────────────────────
        $totalUsers    = User::count();
        $totalExperts  = Expert::where('status', ExpertStatus::Validated)->count();
        $pendingExperts = Expert::where('status', ExpertStatus::Pending)->count();
        $totalConvs    = Conversation::count();
        $activeConvs   = Conversation::whereIn('status', [ConversationStatus::Ai, ConversationStatus::Expert])->count();
        $totalRevenue  = Payment::where('status', PaymentStatus::Completed)->sum('amount');

        // ── Weekly trends ──────────────────────────────────────────
        $usersThisWeek  = User::where('created_at', '>=', $weekStart)->count();
        $usersPrevWeek  = User::whereBetween('created_at', [$prevStart, $prevEnd])->count();
        $convsThisWeek  = Conversation::where('created_at', '>=', $weekStart)->count();
        $convsPrevWeek  = Conversation::whereBetween('created_at', [$prevStart, $prevEnd])->count();
        $revenueThisWeek = Payment::where('status', PaymentStatus::Completed)->where('created_at', '>=', $weekStart)->sum('amount');
        $revenuePrevWeek = Payment::where('status', PaymentStatus::Completed)->whereBetween('created_at', [$prevStart, $prevEnd])->sum('amount');

        // ── Conversations per day (last 7 days) ───────────────────
        $dailyConvs = Conversation::select(
                DB::raw('DATE(created_at) as date'),
                DB::raw('COUNT(*) as count')
            )
            ->where('created_at', '>=', $weekStart)
            ->groupBy('date')
            ->orderBy('date')
            ->get()
            ->keyBy('date');

        $chartData = [];
        for ($i = 6; $i >= 0; $i--) {
            $day = $now->copy()->subDays($i)->format('Y-m-d');
            $chartData[] = [
                'date'  => Carbon::parse($day)->locale('fr')->isoFormat('ddd D'),
                'total' => $dailyConvs[$day]->count ?? 0,
            ];
        }

        // ── AI vs Expert routing split ─────────────────────────────
        $aiCount     = Conversation::where('channel', ConversationChannel::Ai)->count();
        $expertCount = Conversation::where('channel', ConversationChannel::Expert)->count();
        $hybridCount = Conversation::where('channel', ConversationChannel::Hybrid)->count();

        // ── Last 5 conversations ───────────────────────────────────
        $recentConversations = Conversation::with(['user', 'category', 'expert.user'])
            ->orderByDesc('created_at')
            ->limit(5)
            ->get()
            ->map(fn ($c) => [
                'id'       => $c->id,
                'patient'  => $c->user?->name,
                'category' => $c->category?->name,
                'status'   => $c->status->value,
                'channel'  => $c->channel->value,
                'date'     => $c->created_at->toISOString(),
            ])->values()->toArray();

        // ── Last 5 payments ────────────────────────────────────────
        $recentPayments = Payment::with(['user'])
            ->orderByDesc('created_at')
            ->limit(5)
            ->get()
            ->map(fn ($p) => [
                'id'       => $p->id,
                'patient'  => $p->user?->name,
                'amount'   => $p->amount,
                'currency' => $p->currency,
                'status'   => $p->status->value,
                'provider' => $p->provider->value,
                'date'     => $p->created_at->toISOString(),
            ])->values()->toArray();

        // ── Pending expert applications ────────────────────────────
        $pendingApplications = Expert::with(['user', 'category', 'documents'])
            ->where('status', ExpertStatus::Pending)
            ->orderBy('created_at')
            ->limit(5)
            ->get();

        // ── Top specialties ────────────────────────────────────────
        $topSpecialties = Conversation::select('category_id', DB::raw('COUNT(*) as total'))
            ->with('category')
            ->groupBy('category_id')
            ->orderByDesc('total')
            ->limit(5)
            ->get()
            ->map(fn ($c) => [
                'name'  => $c->category?->name ?? 'N/A',
                'total' => $c->total,
            ])->values()->toArray();

        return [
            'total_users'            => $totalUsers,
            'total_experts'          => $totalExperts,
            'pending_experts'        => $pendingExperts,
            'total_conversations'    => $totalConvs,
            'active_conversations'   => $activeConvs,
            'total_revenue'          => $totalRevenue,
            'trends' => [
                'users'   => $this->trend($usersThisWeek, $usersPrevWeek),
                'convs'   => $this->trend($convsThisWeek, $convsPrevWeek),
                'revenue' => $this->trend((float)$revenueThisWeek, (float)$revenuePrevWeek),
            ],
            'daily_conversations' => $chartData,
            'routing_split'       => [
                ['name' => 'IA',      'value' => $aiCount],
                ['name' => 'Expert',  'value' => $expertCount],
                ['name' => 'Hybride', 'value' => $hybridCount],
            ],
            'recent_conversations'  => $recentConversations,
            'recent_payments'       => $recentPayments,
            'pending_applications'  => ExpertResource::collection($pendingApplications)->resolve(),
            'top_specialties'       => $topSpecialties,
        ];
    }

    private function trend(float $current, float $previous): array
    {
        $diff = $current - $previous;
        $pct  = $previous > 0 ? round(($diff / $previous) * 100) : ($current > 0 ? 100 : 0);
        return ['diff' => $diff, 'pct' => $pct, 'up' => $diff >= 0];
    }
}
