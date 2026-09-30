<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * How a payment was applied to one installment. SIGNED: a reversal is a negative row
 * linked to a payment_adjustments row. The installment's paid total = SUM(amount_paise).
 */
class PaymentAllocation extends Model
{
    public $timestamps = false;

    protected $fillable = ['payment_id', 'installment_id', 'amount_paise', 'adjustment_id'];

    public function payment(): BelongsTo
    {
        return $this->belongsTo(Payment::class);
    }

    public function installment(): BelongsTo
    {
        return $this->belongsTo(ChitInstallment::class, 'installment_id');
    }
}
