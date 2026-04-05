<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Rider;
use App\Models\RideLog;
use App\Models\Rating;
use App\Models\Complaint;
use App\Services\GeoService;
use App\Services\FirebaseService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class UserController extends Controller
{
    protected GeoService $geo;
    protected FirebaseService $firebase;

    public function __construct(GeoService $geo, FirebaseService $firebase)
    {
        $this->geo = $geo;
        $this->firebase = $firebase;
    }

    /**
     * Find nearby autos
     */
    public function nearbyAutos(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'radius' => 'nullable|integer|min:500|max:10000',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $radius = $request->get('radius', config('autowala.location.nearby_radius_meters'));

        $riders = $this->geo->findNearbyRiders(
            $request->latitude,
            $request->longitude,
            $radius
        );

        // Calculate ETA for each rider
        $ridersWithEta = array_map(function ($rider) {
            $rider['eta_minutes'] = $this->geo->calculateETA($rider['distance_meters']);
            return $rider;
        }, $riders);

        return response()->json([
            'success' => true,
            'data' => [
                'autos' => $ridersWithEta,
                'count' => count($ridersWithEta),
                'search_radius' => $radius,
            ],
        ]);
    }

    /**
     * Find routes near pickup point
     */
    public function nearbyRoutes(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'radius' => 'nullable|integer|min:500|max:5000',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $radius = $request->get('radius', 2000);

        $routes = $this->geo->findRoutesNearPoint(
            $request->latitude,
            $request->longitude,
            $radius
        );

        return response()->json([
            'success' => true,
            'data' => [
                'routes' => $routes,
                'count' => count($routes),
            ],
        ]);
    }

    /**
     * Get rider details
     */
    public function getRiderDetails(Request $request, string $riderId): JsonResponse
    {
        $rider = Rider::with(['vehicle', 'activeRoutes'])
            ->where('status', 'approved')
            ->find($riderId);

        if (!$rider) {
            return response()->json([
                'success' => false,
                'message' => 'Rider not found',
            ], 404);
        }

        // Calculate distance if user location provided
        $distance = null;
        $eta = null;
        if ($request->has(['latitude', 'longitude'])) {
            $distance = $rider->getDistanceFrom($request->latitude, $request->longitude);
            $eta = $distance ? $this->geo->calculateETA($distance) : null;
        }

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $rider->id,
                'name' => $rider->name,
                'phone' => $rider->phone,
                'avatar_url' => $rider->avatar_url,
                'rating_avg' => $rider->rating_avg,
                'rating_count' => $rider->rating_count,
                'total_rides' => $rider->total_rides,
                'is_online' => $rider->is_online,
                'is_available' => $rider->is_available,
                'vehicle' => $rider->vehicle ? [
                    'registration_number' => $rider->vehicle->registration_number,
                    'color' => $rider->vehicle->color,
                    'make' => $rider->vehicle->make,
                    'model' => $rider->vehicle->model,
                ] : null,
                'active_routes' => $rider->activeRoutes->map(fn($r) => [
                    'id' => $r->id,
                    'name' => $r->name,
                    'start_address' => $r->start_address,
                    'end_address' => $r->end_address,
                    'base_fare' => $r->base_fare,
                ]),
                'distance_meters' => $distance,
                'eta_minutes' => $eta,
            ],
        ]);
    }

    /**
     * Start tracking a rider
     */
    public function startTracking(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'rider_id' => 'required|uuid|exists:riders,id',
            'route_id' => 'nullable|uuid|exists:routes,id',
            'pickup_lat' => 'nullable|numeric|between:-90,90',
            'pickup_lng' => 'nullable|numeric|between:-180,180',
            'pickup_address' => 'nullable|string|max:255',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();
        $rider = Rider::find($request->rider_id);

        if (!$rider || !$rider->is_online) {
            return response()->json([
                'success' => false,
                'message' => 'Rider is not available',
            ], 400);
        }

        // Create ride log
        $rideLog = RideLog::create([
            'user_id' => $user->id,
            'rider_id' => $rider->id,
            'route_id' => $request->route_id,
            'vehicle_id' => $rider->vehicle?->id,
            'pickup_address' => $request->pickup_address,
            'started_at' => now(),
        ]);

        if ($request->pickup_lat && $request->pickup_lng) {
            $rideLog->update([
                'pickup_location' => \DB::raw("ST_SetSRID(ST_MakePoint({$request->pickup_lng}, {$request->pickup_lat}), 4326)::geography"),
            ]);
        }

        // Create Firebase tracking session
        $sessionId = Str::uuid()->toString();
        $this->firebase->createTrackingSession($sessionId, $rider->id, $user->id);

        return response()->json([
            'success' => true,
            'message' => 'Tracking started',
            'data' => [
                'ride_id' => $rideLog->id,
                'session_id' => $sessionId,
                'rider' => [
                    'id' => $rider->id,
                    'name' => $rider->name,
                    'phone' => $rider->phone,
                    'vehicle_number' => $rider->vehicle?->registration_number,
                ],
            ],
        ]);
    }

    /**
     * End tracking
     */
    public function endTracking(Request $request, string $rideId): JsonResponse
    {
        $user = $request->user();
        $rideLog = $user->rideLogs()->find($rideId);

        if (!$rideLog) {
            return response()->json([
                'success' => false,
                'message' => 'Ride not found',
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'session_id' => 'nullable|uuid',
            'dropoff_lat' => 'nullable|numeric|between:-90,90',
            'dropoff_lng' => 'nullable|numeric|between:-180,180',
            'dropoff_address' => 'nullable|string|max:255',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $rideLog->update([
            'dropoff_address' => $request->dropoff_address,
            'is_completed' => true,
            'ended_at' => now(),
        ]);

        if ($request->dropoff_lat && $request->dropoff_lng) {
            $rideLog->update([
                'dropoff_location' => \DB::raw("ST_SetSRID(ST_MakePoint({$request->dropoff_lng}, {$request->dropoff_lat}), 4326)::geography"),
            ]);
        }

        // End Firebase session
        if ($request->session_id) {
            $this->firebase->endTrackingSession($request->session_id);
        }

        // Increment rider's total rides
        $rideLog->rider->increment('total_rides');

        return response()->json([
            'success' => true,
            'message' => 'Ride completed',
            'data' => [
                'ride_id' => $rideLog->id,
                'can_rate' => !$rideLog->rating()->exists(),
            ],
        ]);
    }

    /**
     * Rate a ride
     */
    public function rateRide(Request $request, string $rideId): JsonResponse
    {
        $user = $request->user();
        $rideLog = $user->rideLogs()->find($rideId);

        if (!$rideLog) {
            return response()->json([
                'success' => false,
                'message' => 'Ride not found',
            ], 404);
        }

        if ($rideLog->rating()->exists()) {
            return response()->json([
                'success' => false,
                'message' => 'Ride already rated',
            ], 400);
        }

        $validator = Validator::make($request->all(), [
            'rating' => 'required|integer|min:1|max:5',
            'review' => 'nullable|string|max:500',
            'tags' => 'nullable|array',
            'tags.*' => 'string|max:50',
            'is_anonymous' => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        Rating::create([
            'ride_log_id' => $rideLog->id,
            'user_id' => $user->id,
            'rider_id' => $rideLog->rider_id,
            'rating' => $request->rating,
            'review' => $request->review,
            'tags' => $request->tags,
            'is_anonymous' => $request->is_anonymous ?? false,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Thank you for your feedback!',
        ]);
    }

    /**
     * File a complaint
     */
    public function fileComplaint(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'ride_id' => 'nullable|uuid|exists:ride_logs,id',
            'rider_id' => 'required|uuid|exists:riders,id',
            'complaint_type' => 'required|in:safety,behavior,pricing,vehicle,other',
            'subject' => 'required|string|max:255',
            'description' => 'required|string|max:2000',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();

        $complaint = Complaint::create([
            'ride_log_id' => $request->ride_id,
            'complainant_user_id' => $user->id,
            'against_rider_id' => $request->rider_id,
            'complaint_type' => $request->complaint_type,
            'subject' => $request->subject,
            'description' => $request->description,
            'priority' => $request->complaint_type === 'safety' ? 1 : 3,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Complaint filed successfully. We will review it shortly.',
            'data' => [
                'complaint_id' => $complaint->id,
            ],
        ]);
    }

    /**
     * Get user's complaints
     */
    public function getComplaints(Request $request): JsonResponse
    {
        $user = $request->user();
        $complaints = $user->complaints()
            ->orderByDesc('created_at')
            ->get()
            ->map(fn($c) => [
                'id' => $c->id,
                'type' => $c->complaint_type,
                'subject' => $c->subject,
                'status' => $c->status,
                'created_at' => $c->created_at->toIso8601String(),
                'resolved_at' => $c->resolved_at?->toIso8601String(),
            ]);

        return response()->json([
            'success' => true,
            'data' => $complaints,
        ]);
    }

    /**
     * Get ride history
     */
    public function getRideHistory(Request $request): JsonResponse
    {
        $user = $request->user();
        $page = $request->get('page', 1);
        $perPage = $request->get('per_page', 20);

        $rides = $user->rideLogs()
            ->with(['rider:id,name,phone,avatar_url,rating_avg', 'rating', 'route:id,name'])
            ->orderByDesc('created_at')
            ->paginate($perPage, ['*'], 'page', $page);

        return response()->json([
            'success' => true,
            'data' => [
                'rides' => collect($rides->items())->map(fn($ride) => [
                    'id' => $ride->id,
                    'rider' => [
                        'id' => $ride->rider->id,
                        'name' => $ride->rider->name,
                        'phone' => $ride->rider->phone,
                        'avatar_url' => $ride->rider->avatar_url,
                        'rating' => $ride->rider->rating_avg,
                    ],
                    'route_name' => $ride->route?->name,
                    'pickup_address' => $ride->pickup_address,
                    'dropoff_address' => $ride->dropoff_address,
                    'fare_shown' => $ride->fare_shown,
                    'is_completed' => $ride->is_completed,
                    'started_at' => $ride->started_at?->toIso8601String(),
                    'ended_at' => $ride->ended_at?->toIso8601String(),
                    'my_rating' => $ride->rating?->rating,
                    'has_rated' => (bool) $ride->rating,
                ]),
                'pagination' => [
                    'current_page' => $rides->currentPage(),
                    'last_page' => $rides->lastPage(),
                    'per_page' => $rides->perPage(),
                    'total' => $rides->total(),
                ],
            ],
        ]);
    }

    /**
     * Update user location
     */
    public function updateLocation(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();
        $user->updateLocation($request->latitude, $request->longitude);

        return response()->json([
            'success' => true,
        ]);
    }

    /**
     * Get notifications
     */
    public function getNotifications(Request $request): JsonResponse
    {
        $user = $request->user();
        $notifications = $user->notifications()
            ->orderByDesc('created_at')
            ->limit(50)
            ->get();

        return response()->json([
            'success' => true,
            'data' => $notifications,
        ]);
    }

    /**
     * Mark notification as read
     */
    public function markNotificationRead(Request $request, string $notificationId): JsonResponse
    {
        $user = $request->user();
        $notification = $user->notifications()->find($notificationId);

        if (!$notification) {
            return response()->json([
                'success' => false,
                'message' => 'Notification not found',
            ], 404);
        }

        $notification->markAsRead();

        return response()->json([
            'success' => true,
        ]);
    }

    /**
     * Get SOS info
     */
    public function getSosInfo(): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data' => [
                'emergency_numbers' => config('autowala.sos.numbers'),
                'support_phone' => config('autowala.sos.support_phone'),
                'support_email' => config('autowala.sos.support_email'),
            ],
        ]);
    }

    /**
     * Share ride details
     */
    public function shareRide(Request $request, string $rideId): JsonResponse
    {
        $user = $request->user();
        $rideLog = $user->rideLogs()->with(['rider', 'rider.vehicle'])->find($rideId);

        if (!$rideLog) {
            return response()->json([
                'success' => false,
                'message' => 'Ride not found',
            ], 404);
        }

        $shareText = sprintf(
            "I'm traveling in an auto via AutoWala.\n\nRider: %s\nVehicle: %s\nPhone: %s\n\nTrack my ride: %s",
            $rideLog->rider->name,
            $rideLog->rider->vehicle?->registration_number ?? 'N/A',
            $rideLog->rider->phone,
            config('app.url') . "/track/{$rideLog->id}"
        );

        return response()->json([
            'success' => true,
            'data' => [
                'share_text' => $shareText,
                'track_url' => config('app.url') . "/track/{$rideLog->id}",
            ],
        ]);
    }
}
