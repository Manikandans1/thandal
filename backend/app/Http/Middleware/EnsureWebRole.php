<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/** Same idea as EnsureRole but for the session-based admin web panel. */
class EnsureWebRole
{
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $user = $request->user('web');
        $ok = $user && $user->status === 'active' && (
            in_array($user->role, $roles, true) || (in_array('admin', $roles, true) && $user->role === 'super_admin')
        );
        abort_unless($ok, 403);

        return $next($request);
    }
}
