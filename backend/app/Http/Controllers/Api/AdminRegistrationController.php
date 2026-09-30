<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\AdminRegistrationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/** Super-Admin-only: approve/reject new admin registrations, activate/deactivate admins (functional spec §3.4). */
class AdminRegistrationController extends Controller
{
    public function __construct(protected AdminRegistrationService $registrations) {}

    public function index(Request $request): JsonResponse
    {
        abort_unless($request->user()->isSuperAdmin(), 403);
        $status = $request->get('status', 'pending');

        return response()->json(User::where('role', 'admin')->where('status', $status)->latest()->get());
    }

    public function approve(Request $request, User $pending): JsonResponse
    {
        abort_unless($request->user()->isSuperAdmin(), 403);
        $this->registrations->approve($pending, $request->user(), $request->get('note', ''));

        return response()->json(['ok' => true]);
    }

    public function reject(Request $request, User $pending): JsonResponse
    {
        abort_unless($request->user()->isSuperAdmin(), 403);
        $request->validate(['note' => 'required|string']);
        $this->registrations->reject($pending, $request->user(), $request->note);

        return response()->json(['ok' => true]);
    }

    public function setActive(Request $request, User $admin): JsonResponse
    {
        abort_unless($request->user()->isSuperAdmin(), 403);
        $request->validate(['active' => 'required|boolean']);
        $this->registrations->setActive($admin, (bool) $request->active, $request->user());

        return response()->json(['ok' => true]);
    }
}
