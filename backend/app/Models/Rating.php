<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Rating extends Model
{
    use HasFactory, HasUuids;

    protected $keyType = 'string';
    public $incrementing = false;
    public $timestamps = false;

    protected $fillable = [
        'ride_log_id',
        'user_id',
        'rider_id',
        'rating',
        'review',
        'tags',
        'is_anonymous',
    ];

    protected $casts = [
        'rating' => 'integer',
        'tags' => 'array',
        'is_anonymous' => 'boolean',
        'created_at' => 'datetime',
    ];

    // Relationships
    public function rideLog()
    {
        return $this->belongsTo(RideLog::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function rider()
    {
        return $this->belongsTo(Rider::class);
    }

    // Scopes
    public function scopePositive($query)
    {
        return $query->where('rating', '>=', 4);
    }

    public function scopeNegative($query)
    {
        return $query->where('rating', '<=', 2);
    }

    public function scopeWithReview($query)
    {
        return $query->whereNotNull('review');
    }
}
