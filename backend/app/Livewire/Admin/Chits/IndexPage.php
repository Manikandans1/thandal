<?php

namespace App\Livewire\Admin\Chits;

use App\Models\Chit;
use Livewire\Component;
use Livewire\WithPagination;

class IndexPage extends Component
{
    use WithPagination;

    public string $status = 'All';

    public function render()
    {
        $chits = Chit::with('customer.user')
            ->when($this->status !== 'All', fn ($q) => $q->where('status', strtolower($this->status)))
            ->latest()->paginate(15);

        return view('livewire.admin.chits.index-page', compact('chits'))->layout('layouts.admin');
    }
}
