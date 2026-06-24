<?php

namespace Tests\Feature\Api;

use App\Models\Category;
use App\Models\Expert;
use App\Models\User;
use App\Models\Wallet;
use App\Models\WalletTransaction;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class ExpertModuleTest extends TestCase
{
    // ─── Apply as Expert ──────────────────────────────────────────────────────

    public function test_user_can_apply_as_expert(): void
    {
        Storage::fake('s3');

        $user     = User::factory()->create(['email_verified_at' => now()]);
        $category = Category::factory()->create();

        // Documents array is required; each entry needs 'file' (UploadedFile) and 'type'
        $diploma = UploadedFile::fake()->create('diploma.pdf', 100, 'application/pdf');

        $response = $this->actingAs($user)->post('/api/v1/expert/apply', [
            'category_id' => $category->id,
            'bio'         => 'Médecin généraliste avec 10 ans d\'expérience.',
            'city'        => 'Casablanca',
            'documents'   => [
                ['file' => $diploma, 'type' => 'diploma'],
            ],
        ]);

        $response->assertStatus(201);
        $this->assertDatabaseHas('experts', ['user_id' => $user->id, 'status' => 'pending']);
    }

    public function test_apply_requires_category_id(): void
    {
        $user = User::factory()->create(['email_verified_at' => now()]);

        $response = $this->actingAs($user)->postJson('/api/v1/expert/apply', [
            'bio' => 'Some bio',
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors(['category_id']);
    }

    public function test_user_cannot_apply_twice(): void
    {
        Storage::fake('s3');

        $user     = User::factory()->create(['email_verified_at' => now(), 'role' => 'expert']);
        $category = Category::factory()->create();
        Expert::factory()->create(['user_id' => $user->id, 'status' => 'pending']);

        $response = $this->actingAs($user)->postJson('/api/v1/expert/apply', [
            'category_id' => $category->id,
            'bio'         => 'Already applied.',
        ]);

        $response->assertStatus(422);
    }

    // ─── Expert Profile Update ────────────────────────────────────────────────

    public function test_expert_can_update_their_profile(): void
    {
        $expert = Expert::factory()->create();
        $user   = $expert->user;

        $response = $this->actingAs($user)->putJson('/api/v1/expert/profile', [
            'bio'  => 'Updated bio.',
            'city' => 'Rabat',
        ]);

        $response->assertStatus(200);
        $this->assertDatabaseHas('experts', ['id' => $expert->id, 'city' => 'Rabat']);
    }

    public function test_non_expert_cannot_update_expert_profile(): void
    {
        $user = User::factory()->create(['email_verified_at' => now()]);

        $response = $this->actingAs($user)->putJson('/api/v1/expert/profile', [
            'bio' => 'Not an expert.',
        ]);

        // Non-experts have no expert record → routes return 404 (not 403)
        $response->assertStatus(404);
    }

    // ─── Expert Availability ──────────────────────────────────────────────────

    public function test_expert_can_toggle_availability(): void
    {
        $expert = Expert::factory()->create(['is_available' => true]);
        $user   = $expert->user;

        $response = $this->actingAs($user)->putJson('/api/v1/expert/availability', [
            'is_available' => false,
        ]);

        $response->assertStatus(200);
        $this->assertDatabaseHas('experts', ['id' => $expert->id, 'is_available' => false]);
    }

    // ─── Expert Dashboard ─────────────────────────────────────────────────────

    public function test_expert_can_access_their_dashboard(): void
    {
        $expert = Expert::factory()->create();
        $user   = $expert->user;

        $response = $this->actingAs($user)->getJson('/api/v1/expert/dashboard');

        $response->assertStatus(200)
            ->assertJsonStructure(['data']);
    }

    public function test_non_expert_cannot_access_expert_dashboard(): void
    {
        $user = User::factory()->create(['email_verified_at' => now()]);

        $response = $this->actingAs($user)->getJson('/api/v1/expert/dashboard');

        // Non-expert has no expert record → 404
        $response->assertStatus(404);
    }

    // ─── Expert Wallet ────────────────────────────────────────────────────────

    public function test_expert_can_view_their_wallet(): void
    {
        $expert = Expert::factory()->create();
        Wallet::create(['expert_id' => $expert->id, 'balance' => 140.00, 'total_earned' => 140.00, 'total_withdrawn' => 0]);

        $response = $this->actingAs($expert->user)->getJson('/api/v1/expert/wallet');

        $response->assertStatus(200)
            ->assertJsonStructure(['data' => ['balance', 'total_earned']]);
    }

    public function test_expert_can_view_wallet_transactions(): void
    {
        $expert = Expert::factory()->create();
        $wallet = Wallet::create(['expert_id' => $expert->id, 'balance' => 0, 'total_earned' => 70, 'total_withdrawn' => 0]);
        WalletTransaction::create(['wallet_id' => $wallet->id, 'type' => 'credit', 'amount' => 70, 'description' => 'Consultation #1']);

        $response = $this->actingAs($expert->user)->getJson('/api/v1/expert/wallet/transactions');

        $response->assertStatus(200)
            ->assertJsonStructure(['data', 'meta']);
    }

    public function test_guest_cannot_access_expert_wallet(): void
    {
        $response = $this->getJson('/api/v1/expert/wallet');

        $response->assertStatus(401);
    }
}
