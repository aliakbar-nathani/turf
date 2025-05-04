import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_theme.dart';
import '../../config/app_constants.dart';
import '../../models/turf_model.dart';
import '../../services/turf_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'turf_detail_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  late TurfService _turfService;
  
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String? _userName;
  
  List<Turf> _turfs = [];
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }
  
  Future<void> _checkAuthStatus() async {
    final isLoggedIn = await _authService.isLoggedIn();
    final token = await _authService.getToken();
    
    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
        _turfService = TurfService(authToken: token);
      });
      
      // If logged in, get user information
      if (isLoggedIn) {
        final prefs = await SharedPreferences.getInstance();
        final name = prefs.getString(AppConstants.userNameKey);
        setState(() {
          _userName = name;
        });
      }
      
      // Load turfs regardless of auth status
      _loadTurfs();
    }
  }
  
  Future<void> _loadTurfs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    final result = await _turfService.getTurfs(
      page: _currentPage,
      limit: 10,
    );
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        
        if (result['success']) {
          _turfs = result['turfs'];
          _totalPages = result['totalPages'];
        } else {
          _errorMessage = result['message'];
        }
      });
    }
  }
  
  Future<void> _refreshTurfs() async {
    _currentPage = 1;
    await _loadTurfs();
  }
  
  void _loadNextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
      });
      _loadTurfs();
    }
  }
  
  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      setState(() {
        _isLoggedIn = false;
        _userName = null;
      });
      
      // Navigate to login screen
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }
  
  void _navigateToSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchScreen()),
    );
  }
  
  void _navigateToTurfDetails(Turf turf) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TurfDetailScreen(turfId: turf.id),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Turf Booking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _navigateToSearch,
          ),
          if (_isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
            ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _isLoading && _turfs.isEmpty
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
                        onPressed: _refreshTurfs,
                        style: AppTheme.primaryButtonStyle,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshTurfs,
                  color: AppTheme.primaryColor,
                  child: _buildTurfList(),
                ),
    );
  }
  
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _isLoggedIn ? 'Hello, $_userName!' : 'Welcome, Guest!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isLoggedIn 
                      ? 'Manage your bookings'
                      : 'Sign in to book a turf',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          if (_isLoggedIn) ...[
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('My Bookings'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to bookings screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Favorites'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to favorites screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to profile screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to notifications screen
              },
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Login'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
            ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Search Turfs'),
            onTap: () {
              Navigator.pop(context);
              _navigateToSearch();
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              // Show about dialog
              showAboutDialog(
                context: context,
                applicationName: 'Turf Booking',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(
                  Icons.sports_soccer,
                  size: 40,
                  color: AppTheme.primaryColor,
                ),
                children: [
                  const Text(
                    'A comprehensive turf booking platform that revolutionizes sports venue reservations through intelligent matching, user-centric design, and seamless booking experiences.',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildTurfList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _turfs.length + (_currentPage < _totalPages ? 1 : 0),
      itemBuilder: (context, index) {
        // If we've reached the end of the current page data and there are more pages
        if (index == _turfs.length) {
          return _buildLoadMoreButton();
        }
        
        final turf = _turfs[index];
        return _buildTurfCard(turf);
      },
    );
  }
  
  Widget _buildTurfCard(Turf turf) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: InkWell(
        onTap: () => _navigateToTurfDetails(turf),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Turf image
            SizedBox(
              height: 180,
              width: double.infinity,
              child: turf.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: turf.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: SpinKitFadingCircle(
                          color: AppTheme.primaryColor,
                          size: 30.0,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.sports_soccer,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.sports_soccer,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          turf.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '\$${turf.basePricePerHour.toStringAsFixed(2)}/hr',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${turf.city}, ${turf.state}',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Features
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildFeatureChip(
                        turf.indoor ? 'Indoor' : 'Outdoor',
                        Icons.home_work,
                      ),
                      _buildFeatureChip(
                        turf.surfaceType,
                        Icons.grass,
                      ),
                      if (turf.hasParking)
                        _buildFeatureChip('Parking', Icons.local_parking),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Rating and book button
                  Row(
                    children: [
                      if (turf.averageRating != null) ...[
                        const Icon(
                          Icons.star,
                          size: 18,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${turf.averageRating!.toStringAsFixed(1)} (${turf.reviewCount})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                      ] else
                        const Spacer(),
                      
                      ElevatedButton(
                        onPressed: () => _navigateToTurfDetails(turf),
                        style: AppTheme.primaryButtonStyle,
                        child: const Text('View Details'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureChip(String label, IconData icon) {
    return Chip(
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
    );
  }
  
  Widget _buildLoadMoreButton() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: _isLoading
            ? SpinKitThreeBounce(
                color: AppTheme.primaryColor,
                size: 24.0,
              )
            : TextButton.icon(
                onPressed: _loadNextPage,
                icon: const Icon(Icons.refresh),
                label: const Text('Load More'),
              ),
      ),
    );
  }
}