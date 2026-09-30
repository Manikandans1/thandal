<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

/**
 * The login identity for every role. See docs/02-database-design.md.
 *
 * @property string $role customer|agent|admin|super_admin
 * @property string $mobile 10-digit, unique across every role
 * @property string $status pending|active|inactive|rejected
 */
class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'role', 'name', 'mobile', 'pin_hash', 'status', 'must_change_pin',
        'failed_attempts', 'locked_until', 'last_login_at',
        'decided_by', 'decided_at', 'decision_note', 'created_by',
    ];

    protected $hidden = ['pin_hash'];

    protected function casts(): array
    {
        return [
            'must_change_pin' => 'boolean',
            'locked_until' => 'datetime',
            'last_login_at' => 'datetime',
            'decided_at' => 'datetime',
        ];
    }

    public function agent(): \Illuminate\Database\Eloquent\Relations\HasOne
    {
        return $this->hasOne(Agent::class);
    }

    public function customer(): \Illuminate\Database\Eloquent\Relations\HasOne
    {
        return $this->hasOne(Customer::class);
    }

    public function isLocked(): bool
    {
        return $this->locked_until !== null && $this->locked_until->isFuture();
    }

    public function isSuperAdmin(): bool
    {
        return $this->role === 'super_admin';
    }

    public function isAdmin(): bool
    {
        return in_array($this->role, ['admin', 'super_admin'], true);
    }
}
