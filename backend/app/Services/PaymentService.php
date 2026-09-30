<?php

namespace App\Services;

use App\Models\Agent;
use App\Models\Chit;
use App\Models\Customer;
use App\Models\Payment;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Records money received and applies it to a chit. Both cash and online payments go
 * through here so there is exactly one ledger and one allocation rule (functional spec §6).
 */
class PaymentService
{
    public function __construct(
        protected AllocationService $allocations,
        protected ScheduleService $schedule,
        protected SequenceService $sequences,
        protected AuditLogger $audit,
    ) {}

    /**
     * Agent collects cash from one of their own customers. Confirmed immediately.
     * $clientRequestId must be unique per attempt from the app, so a double-tap or retry
     * can never create two payments (functional spec §6.5).
     */
    public function collectCash(Chit $chit, Agent $agent, int $amountPaise, string $clientRequestId, User $actor): Payment
    {
        return DB::transaction(function () use ($chit, $agent, $amountPaise, $clientRequestId, $actor) {
            $chit = Chit::query()->whereKey($chit->id)->lockForUpdate()->firstOrFail();

            if ($chit->status !== 'active') {
                throw ValidationException::withMessages(['chit' => 'This chit is not active.']);
            }
            if ($chit->customer->agent_id !== $agent->id) {
                throw ValidationException::withMessages(['chit' => 'This customer is not assigned to you.']);
            }
            $this->assertAmountValid($chit, $amountPaise);

            if ($existing = Payment::where('client_request_id', $clientRequestId)->first()) {
                return $existing; // idempotent retry
            }

            $payment = Payment::create([
                'receipt_number' => $this->sequences->nextReceiptNumber(),
                'chit_id' => $chit->id,
                'customer_id' => $chit->customer_id,
                'method' => 'cash',
                'status' => 'confirmed',
                'amount_paise' => $amountPaise,
                'paid_at' => now(),
                'collected_by_agent_id' => $agent->id,
                'recorded_by' => $actor->id,
                'client_request_id' => $clientRequestId,
            ]);

            $applied = $this->allocations->allocate($chit, $payment, $amountPaise);
            $this->schedule->recalculateChitTotals($chit);

            $this->audit->log($actor, 'payment_confirmed', 'payment', $payment->receipt_number,
                'Cash '.rupees($amountPaise)." collected for {$chit->chit_code}");

            return $payment->fresh(['allocations']);
        });
    }

    /** Step 1 of an online payment: create a pending payment + a Razorpay order (see RazorpayService). */
    public function startOnlinePayment(Chit $chit, int $amountPaise, User $actor): Payment
    {
        $this->assertAmountValid($chit, $amountPaise);

        return Payment::create([
            'chit_id' => $chit->id,
            'customer_id' => $chit->customer_id,
            'method' => 'online',
            'status' => 'pending',
            'amount_paise' => $amountPaise,
            'recorded_by' => $actor->id,
        ]);
    }

    /** Step 2: called only after RazorpayService has verified the signature/status. */
    public function confirmOnlinePayment(Payment $payment, string $razorpayPaymentId): Payment
    {
        return DB::transaction(function () use ($payment, $razorpayPaymentId) {
            $payment = Payment::whereKey($payment->id)->lockForUpdate()->firstOrFail();
            if ($payment->status === 'confirmed') {
                return $payment; // already processed by a webhook or a previous call — no-op
            }
            $chit = Chit::whereKey($payment->chit_id)->lockForUpdate()->firstOrFail();

            $payment->status = 'confirmed';
            $payment->razorpay_payment_id = $razorpayPaymentId;
            $payment->receipt_number = $this->sequences->nextReceiptNumber();
            $payment->paid_at = now();
            $payment->save();

            $this->allocations->allocate($chit, $payment, $payment->amount_paise);
            $this->schedule->recalculateChitTotals($chit);

            $this->audit->log(null, 'payment_confirmed', 'payment', $payment->receipt_number,
                'Online '.rupees($payment->amount_paise)." confirmed for {$chit->chit_code} (Razorpay webhook/verify)");

            return $payment->fresh(['allocations']);
        });
    }

    public function failOnlinePayment(Payment $payment, string $reason): Payment
    {
        if ($payment->status === 'confirmed') {
            return $payment;
        }
        $payment->status = 'failed';
        $payment->failure_reason = $reason;
        $payment->save();

        return $payment;
    }

    protected function assertAmountValid(Chit $chit, int $amountPaise): void
    {
        if ($amountPaise <= 0) {
            throw ValidationException::withMessages(['amount' => 'Enter the amount received.']);
        }
        $outstanding = $this->allocations->outstandingPaise($chit);
        if ($amountPaise > $outstanding) {
            throw ValidationException::withMessages(['amount' => 'Amount is more than the outstanding '.rupees($outstanding).'.']);
        }
    }

    /** "Pay full outstanding" — always recalculated at payment time, never cached from the screen. */
    public function fullOutstandingPaise(Chit $chit): int
    {
        return $this->allocations->outstandingPaise($chit);
    }
}
