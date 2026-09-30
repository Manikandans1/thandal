<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/** Append-only. Written by App\Services\AuditLogger, never updated. */
class AuditLog extends Model
{
    const UPDATED_AT = null;

    protected $fillable = [
        'actor_user_id', 'actor_label', 'action', 'entity_type', 'entity_id',
        'summary', 'before_json', 'after_json', 'ip_address', 'user_agent',
    ];

    protected function casts(): array
    {
        return ['before_json' => 'array', 'after_json' => 'array'];
    }
}
