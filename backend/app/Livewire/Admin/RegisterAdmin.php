<?php

namespace App\Livewire\Admin;

use App\Services\AdminRegistrationService;
use Livewire\Component;

/** New admins register themselves; a Super Admin must approve before they can log in (functional spec §3.4). */
class RegisterAdmin extends Component
{
    public string $name = '';
    public string $mobile = '';
    public string $pin = '';
    public string $pin_confirmation = '';
    public bool $done = false;

    public function register(AdminRegistrationService $service)
    {
        $data = $this->validate([
            'name' => 'required|string|max:120',
            'mobile' => 'required|digits:10',
            'pin' => 'required|digits:4',
            'pin_confirmation' => 'required|same:pin',
        ]);

        $service->register($data);
        $this->done = true;
    }

    public function render()
    {
        return view('livewire.admin.register-admin')->layout('layouts.guest');
    }
}
