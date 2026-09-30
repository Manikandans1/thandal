<?php

namespace App\Livewire\Admin\Customers;

use App\Models\Agent;
use App\Models\Customer;
use Livewire\Component;
use Livewire\WithPagination;

class IndexPage extends Component
{
    use WithPagination;

    public string $q = '';
    public string $status = 'All';
    public string $agentFilter = 'All';

    public function updating($name)
    {
        if (in_array($name, ['q', 'status', 'agentFilter'])) {
            $this->resetPage();
        }
    }

    public function render()
    {
        $customers = Customer::query()->with(['user', 'agent.user'])
            ->when($this->q, fn ($q) => $q->whereHas('user', fn ($u) => $u->where('name', 'like', "%{$this->q}%")->orWhere('mobile', 'like', "%{$this->q}%"))->orWhere('customer_code', 'like', "%{$this->q}%"))
            ->when($this->status !== 'All', fn ($q) => $q->whereHas('user', fn ($u) => $u->where('status', strtolower($this->status))))
            ->when($this->agentFilter === 'none', fn ($q) => $q->whereNull('agent_id'))
            ->when(is_numeric($this->agentFilter), fn ($q) => $q->where('agent_id', $this->agentFilter))
            ->paginate(15);

        return view('livewire.admin.customers.index-page', ['customers' => $customers, 'agents' => Agent::with('user')->get()])->layout('layouts.admin');
    }
}
