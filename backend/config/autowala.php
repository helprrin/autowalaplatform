<?php

return [
    /*
    |--------------------------------------------------------------------------
    | AutoWala Application Settings
    |--------------------------------------------------------------------------
    */

    'otp' => [
        'expiry_minutes' => env('OTP_EXPIRY_MINUTES', 5),
        'max_attempts' => env('MAX_OTP_ATTEMPTS', 3),
        'length' => 6,
        'test_mode' => env('OTP_TEST_MODE', false),
        'test_code' => '123456',
    ],

    'location' => [
        'nearby_radius_meters' => env('NEARBY_RADIUS_METERS', 5000),
        'update_interval_seconds' => env('LOCATION_UPDATE_INTERVAL', 5),
        'stale_threshold_minutes' => 10,
    ],

    'rider' => [
        'required_documents' => [
            'aadhar_front',
            'aadhar_back',
            'license_front',
            'license_back',
            'vehicle_rc',
            'selfie',
        ],
        'optional_documents' => [
            'vehicle_permit',
            'vehicle_insurance',
        ],
    ],

    'storage' => [
        'documents_bucket' => env('SUPABASE_BUCKET', 'documents'),
        'max_file_size_mb' => 5,
        'allowed_mimes' => ['image/jpeg', 'image/png', 'image/webp', 'application/pdf'],
    ],

    'rating' => [
        'min' => 1,
        'max' => 5,
        'default' => 5.0,
    ],

    'sos' => [
        'numbers' => ['112', '100'],
        'support_phone' => env('SUPPORT_PHONE', '+919999999999'),
        'support_email' => env('SUPPORT_EMAIL', 'support@autowala.in'),
    ],

    'app_version' => [
        'min_user' => '1.0.0',
        'min_rider' => '1.0.0',
    ],
];
