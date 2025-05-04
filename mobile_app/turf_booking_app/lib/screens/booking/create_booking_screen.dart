import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../config/app_theme.dart';
import '../../models/turf_model.dart';
import '../../services/booking_service.dart';
import '../../services/auth_service.dart';

class CreateBookingScreen extends StatefulWidget {
  final Turf turf;

  const CreateBookingScreen({super.key, required this.turf});

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _proposedPriceController = TextEditingController();
  
  String? _selectedDate;
  String? _selectedTimeSlot;
  String _paymentOption = 'pay_online';
  bool _isNegotiating = false;
  
  bool _isLoading = false;
  bool _isLoadingTimeSlots = false;
  String? _errorMessage;
  
  List<String> _availableTimeSlots = [];
  final AuthService _authService = AuthService();
  late BookingService _bookingService;
  
  @override
  void initState() {
    super.initState();
    _initialize();
    _proposedPriceController.text = widget.turf.basePricePerHour.toString();
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _proposedPriceController.dispose();
    super.dispose();
  }
  
  Future<void> _initialize() async {
    final token = await _authService.getToken();
    setState(() {
      _bookingService = BookingService(authToken: token);
    });
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      // Format date as YYYY-MM-DD
      final formattedDate = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      
      setState(() {
        _selectedDate = formattedDate;
        _selectedTimeSlot = null; // Reset time slot when date changes
      });
      
      // Load available time slots for selected date
      _loadTimeSlots(formattedDate);
    }
  }
  
  Future<void> _loadTimeSlots(String date) async {
    setState(() {
      _isLoadingTimeSlots = true;
      _availableTimeSlots = [];
    });
    
    final result = await _bookingService.getAvailableTimeSlots(widget.turf.id, date);
    
    setState(() {
      _isLoadingTimeSlots = false;
      
      if (result['success']) {
        _availableTimeSlots = List<String>.from(result['timeSlots']);
        
        if (_availableTimeSlots.isEmpty) {
          _errorMessage = 'No available time slots for the selected date';
        } else {
          _errorMessage = null;
        }
      } else {
        _errorMessage = result['message'];
      }
    });
  }
  
  Future<void> _createBooking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedDate == null || _selectedTimeSlot == null) {
      setState(() {
        _errorMessage = 'Please select date and time slot';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    // Handle booking based on negotiation status
    String paymentOption = '';
    double? proposedPrice;
    
    if (_isNegotiating) {
      // When negotiating, set payment_option to negotiation
      paymentOption = 'negotiation';
      proposedPrice = double.tryParse(_proposedPriceController.text);
      
      // Validate proposed price
      if (proposedPrice == null || proposedPrice <= 0) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please enter a valid price';
        });
        return;
      }
    } else {
      // When not negotiating, use selected payment option
      paymentOption = _paymentOption;
    }
    
    final result = await _bookingService.createBooking(
      turfId: widget.turf.id,
      bookingDate: _selectedDate!,
      timeSlot: _selectedTimeSlot!,
      paymentOption: paymentOption,
      proposedPrice: proposedPrice,
      message: _messageController.text.isNotEmpty ? _messageController.text : null,
    );
    
    setState(() {
      _isLoading = false;
    });
    
    if (result['success']) {
      if (!mounted) return;
      
      // Customize message based on negotiation status
      String successMessage;
      if (_isNegotiating) {
        successMessage = 'Your price offer has been submitted to the owner for review';
      } else {
        successMessage = result['message'] ?? 'Booking created successfully';
      }
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: AppTheme.successColor,
        ),
      );
      
      // Handle redirect based on booking type
      if (!_isNegotiating && 
          result.containsKey('redirectUrl') && 
          result['redirectUrl'] != null && 
          paymentOption == 'pay_online') {
        // TODO: Navigate to webview with payment URL
        // For now, just go back to the previous screen
        Navigator.pop(context);
      } else {
        // Go back to previous screen
        Navigator.pop(context);
      }
    } else {
      setState(() {
        _errorMessage = result['message'];
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Turf'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Turf info card
              Card(
                child: Padding(
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
                          child: widget.turf.imageUrl.isNotEmpty
                              ? Image.network(
                                  widget.turf.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
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
                      
                      // Turf details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.turf.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18.0,
                              ),
                            ),
                            
                            const SizedBox(height: 4.0),
                            
                            Text(
                              '${widget.turf.city}, ${widget.turf.state}',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                            
                            const SizedBox(height: 8.0),
                            
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 4.0,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryColor,
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                '\$${widget.turf.basePricePerHour.toStringAsFixed(2)}/hr',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24.0),
              
              // Date selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Date',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                  
                  const SizedBox(height: 8.0),
                  
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today),
                          const SizedBox(width: 16.0),
                          Text(
                            _selectedDate ?? 'Select a date',
                            style: TextStyle(
                              color: _selectedDate != null 
                                  ? Colors.black 
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24.0),
              
              // Time slot selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Time Slot',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                  
                  const SizedBox(height: 8.0),
                  
                  if (_selectedDate == null)
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: const Center(
                        child: Text(
                          'Please select a date first',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else if (_isLoadingTimeSlots)
                    Center(
                      child: SpinKitThreeBounce(
                        color: AppTheme.primaryColor,
                        size: 24.0,
                      ),
                    )
                  else if (_availableTimeSlots.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: const Center(
                        child: Text(
                          'No available time slots for selected date',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _availableTimeSlots.length,
                      itemBuilder: (context, index) {
                        final timeSlot = _availableTimeSlots[index];
                        final isSelected = timeSlot == _selectedTimeSlot;
                        
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedTimeSlot = timeSlot;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? AppTheme.primaryColor 
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(
                                color: isSelected 
                                    ? AppTheme.primaryColor 
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                timeSlot,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black,
                                  fontWeight: isSelected 
                                      ? FontWeight.bold 
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
              
              const SizedBox(height: 24.0),
              
              // Payment options only shown if not negotiating
              if (!_isNegotiating) Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Options',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                  
                  const SizedBox(height: 8.0),
                  
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text('Pay Online'),
                          value: 'pay_online',
                          groupValue: _paymentOption,
                          onChanged: (value) {
                            setState(() {
                              _paymentOption = value!;
                            });
                          },
                          activeColor: AppTheme.primaryColor,
                        ),
                        const Divider(height: 1),
                        RadioListTile<String>(
                          title: const Text('Pay on Arrival'),
                          value: 'pay_on_arrival',
                          groupValue: _paymentOption,
                          onChanged: (value) {
                            setState(() {
                              _paymentOption = value!;
                            });
                          },
                          activeColor: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24.0),
              
              // Negotiation toggle
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'I want to negotiate the price',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Switch(
                          value: _isNegotiating,
                          onChanged: (value) {
                            setState(() {
                              _isNegotiating = value;
                            });
                          },
                          activeColor: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                    
                    if (_isNegotiating) ...[
                      const SizedBox(height: 12.0),
                      
                      TextFormField(
                        controller: _proposedPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Your Proposed Price',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your proposed price';
                          }
                          
                          final price = double.tryParse(value);
                          if (price == null || price <= 0) {
                            return 'Please enter a valid price';
                          }
                          
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 12.0),
                      
                      TextFormField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          labelText: 'Message to Owner (Optional)',
                          hintText: 'Explain why you are proposing this price',
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 24.0),
              
              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppTheme.errorColor,
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: AppTheme.errorColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              if (_errorMessage != null) const SizedBox(height: 24.0),
              
              // Book button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createBooking,
                  style: AppTheme.primaryButtonStyle.copyWith(
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(vertical: 16.0),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isNegotiating ? 'Submit Offer' : 'Book Now',
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}