<?php

namespace Tests\Feature\Api;

use App\Models\Conversation;
use App\Models\Expert;
use App\Models\Review;
use App\Models\User;
use Tests\TestCase;

class ReviewTest extends TestCase
{
    // Reviews are submitted via POST /api/v1/conversations/{id}/rate (no /reviews route)

    public function test_user_can_submit_review_after_consultation(): void
    {
        $user   = User::factory()->create(['email_verified_at' => now()]);
        $expert = Expert::factory()->create();
        $conv   = Conversation::factory()->closed()->create([
            'user_id'   => $user->id,
            'expert_id' => $expert->id,
        ]);

        $response = $this->actingAs($user)->postJson("/api/v1/conversations/{$conv->id}/rate", [
            'rating'  => 4,
            'comment' => 'Médecin à l\'écoute.',
        ]);

        $response->assertStatus(200);
        $this->assertDatabaseHas('reviews', [
            'conversation_id' => $conv->id,
            'user_id'         => $user->id,
            'rating'          => 4,
        ]);
    }

    public function test_review_rating_must_be_1_to_5(): void
    {
        $user   = User::factory()->create(['email_verified_at' => now()]);
        $expert = Expert::factory()->create();
        $conv   = Conversation::factory()->closed()->create([
            'user_id'   => $user->id,
            'expert_id' => $expert->id,
        ]);

        $response = $this->actingAs($user)->postJson("/api/v1/conversations/{$conv->id}/rate", [
            'rating' => 10,
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors(['rating']);
    }

    public function test_user_cannot_rate_another_users_conversation(): void
    {
        $owner  = User::factory()->create(['email_verified_at' => now()]);
        $other  = User::factory()->create(['email_verified_at' => now()]);
        $expert = Expert::factory()->create();
        $conv   = Conversation::factory()->closed()->create([
            'user_id'   => $owner->id,
            'expert_id' => $expert->id,
        ]);

        $response = $this->actingAs($other)->postJson("/api/v1/conversations/{$conv->id}/rate", [
            'rating' => 3,
        ]);

        $response->assertStatus(403);
    }

    public function test_can_list_expert_reviews(): void
    {
        $expert = Expert::factory()->create();
        $user   = User::factory()->create(['email_verified_at' => now()]);
        $conv1  = Conversation::factory()->closed()->create(['user_id' => $user->id, 'expert_id' => $expert->id]);
        $conv2  = Conversation::factory()->closed()->create(['user_id' => $user->id, 'expert_id' => $expert->id]);

        Review::create(['conversation_id' => $conv1->id, 'user_id' => $user->id, 'expert_id' => $expert->id, 'rating' => 5, 'comment' => 'Excellent.']);
        Review::create(['conversation_id' => $conv2->id, 'user_id' => $user->id, 'expert_id' => $expert->id, 'rating' => 4, 'comment' => 'Bien.']);

        $response = $this->actingAs($user)->getJson("/api/v1/experts/{$expert->id}/reviews");

        $response->assertStatus(200)
            ->assertJsonCount(2, 'data');
    }

    public function test_guest_cannot_rate_conversation(): void
    {
        $expert = Expert::factory()->create();
        $owner  = User::factory()->create(['email_verified_at' => now()]);
        $conv   = Conversation::factory()->closed()->create(['user_id' => $owner->id, 'expert_id' => $expert->id]);

        $response = $this->postJson("/api/v1/conversations/{$conv->id}/rate", [
            'rating' => 5,
        ]);

        $response->assertStatus(401);
    }
}
