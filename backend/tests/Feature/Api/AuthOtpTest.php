<?php

namespace Tests\Feature\Api;

use App\Jobs\SendEmailJob;
use App\Models\OtpCode;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class AuthOtpTest extends TestCase
{
    // ─── OTP Email Verification ───────────────────────────────────────────────

    public function test_user_can_verify_email_with_valid_otp(): void
    {
        $user = User::factory()->unverified()->create();

        OtpCode::create([
            'user_id'    => $user->id,
            'code'       => '123456',
            'type'       => 'email_verification',
            'expires_at' => now()->addMinutes(10),
        ]);

        $response = $this->postJson('/api/v1/auth/verify-email', [
            'email' => $user->email,
            'code'  => '123456',
        ]);

        $response->assertStatus(200)
            ->assertJsonStructure(['data' => ['token' => ['access_token', 'refresh_token']]]);

        $this->assertNotNull($user->fresh()->email_verified_at);
    }

    public function test_email_verification_fails_with_wrong_code(): void
    {
        $user = User::factory()->unverified()->create();

        OtpCode::create([
            'user_id'    => $user->id,
            'code'       => '123456',
            'type'       => 'email_verification',
            'expires_at' => now()->addMinutes(10),
        ]);

        $response = $this->postJson('/api/v1/auth/verify-email', [
            'email' => $user->email,
            'code'  => '000000',
        ]);

        $response->assertStatus(422);
    }

    public function test_email_verification_fails_with_expired_otp(): void
    {
        $user = User::factory()->unverified()->create();

        OtpCode::create([
            'user_id'    => $user->id,
            'code'       => '123456',
            'type'       => 'email_verification',
            'expires_at' => now()->subMinute(),
        ]);

        $response = $this->postJson('/api/v1/auth/verify-email', [
            'email' => $user->email,
            'code'  => '123456',
        ]);

        $response->assertStatus(422);
    }

    // ─── Resend OTP ───────────────────────────────────────────────────────────

    public function test_user_can_resend_otp(): void
    {
        Queue::fake();

        $user = User::factory()->unverified()->create();

        $response = $this->postJson('/api/v1/auth/resend-otp', [
            'email' => $user->email,
            'type'  => 'email_verification',
        ]);

        $response->assertStatus(200);
        Queue::assertPushed(SendEmailJob::class);
    }

    public function test_resend_otp_for_already_verified_user_succeeds(): void
    {
        Queue::fake();

        $user = User::factory()->create(['email_verified_at' => now()]);

        // The API does not block already-verified users from resending — returns 200
        $response = $this->postJson('/api/v1/auth/resend-otp', [
            'email' => $user->email,
            'type'  => 'email_verification',
        ]);

        $response->assertStatus(200);
    }

    // ─── Forgot Password ──────────────────────────────────────────────────────

    public function test_user_can_request_password_reset(): void
    {
        Queue::fake();

        $user = User::factory()->create(['email_verified_at' => now()]);

        $response = $this->postJson('/api/v1/auth/forgot-password', [
            'email' => $user->email,
        ]);

        $response->assertStatus(200);
        Queue::assertPushed(SendEmailJob::class);
        $this->assertDatabaseHas('otp_codes', [
            'user_id' => $user->id,
            'type'    => 'password_reset',
        ]);
    }

    public function test_forgot_password_rejects_unknown_email(): void
    {
        // The API validates that the email exists in the DB — returns 422
        $response = $this->postJson('/api/v1/auth/forgot-password', [
            'email' => 'nobody@example.com',
        ]);

        $response->assertStatus(422);
    }

    // ─── Reset Password ───────────────────────────────────────────────────────

    public function test_user_can_reset_password_with_valid_otp(): void
    {
        $user = User::factory()->create(['email_verified_at' => now()]);

        OtpCode::create([
            'user_id'    => $user->id,
            'code'       => '654321',
            'type'       => 'password_reset',
            'expires_at' => now()->addMinutes(10),
        ]);

        $response = $this->postJson('/api/v1/auth/reset-password', [
            'email'                 => $user->email,
            'code'                  => '654321',
            'password'              => 'NewPassword123!',
            'password_confirmation' => 'NewPassword123!',
        ]);

        $response->assertStatus(200);
        $this->assertTrue(Hash::check('NewPassword123!', $user->fresh()->password));
    }

    public function test_reset_password_fails_with_expired_otp(): void
    {
        $user = User::factory()->create(['email_verified_at' => now()]);

        OtpCode::create([
            'user_id'    => $user->id,
            'code'       => '654321',
            'type'       => 'password_reset',
            'expires_at' => now()->subMinute(),
        ]);

        $response = $this->postJson('/api/v1/auth/reset-password', [
            'email'                 => $user->email,
            'code'                  => '654321',
            'password'              => 'NewPassword123!',
            'password_confirmation' => 'NewPassword123!',
        ]);

        $response->assertStatus(422);
    }

    // ─── Refresh Token ────────────────────────────────────────────────────────

    public function test_user_can_refresh_access_token(): void
    {
        $user = User::factory()->create(['email_verified_at' => now()]);

        // Login to get a real refresh token
        $loginResponse = $this->postJson('/api/v1/auth/login', [
            'email'    => $user->email,
            'password' => 'password',
        ]);

        $refreshToken = $loginResponse->json('data.token.refresh_token');

        $response = $this->postJson('/api/v1/auth/refresh', [
            'refresh_token' => $refreshToken,
        ]);

        $response->assertStatus(200)
            ->assertJsonStructure(['data' => ['token' => ['access_token']]]);
    }

    public function test_refresh_fails_with_invalid_token(): void
    {
        $response = $this->postJson('/api/v1/auth/refresh', [
            'refresh_token' => 'invalid-token',
        ]);

        $response->assertStatus(401);
    }

    // ─── Logout ───────────────────────────────────────────────────────────────

    public function test_authenticated_user_can_logout(): void
    {
        $user = User::factory()->create(['email_verified_at' => now()]);

        $response = $this->actingAs($user)->postJson('/api/v1/auth/logout');

        $response->assertStatus(200);
    }

    public function test_guest_cannot_logout(): void
    {
        $response = $this->postJson('/api/v1/auth/logout');

        $response->assertStatus(401);
    }
}
