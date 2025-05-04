class AppConstants {
  static const String appName = 'Turf Booking';
  static const String appVersion = '1.0.0';
  
  // API Base URL - dynamically set via API Config
  static const String apiBaseUrl = 'https://your-replit-app.replit.app/api/mobile';
  
  // Authentication
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userNameKey = 'user_name';
  static const String emailKey = 'email';
  static const String userRoleKey = 'user_role';
  static const String userPhoneKey = 'user_phone';
  
  // User roles
  static const String roleUser = 'USER';
  static const String roleOwner = 'OWNER';
  static const String roleAdmin = 'ADMIN';
  
  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String refreshTokenEndpoint = '/auth/refresh-token';
  static const String userProfileEndpoint = '/user/profile';
  static const String turfListEndpoint = '/turfs';
  static const String turfDetailsEndpoint = '/turfs/';
  static const String bookingsEndpoint = '/bookings';
  static const String reviewsEndpoint = '/reviews';
  static const String favoriteEndpoint = '/favorites';
  
  // Pagination
  static const int defaultPageSize = 10;
  
  // Timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
}