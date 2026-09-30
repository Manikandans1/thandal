<?php

namespace App\Exports;

use App\Models\Agent;
use App\Models\Chit;
use App\Models\Customer;
use App\Models\Payment;
use Maatwebsite\Excel\Concerns\FromArray;
use Maatwebsite\Excel\Concerns\WithHeadings;

/** Backs every "Export CSV / Excel" button (functional spec §10). */
class ReportExport implements FromArray, WithHeadings
{
    public function __construct(protected string $report) {}

    public function headings(): array
    {
        return match ($this->report) {
            'agents' => ['Agent', 'Customers', 'Collected today'],
            'customers' => ['Customer', 'ID', 'Mobile', 'Agent', 'Outstanding', 'Status'],
            'payments' => ['Receipt', 'Date', 'Customer', 'Chit', 'Method', 'Amount', 'Status'],
            'overdue' => ['Customer', 'Chit', 'Installments overdue', 'Overdue amount'],
            'completed' => ['Chit', 'Customer', 'Loan amount', 'Total repaid'],
            default => ['Date', 'Payments', 'Cash', 'Online', 'Total'],
        };
    }

    public function array(): array
    {
        return match ($this->report) {
            'agents' => Agent::with('user')->get()->map(fn (Agent $a) => [$a->user->name, $a->customers()->count(), rupees(0)])->all(),
            'customers' => Customer::with(['user', 'agent.user'])->get()->map(fn (Customer $c) => [
                $c->user->name, $c->customer_code, $c->user->mobile, $c->agent?->user?->name ?? '—', rupees($c->outstandingPaise()), ucfirst($c->user->status),
            ])->all(),
            'payments' => Payment::with(['customer.user', 'chit'])->get()->map(fn (Payment $p) => [
                $p->receipt_number, $p->paid_at?->toDateString(), $p->customer->user->name, $p->chit->chit_code, ucfirst($p->method), rupees($p->effectiveAmountPaise()), ucfirst($p->status),
            ])->all(),
            'overdue' => Chit::where('status', 'active')->get()->filter(fn (Chit $c) => $c->overduePaise() > 0)->map(fn (Chit $c) => [
                $c->customer->user->name, $c->chit_code, $c->installments->where('status', '!=', 'paid')->count(), rupees($c->overduePaise()),
            ])->values()->all(),
            'completed' => Chit::where('status', 'completed')->with('customer.user')->get()->map(fn (Chit $c) => [
                $c->chit_code, $c->customer->user->name, rupees($c->loan_amount_paise), rupees($c->total_repayment_paise),
            ])->all(),
            default => [],
        };
    }
}
