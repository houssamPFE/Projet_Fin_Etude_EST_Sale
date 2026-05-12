<?php

namespace App\Http\Controllers\Api\V1\Auth;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Auth\TwoFactorVerifyRequest;
use App\Http\Resources\UserResource;
use App\Services\AuthService;
use App\Services\TwoFactorService;
use Illuminate\Http\JsonResponse;
use Laravel\Sanctum\PersonalAccessToken;

class TwoFactorVerifyController extends Controller
{
    public function __construct(
        private AuthService $authService,
        private TwoFactorService $twoFactorService,
    ) {}

    /**
     * Verify a TOTP code during login. Exchanges the short-lived 2FA token
     * for a full access + refresh token pair.
     *
     * POST /api/v1/auth/2fa/verify
     */
    public function __invoke(TwoFactorVerifyRequest $request): JsonResponse
    {
        $twoFactorTokenValue = $request->validated('two_factor_token');
        $code                = $request->validated('code');

        // Find and validate the 2FA token
        $accessToken = PersonalAccessToken::findToken($twoFactorTokenValue);

        if (! $accessToken || ! $accessToken->can('2fa')) {
            return response()->json([
                'message' => 'Token 2FA invalide ou expiré.',
            ], 401);
        }

        // Check expiry
        if ($accessToken->expires_at && $accessToken->expires_at->isPast()) {
            $accessToken->delete();
            return response()->json([
                'message' => 'Token 2FA expiré. Veuillez vous reconnecter.',
            ], 401);
        }

        $user = $accessToken->tokenable;

        // Verify the TOTP code
        if (! $this->twoFactorService->verify($user, $code)) {
            return response()->json([
                'message' => 'Code 2FA invalide.',
            ], 422);
        }

        // If this is their first time verifying, confirm the setup!
        if (! $user->two_factor_confirmed_at) {
            $user->update(['two_factor_confirmed_at' => now()]);
        }

        // Revoke the 2FA token and issue full tokens
        $accessToken->delete();
        $tokens = $this->authService->createTokenPair($user);

        return response()->json([
            'message' => 'Connexion réussie.',
            'data'    => [
                'user'  => new UserResource($user),
                'token' => $tokens,
            ],
        ])->withCookie(
            cookie(
                name: 'refresh_token',
                value: $tokens['refresh_token'],
                minutes: 60 * 24 * 30,
                secure: app()->isProduction(),
                httpOnly: true,
                sameSite: 'Strict'
            )
        );
    }
}
