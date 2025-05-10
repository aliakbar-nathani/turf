import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';

class BookingService {
  final String baseUrl = ApiConfig.baseUrl;
  final AuthService _authService = AuthService();
  
  // Get user bookings
  Future<Map<String, dynamic>> getUserBookings() async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/user/bookings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'bookings': responseData['bookings'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch bookings',
        };
      }
    } catch (e) {
      print('Error fetching user bookings: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  // Get owner bookings
  Future<Map<String, dynamic>> getOwnerBookings() async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/owner/bookings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'bookings': responseData['bookings'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch owner bookings',
        };
      }
    } catch (e) {
      print('Error fetching owner bookings: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  // Create a booking
  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> bookingData) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/bookings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(bookingData),
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Booking created successfully',
          'booking': responseData['booking'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to create booking',
        };
      }
    } catch (e) {
      print('Error creating booking: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  // Create an owner booking (for customers not using the app)
  Future<Map<String, dynamic>> createOwnerBooking(Map<String, dynamic> bookingData) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/owner/bookings/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(bookingData),
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Booking created successfully',
          'booking': responseData['booking'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to create booking',
        };
      }
    } catch (e) {
      print('Error creating owner booking: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  // Get booking details
  Future<Map<String, dynamic>> getBookingDetails(int bookingId) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/$bookingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'booking': responseData['booking'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch booking details',
        };
      }
    } catch (e) {
      print('Error fetching booking details: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  // Cancel a booking
  Future<Map<String, dynamic>> cancelBooking(int bookingId) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/bookings/$bookingId/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Booking cancelled successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to cancel booking',
        };
      }
    } catch (e) {
      print('Error cancelling booking: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  // Submit a price negotiation
  Future<Map<String, dynamic>> negotiatePrice(
    int bookingId,
    double proposedPrice,
    String message,
  ) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/bookings/$bookingId/negotiate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'proposed_price': proposedPrice,
          'message': message,
        }),
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Negotiation submitted successfully',
          'negotiation': responseData['negotiation'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to submit negotiation',
        };
      }
    } catch (e) {
      print('Error submitting negotiation: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  // Respond to a negotiation (accept, reject, counter)
  Future<Map<String, dynamic>> respondToNegotiation(
    int bookingId,
    String action,
    double? proposedPrice,
    String? message,
  ) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }
      
      // Build request data based on action
      final data = {
        'action': action,
      };
      
      if (action == 'counter' && proposedPrice != null) {
        data['proposed_price'] = proposedPrice;
      }
      
      if (message != null && message.isNotEmpty) {
        data['message'] = message;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/booking/$bookingId/negotiation'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Response submitted successfully',
          'booking': responseData['booking'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to respond to negotiation',
        };
      }
    } catch (e) {
      print('Error responding to negotiation: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  // Owner-specific version of respond to negotiation
  Future<Map<String, dynamic>> ownerRespondToNegotiation(
    int bookingId,
    String action,
    double? proposedPrice,
    String? message,
  ) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }
      
      // Build request data based on action
      final data = {
        'action': action,
      };
      
      if (action == 'counter' && proposedPrice != null) {
        data['proposed_price'] = proposedPrice;
      }
      
      if (message != null && message.isNotEmpty) {
        data['message'] = message;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/owner/negotiations/respond/$bookingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Response submitted successfully',
          'booking': responseData['booking'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to respond to negotiation',
        };
      }
    } catch (e) {
      print('Error responding to negotiation: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
}