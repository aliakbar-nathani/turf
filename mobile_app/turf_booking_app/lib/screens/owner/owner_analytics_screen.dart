import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/analytics_service.dart';

class OwnerAnalyticsScreen extends StatefulWidget {
  const OwnerAnalyticsScreen({super.key});

  @override
  State<OwnerAnalyticsScreen> createState() => _OwnerAnalyticsScreenState();
}

class _OwnerAnalyticsScreenState extends State<OwnerAnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Analytics data
  Map<String, dynamic>? _bookingAnalytics;
  Map<String, dynamic>? _turfPerformance;
  Map<String, dynamic>? _negotiationStats;
  
  // Filters
  String _periodFilter = 'month';
  final List<Map<String, dynamic>> _periodOptions = [
    {'value': 'week', 'label': 'Week'},
    {'value': 'month', 'label': 'Month'},
    {'value': 'quarter', 'label': 'Quarter'},
    {'value': 'year', 'label': 'Year'},
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      // Load data for the selected tab if not already loaded
      _loadDataForCurrentTab();
    });
    _loadDataForCurrentTab();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadDataForCurrentTab() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final authService = AuthService();
      final token = await authService.getToken();
      final analyticsService = AnalyticsService(authToken: token);
      
      switch (_tabController.index) {
        case 0: // Bookings
          final result = await analyticsService.getBookingAnalytics(
            period: _periodFilter,
          );
          
          setState(() {
            _isLoading = false;
            if (result['success']) {
              _bookingAnalytics = result['data'];
            } else {
              _errorMessage = result['message'];
            }
          });
          break;
          
        case 1: // Turf Performance
          final result = await analyticsService.getTurfPerformance();
          
          setState(() {
            _isLoading = false;
            if (result['success']) {
              _turfPerformance = result['data'];
            } else {
              _errorMessage = result['message'];
            }
          });
          break;
          
        case 2: // Negotiations
          final result = await analyticsService.getNegotiationStats();
          
          setState(() {
            _isLoading = false;
            if (result['success']) {
              _negotiationStats = result['data'];
            } else {
              _errorMessage = result['message'];
            }
          });
          break;
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading analytics data: $e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Insights'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Bookings'),
            Tab(text: 'Turf Performance'),
            Tab(text: 'Negotiations'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingAnalyticsTab(),
          _buildTurfPerformanceTab(),
          _buildNegotiationStatsTab(),
        ],
      ),
    );
  }
  
  Widget _buildBookingAnalyticsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage != null) {
      return _buildErrorView();
    }
    
    final data = _bookingAnalytics;
    if (data == null) {
      return const Center(child: Text('No data available'));
    }
    
    final bookingsOverTime = data['bookings_over_time'] as List?;
    
    return RefreshIndicator(
      onRefresh: _loadDataForCurrentTab,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period filter
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Time Period:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _periodFilter,
                        items: _periodOptions.map((option) {
                          return DropdownMenuItem<String>(
                            value: option['value'],
                            child: Text(option['label']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _periodFilter = value;
                            });
                            _loadDataForCurrentTab();
                          }
                        },
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Key metrics
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Bookings',
                    '${data['total_bookings']}',
                    Icons.calendar_today,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Revenue',
                    '\$${data['total_revenue'].toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Bookings over time chart
            if (bookingsOverTime != null && bookingsOverTime.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bookings & Revenue Over Time',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: _buildSimpleBarChart(bookingsOverTime),
                      ),
                    ],
                  ),
                ),
              ),
              
            const SizedBox(height: 16),
            
            // Average booking value
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.trending_up,
                      color: Colors.purple,
                      size: 36,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Average Booking Value',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${data['average_booking_value'].toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTurfPerformanceTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage != null) {
      return _buildErrorView();
    }
    
    final data = _turfPerformance;
    if (data == null) {
      return const Center(child: Text('No data available'));
    }
    
    final turfs = data['turfs'] as List?;
    final popularDays = data['most_popular_days'] as List?;
    final popularTimes = data['most_popular_times'] as List?;
    
    return RefreshIndicator(
      onRefresh: _loadDataForCurrentTab,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Turf performance comparison
            if (turfs != null && turfs.isNotEmpty) ...[
              const Text(
                'Turf Performance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...turfs.map((turf) => _buildTurfPerformanceCard(turf)).toList(),
              const SizedBox(height: 24),
            ],
            
            // Popular booking days
            if (popularDays != null && popularDays.isNotEmpty) ...[
              const Text(
                'Most Popular Days',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: popularDays.map((day) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Text(
                              day['day'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: day['bookings'] / (popularDays.map((d) => d['bookings']).reduce((a, b) => a > b ? a : b)),
                                backgroundColor: Colors.grey[200],
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${day['bookings']} bookings',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Popular booking times
            if (popularTimes != null && popularTimes.isNotEmpty) ...[
              const Text(
                'Most Popular Time Slots',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: popularTimes.map((time) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(
                                time['time'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: time['bookings'] / (popularTimes.map((t) => t['bookings']).reduce((a, b) => a > b ? a : b)),
                                backgroundColor: Colors.grey[200],
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${time['bookings']} bookings',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildNegotiationStatsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage != null) {
      return _buildErrorView();
    }
    
    final data = _negotiationStats;
    if (data == null) {
      return const Center(child: Text('No data available'));
    }
    
    return RefreshIndicator(
      onRefresh: _loadDataForCurrentTab,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Key metrics
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Negotiations',
                    '${data['total_negotiations']}',
                    Icons.handshake,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Conversion Rate',
                    '${data['conversion_rate'].toStringAsFixed(1)}%',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Avg. Discount',
                    '${data['average_discount'].toStringAsFixed(1)}%',
                    Icons.trending_down,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Revenue Impact',
                    '\$${data['revenue_impact'].toStringAsFixed(2)}',
                    Icons.attach_money,
                    data['revenue_impact'] >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Negotiation status breakdown
            const Text(
              'Negotiation Outcomes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildNegotiationStatusRow(
                      'Accepted',
                      data['accepted'],
                      data['total_negotiations'],
                      Colors.green,
                    ),
                    const SizedBox(height: 8),
                    _buildNegotiationStatusRow(
                      'Rejected',
                      data['rejected'],
                      data['total_negotiations'],
                      Colors.red,
                    ),
                    const SizedBox(height: 8),
                    _buildNegotiationStatusRow(
                      'Counter Offered',
                      data['counter_offered'],
                      data['total_negotiations'],
                      Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    _buildNegotiationStatusRow(
                      'Pending',
                      data['pending'],
                      data['total_negotiations'],
                      Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Suggestions based on data
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb,
                          color: Colors.amber[800],
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Insights & Suggestions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      data['conversion_rate'] < 50
                          ? 'Consider being more flexible with your pricing. Your conversion rate is below 50%, which might indicate your pricing strategy could be adjusted.'
                          : 'Your negotiation strategy is working well with a ${data['conversion_rate'].toStringAsFixed(1)}% conversion rate. Consider analyzing which turfs have the most successful negotiations.',
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The average discount you\'re giving is ${data['average_discount'].toStringAsFixed(1)}%. ' +
                      (data['average_discount'] > 15
                          ? 'This is relatively high, which might impact your profitability. Consider setting slightly higher base prices.'
                          : 'This is a reasonable discount that helps close deals without significantly impacting your revenue.'),
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
              onPressed: _loadDataForCurrentTab,
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
  
  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
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
  
  Widget _buildTurfPerformanceCard(Map<String, dynamic> turf) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              turf['name'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTurfStat(
                    'Bookings',
                    '${turf['bookings_count']}',
                    Icons.calendar_today,
                  ),
                ),
                Expanded(
                  child: _buildTurfStat(
                    'Revenue',
                    '\$${turf['revenue'].toStringAsFixed(2)}',
                    Icons.attach_money,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTurfStat(
                    'Rating',
                    '${turf['rating']}',
                    Icons.star,
                  ),
                ),
                Expanded(
                  child: _buildTurfStat(
                    'Occupancy',
                    '${turf['occupancy_rate'].toStringAsFixed(1)}%',
                    Icons.access_time,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTurfStat(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNegotiationStatusRow(String status, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;
    
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            status,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage / 100,
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            '$count (${percentage.toStringAsFixed(1)}%)',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSimpleBarChart(List bookingsOverTime) {
    // Since this is a simplified visualization without a charting library
    // We'll create a basic representation using Containers
    
    // Find the maximum values for scaling
    double maxCount = 0;
    double maxRevenue = 0;
    
    for (final entry in bookingsOverTime) {
      if (entry['count'] > maxCount) {
        maxCount = entry['count'].toDouble();
      }
      if (entry['revenue'] > maxRevenue) {
        maxRevenue = entry['revenue'].toDouble();
      }
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: bookingsOverTime.map((entry) {
        final count = entry['count'];
        final revenue = entry['revenue'];
        final date = entry['date'].toString().substring(5); // MM-DD format
        
        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                height: 100 * (revenue / maxRevenue),
                width: 12,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 100 * (count / maxCount),
                width: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: const TextStyle(
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}