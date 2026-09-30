<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Route middleware: role:customer / role:agent / role:admin (admin also matches super_admin).
 * Every API route that touches money or people MUST be behind this — the app's claimed role is never trusted alone.
 */
class EnsureRole
{
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $user = $request->user();
        if (! $user || $user->status !== 'active') {
            abort(403, 'Not authorised.');
        }
        $ok = in_array($user->role, $roles, true)
            || (in_array('admin', $roles, true) && $user->role === 'super_admin');
        if (! $ok) {
            abort(403, 'Not authorised.');
        }

        return $next($request);
    }
}
