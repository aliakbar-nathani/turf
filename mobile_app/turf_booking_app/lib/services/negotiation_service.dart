import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/negotiation_model.dart';

class NegotiationService {
  final String? authToken;

  NegotiationService({this.authToken});

  Future<Map<String, dynamic>> getNegotiationDetails(int bookingId) async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/booking/$bookingId/negotiate'),
        headers: _getHeaders(),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'negotiation': Negotiation.fromJson(responseData['negotiation']),
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch negotiation details',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> submitNegotiation({
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

      final Map<String, dynamic> negotiationData = {
        'action': 'propose',
        'proposed_price': proposedPrice,
      };

      if (message != null && message.isNotEmpty) {
        negotiationData['message'] = message;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.negotiation}/$bookingId'),
        headers: _getHeaders(),
        body: json.encode(negotiationData),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Negotiation submitted successfully',
          'negotiation': responseData.containsKey('negotiation') 
            ? Negotiation.fromJson(responseData['negotiation']) 
            : null,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to submit negotiation',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> respondToNegotiation({
    required int bookingId,
    required String action,
    double? counterOfferPrice,
    String? message,
  }) async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final Map<String, dynamic> responseData = {
        'action': action,
      };

      if (action == 'counter' && counterOfferPrice != null) {
        responseData['proposed_price'] = counterOfferPrice;
      }

      if (message != null && message.isNotEmpty) {
        responseData['message'] = message;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ownerNegotiation}/$bookingId'),
        headers: _getHeaders(),
        body: json.encode(responseData),
      );

      final jsonResponse = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': jsonResponse['message'] ?? 'Response submitted successfully',
        };
      } else {
        return {
          'success': false,
          'message': jsonResponse['message'] ?? 'Failed to respond to negotiation',
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