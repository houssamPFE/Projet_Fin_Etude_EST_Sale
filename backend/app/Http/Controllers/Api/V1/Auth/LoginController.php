<?php

namespace App\Http\Controllers\Api\V1\Auth;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Auth\LoginRequest;
use App\Http\Resources\UserResource;
use App\Models\SystemSetting;
use App\Models\User;
use App\Services\AuthService;
use App\Services\TwoFactorService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Crypt;

class LoginController extends Controller
{
    public function __construct(
        private AuthService $authService,
        private TwoFactorService $twoFactorService,
    ) {}

    public function __invoke(LoginRequest $request): JsonResponse
    {
        $user = User::where('email', $request->email)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return response()->json(['message' => 'Identifiants incorrects.'], 401);
        }

        if (! $user->is_active) {
            return response()->json(['message' => 'Compte désactivé. Contactez le support.'], 403);
        }

        // Block non-admins from logging in during maintenance.
        if ($user->role->value !== 'admin') {
            $inMaintenance = Cache::remember('sys:maintenance_mode', 60, function () {
                return SystemSetting::get('maintenance_mode', false);
            });

            if ($inMaintenance) {
                return response()->json([
                    'message'     => 'La plateforme est en cours de maintenance. Veuillez réessayer dans quelques instants.',
                    'maintenance' => true,
                ], 503);
            }
        }

        if (! $user->email_verified_at) {
            return response()->json([
                'message' => 'Email non vérifié. Consultez votre boîte mail.',
                'requires_verification' => true,
            ], 403);
        }

        // 2FA Checks
        $globalRequireAll = SystemSetting::get('require_2fa') === 'true' || SystemSetting::get('require_2fa') === true;
        $globalRequireDoctor = (SystemSetting::get('require_doctor_2fa') === 'true' || SystemSetting::get('require_doctor_2fa') === true) && $user->role->value === 'expert';
        $userRequire = $user->require_2fa;

        $requires2Fa = $globalRequireAll || $globalRequireDoctor || $userRequire;

        // If they already have it enabled
        if ($this->twoFactorService->isEnabled($user)) {
            $twoFactorToken = $this->authService->createTwoFactorToken($user);

            return response()->json([
                'message'          => 'Vérification 2FA requise.',
                'requires_2fa'     => true,
                'two_factor_token' => $twoFactorToken,
            ]);
        }

        // If they MUST set it up, but it's not enabled
        if ($requires2Fa) {
            if (!$user->two_factor_secret) {
                $setupData = $this->twoFactorService->enable($user);
            } else {
                $setupData = [
                    'secret' => Crypt::decryptString($user->two_factor_secret),
                    'qr_code_url' => $this->twoFactorService->getQrCodeUrl(
                        $user,
                        Crypt::decryptString($user->two_factor_secret)
                    ),
                ];
            }
            
            // Revert back because TwoFactorService has getQrCodeUrl as private. Wait, I'll update getQrCodeUrl to public or just duplicate logic.
            // Actually, getQrCodeUrl is private in TwoFactorService. Let's make it public in TwoFactorService or just use google2fa directly.
            // To be safe, I'll update TwoFactorService to make it public.
            
            $twoFactorToken = $this->authService->createTwoFactorToken($user);

            return response()->json([
                'message' => 'Configuration 2FA requise.',
                'requires_2fa_setup' => true,
                'two_factor_token' => $twoFactorToken,
                'setup_data' => $setupData,
            ]);
        }

        $user->update([
            'last_activity_at'   => now(),
            'last_activity_type' => 'Connexion',
        ]);

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
