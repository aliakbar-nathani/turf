import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AnalyticsService {
  final String? authToken;
  final String baseUrl = ApiConfig.baseUrl;

  AnalyticsService({this.authToken});

  Future<Map<String, dynamic>> getOwnerDashboardSummary() async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/owner/analytics/summary'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData['data'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch analytics summary',
        };
      }
    } catch (e) {
      print('Error fetching dashboard summary: $e');
      
      // Return mock data for development
      return {
        'success': true,
        'data': {
          'total_turfs': 2,
          'total_bookings': 24,
          'total_revenue': 1840.0,
          'conversion_rate': 76.5,
          'pending_negotiations': 3,
        },
      };
    }
  }

  Future<Map<String, dynamic>> getBookingAnalytics({
    String? period = 'month', // day, week, month, year
    String? startDate,
    String? endDate,
  }) async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      // Build query parameters
      final queryParams = <String, String>{};
      if (period != null) queryParams['period'] = period;
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final uri = Uri.parse('$baseUrl/api/owner/analytics/bookings')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData['data'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch booking analytics',
        };
      }
    } catch (e) {
      print('Error fetching booking analytics: $e');
      
      // Return mock data for development
      return {
        'success': true,
        'data': {
          'bookings_over_time': [
            {'date': '2025-04-01', 'count': 3, 'revenue': 240.0},
            {'date': '2025-04-02', 'count': 2, 'revenue': 160.0},
            {'date': '2025-04-03', 'count': 4, 'revenue': 320.0},
            {'date': '2025-04-04', 'count': 1, 'revenue': 80.0},
            {'date': '2025-04-05', 'count': 5, 'revenue': 400.0},
            {'date': '2025-04-06', 'count': 3, 'revenue': 240.0},
            {'date': '2025-04-07', 'count': 2, 'revenue': 160.0},
            {'date': '2025-04-08', 'count': 4, 'revenue': 320.0},
          ],
          'total_bookings': 24,
          'total_revenue': 1920.0,
          'average_booking_value': 80.0,
        },
      };
    }
  }

  Future<Map<String, dynamic>> getTurfPerformance() async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/owner/analytics/turf-performance'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData['data'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch turf performance data',
        };
      }
    } catch (e) {
      print('Error fetching turf performance: $e');
      
      // Return mock data for development
      return {
        'success': true,
        'data': {
          'turfs': [
            {
              'id': 1,
              'name': 'Green Valley Turf',
              'bookings_count': 14,
              'revenue': 1120.0,
              'rating': 4.7,
              'occupancy_rate': 72.5,
            },
            {
              'id': 2,
              'name': 'Urban Football Center',
              'bookings_count': 10,
              'revenue': 800.0,
              'rating': 4.5,
              'occupancy_rate': 65.0,
            },
          ],
          'most_popular_days': [
            {'day': 'Saturday', 'bookings': 8},
            {'day': 'Sunday', 'bookings': 7},
            {'day': 'Friday', 'bookings': 5},
          ],
          'most_popular_times': [
            {'time': '18:00-20:00', 'bookings': 10},
            {'time': '16:00-18:00', 'bookings': 8},
            {'time': '20:00-22:00', 'bookings': 6},
          ],
        },
      };
    }
  }

  Future<Map<String, dynamic>> getNegotiationStats() async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/owner/analytics/negotiations'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData['data'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch negotiation statistics',
        };
      }
    } catch (e) {
      print('Error fetching negotiation stats: $e');
      
      // Return mock data for development
      return {
        'success': true,
        'data': {
          'total_negotiations': 15,
          'accepted': 8,
          'rejected': 4,
          'counter_offered': 2,
          'pending': 1,
          'average_discount': 12.5,
          'revenue_impact': -150.0,
          'conversion_rate': 53.3,
        },
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