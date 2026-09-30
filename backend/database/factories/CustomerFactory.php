<?php

namespace Database\Factories;

use App\Models\Customer;
use Illuminate\Database\Eloquent\Factories\Factory;

class CustomerFactory extends Factory
{
    protected $model = Customer::class;

    public function definition(): array
    {
        return [
            'customer_code' => 'THD-1'.$this->faker->unique()->numerify('####'),
            'address' => $this->faker->address(),
            'joined_on' => now()->toDateString(),
            'created_by' => \App\Models\User::factory(),
        ];
    }
}
