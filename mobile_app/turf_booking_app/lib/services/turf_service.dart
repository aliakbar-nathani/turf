import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/turf_model.dart';

class TurfService {
  final String? authToken;

  TurfService({this.authToken});

  Future<Map<String, dynamic>> getTurfs({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.turfs}?page=$page&limit=$limit'),
        headers: _getHeaders(),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        final List<Turf> turfs = (responseData['turfs'] as List)
            .map((turfJson) => Turf.fromJson(turfJson))
            .toList();

        return {
          'success': true,
          'turfs': turfs,
          'totalPages': responseData['total_pages'] ?? 1,
          'currentPage': responseData['current_page'] ?? 1,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch turfs',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getTurfDetails(int turfId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.turfDetails}/$turfId'),
        headers: _getHeaders(),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'turf': Turf.fromJson(responseData['turf']),
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch turf details',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> searchTurfs({
    String? city,
    String? date,
    double? minPrice,
    double? maxPrice,
    String? indoor,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (city != null && city.isNotEmpty) queryParams['city'] = city;
      if (date != null && date.isNotEmpty) queryParams['date'] = date;
      if (minPrice != null) queryParams['min_price'] = minPrice.toString();
      if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
      if (indoor != null) queryParams['indoor'] = indoor;

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.search}')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: _getHeaders(),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        final List<Turf> turfs = (responseData['turfs'] as List)
            .map((turfJson) => Turf.fromJson(turfJson))
            .toList();

        return {
          'success': true,
          'turfs': turfs,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Search failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> advancedSearch({
    String? city,
    String? date,
    double? minPrice,
    double? maxPrice,
    String? indoor,
    bool? hasParking,
    bool? hasChangingRoom,
    bool? hasShower,
    bool? hasFloodlights,
    bool? hasEquipment,
    int? minRating,
    String? surfaceType,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (city != null && city.isNotEmpty) queryParams['city'] = city;
      if (date != null && date.isNotEmpty) queryParams['date'] = date;
      if (minPrice != null) queryParams['min_price'] = minPrice.toString();
      if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
      if (indoor != null) queryParams['indoor'] = indoor;
      if (hasParking != null) queryParams['has_parking'] = hasParking.toString();
      if (hasChangingRoom != null) queryParams['has_changing_room'] = hasChangingRoom.toString();
      if (hasShower != null) queryParams['has_shower'] = hasShower.toString();
      if (hasFloodlights != null) queryParams['has_floodlights'] = hasFloodlights.toString();
      if (hasEquipment != null) queryParams['has_equipment'] = hasEquipment.toString();
      if (minRating != null) queryParams['min_rating'] = minRating.toString();
      if (surfaceType != null) queryParams['surface_type'] = surfaceType;

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.advancedSearch}')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: _getHeaders(),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        final List<Turf> turfs = (responseData['turfs'] as List)
            .map((turfJson) => Turf.fromJson(turfJson))
            .toList();

        return {
          'success': true,
          'turfs': turfs,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Advanced search failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> toggleFavorite(int turfId) async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.favorites}/$turfId/toggle'),
        headers: _getHeaders(),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'isFavorite': responseData['is_favorite'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to toggle favorite',
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