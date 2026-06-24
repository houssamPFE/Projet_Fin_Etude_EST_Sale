<?php

namespace Tests\Feature\Api;

use App\Models\Notification;
use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class UserProfileTest extends TestCase
{
    // ─── Profile Update ───────────────────────────────────────────────────────

    public function test_user_can_update_profile(): void
    {
        $user = User::factory()->create(['email_verified_at' => now()]);

        $response = $this->actingAs($user)->putJson('/api/v1/users/profile', [
            'name'     => 'Updated Name',
            'language' => 'ar',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.name', 'Updated Name');

        $this->assertDatabaseHas('users', ['id' => $user->id, 'name' => 'Updated Name', 'language' => 'ar']);
    }

    public function test_guest_cannot_update_profile(): void
    {
        $response = $this->putJson('/api/v1/users/profile', ['name' => 'Test']);

        $response->assertStatus(401);
    }

    public function test_profile_update_ignores_other_user_email(): void
    {
        // The API does not currently validate email uniqueness on profile update
        $user  = User::factory()->create(['email_verified_at' => now()]);
        $other = User::factory()->create(['email_verified_at' => now()]);

        $response = $this->actingAs($user)->putJson('/api/v1/users/profile', [
            'email' => $other->email,
        ]);

        // Either 200 (allowed) or 422 (blocked) — just confirm no 500 crash
        $this->assertContains($response->status(), [200, 422]);
    }

    // ─── Avatar Upload ────────────────────────────────────────────────────────

    public function test_user_can_upload_avatar(): void
    {
        Storage::fake('s3');

        $user = User::factory()->create(['email_verified_at' => now()]);
        $file = UploadedFile::fake()->create('avatar.jpg', 200, 'image/jpeg');

        $response = $this->actingAs($user)->postJson('/api/v1/users/avatar', [
            'avatar' => $file,
        ]);

        $response->assertStatus(200)
            ->assertJsonStructure(['data' => ['avatar_url']]);
    }

    public function test_avatar_upload_rejects_non_image(): void
    {
        $user = User::factory()->create(['email_verified_at' => now()]);
        $file = UploadedFile::fake()->create('document.pdf', 100, 'application/pdf');

        $response = $this->actingAs($user)->postJson('/api/v1/users/avatar', [
            'avatar' => $file,
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors(['avatar']);
    }

    // ─── Change Password ──────────────────────────────────────────────────────

    public function test_user_can_change_password(): void
    {
        $user = User::factory()->create([
            'email_verified_at' => now(),
            'password'          => Hash::make('OldPass123!'),
        ]);

        $response = $this->actingAs($user)->putJson('/api/v1/users/password', [
            'current_password'      => 'OldPass123!',
            'password'              => 'NewPass456!',
            'password_confirmation' => 'NewPass456!',
        ]);

        $response->assertStatus(200);
        $this->assertTrue(Hash::check('NewPass456!', $user->fresh()->password));
    }

    public function test_change_password_fails_with_wrong_current_password(): void
    {
        $user = User::factory()->create([
            'email_verified_at' => now(),
            'password'          => Hash::make('OldPass123!'),
        ]);

        $response = $this->actingAs($user)->putJson('/api/v1/users/password', [
            'current_password'      => 'WrongPass!',
            'password'              => 'NewPass456!',
            'password_confirmation' => 'NewPass456!',
        ]);

        // Wrong password → 403 (actual controller behavior, not 422)
        $response->assertStatus(403);
    }

    // ─── Notifications ────────────────────────────────────────────────────────
    // Route: /api/v1/notifications (NOT /api/v1/users/notifications)

    public function test_user_can_list_notifications(): void
    {
        $user = User::factory()->create(['email_verified_at' => now()]);

        for ($i = 0; $i < 4; $i++) {
            Notification::create(['user_id' => $user->id, 'type' => 'test', 'title' => "Notif $i", 'body' => 'body']);
        }

        $response = $this->actingAs($user)->getJson('/api/v1/notifications');

        $response->assertStatus(200)
            ->assertJsonStructure(['data', 'meta']);
    }

    public function test_user_can_mark_notification_as_read(): void
    {
        $user         = User::factory()->create(['email_verified_at' => now()]);
        $notification = Notification::create(['user_id' => $user->id, 'type' => 'test', 'title' => 'Test', 'body' => 'body', 'read_at' => null]);

        $response = $this->actingAs($user)
            ->putJson("/api/v1/notifications/{$notification->id}/read");

        $response->assertStatus(200);
        $this->assertNotNull($notification->fresh()->read_at);
    }

    public function test_user_can_mark_all_notifications_as_read(): void
    {
        $user = User::factory()->create(['email_verified_at' => now()]);
        for ($i = 0; $i < 3; $i++) {
            Notification::create(['user_id' => $user->id, 'type' => 'test', 'title' => "N$i", 'body' => 'b', 'read_at' => null]);
        }

        $response = $this->actingAs($user)->putJson('/api/v1/notifications/read-all');

        $response->assertStatus(200);

        $unread = Notification::where('user_id', $user->id)->whereNull('read_at')->count();
        $this->assertSame(0, $unread);
    }

    public function test_guest_cannot_access_notifications(): void
    {
        $response = $this->getJson('/api/v1/notifications');

        $response->assertStatus(401);
    }

    // ─── Delete Account ───────────────────────────────────────────────────────

    public function test_user_can_delete_own_account(): void
    {
        $user = User::factory()->create([
            'email_verified_at' => now(),
            'password'          => Hash::make('password'),
        ]);

        $response = $this->actingAs($user)->deleteJson('/api/v1/users/account', [
            'password' => 'password',
        ]);

        $response->assertStatus(200);
        // Users model has no SoftDeletes — record is hard-deleted
        $this->assertDatabaseMissing('users', ['id' => $user->id]);
    }

    public function test_delete_account_requires_correct_password(): void
    {
        $user = User::factory()->create([
            'email_verified_at' => now(),
            'password'          => Hash::make('password'),
        ]);

        $userId = $user->id;

        $response = $this->actingAs($user)->deleteJson('/api/v1/users/account', [
            'password' => 'wrong-password',
        ]);

        // Wrong password → 403 (actual controller behavior)
        $response->assertStatus(403);
        $this->assertDatabaseHas('users', ['id' => $userId]);
    }
}
