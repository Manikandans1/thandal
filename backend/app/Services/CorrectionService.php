<?php

namespace App\Services;

use App\Models\Agent;
use App\Models\Chit;
use App\Models\CorrectionRequest;
use App\Models\Payment;
use App\Models\PaymentAdjustment;
use App\Models\PaymentAllocation;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * A confirmed payment is never edited or deleted (functional spec §9). An agent requests a
 * correction; an admin approves (adding adjustment + allocation rows) or rejects (a note is required).
 */
class CorrectionService
{
    public function __construct(
        protected SequenceService $sequences,
        protected ScheduleService $schedule,
        protected AllocationService $allocations,
        protected AuditLogger $audit,
    ) {}

    public function request(Payment $payment, Agent $agent, string $reason, ?int $requestedAmountPaise, string $note, User $actor): CorrectionRequest
    {
        if ($payment->collected_by_agent_id !== $agent->id || $payment->status !== 'confirmed') {
            throw ValidationException::withMessages(['payment' => 'You can only request a correction for a cash payment you collected.']);
        }
        if (mb_strlen(trim($note)) < 10) {
            throw ValidationException::withMessages(['note' => 'Add a few words so the admin can understand (at least 10 characters).']);
        }

        $cr = CorrectionRequest::create([
            'code' => $this->sequences->nextCorrectionCode(),
            'payment_id' => $payment->id,
            'requested_by_agent_id' => $agent->id,
            'reason' => $reason,
            'requested_amount_paise' => $requestedAmountPaise,
            'note' => $note,
            'status' => 'pending',
        ]);

        $this->audit->log($actor, 'correction_requested', 'correction', $cr->code, "For payment {$payment->receipt_number}: {$reason}");

        return $cr;
    }

    public function approve(CorrectionRequest $cr, ?string $moveToChitId, string $note, User $actor): CorrectionRequest
    {
        return DB::transaction(function () use ($cr, $moveToChitId, $note, $actor) {
            $payment = Payment::whereKey($cr->payment_id)->lockForUpdate()->firstOrFail();
            $chit = Chit::whereKey($payment->chit_id)->lockForUpdate()->firstOrFail();

            $adj = match ($cr->reason) {
                'wrong_amount' => $this->applyAmountChange($payment, $chit, (int) $cr->requested_amount_paise, $cr, $actor, $note),
                'duplicate_entry' => $this->reverseEntirely($payment, $chit, $cr, $actor, $note, 'reversal'),
                'wrong_customer_or_chit' => $this->moveToOtherChit($payment, $chit, $moveToChitId, $cr, $actor, $note),
                default => $this->noAmountChangeAcknowledgement($payment, $cr, $actor, $note),
            };

            $this->schedule->recalculateChitTotals($chit->fresh());

            $cr->status = 'approved';
            $cr->decided_by = $actor->id;
            $cr->decided_at = now();
            $cr->decision_note = $note;
            $cr->resolution_chit_id = $moveToChitId ?: null;
            $cr->save();

            $this->audit->log($actor, 'correction_approved', 'correction', $cr->code, "Adjustment created for {$payment->receipt_number}: {$note}");

            return $cr;
        });
    }

    public function reject(CorrectionRequest $cr, string $note, User $actor): CorrectionRequest
    {
        if (mb_strlen(trim($note)) < 1) {
            throw ValidationException::withMessages(['note' => 'A note is required to reject.']);
        }
        $cr->status = 'rejected';
        $cr->decided_by = $actor->id;
        $cr->decided_at = now();
        $cr->decision_note = $note;
        $cr->save();

        $this->audit->log($actor, 'correction_rejected', 'correction', $cr->code, $note);

        return $cr;
    }

    protected function applyAmountChange(Payment $payment, Chit $chit, int $newAmountPaise, CorrectionRequest $cr, User $actor, string $note): PaymentAdjustment
    {
        $current = $payment->effectiveAmountPaise();
        $delta = $newAmountPaise - $current;

        $adj = PaymentAdjustment::create([
            'payment_id' => $payment->id, 'correction_request_id' => $cr->id, 'type' => 'amount_change',
            'delta_paise' => $delta, 'created_by' => $actor->id, 'reason' => $note,
        ]);

        if ($delta < 0) {
            $this->reverseAmount($payment, $chit, -$delta, $adj);
        } elseif ($delta > 0) {
            $allowed = min($delta, $this->allocations->outstandingPaise($chit));
            if ($allowed > 0) {
                $applied = $this->allocations->allocate($chit, $payment, $allowed);
                foreach ($applied as $a) {
                    PaymentAllocation::where('payment_id', $payment->id)
                        ->where('installment_id', $a['installment_id'])->latest('id')->first()?->update(['adjustment_id' => $adj->id]);
                }
            }
        }

        $payment->net_amount_paise = $newAmountPaise;
        $payment->save();

        return $adj;
    }

    protected function reverseEntirely(Payment $payment, Chit $chit, CorrectionRequest $cr, User $actor, string $note, string $type): PaymentAdjustment
    {
        $adj = PaymentAdjustment::create([
            'payment_id' => $payment->id, 'correction_request_id' => $cr->id, 'type' => $type,
            'delta_paise' => -$payment->effectiveAmountPaise(), 'created_by' => $actor->id, 'reason' => $note,
        ]);
        $this->reverseAmount($payment, $chit, $payment->effectiveAmountPaise(), $adj);
        $payment->status = 'reversed';
        $payment->net_amount_paise = 0;
        $payment->save();

        return $adj;
    }

    protected function moveToOtherChit(Payment $payment, Chit $fromChit, ?string $toChitId, CorrectionRequest $cr, User $actor, string $note): PaymentAdjustment
    {
        if (! $toChitId) {
            throw ValidationException::withMessages(['resolution_chit_id' => 'Choose the correct chit for this payment.']);
        }
        $toChit = Chit::whereKey($toChitId)->lockForUpdate()->firstOrFail();
        $amount = $payment->effectiveAmountPaise();

        $adj = $this->reverseEntirely($payment, $fromChit, $cr, $actor, $note, 'moved_to_other_chit');

        $newPayment = $payment->replicate(['receipt_number', 'razorpay_order_id', 'razorpay_payment_id', 'client_request_id']);
        $newPayment->chit_id = $toChit->id;
        $newPayment->customer_id = $toChit->customer_id;
        $newPayment->status = 'confirmed';
        $newPayment->net_amount_paise = null;
        $newPayment->notes = "Moved from {$fromChit->chit_code} by correction {$cr->code}";
        $newPayment->save();

        $applied = $this->allocations->allocate($toChit, $newPayment, min($amount, $this->allocations->outstandingPaise($toChit)));
        $this->schedule->recalculateChitTotals($toChit);

        return $adj;
    }

    protected function noAmountChangeAcknowledgement(Payment $payment, CorrectionRequest $cr, User $actor, string $note): PaymentAdjustment
    {
        return PaymentAdjustment::create([
            'payment_id' => $payment->id, 'correction_request_id' => $cr->id, 'type' => 'amount_change',
            'delta_paise' => 0, 'created_by' => $actor->id, 'reason' => $note,
        ]);
    }

    /** Reverse $amountPaise worth of allocations, most recent first, with negative allocation rows. */
    protected function reverseAmount(Payment $payment, Chit $chit, int $amountPaise, PaymentAdjustment $adj): void
    {
        $remaining = $amountPaise;
        $rows = PaymentAllocation::where('payment_id', $payment->id)->where('amount_paise', '>', 0)->orderByDesc('id')->get();

        foreach ($rows as $row) {
            if ($remaining <= 0) {
                break;
            }
            $take = min($remaining, $row->amount_paise);

            PaymentAllocation::create([
                'payment_id' => $payment->id, 'installment_id' => $row->installment_id,
                'amount_paise' => -$take, 'adjustment_id' => $adj->id,
            ]);

            $installment = $row->installment()->lockForUpdate()->first();
            $installment->paid_paise -= $take;
            $installment->status = $installment->paid_paise <= 0 ? 'upcoming' : 'partially_paid';
            $installment->paid_at = null;
            $installment->save();

            $remaining -= $take;
        }
    }
}
