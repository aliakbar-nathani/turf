import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Save auth token and user info
        await _saveAuthData(responseData);
        return {
          'success': true,
          'message': 'Login successful',
          'user': User.fromJson(responseData['user']),
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String phoneNumber,
    bool isOwner = false,
  }) async {
    try {
      final endpoint = isOwner ? ApiConfig.registerOwner : ApiConfig.register;
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
          'phone_number': phoneNumber,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        // Save auth token and user info if registration automatically logs in
        if (responseData.containsKey('token')) {
          await _saveAuthData(responseData);
        }
        
        return {
          'success': true,
          'message': 'Registration successful',
          'user': responseData.containsKey('user') 
              ? User.fromJson(responseData['user']) 
              : null,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userIdKey);
    await prefs.remove(AppConstants.userNameKey);
    await prefs.remove(AppConstants.userRoleKey);
    await prefs.remove(AppConstants.emailKey);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.userIdKey);
  }

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userRoleKey);
  }

  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    if (data.containsKey('token')) {
      await prefs.setString(AppConstants.tokenKey, data['token']);
    }
    
    if (data.containsKey('user')) {
      final user = data['user'];
      await prefs.setInt(AppConstants.userIdKey, user['id']);
      await prefs.setString(AppConstants.userNameKey, user['username']);
      await prefs.setString(AppConstants.userRoleKey, user['role']);
      await prefs.setString(AppConstants.emailKey, user['email']);
    }
  }
}