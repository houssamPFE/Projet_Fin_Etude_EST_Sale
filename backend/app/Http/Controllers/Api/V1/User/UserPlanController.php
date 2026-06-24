<?php

namespace App\Http\Controllers\Api\V1\User;

use App\Services\PaymentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class UserPlanController
{
    /**
     * GET /api/v1/users/plan
     * Returns the current user's plan status.
     */
    public function __invoke(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json([
            'data' => [
                'plan'                 => $user->plan,
                'consultation_credits' => $user->consultation_credits,
                'plan_expires_at'      => $user->plan_expires_at?->toISOString(),
                'is_active'            => $user->hasPaidPlan(),
                'can_consult'          => $user->canConsult(),
                'plans'                => PaymentService::PLANS,
                'extra_credit_price'   => PaymentService::EXTRA_CREDIT_PRICE,
            ],
        ]);
    }
}
