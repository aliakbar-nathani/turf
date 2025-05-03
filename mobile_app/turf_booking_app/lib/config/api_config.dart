class ApiConfig {
  // Base URL for the API - this will need to be updated based on deployment
  static const String baseUrl = 'http://10.0.2.2:5000'; // Android emulator pointing to localhost
  // static const String baseUrl = 'http://localhost:5000'; // For iOS simulator

  // Authentication endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String registerOwner = '/auth/register_owner';
  
  // Turf endpoints
  static const String turfs = '/turf/list';
  static const String turfDetails = '/turf/details';
  static const String search = '/turf/search';
  static const String advancedSearch = '/turf/advanced_search';
  
  // Booking endpoints
  static const String bookings = '/user/bookings';
  static const String createBooking = '/booking/create';
  static const String ownerBookings = '/owner/bookings';
  
  // Negotiation endpoints
  static const String negotiation = '/booking/negotiate';
  static const String ownerNegotiation = '/owner/negotiate';
  
  // User endpoints
  static const String userProfile = '/user/profile';
  static const String favorites = '/user/favorites';
  static const String notifications = '/user/notifications';
  
  // Payment endpoints
  static const String checkout = '/payment/checkout';
  static const String paymentMethods = '/payment/methods';
}

class AppConstants {
  static const String appName = 'Turf Booking';
  static const String appVersion = '1.0.0';
  
  // Shared preferences keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userNameKey = 'user_name';
  static const String userRoleKey = 'user_role';
  static const String emailKey = 'email';
  
  // User roles
  static const String roleUser = 'USER';
  static const String roleOwner = 'OWNER';
  static const String roleAdmin = 'ADMIN';
  
  // Booking statuses
  static const String statusPending = 'pending';
  static const String statusNegotiating = 'negotiating';
  static const String statusConfirmed = 'confirmed';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';
  static const String statusPaymentPending = 'payment_pending';
}