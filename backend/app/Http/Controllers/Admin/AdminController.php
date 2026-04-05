<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AdminUser;
use App\Models\User;
use App\Models\Rider;
use App\Models\Document;
use App\Models\RideLog;
use App\Models\Rating;
use App\Models\Complaint;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;

class AdminController extends Controller
{
    /**
     * Admin login
     */
    public function login(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $admin = AdminUser::where('email', $request->email)->first();

        if (!$admin || !Hash::check($request->password, $admin->password_hash)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid credentials',
            ], 401);
        }

        if (!$admin->is_active) {
            return response()->json([
                'success' => false,
                'message' => 'Account is deactivated',
            ], 403);
        }

        $admin->recordLogin();
        $token = $admin->createToken('admin_panel', ['admin'])->plainTextToken;

        return response()->json([
            'success' => true,
            'data' => [
                'admin' => [
                    'id' => $admin->id,
                    'email' => $admin->email,
                    'name' => $admin->name,
                    'role' => $admin->role,
                ],
                'token' => $token,
            ],
        ]);
    }

    /**
     * Dashboard stats
     */
    public function dashboard(): JsonResponse
    {
        $today = now()->startOfDay();
        $thisWeek = now()->startOfWeek();
        $thisMonth = now()->startOfMonth();

        return response()->json([
            'success' => true,
            'data' => [
                'users' => [
                    'total' => User::count(),
                    'active' => User::active()->count(),
                    'new_today' => User::whereDate('created_at', $today)->count(),
                    'new_this_week' => User::where('created_at', '>=', $thisWeek)->count(),
                ],
                'riders' => [
                    'total' => Rider::count(),
                    'approved' => Rider::approved()->count(),
                    'pending' => Rider::where('status', 'pending')->count(),
                    'online' => Rider::online()->count(),
                    'new_today' => Rider::whereDate('created_at', $today)->count(),
                ],
                'rides' => [
                    'total' => RideLog::count(),
                    'today' => RideLog::today()->count(),
                    'this_week' => RideLog::thisWeek()->count(),
                    'this_month' => RideLog::thisMonth()->count(),
                    'completed' => RideLog::completed()->count(),
                ],
                'ratings' => [
                    'total' => Rating::count(),
                    'average' => round(Rating::avg('rating'), 2),
                    'positive' => Rating::positive()->count(),
                    'negative' => Rating::negative()->count(),
                ],
                'complaints' => [
                    'total' => Complaint::count(),
                    'open' => Complaint::open()->count(),
                    'in_progress' => Complaint::inProgress()->count(),
                    'resolved' => Complaint::resolved()->count(),
                ],
                'kyc' => [
                    'pending_documents' => Document::pending()->count(),
                    'pending_riders' => Rider::where('status', 'pending')
                        ->whereNotNull('kyc_submitted_at')
                        ->count(),
                ],
            ],
        ]);
    }

    /**
     * List users
     */
    public function listUsers(Request $request): JsonResponse
    {
        $query = User::query();

        if ($request->search) {
            $query->where(function ($q) use ($request) {
                $q->where('name', 'ilike', "%{$request->search}%")
                  ->orWhere('phone', 'ilike', "%{$request->search}%")
                  ->orWhere('email', 'ilike', "%{$request->search}%");
            });
        }

        if ($request->status) {
            $query->where('status', $request->status);
        }

        $users = $query->orderByDesc('created_at')
            ->paginate($request->get('per_page', 20));

        return response()->json([
            'success' => true,
            'data' => $users,
        ]);
    }

    /**
     * Get user details
     */
    public function getUser(string $userId): JsonResponse
    {
        $user = User::with(['rideLogs' => fn($q) => $q->latest()->limit(10)])
            ->find($userId);

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User not found',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'user' => $user,
                'stats' => [
                    'total_rides' => $user->rideLogs()->count(),
                    'ratings_given' => $user->ratings()->count(),
                    'complaints_filed' => $user->complaints()->count(),
                ],
            ],
        ]);
    }

    /**
     * Update user status
     */
    public function updateUserStatus(Request $request, string $userId): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'status' => 'required|in:active,inactive,blocked',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = User::find($userId);
        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User not found',
            ], 404);
        }

        $user->update(['status' => $request->status]);

        return response()->json([
            'success' => true,
            'message' => 'User status updated',
        ]);
    }

    /**
     * List riders
     */
    public function listRiders(Request $request): JsonResponse
    {
        $query = Rider::with('vehicle');

        if ($request->search) {
            $query->where(function ($q) use ($request) {
                $q->where('name', 'ilike', "%{$request->search}%")
                  ->orWhere('phone', 'ilike', "%{$request->search}%");
            });
        }

        if ($request->status) {
            $query->where('status', $request->status);
        }

        if ($request->online) {
            $query->where('is_online', $request->online === 'true');
        }

        $riders = $query->orderByDesc('created_at')
            ->paginate($request->get('per_page', 20));

        return response()->json([
            'success' => true,
            'data' => $riders,
        ]);
    }

    /**
     * Get rider details
     */
    public function getRider(string $riderId): JsonResponse
    {
        $rider = Rider::with(['vehicle', 'documents', 'routes'])
            ->find($riderId);

        if (!$rider) {
            return response()->json([
                'success' => false,
                'message' => 'Rider not found',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'rider' => $rider,
                'stats' => [
                    'total_rides' => $rider->rideLogs()->count(),
                    'completed_rides' => $rider->rideLogs()->completed()->count(),
                    'total_ratings' => $rider->rating_count,
                    'average_rating' => $rider->rating_avg,
                    'complaints_against' => Complaint::where('against_rider_id', $rider->id)->count(),
                ],
            ],
        ]);
    }

    /**
     * Get riders pending KYC approval
     */
    public function pendingKyc(Request $request): JsonResponse
    {
        $riders = Rider::with(['documents', 'vehicle'])
            ->where('status', 'pending')
            ->whereNotNull('kyc_submitted_at')
            ->orderBy('kyc_submitted_at')
            ->paginate($request->get('per_page', 20));

        return response()->json([
            'success' => true,
            'data' => $riders,
        ]);
    }

    /**
     * Approve rider KYC
     */
    public function approveKyc(Request $request, string $riderId): JsonResponse
    {
        $rider = Rider::find($riderId);

        if (!$rider) {
            return response()->json([
                'success' => false,
                'message' => 'Rider not found',
            ], 404);
        }

        if (!$rider->isKycComplete()) {
            return response()->json([
                'success' => false,
                'message' => 'KYC documents incomplete',
            ], 400);
        }

        $admin = $request->user();

        DB::transaction(function () use ($rider, $admin) {
            // Approve all pending documents
            $rider->documents()
                ->where('status', 'pending')
                ->update([
                    'status' => 'approved',
                    'verified_by' => $admin->id,
                    'verified_at' => now(),
                ]);

            // Approve rider
            $rider->update([
                'status' => 'approved',
                'kyc_approved_at' => now(),
            ]);
        });

        return response()->json([
            'success' => true,
            'message' => 'Rider KYC approved',
        ]);
    }

    /**
     * Reject rider KYC
     */
    public function rejectKyc(Request $request, string $riderId): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'reason' => 'required|string|max:500',
            'document_rejections' => 'nullable|array',
            'document_rejections.*.type' => 'required|string',
            'document_rejections.*.reason' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $rider = Rider::find($riderId);

        if (!$rider) {
            return response()->json([
                'success' => false,
                'message' => 'Rider not found',
            ], 404);
        }

        $admin = $request->user();

        DB::transaction(function () use ($rider, $request, $admin) {
            // Reject specific documents
            if ($request->document_rejections) {
                foreach ($request->document_rejections as $rejection) {
                    $rider->documents()
                        ->where('document_type', $rejection['type'])
                        ->update([
                            'status' => 'rejected',
                            'rejection_reason' => $rejection['reason'],
                            'verified_by' => $admin->id,
                            'verified_at' => now(),
                        ]);
                }
            }

            // Update rider status
            $rider->update([
                'status' => 'rejected',
                'kyc_rejected_reason' => $request->reason,
            ]);
        });

        return response()->json([
            'success' => true,
            'message' => 'Rider KYC rejected',
        ]);
    }

    /**
     * Approve single document
     */
    public function approveDocument(Request $request, string $documentId): JsonResponse
    {
        $document = Document::find($documentId);

        if (!$document) {
            return response()->json([
                'success' => false,
                'message' => 'Document not found',
            ], 404);
        }

        $document->approve($request->user()->id);

        return response()->json([
            'success' => true,
            'message' => 'Document approved',
        ]);
    }

    /**
     * Reject single document
     */
    public function rejectDocument(Request $request, string $documentId): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'reason' => 'required|string|max:500',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $document = Document::find($documentId);

        if (!$document) {
            return response()->json([
                'success' => false,
                'message' => 'Document not found',
            ], 404);
        }

        $document->reject($request->user()->id, $request->reason);

        return response()->json([
            'success' => true,
            'message' => 'Document rejected',
        ]);
    }

    /**
     * Update rider status
     */
    public function updateRiderStatus(Request $request, string $riderId): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'status' => 'required|in:pending,approved,rejected,suspended',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $rider = Rider::find($riderId);
        if (!$rider) {
            return response()->json([
                'success' => false,
                'message' => 'Rider not found',
            ], 404);
        }

        $rider->update(['status' => $request->status]);

        // If suspended, force offline
        if ($request->status === 'suspended') {
            $rider->update(['is_online' => false]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Rider status updated',
        ]);
    }

    /**
     * List all online riders with locations
     */
    public function onlineRiders(): JsonResponse
    {
        $riders = Rider::with('vehicle')
            ->approved()
            ->online()
            ->whereNotNull('current_location')
            ->get()
            ->map(function ($rider) {
                $coords = DB::selectOne("
                    SELECT 
                        ST_Y(current_location::geometry) as lat,
                        ST_X(current_location::geometry) as lng
                    FROM riders WHERE id = ?
                ", [$rider->id]);

                return [
                    'id' => $rider->id,
                    'name' => $rider->name,
                    'phone' => $rider->phone,
                    'vehicle_number' => $rider->vehicle?->registration_number,
                    'rating' => $rider->rating_avg,
                    'is_available' => $rider->is_available,
                    'location' => [
                        'lat' => $coords->lat,
                        'lng' => $coords->lng,
                    ],
                    'heading' => $rider->current_heading,
                    'last_seen' => $rider->location_updated_at?->toIso8601String(),
                ];
            });

        return response()->json([
            'success' => true,
            'data' => [
                'riders' => $riders,
                'count' => $riders->count(),
            ],
        ]);
    }

    /**
     * List complaints
     */
    public function listComplaints(Request $request): JsonResponse
    {
        $query = Complaint::with([
            'complainantUser:id,name,phone',
            'againstRider:id,name,phone',
        ]);

        if ($request->status) {
            $query->where('status', $request->status);
        }

        if ($request->type) {
            $query->where('complaint_type', $request->type);
        }

        if ($request->priority) {
            $query->where('priority', '<=', $request->priority);
        }

        $complaints = $query->orderByDesc('created_at')
            ->paginate($request->get('per_page', 20));

        return response()->json([
            'success' => true,
            'data' => $complaints,
        ]);
    }

    /**
     * Get complaint details
     */
    public function getComplaint(string $complaintId): JsonResponse
    {
        $complaint = Complaint::with([
            'complainantUser',
            'againstRider',
            'rideLog',
        ])->find($complaintId);

        if (!$complaint) {
            return response()->json([
                'success' => false,
                'message' => 'Complaint not found',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $complaint,
        ]);
    }

    /**
     * Update complaint
     */
    public function updateComplaint(Request $request, string $complaintId): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'status' => 'sometimes|in:open,in_progress,resolved,closed',
            'priority' => 'sometimes|integer|min:1|max:5',
            'resolution_notes' => 'nullable|string|max:2000',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $complaint = Complaint::find($complaintId);

        if (!$complaint) {
            return response()->json([
                'success' => false,
                'message' => 'Complaint not found',
            ], 404);
        }

        $updateData = $request->only(['status', 'priority', 'resolution_notes']);

        if ($request->status === 'in_progress' && !$complaint->assigned_to) {
            $updateData['assigned_to'] = $request->user()->id;
        }

        if ($request->status === 'resolved') {
            $updateData['resolved_at'] = now();
        }

        $complaint->update($updateData);

        return response()->json([
            'success' => true,
            'message' => 'Complaint updated',
        ]);
    }

    /**
     * Get analytics
     */
    public function analytics(Request $request): JsonResponse
    {
        $days = $request->get('days', 30);
        $startDate = now()->subDays($days)->startOfDay();

        // Daily rides
        $dailyRides = RideLog::select(
            DB::raw('DATE(created_at) as date'),
            DB::raw('COUNT(*) as count')
        )
            ->where('created_at', '>=', $startDate)
            ->groupBy('date')
            ->orderBy('date')
            ->get();

        // Daily new users
        $dailyUsers = User::select(
            DB::raw('DATE(created_at) as date'),
            DB::raw('COUNT(*) as count')
        )
            ->where('created_at', '>=', $startDate)
            ->groupBy('date')
            ->orderBy('date')
            ->get();

        // Daily new riders
        $dailyRiders = Rider::select(
            DB::raw('DATE(created_at) as date'),
            DB::raw('COUNT(*) as count')
        )
            ->where('created_at', '>=', $startDate)
            ->groupBy('date')
            ->orderBy('date')
            ->get();

        // Rating distribution
        $ratingDistribution = Rating::select(
            'rating',
            DB::raw('COUNT(*) as count')
        )
            ->groupBy('rating')
            ->orderBy('rating')
            ->get();

        // Top riders
        $topRiders = Rider::select('id', 'name', 'rating_avg', 'total_rides')
            ->approved()
            ->orderByDesc('rating_avg')
            ->orderByDesc('total_rides')
            ->limit(10)
            ->get();

        // Complaint types
        $complaintTypes = Complaint::select(
            'complaint_type',
            DB::raw('COUNT(*) as count')
        )
            ->where('created_at', '>=', $startDate)
            ->groupBy('complaint_type')
            ->get();

        return response()->json([
            'success' => true,
            'data' => [
                'daily_rides' => $dailyRides,
                'daily_users' => $dailyUsers,
                'daily_riders' => $dailyRiders,
                'rating_distribution' => $ratingDistribution,
                'top_riders' => $topRiders,
                'complaint_types' => $complaintTypes,
            ],
        ]);
    }
}
