<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Agent;
use App\Models\Chit;
use App\Models\Customer;
use App\Models\Payment;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/** The numbers behind the Home / Dashboard screens. Definitions match functional spec §7. */
class DashboardController extends Controller
{
    public function admin(): JsonResponse
    {
        $active = Chit::where('status', 'active')->get();
        $todayPayments = Payment::where('status', 'confirmed')->whereDate('paid_at', today_ist())->get();
        $pending = $active->sum(fn (Chit $c) => $this->dueTodayPaise($c));
        $towardDue = $this->collectedTowardDuePaise($todayPayments->pluck('id'));

        return response()->json([
            'customers' => Customer::count(),
            'active_chits' => $active->count(),
            'expected_today' => rupees($pending + $towardDue),
            'pending_today' => rupees($pending),
            'collected_today' => rupees($todayPayments->sum('amount_paise')),
            'cash_today' => rupees($todayPayments->where('method', 'cash')->sum('amount_paise')),
            'online_today' => rupees($todayPayments->where('method', 'online')->sum('amount_paise')),
            'outstanding' => rupees($active->sum(fn (Chit $c) => $c->outstandingPaise())),
            'overdue' => rupees($active->sum(fn (Chit $c) => $c->overduePaise())),
            'pending_corrections' => \App\Models\CorrectionRequest::where('status', 'pending')->count(),
            'pending_online_payments' => \App\Models\Payment::where('status', 'pending')->where('method', 'online')->count(),
            'pending_disbursements' => Chit::where('status', 'pending')->count(),
            'paise' => [
                'expected_today' => $pending + $towardDue,
                'pending_today' => $pending,
                'collected_today' => (int) $todayPayments->sum('amount_paise'),
                'cash_today' => (int) $todayPayments->where('method', 'cash')->sum('amount_paise'),
                'online_today' => (int) $todayPayments->where('method', 'online')->sum('amount_paise'),
                'outstanding' => $active->sum(fn (Chit $c) => $c->outstandingPaise()),
                'overdue' => $active->sum(fn (Chit $c) => $c->overduePaise()),
            ],
        ]);
    }

    public function agent(Request $request): JsonResponse
    {
        $agent = $request->user()->agent;
        $customerIds = Agent::findOrFail($agent->id)->customers()->pluck('id');
        $chits = Chit::whereIn('customer_id', $customerIds)->where('status', 'active')->get();
        $today = Payment::where('collected_by_agent_id', $agent->id)->where('status', 'confirmed')->whereDate('paid_at', today_ist())->sum('amount_paise');

        $pending = $chits->sum(fn (Chit $c) => $this->dueTodayPaise($c));
        $todayIds = Payment::where('collected_by_agent_id', $agent->id)->where('status', 'confirmed')->whereDate('paid_at', today_ist())->pluck('id');
        $towardDue = $this->collectedTowardDuePaise($todayIds);
        $overdueCustomers = Customer::whereIn('id', $customerIds)->get()
            ->filter(fn (Customer $c) => $c->activeChits()->with('installments')->get()->sum(fn (Chit $ch) => $ch->overduePaise()) > 0)->count();

        return response()->json([
            'customers' => $customerIds->count(),
            'expected_today' => rupees($pending + $towardDue),
            'pending_today' => rupees($pending),
            'collected_today' => rupees($today),
            'collected_toward_due' => rupees($towardDue),
            'percent_collected' => ($pending + $towardDue) > 0 ? round($towardDue / ($pending + $towardDue), 4) : 0,
            'overdue_customers' => $overdueCustomers,
            'paise' => [
                'expected_today' => $pending + $towardDue,
                'pending_today' => $pending,
                'collected_today' => (int) $today,
                'collected_toward_due' => $towardDue,
            ],
        ]);
    }

    /** The logged-in customer's own totals (Customer Home). */
    public function customer(Request $request): JsonResponse
    {
        $active = $request->user()->customer->activeChits()->with('installments')->get();

        return response()->json([
            'active_chits' => $active->count(),
            'total_loan' => rupees($active->sum('loan_amount_paise')),
            'total_repayment' => rupees($active->sum('total_repayment_paise')),
            'outstanding' => rupees($active->sum(fn (Chit $c) => $c->outstandingPaise())),
            'overdue' => rupees($active->sum(fn (Chit $c) => $c->overduePaise())),
        ]);
    }

    /** Money allocated today (by the given payments) to installments that were due on or before today (spec §7). */
    protected function collectedTowardDuePaise($paymentIds): int
    {
        if ($paymentIds->isEmpty()) {
            return 0;
        }
        $today = today_ist()->toDateString();

        return (int) \App\Models\PaymentAllocation::whereIn('payment_id', $paymentIds)
            ->whereHas('installment', fn ($q) => $q->whereDate('due_date', '<=', $today))
            ->where('amount_paise', '>', 0)
            ->sum('amount_paise');
    }

    protected function dueTodayPaise(Chit $chit): int
    {
        $chit->loadMissing('installments');
        $today = today_ist()->toDateString();

        return $chit->installments->filter(fn ($i) => $i->due_date->toDateString() <= $today && $i->status !== 'paid' && $i->status !== 'cancelled')
            ->sum(fn ($i) => $i->remainingPaise());
    }
}
