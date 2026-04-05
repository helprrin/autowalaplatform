<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class RoutePoint extends Model
{
    use HasFactory, HasUuids;

    protected $keyType = 'string';
    public $incrementing = false;
    public $timestamps = false;

    protected $fillable = [
        'route_id',
        'point_order',
        'location',
        'address',
        'landmark',
    ];

    protected $casts = [
        'point_order' => 'integer',
        'created_at' => 'datetime',
    ];

    // Relationships
    public function route()
    {
        return $this->belongsTo(Route::class);
    }

    // Helpers
    public function getCoordinates(): ?array
    {
        if (!$this->location) {
            return null;
        }

        $result = \DB::selectOne("
            SELECT 
                ST_Y(location::geometry) as lat,
                ST_X(location::geometry) as lng
            FROM route_points WHERE id = ?
        ", [$this->id]);

        return $result ? ['lat' => $result->lat, 'lng' => $result->lng] : null;
    }
}
