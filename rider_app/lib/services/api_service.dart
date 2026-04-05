import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  final _storage = const FlutterSecureStorage();

  void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: StorageKeys.authToken);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            // Handle unauthorized
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Auth
  Future<Map<String, dynamic>> requestOtp(String phone) async {
    final response = await _dio.post(
      '/auth/rider/request-otp',
      data: {'phone': phone},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final response = await _dio.post(
      '/auth/rider/verify-otp',
      data: {'phone': phone, 'otp': otp},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await _dio.put('/rider/profile', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get('/rider/profile');
    return response.data;
  }

  // KYC
  Future<Map<String, dynamic>> uploadDocument(
    String type,
    String filePath,
  ) async {
    final formData = FormData.fromMap({
      'type': type,
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post('/rider/documents', data: formData);
    return response.data;
  }

  Future<List<dynamic>> getDocuments() async {
    final response = await _dio.get('/rider/documents');
    return response.data['data'];
  }

  Future<Map<String, dynamic>> submitKyc() async {
    final response = await _dio.post('/rider/kyc/submit');
    return response.data;
  }

  // Vehicle
  Future<Map<String, dynamic>> registerVehicle(
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post('/rider/vehicle', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateVehicle(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.put('/rider/vehicle/$id', data: data);
    return response.data;
  }

  // Routes
  Future<List<dynamic>> getRoutes() async {
    final response = await _dio.get('/rider/routes');
    return response.data['data'];
  }

  Future<Map<String, dynamic>> createRoute(Map<String, dynamic> data) async {
    final response = await _dio.post('/rider/routes', data: data);
    return response.data;
  }

  Future<void> deleteRoute(String id) async {
    await _dio.delete('/rider/routes/$id');
  }

  Future<Map<String, dynamic>> updateRoute(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.put('/rider/routes/$id', data: data);
    return response.data;
  }

  // Status
  Future<Map<String, dynamic>> goOnline() async {
    final response = await _dio.post('/rider/status/online');
    return response.data;
  }

  Future<Map<String, dynamic>> goOffline() async {
    final response = await _dio.post('/rider/status/offline');
    return response.data;
  }

  Future<void> updateLocation(double lat, double lng, double? heading) async {
    await _dio.post(
      '/rider/location',
      data: {'latitude': lat, 'longitude': lng, 'heading': heading},
    );
  }

  // Stats
  Future<Map<String, dynamic>> getStats() async {
    final response = await _dio.get('/rider/stats');
    return response.data;
  }

  Future<Map<String, dynamic>> getEarnings({
    String? startDate,
    String? endDate,
  }) async {
    final response = await _dio.get(
      '/rider/earnings',
      queryParameters: {
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      },
    );
    return response.data;
  }

  // Ratings
  Future<List<dynamic>> getRatings() async {
    final response = await _dio.get('/rider/ratings');
    return response.data['data'];
  }
}
