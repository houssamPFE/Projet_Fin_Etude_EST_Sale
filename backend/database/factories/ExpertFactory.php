<?php

namespace Database\Factories;

use App\Enums\Role;
use App\Models\Category;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class ExpertFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id'      => User::factory()->state(['role' => Role::Expert->value]),
            'category_id'  => Category::factory(),
            'bio'          => fake()->paragraph(),
            'rating_avg'   => fake()->randomFloat(2, 3, 5),
            'total_reviews'=> fake()->numberBetween(0, 50),
            'is_available' => true,
            'status'       => 'validated',
        ];
    }

    public function pending(): static
    {
        return $this->state(['status' => 'pending']);
    }
}
