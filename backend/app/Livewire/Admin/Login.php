<?php

namespace App\Livewire\Admin;

use App\Models\User;
use App\Services\PinService;
use Livewire\Component;

/** Same login rules as the mobile API (functional spec §3.1): mobile number + PIN, 3 attempts, 15-minute lock. */
class Login extends Component
{
    public string $mobile = '';
    public string $pin = '';
    public ?string $error = null;

    public function login(PinService $pins)
    {
        $this->error = null;
        $this->validate(['mobile' => 'required|digits:10', 'pin' => 'required|digits:4']);

        $user = User::where('mobile', $this->mobile)->first();
        if (! $user || ! in_array($user->role, ['admin', 'super_admin'], true)) {
            $this->error = 'Mobile number or PIN is incorrect.';

            return;
        }
        if ($user->status === 'pending') {
            $this->error = 'Your registration is waiting for approval by a Super Admin.';

            return;
        }
        if ($user->status !== 'active') {
            $this->error = 'This account is inactive. Contact the Super Admin.';

            return;
        }

        $result = $pins->attemptLogin($user, $this->pin);
        if (! $result['ok']) {
            $this->error = $result['message'];

            return;
        }

        auth('web')->login($user);
        session()->regenerate();
        $this->redirect(route('dashboard'), navigate: false);
    }

    public function render()
    {
        return view('livewire.admin.login')->layout('layouts.guest');
    }
}
