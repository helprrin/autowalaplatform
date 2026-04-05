import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';
import '../core/constants.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final User? user;
  final Rider? rider;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.rider,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    User? user,
    Rider? rider,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      rider: rider ?? this.rider,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState());

  final _api = ApiService();
  final _firebase = FirebaseService();
  final _storage = const FlutterSecureStorage();

  Future<void> init() async {
    _api.init();
    await _firebase.init();

    final token = await _storage.read(key: StorageKeys.authToken);
    if (token != null) {
      await _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    try {
      state = state.copyWith(isLoading: true);
      final response = await _api.getProfile();
      final user = User.fromJson(response['user']);
      final rider = Rider.fromJson(response['rider']);

      await _firebase.setRiderId(rider.id);

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
        rider: rider,
      );
    } catch (e) {
      await _storage.deleteAll();
      state = state.copyWith(isLoading: false, isAuthenticated: false);
    }
  }

  Future<bool> requestOtp(String phone) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _api.requestOtp(phone);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to send OTP. Please try again.',
      );
      return false;
    }
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final response = await _api.verifyOtp(phone, otp);

      await _storage.write(
        key: StorageKeys.authToken,
        value: response['token'],
      );

      final user = User.fromJson(response['user']);
      final rider = response['rider'] != null
          ? Rider.fromJson(response['rider'])
          : null;

      if (rider != null) {
        await _firebase.setRiderId(rider.id);
      }

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
        rider: rider,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Invalid OTP. Please try again.',
      );
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final response = await _api.updateProfile(data);

      final user = User.fromJson(response['user']);
      final rider = response['rider'] != null
          ? Rider.fromJson(response['rider'])
          : null;

      state = state.copyWith(isLoading: false, user: user, rider: rider);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update profile.',
      );
      return false;
    }
  }

  Future<void> refreshProfile() async {
    await _loadProfile();
  }

  Future<void> logout() async {
    await _firebase.cleanup();
    await _storage.deleteAll();
    state = AuthState();
  }
}
