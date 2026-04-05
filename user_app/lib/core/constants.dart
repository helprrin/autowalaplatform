class ApiConstants {
  static const String baseUrl = 'https://api.autowala.in/api';

  // Auth endpoints
  static const String requestOtp = '/user/auth/request-otp';
  static const String verifyOtp = '/user/auth/verify-otp';
  static const String logout = '/user/logout';
  static const String profile = '/user/profile';

  // Discovery
  static const String nearbyAutos = '/user/nearby-autos';
  static const String nearbyRoutes = '/user/nearby-routes';
  static const String riderDetails = '/user/rider';

  // Tracking
  static const String startTracking = '/user/track/start';
  static const String endTracking = '/user/track';
  static const String shareRide = '/user/track';

  // Ratings & Complaints
  static const String rateRide = '/user/ride';
  static const String fileComplaint = '/user/complaint';
  static const String getComplaints = '/user/complaints';

  // History
  static const String rideHistory = '/user/rides';

  // Notifications
  static const String notifications = '/user/notifications';

  // SOS
  static const String sosInfo = '/user/sos';

  // Location
  static const String updateLocation = '/user/location';
}

class AppConstants {
  static const String appName = 'AutoWala';
  static const String appTagline = 'Shared rides, simplified';

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String onboardingKey = 'onboarding_complete';

  // Firebase paths
  static const String ridersPath = 'riders';
  static const String activeSessionsPath = 'activeSessions';

  // Map defaults
  static const double defaultLat = 12.9716;
  static const double defaultLng = 77.5946;
  static const double defaultZoom = 15.0;

  // Location settings
  static const int locationUpdateInterval = 5; // seconds
  static const int nearbyRadius = 5000; // meters

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
