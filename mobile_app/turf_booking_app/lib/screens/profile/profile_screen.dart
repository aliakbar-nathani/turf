import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/user_session_manager.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  late UserService _userService;
  late UserSessionManager _sessionManager;
  
  bool _isLoading = true;
  String? _errorMessage;
  
  // User profile data
  String _username = '';
  String _email = '';
  String _phoneNumber = '';
  String _userRole = '';
  
  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  Future<void> _initialize() async {
    final token = await _authService.getToken();
    _sessionManager = UserSessionManager();
    
    if (token == null) {
      _navigateToLogin();
      return;
    }
    
    setState(() {
      _userService = UserService(authToken: token);
    });
    
    _loadUserProfile();
  }
  
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Try to get cached profile data first
      final userData = await _sessionManager.getUserData();
      
      if (userData != null && 
          userData.containsKey('username') && 
          userData.containsKey('email')) {
        setState(() {
          _username = userData['username'] ?? '';
          _email = userData['email'] ?? '';
          _phoneNumber = userData['phoneNumber'] ?? '';
          _userRole = userData['userRole'] ?? '';
          _isLoading = false;
        });
      }
      
      // Still fetch fresh data from API
      final result = await _userService.getUserProfile();
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        
        if (result['success']) {
          final userData = result['userData'];
          _username = userData['username'] ?? '';
          _email = userData['email'] ?? '';
          _phoneNumber = userData['phone_number'] ?? userData['phoneNumber'] ?? '';
          _userRole = userData['role'] ?? userData['userRole'] ?? '';
          
          // Save updated profile to session
          _sessionManager.saveUserData({
            'username': _username,
            'email': _email,
            'phoneNumber': _phoneNumber,
            'userRole': _userRole,
          });
        } else {
          _errorMessage = result['message'];
        }
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading profile: $e';
      });
    }
  }
  
  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              setState(() {
                _isLoading = true;
              });
              
              await _authService.logout();
              await _sessionManager.clearSession();
              
              if (!mounted) return;
              
              setState(() {
                _isLoading = false;
              });
              
              _navigateToLogin();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
  
  void _navigateToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }
  
  void _editProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile editing will be available soon'),
      ),
    );
  }
  
  void _showNotificationSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification settings will be available soon'),
      ),
    );
  }
  
  void _showPaymentMethods() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment methods will be available soon'),
      ),
    );
  }
  
  void _showFavoriteTurfs() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Favorite turfs will be available soon'),
      ),
    );
  }
  
  void _showHelpAndSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Help and support will be available soon'),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: _isLoading
          ? Center(
              child: SpinKitCircle(
                color: AppTheme.primaryColor,
                size: 50.0,
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_errorMessage',
                        style: TextStyle(color: AppTheme.errorColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserProfile,
                        style: AppTheme.primaryButtonStyle,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUserProfile,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      // Profile header
                      _buildProfileHeader(),
                      
                      const SizedBox(height: 24.0),
                      
                      // Settings sections
                      _buildSectionTitle('Account Settings'),
                      _buildSettingItem(
                        icon: Icons.person_outline,
                        title: 'Edit Profile',
                        onTap: _editProfile,
                      ),
                      _buildSettingItem(
                        icon: Icons.notifications_outlined,
                        title: 'Notification Settings',
                        onTap: _showNotificationSettings,
                      ),
                      _buildSettingItem(
                        icon: Icons.credit_card_outlined,
                        title: 'Payment Methods',
                        onTap: _showPaymentMethods,
                      ),
                      _buildSettingItem(
                        icon: Icons.favorite_border,
                        title: 'Favorite Turfs',
                        onTap: _showFavoriteTurfs,
                      ),
                      
                      const SizedBox(height: 24.0),
                      
                      _buildSectionTitle('Support'),
                      _buildSettingItem(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        onTap: _showHelpAndSupport,
                      ),
                      _buildSettingItem(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        onTap: () {
                          // Show privacy policy
                        },
                      ),
                      _buildSettingItem(
                        icon: Icons.description_outlined,
                        title: 'Terms of Service',
                        onTap: () {
                          // Show terms of service
                        },
                      ),
                      
                      const SizedBox(height: 24.0),
                      
                      // Logout button
                      TextButton.icon(
                        onPressed: _logout,
                        icon: Icon(
                          Icons.logout,
                          color: AppTheme.errorColor,
                        ),
                        label: Text(
                          'Logout',
                          style: TextStyle(
                            color: AppTheme.errorColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                        ),
                      ),
                      
                      const SizedBox(height: 16.0),
                      
                      // App version
                      Center(
                        child: Text(
                          'App Version: 1.0.0',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12.0,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32.0),
                    ],
                  ),
                ),
    );
  }
  
  Widget _buildProfileHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Profile avatar
            CircleAvatar(
              radius: 40,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
              child: Text(
                _username.isNotEmpty ? _username[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _username,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _email,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _phoneNumber,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _userRole,
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Edit button
            IconButton(
              onPressed: _editProfile,
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Profile',
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Card(
      elevation: 0,
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Icon(
          icon,
          color: AppTheme.primaryColor,
        ),
        title: Text(title),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}