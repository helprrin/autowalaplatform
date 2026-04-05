import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../core/constants.dart';

// Auth state
class AuthState {
  final User? user;
  final String? token;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.token, this.isLoading = false, this.error});

  bool get isAuthenticated => token != null && user != null;

  AuthState copyWith({
    User? user,
    String? token,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthNotifier(this._api) : super(AuthState()) {
    _loadSavedAuth();
  }

  Future<void> _loadSavedAuth() async {
    state = state.copyWith(isLoading: true);

    try {
      final token = await _storage.read(key: AppConstants.tokenKey);
      final userJson = await _storage.read(key: AppConstants.userKey);

      if (token != null && userJson != null) {
        final user = User.fromJson(jsonDecode(userJson));
        state = AuthState(user: user, token: token);
      } else {
        state = AuthState();
      }
    } catch (e) {
      state = AuthState();
    }
  }

  Future<bool> requestOtp(String phone) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _api.requestOtp(phone);
      state = state.copyWith(isLoading: false);
      return response.data['success'] == true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to send OTP');
      return false;
    }
  }

  Future<bool> verifyOtp(
    String phone,
    String otp, {
    String? deviceToken,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _api.verifyOtp(
        phone,
        otp,
        deviceToken: deviceToken,
      );
      final data = response.data;

      if (data['success'] == true) {
        final user = User.fromJson(data['data']['user']);
        final token = data['data']['token'] as String;

        // Save to storage
        await _storage.write(key: AppConstants.tokenKey, value: token);
        await _storage.write(
          key: AppConstants.userKey,
          value: jsonEncode(user.toJson()),
        );
        await _api.setToken(token);

        state = AuthState(user: user, token: token);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: data['message'] ?? 'Verification failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Verification failed');
      return false;
    }
  }

  Future<bool> updateProfile(String name, {String? email}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _api.updateProfile({
        'name': name,
        if (email != null) 'email': email,
      });

      if (response.data['success'] == true) {
        final updatedUser = state.user?.copyWith(name: name, email: email);
        if (updatedUser != null) {
          await _storage.write(
            key: AppConstants.userKey,
            value: jsonEncode(updatedUser.toJson()),
          );
          state = state.copyWith(user: updatedUser, isLoading: false);
        }
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update profile',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update profile',
      );
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (e) {
      // Ignore logout API errors
    }

    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.userKey);
    await _api.clearToken();
    state = AuthState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final api = ref.watch(apiServiceProvider);
  return AuthNotifier(api);
});
