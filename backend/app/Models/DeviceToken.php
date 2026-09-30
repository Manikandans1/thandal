<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/** Push notification tokens. Not used in V1 — kept so push can be added without a schema change. */
class DeviceToken extends Model
{
    protected $fillable = ['user_id', 'token', 'platform', 'last_seen_at'];

    protected function casts(): array
    {
        return ['last_seen_at' => 'datetime'];
    }
}
