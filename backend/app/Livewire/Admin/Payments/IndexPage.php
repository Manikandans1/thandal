<?php

namespace App\Livewire\Admin\Payments;

use App\Models\CorrectionRequest;
use App\Models\Payment;
use Livewire\Component;
use Livewire\WithPagination;

class IndexPage extends Component
{
    use WithPagination;

    public string $tab = 'list';
    public string $correctionStatus = 'pending';

    public function approve(int $id, \App\Services\CorrectionService $corrections)
    {
        $corrections->approve(CorrectionRequest::findOrFail($id), null, 'Approved.', auth()->user());
    }

    public function reject(int $id, \App\Services\CorrectionService $corrections)
    {
        $corrections->reject(CorrectionRequest::findOrFail($id), request('note', 'Rejected.'), auth()->user());
    }

    public function render()
    {
        $payments = Payment::with(['customer.user', 'chit'])->latest()->paginate(15);
        $corrections = CorrectionRequest::with(['payment.customer.user', 'requestedByAgent.user'])
            ->where('status', $this->correctionStatus)->latest()->get();

        return view('livewire.admin.payments.index-page', compact('payments', 'corrections'))->layout('layouts.admin');
    }
}
