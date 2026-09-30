<?php

namespace App\Livewire\Admin\Chits;

use App\Models\Customer;
use App\Services\ChitService;
use Livewire\Component;

/**
 * Mirrors the approved "Create chit account" screen. Total to pay = installment amount x count
 * (final decision, functional spec §5.2/§15 #1) — no interest, no lump sum.
 */
class CreatePage extends Component
{
    public ?int $customer_id = null;
    public ?int $loan_amount = null;
    public string $frequency = 'daily';
    public ?int $installment_count = null;
    public ?int $installment_amount = null;
    public string $start_date = '';
    public ?int $agent_id = null;
    public string $notes = '';

    public ?string $createdCode = null;

    public function mount()
    {
        $this->start_date = now()->addDays(2)->toDateString();
    }

    public function getTotalToPayProperty(): ?int
    {
        if ($this->installment_amount && $this->installment_count) {
            return $this->installment_amount * $this->installment_count;
        }

        return null;
    }

    public function getUnitProperty(): string
    {
        return match ($this->frequency) { 'weekly' => 'week', 'monthly' => 'month', default => 'day' };
    }

    public function save(ChitService $chits)
    {
        $data = $this->validate([
            'customer_id' => 'required|exists:customers,id',
            'loan_amount' => 'required|integer|min:1',
            'frequency' => 'required|in:daily,weekly,monthly',
            'installment_count' => 'required|integer|min:1',
            'installment_amount' => 'required|integer|min:1',
            'start_date' => 'required|date',
        ]);

        $chit = $chits->create([
            'customer_id' => $data['customer_id'],
            'loan_amount_paise' => $data['loan_amount'] * 100,
            'frequency' => $data['frequency'],
            'installment_count' => $data['installment_count'],
            'installment_amount_paise' => $data['installment_amount'] * 100,
            'start_date' => $data['start_date'],
            'notes' => $this->notes ?: null,
        ], auth()->user());

        $this->createdCode = $chit->chit_code;
        $this->redirect(route('chits.show', $chit), navigate: false);
    }

    public function render()
    {
        return view('livewire.admin.chits.create-page', ['customers' => Customer::with('user')->get()])->layout('layouts.admin');
    }
}
