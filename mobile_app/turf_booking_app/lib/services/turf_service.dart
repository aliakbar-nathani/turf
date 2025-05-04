import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/turf_model.dart';

class TurfService {
  final String? authToken;
  final String baseUrl = ApiConfig.baseUrl;

  TurfService({this.authToken});

  // Get all turfs with optional filtering
  Future<Map<String, dynamic>> getTurfs({
    String? city,
    String? date,
    double? minPrice,
    double? maxPrice,
    bool? indoor,
    String? surfaceType,
    int? minRating,
    bool? hasParking,
    bool? hasChangingRoom,
    bool? hasShower,
    bool? hasFloodlights,
    bool? hasEquipment,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (city != null && city.isNotEmpty) queryParams['city'] = city;
      if (date != null && date.isNotEmpty) queryParams['date'] = date;
      if (minPrice != null) queryParams['min_price'] = minPrice.toString();
      if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
      if (indoor != null) queryParams['indoor'] = indoor.toString();
      if (surfaceType != null && surfaceType.isNotEmpty) {
        queryParams['surface_type'] = surfaceType;
      }
      if (minRating != null) queryParams['min_rating'] = minRating.toString();
      if (hasParking != null) queryParams['has_parking'] = hasParking.toString();
      if (hasChangingRoom != null) {
        queryParams['has_changing_room'] = hasChangingRoom.toString();
      }
      if (hasShower != null) queryParams['has_shower'] = hasShower.toString();
      if (hasFloodlights != null) {
        queryParams['has_floodlights'] = hasFloodlights.toString();
      }
      if (hasEquipment != null) {
        queryParams['has_equipment'] = hasEquipment.toString();
      }

      final uri = Uri.parse('$baseUrl/api/turfs')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final turfsJson = responseData['turfs'] as List;
        final turfs = turfsJson.map((json) => Turf.fromJson(json)).toList();

        return {
          'success': true,
          'turfs': turfs,
          'total': responseData['total'],
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

  // Get a specific turf by ID
  Future<Map<String, dynamic>> getTurfById(int turfId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/turfs/$turfId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final turf = Turf.fromJson(responseData['turf']);

        return {
          'success': true,
          'turf': turf,
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

  // Get available time slots for a specific turf on a specific date
  Future<Map<String, dynamic>> getAvailableTimeSlots(
      int turfId, String date) async {
    try {
      final queryParams = {'date': date};
      final uri = Uri.parse('$baseUrl/api/turfs/$turfId/time-slots')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'timeSlots': responseData['time_slots'],
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

  // Get reviews for a specific turf
  Future<Map<String, dynamic>> getTurfReviews(int turfId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/turfs/$turfId/reviews'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'reviews': responseData['reviews'],
          'average_rating': responseData['average_rating'],
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

  // Submit a review for a turf
  Future<Map<String, dynamic>> submitReview(
      {required int turfId, required int rating, String? comment}) async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/turfs/$turfId/reviews'),
        headers: _getHeaders(),
        body: jsonEncode({
          'rating': rating,
          'comment': comment,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Review submitted successfully',
          'review': responseData['review'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to submit review',
        };
      }
    } catch (e) {
      print('Error submitting review: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Get turfs owned by the authenticated user
  Future<Map<String, dynamic>> getOwnerTurfs() async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/owner/turfs'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final turfsJson = responseData['turfs'] as List;
        final turfs = turfsJson.map((json) => Turf.fromJson(json)).toList();

        return {
          'success': true,
          'turfs': turfs,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch your turfs',
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

  // Create a new turf
  Future<Map<String, dynamic>> createTurf(Map<String, dynamic> turfData) async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/owner/turfs'),
        headers: _getHeaders(),
        body: jsonEncode(turfData),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final turf = Turf.fromJson(responseData['turf']);

        return {
          'success': true,
          'message': responseData['message'] ?? 'Turf created successfully',
          'turf': turf,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to create turf',
        };
      }
    } catch (e) {
      print('Error creating turf: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Update an existing turf
  Future<Map<String, dynamic>> updateTurf(
      int turfId, Map<String, dynamic> turfData) async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/owner/turfs/$turfId'),
        headers: _getHeaders(),
        body: jsonEncode(turfData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final turf = Turf.fromJson(responseData['turf']);

        return {
          'success': true,
          'message': responseData['message'] ?? 'Turf updated successfully',
          'turf': turf,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update turf',
        };
      }
    } catch (e) {
      print('Error updating turf: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Delete a turf
  Future<Map<String, dynamic>> deleteTurf(int turfId) async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/api/owner/turfs/$turfId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Turf deleted successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to delete turf',
        };
      }
    } catch (e) {
      print('Error deleting turf: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Get time slots for a specific turf (owner view - includes all slots)
  Future<Map<String, dynamic>> getTurfTimeSlots(int turfId) async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/owner/turfs/$turfId/time-slots'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'timeSlots': responseData['time_slots'],
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

  // Add a new time slot to a turf
  Future<Map<String, dynamic>> addTimeSlot(
      int turfId, Map<String, dynamic> timeSlotData) async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/owner/turfs/$turfId/time-slots'),
        headers: _getHeaders(),
        body: jsonEncode(timeSlotData),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Time slot added successfully',
          'timeSlot': responseData['time_slot'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to add time slot',
        };
      }
    } catch (e) {
      print('Error adding time slot: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Delete a time slot
  Future<Map<String, dynamic>> deleteTimeSlot(
      int turfId, int timeSlotId) async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/api/owner/turfs/$turfId/time-slots/$timeSlotId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Time slot deleted successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to delete time slot',
        };
      }
    } catch (e) {
      print('Error deleting time slot: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Respond to a review (owner only)
  Future<Map<String, dynamic>> respondToReview(
      int reviewId, String response) async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final apiResponse = await http.post(
        Uri.parse('$baseUrl/api/owner/reviews/$reviewId/respond'),
        headers: _getHeaders(),
        body: jsonEncode({
          'response': response,
        }),
      );

      if (apiResponse.statusCode == 200) {
        final responseData = jsonDecode(apiResponse.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Response added successfully',
        };
      } else {
        final errorData = jsonDecode(apiResponse.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to respond to review',
        };
      }
    } catch (e) {
      print('Error responding to review: $e');
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