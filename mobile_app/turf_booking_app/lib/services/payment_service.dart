import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';

class PaymentService {
  final String? authToken;

  PaymentService({this.authToken});

  Future<Map<String, dynamic>> createCheckoutSession(int bookingId) async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.checkout}/$bookingId'),
        headers: _getHeaders(),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'checkout_url': responseData['checkout_url'],
          'session_id': responseData['session_id'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to create checkout session',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  Future<bool> launchPayment(String paymentUrl) async {
    try {
      final Uri url = Uri.parse(paymentUrl);
      
      // Launch the URL in external browser
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return true;
      } else {
        throw Exception('Could not launch payment URL');
      }
    } catch (e) {
      print('Error launching payment URL: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> checkPaymentStatus(
    int bookingId, 
    String sessionId,
  ) async {
    try {
      if (authToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.paymentStatus}/$bookingId?session_id=$sessionId'),
        headers: _getHeaders(),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'is_paid': responseData['is_paid'] ?? false,
          'message': responseData['message'] ?? 'Payment status retrieved',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to check payment status',
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