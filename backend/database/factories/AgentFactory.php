<?php

namespace Database\Factories;

use App\Models\Agent;
use Illuminate\Database\Eloquent\Factories\Factory;

class AgentFactory extends Factory
{
    protected $model = Agent::class;

    public function definition(): array
    {
        return [
            'agent_code' => 'AGT-'.$this->faker->unique()->numerify('###'),
            'address' => $this->faker->address(),
            'joined_on' => now()->toDateString(),
        ];
    }
}
