<?php

namespace App\Livewire\Admin;

use App\Models\Chit;
use App\Models\CorrectionRequest;
use App\Models\Customer;
use App\Models\Payment;
use App\Models\User;
use Livewire\Component;

/** The numbers here follow the definitions in functional spec §7. */
class Dashboard extends Component
{
    public function render()
    {
        $active = Chit::where('status', 'active')->with('installments')->get();
        $today = Payment::where('status', 'confirmed')->whereDate('paid_at', today_ist())->get();

        return view('livewire.admin.dashboard', [
            'customers' => Customer::count(),
            'activeChits' => $active->count(),
            'pendingChits' => Chit::where('status', 'pending')->count(),
            'expectedToday' => $active->sum(fn (Chit $c) => $this->dueToday($c)),
            'collectedToday' => $today->sum('amount_paise'),
            'cashToday' => $today->where('method', 'cash')->sum('amount_paise'),
            'onlineToday' => $today->where('method', 'online')->sum('amount_paise'),
            'outstanding' => $active->sum(fn (Chit $c) => $c->outstandingPaise()),
            'overdue' => $active->sum(fn (Chit $c) => $c->overduePaise()),
            'pendingCorrections' => CorrectionRequest::where('status', 'pending')->count(),
            'pendingAdmins' => auth()->user()->isSuperAdmin() ? User::where('role', 'admin')->where('status', 'pending')->count() : 0,
        ])->layout('layouts.admin');
    }

    protected function dueToday(Chit $chit): int
    {
        $today = today_ist()->toDateString();

        return $chit->installments->filter(fn ($i) => $i->due_date->toDateString() <= $today && ! in_array($i->status, ['paid', 'cancelled'], true))
            ->sum(fn ($i) => $i->remainingPaise());
    }
}
