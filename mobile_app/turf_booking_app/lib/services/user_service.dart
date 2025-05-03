import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../models/booking_model.dart';

class UserService {
  final String? authToken;

  UserService({this.authToken});

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.userProfile}'),
        headers: _getHeaders(),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'user': User.fromJson(responseData['user']),
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch user profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> updateUserProfile({
    required String username,
    required String phoneNumber,
    String? currentPassword,
    String? newPassword,
  }) async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final Map<String, dynamic> userData = {
        'username': username,
        'phone_number': phoneNumber,
      };

      if (currentPassword != null && currentPassword.isNotEmpty &&
          newPassword != null && newPassword.isNotEmpty) {
        userData['current_password'] = currentPassword;
        userData['new_password'] = newPassword;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.userProfile}/update'),
        headers: _getHeaders(),
        body: json.encode(userData),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Profile updated successfully',
          'user': User.fromJson(responseData['user']),
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getUserBookings() async {
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

  Future<Map<String, dynamic>> getFavoriteTurfs() async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.favorites}'),
        headers: _getHeaders(),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'turfs': responseData['turfs'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch favorite turfs',
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