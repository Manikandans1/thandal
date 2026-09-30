<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

/** Agent profile. Visible customers = customers whose CURRENT agent_id is this agent. */
class Agent extends Model
{
    use HasFactory;

    protected $fillable = ['user_id', 'agent_code', 'address', 'joined_on'];

    protected function casts(): array
    {
        return ['joined_on' => 'date'];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function customers(): HasMany
    {
        return $this->hasMany(Customer::class);
    }

    public function currentIdentityDocument(): HasOne
    {
        return $this->hasOne(IdentityDocument::class)->where('is_current', true);
    }
}
