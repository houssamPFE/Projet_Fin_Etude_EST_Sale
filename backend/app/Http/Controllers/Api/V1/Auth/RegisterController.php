<?php

namespace App\Http\Controllers\Api\V1\Auth;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Auth\RegisterRequest;
use App\Http\Resources\UserResource;
use App\Models\SystemSetting;
use App\Services\AuthService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Cache;

class RegisterController extends Controller
{
    public function __construct(private AuthService $authService) {}

    public function __invoke(RegisterRequest $request): JsonResponse
    {
        $allowed = Cache::remember('sys:allow_registrations', 60, fn () =>
            SystemSetting::get('allow_registrations', true)
        );

        if (! $allowed) {
            return response()->json([
                'message' => 'Les inscriptions sont temporairement désactivées.',
            ], 403);
        }

        $user = $this->authService->register($request->validated());

        return response()->json([
            'message' => 'Compte créé. Vérifiez votre email pour confirmer votre inscription.',
            'data'    => new UserResource($user),
        ], 201);
    }
}
