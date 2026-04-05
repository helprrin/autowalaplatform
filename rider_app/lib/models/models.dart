class User {
  final String id;
  final String phone;
  final String? name;
  final String? email;
  final String? avatarUrl;
  final String status;
  final DateTime createdAt;

  User({
    required this.id,
    required this.phone,
    this.name,
    this.email,
    this.avatarUrl,
    required this.status,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      phone: json['phone'],
      name: json['name'],
      email: json['email'],
      avatarUrl: json['avatar_url'],
      status: json['status'] ?? 'active',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Rider {
  final String id;
  final String userId;
  final String? licenseNumber;
  final String status;
  final String kycStatus;
  final bool isOnline;
  final double ratingAvg;
  final int totalRides;
  final double? latitude;
  final double? longitude;
  final Vehicle? vehicle;
  final User? user;
  final DateTime createdAt;

  Rider({
    required this.id,
    required this.userId,
    this.licenseNumber,
    required this.status,
    required this.kycStatus,
    required this.isOnline,
    required this.ratingAvg,
    required this.totalRides,
    this.latitude,
    this.longitude,
    this.vehicle,
    this.user,
    required this.createdAt,
  });

  bool get isKycComplete => kycStatus == 'verified';
  bool get canGoOnline => status == 'approved' && isKycComplete;

  factory Rider.fromJson(Map<String, dynamic> json) {
    return Rider(
      id: json['id'],
      userId: json['user_id'],
      licenseNumber: json['license_number'],
      status: json['status'] ?? 'pending',
      kycStatus: json['kyc_status'] ?? 'pending',
      isOnline: json['is_online'] ?? false,
      ratingAvg: (json['rating_avg'] ?? 0).toDouble(),
      totalRides: json['total_rides'] ?? 0,
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      vehicle: json['vehicle'] != null
          ? Vehicle.fromJson(json['vehicle'])
          : null,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Vehicle {
  final String id;
  final String riderId;
  final String vehicleNumber;
  final String vehicleType;
  final String? color;
  final String? make;
  final String? model;
  final int? year;
  final bool isActive;

  Vehicle({
    required this.id,
    required this.riderId,
    required this.vehicleNumber,
    required this.vehicleType,
    this.color,
    this.make,
    this.model,
    this.year,
    required this.isActive,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      riderId: json['rider_id'],
      vehicleNumber: json['vehicle_number'],
      vehicleType: json['vehicle_type'] ?? 'auto',
      color: json['color'],
      make: json['make'],
      model: json['model'],
      year: json['year'],
      isActive: json['is_active'] ?? true,
    );
  }
}

class Document {
  final String id;
  final String riderId;
  final String type;
  final String fileUrl;
  final String status;
  final String? rejectionReason;
  final DateTime createdAt;

  Document({
    required this.id,
    required this.riderId,
    required this.type,
    required this.fileUrl,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'],
      riderId: json['rider_id'],
      type: json['type'],
      fileUrl: json['file_url'],
      status: json['status'] ?? 'pending',
      rejectionReason: json['rejection_reason'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class RiderRoute {
  final String id;
  final String riderId;
  final String name;
  final String startAddress;
  final String endAddress;
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;
  final double fare;
  final bool isActive;
  final List<RoutePoint>? points;
  final DateTime createdAt;

  RiderRoute({
    required this.id,
    required this.riderId,
    required this.name,
    required this.startAddress,
    required this.endAddress,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    required this.fare,
    required this.isActive,
    this.points,
    required this.createdAt,
  });

  factory RiderRoute.fromJson(Map<String, dynamic> json) {
    return RiderRoute(
      id: json['id'],
      riderId: json['rider_id'],
      name: json['name'],
      startAddress: json['start_address'],
      endAddress: json['end_address'],
      startLat: (json['start_latitude'] ?? json['start_lat']).toDouble(),
      startLng: (json['start_longitude'] ?? json['start_lng']).toDouble(),
      endLat: (json['end_latitude'] ?? json['end_lat']).toDouble(),
      endLng: (json['end_longitude'] ?? json['end_lng']).toDouble(),
      fare: (json['fare'] ?? 0).toDouble(),
      isActive: json['is_active'] ?? false,
      points: (json['points'] as List?)
          ?.map((p) => RoutePoint.fromJson(p))
          .toList(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'start_address': startAddress,
      'end_address': endAddress,
      'start_latitude': startLat,
      'start_longitude': startLng,
      'end_latitude': endLat,
      'end_longitude': endLng,
      'fare': fare,
      'is_active': isActive,
    };
  }
}

class RoutePoint {
  final String id;
  final String routeId;
  final int sequence;
  final double latitude;
  final double longitude;
  final String? address;

  RoutePoint({
    required this.id,
    required this.routeId,
    required this.sequence,
    required this.latitude,
    required this.longitude,
    this.address,
  });

  factory RoutePoint.fromJson(Map<String, dynamic> json) {
    return RoutePoint(
      id: json['id'],
      routeId: json['route_id'],
      sequence: json['sequence'],
      latitude: (json['latitude']).toDouble(),
      longitude: (json['longitude']).toDouble(),
      address: json['address'],
    );
  }
}

class RiderStats {
  final int totalRides;
  final int ridesThisWeek;
  final int ridesThisMonth;
  final double ratingAvg;
  final int totalRatings;

  RiderStats({
    required this.totalRides,
    required this.ridesThisWeek,
    required this.ridesThisMonth,
    required this.ratingAvg,
    required this.totalRatings,
  });

  factory RiderStats.fromJson(Map<String, dynamic> json) {
    return RiderStats(
      totalRides: json['total_rides'] ?? 0,
      ridesThisWeek: json['rides_this_week'] ?? 0,
      ridesThisMonth: json['rides_this_month'] ?? 0,
      ratingAvg: (json['rating_avg'] ?? 0).toDouble(),
      totalRatings: json['total_ratings'] ?? 0,
    );
  }
}
