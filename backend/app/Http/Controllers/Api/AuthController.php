<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\LoginRequest;
use App\Http\Requests\Auth\RegisterAdminRequest;
use App\Http\Requests\Auth\SetNewPinRequest;
use App\Models\User;
use App\Services\AdminRegistrationService;
use App\Services\PinService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

/**
 * One login for every role (functional spec §3.1). The account's role decides which
 * side of the app opens; the server never trusts a role claimed by the client.
 */
class AuthController extends Controller
{
    public function __construct(protected PinService $pins, protected AdminRegistrationService $registrations) {}

    public function login(LoginRequest $request): JsonResponse
    {
        $user = User::where('mobile', $request->mobile)->first();

        if (! $user) {
            return response()->json(['message' => 'Mobile number or PIN is incorrect.'], 422);
        }

        if ($user->status === 'pending') {
            return response()->json(['message' => 'Your registration is waiting for approval by a Super Admin.'], 403);
        }
        if ($user->status === 'rejected') {
            return response()->json(['message' => 'Your registration was not approved. Contact the Super Admin.'], 403);
        }
        if ($user->status === 'inactive') {
            return response()->json(['message' => 'This account is inactive. Contact Thandal.'], 403);
        }

        $result = $this->pins->attemptLogin($user, $request->pin);
        if (! $result['ok']) {
            return response()->json(['message' => $result['message'], 'attempts_left' => $result['attemptsLeft']], 422);
        }

        return response()->json([
            'token' => $this->pins->newApiToken($user),
            'must_change_pin' => $user->must_change_pin,
            'user' => new \App\Http\Resources\UserResource($user),
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['ok' => true]);
    }

    public function setNewPin(SetNewPinRequest $request): JsonResponse
    {
        $user = User::where('mobile', $request->mobile)->first();
        if (! $user || ! \Illuminate\Support\Facades\Hash::check($request->temporary_pin, $user->pin_hash)) {
            throw ValidationException::withMessages(['temporary_pin' => 'Temporary PIN is incorrect.']);
        }
        if ($err = $this->pins->validateNewPin($request->pin, $user->pin_hash)) {
            throw ValidationException::withMessages(['pin' => $err]);
        }

        $user->pin_hash = $this->pins->hash($request->pin);
        $user->must_change_pin = false;
        $user->save();

        return response()->json(['ok' => true]);
    }

    public function changePin(Request $request): JsonResponse
    {
        $request->validate(['current_pin' => 'required|digits:4', 'pin' => 'required|digits:4', 'pin_confirmation' => 'required|same:pin']);
        $user = $request->user();
        if (! \Illuminate\Support\Facades\Hash::check($request->current_pin, $user->pin_hash)) {
            throw ValidationException::withMessages(['current_pin' => 'Current PIN is incorrect.']);
        }
        if ($err = $this->pins->validateNewPin($request->pin, $user->pin_hash)) {
            throw ValidationException::withMessages(['pin' => $err]);
        }
        $user->pin_hash = $this->pins->hash($request->pin);
        $user->save();

        return response()->json(['ok' => true]);
    }

    public function registerAdmin(RegisterAdminRequest $request): JsonResponse
    {
        $user = $this->registrations->register($request->validated());

        return response()->json(['id' => $user->id, 'status' => $user->status], 201);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json(new \App\Http\Resources\UserResource($request->user()));
    }
}
