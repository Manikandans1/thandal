<?php

namespace App\Livewire\Admin\Chits;

use App\Models\Chit;
use App\Services\ChitService;
use Livewire\Component;

class ShowPage extends Component
{
    public Chit $chit;
    public string $tab = 'overview';

    public string $disb_method = 'cash';
    public string $disb_reference = '';
    public string $disb_note = '';

    public function mount(Chit $chit)
    {
        $this->chit = $chit->load(['customer.user', 'installments', 'payments', 'disbursement']);
    }

    public function disburse(ChitService $chits)
    {
        $data = $this->validate([
            'disb_method' => 'required|in:cash,bank_transfer',
            'disb_reference' => 'nullable|required_if:disb_method,bank_transfer|string|max:60',
        ]);
        $chits->recordDisbursement($this->chit, [
            'method' => $data['disb_method'], 'status' => 'completed', 'disbursed_on' => now()->toDateString(),
            'reference' => $data['disb_reference'] ?? null, 'note' => $this->disb_note,
        ], auth()->user());
        $this->chit->refresh();
    }

    public function render()
    {
        return view('livewire.admin.chits.show-page')->layout('layouts.admin');
    }
}
