<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Rider;
use App\Services\OtpService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;

class AuthController extends Controller
{
    protected OtpService $otpService;

    public function __construct(OtpService $otpService)
    {
        $this->otpService = $otpService;
    }

    /**
     * Request OTP for user login
     */
    public function requestUserOtp(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'phone' => 'required|string|regex:/^\+91[0-9]{10}$/',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid phone number format. Use +91XXXXXXXXXX',
                'errors' => $validator->errors(),
            ], 422);
        }

        $result = $this->otpService->send($request->phone, 'user_login');

        return response()->json($result, $result['success'] ? 200 : 400);
    }

    /**
     * Verify OTP and login user
     */
    public function verifyUserOtp(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'phone' => 'required|string|regex:/^\+91[0-9]{10}$/',
            'otp' => 'required|string|size:6',
            'device_token' => 'nullable|string',
            'device_type' => 'nullable|in:android,ios',
            'app_version' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        $result = $this->otpService->verify($request->phone, $request->otp);

        if (!$result['success']) {
            return response()->json($result, 400);
        }

        // Create or update user
        $user = User::updateOrCreate(
            ['phone' => $request->phone],
            [
                'device_token' => $request->device_token,
                'device_type' => $request->device_type,
                'app_version' => $request->app_version,
            ]
        );

        // Create auth token
        $token = $user->createToken('user_app', ['user'])->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Login successful',
            'data' => [
                'user' => [
                    'id' => $user->id,
                    'phone' => $user->phone,
                    'name' => $user->name,
                    'email' => $user->email,
                    'avatar_url' => $user->avatar_url,
                    'is_new' => !$user->name,
                ],
                'token' => $token,
            ],
        ]);
    }

    /**
     * Request OTP for rider login
     */
    public function requestRiderOtp(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'phone' => 'required|string|regex:/^\+91[0-9]{10}$/',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid phone number format. Use +91XXXXXXXXXX',
                'errors' => $validator->errors(),
            ], 422);
        }

        $result = $this->otpService->send($request->phone, 'rider_login');

        return response()->json($result, $result['success'] ? 200 : 400);
    }

    /**
     * Verify OTP and login rider
     */
    public function verifyRiderOtp(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'phone' => 'required|string|regex:/^\+91[0-9]{10}$/',
            'otp' => 'required|string|size:6',
            'device_token' => 'nullable|string',
            'device_type' => 'nullable|in:android,ios',
            'app_version' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        $result = $this->otpService->verify($request->phone, $request->otp);

        if (!$result['success']) {
            return response()->json($result, 400);
        }

        // Find or create rider
        $rider = Rider::firstOrCreate(
            ['phone' => $request->phone],
            ['name' => '']
        );

        $rider->update([
            'device_token' => $request->device_token,
            'device_type' => $request->device_type,
            'app_version' => $request->app_version,
        ]);

        // Create auth token
        $token = $rider->createToken('rider_app', ['rider'])->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Login successful',
            'data' => [
                'rider' => [
                    'id' => $rider->id,
                    'phone' => $rider->phone,
                    'name' => $rider->name,
                    'status' => $rider->status,
                    'is_kyc_complete' => $rider->isKycComplete(),
                    'is_kyc_approved' => $rider->isKycApproved(),
                    'pending_documents' => $rider->getPendingDocuments(),
                    'is_new' => !$rider->name,
                ],
                'token' => $token,
            ],
        ]);
    }

    /**
     * Logout user/rider
     */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logged out successfully',
        ]);
    }

    /**
     * Get current user profile
     */
    public function userProfile(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $user->id,
                'phone' => $user->phone,
                'name' => $user->name,
                'email' => $user->email,
                'avatar_url' => $user->avatar_url,
                'status' => $user->status,
                'created_at' => $user->created_at->toIso8601String(),
            ],
        ]);
    }

    /**
     * Update user profile
     */
    public function updateUserProfile(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|string|max:100',
            'email' => 'sometimes|email|max:255',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();
        $user->update($request->only(['name', 'email']));

        return response()->json([
            'success' => true,
            'message' => 'Profile updated successfully',
            'data' => [
                'id' => $user->id,
                'phone' => $user->phone,
                'name' => $user->name,
                'email' => $user->email,
            ],
        ]);
    }

    /**
     * Get current rider profile
     */
    public function riderProfile(Request $request): JsonResponse
    {
        $rider = $request->user();
        $rider->load(['vehicle', 'documents', 'activeRoutes']);

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $rider->id,
                'phone' => $rider->phone,
                'name' => $rider->name,
                'email' => $rider->email,
                'avatar_url' => $rider->avatar_url,
                'status' => $rider->status,
                'is_online' => $rider->is_online,
                'is_available' => $rider->is_available,
                'rating_avg' => $rider->rating_avg,
                'rating_count' => $rider->rating_count,
                'total_rides' => $rider->total_rides,
                'vehicle' => $rider->vehicle,
                'documents' => $rider->documents->map(fn($doc) => [
                    'type' => $doc->document_type,
                    'status' => $doc->status,
                    'rejection_reason' => $doc->rejection_reason,
                ]),
                'active_routes_count' => $rider->activeRoutes->count(),
                'is_kyc_complete' => $rider->isKycComplete(),
                'is_kyc_approved' => $rider->isKycApproved(),
                'pending_documents' => $rider->getPendingDocuments(),
                'created_at' => $rider->created_at->toIso8601String(),
            ],
        ]);
    }
}
