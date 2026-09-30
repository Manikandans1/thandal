<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/** Append-only record of a correction applied to a payment. delta_paise is signed. */
class PaymentAdjustment extends Model
{
    const UPDATED_AT = null;

    protected $fillable = ['payment_id', 'correction_request_id', 'type', 'delta_paise', 'created_by', 'reason'];

    public function payment(): BelongsTo
    {
        return $this->belongsTo(Payment::class);
    }

    public function correctionRequest(): BelongsTo
    {
        return $this->belongsTo(CorrectionRequest::class);
    }
}
