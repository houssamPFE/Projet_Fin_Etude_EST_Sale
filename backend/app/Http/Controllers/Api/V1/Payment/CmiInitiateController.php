<?php

namespace App\Http\Controllers\Api\V1\Payment;

use App\Http\Controllers\Controller;
use App\Services\PaymentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CmiInitiateController extends Controller
{
    public function __construct(private PaymentService $paymentService) {}

    /**
     * Initiate a CMI payment for a subscription plan or extra credit.
     *
     * POST /api/v1/payments/cmi/initiate
     * Body: { "type": "pro" | "premium" | "extra" }
     */
    public function __invoke(Request $request): JsonResponse
    {
        $request->validate([
            'type' => ['required', 'string', 'in:pro,premium,extra'],
        ]);

        $result = $this->paymentService->initiateCmiSubscription(
            $request->user(),
            $request->type,
        );

        return response()->json(['data' => $result]);
    }
}
