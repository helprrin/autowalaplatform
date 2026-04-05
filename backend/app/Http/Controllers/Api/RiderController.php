<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Rider;
use App\Models\Vehicle;
use App\Models\Document;
use App\Models\Route;
use App\Services\StorageService;
use App\Services\FirebaseService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;

class RiderController extends Controller
{
    protected StorageService $storage;
    protected FirebaseService $firebase;

    public function __construct(StorageService $storage, FirebaseService $firebase)
    {
        $this->storage = $storage;
        $this->firebase = $firebase;
    }

    /**
     * Update rider profile
     */
    public function updateProfile(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:100',
            'email' => 'nullable|email|max:255',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $rider = $request->user();
        $rider->update($request->only(['name', 'email']));

        // Update Firebase profile
        $this->firebase->updateRiderProfile($rider->id, [
            'name' => $rider->name,
            'phone' => $rider->phone,
            'vehicleNumber' => $rider->vehicle?->registration_number ?? '',
            'rating' => (float) $rider->rating_avg,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Profile updated successfully',
        ]);
    }

    /**
     * Register vehicle
     */
    public function registerVehicle(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'registration_number' => 'required|string|max:20|unique:vehicles,registration_number',
            'make' => 'nullable|string|max:50',
            'model' => 'nullable|string|max:50',
            'year' => 'nullable|integer|min:2000|max:' . (date('Y') + 1),
            'color' => 'nullable|string|max:30',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $rider = $request->user();

        // Deactivate existing vehicles
        $rider->vehicles()->update(['is_active' => false]);

        // Create new vehicle
        $vehicle = Vehicle::create([
            'rider_id' => $rider->id,
            'registration_number' => strtoupper($request->registration_number),
            'make' => $request->make,
            'model' => $request->model,
            'year' => $request->year,
            'color' => $request->color,
            'is_active' => true,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Vehicle registered successfully',
            'data' => $vehicle,
        ]);
    }

    /**
     * Upload KYC document
     */
    public function uploadDocument(Request $request): JsonResponse
    {
        $allowedTypes = array_merge(
            config('autowala.rider.required_documents'),
            config('autowala.rider.optional_documents')
        );

        $validator = Validator::make($request->all(), [
            'document_type' => 'required|string|in:' . implode(',', $allowedTypes),
            'file' => 'required|file|mimes:jpeg,jpg,png,webp,pdf|max:5120',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $rider = $request->user();
        $type = $request->document_type;

        // Upload to Supabase Storage
        $uploadResult = $this->storage->upload(
            $request->file('file'),
            "kyc/{$rider->id}",
            "{$type}_{$rider->id}.{$request->file('file')->getClientOriginalExtension()}"
        );

        if (!$uploadResult['success']) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to upload document',
            ], 500);
        }

        // Create or update document record
        $document = Document::updateOrCreate(
            [
                'rider_id' => $rider->id,
                'document_type' => $type,
            ],
            [
                'file_url' => $uploadResult['url'],
                'file_name' => $uploadResult['filename'],
                'file_size' => $uploadResult['size'],
                'status' => 'pending',
                'rejection_reason' => null,
            ]
        );

        // Check if KYC is complete
        if ($rider->isKycComplete() && !$rider->kyc_submitted_at) {
            $rider->update(['kyc_submitted_at' => now()]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Document uploaded successfully',
            'data' => [
                'document_type' => $document->document_type,
                'status' => $document->status,
                'is_kyc_complete' => $rider->isKycComplete(),
                'pending_documents' => $rider->getPendingDocuments(),
            ],
        ]);
    }

    /**
     * Get document status
     */
    public function getDocuments(Request $request): JsonResponse
    {
        $rider = $request->user();
        $documents = $rider->documents;

        $required = config('autowala.rider.required_documents');
        $optional = config('autowala.rider.optional_documents');

        $documentStatus = [];
        
        foreach ($required as $type) {
            $doc = $documents->firstWhere('document_type', $type);
            $documentStatus[$type] = [
                'type' => $type,
                'required' => true,
                'uploaded' => (bool) $doc,
                'status' => $doc?->status ?? 'not_uploaded',
                'rejection_reason' => $doc?->rejection_reason,
                'file_url' => $doc?->file_url,
            ];
        }

        foreach ($optional as $type) {
            $doc = $documents->firstWhere('document_type', $type);
            $documentStatus[$type] = [
                'type' => $type,
                'required' => false,
                'uploaded' => (bool) $doc,
                'status' => $doc?->status ?? 'not_uploaded',
                'rejection_reason' => $doc?->rejection_reason,
                'file_url' => $doc?->file_url,
            ];
        }

        return response()->json([
            'success' => true,
            'data' => [
                'documents' => array_values($documentStatus),
                'is_kyc_complete' => $rider->isKycComplete(),
                'is_kyc_approved' => $rider->isKycApproved(),
                'kyc_status' => $rider->status,
            ],
        ]);
    }

    /**
     * Toggle online status
     */
    public function toggleOnline(Request $request): JsonResponse
    {
        $rider = $request->user();

        if (!$rider->isKycApproved()) {
            return response()->json([
                'success' => false,
                'message' => 'KYC approval required to go online',
            ], 403);
        }

        $isOnline = !$rider->is_online;
        $rider->update(['is_online' => $isOnline]);

        // Update Firebase status
        $this->firebase->updateRiderStatus($rider->id, $isOnline, $rider->is_available);

        if (!$isOnline) {
            $this->firebase->removeRider($rider->id);
        }

        return response()->json([
            'success' => true,
            'message' => $isOnline ? 'You are now online' : 'You are now offline',
            'data' => ['is_online' => $isOnline],
        ]);
    }

    /**
     * Toggle availability
     */
    public function toggleAvailability(Request $request): JsonResponse
    {
        $rider = $request->user();
        
        $isAvailable = !$rider->is_available;
        $rider->update(['is_available' => $isAvailable]);

        // Update Firebase status
        $this->firebase->updateRiderStatus($rider->id, $rider->is_online, $isAvailable);

        return response()->json([
            'success' => true,
            'message' => $isAvailable ? 'Now accepting rides' : 'Not accepting rides',
            'data' => ['is_available' => $isAvailable],
        ]);
    }

    /**
     * Update location
     */
    public function updateLocation(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'heading' => 'nullable|numeric|between:0,360',
            'speed' => 'nullable|numeric|min:0',
            'accuracy' => 'nullable|numeric|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $rider = $request->user();

        // Update database location
        $rider->updateLocation(
            $request->latitude,
            $request->longitude,
            $request->heading
        );

        // Update Firebase location
        $this->firebase->updateRiderLocation(
            $rider->id,
            $request->latitude,
            $request->longitude,
            $request->heading,
            $request->speed,
            $request->accuracy
        );

        return response()->json([
            'success' => true,
        ]);
    }

    /**
     * Create route
     */
    public function createRoute(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:100',
            'description' => 'nullable|string|max:500',
            'base_fare' => 'required|numeric|min:1|max:10000',
            'per_km_fare' => 'nullable|numeric|min:0|max:100',
            'points' => 'required|array|min:2',
            'points.*.lat' => 'required|numeric|between:-90,90',
            'points.*.lng' => 'required|numeric|between:-180,180',
            'points.*.address' => 'nullable|string|max:255',
            'points.*.landmark' => 'nullable|string|max:255',
            'start_address' => 'nullable|string|max:255',
            'end_address' => 'nullable|string|max:255',
            'operating_days' => 'nullable|array',
            'operating_days.*' => 'in:mon,tue,wed,thu,fri,sat,sun',
            'start_time' => 'nullable|date_format:H:i',
            'end_time' => 'nullable|date_format:H:i',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $rider = $request->user();

        try {
            DB::beginTransaction();

            $route = Route::createWithPoints([
                'rider_id' => $rider->id,
                'name' => $request->name,
                'description' => $request->description,
                'base_fare' => $request->base_fare,
                'per_km_fare' => $request->per_km_fare ?? 0,
                'start_address' => $request->start_address ?? $request->points[0]['address'] ?? null,
                'end_address' => $request->end_address ?? end($request->points)['address'] ?? null,
                'operating_days' => $request->operating_days ?? ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'],
                'start_time' => $request->start_time,
                'end_time' => $request->end_time,
            ], $request->points);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Route created successfully',
                'data' => [
                    'id' => $route->id,
                    'name' => $route->name,
                    'base_fare' => $route->base_fare,
                ],
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Failed to create route',
            ], 500);
        }
    }

    /**
     * Get routes
     */
    public function getRoutes(Request $request): JsonResponse
    {
        $rider = $request->user();
        $routes = $rider->routes()->with('points')->get();

        return response()->json([
            'success' => true,
            'data' => $routes->map(fn($route) => [
                'id' => $route->id,
                'name' => $route->name,
                'description' => $route->description,
                'start_address' => $route->start_address,
                'end_address' => $route->end_address,
                'base_fare' => $route->base_fare,
                'per_km_fare' => $route->per_km_fare,
                'is_active' => $route->is_active,
                'operating_days' => $route->operating_days,
                'start_time' => $route->start_time,
                'end_time' => $route->end_time,
                'points' => $route->points->map(fn($p) => $p->getCoordinates()),
            ]),
        ]);
    }

    /**
     * Update route
     */
    public function updateRoute(Request $request, string $routeId): JsonResponse
    {
        $rider = $request->user();
        $route = $rider->routes()->find($routeId);

        if (!$route) {
            return response()->json([
                'success' => false,
                'message' => 'Route not found',
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|string|max:100',
            'description' => 'nullable|string|max:500',
            'base_fare' => 'sometimes|numeric|min:1|max:10000',
            'per_km_fare' => 'nullable|numeric|min:0|max:100',
            'is_active' => 'sometimes|boolean',
            'operating_days' => 'nullable|array',
            'start_time' => 'nullable|date_format:H:i',
            'end_time' => 'nullable|date_format:H:i',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $route->update($request->only([
            'name', 'description', 'base_fare', 'per_km_fare',
            'is_active', 'operating_days', 'start_time', 'end_time',
        ]));

        return response()->json([
            'success' => true,
            'message' => 'Route updated successfully',
        ]);
    }

    /**
     * Delete route
     */
    public function deleteRoute(Request $request, string $routeId): JsonResponse
    {
        $rider = $request->user();
        $route = $rider->routes()->find($routeId);

        if (!$route) {
            return response()->json([
                'success' => false,
                'message' => 'Route not found',
            ], 404);
        }

        $route->delete();

        return response()->json([
            'success' => true,
            'message' => 'Route deleted successfully',
        ]);
    }

    /**
     * Set current active route (for Firebase broadcast)
     */
    public function setActiveRoute(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'route_id' => 'nullable|uuid',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $rider = $request->user();

        if ($request->route_id) {
            $route = $rider->routes()->find($request->route_id);
            
            if (!$route) {
                return response()->json([
                    'success' => false,
                    'message' => 'Route not found',
                ], 404);
            }

            $this->firebase->setRiderRoute($rider->id, [
                'routeId' => $route->id,
                'routeName' => $route->name,
                'fare' => (float) $route->base_fare,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Active route set',
            ]);
        }

        // Clear active route
        $this->firebase->setRiderRoute($rider->id, null);

        return response()->json([
            'success' => true,
            'message' => 'Active route cleared',
        ]);
    }

    /**
     * Get ride history
     */
    public function getRideHistory(Request $request): JsonResponse
    {
        $rider = $request->user();
        $page = $request->get('page', 1);
        $perPage = $request->get('per_page', 20);

        $rides = $rider->rideLogs()
            ->with(['user:id,name,phone', 'rating'])
            ->orderByDesc('created_at')
            ->paginate($perPage, ['*'], 'page', $page);

        return response()->json([
            'success' => true,
            'data' => [
                'rides' => $rides->items(),
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
     * Get ratings
     */
    public function getRatings(Request $request): JsonResponse
    {
        $rider = $request->user();
        $page = $request->get('page', 1);
        $perPage = $request->get('per_page', 20);

        $ratings = $rider->ratings()
            ->with('user:id,name')
            ->orderByDesc('created_at')
            ->paginate($perPage, ['*'], 'page', $page);

        return response()->json([
            'success' => true,
            'data' => [
                'summary' => [
                    'average' => $rider->rating_avg,
                    'count' => $rider->rating_count,
                    'distribution' => [
                        5 => $rider->ratings()->where('rating', 5)->count(),
                        4 => $rider->ratings()->where('rating', 4)->count(),
                        3 => $rider->ratings()->where('rating', 3)->count(),
                        2 => $rider->ratings()->where('rating', 2)->count(),
                        1 => $rider->ratings()->where('rating', 1)->count(),
                    ],
                ],
                'ratings' => $ratings->items(),
                'pagination' => [
                    'current_page' => $ratings->currentPage(),
                    'last_page' => $ratings->lastPage(),
                    'total' => $ratings->total(),
                ],
            ],
        ]);
    }
}
