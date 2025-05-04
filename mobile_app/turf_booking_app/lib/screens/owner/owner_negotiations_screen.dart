import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/booking_service.dart';
import '../../services/auth_service.dart';
import '../../models/negotiation_model.dart';

class OwnerNegotiationsScreen extends StatefulWidget {
  const OwnerNegotiationsScreen({super.key});

  @override
  State<OwnerNegotiationsScreen> createState() => _OwnerNegotiationsScreenState();
}

class _OwnerNegotiationsScreenState extends State<OwnerNegotiationsScreen> {
  bool _isLoading = true;
  List<Negotiation> _negotiations = [];
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadNegotiations();
  }
  
  Future<void> _loadNegotiations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final authService = AuthService();
      final token = await authService.getToken();
      
      final bookingService = BookingService(authToken: token);
      final result = await bookingService.getOwnerNegotiations();
      
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _negotiations = result['negotiations'];
        } else {
          _errorMessage = result['message'];
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load negotiations: $e';
      });
    }
  }
  
  Future<void> _respondToNegotiation(Negotiation negotiation, String action) async {
    final priceController = TextEditingController();
    final messageController = TextEditingController();
    
    if (action == 'counter') {
      // Show dialog to enter counter offer
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Counter Offer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Original Price: \$${negotiation.originalAmount.toStringAsFixed(2)}'),
              Text('Current Offer: \$${negotiation.currentAmount.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Your Counter Offer',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message (optional)',
                  border: OutlineInputBorder(),
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
              onPressed: () {
                Navigator.pop(context, {
                  'price': double.tryParse(priceController.text),
                  'message': messageController.text,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Submit Counter Offer'),
            ),
          ],
        ),
      ).then((result) async {
        if (result != null) {
          await _submitResponse(
            negotiation.id,
            action,
            result['price'],
            result['message'],
          );
        }
      });
    } else if (action == 'accept' || action == 'reject') {
      // Show confirmation dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${action == 'accept' ? 'Accept' : 'Reject'} Negotiation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                action == 'accept'
                    ? 'Are you sure you want to accept the offer of \$${negotiation.currentAmount.toStringAsFixed(2)}?'
                    : 'Are you sure you want to reject this offer?',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message (optional)',
                  border: OutlineInputBorder(),
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
              onPressed: () {
                Navigator.pop(context, {
                  'message': messageController.text,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: action == 'accept'
                    ? Colors.green
                    : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(action == 'accept' ? 'Accept' : 'Reject'),
            ),
          ],
        ),
      ).then((result) async {
        if (result != null) {
          await _submitResponse(
            negotiation.id,
            action,
            null,
            result['message'],
          );
        }
      });
    }
  }
  
  Future<void> _submitResponse(
    int negotiationId,
    String action,
    double? proposedPrice,
    String? message,
  ) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = AuthService();
      final token = await authService.getToken();
      
      final bookingService = BookingService(authToken: token);
      final result = await bookingService.respondToNegotiationAsOwner(
        negotiationId: negotiationId,
        action: action,
        proposedPrice: proposedPrice,
        message: message,
      );
      
      setState(() {
        _isLoading = false;
      });
      
      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
          _loadNegotiations(); // Reload the list
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
  
  String _formatStatus(String status) {
    return status.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'counter_offered':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Price Negotiations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNegotiations,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadNegotiations,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _negotiations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.handshake,
                            size: 80,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No negotiations yet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'When users request price negotiations, they will appear here',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _negotiations.length,
                      itemBuilder: (context, index) {
                        final negotiation = _negotiations[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        negotiation.turfName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(negotiation.status).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _getStatusColor(negotiation.status),
                                        ),
                                      ),
                                      child: Text(
                                        _formatStatus(negotiation.status),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _getStatusColor(negotiation.status),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'From: ${negotiation.userName}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Text(
                                      'Original Price:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '\$${negotiation.originalAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Text(
                                      'Proposed Price:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '\$${negotiation.currentAmount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: negotiation.currentAmount < negotiation.originalAmount
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                    ),
                                    Text(
                                      ' (${((negotiation.currentAmount - negotiation.originalAmount) / negotiation.originalAmount * 100).toStringAsFixed(1)}%)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: negotiation.currentAmount < negotiation.originalAmount
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                if (negotiation.message != null && negotiation.message!.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Message:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(negotiation.message!),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                Text(
                                  'Requested: ${_formatDate(negotiation.createdAt)}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                if (negotiation.updatedAt != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Last updated: ${_formatDate(negotiation.updatedAt!)}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                                
                                if (negotiation.status == 'pending') ...[
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () => _respondToNegotiation(negotiation, 'accept'),
                                        icon: const Icon(Icons.check),
                                        label: const Text('Accept'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () => _respondToNegotiation(negotiation, 'counter'),
                                        icon: const Icon(Icons.swap_horiz),
                                        label: const Text('Counter'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () => _respondToNegotiation(negotiation, 'reject'),
                                        icon: const Icon(Icons.close),
                                        label: const Text('Reject'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
  
  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}