<?php

use App\Http\Middleware\EnsureRole;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware) {
        $middleware->alias([
            'role' => EnsureRole::class,
            'role.web' => \App\Http\Middleware\EnsureWebRole::class,
        ]);
       // $middleware->api(prepend: [\Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful::class]);
       $middleware->api();
    })
    ->withExceptions(function (Exceptions $exceptions) {
        //
    })->create();
