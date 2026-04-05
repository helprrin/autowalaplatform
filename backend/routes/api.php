<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\RiderController;
use App\Http\Controllers\Admin\AdminController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// Health check
Route::get('/health', fn() => response()->json(['status' => 'ok', 'timestamp' => now()->toIso8601String()]));

// App version check
Route::get('/version', fn() => response()->json([
    'user_app' => [
        'min_version' => config('autowala.app_version.min_user'),
        'current_version' => '1.0.0',
    ],
    'rider_app' => [
        'min_version' => config('autowala.app_version.min_rider'),
        'current_version' => '1.0.0',
    ],
]));

/*
|--------------------------------------------------------------------------
| User Authentication Routes
|--------------------------------------------------------------------------
*/
Route::prefix('user/auth')->group(function () {
    Route::post('/request-otp', [AuthController::class, 'requestUserOtp']);
    Route::post('/verify-otp', [AuthController::class, 'verifyUserOtp']);
});

/*
|--------------------------------------------------------------------------
| Rider Authentication Routes
|--------------------------------------------------------------------------
*/
Route::prefix('rider/auth')->group(function () {
    Route::post('/request-otp', [AuthController::class, 'requestRiderOtp']);
    Route::post('/verify-otp', [AuthController::class, 'verifyRiderOtp']);
});

/*
|--------------------------------------------------------------------------
| User Protected Routes
|--------------------------------------------------------------------------
*/
Route::prefix('user')->middleware(['auth:sanctum', 'ability:user'])->group(function () {
    // Auth
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/profile', [AuthController::class, 'userProfile']);
    Route::put('/profile', [AuthController::class, 'updateUserProfile']);
    
    // Discovery
    Route::get('/nearby-autos', [UserController::class, 'nearbyAutos']);
    Route::get('/nearby-routes', [UserController::class, 'nearbyRoutes']);
    Route::get('/rider/{riderId}', [UserController::class, 'getRiderDetails']);
    
    // Tracking
    Route::post('/track/start', [UserController::class, 'startTracking']);
    Route::post('/track/{rideId}/end', [UserController::class, 'endTracking']);
    Route::get('/track/{rideId}/share', [UserController::class, 'shareRide']);
    
    // Ratings
    Route::post('/ride/{rideId}/rate', [UserController::class, 'rateRide']);
    
    // Complaints
    Route::post('/complaint', [UserController::class, 'fileComplaint']);
    Route::get('/complaints', [UserController::class, 'getComplaints']);
    
    // History
    Route::get('/rides', [UserController::class, 'getRideHistory']);
    
    // Location
    Route::post('/location', [UserController::class, 'updateLocation']);
    
    // Notifications
    Route::get('/notifications', [UserController::class, 'getNotifications']);
    Route::post('/notifications/{notificationId}/read', [UserController::class, 'markNotificationRead']);
    
    // SOS
    Route::get('/sos', [UserController::class, 'getSosInfo']);
});

/*
|--------------------------------------------------------------------------
| Rider Protected Routes
|--------------------------------------------------------------------------
*/
Route::prefix('rider')->middleware(['auth:sanctum', 'ability:rider'])->group(function () {
    // Auth
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/profile', [AuthController::class, 'riderProfile']);
    Route::put('/profile', [RiderController::class, 'updateProfile']);
    
    // Vehicle
    Route::post('/vehicle', [RiderController::class, 'registerVehicle']);
    
    // KYC
    Route::post('/documents', [RiderController::class, 'uploadDocument']);
    Route::get('/documents', [RiderController::class, 'getDocuments']);
    
    // Status
    Route::post('/toggle-online', [RiderController::class, 'toggleOnline']);
    Route::post('/toggle-availability', [RiderController::class, 'toggleAvailability']);
    
    // Location
    Route::post('/location', [RiderController::class, 'updateLocation']);
    
    // Routes
    Route::get('/routes', [RiderController::class, 'getRoutes']);
    Route::post('/routes', [RiderController::class, 'createRoute']);
    Route::put('/routes/{routeId}', [RiderController::class, 'updateRoute']);
    Route::delete('/routes/{routeId}', [RiderController::class, 'deleteRoute']);
    Route::post('/routes/active', [RiderController::class, 'setActiveRoute']);
    
    // History
    Route::get('/rides', [RiderController::class, 'getRideHistory']);
    
    // Ratings
    Route::get('/ratings', [RiderController::class, 'getRatings']);
});

/*
|--------------------------------------------------------------------------
| Admin Routes
|--------------------------------------------------------------------------
*/
Route::prefix('admin')->group(function () {
    Route::post('/login', [AdminController::class, 'login']);
});

Route::prefix('admin')->middleware(['auth:sanctum', 'ability:admin'])->group(function () {
    // Dashboard
    Route::get('/dashboard', [AdminController::class, 'dashboard']);
    Route::get('/analytics', [AdminController::class, 'analytics']);
    
    // Users
    Route::get('/users', [AdminController::class, 'listUsers']);
    Route::get('/users/{userId}', [AdminController::class, 'getUser']);
    Route::put('/users/{userId}/status', [AdminController::class, 'updateUserStatus']);
    
    // Riders
    Route::get('/riders', [AdminController::class, 'listRiders']);
    Route::get('/riders/{riderId}', [AdminController::class, 'getRider']);
    Route::put('/riders/{riderId}/status', [AdminController::class, 'updateRiderStatus']);
    Route::get('/riders/online/map', [AdminController::class, 'onlineRiders']);
    
    // KYC
    Route::get('/kyc/pending', [AdminController::class, 'pendingKyc']);
    Route::post('/kyc/{riderId}/approve', [AdminController::class, 'approveKyc']);
    Route::post('/kyc/{riderId}/reject', [AdminController::class, 'rejectKyc']);
    Route::post('/documents/{documentId}/approve', [AdminController::class, 'approveDocument']);
    Route::post('/documents/{documentId}/reject', [AdminController::class, 'rejectDocument']);
    
    // Complaints
    Route::get('/complaints', [AdminController::class, 'listComplaints']);
    Route::get('/complaints/{complaintId}', [AdminController::class, 'getComplaint']);
    Route::put('/complaints/{complaintId}', [AdminController::class, 'updateComplaint']);
});
