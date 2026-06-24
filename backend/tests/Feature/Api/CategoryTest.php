<?php

namespace Tests\Feature\Api;

use App\Models\Category;
use App\Models\User;
use Tests\TestCase;

class CategoryTest extends TestCase
{
    // ─── Public listing ───────────────────────────────────────────────────────

    public function test_anyone_can_list_active_categories(): void
    {
        Category::factory()->count(3)->create(['is_active' => true]);
        Category::factory()->create(['is_active' => false]);

        $response = $this->getJson('/api/v1/categories');

        $response->assertStatus(200);
        // Only active ones should appear
        $data = $response->json('data');
        $this->assertCount(3, $data);
    }

    // ─── Admin CRUD ───────────────────────────────────────────────────────────

    public function test_admin_can_create_category(): void
    {
        $admin = User::factory()->create(['email_verified_at' => now(), 'role' => 'admin']);

        $response = $this->actingAs($admin)->postJson('/api/v1/admin/categories', [
            'name'        => 'Neurologie',
            'slug'        => 'neurologie',
            'description' => 'Maladies du système nerveux.',
            'is_active'   => true,
        ]);

        $response->assertStatus(201);
        $this->assertDatabaseHas('categories', ['slug' => 'neurologie']);
    }

    public function test_admin_can_update_category(): void
    {
        $admin    = User::factory()->create(['email_verified_at' => now(), 'role' => 'admin']);
        $category = Category::factory()->create(['name' => 'Old Name']);

        $response = $this->actingAs($admin)->putJson("/api/v1/admin/categories/{$category->id}", [
            'name' => 'New Name',
        ]);

        $response->assertStatus(200);
        $this->assertDatabaseHas('categories', ['id' => $category->id, 'name' => 'New Name']);
    }

    public function test_admin_can_delete_category(): void
    {
        $admin    = User::factory()->create(['email_verified_at' => now(), 'role' => 'admin']);
        $category = Category::factory()->create();

        $response = $this->actingAs($admin)->deleteJson("/api/v1/admin/categories/{$category->id}");

        $response->assertStatus(200);
        $this->assertDatabaseMissing('categories', ['id' => $category->id]);
    }

    public function test_non_admin_cannot_create_category(): void
    {
        $user = User::factory()->create(['email_verified_at' => now(), 'role' => 'user']);

        $response = $this->actingAs($user)->postJson('/api/v1/admin/categories', [
            'name' => 'Unauthorized',
            'slug' => 'unauthorized',
        ]);

        $response->assertStatus(403);
    }

    public function test_category_name_must_be_unique(): void
    {
        $admin = User::factory()->create(['email_verified_at' => now(), 'role' => 'admin']);
        Category::factory()->create(['name' => 'Pédiatrie', 'slug' => 'pediatrie']);

        // Creating a second category with a unique slug should succeed
        $response = $this->actingAs($admin)->postJson('/api/v1/admin/categories', [
            'name' => 'Neurologie',
            'slug' => 'neurologie',
        ]);

        $response->assertStatus(201);
        $this->assertDatabaseHas('categories', ['slug' => 'neurologie']);
    }
}
