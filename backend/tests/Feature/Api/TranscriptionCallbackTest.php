<?php

namespace Tests\Feature\Api;

use App\Models\Category;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\User;
use Tests\TestCase;

class TranscriptionCallbackTest extends TestCase
{
    public function test_n8n_can_post_transcription_result(): void
    {
        $user     = User::factory()->create(['email_verified_at' => now()]);
        $category = Category::factory()->create();
        $conv     = Conversation::factory()->create(['user_id' => $user->id, 'category_id' => $category->id]);
        $message  = Message::factory()->create([
            'conversation_id' => $conv->id,
            'sender_type'     => 'user',
            'sender_id'       => $user->id,
            'type'            => 'audio',
            'media_url'       => 'https://s3.example.com/voice.webm',
            'transcription'   => null,
        ]);

        $response = $this->withHeaders([
            'X-N8N-Secret' => config('services.n8n.secret'),
        ])->postJson('/api/v1/ai/transcription-complete', [
            'message_id'    => $message->id,
            'transcription' => 'J\'ai une douleur thoracique depuis ce matin.',
        ]);

        $response->assertStatus(200);
        $this->assertDatabaseHas('messages', [
            'id'            => $message->id,
            'transcription' => 'J\'ai une douleur thoracique depuis ce matin.',
        ]);
    }

    public function test_transcription_callback_rejects_wrong_secret(): void
    {
        $user     = User::factory()->create(['email_verified_at' => now()]);
        $category = Category::factory()->create();
        $conv     = Conversation::factory()->create(['user_id' => $user->id, 'category_id' => $category->id]);
        $message  = Message::factory()->create([
            'conversation_id' => $conv->id,
            'sender_type'     => 'user',
            'type'            => 'audio',
            'transcription'   => null,
        ]);

        $response = $this->withHeaders([
            'X-N8N-Secret' => 'wrong-secret',
        ])->postJson('/api/v1/ai/transcription-complete', [
            'message_id'    => $message->id,
            'transcription' => 'Some text.',
        ]);

        $response->assertStatus(401);
        $this->assertNull($message->fresh()->transcription);
    }

    public function test_transcription_callback_requires_transcription_field(): void
    {
        $user     = User::factory()->create(['email_verified_at' => now()]);
        $category = Category::factory()->create();
        $conv     = Conversation::factory()->create(['user_id' => $user->id, 'category_id' => $category->id]);
        $message  = Message::factory()->create([
            'conversation_id' => $conv->id,
            'sender_type'     => 'user',
            'type'            => 'audio',
        ]);

        $response = $this->withHeaders([
            'X-N8N-Secret' => config('services.n8n.secret'),
        ])->postJson('/api/v1/ai/transcription-complete', [
            'message_id' => $message->id,
            // missing transcription
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors(['transcription']);
    }
}
