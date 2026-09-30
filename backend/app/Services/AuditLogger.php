<?php

namespace App\Services;

use App\Models\AuditLog;
use App\Models\User;
use Illuminate\Support\Facades\Request;

/** Writes an append-only audit trail entry. Call this from services, not controllers, so nothing is missed. */
class AuditLogger
{
    public function log(?User $actor, string $action, string $entityType, string $entityId, string $summary, ?array $before = null, ?array $after = null): void
    {
        AuditLog::create([
            'actor_user_id' => $actor?->id,
            'actor_label' => $actor ? "{$actor->name} ({$this->roleCode($actor)})" : 'System',
            'action' => $action,
            'entity_type' => $entityType,
            'entity_id' => $entityId,
            'summary' => $summary,
            'before_json' => $before,
            'after_json' => $after,
            'ip_address' => Request::ip(),
            'user_agent' => substr((string) Request::header('User-Agent'), 0, 255),
        ]);
    }

    protected function roleCode(User $u): string
    {
        return match ($u->role) {
            'customer' => $u->customer?->customer_code ?? 'customer',
            'agent' => $u->agent?->agent_code ?? 'agent',
            default => 'admin',
        };
    }
}
