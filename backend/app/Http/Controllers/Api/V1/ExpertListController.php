<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\ExpertResource;
use App\Models\Expert;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ExpertListController extends Controller
{
    /**
     * List validated, publicly visible experts with optional filtering.
     *
     * GET /api/v1/experts
     */
    public function __invoke(Request $request): JsonResponse
    {
        $query = Expert::validated()
            ->with(['user', 'category'])
            ->withCount('reviews');

        // Filter by category id
        if ($request->filled('category_id')) {
            $query->where('category_id', $request->integer('category_id'));
        }

        // Filter by specialty slug (e.g. specialty=cardiologie)
        if ($request->filled('specialty')) {
            $query->whereHas('category', fn ($q) => $q->where('slug', $request->string('specialty')));
        }

        // Filter by availability
        if ($request->filled('available')) {
            $query->where('is_available', $request->boolean('available'));
        }

        // Search by name or bio
        if ($request->filled('search')) {
            $search = $request->string('search');
            $query->where(function ($q) use ($search) {
                $q->whereHas('user', fn ($u) => $u->where('name', 'ilike', "%{$search}%"))
                  ->orWhere('bio', 'ilike', "%{$search}%");
            });
        }

        // Sort
        $sortBy = $request->input('sort', 'rating');
        $query = match ($sortBy) {
            'rating'  => $query->orderByDesc('rating_avg'),
            'reviews' => $query->orderByDesc('total_reviews'),
            'newest'  => $query->orderByDesc('created_at'),
            default   => $query->orderByDesc('rating_avg'),
        };

        $experts = $query->paginate($request->integer('per_page', 15));

        return response()->json([
            'data' => ExpertResource::collection($experts),
            'meta' => [
                'current_page' => $experts->currentPage(),
                'last_page'    => $experts->lastPage(),
                'per_page'     => $experts->perPage(),
                'total'        => $experts->total(),
            ],
        ]);
    }
}
