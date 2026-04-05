class AppConstants {
  static const String appName = 'AutoWala Rider';
  static const String appTagline = 'Share your ride, earn more';

  // API
  static const String baseUrl = 'https://api.autowala.in/api';

  // Firebase
  static const String firebaseDbUrl =
      'https://autowala-default-rtdb.firebaseio.com';

  // Location
  static const int locationUpdateInterval = 5; // seconds
  static const double nearbyRadius = 5.0; // km

  // Document types
  static const List<String> requiredDocuments = [
    'driving_license',
    'vehicle_registration',
    'permit',
    'photo',
  ];

  // Document labels
  static const Map<String, String> documentLabels = {
    'driving_license': 'Driving License',
    'vehicle_registration': 'Vehicle Registration (RC)',
    'permit': 'Auto Permit',
    'photo': 'Profile Photo',
  };

  // KYC Status
  static const Map<String, String> kycStatusLabels = {
    'pending': 'Pending',
    'submitted': 'Under Review',
    'verified': 'Verified',
    'rejected': 'Rejected',
  };
}

class StorageKeys {
  static const String authToken = 'auth_token';
  static const String userId = 'user_id';
  static const String riderId = 'rider_id';
  static const String userData = 'user_data';
  static const String riderData = 'rider_data';
  static const String isOnline = 'is_online';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String fcmToken = 'fcm_token';
}
