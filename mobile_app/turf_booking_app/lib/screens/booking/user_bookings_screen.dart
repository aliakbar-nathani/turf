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
  
  void _showPaymentDialog(Booking booking) {
    // Get the redirect URL for payment
    String paymentUrl = '';
    
    // Construct payment URL using the API base URL
    try {
      // Use the same base URL as the rest of the API
      paymentUrl = '${ApiConfig.baseUrl}/payment/checkout/${booking.id}';
    } catch (e) {
      print('Error constructing payment URL: $e');
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Complete Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Booking #${booking.id} - ${booking.turfName}'),
              const SizedBox(height: 8),
              Text('Amount: \$${booking.price.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              const Text('Please click the button below to proceed to the payment page:'),
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
                
                try {
                  // Convert string to Uri
                  final Uri url = Uri.parse(paymentUrl);

                  // Launch the URL in external browser
                  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                    throw Exception('Could not launch $url');
                  }
                  
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment page opened in browser. Once payment is complete, your booking will be automatically confirmed.'),
                      duration: Duration(seconds: 5),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  // Refresh bookings after a delay to reflect the updated payment status
                  Future.delayed(const Duration(seconds: 5), () {
                    _loadBookings();
                  });
                } catch (e) {
                  // Show error if URL launch fails
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Could not open payment page: $e'),
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Booking #${booking.id} - ${booking.turfName}'),
              const SizedBox(height: 8),
              Text('Current Price: \$${booking.price.toStringAsFixed(2)}'),
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
          if (booking.canCancel || booking.canPay || booking.canNegotiate || booking.userCanRespond)
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
                        _showPaymentDialog(booking);
                      },
                      style: AppTheme.primaryButtonStyle,
                      child: const Text('Pay Now'),
                    ),
                  ],
                  
                  if (booking.userCanRespond) ...[
                    const SizedBox(width: 8.0),
                    ElevatedButton(
                      onPressed: () async {
                        // Show dialog to accept, reject, or counter offer
                        await _showRespondToNegotiationDialog(booking);
                      },
                      style: AppTheme.secondaryButtonStyle,
                      child: const Text('Respond to Offer'),
                    ),
                  ] else if (booking.canNegotiate) ...[
                    const SizedBox(width: 8.0),
                    ElevatedButton(
                      onPressed: () {
                        _showNegotiationDialog(booking);
                      },
                      style: AppTheme.secondaryButtonStyle,
                      child: const Text('Negotiate'),
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
  
  Future<void> _showRespondToNegotiationDialog(Booking booking) async {
    final proposedPriceController = TextEditingController(
      text: booking.proposedPrice?.toString() ?? booking.price.toString()
    );
    final messageController = TextEditingController();
    
    // Whether the user is making a counter offer or not
    bool isCounterOffer = false;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Respond to Negotiation'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Booking #${booking.id} - ${booking.turfName}'),
                  const SizedBox(height: 8),
                  Text('Current Offer: \$${booking.proposedPrice?.toStringAsFixed(2) ?? booking.price.toStringAsFixed(2)}'),
                  const SizedBox(height: 16),
                  
                  // Radio buttons for action selection
                  Row(
                    children: [
                      Radio<bool>(
                        value: false,
                        groupValue: isCounterOffer,
                        onChanged: (value) {
                          setState(() {
                            isCounterOffer = value!;
                          });
                        },
                      ),
                      const Text('Accept or Reject Offer'),
                    ],
                  ),
                  Row(
                    children: [
                      Radio<bool>(
                        value: true,
                        groupValue: isCounterOffer,
                        onChanged: (value) {
                          setState(() {
                            isCounterOffer = value!;
                          });
                        },
                      ),
                      const Text('Make Counter Offer'),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  if (isCounterOffer) ...[
                    // Price input field
                    TextField(
                      controller: proposedPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Your Counter Price (\$)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        // In a real app, we'd use a proper numeric formatter
                        // FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                  ],
                  
                  // Message input field
                  TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      labelText: 'Message (Optional)',
                      border: OutlineInputBorder(),
                      hintText: 'Add any additional details...',
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
                if (!isCounterOffer) ...[
                  OutlinedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _submitNegotiationResponse(
                        booking,
                        'reject',
                        null,
                        messageController.text.trim(),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      side: BorderSide(color: AppTheme.errorColor),
                    ),
                    child: const Text('Reject'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _submitNegotiationResponse(
                        booking,
                        'accept',
                        null,
                        messageController.text.trim(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                    ),
                    child: const Text('Accept'),
                  ),
                ] else ...[
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
                      
                      await _submitNegotiationResponse(
                        booking,
                        'counter',
                        proposedPrice,
                        messageController.text.trim(),
                      );
                    },
                    style: AppTheme.secondaryButtonStyle,
                    child: const Text('Submit Counter Offer'),
                  ),
                ],
              ],
            );
          }
        );
      },
    );
  }
  
  Future<void> _submitNegotiationResponse(
    Booking booking,
    String action,
    double? proposedPrice,
    String? message,
  ) async {
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
          const Text('Processing your response...'),
        ],
      ),
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(loadingSnackBar);
    
    try {
      // Make the API call to submit the negotiation response
      final token = await _authService.getToken();
      final bookingService = BookingService(authToken: token);
      final result = await bookingService.respondToNegotiation(
        bookingId: booking.id,
        action: action,
        proposedPrice: proposedPrice,
        message: message,
      );
      
      // Add a small delay for better UX
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Refresh the bookings list
      await _loadBookings();
      
      // Show success or error message
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Response submitted successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        throw Exception(result['message'] ?? 'Failed to submit response');
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
  }
}