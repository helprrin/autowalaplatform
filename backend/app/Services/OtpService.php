<?php

namespace App\Services;

use App\Models\OtpVerification;
use Twilio\Rest\Client;
use Illuminate\Support\Facades\Log;

class OtpService
{
    protected ?Client $twilio = null;

    public function __construct()
    {
        if (config('services.twilio.sid') && config('services.twilio.token')) {
            $this->twilio = new Client(
                config('services.twilio.sid'),
                config('services.twilio.token')
            );
        }
    }

    public function send(string $phone, string $purpose = 'login'): array
    {
        $otp = OtpVerification::generate($phone, $purpose);

        // Don't send SMS in test mode
        if (config('autowala.otp.test_mode')) {
            return [
                'success' => true,
                'message' => 'OTP sent successfully (test mode)',
                'expires_at' => $otp->expires_at->toIso8601String(),
            ];
        }

        try {
            if ($this->twilio) {
                $this->twilio->messages->create($phone, [
                    'from' => config('services.twilio.from'),
                    'body' => "Your AutoWala verification code is: {$otp->otp_code}. Valid for " . 
                              config('autowala.otp.expiry_minutes') . " minutes.",
                ]);
            }

            return [
                'success' => true,
                'message' => 'OTP sent successfully',
                'expires_at' => $otp->expires_at->toIso8601String(),
            ];
        } catch (\Exception $e) {
            Log::error('OTP send failed', [
                'phone' => $phone,
                'error' => $e->getMessage(),
            ]);

            return [
                'success' => false,
                'message' => 'Failed to send OTP. Please try again.',
            ];
        }
    }

    public function verify(string $phone, string $code): array
    {
        $otp = OtpVerification::forPhone($phone)->valid()->latest('created_at')->first();

        if (!$otp) {
            return [
                'success' => false,
                'message' => 'No valid OTP found. Please request a new one.',
            ];
        }

        if ($otp->isExpired()) {
            return [
                'success' => false,
                'message' => 'OTP has expired. Please request a new one.',
            ];
        }

        if ($otp->isMaxAttemptsReached()) {
            return [
                'success' => false,
                'message' => 'Maximum attempts reached. Please request a new OTP.',
            ];
        }

        if ($otp->verify($code)) {
            return [
                'success' => true,
                'message' => 'OTP verified successfully',
            ];
        }

        $attemptsLeft = config('autowala.otp.max_attempts') - $otp->attempts;
        
        return [
            'success' => false,
            'message' => "Invalid OTP. {$attemptsLeft} attempt(s) remaining.",
            'attempts_left' => $attemptsLeft,
        ];
    }
}
