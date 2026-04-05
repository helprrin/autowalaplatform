import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../core/constants.dart';

class FirebaseService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Subscribe to a specific rider's location
  Stream<Map<String, dynamic>?> subscribeToRiderLocation(String riderId) {
    return _database
        .ref('${AppConstants.ridersPath}/$riderId/location')
        .onValue
        .map((event) {
          if (event.snapshot.value == null) return null;
          return Map<String, dynamic>.from(event.snapshot.value as Map);
        });
  }

  // Subscribe to rider's full data (location, status, profile, route)
  Stream<Map<String, dynamic>?> subscribeToRider(String riderId) {
    return _database.ref('${AppConstants.ridersPath}/$riderId').onValue.map((
      event,
    ) {
      if (event.snapshot.value == null) return null;
      return Map<String, dynamic>.from(event.snapshot.value as Map);
    });
  }

  // Get all nearby riders (one-time fetch)
  Future<List<Map<String, dynamic>>> getNearbyRiders() async {
    final snapshot = await _database
        .ref(AppConstants.ridersPath)
        .orderByChild('status/isOnline')
        .equalTo(true)
        .get();

    if (snapshot.value == null) return [];

    final ridersMap = Map<String, dynamic>.from(snapshot.value as Map);
    return ridersMap.entries.map((e) {
      final data = Map<String, dynamic>.from(e.value as Map);
      data['id'] = e.key;
      return data;
    }).toList();
  }

  // Subscribe to nearby riders (real-time)
  Stream<List<Map<String, dynamic>>> subscribeToNearbyRiders() {
    return _database
        .ref(AppConstants.ridersPath)
        .orderByChild('status/isOnline')
        .equalTo(true)
        .onValue
        .map((event) {
          if (event.snapshot.value == null) return [];

          final ridersMap = Map<String, dynamic>.from(
            event.snapshot.value as Map,
          );
          return ridersMap.entries.map((e) {
            final data = Map<String, dynamic>.from(e.value as Map);
            data['id'] = e.key;
            return data;
          }).toList();
        });
  }

  // Check if rider is online
  Future<bool> isRiderOnline(String riderId) async {
    final snapshot = await _database
        .ref('${AppConstants.ridersPath}/$riderId/status/isOnline')
        .get();
    return snapshot.value == true;
  }

  // Create tracking session
  Future<void> createTrackingSession({
    required String sessionId,
    required String riderId,
    required String userId,
  }) async {
    await _database.ref('${AppConstants.activeSessionsPath}/$sessionId').set({
      'riderId': riderId,
      'userId': userId,
      'startedAt': ServerValue.timestamp,
      'status': 'tracking',
    });
  }

  // End tracking session
  Future<void> endTrackingSession(String sessionId) async {
    await _database
        .ref('${AppConstants.activeSessionsPath}/$sessionId')
        .remove();
  }
}
