import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';

class ApiService {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: AppConstants.connectionTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: AppConstants.tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            // Token expired - clear and redirect to login
            _storage.delete(key: AppConstants.tokenKey);
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Auth
  Future<Response> requestOtp(String phone) async {
    return _dio.post(ApiConstants.requestOtp, data: {'phone': phone});
  }

  Future<Response> verifyOtp(
    String phone,
    String otp, {
    String? deviceToken,
  }) async {
    return _dio.post(
      ApiConstants.verifyOtp,
      data: {
        'phone': phone,
        'otp': otp,
        'device_token': deviceToken,
        'device_type': 'android',
      },
    );
  }

  Future<Response> logout() async {
    return _dio.post(ApiConstants.logout);
  }

  // Profile
  Future<Response> getProfile() async {
    return _dio.get(ApiConstants.profile);
  }

  Future<Response> updateProfile(Map<String, dynamic> data) async {
    return _dio.put(ApiConstants.profile, data: data);
  }

  // Discovery
  Future<Response> getNearbyAutos(double lat, double lng, {int? radius}) async {
    return _dio.get(
      ApiConstants.nearbyAutos,
      queryParameters: {
        'latitude': lat,
        'longitude': lng,
        if (radius != null) 'radius': radius,
      },
    );
  }

  Future<Response> getNearbyRoutes(
    double lat,
    double lng, {
    int? radius,
  }) async {
    return _dio.get(
      ApiConstants.nearbyRoutes,
      queryParameters: {
        'latitude': lat,
        'longitude': lng,
        if (radius != null) 'radius': radius,
      },
    );
  }

  Future<Response> getRiderDetails(
    String riderId, {
    double? lat,
    double? lng,
  }) async {
    return _dio.get(
      '${ApiConstants.riderDetails}/$riderId',
      queryParameters: {
        if (lat != null) 'latitude': lat,
        if (lng != null) 'longitude': lng,
      },
    );
  }

  // Tracking
  Future<Response> startTracking({
    required String riderId,
    String? routeId,
    double? pickupLat,
    double? pickupLng,
    String? pickupAddress,
  }) async {
    return _dio.post(
      ApiConstants.startTracking,
      data: {
        'rider_id': riderId,
        if (routeId != null) 'route_id': routeId,
        if (pickupLat != null) 'pickup_lat': pickupLat,
        if (pickupLng != null) 'pickup_lng': pickupLng,
        if (pickupAddress != null) 'pickup_address': pickupAddress,
      },
    );
  }

  Future<Response> endTracking(
    String rideId, {
    String? sessionId,
    double? dropoffLat,
    double? dropoffLng,
    String? dropoffAddress,
  }) async {
    return _dio.post(
      '${ApiConstants.endTracking}/$rideId/end',
      data: {
        if (sessionId != null) 'session_id': sessionId,
        if (dropoffLat != null) 'dropoff_lat': dropoffLat,
        if (dropoffLng != null) 'dropoff_lng': dropoffLng,
        if (dropoffAddress != null) 'dropoff_address': dropoffAddress,
      },
    );
  }

  Future<Response> shareRide(String rideId) async {
    return _dio.get('${ApiConstants.shareRide}/$rideId/share');
  }

  // Ratings
  Future<Response> rateRide(
    String rideId,
    int rating, {
    String? review,
    List<String>? tags,
  }) async {
    return _dio.post(
      '${ApiConstants.rateRide}/$rideId/rate',
      data: {
        'rating': rating,
        if (review != null) 'review': review,
        if (tags != null) 'tags': tags,
      },
    );
  }

  // Complaints
  Future<Response> fileComplaint({
    String? rideId,
    required String riderId,
    required String complaintType,
    required String subject,
    required String description,
  }) async {
    return _dio.post(
      ApiConstants.fileComplaint,
      data: {
        if (rideId != null) 'ride_id': rideId,
        'rider_id': riderId,
        'complaint_type': complaintType,
        'subject': subject,
        'description': description,
      },
    );
  }

  Future<Response> getComplaints() async {
    return _dio.get(ApiConstants.getComplaints);
  }

  // History
  Future<Response> getRideHistory({int page = 1, int perPage = 20}) async {
    return _dio.get(
      ApiConstants.rideHistory,
      queryParameters: {'page': page, 'per_page': perPage},
    );
  }

  // Notifications
  Future<Response> getNotifications() async {
    return _dio.get(ApiConstants.notifications);
  }

  Future<Response> markNotificationRead(String notificationId) async {
    return _dio.post('${ApiConstants.notifications}/$notificationId/read');
  }

  // SOS
  Future<Response> getSosInfo() async {
    return _dio.get(ApiConstants.sosInfo);
  }

  // Location
  Future<Response> updateLocation(double lat, double lng) async {
    return _dio.post(
      ApiConstants.updateLocation,
      data: {'latitude': lat, 'longitude': lng},
    );
  }

  // Token management
  Future<void> setToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: AppConstants.tokenKey);
  }

  Future<String?> getToken() async {
    return _storage.read(key: AppConstants.tokenKey);
  }
}
