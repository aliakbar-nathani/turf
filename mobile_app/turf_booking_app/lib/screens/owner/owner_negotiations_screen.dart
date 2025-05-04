import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../config/app_theme.dart';
import '../../models/negotiation_model.dart';
import '../../services/booking_service.dart';
import '../../services/auth_service.dart';

class OwnerNegotiationsScreen extends StatefulWidget {
  const OwnerNegotiationsScreen({super.key});

  @override
  State<OwnerNegotiationsScreen> createState() => _OwnerNegotiationsScreenState();
}

class _OwnerNegotiationsScreenState extends State<OwnerNegotiationsScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late BookingService _bookingService;
  
  bool _isLoading = true;
  String? _errorMessage;
  List<Negotiation> _pendingNegotiations = [];
  List<Negotiation> _completedNegotiations = [];
  
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initialize();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _initialize() async {
    final token = await _authService.getToken();
    setState(() {
      _bookingService = BookingService(authToken: token);
    });
    
    _loadNegotiations();
  }
  
  Future<void> _loadNegotiations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Get owner's negotiations
      final result = await _bookingService.getOwnerNegotiations();
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        
        if (result['success']) {
          final allNegotiations = result['negotiations'] as List<Negotiation>;
          
          // Filter negotiations by status
          _pendingNegotiations = allNegotiations.where((n) => 
              n.status == 'pending' || n.status == 'counter_offered').toList();
          
          _completedNegotiations = allNegotiations.where((n) => 
              n.status == 'accepted' || n.status == 'rejected').toList();
        } else {
          _errorMessage = result['message'] ?? 'Failed to load negotiations';
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
  
  void _showNegotiationActionDialog(Negotiation negotiation) {
    final priceController = TextEditingController(
      text: negotiation.currentAmount.toString()
    );
    final messageController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Respond to Negotiation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Booking #${negotiation.bookingId} - ${negotiation.turfName}',
                style: const TextStyle(fontSize: 14.0),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              Text(
                'Customer: ${negotiation.userName}',
                style: const TextStyle(fontSize: 14.0),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Original Price:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    '\$${negotiation.originalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Customer\'s Offer:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    '\$${negotiation.currentAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: negotiation.currentAmount < negotiation.originalAmount 
                          ? Colors.red 
                          : Colors.green,
                    ),
                  ),
                ],
              ),
              if (negotiation.message != null && negotiation.message!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Customer Message:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(negotiation.message!),
                ),
              ],
              const SizedBox(height: 24),
              
              const Text(
                'Your Response:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              // Counter price input field
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Your Counter Price (\$)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              
              const SizedBox(height: 12),
              
              // Message input field
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message to Customer (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Explain your response...',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            // Reject button
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _respondToNegotiation(negotiation.id, 'reject', null, messageController.text);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Reject Offer'),
            ),
            // Accept button
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _respondToNegotiation(negotiation.id, 'accept', null, messageController.text);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
              ),
              child: const Text('Accept Offer'),
            ),
            // Counter offer button
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                
                // Validate input
                double? counterPrice;
                try {
                  counterPrice = double.parse(priceController.text);
                  if (counterPrice <= 0) {
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
                
                _respondToNegotiation(
                  negotiation.id, 
                  'counter', 
                  counterPrice, 
                  messageController.text
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryColor,
              ),
              child: const Text('Counter Offer'),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _respondToNegotiation(
    int negotiationId, 
    String action, 
    double? counterPrice, 
    String message
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
      // Make the API call to respond to the negotiation
      final result = await _bookingService.respondToNegotiationAsOwner(
        negotiationId: negotiationId,
        action: action,
        proposedPrice: counterPrice,
        message: message.trim().isNotEmpty ? message.trim() : null,
      );
      
      // Add a small delay for better UX
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Refresh the negotiations list
      await _loadNegotiations();
      
      // Show success message
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Your response has been sent'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        throw Exception(result['message'] ?? 'Failed to respond to negotiation');
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Price Negotiations'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          indicatorColor: Colors.white,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNegotiations,
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
                        onPressed: _loadNegotiations,
                        style: AppTheme.primaryButtonStyle,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildNegotiationList(_pendingNegotiations, true),
                    _buildNegotiationList(_completedNegotiations, false),
                  ],
                ),
    );
  }
  
  Widget _buildNegotiationList(List<Negotiation> negotiations, bool isActionable) {
    if (negotiations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActionable ? Icons.handshake : Icons.history,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              isActionable 
                  ? 'No pending negotiations' 
                  : 'No completed negotiations',
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
      onRefresh: _loadNegotiations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: negotiations.length,
        itemBuilder: (context, index) {
          final negotiation = negotiations[index];
          return _buildNegotiationCard(negotiation, isActionable);
        },
      ),
    );
  }
  
  Widget _buildNegotiationCard(Negotiation negotiation, bool isActionable) {
    final priceChange = negotiation.currentAmount - negotiation.originalAmount;
    final priceChangePercentage = (priceChange / negotiation.originalAmount) * 100;
    final isPriceIncrease = priceChange >= 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Negotiation header with booking ID and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Booking #${negotiation.bookingId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
                _buildStatusChip(negotiation.status),
              ],
            ),
            const SizedBox(height: 12.0),
            
            // Turf name and customer
            Text(
              'Turf: ${negotiation.turfName}',
              style: const TextStyle(fontSize: 14.0),
            ),
            const SizedBox(height: 4.0),
            Text(
              'Customer: ${negotiation.userName}',
              style: const TextStyle(fontSize: 14.0),
            ),
            const SizedBox(height: 12.0),
            
            // Price details
            Card(
              elevation: 0,
              color: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Original Price:',
                          style: TextStyle(fontSize: 14.0),
                        ),
                        Text(
                          '\$${negotiation.originalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Current Offer:',
                          style: TextStyle(fontSize: 14.0),
                        ),
                        Row(
                          children: [
                            Text(
                              '\$${negotiation.currentAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                                color: isPriceIncrease ? Colors.green : Colors.red,
                              ),
                            ),
                            const SizedBox(width: 4.0),
                            Icon(
                              isPriceIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                              size: 14.0,
                              color: isPriceIncrease ? Colors.green : Colors.red,
                            ),
                            Text(
                              '${priceChangePercentage.abs().toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 12.0,
                                color: isPriceIncrease ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Message if any
            if (negotiation.message != null && negotiation.message!.isNotEmpty) ...[
              const SizedBox(height: 12.0),
              const Text(
                'Message:',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                negotiation.message!,
                style: const TextStyle(
                  fontSize: 14.0,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            
            // Action buttons
            if (isActionable) ...[
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _respondToNegotiation(
                      negotiation.id, 'reject', null, 'Sorry, we cannot accept this offer.'
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 8.0),
                  OutlinedButton(
                    onPressed: () => _respondToNegotiation(
                      negotiation.id, 'accept', null, 'Thank you for your business!'
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                    ),
                    child: const Text('Accept'),
                  ),
                  const SizedBox(width: 8.0),
                  ElevatedButton(
                    onPressed: () => _showNegotiationActionDialog(negotiation),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryColor,
                    ),
                    child: const Text('Respond'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    String statusText;
    
    switch (status) {
      case 'pending':
        backgroundColor = Colors.orange;
        statusText = 'Pending';
        break;
      case 'counter_offered':
        backgroundColor = Colors.blue;
        statusText = 'Counter Offered';
        break;
      case 'accepted':
        backgroundColor = Colors.green;
        statusText = 'Accepted';
        break;
      case 'rejected':
        backgroundColor = Colors.red;
        statusText = 'Rejected';
        break;
      default:
        backgroundColor = Colors.grey;
        statusText = status.replaceAll('_', ' ');
        statusText = statusText[0].toUpperCase() + statusText.substring(1);
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusText,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}