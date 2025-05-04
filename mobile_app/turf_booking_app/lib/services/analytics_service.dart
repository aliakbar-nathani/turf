import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AnalyticsService {
  final String? authToken;
  final String baseUrl = AppConstants.apiBaseUrl;

  AnalyticsService({required this.authToken});

  Future<Map<String, dynamic>> getRevenueData({required String timeRange}) async {
    try {
      if (authToken == null) {
        return {'success': false, 'message': 'Authentication required'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/owner/analytics/revenue?time_range=$timeRange'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData['data'] ?? {},
        };
      } else if (response.statusCode == 401) {
        return {'success': false, 'message': 'Unauthorized'};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch revenue data',
        };
      }
    } catch (e) {
      // For development purposes until the backend is implemented
      // In a real app, we would return the error
      print('Error fetching revenue data: $e');
      
      // Return sample data structure that would match the API
      return {
        'success': true,
        'data': {
          'total_revenue': 2500.00,
          'compared_to_last_period': 15.5,
          'monthly_data': [
            {'month': 'Jan', 'revenue': 2100.0},
            {'month': 'Feb', 'revenue': 1800.0},
            {'month': 'Mar', 'revenue': 2300.0},
            {'month': 'Apr', 'revenue': 2500.0},
          ],
        },
      };
    }
  }

  Future<Map<String, dynamic>> getBookingData({required String timeRange}) async {
    try {
      if (authToken == null) {
        return {'success': false, 'message': 'Authentication required'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/owner/analytics/bookings?time_range=$timeRange'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData['data'] ?? {},
        };
      } else if (response.statusCode == 401) {
        return {'success': false, 'message': 'Unauthorized'};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch booking data',
        };
      }
    } catch (e) {
      // For development purposes until the backend is implemented
      // In a real app, we would return the error
      print('Error fetching booking data: $e');
      
      // Return sample data structure that would match the API
      return {
        'success': true,
        'data': {
          'total': 45,
          'completed': 32,
          'pending': 10,
          'cancelled': 3,
        },
      };
    }
  }

  Future<Map<String, dynamic>> getTurfPerformanceData({required String timeRange}) async {
    try {
      if (authToken == null) {
        return {'success': false, 'message': 'Authentication required'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/owner/analytics/turf-performance?time_range=$timeRange'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData['data'] ?? {},
        };
      } else if (response.statusCode == 401) {
        return {'success': false, 'message': 'Unauthorized'};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch turf performance data',
        };
      }
    } catch (e) {
      // For development purposes until the backend is implemented
      // In a real app, we would return the error
      print('Error fetching turf performance data: $e');
      
      // Return sample data structure that would match the API
      return {
        'success': true,
        'data': {
          'turfs': [
            {
              'id': 1,
              'name': 'Green Valley Turf',
              'booking_count': 22,
              'revenue': 1450.0,
              'occupancy_rate': 78.5,
              'rating': 4.7,
            },
            {
              'id': 2,
              'name': 'Urban Football Center',
              'booking_count': 18,
              'revenue': 950.0,
              'occupancy_rate': 65.0,
              'rating': 4.2,
            },
            {
              'id': 3,
              'name': 'Riverside Playfield',
              'booking_count': 5,
              'revenue': 350.0,
              'occupancy_rate': 42.0,
              'rating': 4.0,
            },
          ],
        },
      };
    }
  }
}