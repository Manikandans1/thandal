<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'role' => $this->role,
            'name' => $this->name,
            'mobile' => $this->mobile,
            'must_change_pin' => $this->must_change_pin,
            'customer_code' => $this->customer?->customer_code,
            'agent_code' => $this->agent?->agent_code,
        ];
    }
}
