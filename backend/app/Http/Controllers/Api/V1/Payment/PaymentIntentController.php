<?php

namespace App\Http\Controllers\Api\V1\Payment;

use App\Http\Controllers\Controller;
use App\Services\PaymentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PaymentIntentController extends Controller
{
    public function __construct(private PaymentService $paymentService) {}

    /**
     * Create a Stripe PaymentIntent for a subscription plan or extra credit.
     *
     * POST /api/v1/payments/stripe/intent
     * Body: { "type": "pro" | "premium" | "extra" }
     */
    public function __invoke(Request $request): JsonResponse
    {
        $request->validate([
            'type' => ['required', 'string', 'in:pro,premium,extra'],
        ]);

        $result = $this->paymentService->createSubscriptionIntent(
            $request->user(),
            $request->type,
        );

        return response()->json(['data' => $result]);
    }
}
