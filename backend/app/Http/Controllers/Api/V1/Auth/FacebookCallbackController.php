<?php

namespace App\Http\Controllers\Api\V1\Auth;

use App\Http\Controllers\Controller;
use App\Services\AuthService;
use App\Services\TwoFactorService;
use Illuminate\Http\RedirectResponse;
use Laravel\Socialite\Facades\Socialite;

class FacebookCallbackController extends Controller
{
    public function __construct(
        private AuthService $authService,
        private TwoFactorService $twoFactorService,
    ) {}

    /**
     * Handle the Facebook OAuth callback and redirect back to the SPA.
     *
     * GET /api/v1/auth/facebook/callback
     */
    public function __invoke(): RedirectResponse
    {
        try {
            $socialUser = Socialite::driver('facebook')->stateless()->user();
        } catch (\Throwable) {
            return $this->redirectToFrontend([
                'error' => 'Erreur d\'authentification Facebook.',
            ]);
        }

        $result = $this->authService->handleSocialLogin('facebook', $socialUser);

        if ($this->twoFactorService->isEnabled($result['user'])) {
            $twoFactorToken = $this->authService->createTwoFactorToken($result['user']);
            $result['user']->tokens()->where('name', '!=', '2fa_token')->delete();

            return $this->redirectToFrontend([
                'requires_2fa'     => '1',
                'two_factor_token' => $twoFactorToken,
            ]);
        }

        return $this->redirectToFrontend([
            'access_token'  => $result['tokens']['access_token'],
            'refresh_token' => $result['tokens']['refresh_token'],
            'provider'      => 'facebook',
        ])->withCookie(
            cookie(
                name: 'refresh_token',
                value: $result['tokens']['refresh_token'],
                minutes: 60 * 24 * 30,
                secure: app()->isProduction(),
                httpOnly: true,
                sameSite: 'Strict'
            )
        );
    }

    private function redirectToFrontend(array $payload): RedirectResponse
    {
        $base = rtrim(config('app.frontend_url'), '/').'/auth/social/callback';
        $fragment = http_build_query($payload);

        return redirect()->away($base.($fragment ? '#'.$fragment : ''));
    }
}
