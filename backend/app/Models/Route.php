<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Route extends Model
{
    use HasFactory, HasUuids;

    protected $keyType = 'string';
    public $incrementing = false;

    protected $fillable = [
        'rider_id',
        'name',
        'description',
        'start_point',
        'end_point',
        'start_address',
        'end_address',
        'route_line',
        'distance_meters',
        'duration_minutes',
        'base_fare',
        'per_km_fare',
        'is_active',
        'operating_days',
        'start_time',
        'end_time',
    ];

    protected $casts = [
        'distance_meters' => 'integer',
        'duration_minutes' => 'integer',
        'base_fare' => 'decimal:2',
        'per_km_fare' => 'decimal:2',
        'is_active' => 'boolean',
        'operating_days' => 'array',
        'start_time' => 'datetime:H:i',
        'end_time' => 'datetime:H:i',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // Relationships
    public function rider()
    {
        return $this->belongsTo(Rider::class);
    }

    public function points()
    {
        return $this->hasMany(RoutePoint::class)->orderBy('point_order');
    }

    public function rideLogs()
    {
        return $this->hasMany(RideLog::class);
    }

    // Scopes
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopeNearStart($query, float $lat, float $lng, int $radiusMeters = 2000)
    {
        return $query->whereRaw("
            ST_DWithin(
                start_point,
                ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography,
                ?
            )
        ", [$lng, $lat, $radiusMeters]);
    }

    public function scopeNearEnd($query, float $lat, float $lng, int $radiusMeters = 2000)
    {
        return $query->whereRaw("
            ST_DWithin(
                end_point,
                ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography,
                ?
            )
        ", [$lng, $lat, $radiusMeters]);
    }

    // Helpers
    public static function createWithPoints(array $data, array $points): self
    {
        $startPoint = $points[0];
        $endPoint = end($points);

        $route = static::create([
            ...$data,
            'start_point' => \DB::raw("ST_SetSRID(ST_MakePoint({$startPoint['lng']}, {$startPoint['lat']}), 4326)::geography"),
            'end_point' => \DB::raw("ST_SetSRID(ST_MakePoint({$endPoint['lng']}, {$endPoint['lat']}), 4326)::geography"),
        ]);

        foreach ($points as $index => $point) {
            RoutePoint::create([
                'route_id' => $route->id,
                'point_order' => $index,
                'location' => \DB::raw("ST_SetSRID(ST_MakePoint({$point['lng']}, {$point['lat']}), 4326)::geography"),
                'address' => $point['address'] ?? null,
                'landmark' => $point['landmark'] ?? null,
            ]);
        }

        return $route;
    }

    public function isOperatingNow(): bool
    {
        $today = strtolower(now()->format('D'));
        
        if (!in_array($today, $this->operating_days ?? [])) {
            return false;
        }

        if ($this->start_time && $this->end_time) {
            $now = now()->format('H:i');
            return $now >= $this->start_time && $now <= $this->end_time;
        }

        return true;
    }
}
