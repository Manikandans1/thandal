<?php

return [
    // Business rules that are safe to tune from config instead of code.
    'support_phone' => env('THANDAL_SUPPORT_PHONE', '+91 44 5555 0142'),
    'support_hours' => env('THANDAL_SUPPORT_HOURS', 'Mon-Sat, 9:30 am - 6:00 pm'),
    'receipt_prefix' => env('THANDAL_RECEIPT_PREFIX', 'THD-RCP'),

    'pin' => [
        'max_attempts' => (int) env('THANDAL_PIN_MAX_ATTEMPTS', 3),
        'lock_minutes' => (int) env('THANDAL_PIN_LOCK_MINUTES', 15),
        'weak_pins' => ['0000', '1111', '1234', '1212', '0001'],
    ],

    'ids' => [
        'customer_prefix' => 'THD-1',
        'customer_start'  => 10001,
        'chit_prefix'     => 'THD-',
        'chit_start'      => 1001,
        'agent_prefix'    => 'AGT-',
        'agent_start'     => 1,
        'correction_prefix' => 'CR-',
        'correction_start'  => 1,
    ],

    'document_types' => [
        'aadhaar_card'    => 'Aadhaar card',
        'pan_card'        => 'PAN card',
        'voter_id'        => 'Voter ID',
        'driving_licence' => 'Driving licence',
        'passport'        => 'Passport',
        'ration_card'     => 'Ration card',
    ],

    'razorpay_reconcile_after_minutes' => 30,
];
