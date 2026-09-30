<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/** Every Razorpay webhook received. event_id is unique so a repeated webhook is a no-op. */
class RazorpayEvent extends Model
{
    const UPDATED_AT = null;

    protected $fillable = ['event_id', 'event_type', 'payment_id', 'payload', 'status', 'processed_at', 'error'];

    protected function casts(): array
    {
        return ['payload' => 'array', 'processed_at' => 'datetime'];
    }
}
