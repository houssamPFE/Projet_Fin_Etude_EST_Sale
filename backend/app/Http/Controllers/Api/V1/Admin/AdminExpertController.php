<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\ExpertResource;
use App\Models\Expert;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminExpertController extends Controller
{
    /**
     * GET /api/v1/admin/experts
     * List ALL experts with optional filters (status, search, category).
     */
    public function index(Request $request): JsonResponse
    {
        $experts = Expert::with(['user', 'category', 'documents'])
            ->when(
                $request->filled('status'),
                fn ($q) => $q->where('status', $request->status)
            )
            ->when(
                $request->boolean('exclude_pending'),
                fn ($q) => $q->where('status', '!=', 'pending')
            )
            ->when(
                $request->filled('search'),
                fn ($q) => $q->whereHas(
                    'user',
                    fn ($uq) => $uq
                        ->where('name',  'like', "%{$request->search}%")
                        ->orWhere('email', 'like', "%{$request->search}%")
                )
            )
            ->when(
                $request->filled('category_id'),
                fn ($q) => $q->where('category_id', $request->category_id)
            )
            ->orderByDesc('created_at')
            ->paginate($request->integer('per_page', 20));

        return response()->json([
            'data' => ExpertResource::collection($experts),
            'meta' => [
                'total'        => $experts->total(),
                'current_page' => $experts->currentPage(),
                'last_page'    => $experts->lastPage(),
                'per_page'     => $experts->perPage(),
            ],
            'stats' => [
                'pending'   => Expert::where('status', 'pending')->count(),
                'validated' => Expert::where('status', 'validated')->count(),
                'rejected'  => Expert::where('status', 'rejected')->count(),
            ],
        ]);
    }

    /**
     * PUT /api/v1/admin/experts/{expert}/toggle
     * Toggle a validated expert's is_available flag.
     */
    public function toggleAvailability(Request $request, Expert $expert): JsonResponse
    {
        if ($expert->status->value !== 'validated') {
            return response()->json([
                'message' => 'Seuls les experts validés peuvent être mis en disponibilité.',
            ], 422);
        }

        $expert->update(['is_available' => ! $expert->is_available]);

        return response()->json([
            'message' => $expert->is_available
                ? 'Médecin marqué comme disponible.'
                : 'Médecin marqué comme indisponible.',
            'data' => new ExpertResource($expert->fresh(['user', 'category'])),
        ]);
    }
}
