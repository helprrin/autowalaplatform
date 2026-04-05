import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';
import '../core/constants.dart';
import 'auth_provider.dart';

// Location state
class LocationState {
  final Position? currentPosition;
  final bool isLoading;
  final String? error;

  LocationState({this.currentPosition, this.isLoading = false, this.error});

  LocationState copyWith({
    Position? currentPosition,
    bool? isLoading,
    String? error,
  }) {
    return LocationState(
      currentPosition: currentPosition ?? this.currentPosition,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  final LocationService _locationService;

  LocationNotifier(this._locationService) : super(LocationState()) {
    _init();
  }

  Future<void> _init() async {
    await getCurrentLocation();
  }

  Future<void> getCurrentLocation() async {
    state = state.copyWith(isLoading: true, error: null);

    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      state = state.copyWith(currentPosition: position, isLoading: false);
    } else {
      state = state.copyWith(
        isLoading: false,
        error: 'Could not get location. Please enable location services.',
      );
    }
  }

  void updateLocation(Position position) {
    state = state.copyWith(currentPosition: position);
  }
}

// Nearby riders state
class NearbyRidersState {
  final List<NearbyRider> riders;
  final bool isLoading;
  final String? error;

  NearbyRidersState({
    this.riders = const [],
    this.isLoading = false,
    this.error,
  });

  NearbyRidersState copyWith({
    List<NearbyRider>? riders,
    bool? isLoading,
    String? error,
  }) {
    return NearbyRidersState(
      riders: riders ?? this.riders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NearbyRidersNotifier extends StateNotifier<NearbyRidersState> {
  final ApiService _api;
  final FirebaseService _firebase;
  StreamSubscription? _subscription;

  NearbyRidersNotifier(this._api, this._firebase) : super(NearbyRidersState());

  Future<void> fetchNearbyRiders(double lat, double lng) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _api.getNearbyAutos(lat, lng);

      if (response.data['success'] == true) {
        final ridersData = response.data['data']['autos'] as List;
        final riders = ridersData.map((r) => NearbyRider.fromJson(r)).toList();
        state = state.copyWith(riders: riders, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to fetch nearby autos',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch nearby autos',
      );
    }
  }

  void subscribeToRiders() {
    _subscription?.cancel();
    _subscription = _firebase.subscribeToNearbyRiders().listen((ridersData) {
      final riders = ridersData
          .map((data) {
            final location = data['location'] as Map<String, dynamic>?;
            final profile = data['profile'] as Map<String, dynamic>?;
            final status = data['status'] as Map<String, dynamic>?;

            if (location == null || profile == null) return null;
            if (status?['isOnline'] != true || status?['isAvailable'] != true)
              return null;

            return NearbyRider(
              id: data['id'] as String,
              name: profile['name'] as String? ?? 'Unknown',
              phone: profile['phone'] as String? ?? '',
              ratingAvg: (profile['rating'] as num?)?.toDouble() ?? 5.0,
              ratingCount: 0,
              distanceMeters: 0,
              latitude: (location['latitude'] as num).toDouble(),
              longitude: (location['longitude'] as num).toDouble(),
              heading: (location['heading'] as num?)?.toDouble(),
              vehicleNumber: profile['vehicleNumber'] as String?,
            );
          })
          .whereType<NearbyRider>()
          .toList();

      state = state.copyWith(riders: riders);
    });
  }

  void unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    unsubscribe();
    super.dispose();
  }
}

// Tracking state
class TrackingState {
  final String? rideId;
  final String? sessionId;
  final String? riderId;
  final RiderLocation? riderLocation;
  final bool isTracking;
  final String? error;

  TrackingState({
    this.rideId,
    this.sessionId,
    this.riderId,
    this.riderLocation,
    this.isTracking = false,
    this.error,
  });

  TrackingState copyWith({
    String? rideId,
    String? sessionId,
    String? riderId,
    RiderLocation? riderLocation,
    bool? isTracking,
    String? error,
  }) {
    return TrackingState(
      rideId: rideId ?? this.rideId,
      sessionId: sessionId ?? this.sessionId,
      riderId: riderId ?? this.riderId,
      riderLocation: riderLocation ?? this.riderLocation,
      isTracking: isTracking ?? this.isTracking,
      error: error,
    );
  }
}

class TrackingNotifier extends StateNotifier<TrackingState> {
  final ApiService _api;
  final FirebaseService _firebase;
  StreamSubscription? _locationSubscription;

  TrackingNotifier(this._api, this._firebase) : super(TrackingState());

  Future<bool> startTracking({
    required String riderId,
    String? routeId,
    double? pickupLat,
    double? pickupLng,
    String? pickupAddress,
  }) async {
    try {
      final response = await _api.startTracking(
        riderId: riderId,
        routeId: routeId,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        pickupAddress: pickupAddress,
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];

        state = state.copyWith(
          rideId: data['ride_id'],
          sessionId: data['session_id'],
          riderId: riderId,
          isTracking: true,
        );

        // Subscribe to rider's location
        _subscribeToRiderLocation(riderId);

        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: 'Failed to start tracking');
      return false;
    }
  }

  void _subscribeToRiderLocation(String riderId) {
    _locationSubscription?.cancel();
    _locationSubscription = _firebase.subscribeToRiderLocation(riderId).listen((
      data,
    ) {
      if (data != null) {
        state = state.copyWith(riderLocation: RiderLocation.fromJson(data));
      }
    });
  }

  Future<bool> endTracking({
    double? dropoffLat,
    double? dropoffLng,
    String? dropoffAddress,
  }) async {
    if (state.rideId == null) return false;

    try {
      final response = await _api.endTracking(
        state.rideId!,
        sessionId: state.sessionId,
        dropoffLat: dropoffLat,
        dropoffLng: dropoffLng,
        dropoffAddress: dropoffAddress,
      );

      if (response.data['success'] == true) {
        _locationSubscription?.cancel();
        state = TrackingState();
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: 'Failed to end tracking');
      return false;
    }
  }

  void cancelTracking() {
    _locationSubscription?.cancel();
    state = TrackingState();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
}

// Providers
final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);
final firebaseServiceProvider = Provider<FirebaseService>(
  (ref) => FirebaseService(),
);

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>(
  (ref) {
    final locationService = ref.watch(locationServiceProvider);
    return LocationNotifier(locationService);
  },
);

final nearbyRidersProvider =
    StateNotifierProvider<NearbyRidersNotifier, NearbyRidersState>((ref) {
      final api = ref.watch(apiServiceProvider);
      final firebase = ref.watch(firebaseServiceProvider);
      return NearbyRidersNotifier(api, firebase);
    });

final trackingProvider = StateNotifierProvider<TrackingNotifier, TrackingState>(
  (ref) {
    final api = ref.watch(apiServiceProvider);
    final firebase = ref.watch(firebaseServiceProvider);
    return TrackingNotifier(api, firebase);
  },
);
