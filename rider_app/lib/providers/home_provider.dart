import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';
import 'auth_provider.dart';

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier(ref);
});

class HomeState {
  final bool isOnline;
  final bool isLoading;
  final Position? currentPosition;
  final RiderRoute? activeRoute;
  final List<RiderRoute> routes;
  final RiderStats? stats;
  final String? error;

  HomeState({
    this.isOnline = false,
    this.isLoading = false,
    this.currentPosition,
    this.activeRoute,
    this.routes = const [],
    this.stats,
    this.error,
  });

  HomeState copyWith({
    bool? isOnline,
    bool? isLoading,
    Position? currentPosition,
    RiderRoute? activeRoute,
    List<RiderRoute>? routes,
    RiderStats? stats,
    String? error,
  }) {
    return HomeState(
      isOnline: isOnline ?? this.isOnline,
      isLoading: isLoading ?? this.isLoading,
      currentPosition: currentPosition ?? this.currentPosition,
      activeRoute: activeRoute ?? this.activeRoute,
      routes: routes ?? this.routes,
      stats: stats ?? this.stats,
      error: error,
    );
  }
}

class HomeNotifier extends StateNotifier<HomeState> {
  HomeNotifier(this._ref) : super(HomeState());

  final Ref _ref;
  final _api = ApiService();
  final _firebase = FirebaseService();
  final _location = LocationService();

  StreamSubscription? _locationSubscription;

  Future<void> init() async {
    await _loadRoutes();
    await _loadStats();
    await _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final position = await _location.getCurrentPosition();
    if (position != null) {
      state = state.copyWith(currentPosition: position);
    }
  }

  Future<void> _loadRoutes() async {
    try {
      final routes = await _api.getRoutes();
      state = state.copyWith(
        routes: routes.map((r) => RiderRoute.fromJson(r)).toList(),
      );
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _api.getStats();
      state = state.copyWith(stats: RiderStats.fromJson(stats));
    } catch (e) {
      // Ignore
    }
  }

  Future<bool> goOnline({RiderRoute? route}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Check location permission
      final hasPermission = await _location.checkPermissions();
      if (!hasPermission) {
        state = state.copyWith(
          isLoading: false,
          error: 'Location permission required to go online.',
        );
        return false;
      }

      // Get current location
      final position = await _location.getCurrentPosition();
      if (position == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Unable to get location. Please enable GPS.',
        );
        return false;
      }

      // Call API
      await _api.goOnline();

      // Start Firebase location updates
      await _firebase.startLocationUpdates(
        latitude: position.latitude,
        longitude: position.longitude,
        heading: position.heading,
        routeId: route?.id,
      );

      // Start continuous location updates
      _locationSubscription?.cancel();
      _locationSubscription = _location.getPositionStream().listen((position) {
        _onLocationUpdate(position);
      });

      state = state.copyWith(
        isLoading: false,
        isOnline: true,
        activeRoute: route,
        currentPosition: position,
      );

      // Refresh auth state
      _ref.read(authProvider.notifier).refreshProfile();

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to go online. Please try again.',
      );
      return false;
    }
  }

  Future<bool> goOffline() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Stop location updates
      _locationSubscription?.cancel();
      _locationSubscription = null;

      // Stop Firebase updates
      await _firebase.stopLocationUpdates();

      // Call API
      await _api.goOffline();

      state = state.copyWith(
        isLoading: false,
        isOnline: false,
        activeRoute: null,
      );

      // Refresh auth state
      _ref.read(authProvider.notifier).refreshProfile();

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to go offline. Please try again.',
      );
      return false;
    }
  }

  void _onLocationUpdate(Position position) {
    state = state.copyWith(currentPosition: position);

    // Update Firebase
    _firebase.updateLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      heading: position.heading,
      routeId: state.activeRoute?.id,
    );
  }

  Future<void> setActiveRoute(RiderRoute? route) async {
    state = state.copyWith(activeRoute: route);

    if (state.isOnline) {
      // Update Firebase with new route
      final position = state.currentPosition;
      if (position != null) {
        await _firebase.updateLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          heading: position.heading,
          routeId: route?.id,
        );
      }
    }
  }

  Future<void> refreshRoutes() async {
    await _loadRoutes();
  }

  Future<void> refreshStats() async {
    await _loadStats();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
}
