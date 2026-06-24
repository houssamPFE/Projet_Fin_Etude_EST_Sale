<?php

namespace Tests\Feature\Api;

use App\Models\Category;
use App\Models\Conversation;
use App\Models\Expert;
use App\Models\User;
use Illuminate\Support\Facades\Event;
use Tests\TestCase;

class ConversationEscalateTest extends TestCase
{
    // ─── 402 Guard ────────────────────────────────────────────────────────────

    public function test_free_user_gets_402_when_escalating(): void
    {
        $user     = User::factory()->create(['email_verified_at' => now(), 'plan' => 'free', 'consultation_credits' => 0]);
        $category = Category::factory()->create();
        $conv     = Conversation::factory()->create(['user_id' => $user->id, 'category_id' => $category->id]);

        $response = $this->actingAs($user)->postJson("/api/v1/conversations/{$conv->id}/escalate");

        $response->assertStatus(402);
    }

    public function test_pro_user_with_no_credits_gets_402(): void
    {
        $user     = User::factory()->create([
            'email_verified_at' => now(),
            'plan' => 'pro',
            'plan_expires_at' => now()->addDays(30),
            'consultation_credits' => 0,
        ]);
        $category = Category::factory()->create();
        $conv     = Conversation::factory()->create(['user_id' => $user->id, 'category_id' => $category->id]);

        $response = $this->actingAs($user)->postJson("/api/v1/conversations/{$conv->id}/escalate");

        $response->assertStatus(402);
    }

    // ─── Successful Escalation ────────────────────────────────────────────────

    public function test_pro_user_with_credits_can_escalate(): void
    {
        Event::fake();

        $category = Category::factory()->create();
        $user     = User::factory()->create([
            'email_verified_at'    => now(),
            'plan'                 => 'pro',
            'plan_expires_at'      => now()->addDays(30),
            'consultation_credits' => 2,
        ]);
        Expert::factory()->create(['category_id' => $category->id, 'is_available' => true]);
        $conv = Conversation::factory()->create(['user_id' => $user->id, 'category_id' => $category->id]);

        $response = $this->actingAs($user)->postJson("/api/v1/conversations/{$conv->id}/escalate");

        // 200 if expert found, or 200 with same status if no specialist
        $response->assertStatus(200);

        // Credit should be deducted
        $this->assertSame(1, $user->fresh()->consultation_credits);
    }

    public function test_escalate_deducts_credit_exactly_once(): void
    {
        Event::fake();

        $category = Category::factory()->create();
        $user     = User::factory()->create([
            'email_verified_at'    => now(),
            'plan'                 => 'premium',
            'plan_expires_at'      => now()->addDays(30),
            'consultation_credits' => 5,
        ]);
        Expert::factory()->create(['category_id' => $category->id, 'is_available' => true]);
        $conv = Conversation::factory()->create(['user_id' => $user->id, 'category_id' => $category->id]);

        $this->actingAs($user)->postJson("/api/v1/conversations/{$conv->id}/escalate");

        $this->assertSame(4, $user->fresh()->consultation_credits);
    }

    // ─── Ownership Guard ──────────────────────────────────────────────────────

    public function test_user_cannot_escalate_another_users_conversation(): void
    {
        $owner    = User::factory()->create(['email_verified_at' => now()]);
        $other    = User::factory()->create([
            'email_verified_at'    => now(),
            'plan'                 => 'pro',
            'plan_expires_at'      => now()->addDays(30),
            'consultation_credits' => 2,
        ]);
        $category = Category::factory()->create();
        $conv     = Conversation::factory()->create(['user_id' => $owner->id, 'category_id' => $category->id]);

        $response = $this->actingAs($other)->postJson("/api/v1/conversations/{$conv->id}/escalate");

        $response->assertStatus(403);
    }

    public function test_guest_cannot_escalate(): void
    {
        $category = Category::factory()->create();
        $user     = User::factory()->create();
        $conv     = Conversation::factory()->create(['user_id' => $user->id, 'category_id' => $category->id]);

        $response = $this->postJson("/api/v1/conversations/{$conv->id}/escalate");

        $response->assertStatus(401);
    }
}
