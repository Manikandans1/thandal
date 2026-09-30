<?php

namespace App\Services;

use App\Models\Chit;
use App\Models\Payment;
use App\Models\PaymentAllocation;
use Illuminate\Support\Collection;

/**
 * Applies a payment's amount to a chit's unpaid installments, oldest due date first
 * (overdue, then today, then future). Partial and advance payments are both allowed.
 * See functional spec §6.2.
 */
class AllocationService
{
    /**
     * @return Collection<int, array{installment_id:int, amount_paise:int}> what was applied, for the receipt / "Applied to" list
     */
    public function allocate(Chit $chit, Payment $payment, int $amountPaise): Collection
    {
        $chit->loadMissing('installments');

        $unpaid = $chit->installments
            ->where('status', '!=', 'cancelled')
            ->where('status', '!=', 'paid')
            ->sortBy('sequence');

        $remaining = $amountPaise;
        $applied = collect();

        foreach ($unpaid as $installment) {
            if ($remaining <= 0) {
                break;
            }
            $need = $installment->remainingPaise();
            if ($need <= 0) {
                continue;
            }
            $give = min($need, $remaining);

            PaymentAllocation::create([
                'payment_id' => $payment->id,
                'installment_id' => $installment->id,
                'amount_paise' => $give,
            ]);

            $installment->paid_paise += $give;
            $installment->status = $installment->paid_paise >= $installment->amount_paise ? 'paid' : 'partially_paid';
            $installment->paid_at = $installment->status === 'paid' ? now() : $installment->paid_at;
            $installment->save();

            $applied->push(['installment_id' => $installment->id, 'sequence' => $installment->sequence, 'due_date' => $installment->due_date->toDateString(), 'amount_paise' => $give]);
            $remaining -= $give;
        }

        if ($remaining > 0) {
            // Should never happen: PaymentService checks amount <= outstanding before calling allocate().
            throw new \RuntimeException('Payment amount exceeds the outstanding balance of the chit.');
        }

        return $applied;
    }

    /** Maximum amount that can currently be applied to this chit (its outstanding balance). */
    public function outstandingPaise(Chit $chit): int
    {
        return $chit->outstandingPaise();
    }
}
