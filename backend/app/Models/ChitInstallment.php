<?php

namespace App\Models;

use Carbon\Carbon;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * One row per due date in a chit's schedule.
 * "Overdue" is NEVER stored — it is derived (due_date < today and not fully paid).
 */
class ChitInstallment extends Model
{
    public $timestamps = false;

    protected $fillable = ['chit_id', 'sequence', 'due_date', 'amount_paise', 'paid_paise', 'status', 'paid_at'];

    protected function casts(): array
    {
        return ['due_date' => 'date', 'paid_at' => 'datetime'];
    }

    public function chit(): BelongsTo
    {
        return $this->belongsTo(Chit::class);
    }

    public function allocations(): HasMany
    {
        return $this->hasMany(PaymentAllocation::class, 'installment_id');
    }

    public function remainingPaise(): int
    {
        return max(0, $this->amount_paise - $this->paid_paise);
    }

    /** Computed display status: upcoming | due_today | overdue | partially_paid | paid | cancelled. */
    public function displayStatus(): string
    {
        if ($this->status === 'cancelled') {
            return 'cancelled';
        }
        if ($this->status === 'paid') {
            return 'paid';
        }
        $today = Carbon::now('Asia/Kolkata')->toDateString();
        $due = $this->due_date->toDateString();
        if ($this->paid_paise > 0 && $this->paid_paise < $this->amount_paise) {
            return $due < $today ? 'overdue' : ($due === $today ? 'due_today' : 'partially_paid');
        }
        if ($due < $today) {
            return 'overdue';
        }
        if ($due === $today) {
            return 'due_today';
        }

        return 'upcoming';
    }
}
