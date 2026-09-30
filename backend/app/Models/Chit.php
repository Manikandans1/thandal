<?php

namespace App\Models;

use Carbon\Carbon;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

/**
 * A loan and its repayment plan.
 * total_repayment_paise = installment_amount_paise * installment_count (DB-enforced, see chk_chits_total).
 * There is NO interest and NO penalty anywhere in this system.
 */
class Chit extends Model
{
    use HasFactory;

    protected $fillable = [
        'chit_code', 'customer_id', 'created_by', 'loan_amount_paise', 'frequency',
        'installment_count', 'installment_amount_paise', 'total_repayment_paise',
        'paid_paise', 'paid_installments', 'start_date', 'end_date', 'status',
        'activated_at', 'completed_at', 'cancelled_at', 'cancel_reason', 'notes',
    ];

    protected function casts(): array
    {
        return [
            'start_date' => 'date', 'end_date' => 'date',
            'activated_at' => 'datetime', 'completed_at' => 'datetime', 'cancelled_at' => 'datetime',
        ];
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function installments(): HasMany
    {
        return $this->hasMany(ChitInstallment::class)->orderBy('sequence');
    }

    public function payments(): HasMany
    {
        return $this->hasMany(Payment::class);
    }

    public function disbursement(): HasOne
    {
        return $this->hasOne(Disbursement::class)->latestOfMany();
    }

    public function completedDisbursement(): HasOne
    {
        return $this->hasOne(Disbursement::class)->where('status', 'completed');
    }

    public function isActive(): bool
    {
        return $this->status === 'active';
    }

    public function outstandingPaise(): int
    {
        if (! $this->isActive()) {
            return 0;
        }

        return max(0, $this->total_repayment_paise - $this->paid_paise);
    }

    /** Sum of the remaining amount on every OVERDUE installment (due date before today IST, not fully paid). */
    public function overduePaise(): int
    {
        if (! $this->isActive()) {
            return 0;
        }
        $today = Carbon::now('Asia/Kolkata')->toDateString();

        return $this->installments
            ->filter(fn (ChitInstallment $i) => $i->due_date->toDateString() < $today && $i->status !== 'paid' && $i->status !== 'cancelled')
            ->sum(fn (ChitInstallment $i) => $i->amount_paise - $i->paid_paise);
    }

    /** The due date of installment #n, given the frequency. Monthly clamps to the last day of the month. */
    public function dueDateForSequence(int $sequence): Carbon
    {
        $n = $sequence - 1;

        return match ($this->frequency) {
            'daily' => $this->start_date->copy()->addDays($n),
            'weekly' => $this->start_date->copy()->addDays(7 * $n),
            'monthly' => $this->start_date->copy()->addMonthsNoOverflow($n),
            default => throw new \InvalidArgumentException("Unknown frequency {$this->frequency}"),
        };
    }

    public function unitLabel(bool $plural = true): string
    {
        $u = match ($this->frequency) { 'daily' => 'day', 'weekly' => 'week', 'monthly' => 'month' };

        return $plural ? $u.'s' : $u;
    }
}
