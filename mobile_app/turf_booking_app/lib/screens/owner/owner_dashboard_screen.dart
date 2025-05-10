import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../../services/turf_service.dart';
import '../../services/analytics_service.dart';
import 'owner_analytics_screen.dart';
import 'owner_turf_list_screen.dart';
import 'owner_negotiations_screen.dart';
import 'owner_add_turf_screen.dart';
import 'owner_create_booking_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  bool _isLoading = true;
  String? _userName;
  Map<String, dynamic>? _ownerStats;
  List<Map<String, dynamic>> _recentBookings = [];
  List<Map<String, dynamic>> _pendingNegotiations = [];
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }
  
  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Get auth token
      final authService = AuthService();
      final token = await authService.getToken();
      final userName = await authService.getUserName();
      
      // Get analytics and dashboard data
      final analyticsService = AnalyticsService(authToken: token);
      final bookingService = BookingService(authToken: token);
      
      // Get dashboard summary
      final dashboardResult = await analyticsService.getOwnerDashboardSummary();
      
      // Get recent bookings
      final bookingsResult = await bookingService.getOwnerBookings(status: 'upcoming');
      
      // Get pending negotiations
      final negotiationsResult = await bookingService.getOwnerNegotiations();
      
      setState(() {
        _isLoading = false;
        _userName = userName;
        
        if (dashboardResult['success']) {
          _ownerStats = dashboardResult['data'];
        }
        
        if (bookingsResult['success'] && bookingsResult['bookings'] != null) {
          final bookings = bookingsResult['bookings'];
          _recentBookings = bookings.take(5).map((booking) => {
            'id': booking.id,
            'turf_name': booking.turfName,
            'date': booking.bookingDate,
            'user_name': booking.userName,
            'status': booking.status,
            'amount': booking.totalAmount,
          }).toList();
        }
        
        if (negotiationsResult['success'] && 
            negotiationsResult['negotiations'] != null) {
          final negotiations = negotiationsResult['negotiations'];
          _pendingNegotiations = negotiations
              .where((nego) => nego.status == 'pending')
              .take(3)
              .map((nego) => {
                'id': nego.id,
                'booking_id': nego.bookingId,
                'turf_name': nego.turfName,
                'user_name': nego.userName,
                'original_amount': nego.originalAmount,
                'current_amount': nego.currentAmount,
                'created_at': nego.createdAt,
              }).toList();
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load dashboard data: $e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeSection(),
                        const SizedBox(height: 24),
                        _buildQuickStats(),
                        const SizedBox(height: 24),
                        _buildQuickActions(),
                        const SizedBox(height: 24),
                        _buildPendingNegotiationsSection(),
                        const SizedBox(height: 24),
                        _buildRecentBookingsSection(),
                      ],
                    ),
                  ),
                ),
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboardData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWelcomeSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: AppTheme.primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, $_userName!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Manage your turfs and bookings',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickStats() {
    final stats = _ownerStats ?? {
      'total_turfs': 0,
      'total_bookings': 0,
      'total_revenue': 0.0,
      'conversion_rate': 0.0,
    };
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'At a Glance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Turfs',
                '${stats['total_turfs']}',
                Icons.sports_soccer,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Bookings',
                '${stats['total_bookings']}',
                Icons.calendar_today,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Revenue',
                '\$${stats['total_revenue'].toStringAsFixed(2)}',
                Icons.attach_money,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Conversion Rate',
                '${stats['conversion_rate'].toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Add New Turf',
                Icons.add_circle,
                Colors.green,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OwnerAddTurfScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Manage Turfs',
                Icons.edit,
                Colors.blue,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OwnerTurfListScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Create Booking',
                Icons.event_available,
                Colors.teal,
                () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => const OwnerCreateBookingScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Negotiations',
                Icons.handshake,
                Colors.orange,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OwnerNegotiationsScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Analytics',
                Icons.bar_chart,
                Colors.purple,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OwnerAnalyticsScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            // Empty space for alignment
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }
  
  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPendingNegotiationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                'Pending Negotiations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OwnerNegotiationsScreen()),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _pendingNegotiations.isEmpty
            ? const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'No pending negotiations',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              )
            : Column(
                children: _pendingNegotiations.map((negotiation) {
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.orange,
                        child: Icon(
                          Icons.handshake,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(negotiation['turf_name']),
                      subtitle: Text('From: ${negotiation['user_name']}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${negotiation['current_amount'].toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          Text(
                            '\$${negotiation['original_amount'].toStringAsFixed(2)}',
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const OwnerNegotiationsScreen()),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
      ],
    );
  }
  
  Widget _buildRecentBookingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                'Recent Bookings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to all bookings
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _recentBookings.isEmpty
            ? const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'No recent bookings',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              )
            : Column(
                children: _recentBookings.map((booking) {
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Text(
                          booking['user_name'].substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(booking['turf_name']),
                      subtitle: Text(
                        '${_formatDate(booking['date'])} • ${booking['user_name']}',
                      ),
                      trailing: Text(
                        '\$${booking['amount'].toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        // Navigate to booking details
                      },
                    ),
                  );
                }).toList(),
              ),
      ],
    );
  }
  
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}