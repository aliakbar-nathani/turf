class ApiConfig {
  // Base URL for API requests
  static const String baseUrl = 'https://turf-booking-app.example.com/api';

  // API endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String registerOwnerEndpoint = '/auth/register-owner';
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