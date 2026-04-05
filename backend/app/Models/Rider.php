<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class Rider extends Authenticatable
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
        'is_online',
        'is_available',
        'current_location',
        'current_heading',
        'location_updated_at',
        'rating_avg',
        'rating_count',
        'total_rides',
        'device_token',
        'device_type',
        'app_version',
        'kyc_submitted_at',
        'kyc_approved_at',
        'kyc_rejected_reason',
    ];

    protected $hidden = [
        'device_token',
    ];

    protected $casts = [
        'is_online' => 'boolean',
        'is_available' => 'boolean',
        'rating_avg' => 'decimal:1',
        'current_heading' => 'decimal:2',
        'location_updated_at' => 'datetime',
        'kyc_submitted_at' => 'datetime',
        'kyc_approved_at' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // Relationships
    public function vehicle()
    {
        return $this->hasOne(Vehicle::class)->where('is_active', true);
    }

    public function vehicles()
    {
        return $this->hasMany(Vehicle::class);
    }

    public function documents()
    {
        return $this->hasMany(Document::class);
    }

    public function routes()
    {
        return $this->hasMany(Route::class);
    }

    public function activeRoutes()
    {
        return $this->hasMany(Route::class)->where('is_active', true);
    }

    public function rideLogs()
    {
        return $this->hasMany(RideLog::class);
    }

    public function ratings()
    {
        return $this->hasMany(Rating::class);
    }

    public function notifications()
    {
        return $this->hasMany(Notification::class);
    }

    // Scopes
    public function scopeApproved($query)
    {
        return $query->where('status', 'approved');
    }

    public function scopeOnline($query)
    {
        return $query->where('is_online', true);
    }

    public function scopeAvailable($query)
    {
        return $query->where('is_available', true);
    }

    public function scopeNearby($query, float $lat, float $lng, int $radiusMeters = 5000)
    {
        return $query->whereRaw("
            ST_DWithin(
                current_location,
                ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography,
                ?
            )
        ", [$lng, $lat, $radiusMeters]);
    }

    // Helpers
    public function updateLocation(float $lat, float $lng, ?float $heading = null): void
    {
        $this->update([
            'current_location' => \DB::raw("ST_SetSRID(ST_MakePoint($lng, $lat), 4326)::geography"),
            'current_heading' => $heading,
            'location_updated_at' => now(),
        ]);
    }

    public function isKycComplete(): bool
    {
        $required = config('autowala.rider.required_documents');
        $uploaded = $this->documents()->pluck('document_type')->toArray();
        
        return empty(array_diff($required, $uploaded));
    }

    public function isKycApproved(): bool
    {
        return $this->status === 'approved';
    }

    public function getPendingDocuments(): array
    {
        $required = config('autowala.rider.required_documents');
        $approved = $this->documents()
            ->where('status', 'approved')
            ->pluck('document_type')
            ->toArray();
        
        return array_diff($required, $approved);
    }

    public function getDistanceFrom(float $lat, float $lng): ?float
    {
        if (!$this->current_location) {
            return null;
        }

        $result = \DB::selectOne("
            SELECT ST_Distance(
                current_location,
                ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography
            ) as distance
            FROM riders WHERE id = ?
        ", [$lng, $lat, $this->id]);

        return $result?->distance;
    }
}
