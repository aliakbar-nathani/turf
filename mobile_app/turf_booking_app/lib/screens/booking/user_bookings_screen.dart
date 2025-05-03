import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_theme.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class UserBookingsScreen extends StatefulWidget {
  const UserBookingsScreen({super.key});

  @override
  State<UserBookingsScreen> createState() => _UserBookingsScreenState();
}

class _UserBookingsScreenState extends State<UserBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<Booking> _allBookings = [];
  List<Booking> _upcomingBookings = [];
  List<Booking> _pastBookings = [];
  List<Booking> _pendingBookings = [];
  
  bool _isLoading = true;
  String? _errorMessage;
  
  final AuthService _authService = AuthService();
  late BookingService _bookingService;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    final token = await _authService.getToken();
    
    if (token == null) {
      _navigateToLogin();
      return;
    }
    
    _bookingService = BookingService(authToken: token);
    final result = await _bookingService.getBookings();
    
    setState(() {
      _isLoading = false;
      
      if (result['success']) {
        _allBookings = result['bookings'];
        _filterBookings();
      } else {
        _errorMessage = result['message'];
      }
    });
  }
  
  void _filterBookings() {
    _upcomingBookings = _allBookings.where((booking) => 
      booking.isConfirmed || 
      booking.status == 'payment_pending'
    ).toList();
    
    _pendingBookings = _allBookings.where((booking) => 
      booking.isPending || 
      booking.status == 'negotiating'
    ).toList();
    
    _pastBookings = _allBookings.where((booking) => 
      booking.isCompleted || 
      booking.status == 'cancelled'
    ).toList();
  }
  
  Future<void> _cancelBooking(Booking booking) async {
    final result = await _bookingService.cancelBooking(booking.id);
    
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: AppTheme.successColor,
        ),
      );
      
      // Reload bookings after cancellation
      _loadBookings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
  
  void _showCancelConfirmationDialog(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text(
          'Are you sure you want to cancel this booking? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('No, Keep It'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelBooking(booking);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Pending'),
            Tab(text: 'Past'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          indicatorColor: Colors.white,
        ),
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
                        onPressed: _loadBookings,
                        style: AppTheme.primaryButtonStyle,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBookingList(_upcomingBookings, 'upcoming'),
                    _buildBookingList(_pendingBookings, 'pending'),
                    _buildBookingList(_pastBookings, 'past'),
                  ],
                ),
    );
  }
  
  Widget _buildBookingList(List<Booking> bookings, String type) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getEmptyIcon(type),
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyMessage(type),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadBookings,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _buildBookingCard(booking, type);
        },
      ),
    );
  }
  
  Widget _buildBookingCard(Booking booking, String type) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header with status
          Container(
            color: _getStatusColor(booking.status),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getStatusText(booking.status),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  booking.formattedDate,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Booking details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Turf image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: booking.turfImageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: booking.turfImageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: SpinKitFadingCircle(
                                color: AppTheme.primaryColor,
                                size: 24.0,
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.sports_soccer,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.sports_soccer,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(width: 16.0),
                
                // Booking info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.turfName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                      
                      const SizedBox(height: 4.0),
                      
                      // Time
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            booking.timeRange,
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 4.0),
                      
                      // Price
                      Row(
                        children: [
                          const Icon(
                            Icons.payment,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '\$${booking.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (booking.isNegotiable && booking.proposedPrice != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(Proposed: \$${booking.proposedPrice!.toStringAsFixed(2)})',
                              style: TextStyle(
                                color: AppTheme.accentColor,
                                fontSize: 12.0,
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      const SizedBox(height: 4.0),
                      
                      // Payment status
                      Row(
                        children: [
                          Icon(
                            booking.isPaid ? Icons.check_circle : Icons.money_off,
                            size: 16,
                            color: booking.isPaid ? AppTheme.successColor : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            booking.isPaid ? 'Paid' : 'Payment pending',
                            style: TextStyle(
                              color: booking.isPaid ? AppTheme.successColor : Colors.grey[600],
                            ),
                          ),
                          if (booking.paymentMethod != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(${_formatPaymentMethod(booking.paymentMethod!)})',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12.0,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Action buttons
          if (booking.canCancel || booking.canPay || booking.canNegotiate)
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (booking.canCancel)
                    OutlinedButton(
                      onPressed: () => _showCancelConfirmationDialog(booking),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: BorderSide(color: AppTheme.errorColor),
                      ),
                      child: const Text('Cancel'),
                    ),
                  
                  if (booking.canPay) ...[
                    const SizedBox(width: 8.0),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to payment screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Payment functionality coming soon'),
                          ),
                        );
                      },
                      style: AppTheme.primaryButtonStyle,
                      child: const Text('Pay Now'),
                    ),
                  ],
                  
                  if (booking.canNegotiate) ...[
                    const SizedBox(width: 8.0),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to negotiation screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Negotiation view coming soon'),
                          ),
                        );
                      },
                      style: AppTheme.secondaryButtonStyle,
                      child: const Text('Negotiation'),
                    ),
                  ],
                ],
              ),
            ),
          
          // Owner response for negotiation
          if (booking.status == 'negotiating' && booking.ownerResponse != null)
            Container(
              padding: const EdgeInsets.all(12.0),
              color: Colors.grey[100],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Owner Response:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.0,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    booking.ownerResponse!,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return AppTheme.successColor;
      case 'pending':
        return Colors.orange;
      case 'negotiating':
        return AppTheme.secondaryColor;
      case 'payment_pending':
        return Colors.purple;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return Colors.grey;
      default:
        return AppTheme.primaryColor;
    }
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmed';
      case 'pending':
        return 'Pending Approval';
      case 'negotiating':
        return 'Price Negotiation';
      case 'payment_pending':
        return 'Payment Pending';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.toUpperCase();
    }
  }
  
  String _formatPaymentMethod(String method) {
    if (method == 'pay_online') {
      return 'Online Payment';
    } else if (method == 'pay_on_arrival') {
      return 'Pay on Arrival';
    }
    return method;
  }
  
  IconData _getEmptyIcon(String type) {
    switch (type) {
      case 'upcoming':
        return Icons.event_available;
      case 'pending':
        return Icons.pending_actions;
      case 'past':
        return Icons.history;
      default:
        return Icons.sports_soccer;
    }
  }
  
  String _getEmptyMessage(String type) {
    switch (type) {
      case 'upcoming':
        return 'You have no upcoming bookings.\nBook a turf to get started!';
      case 'pending':
        return 'You have no pending bookings.\nAll your booking requests will appear here.';
      case 'past':
        return 'You have no past bookings.\nCompleted or cancelled bookings will appear here.';
      default:
        return 'No bookings found.';
    }
  }
}