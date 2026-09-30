<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;

class UserFactory extends Factory
{
    protected $model = User::class;

    public function definition(): array
    {
        return [
            'role' => 'customer',
            'name' => $this->faker->name(),
            'mobile' => (string) $this->faker->unique()->numerify('9#########'),
            'pin_hash' => Hash::make('4826'),
            'status' => 'active',
            'must_change_pin' => false,
            'failed_attempts' => 0,
        ];
    }
}
