<?php

namespace App\Services;

use App\Models\User;
use PragmaRX\Google2FA\Google2FA;
use Illuminate\Support\Facades\Crypt;

class TwoFactorService
{
    private Google2FA $google2fa;

    public function __construct()
    {
        $this->google2fa = new Google2FA();
    }

    /**
     * Generate a new TOTP secret and QR code URL for the user.
     * The secret is stored encrypted but NOT yet confirmed.
     *
     * @return array{secret: string, qr_code_url: string}
     */
    public function enable(User $user): array
    {
        $secret = $this->google2fa->generateSecretKey();

        $user->update([
            'two_factor_secret'       => Crypt::encryptString($secret),
            'two_factor_confirmed_at' => null,
        ]);

        $qrCodeUrl = $this->getQrCodeUrl($user, $secret);

        return [
            'secret'       => $secret,
            'qr_code_url'  => $qrCodeUrl,
        ];
    }

    /**
     * Confirm 2FA setup by verifying the TOTP code.
     */
    public function confirm(User $user, string $code): bool
    {
        if (! $this->verify($user, $code)) {
            return false;
        }

        $user->update(['two_factor_confirmed_at' => now()]);

        return true;
    }

    /**
     * Disable 2FA for the user.
     */
    public function disable(User $user): void
    {
        $user->update([
            'two_factor_secret'       => null,
            'two_factor_confirmed_at' => null,
        ]);
    }

    /**
     * Verify a TOTP code against the user's stored secret.
     */
    public function verify(User $user, string $code): bool
    {
        if (! $user->two_factor_secret) {
            return false;
        }

        $secret = Crypt::decryptString($user->two_factor_secret);

        return $this->google2fa->verifyKey($secret, $code);
    }

    /**
     * Check if a user has 2FA fully enabled (secret + confirmed).
     */
    public function isEnabled(User $user): bool
    {
        return $user->two_factor_secret !== null
            && $user->two_factor_confirmed_at !== null;
    }

    /**
     * Generate an otpauth:// URL for QR code scanning.
     */
    public function getQrCodeUrl(User $user, string $secret): string
    {
        return $this->google2fa->getQRCodeUrl(
            config('app.name', 'Nexora'),
            $user->email,
            $secret
        );
    }
}
