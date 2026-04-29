<?php

namespace Tests\Feature\Api;

use App\Jobs\ProcessMessageJob;
use App\Models\Category;
use App\Models\Conversation;
use App\Models\Expert;
use App\Models\User;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class ConversationTest extends TestCase
{
    public function test_user_can_create_conversation(): void
    {
        Queue::fake();
        $user     = User::factory()->create(['email_verified_at' => now()]);
        $category = Category::factory()->create();

        $response = $this->actingAs($user)->postJson('/api/v1/conversations', [
            'category_id' => $category->id,
            'title'       => 'My question',
            'message'     => 'Hello, I need help.',
        ]);

        $response->assertStatus(201)
            ->assertJsonStructure(['data' => ['conversation' => ['id', 'status']]]);

        $this->assertDatabaseHas('conversations', ['user_id' => $user->id]);
    }

    public function test_user_can_create_conversation_for_a_selected_expert(): void
    {
        Queue::fake();

        $user = User::factory()->create(['email_verified_at' => now()]);
        $expert = Expert::factory()->create();

        $response = $this->actingAs($user)->postJson('/api/v1/conversations', [
            'category_id' => Category::factory()->create()->id,
            'expert_id'   => $expert->id,
            'title'       => 'Question pour un specialiste',
            'message'     => 'Bonjour docteur.',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.conversation.expert.id', $expert->id)
            ->assertJsonPath('data.conversation.category.id', $expert->category_id)
            ->assertJsonPath('data.conversation.status', 'expert');

        $this->assertDatabaseHas('conversations', [
            'user_id'     => $user->id,
            'expert_id'   => $expert->id,
            'category_id' => $expert->category_id,
            'status'      => 'expert',
            'channel'     => 'expert',
        ]);
    }

    public function test_user_can_list_own_conversations(): void
    {
        $user  = User::factory()->create(['email_verified_at' => now()]);
        $other = User::factory()->create();

        Conversation::factory()->count(3)->create(['user_id' => $user->id]);
        Conversation::factory()->create(['user_id' => $other->id]);

        $response = $this->actingAs($user)->getJson('/api/v1/conversations');

        $response->assertStatus(200)
            ->assertJsonPath('meta.total', 3);
    }

    public function test_user_can_view_own_conversation(): void
    {
        $user         = User::factory()->create(['email_verified_at' => now()]);
        $conversation = Conversation::factory()->create(['user_id' => $user->id]);

        $response = $this->actingAs($user)->getJson('/api/v1/conversations/' . $conversation->id);

        $response->assertStatus(200)
            ->assertJsonPath('data.id', $conversation->id);
    }

    public function test_user_cannot_view_others_conversation(): void
    {
        $user  = User::factory()->create(['email_verified_at' => now()]);
        $other = User::factory()->create();
        $conv  = Conversation::factory()->create(['user_id' => $other->id]);

        $response = $this->actingAs($user)->getJson('/api/v1/conversations/' . $conv->id);

        $response->assertStatus(403);
    }

    public function test_guest_cannot_access_conversations(): void
    {
        $response = $this->getJson('/api/v1/conversations');

        $response->assertStatus(401);
    }
}
