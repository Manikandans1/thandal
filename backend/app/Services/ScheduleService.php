<?php

namespace App\Services;

use App\Models\Chit;
use App\Models\ChitInstallment;
use Carbon\Carbon;

/**
 * Builds a chit's repayment schedule. One row per installment, generated once when the
 * chit is created (and regenerated if a Pending chit's terms are edited before it goes Active).
 *
 * Due dates (functional spec §5.3):
 *   daily   -> start_date + (n-1) days
 *   weekly  -> start_date + 7*(n-1) days
 *   monthly -> same day-of-month as start_date, n-1 months later; clamped to the
 *              last day of that month if the day doesn't exist (addMonthsNoOverflow).
 */
class ScheduleService
{
    public function generate(Chit $chit): void
    {
        $chit->installments()->delete();

        $rows = [];
        for ($n = 1; $n <= $chit->installment_count; $n++) {
            $rows[] = [
                'chit_id' => $chit->id,
                'sequence' => $n,
                'due_date' => $chit->dueDateForSequence($n)->toDateString(),
                'amount_paise' => $chit->installment_amount_paise,
                'paid_paise' => 0,
                'status' => 'upcoming',
            ];
        }
        ChitInstallment::insert($rows);

        $chit->end_date = $chit->dueDateForSequence($chit->installment_count);
        $chit->save();
    }

    /** Recompute the derived totals (paid_paise, paid_installments) from the installment rows. Call after any allocation change, inside the same transaction, with the chit row locked. */
    public function recalculateChitTotals(Chit $chit): void
    {
        $chit->loadMissing('installments');
        $chit->paid_paise = (int) $chit->installments->sum('paid_paise');
        $chit->paid_installments = $chit->installments->where('status', 'paid')->count();

        if ($chit->status === 'active' && $chit->paid_paise >= $chit->total_repayment_paise) {
            $chit->status = 'completed';
            $chit->completed_at = Carbon::now('Asia/Kolkata');
        } elseif ($chit->status === 'completed' && $chit->paid_paise < $chit->total_repayment_paise) {
            // A correction reduced a paid chit below its total: it goes back to Active.
            $chit->status = 'active';
            $chit->completed_at = null;
        }

        $chit->save();
    }
}
