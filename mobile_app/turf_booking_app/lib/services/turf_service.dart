import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/turf_model.dart';
import '../services/auth_service.dart';

class TurfService {
  final String baseUrl = ApiConfig.baseUrl;
  final AuthService _authService = AuthService();
  
  // Get owner turfs
  Future<Map<String, dynamic>> getOwnerTurfs() async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/owner/turfs'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Parse turfs from response
        final List<dynamic> turfsJson = responseData['turfs'];
        final List<Turf> turfs = turfsJson.map((turfJson) => Turf.fromJson(turfJson)).toList();
        
        return {
          'success': true,
          'turfs': turfs,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch owner turfs',
        };
      }
    } catch (e) {
      print('Error fetching owner turfs: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  // Get all turfs with optional filters
  Future<Map<String, dynamic>> getTurfs({
    int page = 1,
    int limit = 10,
    String? city,
    bool? indoor,
  }) async {
    try {
      // Build query parameters
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (city != null && city.isNotEmpty) {
        queryParams['city'] = city;
      }
      
      if (indoor != null) {
        queryParams['indoor'] = indoor.toString();
      }
      
      // Make API request
      final uri = Uri.parse('$baseUrl/turfs').replace(queryParameters: queryParams);
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Parse turfs from response
        final List<dynamic> turfsJson = responseData['turfs'];
        final List<Turf> turfs = turfsJson.map((turfJson) => Turf.fromJson(turfJson)).toList();
        
        return {
          'success': true,
          'turfs': turfs,
          'current_page': responseData['current_page'],
          'total_pages': responseData['total_pages'],
          'total_turfs': responseData['total_turfs'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch turfs',
        };
      }
    } catch (e) {
      print('Error fetching turfs: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  // Search for turfs
  Future<Map<String, dynamic>> searchTurfs({
    String? city,
    String? date,
    double? minPrice,
    double? maxPrice,
    bool? indoor,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{};
      
      if (city != null && city.isNotEmpty) {
        queryParams['city'] = city;
      }
      
      if (date != null && date.isNotEmpty) {
        queryParams['date'] = date;
      }
      
      if (minPrice != null) {
        queryParams['min_price'] = minPrice.toString();
      }
      
      if (maxPrice != null) {
        queryParams['max_price'] = maxPrice.toString();
      }
      
      if (indoor != null) {
        queryParams['indoor'] = indoor.toString();
      }
      
      // Make API request
      final uri = Uri.parse('$baseUrl/search').replace(queryParameters: queryParams);
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Parse turfs from response
        final List<dynamic> turfsJson = responseData['turfs'];
        final List<Turf> turfs = turfsJson.map((turfJson) => Turf.fromJson(turfJson)).toList();
        
        return {
          'success': true,
          'turfs': turfs,
          'count': responseData['count'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to search turfs',
        };
      }
    } catch (e) {
      print('Error searching turfs: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  // Get turf details
  Future<Map<String, dynamic>> getTurfDetails(int turfId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/turf/$turfId'));
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final turfData = responseData['turf'];
        
        return {
          'success': true,
          'turf': Turf.fromDetailJson(turfData),
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch turf details',
        };
      }
    } catch (e) {
      print('Error fetching turf details: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  // Get available time slots for a turf on a specific date
  Future<Map<String, dynamic>> getTurfTimeSlots(int turfId, String date) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/turf/$turfId/time_slots').replace(
          queryParameters: {'date': date},
        ),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        return {
          'success': true,
          'time_slots': responseData['time_slots'],
          'is_available': responseData['is_available'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch time slots',
        };
      }
    } catch (e) {
      print('Error fetching time slots: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  // Get reviews for a turf
  Future<Map<String, dynamic>> getTurfReviews(int turfId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/turf/$turfId/reviews'));
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        return {
          'success': true,
          'turf_name': responseData['turf_name'],
          'reviews': responseData['reviews'],
          'avg_rating': responseData['avg_rating'],
          'review_count': responseData['review_count'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch reviews',
        };
      }
    } catch (e) {
      print('Error fetching reviews: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  // Owner-specific: Get turfs owned by the current user
  Future<Map<String, dynamic>> getOwnerTurfs() async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/owner/turfs'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Parse turfs from response
        final List<dynamic> turfsJson = responseData['turfs'];
        final List<Turf> turfs = turfsJson.map((turfJson) => Turf.fromOwnerJson(turfJson)).toList();
        
        return {
          'success': true,
          'turfs': turfs,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch owner turfs',
        };
      }
    } catch (e) {
      print('Error fetching owner turfs: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  // Owner-specific: Get analytics for owner's turfs
  Future<Map<String, dynamic>> getOwnerAnalytics({int? turfId}) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }
      
      // Build query parameters
      final queryParams = <String, String>{};
      if (turfId != null) {
        queryParams['turf_id'] = turfId.toString();
      }
      
      final uri = Uri.parse('$baseUrl/owner/analytics').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        return {
          'success': true,
          'turf': responseData['turf'],
          'turfs': responseData['turfs'],
          'analytics': responseData['analytics'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch analytics',
        };
      }
    } catch (e) {
      print('Error fetching owner analytics: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
}