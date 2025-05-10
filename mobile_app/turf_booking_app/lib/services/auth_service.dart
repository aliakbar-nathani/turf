import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';

enum UserRole {
  user,
  owner,
  admin,
}

class AuthService {
  final String baseUrl = ApiConfig.baseUrl;
  
  // Login user
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // Save auth token and user info
        await _saveAuthData(
          responseData['token'],
          responseData['user']['id'],
          responseData['user']['username'],
          responseData['user']['email'],
          responseData['user']['role'],
        );
        
        return {
          'success': true,
          'message': 'Login successful',
          'user': User.fromJson(responseData['user']),
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      print('Error logging in: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  // Register user
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String phoneNumber,
    required bool isOwner,
  }) async {
    try {
      final endpoint = isOwner ? '/auth/register-owner' : '/auth/register';
      
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'phone_number': phoneNumber,
        }),
      );
      
      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Registration successful',
          'user': User.fromJson(responseData['user']),
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      print('Error registering: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  // Logout user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('username');
    await prefs.remove('email');
    await prefs.remove('user_role');
  }
  
  // Get user profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await getToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'user': User.fromJson(responseData['user']),
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch profile',
        };
      }
    } catch (e) {
      print('Error fetching profile: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  // Update user profile
  Future<Map<String, dynamic>> updateProfile({
    required String username,
    required String phoneNumber,
    String? currentPassword,
    String? newPassword,
  }) async {
    try {
      final token = await getToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }
      
      final updateData = {
        'username': username,
        'phone_number': phoneNumber,
      };
      
      if (currentPassword != null && currentPassword.isNotEmpty &&
          newPassword != null && newPassword.isNotEmpty) {
        updateData['current_password'] = currentPassword;
        updateData['new_password'] = newPassword;
      }
      
      final response = await http.put(
        Uri.parse('$baseUrl/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updateData),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Update stored username
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', username);
        
        return {
          'success': true,
          'message': responseData['message'] ?? 'Profile updated successfully',
          'user': User.fromJson(responseData['user']),
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      print('Error updating profile: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }
  
  // Get user role
  Future<UserRole> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final userRole = prefs.getString('user_role');
    
    if (userRole == 'owner') {
      return UserRole.owner;
    } else if (userRole == 'admin') {
      return UserRole.admin;
    } else {
      return UserRole.user;
    }
  }
  
  // Check if user is an owner
  Future<bool> isOwner() async {
    final userRole = await getUserRole();
    return userRole == UserRole.owner;
  }
  
  // Check if user is an admin
  Future<bool> isAdmin() async {
    final userRole = await getUserRole();
    return userRole == UserRole.admin;
  }
  
  // Get authentication token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  
  // Get user ID
  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }
  
  // Get username
  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }
  
  // Get user email
  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email');
  }
  
  // Save authentication data
  Future<void> _saveAuthData(
    String token,
    int userId,
    String username,
    String email,
    String role,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setInt('user_id', userId);
    await prefs.setString('username', username);
    await prefs.setString('email', email);
    await prefs.setString('user_role', role);
  }
  
  // Request password reset
  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/request-password-reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
        }),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Password reset instructions sent to your email',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to request password reset',
        };
      }
    } catch (e) {
      print('Error requesting password reset: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  // Reset password with token
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'new_password': newPassword,
        }),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Password reset successful',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to reset password',
        };
      }
    } catch (e) {
      print('Error resetting password: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
}