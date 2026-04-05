<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OtpVerification extends Model
{
    use HasFactory, HasUuids;

    protected $keyType = 'string';
    public $incrementing = false;
    public $timestamps = false;

    protected $fillable = [
        'phone',
        'otp_code',
        'purpose',
        'is_verified',
        'attempts',
        'expires_at',
    ];

    protected $hidden = [
        'otp_code',
    ];

    protected $casts = [
        'is_verified' => 'boolean',
        'attempts' => 'integer',
        'expires_at' => 'datetime',
        'created_at' => 'datetime',
    ];

    // Scopes
    public function scopeForPhone($query, string $phone)
    {
        return $query->where('phone', $phone);
    }

    public function scopeValid($query)
    {
        return $query->where('expires_at', '>', now())
                     ->where('is_verified', false);
    }

    // Helpers
    public function isExpired(): bool
    {
        return $this->expires_at->isPast();
    }

    public function isMaxAttemptsReached(): bool
    {
        return $this->attempts >= config('autowala.otp.max_attempts');
    }

    public function verify(string $code): bool
    {
        if ($this->isExpired() || $this->isMaxAttemptsReached()) {
            return false;
        }

        $this->increment('attempts');

        if ($this->otp_code === $code) {
            $this->update(['is_verified' => true]);
            return true;
        }

        return false;
    }

    public static function generate(string $phone, string $purpose = 'login'): self
    {
        // Invalidate any existing OTPs
        static::forPhone($phone)->valid()->delete();

        $isTestMode = config('autowala.otp.test_mode');
        $code = $isTestMode 
            ? config('autowala.otp.test_code') 
            : str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);

        return static::create([
            'phone' => $phone,
            'otp_code' => $code,
            'purpose' => $purpose,
            'expires_at' => now()->addMinutes(config('autowala.otp.expiry_minutes')),
        ]);
    }
}
