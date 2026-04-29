<?php

namespace App\Http\Controllers\Api\V1\Auth;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Services\AuthService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Laravel\Sanctum\PersonalAccessToken;

class RefreshTokenController extends Controller
{
    public function __construct(private AuthService $authService) {}

    public function __invoke(Request $request): JsonResponse
    {
        $rawToken = $request->cookie('refresh_token') ?: $request->input('refresh_token');

        if (! $rawToken) {
            return response()->json(['message' => 'Refresh token manquant.'], 401);
        }

        $token = PersonalAccessToken::findToken($rawToken);

        if (! $token || ! $token->can('refresh') || ($token->expires_at && $token->expires_at->isPast())) {
            return response()->json(['message' => 'Refresh token invalide ou expiré.'], 401);
        }

        $user = $token->tokenable;

        if (! $user->is_active) {
            return response()->json(['message' => 'Compte désactivé.'], 403);
        }

        $token->delete();

        $tokens = $this->authService->createTokenPair($user);

        return response()->json([
            'message' => 'Token renouvelé.',
            'data'    => [
                'user'  => new UserResource($user),
                'token' => $tokens,
            ],
        ])->withCookie(
            cookie('refresh_token', $tokens['refresh_token'], 60 * 24 * 30,
                secure: app()->isProduction(), httpOnly: true, sameSite: 'Strict')
        );
    }
}
