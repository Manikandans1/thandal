<?php

return [
    'driver' => env('SESSION_DRIVER', 'database'),
    'lifetime' => (int) env('SESSION_LIFETIME', 30), // 30 minutes idle timeout for the admin web panel (functional spec §3.3)
    'expire_on_close' => false,
    'encrypt' => true,
    'table' => 'sessions',
    'connection' => null,
    'cookie' => 'thandal_session',
    'path' => '/',
    'same_site' => 'lax',
    'http_only' => true,
    'secure' => env('APP_ENV') === 'production',
];
