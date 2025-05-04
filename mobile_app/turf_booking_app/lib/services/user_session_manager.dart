import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_constants.dart';

class UserSessionManager {
  // Singleton pattern
  static final UserSessionManager _instance = UserSessionManager._internal();
  factory UserSessionManager() => _instance;
  UserSessionManager._internal();

  // Cached values
  String? _token;
  int? _userId;
  String? _userName;
  String? _userRole;
  String? _email;

  // Additional user data storage key
  static const String _userDataKey = 'user_data';

  // Getters
  String? get token => _token;
  int? get userId => _userId;
  String? get userName => _userName;
  String? get userRole => _userRole;
  String? get email => _email;
  
  // Check if user is logged in
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;
  
  // Check user role
  bool get isUser => _userRole == AppConstants.roleUser;
  bool get isOwner => _userRole == AppConstants.roleOwner;
  bool get isAdmin => _userRole == AppConstants.roleAdmin;

  // Load session from SharedPreferences
  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.tokenKey);
    _userId = prefs.getInt(AppConstants.userIdKey);
    _userName = prefs.getString(AppConstants.userNameKey);
    _userRole = prefs.getString(AppConstants.userRoleKey);
    _email = prefs.getString(AppConstants.emailKey);
  }

  // Save session to SharedPreferences
  Future<void> saveSession({
    required String token,
    required int userId,
    required String userName,
    required String userRole,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
    await prefs.setInt(AppConstants.userIdKey, userId);
    await prefs.setString(AppConstants.userNameKey, userName);
    await prefs.setString(AppConstants.userRoleKey, userRole);
    await prefs.setString(AppConstants.emailKey, email);
    
    // Update cached values
    _token = token;
    _userId = userId;
    _userName = userName;
    _userRole = userRole;
    _email = email;
  }

  // Clear session (logout)
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userIdKey);
    await prefs.remove(AppConstants.userNameKey);
    await prefs.remove(AppConstants.userRoleKey);
    await prefs.remove(AppConstants.emailKey);
    await prefs.remove(_userDataKey);
    
    // Clear cached values
    _token = null;
    _userId = null;
    _userName = null;
    _userRole = null;
    _email = null;
  }
  
  // Save additional user data
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, json.encode(userData));
  }
  
  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataStr = prefs.getString(_userDataKey);
    
    if (userDataStr != null && userDataStr.isNotEmpty) {
      try {
        return json.decode(userDataStr) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    
    return null;
  }
}