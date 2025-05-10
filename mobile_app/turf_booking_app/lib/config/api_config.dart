class ApiConfig {
  // Base URL for API requests
  // In development mode: Use localhost
  // static const String baseUrl = 'http://localhost:5000/api/mobile';
  
  // In production: Use the deployed API URL
  static const String baseUrl = 'https://turf-booking-app.replit.app/api/mobile';

  // API endpoints
  static const String loginEndpoint = '/login';
  static const String registerEndpoint = '/register';
  static const String registerOwnerEndpoint = '/register-owner';
  static const String profileEndpoint = '/user/profile';
  static const String turfsEndpoint = '/turfs';
  static const String bookingsEndpoint = '/bookings';
  static const String negotiationsEndpoint = '/negotiations';
  static const String ownerTurfsEndpoint = '/owner/turfs';
  static const String ownerBookingsEndpoint = '/owner/bookings';
  static const String ownerNegotiationsEndpoint = '/owner/negotiations';
  static const String analyticsEndpoint = '/owner/analytics';

  // API request timeout in seconds
  static const int requestTimeout = 15;

  // API request retry count
  static const int maxRetryCount = 3;
}