<?php

namespace App\Livewire\Admin\Customers;

use App\Models\Customer;
use Livewire\Component;

class ShowPage extends Component
{
    public Customer $customer;

    public function mount(Customer $customer)
    {
        $this->customer = $customer->load(['user', 'agent.user', 'currentIdentityDocument', 'chits.installments', 'assignments.agent.user']);
    }

    public function render()
    {
        return view('livewire.admin.customers.show-page')->layout('layouts.admin');
    }
}
