<?php

return [
    'default' => env('DB_CONNECTION', 'mysql'),
    'connections' => [
        'mysql' => [
            'driver' => 'mysql',
            'host' => env('DB_HOST', '127.0.0.1'),
            'port' => env('DB_PORT', '3306'),
            'database' => env('DB_DATABASE', 'thandal'),
            'username' => env('DB_USERNAME', 'thandal'),
            'password' => env('DB_PASSWORD', ''),
            'charset' => 'utf8mb4',
            'collation' => 'utf8mb4_unicode_ci',
            'prefix' => '',
            'strict' => true,
            'engine' => 'InnoDB',

            'options' => env('DB_SSL_CA')
                ? [
                    PDO::MYSQL_ATTR_SSL_CA => env('DB_SSL_CA'),
                ]
                : [],
        ],
    ],
    'migrations' => 'migrations',
];
