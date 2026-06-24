<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\User;
use App\Services\PaymentService;
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
        $allowed = ['name', 'email', 'created_at', 'role', 'last_activity_at'];
        $sortBy  = in_array($request->sort_by, $allowed) ? $request->sort_by : 'created_at';
        $sortDir = $request->sort_dir === 'asc' ? 'asc' : 'desc';

        $users = User::query()
            ->when($request->search, fn($q) => $q->where(fn($q2) => $q2
                ->where('name', 'like', "%{$request->search}%")
                ->orWhere('email', 'like', "%{$request->search}%")))
            ->when($request->role, fn($q) => $q->where('role', $request->role))
            ->when($request->plan, fn($q) => $q->where('plan', $request->plan))
            ->when($request->status !== null && $request->status !== '', function ($q) use ($request) {
                match ($request->status) {
                    'active'    => $q->where('is_active', true)->whereNotNull('email_verified_at'),
                    'suspended' => $q->where('is_active', false),
                    'pending'   => $q->where('is_active', true)->whereNull('email_verified_at'),
                    default     => null,
                };
            })
            ->when($request->source, function ($q) use ($request) {
                match ($request->source) {
                    'google'   => $q->whereNotNull('google_id'),
                    'facebook' => $q->whereNotNull('facebook_id'),
                    'email'    => $q->whereNull('google_id')->whereNull('facebook_id'),
                    default    => null,
                };
            })
            ->orderBy($sortBy, $sortDir)
            ->paginate(20);

        return response()->json([
            'data' => UserResource::collection($users),
            'meta' => [
                'total'        => $users->total(),
                'current_page' => $users->currentPage(),
                'last_page'    => $users->lastPage(),
            ],
        ]);
    }

    /**
     * GET /api/v1/admin/users/stats
     */
    public function stats(): JsonResponse
    {
        $total     = User::count();
        $active    = User::where('is_active', true)->whereNotNull('email_verified_at')->count();
        $suspended = User::where('is_active', false)->count();
        $pending   = User::where('is_active', true)->whereNull('email_verified_at')->count();

        $plans = [
            'free'    => User::where('plan', 'free')->count(),
            'pro'     => User::where('plan', 'pro')->count(),
            'premium' => User::where('plan', 'premium')->count(),
        ];

        return response()->json([
            'data' => compact('total', 'active', 'suspended', 'pending', 'plans'),
        ]);
    }

    /**
     * PUT /api/v1/admin/users/{user}/plan
     * Admin manually sets a user's plan, credits, and expiry.
     */
    public function changePlan(Request $request, User $user): JsonResponse
    {
        $validated = $request->validate([
            'plan'                 => ['required', 'in:free,pro,premium'],
            'consultation_credits' => ['required', 'integer', 'min:0', 'max:100'],
            'plan_expires_at'      => ['nullable', 'date'],
        ]);

        $user->update([
            'plan'                 => $validated['plan'],
            'consultation_credits' => $validated['consultation_credits'],
            'plan_expires_at'      => $validated['plan'] === 'free' ? null : ($validated['plan_expires_at'] ?? now()->addDays(30)),
        ]);

        \Illuminate\Support\Facades\Log::info('[Admin] Plan changed manually', [
            'admin_id' => $request->user()->id,
            'user_id'  => $user->id,
            'plan'     => $validated['plan'],
            'credits'  => $validated['consultation_credits'],
        ]);

        return response()->json([
            'message' => "Plan mis à jour : {$validated['plan']} ({$validated['consultation_credits']} crédit(s)).",
            'data'    => new UserResource($user->fresh()),
        ]);
    }

    /**
     * PUT /api/v1/admin/users/{user}
     */
    public function update(Request $request, User $user): JsonResponse
    {
        $validated = $request->validate([
            'name'     => ['sometimes', 'string', 'max:150'],
            'email'    => ['sometimes', 'email', 'max:180', Rule::unique('users')->ignore($user->id)],
            'phone'    => ['sometimes', 'nullable', 'max:20', Rule::unique('users')->ignore($user->id)],
            'role'     => ['sometimes', 'in:user,expert,admin'],
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
            'data'    => new UserResource($user->fresh()),
        ]);
    }

    /**
     * PUT /api/v1/admin/users/{user}/toggle
     */
    public function toggle(Request $request, User $user): JsonResponse
    {
        if ($user->id === $request->user()->id) {
            return response()->json(['message' => 'Impossible de désactiver votre propre compte.'], 422);
        }

        $user->update(['is_active' => !$user->is_active]);

        return response()->json([
            'message' => $user->is_active ? 'Compte activé.' : 'Compte suspendu.',
            'data'    => new UserResource($user),
        ]);
    }

    /**
     * PUT /api/v1/admin/users/bulk-suspend
     */
    public function bulkSuspend(Request $request): JsonResponse
    {
        $request->validate([
            'ids'   => ['required', 'array', 'min:1'],
            'ids.*' => ['integer', 'exists:users,id'],
        ]);

        $adminId = $request->user()->id;

        $count = User::whereIn('id', $request->ids)
            ->where('id', '!=', $adminId)
            ->where('is_active', true)
            ->update(['is_active' => false]);

        return response()->json([
            'message' => "{$count} utilisateur(s) suspendu(s).",
        ]);
    }

    /**
     * PUT /api/v1/admin/users/{user}/security
     */
    public function updateSecurity(Request $request, User $user, TwoFactorService $twoFactorService): JsonResponse
    {
        $validated = $request->validate([
            'require_2fa' => ['sometimes', 'boolean'],
            'reset_2fa'   => ['sometimes', 'boolean'],
        ]);

        if (isset($validated['require_2fa'])) {
            $user->update(['require_2fa' => $validated['require_2fa']]);
        }

        if (!empty($validated['reset_2fa'])) {
            $twoFactorService->disable($user);
        }

        return response()->json([
            'message' => 'Paramètres de sécurité mis à jour.',
            'data'    => new UserResource($user->fresh()),
        ]);
    }
}
