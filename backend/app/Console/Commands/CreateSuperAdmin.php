<?php

namespace App\Console\Commands;

use App\Models\User;
use App\Services\PinService;
use Illuminate\Console\Command;

/** Run once during setup: php artisan thandal:create-super-admin */
class CreateSuperAdmin extends Command
{
    protected $signature = 'thandal:create-super-admin {name} {mobile}';
    protected $description = 'Create the first Super Admin account (a temporary PIN is printed once)';

    public function handle(PinService $pins): int
    {
        $mobile = $this->argument('mobile');
        if (User::where('mobile', $mobile)->exists()) {
            $this->error('This mobile number is already used.');

            return self::FAILURE;
        }

        $pin = $pins->generateTemporaryPin();
        User::create([
            'role' => 'super_admin', 'name' => $this->argument('name'), 'mobile' => $mobile,
            'pin_hash' => $pins->hash($pin), 'status' => 'active', 'must_change_pin' => true,
        ]);

        $this->info("Super Admin created. Mobile: {$mobile}");
        $this->warn("Temporary PIN: {$pin}  (shown once — the app will ask for a new PIN on first login)");

        return self::SUCCESS;
    }
}
