<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\ExpertResource;
use App\Models\Expert;
use App\Services\ExpertService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminExpertValidateController extends Controller
{
    public function __construct(private ExpertService $expertService) {}

    /**
     * Validate (approve) an expert application.
     *
     * PUT /api/v1/admin/experts/{expert}/validate
     */
    public function __invoke(Request $request, Expert $expert): JsonResponse
    {
        if ($expert->status->value === 'validated') {
            return response()->json([
                'message' => 'Cet expert est déjà validé.',
            ], 422);
        }

        $expert = $this->expertService->validate($expert, $request->user());

        return response()->json([
            'message' => 'Expert validé avec succès.',
            'data'    => new ExpertResource($expert),
        ]);
    }
}
