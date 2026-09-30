<?php

namespace App\Services;

use App\Models\Chit;
use App\Models\Customer;
use App\Models\Disbursement;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Create, edit, disburse and cancel chits. Total repayment = installment_amount * installment_count
 * (functional spec §5.2) — there is no interest and no lump-sum loan repayment.
 */
class ChitService
{
    public function __construct(
        protected SequenceService $sequences,
        protected ScheduleService $schedule,
        protected AuditLogger $audit,
    ) {}

    /**
     * @param array{customer_id:int, loan_amount_paise:int, frequency:string, installment_count:int, installment_amount_paise:int, start_date:string, notes?:string} $data
     */
    public function create(array $data, User $actor): Chit
    {
        $this->validateTerms($data);

        return DB::transaction(function () use ($data, $actor) {
            $chit = Chit::create([
                'chit_code' => $this->sequences->nextChitCode(),
                'customer_id' => $data['customer_id'],
                'created_by' => $actor->id,
                'loan_amount_paise' => $data['loan_amount_paise'],
                'frequency' => $data['frequency'],
                'installment_count' => $data['installment_count'],
                'installment_amount_paise' => $data['installment_amount_paise'],
                'total_repayment_paise' => $data['installment_amount_paise'] * $data['installment_count'],
                'start_date' => $data['start_date'],
                'end_date' => $data['start_date'], // recomputed by ScheduleService::generate()
                'status' => 'pending',
                'notes' => $data['notes'] ?? null,
            ]);

            $this->schedule->generate($chit);

            $this->audit->log($actor, 'chit_created', 'chit', $chit->chit_code,
                "Loan ".rupees($chit->loan_amount_paise)." · ".rupees($chit->installment_amount_paise)." every {$chit->unitLabel(false)} · {$chit->installment_count} {$chit->unitLabel()} · total ".rupees($chit->total_repayment_paise));

            return $chit->fresh();
        });
    }

    protected function validateTerms(array $data): void
    {
        $errors = [];
        if (($data['loan_amount_paise'] ?? 0) <= 0) {
            $errors['loan_amount'] = 'Enter the loan amount.';
        }
        if (! in_array($data['frequency'] ?? null, ['daily', 'weekly', 'monthly'], true)) {
            $errors['frequency'] = 'Choose Daily, Weekly or Monthly.';
        }
        if (($data['installment_count'] ?? 0) <= 0) {
            $errors['installment_count'] = 'Enter the number of installments.';
        }
        if (($data['installment_amount_paise'] ?? 0) <= 0) {
            $errors['installment_amount'] = 'Enter the installment amount.';
        }
        if (empty($data['start_date'])) {
            $errors['start_date'] = 'Choose a start date.';
        }
        $customer = Customer::find($data['customer_id'] ?? null);
        if (! $customer) {
            $errors['customer_id'] = 'Select a customer.';
        }
        if ($errors) {
            throw ValidationException::withMessages($errors);
        }
    }

    public function recordDisbursement(Chit $chit, array $data, User $actor): Disbursement
    {
        return DB::transaction(function () use ($chit, $data, $actor) {
            if ($data['method'] === 'bank_transfer' && empty($data['reference'])) {
                throw ValidationException::withMessages(['reference' => 'Reference number is required for bank transfers.']);
            }

            $disb = Disbursement::create([
                'chit_id' => $chit->id,
                'method' => $data['method'],
                'amount_paise' => $chit->loan_amount_paise,
                'status' => $data['status'],
                'disbursed_on' => $data['disbursed_on'] ?? now()->toDateString(),
                'reference' => $data['reference'] ?? null,
                'note' => $data['note'] ?? null,
                'recorded_by' => $actor->id,
            ]);

            if ($data['status'] === 'completed') {
                $chit->status = 'active';
                $chit->activated_at = now();
                $chit->save();
                $this->audit->log($actor, 'disbursement_recorded', 'chit', $chit->chit_code,
                    ucfirst($data['method']).' '.rupees($chit->loan_amount_paise).' · chit is now Active');
            } else {
                $this->audit->log($actor, 'disbursement_failed', 'chit', $chit->chit_code, $data['note'] ?? 'Disbursement attempt failed');
            }

            return $disb;
        });
    }

    public function cancel(Chit $chit, string $reason, User $actor): Chit
    {
        return DB::transaction(function () use ($chit, $reason, $actor) {
            if (! in_array($chit->status, ['pending', 'active'], true)) {
                throw ValidationException::withMessages(['status' => 'Only a pending or active chit can be cancelled.']);
            }
            $chit->installments()->whereIn('status', ['upcoming', 'partially_paid'])->update(['status' => 'cancelled']);
            $chit->status = 'cancelled';
            $chit->cancelled_at = now();
            $chit->cancel_reason = $reason;
            $chit->save();

            $this->audit->log($actor, 'chit_cancelled', 'chit', $chit->chit_code, $reason);

            return $chit;
        });
    }
}
