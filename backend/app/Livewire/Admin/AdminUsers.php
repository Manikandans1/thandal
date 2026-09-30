<?php

namespace App\Livewire\Admin;

use App\Models\User;
use App\Services\AdminRegistrationService;
use Livewire\Component;

/** Super-Admin-only (functional spec §3.4): approve/reject registrations, activate/deactivate admins. */
class AdminUsers extends Component
{
    public string $tab = 'admins';
    public string $reqStatus = 'pending';

    public function approve(int $id, AdminRegistrationService $service)
    {
        abort_unless(auth()->user()->isSuperAdmin(), 403);
        $service->approve(User::findOrFail($id), auth()->user(), 'Approved.');
    }

    public function reject(int $id, AdminRegistrationService $service)
    {
        abort_unless(auth()->user()->isSuperAdmin(), 403);
        $service->reject(User::findOrFail($id), auth()->user(), request('note', 'Rejected.'));
    }

    public function toggle(int $id, AdminRegistrationService $service)
    {
        abort_unless(auth()->user()->isSuperAdmin(), 403);
        $admin = User::findOrFail($id);
        $service->setActive($admin, $admin->status !== 'active', auth()->user());
    }

    public function render()
    {
        return view('livewire.admin.admin-users', [
            'admins' => User::where('role', 'admin')->where('status', '!=', 'pending')->where('status', '!=', 'rejected')->get(),
            'requests' => User::where('role', 'admin')->where('status', $this->reqStatus)->latest()->get(),
        ])->layout('layouts.admin');
    }
}
