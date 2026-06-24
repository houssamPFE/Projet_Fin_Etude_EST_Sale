<?php

namespace App\Http\Controllers\Api\V1\Expert;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Expert\ApplyExpertRequest;
use App\Http\Resources\ExpertResource;
use App\Models\Expert;
use App\Services\ExpertService;
use Illuminate\Http\JsonResponse;

class ApplyController extends Controller
{
    public function __construct(private ExpertService $expertService) {}

    /**
     * Submit an expert application with documents.
     *
     * POST /api/v1/expert/apply
     */
    public function __invoke(ApplyExpertRequest $request): JsonResponse
    {
        $user = $request->user();

        // Check if user already has an expert profile
        if ($user->expert) {
            return response()->json([
                'message' => 'Vous avez déjà soumis une candidature expert.',
            ], 422);
        }

        $documents = collect($request->validated('documents'))->map(fn ($doc) => [
            'file' => $doc['file'],
            'type' => $doc['type'],
        ])->toArray();

        $expert = $this->expertService->apply(
            $user,
            $request->only(['category_id', 'bio', 'certifications']),
            $documents
        );

        return response()->json([
            'message' => 'Candidature expert soumise avec succès. Elle sera examinée sous 48h.',
            'data'    => new ExpertResource($expert),
        ], 201);
    }
}
