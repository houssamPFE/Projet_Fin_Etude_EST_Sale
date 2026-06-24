<?php

namespace Tests\Feature\Api;

use App\Enums\ConversationChannel;
use App\Enums\ConversationStatus;
use App\Enums\Role;
use App\Models\Category;
use App\Models\Conversation;
use App\Models\Expert;
use App\Models\Message;
use App\Models\User;
use Illuminate\Support\Facades\Event;
use Tests\TestCase;

class AiCallbackTest extends TestCase
{
    public function test_callback_stores_ai_actions_without_assigning_expert(): void
    {
        Event::fake();
        config(['services.n8n.secret' => 'test-secret']);

        $generalCategory = $this->category('medecine-generale', 'Medecine generale');
        $this->category('cardiologie', 'Cardiologie');
        $this->availableExpert($generalCategory, 4.9);

        [$conversation, $message] = $this->conversationWithMessage($generalCategory);

        $response = $this->postJson('/api/v1/ai/callback', $this->payload($conversation, $message, [
            'urgency_level' => 'moderate',
            'specialty_suggested' => 'cardiologie',
            'intent' => 'recommend_expert',
            'suggest_expert' => true,
            'requires_premium' => true,
            'actions' => [
                [
                    'type' => 'find_expert',
                    'label' => 'Oui, chercher un medecin',
                    'specialty' => 'cardiologie',
                ],
                [
                    'type' => 'continue_ai',
                    'label' => 'Non, continuer avec l IA',
                ],
            ],
        ]), [
            'X-N8N-Secret' => 'test-secret',
        ]);

        $response->assertOk();

        $conversation->refresh();

        $this->assertNull($conversation->expert_id);
        $this->assertSame($generalCategory->id, $conversation->category_id);
        $this->assertSame(ConversationStatus::Ai, $conversation->status);
        $this->assertSame(ConversationChannel::Ai, $conversation->channel);

        $aiMessage = Message::query()
            ->where('conversation_id', $conversation->id)
            ->where('sender_type', 'ai')
            ->firstOrFail();

        $this->assertSame('cardiologie', $aiMessage->metadata['specialty_suggested']);
        $this->assertSame('moderate', $aiMessage->metadata['urgency_level']);
        $this->assertSame('recommend_expert', $aiMessage->metadata['intent']);
        $this->assertTrue($aiMessage->metadata['suggest_expert']);
        $this->assertTrue($aiMessage->metadata['requires_premium']);
        $this->assertSame('find_expert', $aiMessage->metadata['actions'][0]['type']);
    }

    public function test_callback_keeps_emergency_conversation_in_ai_until_access_is_valid(): void
    {
        Event::fake();
        config(['services.n8n.secret' => 'test-secret']);

        $generalCategory = $this->category('medecine-generale', 'Medecine generale');
        $this->category('cardiologie', 'Cardiologie');
        $this->availableExpert($generalCategory);

        [$conversation, $message] = $this->conversationWithMessage($generalCategory);

        $response = $this->postJson('/api/v1/ai/callback', $this->payload($conversation, $message, [
            'urgency_level' => 'urgent',
            'specialty_suggested' => 'cardiologie',
        ]), [
            'X-N8N-Secret' => 'test-secret',
        ]);

        $response->assertOk();

        $conversation->refresh();

        $this->assertNull($conversation->expert_id);
        $this->assertSame($generalCategory->id, $conversation->category_id);
        $this->assertSame(ConversationStatus::Ai, $conversation->status);
        $this->assertSame(ConversationChannel::Ai, $conversation->channel);
    }

    public function test_callback_keeps_ai_conversation_open_when_no_expert_is_available(): void
    {
        Event::fake();
        config(['services.n8n.secret' => 'test-secret']);

        $generalCategory = $this->category('medecine-generale', 'Medecine generale');
        $this->category('cardiologie', 'Cardiologie');

        [$conversation, $message] = $this->conversationWithMessage($generalCategory);

        $response = $this->postJson('/api/v1/ai/callback', $this->payload($conversation, $message, [
            'urgency_level' => 'urgent',
            'specialty_suggested' => 'cardiologie',
        ]), [
            'X-N8N-Secret' => 'test-secret',
        ]);

        $response->assertOk();

        $conversation->refresh();

        $this->assertNull($conversation->expert_id);
        $this->assertSame($generalCategory->id, $conversation->category_id);
        $this->assertSame(ConversationStatus::Ai, $conversation->status);
        $this->assertSame(ConversationChannel::Ai, $conversation->channel);
    }

    private function category(string $slug, string $name): Category
    {
        return Category::factory()->create([
            'slug' => $slug,
            'name' => $name,
            'is_active' => true,
        ]);
    }

    private function availableExpert(Category $category, float $rating = 4.2): Expert
    {
        $expertUser = User::factory()->create([
            'role' => Role::Expert->value,
        ]);

        return Expert::factory()->create([
            'user_id' => $expertUser->id,
            'category_id' => $category->id,
            'status' => 'validated',
            'is_available' => true,
            'rating_avg' => $rating,
        ]);
    }

    private function conversationWithMessage(Category $category): array
    {
        $user = User::factory()->create();

        $conversation = Conversation::factory()->create([
            'user_id' => $user->id,
            'category_id' => $category->id,
            'status' => ConversationStatus::Ai->value,
            'channel' => ConversationChannel::Ai->value,
        ]);

        $message = Message::factory()->create([
            'conversation_id' => $conversation->id,
            'sender_type' => 'user',
            'sender_id' => $user->id,
            'content' => 'J ai une douleur forte a la poitrine et je respire mal',
        ]);

        return [$conversation, $message];
    }

    private function payload(Conversation $conversation, Message $message, array $overrides = []): array
    {
        return array_merge([
            'message_id' => $message->id,
            'conversation_id' => $conversation->id,
            'response' => 'Appelez les urgences maintenant.',
            'confidence' => 0.94,
            'escalate' => true,
            'urgency_level' => 'emergency',
            'specialty_suggested' => 'cardiologie',
            'model' => 'test-model',
            'tokens_used' => 42,
        ], $overrides);
    }
}
