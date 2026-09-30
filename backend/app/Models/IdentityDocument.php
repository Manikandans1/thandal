<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Crypt;

/**
 * ID proof of a customer OR an agent (exactly one, enforced by a DB check).
 * The number is encrypted at rest; only the last 4 digits are ever shown in the UI.
 */
class IdentityDocument extends Model
{
    protected $fillable = [
        'customer_id', 'agent_id', 'doc_type', 'number_encrypted', 'number_last4',
        'file_path', 'file_mime', 'file_size_bytes', 'is_current', 'uploaded_by',
    ];

    protected $hidden = ['number_encrypted', 'file_path'];

    protected function casts(): array
    {
        return ['is_current' => 'boolean'];
    }

    public static function encryptNumber(string $plain): string
    {
        return Crypt::encryptString($plain);
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function agent(): BelongsTo
    {
        return $this->belongsTo(Agent::class);
    }

    public function typeLabel(): string
    {
        return config('thandal.document_types')[$this->doc_type] ?? $this->doc_type;
    }
}
