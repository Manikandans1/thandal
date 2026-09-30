<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

/** Customer profile. agent_id is the CURRENT agent; agent_assignments keeps history. */
class Customer extends Model
{
    use HasFactory;

    protected $fillable = ['user_id', 'customer_code', 'address', 'agent_id', 'joined_on', 'created_by'];

    protected function casts(): array
    {
        return ['joined_on' => 'date'];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function agent(): BelongsTo
    {
        return $this->belongsTo(Agent::class);
    }

    public function chits(): HasMany
    {
        return $this->hasMany(Chit::class);
    }

    public function activeChits(): HasMany
    {
        return $this->chits()->where('status', 'active');
    }

    public function payments(): HasMany
    {
        return $this->hasMany(Payment::class);
    }

    public function assignments(): HasMany
    {
        return $this->hasMany(AgentAssignment::class)->orderByDesc('assigned_on');
    }

    public function currentIdentityDocument(): HasOne
    {
        return $this->hasOne(IdentityDocument::class)->where('is_current', true);
    }

    /** Sum of outstanding across active chits, in paise. Loads activeChits.installments if not already loaded. */
    public function outstandingPaise(): int
    {
        return $this->activeChits->sum(fn (Chit $c) => $c->outstandingPaise());
    }

    public function overduePaise(): int
    {
        return $this->activeChits->sum(fn (Chit $c) => $c->overduePaise());
    }
}
