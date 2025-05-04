import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';
import '../config/api_config.dart';
import '../services/auth_service.dart';
import 'auth/login_screen.dart';
import 'turf/home_screen.dart';
import 'booking/user_bookings_screen.dart';
import 'profile/user_profile_screen.dart';
import 'profile/user_reviews_screen.dart';
import 'turf/search_screen.dart';
import 'owner/owner_dashboard_screen.dart';
import 'owner/owner_turf_list_screen.dart';
import 'owner/owner_negotiations_screen.dart';
import 'owner/owner_analytics_screen.dart';
import 'owner/owner_add_turf_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int _currentIndex = 0;
  String? _userName;
  String? _userRole;
  bool _isLoading = true;
  
  // User screens
  final List<Widget> _userScreens = [
    const HomeScreen(),
    const UserBookingsScreen(),
    const SearchScreen(),
    const UserProfileScreen(),
  ];
  
  // Owner screens
  final List<Widget> _ownerScreens = [
    const OwnerDashboardScreen(),
    const OwnerTurfListScreen(),
    const OwnerNegotiationsScreen(),
    const UserProfileScreen(),
  ];
  
  // Getter for the current screens based on role
  List<Widget> get _screens {
    if (_userRole == 'owner') {
      return _ownerScreens;
    }
    return _userScreens;
  }
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(AppConstants.userNameKey);
    final role = prefs.getString(AppConstants.userRoleKey);
    
    setState(() {
      _userName = name;
      _userRole = role;
      _isLoading = false;
    });
  }
  
  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });
    
    final authService = AuthService();
    await authService.logout();
    
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }
  
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutConfirmation,
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        items: _userRole == 'owner'
            ? const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.sports_soccer),
                  label: 'My Turfs',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.handshake),
                  label: 'Negotiations',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ]
            : const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today),
                  label: 'Bookings',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: 'Search',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
      ),
    );
  }
  
  String _getAppBarTitle() {
    if (_userRole == 'owner') {
      switch (_currentIndex) {
        case 0:
          return 'Owner Dashboard';
        case 1:
          return 'My Turfs';
        case 2:
          return 'Negotiations';
        case 3:
          return 'Profile';
        default:
          return 'Turf Booking';
      }
    } else {
      switch (_currentIndex) {
        case 0:
          return 'Turf Booking';
        case 1:
          return 'My Bookings';
        case 2:
          return 'Search Turfs';
        case 3:
          return 'Profile';
        default:
          return 'Turf Booking';
      }
    }
  }
  
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header section
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Hello, ${_userName ?? 'User'}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_userRole != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _userRole!.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Menu items based on role
          if (_userRole == 'owner') ...[
            // Owner-specific menu items
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                setState(() { _currentIndex = 0; });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sports_soccer),
              title: const Text('My Turfs'),
              onTap: () {
                setState(() { _currentIndex = 1; });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.handshake),
              title: const Text('Negotiations'),
              onTap: () {
                setState(() { _currentIndex = 2; });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Analytics'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OwnerAnalyticsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Add New Turf'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OwnerAddTurfScreen()),
                );
              },
            ),
          ] else ...[
            // Regular user menu items
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                setState(() { _currentIndex = 0; });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('My Bookings'),
              onTap: () {
                setState(() { _currentIndex = 1; });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search Turfs'),
              onTap: () {
                setState(() { _currentIndex = 2; });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Favorites'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Favorites screen coming soon')),
                );
                Navigator.pop(context);
              },
            ),
          ],
          
          // Common menu items
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications screen coming soon')),
              );
              Navigator.pop(context);
            },
          ),
          
          if (_userRole != 'owner') ...[
            ListTile(
              leading: const Icon(Icons.rate_review),
              title: const Text('My Reviews'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserReviewsScreen()),
                );
              },
            ),
          ],
          
          const Divider(),
          
          // Profile and settings
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              setState(() { _currentIndex = 3; });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings screen coming soon')),
              );
              Navigator.pop(context);
            },
          ),
          
          const Divider(),
          
          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showLogoutConfirmation();
            },
          ),
        ],
      ),
    );
  }
}