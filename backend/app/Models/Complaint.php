<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Complaint extends Model
{
    use HasFactory, HasUuids;

    protected $keyType = 'string';
    public $incrementing = false;

    protected $fillable = [
        'ride_log_id',
        'complainant_user_id',
        'complainant_rider_id',
        'against_user_id',
        'against_rider_id',
        'complaint_type',
        'subject',
        'description',
        'attachments',
        'status',
        'priority',
        'assigned_to',
        'resolution_notes',
        'resolved_at',
    ];

    protected $casts = [
        'attachments' => 'array',
        'priority' => 'integer',
        'resolved_at' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // Relationships
    public function rideLog()
    {
        return $this->belongsTo(RideLog::class);
    }

    public function complainantUser()
    {
        return $this->belongsTo(User::class, 'complainant_user_id');
    }

    public function complainantRider()
    {
        return $this->belongsTo(Rider::class, 'complainant_rider_id');
    }

    public function againstUser()
    {
        return $this->belongsTo(User::class, 'against_user_id');
    }

    public function againstRider()
    {
        return $this->belongsTo(Rider::class, 'against_rider_id');
    }

    public function assignee()
    {
        return $this->belongsTo(AdminUser::class, 'assigned_to');
    }

    // Scopes
    public function scopeOpen($query)
    {
        return $query->where('status', 'open');
    }

    public function scopeInProgress($query)
    {
        return $query->where('status', 'in_progress');
    }

    public function scopeResolved($query)
    {
        return $query->whereIn('status', ['resolved', 'closed']);
    }

    public function scopeHighPriority($query)
    {
        return $query->where('priority', '<=', 2);
    }

    public function scopeByType($query, string $type)
    {
        return $query->where('complaint_type', $type);
    }

    // Helpers
    public function resolve(string $notes): void
    {
        $this->update([
            'status' => 'resolved',
            'resolution_notes' => $notes,
            'resolved_at' => now(),
        ]);
    }

    public function close(): void
    {
        $this->update(['status' => 'closed']);
    }

    public function assign(string $adminId): void
    {
        $this->update([
            'assigned_to' => $adminId,
            'status' => 'in_progress',
        ]);
    }
}
