import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/analytics_service.dart';

class OwnerAnalyticsScreen extends StatefulWidget {
  const OwnerAnalyticsScreen({super.key});

  @override
  State<OwnerAnalyticsScreen> createState() => _OwnerAnalyticsScreenState();
}

class _OwnerAnalyticsScreenState extends State<OwnerAnalyticsScreen> {
  final AuthService _authService = AuthService();
  late AnalyticsService _analyticsService;
  
  bool _isLoading = true;
  String? _errorMessage;
  
  // Analytics data
  Map<String, dynamic> _revenueData = {};
  Map<String, dynamic> _bookingData = {};
  Map<String, dynamic> _turfPerformance = {};
  
  String _selectedTimeRange = 'month'; // week, month, year
  
  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  Future<void> _initialize() async {
    final token = await _authService.getToken();
    setState(() {
      _analyticsService = AnalyticsService(authToken: token);
    });
    
    _loadAnalytics();
  }
  
  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Get revenue data
      final revenueResult = await _analyticsService.getRevenueData(timeRange: _selectedTimeRange);
      
      // Get booking data
      final bookingResult = await _analyticsService.getBookingData(timeRange: _selectedTimeRange);
      
      // Get turf performance data
      final turfResult = await _analyticsService.getTurfPerformanceData(timeRange: _selectedTimeRange);
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        
        if (revenueResult['success']) {
          _revenueData = revenueResult['data'];
        }
        
        if (bookingResult['success']) {
          _bookingData = bookingResult['data'];
        }
        
        if (turfResult['success']) {
          _turfPerformance = turfResult['data'];
        }
        
        // Error handling
        if (!revenueResult['success'] && !bookingResult['success'] && !turfResult['success']) {
          _errorMessage = 'Failed to load analytics data';
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
  
  void _changeTimeRange(String range) {
    if (_selectedTimeRange != range) {
      setState(() {
        _selectedTimeRange = range;
      });
      _loadAnalytics();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
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
                        onPressed: _loadAnalytics,
                        style: AppTheme.primaryButtonStyle,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Time range selector
                        _buildTimeRangeSelector(),
                        const SizedBox(height: 24.0),
                        
                        // Revenue summary
                        _buildRevenueSummary(),
                        const SizedBox(height: 32.0),
                        
                        // Booking chart
                        _buildBookingChart(),
                        const SizedBox(height: 32.0),
                        
                        // Turf performance
                        _buildTurfPerformance(),
                        const SizedBox(height: 32.0),
                        
                        // Export button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Export feature coming soon')),
                              );
                            },
                            icon: const Icon(Icons.download),
                            label: const Text('Export Data'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                      ],
                    ),
                  ),
                ),
    );
  }
  
  Widget _buildTimeRangeSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildTimeRangeButton('Week', 'week'),
            _buildTimeRangeButton('Month', 'month'),
            _buildTimeRangeButton('Year', 'year'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTimeRangeButton(String label, String value) {
    return TextButton(
      onPressed: () => _changeTimeRange(value),
      style: TextButton.styleFrom(
        foregroundColor: _selectedTimeRange == value 
            ? AppTheme.primaryColor 
            : Colors.grey,
        backgroundColor: _selectedTimeRange == value 
            ? AppTheme.primaryColor.withOpacity(0.1) 
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: _selectedTimeRange == value 
              ? FontWeight.bold 
              : FontWeight.normal,
        ),
      ),
    );
  }
  
  Widget _buildRevenueSummary() {
    // Sample data - in a real app, this would come from the API
    final totalRevenue = _revenueData['total_revenue'] ?? 0.0;
    final comparedToLastPeriod = _revenueData['compared_to_last_period'] ?? 0.0;
    final isIncrease = comparedToLastPeriod >= 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Revenue Summary',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16.0),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Total Revenue',
                      style: TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      '(${_getTimeRangeLabel()})',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Text(
                  '\$${totalRevenue.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    Icon(
                      isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 16.0,
                      color: isIncrease ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      '${comparedToLastPeriod.abs().toStringAsFixed(1)}% ${isIncrease ? 'increase' : 'decrease'} from last ${_selectedTimeRange}',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: isIncrease ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildBookingChart() {
    // Sample data - in a real app, this would come from the API
    final completedBookings = _bookingData['completed'] ?? 0;
    final pendingBookings = _bookingData['pending'] ?? 0;
    final cancelledBookings = _bookingData['cancelled'] ?? 0;
    final totalBookings = completedBookings + pendingBookings + cancelledBookings;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Booking Overview',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16.0),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(
                  height: 180,
                  child: totalBookings > 0
                      ? PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 50,
                            sections: [
                              PieChartSectionData(
                                color: Colors.green,
                                value: completedBookings.toDouble(),
                                title: '${((completedBookings / totalBookings) * 100).round()}%',
                                radius: 60,
                                titleStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              PieChartSectionData(
                                color: Colors.orange,
                                value: pendingBookings.toDouble(),
                                title: '${((pendingBookings / totalBookings) * 100).round()}%',
                                radius: 60,
                                titleStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              PieChartSectionData(
                                color: Colors.red,
                                value: cancelledBookings.toDouble(),
                                title: '${((cancelledBookings / totalBookings) * 100).round()}%',
                                radius: 60,
                                titleStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const Center(
                          child: Text(
                            'No booking data available',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16.0,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 16.0),
                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildLegendItem('Completed', Colors.green, completedBookings),
                    _buildLegendItem('Pending', Colors.orange, pendingBookings),
                    _buildLegendItem('Cancelled', Colors.red, cancelledBookings),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildLegendItem(String label, Color color, int count) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label ($count)',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
  
  Widget _buildTurfPerformance() {
    // Sample data - in a real app, this would come from the API
    final turfStats = _turfPerformance['turfs'] ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Turf Performance',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16.0),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: turfStats.isEmpty
                ? const Center(
                    child: Text(
                      'No turf performance data available',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16.0,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      for (int i = 0; i < turfStats.length; i++)
                        _buildTurfStatItem(turfStats[i], i == turfStats.length - 1),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTurfStatItem(Map<String, dynamic> turfStat, bool isLast) {
    final name = turfStat['name'] ?? 'Unknown Turf';
    final bookingCount = turfStat['booking_count'] ?? 0;
    final revenue = turfStat['revenue'] ?? 0.0;
    final occupancyRate = turfStat['occupancy_rate'] ?? 0.0;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bookings',
                              style: TextStyle(
                                fontSize: 12.0,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '$bookingCount',
                              style: const TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Revenue',
                              style: TextStyle(
                                fontSize: 12.0,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '\$${revenue.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Occupancy',
                              style: TextStyle(
                                fontSize: 12.0,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '${occupancyRate.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: 16.0),
          const Divider(),
          const SizedBox(height: 16.0),
        ],
      ],
    );
  }
  
  String _getTimeRangeLabel() {
    switch (_selectedTimeRange) {
      case 'week':
        return 'This Week';
      case 'month':
        return 'This Month';
      case 'year':
        return 'This Year';
      default:
        return 'This Month';
    }
  }
}