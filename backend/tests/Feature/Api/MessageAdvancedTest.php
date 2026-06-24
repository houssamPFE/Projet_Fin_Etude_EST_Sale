<?php

namespace Tests\Feature\Api;

use App\Jobs\ProcessMessageJob;
use App\Jobs\TranscribeAudioJob;
use App\Models\Category;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Queue;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class MessageAdvancedTest extends TestCase
{
    // ─── Send Text Message ─────────────────────────────────────────────────────

    public function test_user_can_send_a_text_message(): void
    {
        Queue::fake();
        Storage::fake('s3');

        $user     = User::factory()->create(['email_verified_at' => now()]);
        $category = Category::factory()->create();
        $conv     = Conversation::factory()->create(['user_id' => $user->id, 'category_id' => $category->id]);

        $response = $this->actingAs($user)->postJson("/api/v1/conversations/{$conv->id}/messages", [
            'content' => 'Bonjour, j\'ai mal à la tête depuis 3 jours.',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.sender_type', 'user');

        Queue::assertPushed(ProcessMessageJob::class);
    }

    public function test_message_content_is_required(): void
    {
        $user     = User::factory()->create(['email_verified_at' => now()]);
        $category = Category::factory()->create();
        $conv     = Conversation::factory()->create(['user_id' => $user->id, 'category_id' => $category->id]);

        $response = $this->actingAs($user)->postJson("/api/v1/conversations/{$conv->id}/messages", []);

        $response->assertStatus(422)->assertJsonValidationErrors(['content']);
    }

    public function test_user_cannot_send_message_to_another_users_conversation(): void
    {
        Queue::fake();

        $owner    = User::factory()->create(['email_verified_at' => now()]);
        $attacker = User::factory()->create(['email_verified_at' => now()]);
        $category = Category::factory()->create();
        $conv     = Conversation::factory()->create(['user_id' => $owner->id, 'category_id' => $category->id]);

        $response = $this->actingAs($attacker)->postJson("/api/v1/conversations/{$conv->id}/messages", [
            'content' => 'Intrusion!',
        ]);

        $response->assertStatus(403);
    }

    // ─── Audio Message ────────────────────────────────────────────────────────

    public function test_user_can_send_audio_message(): void
    {
        Queue::fake();
        Storage::fake('s3');

        $user     = User::factory()->create(['email_verified_at' => now()]);
        $category = Category::factory()->create();
        $conv     = Conversation::factory()->create(['user_id' => $user->id, 'category_id' => $category->id]);
        $audio    = UploadedFile::fake()->create('voice.webm', 500, 'audio/webm');

        $response = $this->actingAs($user)->postJson("/api/v1/conversations/{$conv->id}/messages/audio", [
            'audio' => $audio,
        ]);

        $response->assertStatus(201);
        Queue::assertPushed(TranscribeAudioJob::class);
    }

    // ─── List Messages ─────────────────────────────────────────────────────────

    public function test_user_can_list_messages_in_their_conversation(): void
    {
        $user     = User::factory()->create(['email_verified_at' => now()]);
        $category = Category::factory()->create();
        $conv     = Conversation::factory()->create(['user_id' => $user->id, 'category_id' => $category->id]);
        Message::factory()->count(5)->create([
            'conversation_id' => $conv->id,
            'sender_type'     => 'user',
            'sender_id'       => $user->id,
        ]);

        $response = $this->actingAs($user)->getJson("/api/v1/conversations/{$conv->id}/messages");

        $response->assertStatus(200)
            ->assertJsonCount(5, 'data');
    }

    // ─── Mark Message as Read ─────────────────────────────────────────────────

    public function test_user_can_mark_message_as_read(): void
    {
        $user     = User::factory()->create(['email_verified_at' => now()]);
        $category = Category::factory()->create();
        $conv     = Conversation::factory()->create(['user_id' => $user->id, 'category_id' => $category->id]);
        $message  = Message::factory()->create([
            'conversation_id' => $conv->id,
            'sender_type'     => 'ai',
            'read_at'         => null,
        ]);

        $response = $this->actingAs($user)
            ->putJson("/api/v1/conversations/{$conv->id}/messages/{$message->id}/read");

        $response->assertStatus(200);
        $this->assertNotNull($message->fresh()->read_at);
    }

    // ─── AI Callback ──────────────────────────────────────────────────────────

    public function test_n8n_callback_creates_ai_message(): void
    {
        $user    = User::factory()->create(['email_verified_at' => now()]);
        $category = Category::factory()->create();
        $conv    = Conversation::factory()->create(['user_id' => $user->id, 'category_id' => $category->id]);
        // The callback requires a reference to the original user message
        $message = Message::factory()->create([
            'conversation_id' => $conv->id,
            'sender_type'     => 'user',
            'sender_id'       => $user->id,
            'content'         => 'J\'ai mal à la tête.',
        ]);

        $response = $this->withHeaders([
            'X-N8N-Secret' => config('services.n8n.secret'),
        ])->postJson('/api/v1/ai/callback', [
            'message_id'      => $message->id,
            'conversation_id' => $conv->id,
            'response'        => 'Voici quelques informations sur votre symptôme.',
            'confidence'      => 0.85,
            'escalate'        => false,
            'urgency_level'   => 'low',
            'model'           => 'llama-3.1-8b-instant',
            'tokens_used'     => 150,
        ]);

        $response->assertStatus(200);
        $this->assertDatabaseHas('messages', [
            'conversation_id' => $conv->id,
            'sender_type'     => 'ai',
        ]);
    }

    public function test_n8n_callback_without_secret_returns_401(): void
    {
        $user     = User::factory()->create(['email_verified_at' => now()]);
        $category = Category::factory()->create();
        $conv     = Conversation::factory()->create(['user_id' => $user->id, 'category_id' => $category->id]);

        $response = $this->postJson('/api/v1/ai/callback', [
            'conversation_id' => $conv->id,
            'content'         => 'Unauthorized call.',
        ]);

        $response->assertStatus(401);
    }
}
