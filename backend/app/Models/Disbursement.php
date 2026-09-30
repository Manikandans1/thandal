<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/** The loan amount given to the customer. A chit becomes Active only after a status=completed row exists. */
class Disbursement extends Model
{
    const UPDATED_AT = null;

    protected $fillable = ['chit_id', 'method', 'amount_paise', 'status', 'disbursed_on', 'reference', 'note', 'recorded_by'];

    protected function casts(): array
    {
        return ['disbursed_on' => 'date'];
    }

    public function chit(): BelongsTo
    {
        return $this->belongsTo(Chit::class);
    }
}
