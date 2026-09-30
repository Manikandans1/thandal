<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * One row per money received (cash or online). CONFIRMED rows are never edited or deleted;
 * fixes are new payment_adjustments + payment_allocations rows (see CorrectionService).
 */
class Payment extends Model
{
    protected $fillable = [
        'receipt_number', 'chit_id', 'customer_id', 'method', 'status', 'amount_paise', 'net_amount_paise',
        'paid_at', 'collected_by_agent_id', 'recorded_by', 'razorpay_order_id', 'razorpay_payment_id',
        'failure_reason', 'client_request_id', 'notes',
    ];

    protected function casts(): array
    {
        return ['paid_at' => 'datetime'];
    }

    public function chit(): BelongsTo
    {
        return $this->belongsTo(Chit::class);
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function collectedByAgent(): BelongsTo
    {
        return $this->belongsTo(Agent::class, 'collected_by_agent_id');
    }

    public function allocations(): HasMany
    {
        return $this->hasMany(PaymentAllocation::class);
    }

    public function adjustments(): HasMany
    {
        return $this->hasMany(PaymentAdjustment::class);
    }

    public function correctionRequests(): HasMany
    {
        return $this->hasMany(CorrectionRequest::class);
    }

    /** The amount that actually counts today: the original amount, unless a correction changed it. */
    public function effectiveAmountPaise(): int
    {
        return $this->net_amount_paise ?? $this->amount_paise;
    }
}
