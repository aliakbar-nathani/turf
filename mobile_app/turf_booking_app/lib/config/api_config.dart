class ApiConfig {
  // Base URL for the API - this will need to be updated based on deployment
  static String get baseUrl {
    // For web platform, use the dynamic host
    if (Uri.base.toString() != 'null') {
      // Use http instead of https for development
      return 'http://${Uri.base.host}:5000';
    }
    // Default fallbacks
    return 'http://localhost:5000'; // Default to localhost
  }
  // Alternative URLs for different environments:
  // 'http://10.0.2.2:5000' - Android emulator pointing to localhost
  // 'http://localhost:5000' - For iOS simulator

  // Authentication endpoints
  static const String login = '/api/mobile/login';
  static const String register = '/api/mobile/register';
  static const String registerOwner = '/api/mobile/register';
  
  // Turf endpoints
  static const String turfs = '/api/mobile/turfs';
  static const String turfDetails = '/api/mobile/turf';
  static const String search = '/api/mobile/search';
  static const String advancedSearch = '/api/mobile/advanced_search';
  
  // Booking endpoints
  static const String bookings = '/api/mobile/user/bookings';
  static const String createBooking = '/api/mobile/booking/create';
  static const String ownerBookings = '/api/mobile/owner/bookings';
  
  // Negotiation endpoints
  static const String negotiation = '/api/mobile/booking/{id}/negotiation';
  static const String ownerNegotiation = '/api/mobile/owner/booking/{id}/negotiation';
  
  // User endpoints
  static const String userProfile = '/api/mobile/user/profile';
  static const String favorites = '/api/mobile/user/favorites';
  static const String notifications = '/api/mobile/user/notifications';
  
  // Payment endpoints
  static const String checkout = '/payment/mobile-checkout';
  static const String paymentStatus = '/payment/mobile-status';
  static const String paymentMethods = '/api/mobile/payment/methods';
  
  // Review endpoints
  static const String reviews = '/api/mobile/turf/{id}/reviews';
  static const String submitReview = '/api/mobile/turf/{id}/review';
  static const String updateReview = '/api/mobile/review/{id}';
  static const String deleteReview = '/api/mobile/review/{id}';
  static const String respondToReview = '/api/mobile/owner/review/{id}/respond';
  static const String userReviews = '/api/mobile/user/reviews';
  static const String canReviewTurf = '/api/mobile/turf/{id}/can_review';
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