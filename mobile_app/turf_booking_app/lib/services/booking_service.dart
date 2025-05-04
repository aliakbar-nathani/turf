import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/booking_model.dart';

class BookingService {
  final String? authToken;

  BookingService({this.authToken});

  Future<Map<String, dynamic>> getBookings() async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.bookings}'),
        headers: _getHeaders(),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        final List<Booking> bookings = (responseData['bookings'] as List)
            .map((bookingJson) => Booking.fromJson(bookingJson))
            .toList();

        return {
          'success': true,
          'bookings': bookings,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch bookings',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getOwnerBookings() async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ownerBookings}'),
        headers: _getHeaders(),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        final List<Booking> bookings = (responseData['bookings'] as List)
            .map((bookingJson) => Booking.fromJson(bookingJson))
            .toList();

        return {
          'success': true,
          'bookings': bookings,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch owner bookings',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> createBooking({
    required int turfId,
    required String bookingDate,
    required String timeSlot,
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

      final Map<String, dynamic> bookingData = {
        'turf_id': turfId,
        'booking_date': bookingDate,
        'time_slot': timeSlot,
        'payment_option': paymentOption,
      };

      if (proposedPrice != null) {
        bookingData['proposed_price'] = proposedPrice;
      }

      if (message != null && message.isNotEmpty) {
        bookingData['message'] = message;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.createBooking}'),
        headers: _getHeaders(),
        body: json.encode(bookingData),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'booking': Booking.fromJson(responseData['booking']),
          'message': responseData['message'] ?? 'Booking created successfully',
          'redirectUrl': responseData['redirect_url'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to create booking',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> cancelBooking(int bookingId) async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/booking/$bookingId/cancel'),
        headers: _getHeaders(),
      );

      final responseData = json.decode(response.body);

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
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getAvailableTimeSlots(int turfId, String date) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/mobile/turf/$turfId/time_slots?date=$date'),
        headers: _getHeaders(),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'timeSlots': responseData['time_slots'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch time slots',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
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