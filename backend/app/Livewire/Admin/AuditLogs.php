<?php

namespace App\Livewire\Admin;

use App\Models\AuditLog;
use Livewire\Component;
use Livewire\WithPagination;

class AuditLogs extends Component
{
    use WithPagination;

    public string $q = '';

    public function render()
    {
        $logs = AuditLog::query()
            ->when($this->q, fn ($qq) => $qq->where('entity_id', 'like', "%{$this->q}%")->orWhere('summary', 'like', "%{$this->q}%"))
            ->latest()->paginate(20);

        return view('livewire.admin.audit-logs', compact('logs'))->layout('layouts.admin');
    }
}
