import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/review_model.dart';

class ReviewService {
  final String? authToken;

  ReviewService({this.authToken});

  // Add headers with auth token if available
  Map<String, String> _getHeaders() {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    return headers;
  }

  // Get all reviews for a turf
  Future<Map<String, dynamic>> getTurfReviews(int turfId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/turf/$turfId/reviews'),
        headers: _getHeaders(),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        final List<dynamic> reviewsJson = responseData['reviews'];
        final List<Review> reviews = reviewsJson
            .map((json) => Review.fromJson(json))
            .toList();

        return {
          'success': true,
          'reviews': reviews,
          'averageRating': responseData['average_rating'],
          'reviewCount': responseData['review_count'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to load reviews',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Get all reviews by current user
  Future<Map<String, dynamic>> getUserReviews() async {
    if (authToken == null) {
      return {
        'success': false,
        'message': 'Authentication token required',
      };
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/user/reviews'),
        headers: _getHeaders(),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        final List<dynamic> reviewsJson = responseData['reviews'];
        final List<Review> reviews = reviewsJson
            .map((json) => Review.fromJson(json))
            .toList();

        return {
          'success': true,
          'reviews': reviews,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to load reviews',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Submit a new review
  Future<Map<String, dynamic>> submitReview({
    required int turfId,
    required int rating,
    String? comment,
  }) async {
    if (authToken == null) {
      return {
        'success': false,
        'message': 'Authentication token required',
      };
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/turf/$turfId/review'),
        headers: _getHeaders(),
        body: json.encode({
          'rating': rating,
          'comment': comment ?? '',
        }),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 201 && responseData['success']) {
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
        'message': 'Error: $e',
      };
    }
  }

  // Update an existing review
  Future<Map<String, dynamic>> updateReview({
    required int reviewId,
    required int rating,
    String? comment,
  }) async {
    if (authToken == null) {
      return {
        'success': false,
        'message': 'Authentication token required',
      };
    }

    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/review/$reviewId'),
        headers: _getHeaders(),
        body: json.encode({
          'rating': rating,
          'comment': comment ?? '',
        }),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
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
        'message': 'Error: $e',
      };
    }
  }

  // Delete a review
  Future<Map<String, dynamic>> deleteReview(int reviewId) async {
    if (authToken == null) {
      return {
        'success': false,
        'message': 'Authentication token required',
      };
    }

    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/review/$reviewId'),
        headers: _getHeaders(),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
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
        'message': 'Error: $e',
      };
    }
  }

  // Check if user can review a turf
  Future<Map<String, dynamic>> canReviewTurf(int turfId) async {
    if (authToken == null) {
      return {
        'success': false,
        'message': 'Authentication token required',
        'canReview': false,
      };
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/turf/$turfId/can_review'),
        headers: _getHeaders(),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        return {
          'success': true,
          'canReview': responseData['can_review'] ?? false,
          'message': responseData['message'] ?? '',
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
        'message': 'Error: $e',
        'canReview': false,
      };
    }
  }
}