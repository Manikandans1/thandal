<?php

return [
    'default' => 'local',
    'disks' => [
        'local' => ['driver' => 'local', 'root' => storage_path('app/private'), 'serve' => true, 'throw' => false],
        'public' => ['driver' => 'local', 'root' => storage_path('app/public'), 'url' => env('APP_URL').'/storage', 'visibility' => 'public', 'throw' => false],
        // ID proof photos (functional spec §4.3) — never publicly reachable.
        'private' => ['driver' => 'local', 'root' => storage_path('app/private'), 'visibility' => 'private', 'throw' => false],
    ],
    'links' => [public_path('storage') => storage_path('app/public')],
];
