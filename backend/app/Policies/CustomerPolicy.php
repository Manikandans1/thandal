<?php

namespace App\Policies;

use App\Models\Customer;
use App\Models\User;

/** An agent may only act on customers CURRENTLY assigned to them (functional spec §2). */
class CustomerPolicy
{
    public function view(User $user, Customer $customer): bool
    {
        if ($user->isAdmin()) {
            return true;
        }
        if ($user->role === 'agent') {
            return $customer->agent_id === $user->agent?->id;
        }
        if ($user->role === 'customer') {
            return $customer->user_id === $user->id;
        }

        return false;
    }

    public function collectPayment(User $user, Customer $customer): bool
    {
        return $user->role === 'agent' && $customer->agent_id === $user->agent?->id;
    }
}
