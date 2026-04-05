# Firebase Realtime Database Structure

## Overview
Firebase is used **only** for real-time rider location tracking. All other data is stored in Supabase PostgreSQL.

## Data Structure

```json
{
  "riders": {
    "<rider_uuid>": {
      "location": {
        "latitude": 12.9716,
        "longitude": 77.5946,
        "heading": 45.0,
        "speed": 25.5,
        "accuracy": 10.0,
        "timestamp": 1712345678901
      },
      "status": {
        "isOnline": true,
        "isAvailable": true,
        "lastSeen": 1712345678901
      },
      "profile": {
        "name": "Rajesh Kumar",
        "phone": "+919876543210",
        "vehicleNumber": "KA01AB1234",
        "rating": 4.5
      },
      "currentRoute": {
        "routeId": "uuid-here",
        "routeName": "Koramangala to MG Road",
        "fare": 50.00
      }
    }
  },
  
  "activeSessions": {
    "<session_uuid>": {
      "riderId": "rider-uuid",
      "userId": "user-uuid",
      "startedAt": 1712345678901,
      "status": "tracking"
    }
  },
  
  "geohashes": {
    "tdr1wu": {
      "<rider_uuid>": {
        "latitude": 12.9716,
        "longitude": 77.5946,
        "timestamp": 1712345678901
      }
    }
  }
}
```

## Indexes

```json
{
  "rules": {
    "riders": {
      ".indexOn": ["status/isOnline", "status/lastSeen"]
    },
    "geohashes": {
      "$geohash": {
        ".indexOn": ["timestamp"]
      }
    }
  }
}
```

## Usage Patterns

### Rider App - Publishing Location
```dart
// Update location every 3-5 seconds
final ref = FirebaseDatabase.instance.ref('riders/$riderId/location');
await ref.set({
  'latitude': position.latitude,
  'longitude': position.longitude,
  'heading': position.heading,
  'speed': position.speed,
  'accuracy': position.accuracy,
  'timestamp': ServerValue.timestamp,
});
```

### User App - Subscribing to Rider Location
```dart
// Listen to specific rider's location
final ref = FirebaseDatabase.instance.ref('riders/$riderId/location');
ref.onValue.listen((event) {
  final data = event.snapshot.value as Map;
  // Update map marker
});
```

### Finding Nearby Riders (using Geohashes)
```dart
// Calculate geohash for user location
final userGeohash = GeoHash.encode(userLat, userLng, precision: 6);

// Query riders in same geohash area
final ref = FirebaseDatabase.instance.ref('geohashes/$userGeohash');
ref.onValue.listen((event) {
  // Process nearby riders
});
```

## Data Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Rider App   │────▶│  Firebase   │◀────│  User App   │
│ (Publish)   │     │  Realtime   │     │ (Subscribe) │
└─────────────┘     └─────────────┘     └─────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │ Cloud Func  │
                    │ (Optional)  │
                    └─────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  Supabase   │
                    │ (Analytics) │
                    └─────────────┘
```

## Cleanup Strategy

- Riders going offline should set `isOnline: false`
- Cloud function runs every 5 mins to clean stale data (lastSeen > 10 mins)
- Geohash entries auto-expire after 30 seconds of no updates

## Security Notes

1. Riders can only write to their own node
2. All authenticated users can read rider locations
3. Rate limiting via Firebase rules
4. No sensitive data in Firebase - only location and public profile
