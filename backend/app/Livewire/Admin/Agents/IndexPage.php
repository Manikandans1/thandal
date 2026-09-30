<?php

namespace App\Livewire\Admin\Agents;

use App\Models\Agent;
use Livewire\Component;

class IndexPage extends Component
{
    public function render()
    {
        return view('livewire.admin.agents.index-page', ['agents' => Agent::with('user')->withCount('customers')->get()])->layout('layouts.admin');
    }
}
