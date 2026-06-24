<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\PaymentResource;
use App\Models\Payment;
use App\Enums\PaymentStatus;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminPaymentsController extends Controller
{
    /**
     * GET /api/v1/admin/payments
     */
    public function __invoke(Request $request): JsonResponse
    {
        // payment_type filter: pro (249), premium (449), extra (89)
        $typeAmounts = ['pro' => 249, 'premium' => 449, 'extra' => 89];

        $payments = Payment::query()
            ->with(['user', 'expert.user', 'conversation'])
            ->when($request->status,   fn ($q) => $q->where('status', $request->status))
            ->when($request->provider, fn ($q) => $q->where('provider', $request->provider))
            ->when($request->payment_type && isset($typeAmounts[$request->payment_type]),
                fn ($q) => $q->where('amount', $typeAmounts[$request->payment_type]))
            ->when($request->search,   fn ($q) => $q->whereHas('user', fn ($q2) =>
                $q2->where('name', 'like', "%{$request->search}%")
                   ->orWhere('email', 'like', "%{$request->search}%")))
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        $done = fn () => Payment::where('status', PaymentStatus::Completed);

        $stats = [
            'total_revenue'        => $done()->sum('amount'),
            'stripe_revenue'       => $done()->where('provider', 'stripe')->sum('amount'),
            'cmi_revenue'          => $done()->where('provider', 'cmi')->sum('amount'),
            'subscription_revenue' => $done()->whereIn('amount', [249, 449])->sum('amount'),
            'extra_revenue'        => $done()->where('amount', 89)->sum('amount'),
            'pending_count'        => Payment::where('status', PaymentStatus::Pending)->count(),
            'completed_count'      => Payment::where('status', PaymentStatus::Completed)->count(),
            'failed_count'         => Payment::where('status', PaymentStatus::Failed)->count(),
            'plan_breakdown'       => [
                'pro'     => $done()->where('amount', 249)->count(),
                'premium' => $done()->where('amount', 449)->count(),
                'extra'   => $done()->where('amount', 89)->count(),
            ],
        ];

        return response()->json([
            'data' => PaymentResource::collection($payments),
            'meta' => [
                'total'        => $payments->total(),
                'current_page' => $payments->currentPage(),
                'last_page'    => $payments->lastPage(),
            ],
            'stats' => $stats,
        ]);
    }
}
