import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/review_model.dart';

class ReviewService {
  final String? authToken;

  ReviewService({this.authToken});

  Future<Map<String, dynamic>> getTurfReviews(int turfId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/turf/$turfId/reviews'),
        headers: _getHeaders(),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        final List<Review> reviews = (responseData['reviews'] as List)
            .map((reviewJson) => Review.fromJson(reviewJson))
            .toList();

        return {
          'success': true,
          'reviews': reviews,
          'averageRating': responseData['average_rating']?.toDouble(),
          'reviewCount': responseData['review_count'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch reviews',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getUserReviews() async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/user/reviews'),
        headers: _getHeaders(),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        final List<Review> reviews = (responseData['reviews'] as List)
            .map((reviewJson) => Review.fromJson(reviewJson))
            .toList();

        return {
          'success': true,
          'reviews': reviews,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch user reviews',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> submitReview({
    required int turfId,
    required int rating,
    required String comment,
  }) async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/turf/$turfId/review'),
        headers: _getHeaders(),
        body: json.encode({
          'rating': rating,
          'comment': comment,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Review submitted successfully',
          'review': Review.fromJson(responseData['review']),
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to submit review',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> updateReview({
    required int reviewId,
    required int rating,
    required String comment,
  }) async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/review/$reviewId'),
        headers: _getHeaders(),
        body: json.encode({
          'rating': rating,
          'comment': comment,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Review updated successfully',
          'review': Review.fromJson(responseData['review']),
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update review',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> deleteReview(int reviewId) async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/review/$reviewId'),
        headers: _getHeaders(),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Review deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to delete review',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> respondToReview({
    required int reviewId,
    required String response,
  }) async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final httpResponse = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/owner/review/$reviewId/respond'),
        headers: _getHeaders(),
        body: json.encode({
          'response': response,
        }),
      );

      final responseData = json.decode(httpResponse.body);

      if (httpResponse.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Response submitted successfully',
          'review': Review.fromJson(responseData['review']),
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to submit response',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> canReviewTurf(int turfId) async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/turf/$turfId/can_review'),
        headers: _getHeaders(),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'canReview': responseData['can_review'] ?? false,
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to check review eligibility',
          'canReview': false,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
        'canReview': false,
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