import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final _database = FirebaseDatabase.instance;
  final _storage = const FlutterSecureStorage();
  Timer? _locationTimer;
  StreamSubscription? _sessionSubscription;

  String? _riderId;
  bool _isOnline = false;

  Future<void> init() async {
    _riderId = await _storage.read(key: StorageKeys.riderId);
  }

  Future<void> setRiderId(String riderId) async {
    _riderId = riderId;
    await _storage.write(key: StorageKeys.riderId, value: riderId);
  }

  /// Start broadcasting location
  Future<void> startLocationUpdates({
    required double latitude,
    required double longitude,
    double? heading,
    String? routeId,
  }) async {
    if (_riderId == null) return;

    _isOnline = true;

    // Update rider location in Firebase
    await _updateLocation(latitude, longitude, heading, routeId);

    // Start periodic updates
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(
      const Duration(seconds: AppConstants.locationUpdateInterval),
      (_) async {
        if (_isOnline) {
          // Location will be updated by the provider
        }
      },
    );
  }

  Future<void> _updateLocation(
    double latitude,
    double longitude,
    double? heading,
    String? routeId,
  ) async {
    if (_riderId == null) return;

    final geohash = _encodeGeohash(latitude, longitude);
    final timestamp = ServerValue.timestamp;

    // Update in /riders_live/{riderId}
    await _database.ref('riders_live/$_riderId').update({
      'location': {
        'lat': latitude,
        'lng': longitude,
        'heading': heading ?? 0,
        'geohash': geohash,
      },
      'updated_at': timestamp,
      'is_online': true,
      if (routeId != null) 'active_route_id': routeId,
    });

    // Also update in geohash index for efficient queries
    await _database
        .ref('riders_by_geohash/${geohash.substring(0, 6)}/$_riderId')
        .set({'lat': latitude, 'lng': longitude, 'updated_at': timestamp});
  }

  /// Update location manually
  Future<void> updateLocation({
    required double latitude,
    required double longitude,
    double? heading,
    String? routeId,
  }) async {
    if (!_isOnline) return;
    await _updateLocation(latitude, longitude, heading, routeId);
  }

  /// Stop broadcasting location
  Future<void> stopLocationUpdates() async {
    _isOnline = false;
    _locationTimer?.cancel();
    _locationTimer = null;

    if (_riderId != null) {
      // Mark as offline
      await _database.ref('riders_live/$_riderId').update({
        'is_online': false,
        'updated_at': ServerValue.timestamp,
      });
    }
  }

  /// Clean up old data
  Future<void> cleanup() async {
    await stopLocationUpdates();
    _sessionSubscription?.cancel();
  }

  /// Encode lat/lng to geohash
  String _encodeGeohash(double latitude, double longitude) {
    const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
    var minLat = -90.0, maxLat = 90.0;
    var minLng = -180.0, maxLng = 180.0;
    var hash = '';
    var isEven = true;
    var bit = 0;
    var ch = 0;

    while (hash.length < 9) {
      if (isEven) {
        final mid = (minLng + maxLng) / 2;
        if (longitude > mid) {
          ch |= (1 << (4 - bit));
          minLng = mid;
        } else {
          maxLng = mid;
        }
      } else {
        final mid = (minLat + maxLat) / 2;
        if (latitude > mid) {
          ch |= (1 << (4 - bit));
          minLat = mid;
        } else {
          maxLat = mid;
        }
      }
      isEven = !isEven;
      if (bit < 4) {
        bit++;
      } else {
        hash += base32[ch];
        bit = 0;
        ch = 0;
      }
    }
    return hash;
  }
}
