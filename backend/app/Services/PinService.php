<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

/**
 * PIN rules (functional spec §3.2): 4 digits, never a weak PIN, hashed only,
 * 3 wrong attempts locks the account for 15 minutes.
 */
class PinService
{
    public function validateNewPin(string $pin, ?string $mustDifferFromHash = null): ?string
    {
        if (! preg_match('/^\d{4}$/', $pin)) {
            return 'PIN must be exactly 4 digits.';
        }
        if (in_array($pin, config('thandal.pin.weak_pins'), true)) {
            return 'Choose a PIN that is harder to guess.';
        }
        if ($mustDifferFromHash && Hash::check($pin, $mustDifferFromHash)) {
            return 'New PIN must be different from the current PIN.';
        }

        return null;
    }

    public function hash(string $pin): string
    {
        return Hash::make($pin);
    }

    public function generateTemporaryPin(): string
    {
        // Avoid weak PINs even when generated randomly.
        do {
            $pin = (string) random_int(1000, 9999);
        } while (in_array($pin, config('thandal.pin.weak_pins'), true));

        return $pin;
    }

    /** @return array{ok:bool, message:?string, attemptsLeft:?int} */
    public function attemptLogin(User $user, string $pin): array
    {
        if ($user->isLocked()) {
            $minutes = now()->diffInMinutes($user->locked_until) + 1;

            return ['ok' => false, 'message' => "Too many attempts. Try again in {$minutes} minute(s).", 'attemptsLeft' => 0];
        }

        if (Hash::check($pin, $user->pin_hash)) {
            $user->failed_attempts = 0;
            $user->locked_until = null;
            $user->last_login_at = now();
            $user->save();

            return ['ok' => true, 'message' => null, 'attemptsLeft' => null];
        }

        $user->failed_attempts++;
        $max = config('thandal.pin.max_attempts');

        if ($user->failed_attempts >= $max) {
            $user->locked_until = now()->addMinutes(config('thandal.pin.lock_minutes'));
            $user->failed_attempts = 0;
            $user->save();

            return ['ok' => false, 'message' => 'Too many attempts. Try again in '.config('thandal.pin.lock_minutes').' minutes.', 'attemptsLeft' => 0];
        }

        $user->save();
        $left = $max - $user->failed_attempts;

        return ['ok' => false, 'message' => "Mobile number or PIN is incorrect. {$left} attempt(s) left.", 'attemptsLeft' => $left];
    }

    public function newApiToken(User $user): string
    {
        $user->tokens()->delete();

        return $user->createToken('thandal-app', ['*'], now()->addDays((int) env('SANCTUM_TOKEN_EXPIRATION_DAYS', 30)))->plainTextToken;
    }
}
