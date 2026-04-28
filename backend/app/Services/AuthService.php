<?php

namespace App\Services;

use App\Enums\OtpType;
use App\Jobs\SendEmailJob;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Laravel\Socialite\Contracts\User as SocialiteUser;

class AuthService
{
    public function __construct(private OtpService $otpService) {}

    /**
     * Register a new user with email/password and send OTP verification.
     */
    public function register(array $data): User
    {
        $user = User::create([
            'name'      => $data['name'],
            'email'     => $data['email'],
            'password'  => $data['password'],
            'language'  => $data['language'] ?? 'fr',
            'role'      => 'user',
            'is_active' => true,
        ]);

        $otp = $this->otpService->generate($user, OtpType::EmailVerification);

        SendEmailJob::dispatch('otp', $user, ['otp' => $otp->code, 'type' => 'verification']);

        return $user;
    }

    /**
     * Create a Sanctum access + refresh token pair.
     */
    public function createTokenPair(User $user): array
    {
        // Revoke all existing tokens on fresh login
        $user->tokens()->delete();

        $expirationMinutes = (int)(config('sanctum.expiration') ?? 15);

        $accessToken = $user->createToken(
            'access_token',
            ['*'],
            now()->addMinutes($expirationMinutes)
        );

        $refreshToken = $user->createToken(
            'refresh_token',
            ['refresh'],
            now()->addDays(30)
        );

        return [
            'access_token'  => $accessToken->plainTextToken,
            'refresh_token' => $refreshToken->plainTextToken,
            'token_type'    => 'Bearer',
            'expires_in'    => config('sanctum.expiration', 15) * 60,
        ];
    }

    /**
     * Send a password reset OTP to the user.
     */
    public function sendPasswordResetOtp(User $user): void
    {
        $otp = $this->otpService->generate($user, OtpType::PasswordReset);
        SendEmailJob::dispatch('otp', $user, ['otp' => $otp->code, 'type' => 'password_reset']);
    }

    /**
     * Reset the user's password and revoke all tokens.
     */
    public function resetPassword(User $user, string $password): void
    {
        $user->update(['password' => Hash::make($password)]);
        $user->tokens()->delete();
    }

    /**
     * Handle OAuth social login (Google or Facebook).
     * Finds existing user by provider ID or email, or creates a new one.
     * Returns token pair + user.
     *
     * @return array{user: User, tokens: array}
     */
    public function handleSocialLogin(string $provider, SocialiteUser $socialUser): array
    {
        $providerIdColumn = $provider . '_id';

        // 1. Try finding by provider ID
        $user = User::where($providerIdColumn, $socialUser->getId())->first();

        // 2. Try finding by email and link the provider
        if (! $user && $socialUser->getEmail()) {
            $user = User::where('email', $socialUser->getEmail())->first();

            if ($user) {
                $user->update([$providerIdColumn => $socialUser->getId()]);
            }
        }

        // 3. Create a new user
        if (! $user) {
            $user = User::create([
                'name'              => $socialUser->getName() ?? $socialUser->getNickname() ?? 'Utilisateur',
                'email'             => $socialUser->getEmail(),
                $providerIdColumn   => $socialUser->getId(),
                'avatar_url'        => $socialUser->getAvatar(),
                'password'          => Hash::make(Str::random(32)),
                'email_verified_at' => now(), // OAuth emails are pre-verified
                'language'          => 'fr',
                'is_active'         => true,
            ]);
        }

        // Auto-verify email for OAuth users if not already verified
        if (! $user->email_verified_at) {
            $user->update(['email_verified_at' => now()]);
        }

        if (! $user->is_active) {
            abort(403, 'Compte désactivé. Contactez le support.');
        }

        $tokens = $this->createTokenPair($user);

        return [
            'user'   => $user,
            'tokens' => $tokens,
        ];
    }

    /**
     * Create a short-lived Sanctum token for 2FA verification.
     * This token can ONLY be used at the /2fa/verify endpoint.
     */
    public function createTwoFactorToken(User $user): string
    {
        $token = $user->createToken(
            '2fa_token',
            ['2fa'],
            now()->addMinutes(5)
        );

        return $token->plainTextToken;
    }
}
