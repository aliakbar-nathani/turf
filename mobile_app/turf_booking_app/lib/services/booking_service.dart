import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/booking_model.dart';
import '../models/negotiation_model.dart';

class BookingService {
  final String? authToken;
  final String baseUrl = ApiConfig.baseUrl;

  BookingService({this.authToken});

  // Create a booking request
  Future<Map<String, dynamic>> createBooking({
    required int turfId,
    required String bookingDate,
    required String timeSlotId,
    required String paymentOption,
    double? proposedPrice,
    String? message,
  }) async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final bookingData = {
        'turf_id': turfId,
        'booking_date': bookingDate,
        'time_slot_id': timeSlotId,
        'payment_option': paymentOption,
      };

      if (proposedPrice != null) {
        bookingData['proposed_price'] = proposedPrice;
      }

      if (message != null && message.isNotEmpty) {
        bookingData['message'] = message;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/bookings'),
        headers: _getHeaders(),
        body: jsonEncode(bookingData),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final booking = Booking.fromJson(responseData['booking']);

        return {
          'success': true,
          'message': responseData['message'] ?? 'Booking created successfully',
          'booking': booking,
          'payment_url': responseData['payment_url'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to create booking',
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

  // Get user bookings with optional status filter
  Future<Map<String, dynamic>> getUserBookings({String? status}) async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final uri = Uri.parse('$baseUrl/api/bookings/user')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final bookingsJson = responseData['bookings'] as List;
        final bookings = bookingsJson.map((json) => Booking.fromJson(json)).toList();

        return {
          'success': true,
          'bookings': bookings,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch bookings',
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

  // Get booking details
  Future<Map<String, dynamic>> getBookingDetails(int bookingId) async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/bookings/$bookingId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final booking = Booking.fromJson(responseData['booking']);

        return {
          'success': true,
          'booking': booking,
          'negotiation': responseData['negotiation'] != null
              ? Negotiation.fromJson(responseData['negotiation'])
              : null,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch booking details',
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
  Future<Map<String, dynamic>> cancelBooking(int bookingId, {String? reason}) async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final requestData = <String, dynamic>{};
      if (reason != null && reason.isNotEmpty) {
        requestData['reason'] = reason;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/bookings/$bookingId/cancel'),
        headers: _getHeaders(),
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Booking cancelled successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to cancel booking',
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

  // Create a new negotiation for a booking
  Future<Map<String, dynamic>> negotiatePrice({
    required int bookingId,
    required double proposedPrice,
    String? message,
  }) async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final negotiationData = {
        'proposed_price': proposedPrice,
      };

      if (message != null && message.isNotEmpty) {
        negotiationData['message'] = message;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/bookings/$bookingId/negotiate'),
        headers: _getHeaders(),
        body: jsonEncode(negotiationData),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final negotiation = Negotiation.fromJson(responseData['negotiation']);

        return {
          'success': true,
          'message': responseData['message'] ?? 'Negotiation created successfully',
          'negotiation': negotiation,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to create negotiation',
        };
      }
    } catch (e) {
      print('Error creating negotiation: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Respond to a negotiation as a user
  Future<Map<String, dynamic>> respondToNegotiationAsUser({
    required int negotiationId,
    required String action, // 'accept', 'reject', 'counter'
    double? proposedPrice,
    String? message,
  }) async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final requestData = {
        'action': action,
      };

      if (proposedPrice != null) {
        requestData['proposed_price'] = proposedPrice;
      }

      if (message != null && message.isNotEmpty) {
        requestData['message'] = message;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/negotiations/$negotiationId/user-response'),
        headers: _getHeaders(),
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Response submitted successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to respond to negotiation',
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

  // Report an issue with a booking
  Future<Map<String, dynamic>> reportBookingIssue({
    required int bookingId,
    required String title,
    required String description,
  }) async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final reportData = {
        'title': title,
        'description': description,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/bookings/$bookingId/report'),
        headers: _getHeaders(),
        body: jsonEncode(reportData),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Issue reported successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to report issue',
        };
      }
    } catch (e) {
      print('Error reporting issue: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // --------------- Owner-specific methods ---------------

  // Get bookings for turfs owned by the authenticated owner
  Future<Map<String, dynamic>> getOwnerBookings({String? status}) async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final uri = Uri.parse('$baseUrl/api/owner/bookings')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final bookingsJson = responseData['bookings'] as List;
        final bookings = bookingsJson.map((json) => Booking.fromJson(json)).toList();

        return {
          'success': true,
          'bookings': bookings,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch owner bookings',
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

  // Get negotiations for turfs owned by the authenticated owner
  Future<Map<String, dynamic>> getOwnerNegotiations({String? status}) async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final uri = Uri.parse('$baseUrl/api/owner/negotiations')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final negotiationsJson = responseData['negotiations'] as List;
        final negotiations = negotiationsJson
            .map((json) => Negotiation.fromJson(json))
            .toList();

        return {
          'success': true,
          'negotiations': negotiations,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch negotiations',
        };
      }
    } catch (e) {
      print('Error fetching owner negotiations: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Respond to a negotiation as an owner
  Future<Map<String, dynamic>> respondToNegotiationAsOwner({
    required int negotiationId,
    required String action, // 'accept', 'reject', 'counter'
    double? proposedPrice,
    String? message,
  }) async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final requestData = {
        'action': action,
      };

      if (proposedPrice != null) {
        requestData['proposed_price'] = proposedPrice;
      }

      if (message != null && message.isNotEmpty) {
        requestData['message'] = message;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/owner/negotiations/$negotiationId/respond'),
        headers: _getHeaders(),
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Response submitted successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to respond to negotiation',
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

  // Update booking status (owner only)
  Future<Map<String, dynamic>> updateBookingStatus({
    required int bookingId,
    required String status,
    String? message,
  }) async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final requestData = {
        'status': status,
      };

      if (message != null && message.isNotEmpty) {
        requestData['message'] = message;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/owner/bookings/$bookingId/status'),
        headers: _getHeaders(),
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Booking status updated successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update booking status',
        };
      }
    } catch (e) {
      print('Error updating booking status: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Check in a user for their booking (owner only)
  Future<Map<String, dynamic>> checkInBooking(int bookingId) async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/owner/bookings/$bookingId/check-in'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'User checked in successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to check in user',
        };
      }
    } catch (e) {
      print('Error checking in user: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Get issues reported for bookings (owner only)
  Future<Map<String, dynamic>> getReportedIssues({String? status}) async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final uri = Uri.parse('$baseUrl/api/owner/reported-issues')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'issues': responseData['issues'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch reported issues',
        };
      }
    } catch (e) {
      print('Error fetching reported issues: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Respond to a reported issue (owner only)
  Future<Map<String, dynamic>> respondToIssue({
    required int issueId,
    required String response,
    String? status,
  }) async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final requestData = {
        'response': response,
      };

      if (status != null && status.isNotEmpty) {
        requestData['status'] = status;
      }

      final apiResponse = await http.post(
        Uri.parse('$baseUrl/api/owner/reported-issues/$issueId/respond'),
        headers: _getHeaders(),
        body: jsonEncode(requestData),
      );

      if (apiResponse.statusCode == 200) {
        final responseData = jsonDecode(apiResponse.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Response submitted successfully',
        };
      } else {
        final errorData = jsonDecode(apiResponse.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to respond to issue',
        };
      }
    } catch (e) {
      print('Error responding to issue: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    return headers;
  }
}