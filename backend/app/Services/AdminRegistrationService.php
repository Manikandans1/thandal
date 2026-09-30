<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * New admins register themselves on the web login. They cannot do anything until a
 * Super Admin approves them (functional spec §3.4). Approved admins can do everything
 * except manage other admins, which stays with the Super Admin.
 */
class AdminRegistrationService
{
    public function __construct(protected PinService $pins, protected AuditLogger $audit) {}

    public function register(array $data): User
    {
        if (User::where('mobile', $data['mobile'])->exists()) {
            throw ValidationException::withMessages(['mobile' => 'This mobile number is already used.']);
        }
        $err = $this->pins->validateNewPin($data['pin']);
        if ($err) {
            throw ValidationException::withMessages(['pin' => $err]);
        }
        if ($data['pin'] !== $data['pin_confirmation']) {
            throw ValidationException::withMessages(['pin_confirmation' => "The two PINs don't match."]);
        }

        $user = User::create([
            'role' => 'admin', 'name' => $data['name'], 'mobile' => $data['mobile'],
            'pin_hash' => $this->pins->hash($data['pin']), 'status' => 'pending',
        ]);

        $this->audit->log($user, 'admin_registration_requested', 'user', (string) $user->id, "{$user->name} asked for admin access");

        return $user;
    }

    public function approve(User $pending, User $superAdmin, string $note): User
    {
        return DB::transaction(function () use ($pending, $superAdmin, $note) {
            $pending->status = 'active';
            $pending->decided_by = $superAdmin->id;
            $pending->decided_at = now();
            $pending->decision_note = $note ?: 'Approved.';
            $pending->save();

            $this->audit->log($superAdmin, 'admin_approved', 'user', (string) $pending->id, "{$pending->name} can now log in as admin");

            return $pending;
        });
    }

    public function reject(User $pending, User $superAdmin, string $note): User
    {
        if (trim($note) === '') {
            throw ValidationException::withMessages(['note' => 'A note is required to reject.']);
        }
        $pending->status = 'rejected';
        $pending->decided_by = $superAdmin->id;
        $pending->decided_at = now();
        $pending->decision_note = $note;
        $pending->save();

        $this->audit->log($superAdmin, 'admin_rejected', 'user', (string) $pending->id, $note);

        return $pending;
    }

    public function setActive(User $admin, bool $active, User $superAdmin): void
    {
        if ($admin->role === 'super_admin') {
            throw ValidationException::withMessages(['user' => 'The Super Admin cannot be deactivated.']);
        }
        $admin->status = $active ? 'active' : 'inactive';
        $admin->save();
        $this->audit->log($superAdmin, $active ? 'admin_activated' : 'admin_deactivated', 'user', (string) $admin->id, 'Status changed');
    }
}
