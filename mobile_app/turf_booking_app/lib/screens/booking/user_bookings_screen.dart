import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../services/auth_service.dart';
import '../../services/user_session_manager.dart';
import '../../services/payment_service.dart';
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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Booking #${booking.id} - ${booking.turfName}',
                style: const TextStyle(fontSize: 14.0),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              const Text(
                'Are you sure you want to cancel this booking? This action cannot be undone.',
                style: TextStyle(fontSize: 14.0),
              ),
            ],
          ),
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
  
  void _showPaymentDialog(Booking booking) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Complete Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking #${booking.id} - ${booking.turfName}',
                  style: const TextStyle(fontSize: 14.0),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                Text(
                  'Amount: \$${booking.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please click the button below to proceed to the payment page:',
                  style: TextStyle(fontSize: 14.0),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Show loading indicator while payment session is being created
                Navigator.pop(context);
                
                // Show loading indicator
                final loadingSnackBar = SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('Preparing payment...'),
                    ],
                  ),
                  duration: const Duration(seconds: 3),
                );
                ScaffoldMessenger.of(context).showSnackBar(loadingSnackBar);
                
                try {
                  // Get token and create payment service
                  final token = await _authService.getToken();
                  if (token == null) {
                    throw Exception('Authentication required');
                  }
                  
                  final paymentService = PaymentService(authToken: token);
                  
                  // Create checkout session
                  final result = await paymentService.createCheckoutSession(booking.id);
                  
                  if (!result['success']) {
                    throw Exception(result['message']);
                  }
                  
                  // Launch payment in browser
                  final paymentUrl = result['checkout_url'];
                  final sessionId = result['session_id'];
                  
                  final launched = await paymentService.launchPayment(paymentUrl);
                  
                  if (!launched) {
                    throw Exception('Could not launch payment page');
                  }
                  
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment page opened in browser. Once payment is complete, your booking will be automatically confirmed.'),
                      duration: Duration(seconds: 5),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  // Poll for payment status updates
                  bool isPaid = false;
                  int retryCount = 0;
                  const maxRetries = 5;
                  
                  while (!isPaid && retryCount < maxRetries) {
                    await Future.delayed(const Duration(seconds: 3));
                    
                    // Check payment status
                    final statusResult = await paymentService.checkPaymentStatus(
                      booking.id, 
                      sessionId,
                    );
                    
                    if (statusResult['success'] && statusResult['is_paid']) {
                      isPaid = true;
                      
                      // Show confirmation and refresh bookings
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Payment successful! Your booking has been confirmed.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      
                      _loadBookings();
                      break;
                    }
                    
                    retryCount++;
                  }
                  
                  // Final refresh after a few seconds in case the webhook hasn't processed yet
                  if (!isPaid) {
                    Future.delayed(const Duration(seconds: 5), () {
                      _loadBookings();
                    });
                  }
                } catch (e) {
                  // Show error if payment initiation fails
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Payment error: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Proceed to Payment'),
            ),
          ],
        );
      },
    );
  }
  
  void _showNegotiationDialog(Booking booking) {
    final proposedPriceController = TextEditingController(
      text: booking.proposedPrice?.toString() ?? booking.price.toString()
    );
    final messageController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Negotiate Price'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking #${booking.id} - ${booking.turfName}',
                  style: const TextStyle(fontSize: 14.0),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                Text(
                  'Current Price: \$${booking.price.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
              
              // Price input field
              TextField(
                controller: proposedPriceController,
                decoration: const InputDecoration(
                  labelText: 'Your Proposed Price (\$)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  // In a real app, we'd use a proper numeric formatter
                  // FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Message input field
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message to Owner (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Explain why you are proposing this price...',
                ),
                maxLines: 3,
              ),
            ],
          ),
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
                
                // Validate input
                double? proposedPrice;
                try {
                  proposedPrice = double.parse(proposedPriceController.text);
                  if (proposedPrice <= 0) {
                    throw Exception('Invalid price');
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid price'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Submitting your offer...'),
                    duration: Duration(seconds: 1),
                  ),
                );
                
                try {
                  // Show loading indicator
                  final loadingSnackBar = SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('Submitting your offer...'),
                      ],
                    ),
                    duration: const Duration(seconds: 2),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(loadingSnackBar);
                  
                  // Make the API call to submit the negotiation
                  final token = await _authService.getToken();
                  final bookingService = BookingService(authToken: token);
                  final result = await bookingService.respondToNegotiation(
                    bookingId: booking.id,
                    action: 'counter',
                    proposedPrice: proposedPrice,
                    message: messageController.text.trim(),
                  );
                  
                  // Add a small delay for better UX
                  await Future.delayed(const Duration(milliseconds: 200));
                  
                  // Refresh the bookings list
                  await _loadBookings();
                  
                  // Show success message
                  if (result['success']) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message'] ?? 'Your price proposal has been sent to the owner'),
                        backgroundColor: AppTheme.successColor,
                      ),
                    );
                  } else {
                    throw Exception(result['message'] ?? 'Failed to submit offer');
                  }
                } catch (e) {
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryColor,
              ),
              child: const Text('Submit Offer'),
            ),
          ],
        );
      },
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Turf image and status tag
          Stack(
            children: [
              // Turf image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
                child: SizedBox(
                  height: 150,
                  width: double.infinity,
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
              
              // Status tag
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(booking.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Booking details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Turf name
                Text(
                  booking.turfName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
                
                const SizedBox(height: 8.0),
                
                // Booking date and time - use Wrap to prevent overflow
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16.0,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          booking.formattedDate,
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 13.0,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16.0,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          booking.formattedTimeSlot,
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 13.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 8.0),
                
                // Price and payment info - use Wrap for flexible layout
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          size: 16.0,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6.0),
                        RichText(
                          text: TextSpan(
                            style: DefaultTextStyle.of(context).style,
                            children: [
                              TextSpan(
                                text: 'Price: ',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13.0,
                                ),
                              ),
                              TextSpan(
                                text: '\$${booking.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontSize: 13.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Payment method tag
                    if (booking.paymentMethod != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: booking.paymentMethod == 'pay_online' 
                              ? Colors.blue.withOpacity(0.1) 
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: booking.paymentMethod == 'pay_online' 
                                ? Colors.blue.withOpacity(0.3) 
                                : Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          booking.paymentMethod == 'pay_online' 
                              ? 'Online Payment' 
                              : 'Pay on Arrival',
                          style: TextStyle(
                            fontSize: 10.0,
                            fontWeight: FontWeight.bold,
                            color: booking.paymentMethod == 'pay_online' 
                                ? Colors.blue 
                                : Colors.orange,
                          ),
                        ),
                      ),
                  ],
                ),
                
                // If there's a proposed price in negotiation
                if (booking.status == 'negotiating' && booking.proposedPrice != null) ...[
                  const SizedBox(height: 16.0),
                  const Divider(),
                  const SizedBox(height: 8.0),
                  
                  // Use Wrap for better responsiveness
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Proposed Price:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryColor,
                          fontSize: 13.0,
                        ),
                      ),
                      Text(
                        '\$${booking.proposedPrice!.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryColor,
                          fontSize: 15.0,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4.0),
                  
                  if (booking.message != null && booking.message!.isNotEmpty)
                    Text(
                      'Your Message: "${booking.message}"',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                        fontSize: 12.0,
                      ),
                    ),
                ],
                
                const SizedBox(height: 16.0),
                
                // Action buttons - Wrap for flexibility in small screens
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  alignment: WrapAlignment.end,
                  children: _buildActionButtons(booking, type),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  List<Widget> _buildActionButtons(Booking booking, String type) {
    final List<Widget> actions = [];
    
    // Cancel button for upcoming and pending bookings
    if ((type == 'upcoming' || type == 'pending') && 
        !booking.isCompleted && 
        booking.status != 'cancelled') {
      actions.add(
        OutlinedButton(
          onPressed: () => _showCancelConfirmationDialog(booking),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.errorColor,
            side: BorderSide(color: AppTheme.errorColor),
            // Smaller padding to prevent overflow
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(fontSize: 12.0),
          ),
        ),
      );
    }
    
    // Add spacing between buttons - using smaller spacing
    if (actions.isNotEmpty) {
      actions.add(const SizedBox(width: 6.0));
    }
    
    // Payment button for pending payment
    if (booking.status == 'payment_pending' && booking.paymentMethod == 'pay_online') {
      actions.add(
        ElevatedButton(
          onPressed: () => _showPaymentDialog(booking),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            // Smaller padding to prevent overflow
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          ),
          child: const Text(
            'Pay Now',
            style: TextStyle(fontSize: 12.0),
          ),
        ),
      );
    }
    
    // View button for all bookings
    if (actions.isEmpty || type == 'past') {
      actions.add(
        ElevatedButton(
          onPressed: () {
            // View booking details
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('View booking details functionality coming soon'),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.secondaryColor,
            foregroundColor: Colors.white,
            // Smaller padding to prevent overflow
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          ),
          child: const Text(
            'View Details',
            style: TextStyle(fontSize: 12.0),
          ),
        ),
      );
    }
    
    // Counter offer button for negotiating bookings
    if (booking.status == 'negotiating') {
      actions.add(
        ElevatedButton(
          onPressed: () => _showNegotiationDialog(booking),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.secondaryColor,
            foregroundColor: Colors.white,
            // Smaller padding to prevent overflow
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          ),
          child: const Text(
            'Counter Offer',
            style: TextStyle(fontSize: 12.0),
          ),
        ),
      );
    }
    
    return actions;
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'negotiating':
        return Colors.blue;
      case 'payment_pending':
        return Colors.purple;
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending Approval';
      case 'negotiating':
        return 'Price Negotiation';
      case 'payment_pending':
        return 'Payment Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
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