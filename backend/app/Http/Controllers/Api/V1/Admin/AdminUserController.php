<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\User;
use App\Services\TwoFactorService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class AdminUserController extends Controller
{
    /**
     * GET /api/v1/admin/users
     */
    public function index(Request $request): JsonResponse
    {
        $users = User::query()
            ->when($request->search, fn($q) => $q->where('name', 'like', "%{$request->search}%")
                ->orWhere('email', 'like', "%{$request->search}%"))
            ->when($request->role, fn($q) => $q->where('role', $request->role))
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return response()->json([
            'data' => UserResource::collection($users),
            'meta' => [
                'total' => $users->total(),
                'current_page' => $users->currentPage(),
                'last_page' => $users->lastPage(),
            ],
        ]);
    }

    /**
     * PUT /api/v1/admin/users/{user}
     * Edit user profile fields (name, email, role, language).
     */
    public function update(Request $request, User $user): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:150'],
            'email' => ['sometimes', 'email', 'max:180', Rule::unique('users')->ignore($user->id)],
            'phone' => ['sometimes', 'nullable', 'max:20', Rule::unique('users')->ignore($user->id)],
            'role' => ['sometimes', 'in:user,expert,admin'],
            'language' => ['sometimes', 'in:fr,ar'],
        ]);

        if (isset($validated['role']) && $user->id === $request->user()->id) {
            return response()->json(['message' => 'Impossible de changer votre propre rôle.'], 422);
        }

        $user->update($validated);

        if (isset($validated['role']) && $user->expert) {
            if ($validated['role'] === 'expert') {
                $user->expert->update(['status' => \App\Enums\ExpertStatus::Validated]);
            } else {
                $user->expert->update(['status' => \App\Enums\ExpertStatus::Rejected]);
            }
        }

        return response()->json([
            'message' => 'Utilisateur mis à jour.',
            'data' => new UserResource($user->fresh()),
        ]);
    }

    /**
     * PUT /api/v1/admin/users/{user}/toggle
     * Toggle active status.
     */
    public function toggle(Request $request, User $user): JsonResponse
    {
        if ($user->id === $request->user()->id) {
            return response()->json(['message' => 'Impossible de désactiver votre propre compte.'], 422);
        }

        $user->update(['is_active' => !$user->is_active]);

        return response()->json([
            'message' => $user->is_active ? 'Compte activé.' : 'Compte désactivé.',
            'data' => new UserResource($user),
        ]);
    }

    /**
     * PUT /api/v1/admin/users/{user}/security
     * Update user 2FA requirement or reset 2FA.
     */
    public function updateSecurity(Request $request, User $user, TwoFactorService $twoFactorService): JsonResponse
    {
        $validated = $request->validate([
            'require_2fa' => ['sometimes', 'boolean'],
            'reset_2fa' => ['sometimes', 'boolean'],
        ]);

        if (isset($validated['require_2fa'])) {
            $user->update(['require_2fa' => $validated['require_2fa']]);
        }

        if (!empty($validated['reset_2fa'])) {
            $twoFactorService->disable($user);
        }

        return response()->json([
            'message' => 'Paramètres de sécurité mis à jour.',
            'data' => new UserResource($user->fresh()),
        ]);
    }
}
