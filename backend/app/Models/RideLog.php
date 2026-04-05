<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class RideLog extends Model
{
    use HasFactory, HasUuids;

    protected $keyType = 'string';
    public $incrementing = false;

    protected $fillable = [
        'user_id',
        'rider_id',
        'route_id',
        'vehicle_id',
        'pickup_location',
        'dropoff_location',
        'pickup_address',
        'dropoff_address',
        'fare_shown',
        'distance_meters',
        'started_at',
        'ended_at',
        'is_completed',
    ];

    protected $casts = [
        'fare_shown' => 'decimal:2',
        'distance_meters' => 'integer',
        'started_at' => 'datetime',
        'ended_at' => 'datetime',
        'is_completed' => 'boolean',
        'created_at' => 'datetime',
    ];

    // Relationships
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function rider()
    {
        return $this->belongsTo(Rider::class);
    }

    public function route()
    {
        return $this->belongsTo(Route::class);
    }

    public function vehicle()
    {
        return $this->belongsTo(Vehicle::class);
    }

    public function rating()
    {
        return $this->hasOne(Rating::class);
    }

    public function complaints()
    {
        return $this->hasMany(Complaint::class);
    }

    // Scopes
    public function scopeCompleted($query)
    {
        return $query->where('is_completed', true);
    }

    public function scopeToday($query)
    {
        return $query->whereDate('created_at', today());
    }

    public function scopeThisWeek($query)
    {
        return $query->whereBetween('created_at', [now()->startOfWeek(), now()->endOfWeek()]);
    }

    public function scopeThisMonth($query)
    {
        return $query->whereMonth('created_at', now()->month)
                     ->whereYear('created_at', now()->year);
    }

    // Helpers
    public function complete(): void
    {
        $this->update([
            'is_completed' => true,
            'ended_at' => now(),
        ]);
    }
}
