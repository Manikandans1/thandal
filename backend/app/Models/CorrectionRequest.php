<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/** An agent's request to fix a payment they collected. Approving never edits the original row. */
class CorrectionRequest extends Model
{
    protected $fillable = [
        'code', 'payment_id', 'requested_by_agent_id', 'reason', 'requested_amount_paise',
        'note', 'status', 'resolution_chit_id', 'decided_by', 'decided_at', 'decision_note',
    ];

    protected function casts(): array
    {
        return ['decided_at' => 'datetime'];
    }

    public function payment(): BelongsTo
    {
        return $this->belongsTo(Payment::class);
    }

    public function requestedByAgent(): BelongsTo
    {
        return $this->belongsTo(Agent::class, 'requested_by_agent_id');
    }

    public function resolutionChit(): BelongsTo
    {
        return $this->belongsTo(Chit::class, 'resolution_chit_id');
    }
}
