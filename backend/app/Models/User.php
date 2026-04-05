<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, HasUuids, Notifiable;

    protected $keyType = 'string';
    public $incrementing = false;

    protected $fillable = [
        'phone',
        'name',
        'email',
        'avatar_url',
        'status',
        'last_location',
        'last_location_updated_at',
        'device_token',
        'device_type',
        'app_version',
    ];

    protected $hidden = [
        'device_token',
    ];

    protected $casts = [
        'last_location_updated_at' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // Relationships
    public function rideLogs()
    {
        return $this->hasMany(RideLog::class);
    }

    public function ratings()
    {
        return $this->hasMany(Rating::class);
    }

    public function complaints()
    {
        return $this->hasMany(Complaint::class, 'complainant_user_id');
    }

    public function notifications()
    {
        return $this->hasMany(Notification::class);
    }

    // Scopes
    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }

    // Helpers
    public function updateLocation(float $lat, float $lng): void
    {
        $this->update([
            'last_location' => \DB::raw("ST_SetSRID(ST_MakePoint($lng, $lat), 4326)::geography"),
            'last_location_updated_at' => now(),
        ]);
    }
}
