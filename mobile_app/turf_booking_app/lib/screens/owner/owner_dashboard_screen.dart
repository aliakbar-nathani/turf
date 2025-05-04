import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../config/app_theme.dart';
import '../../services/turf_service.dart';
import '../../services/booking_service.dart';
import '../../services/auth_service.dart';
import 'owner_turf_list_screen.dart';
import 'owner_negotiations_screen.dart';
import 'owner_analytics_screen.dart';
import 'owner_add_turf_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  final AuthService _authService = AuthService();
  late TurfService _turfService;
  late BookingService _bookingService;
  
  bool _isLoading = true;
  String? _errorMessage;
  
  // Dashboard stats
  int _totalTurfs = 0;
  int _pendingBookings = 0;
  int _pendingNegotiations = 0;
  double _totalRevenue = 0;
  
  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  Future<void> _initialize() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Authentication required';
        });
        return;
      }
      
      setState(() {
        _turfService = TurfService(authToken: token);
        _bookingService = BookingService(authToken: token);
      });
      
      await _loadDashboardData();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to initialize: $e';
      });
    }
  }
  
  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Get owner's turfs
      final turfsResult = await _turfService.getOwnerTurfs();
      
      // Get pending bookings
      final bookingsResult = await _bookingService.getOwnerBookings(status: 'pending');
      
      // Get negotiations
      final negotiationsResult = await _bookingService.getOwnerNegotiations();
      
      // Get revenue stats - would be from a real analytics endpoint
      // Using a placeholder for now that would be replaced with real API data
      final revenueResult = {'success': true, 'total_revenue': 2500.00};
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        
        if (turfsResult['success']) {
          _totalTurfs = turfsResult['turfs']?.length ?? 0;
        }
        
        if (bookingsResult['success']) {
          _pendingBookings = bookingsResult['bookings']?.length ?? 0;
        }
        
        if (negotiationsResult['success']) {
          _pendingNegotiations = negotiationsResult['negotiations']?.length ?? 0;
        }
        
        if (revenueResult['success']) {
          _totalRevenue = revenueResult['total_revenue'] ?? 0;
        }
        
        // Error handling
        if (!turfsResult['success'] && !bookingsResult['success'] && 
            !negotiationsResult['success'] && !revenueResult['success']) {
          _errorMessage = 'Failed to load dashboard data';
        }
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred: $e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh',
          ),
        ],
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
                        onPressed: _loadDashboardData,
                        style: AppTheme.primaryButtonStyle,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome to Your Turf Management Dashboard',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24.0),
                        
                        // Stats Grid
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 16.0,
                          mainAxisSpacing: 16.0,
                          children: [
                            _buildStatCard(
                              icon: Icons.landscape,
                              title: 'My Turfs',
                              value: _totalTurfs.toString(),
                              color: Colors.green,
                              onTap: () => _navigateToTurfList(),
                            ),
                            _buildStatCard(
                              icon: Icons.calendar_today,
                              title: 'Pending Bookings',
                              value: _pendingBookings.toString(),
                              color: Colors.blue,
                              onTap: () => _navigateToBookings(),
                            ),
                            _buildStatCard(
                              icon: Icons.handshake,
                              title: 'Negotiations',
                              value: _pendingNegotiations.toString(),
                              color: Colors.orange,
                              onTap: () => _navigateToNegotiations(),
                            ),
                            _buildStatCard(
                              icon: Icons.payments,
                              title: 'Revenue',
                              value: '\$${_totalRevenue.toStringAsFixed(2)}',
                              color: Colors.purple,
                              onTap: () => _navigateToAnalytics(),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32.0),
                        
                        // Quick Action Buttons
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        _buildActionButtons(),
                        
                        const SizedBox(height: 32.0),
                        
                        // Help section
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.info, color: Colors.blue),
                                  SizedBox(width: 8.0),
                                  Text(
                                    'Need Help?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.0,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8.0),
                              const Text(
                                'As a turf owner, you can manage your listings, handle bookings and price negotiations, and view analytics on your rentals.',
                              ),
                              const SizedBox(height: 8.0),
                              TextButton(
                                onPressed: () {
                                  // Show owner guide/help
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Owner guide coming soon')),
                                  );
                                },
                                child: const Text('Learn More'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddTurf(),
        backgroundColor: AppTheme.secondaryColor,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
  
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 36.0,
                color: color,
              ),
              const SizedBox(height: 12.0),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8.0),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                title: 'Add Turf',
                icon: Icons.add_circle,
                color: AppTheme.secondaryColor,
                onTap: () => _navigateToAddTurf(),
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: _buildActionButton(
                title: 'Manage Bookings',
                icon: Icons.book_online,
                color: Colors.blue,
                onTap: () => _navigateToBookings(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                title: 'Handle Negotiations',
                icon: Icons.handshake,
                color: Colors.orange,
                onTap: () => _navigateToNegotiations(),
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: _buildActionButton(
                title: 'View Analytics',
                icon: Icons.bar_chart,
                color: Colors.purple,
                onTap: () => _navigateToAnalytics(),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 32.0,
            ),
            const SizedBox(height: 8.0),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  void _navigateToTurfList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OwnerTurfListScreen()),
    );
  }
  
  void _navigateToAddTurf() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OwnerAddTurfScreen()),
    );
  }
  
  void _navigateToBookings() {
    // Navigate to owner bookings list
    // For now, show a message that it's coming soon
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Owner bookings management coming soon')),
    );
  }
  
  void _navigateToNegotiations() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OwnerNegotiationsScreen()),
    );
  }
  
  void _navigateToAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OwnerAnalyticsScreen()),
    );
  }
}