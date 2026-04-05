class User {
  final String id;
  final String phone;
  final String? name;
  final String? email;
  final String? avatarUrl;
  final String status;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.phone,
    this.name,
    this.email,
    this.avatarUrl,
    this.status = 'active',
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      phone: json['phone'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'email': email,
      'avatar_url': avatarUrl,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? phone,
    String? name,
    String? email,
    String? avatarUrl,
    String? status,
  }) {
    return User(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  bool get isProfileComplete => name != null && name!.isNotEmpty;
}

class NearbyRider {
  final String id;
  final String name;
  final String phone;
  final String? avatarUrl;
  final double ratingAvg;
  final int ratingCount;
  final double distanceMeters;
  final double latitude;
  final double longitude;
  final double? heading;
  final String? vehicleNumber;
  final String? vehicleColor;
  final int? etaMinutes;
  final List<RiderRoute>? activeRoutes;

  NearbyRider({
    required this.id,
    required this.name,
    required this.phone,
    this.avatarUrl,
    required this.ratingAvg,
    required this.ratingCount,
    required this.distanceMeters,
    required this.latitude,
    required this.longitude,
    this.heading,
    this.vehicleNumber,
    this.vehicleColor,
    this.etaMinutes,
    this.activeRoutes,
  });

  factory NearbyRider.fromJson(Map<String, dynamic> json) {
    return NearbyRider(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      avatarUrl: json['avatar_url'] as String?,
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 5.0,
      ratingCount: json['rating_count'] as int? ?? 0,
      distanceMeters: (json['distance_meters'] as num).toDouble(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      vehicleNumber: json['vehicle_number'] as String?,
      vehicleColor: json['vehicle_color'] as String?,
      etaMinutes: json['eta_minutes'] as int?,
      activeRoutes: json['active_routes'] != null
          ? (json['active_routes'] as List)
                .map((r) => RiderRoute.fromJson(r as Map<String, dynamic>))
                .toList()
          : null,
    );
  }

  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  String get formattedEta {
    if (etaMinutes == null) return 'N/A';
    if (etaMinutes! < 1) return '< 1 min';
    return '$etaMinutes min';
  }
}

class RiderRoute {
  final String id;
  final String name;
  final String? startAddress;
  final String? endAddress;
  final double baseFare;

  RiderRoute({
    required this.id,
    required this.name,
    this.startAddress,
    this.endAddress,
    required this.baseFare,
  });

  factory RiderRoute.fromJson(Map<String, dynamic> json) {
    return RiderRoute(
      id: json['id'] as String,
      name: json['name'] as String,
      startAddress: json['start_address'] as String?,
      endAddress: json['end_address'] as String?,
      baseFare: (json['base_fare'] as num).toDouble(),
    );
  }
}

class RideLog {
  final String id;
  final NearbyRider rider;
  final String? routeName;
  final String? pickupAddress;
  final String? dropoffAddress;
  final double? fareShown;
  final bool isCompleted;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? myRating;
  final bool hasRated;

  RideLog({
    required this.id,
    required this.rider,
    this.routeName,
    this.pickupAddress,
    this.dropoffAddress,
    this.fareShown,
    required this.isCompleted,
    this.startedAt,
    this.endedAt,
    this.myRating,
    required this.hasRated,
  });

  factory RideLog.fromJson(Map<String, dynamic> json) {
    return RideLog(
      id: json['id'] as String,
      rider: NearbyRider.fromJson(json['rider'] as Map<String, dynamic>),
      routeName: json['route_name'] as String?,
      pickupAddress: json['pickup_address'] as String?,
      dropoffAddress: json['dropoff_address'] as String?,
      fareShown: (json['fare_shown'] as num?)?.toDouble(),
      isCompleted: json['is_completed'] as bool? ?? false,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
      myRating: json['my_rating'] as int?,
      hasRated: json['has_rated'] as bool? ?? false,
    );
  }
}

class RiderLocation {
  final double latitude;
  final double longitude;
  final double? heading;
  final double? speed;
  final double? accuracy;
  final int timestamp;

  RiderLocation({
    required this.latitude,
    required this.longitude,
    this.heading,
    this.speed,
    this.accuracy,
    required this.timestamp,
  });

  factory RiderLocation.fromJson(Map<String, dynamic> json) {
    return RiderLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      timestamp: json['timestamp'] as int,
    );
  }
}
