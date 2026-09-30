<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/** History of which agent looked after a customer. A row is never edited once superseded. */
class AgentAssignment extends Model
{
    public $timestamps = false;

    protected $fillable = ['customer_id', 'agent_id', 'assigned_by', 'assigned_on', 'ended_on', 'reason', 'active_customer_id'];

    protected function casts(): array
    {
        return ['assigned_on' => 'date', 'ended_on' => 'date'];
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function agent(): BelongsTo
    {
        return $this->belongsTo(Agent::class);
    }
}
