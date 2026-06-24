<?php

namespace Tests\Feature\Api;

use App\Jobs\CloseConversationJob;
use App\Models\Category;
use App\Models\Conversation;
use App\Models\Expert;
use App\Models\User;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class ConversationActionsTest extends TestCase
{
    // ─── Create Conversation ──────────────────────────────────────────────────

    public function test_user_can_create_a_conversation(): void
    {
        $user     = User::factory()->create(['email_verified_at' => now()]);
        $category = Category::factory()->create();

        $response = $this->actingAs($user)->postJson('/api/v1/conversations', [
            'category_id' => $category->id,
            'title'       => 'Ma première consultation',
        ]);

        $response->assertStatus(201);

        $this->assertDatabaseHas('conversations', ['user_id' => $user->id]);
    }

    public function test_create_conversation_requires_category_id(): void
    {
        $user = User::factory()->create(['email_verified_at' => now()]);

        $response = $this->actingAs($user)->postJson('/api/v1/conversations', [
            'title' => 'Consultation sans catégorie',
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors(['category_id']);
    }

    public function test_guest_cannot_create_conversation(): void
    {
        $category = Category::factory()->create();

        $response = $this->postJson('/api/v1/conversations', [
            'category_id' => $category->id,
        ]);

        $response->assertStatus(401);
    }

    // ─── List Conversations ───────────────────────────────────────────────────

    public function test_user_can_list_their_conversations(): void
    {
        $user     = User::factory()->create(['email_verified_at' => now()]);
        $category = Category::factory()->create();
        Conversation::factory()->count(3)->create(['user_id' => $user->id, 'category_id' => $category->id]);

        $response = $this->actingAs($user)->getJson('/api/v1/conversations');

        $response->assertStatus(200)
            ->assertJsonCount(3, 'data');
    }

    public function test_user_cannot_see_other_users_conversations(): void
    {
        $user1    = User::factory()->create(['email_verified_at' => now()]);
        $user2    = User::factory()->create(['email_verified_at' => now()]);
        $category = Category::factory()->create();
        Conversation::factory()->count(2)->create(['user_id' => $user2->id, 'category_id' => $category->id]);

        $response = $this->actingAs($user1)->getJson('/api/v1/conversations');

        $response->assertStatus(200)
            ->assertJsonCount(0, 'data');
    }

    // ─── Close Conversation ───────────────────────────────────────────────────

    public function test_user_can_close_their_conversation(): void
    {
        Queue::fake();

        $user     = User::factory()->create(['email_verified_at' => now()]);
        $category = Category::factory()->create();
        $conv     = Conversation::factory()->create(['user_id' => $user->id, 'category_id' => $category->id]);

        $response = $this->actingAs($user)->putJson("/api/v1/conversations/{$conv->id}/close");

        $response->assertStatus(200);
        // Close is async via CloseConversationJob — status update happens inside the job
        Queue::assertPushed(CloseConversationJob::class);
    }

    public function test_user_cannot_close_another_users_conversation(): void
    {
        $owner    = User::factory()->create(['email_verified_at' => now()]);
        $attacker = User::factory()->create(['email_verified_at' => now()]);
        $category = Category::factory()->create();
        $conv     = Conversation::factory()->create(['user_id' => $owner->id, 'category_id' => $category->id]);

        $response = $this->actingAs($attacker)->putJson("/api/v1/conversations/{$conv->id}/close");

        $response->assertStatus(403);
    }

    // ─── Rate Conversation ────────────────────────────────────────────────────

    public function test_user_can_rate_a_closed_conversation(): void
    {
        $user   = User::factory()->create(['email_verified_at' => now()]);
        $expert = Expert::factory()->create();
        $conv   = Conversation::factory()->closed()->create([
            'user_id'   => $user->id,
            'expert_id' => $expert->id,
        ]);

        $response = $this->actingAs($user)->postJson("/api/v1/conversations/{$conv->id}/rate", [
            'rating'  => 5,
            'comment' => 'Excellent médecin.',
        ]);

        $response->assertStatus(200);
        $this->assertDatabaseHas('conversations', ['id' => $conv->id, 'rating' => 5]);
        $this->assertDatabaseHas('reviews', ['conversation_id' => $conv->id, 'rating' => 5]);
    }

    public function test_rating_must_be_between_1_and_5(): void
    {
        $user = User::factory()->create(['email_verified_at' => now()]);
        $conv = Conversation::factory()->closed()->create(['user_id' => $user->id]);

        $response = $this->actingAs($user)->postJson("/api/v1/conversations/{$conv->id}/rate", [
            'rating' => 10,
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors(['rating']);
    }

    public function test_expert_can_see_their_assigned_conversations(): void
    {
        $expert   = Expert::factory()->create();
        $category = Category::factory()->create();
        $user     = User::factory()->create(['email_verified_at' => now()]);
        Conversation::factory()->count(2)->create([
            'user_id'   => $user->id,
            'expert_id' => $expert->id,
            'category_id' => $category->id,
            'status'    => 'expert',
        ]);

        // Expert sees their conversations through the main conversations endpoint
        $response = $this->actingAs($expert->user)->getJson('/api/v1/conversations');

        $response->assertStatus(200)
            ->assertJsonCount(2, 'data');
    }
}
