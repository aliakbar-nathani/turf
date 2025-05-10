import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/turf_model.dart';
import '../../services/turf_service.dart';
import '../../services/booking_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_indicator.dart';

class OwnerCreateBookingScreen extends StatefulWidget {
  const OwnerCreateBookingScreen({Key? key}) : super(key: key);

  @override
  State<OwnerCreateBookingScreen> createState() => _OwnerCreateBookingScreenState();
}

class _OwnerCreateBookingScreenState extends State<OwnerCreateBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _bookingDateController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _totalPriceController = TextEditingController();
  final _notesController = TextEditingController();
  
  // Services
  final _turfService = TurfService();
  final _bookingService = BookingService();
  
  // State variables
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<Turf> _ownerTurfs = [];
  String? _errorMessage;
  Turf? _selectedTurf;
  String _paymentMethod = 'pay_on_arrival';

  @override
  void initState() {
    super.initState();
    _loadOwnerTurfs();
    
    // Set default date to today
    _bookingDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }
  
  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _bookingDateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _totalPriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _loadOwnerTurfs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final result = await _turfService.getOwnerTurfs();
      
      if (result['success']) {
        setState(() {
          _ownerTurfs = result['turfs'];
          _isLoading = false;
          
          // Select first turf by default if available
          if (_ownerTurfs.isNotEmpty) {
            _selectedTurf = _ownerTurfs.first;
            
            // Pre-fill price with turf's base price
            _totalPriceController.text = _selectedTurf!.basePricePerHour.toString();
          }
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result['message'] ?? 'Failed to load turfs';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    
    if (picked != null) {
      setState(() {
        _bookingDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }
  
  Future<void> _selectTime(BuildContext context, TextEditingController controller, {TimeOfDay? initialTime}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
    );
    
    if (picked != null) {
      setState(() {
        controller.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }
  
  Future<void> _createBooking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedTurf == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a turf')),
      );
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      final bookingData = {
        'turf_id': _selectedTurf!.id,
        'customer_name': _customerNameController.text,
        'customer_phone': _customerPhoneController.text,
        'booking_date': _bookingDateController.text,
        'start_time': _startTimeController.text,
        'end_time': _endTimeController.text,
        'total_price': double.parse(_totalPriceController.text),
        'payment_method': _paymentMethod,
        'notes': _notesController.text,
      };
      
      final result = await _bookingService.createOwnerBooking(bookingData);
      
      setState(() {
        _isSubmitting = false;
      });
      
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Booking created successfully')),
        );
        
        // Show success dialog
        _showSuccessDialog(result['booking']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to create booking')),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  
  void _showSuccessDialog(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Booking Created'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Booking for ${booking['turf_name']} created successfully'),
            const SizedBox(height: 8),
            Text('Date: ${booking['booking_date']}'),
            Text('Time: ${booking['time_slot']}'),
            Text('Customer: ${booking['customer_name']}'),
            Text('Payment: ${booking['payment_method'] == 'pay_on_arrival' ? 'Pay on Arrival' : 'Paid Online'}'),
            Text('Amount: \$${booking['total_price']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to previous screen
            },
            child: const Text('Done'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Clear form to create another booking
              _resetForm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create Another'),
          ),
        ],
      ),
    );
  }
  
  void _resetForm() {
    _customerNameController.clear();
    _customerPhoneController.clear();
    _startTimeController.clear();
    _endTimeController.clear();
    _notesController.clear();
    
    // Reset to default values
    _bookingDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (_selectedTurf != null) {
      _totalPriceController.text = _selectedTurf!.basePricePerHour.toString();
    }
    _paymentMethod = 'pay_on_arrival';
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Direct Booking'),
      ),
      body: _isLoading 
          ? const Center(child: LoadingIndicator(message: 'Loading turfs...'))
          : _errorMessage != null
              ? _buildErrorView()
              : _buildForm(),
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
            CustomButton(
              text: 'Retry',
              onPressed: _loadOwnerTurfs,
              color: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_ownerTurfs.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'You don\'t have any turfs. Please add a turf first.',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )
          else
            ...[
              _buildTurfSelector(),
              const SizedBox(height: 20),
              _buildCustomerSection(),
              const SizedBox(height: 20),
              _buildBookingDetailsSection(),
              const SizedBox(height: 20),
              _buildPaymentSection(),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Create Booking',
                onPressed: _createBooking,
                isLoading: _isSubmitting,
                color: AppTheme.primaryColor,
                icon: Icons.check_circle,
                width: double.infinity,
              ),
            ],
        ],
      ),
    );
  }
  
  Widget _buildTurfSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Turf',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Turf>(
              decoration: const InputDecoration(
                labelText: 'Turf',
                border: OutlineInputBorder(),
              ),
              value: _selectedTurf,
              items: _ownerTurfs.map((turf) {
                return DropdownMenuItem<Turf>(
                  value: turf,
                  child: Text(turf.name),
                );
              }).toList(),
              onChanged: (Turf? value) {
                setState(() {
                  _selectedTurf = value;
                  if (_selectedTurf != null) {
                    _totalPriceController.text = _selectedTurf!.basePricePerHour.toString();
                  }
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a turf';
                }
                return null;
              },
            ),
            if (_selectedTurf != null) ...[
              const SizedBox(height: 8),
              Text(
                'Location: ${_selectedTurf!.address}, ${_selectedTurf!.city}',
                style: const TextStyle(color: Colors.grey),
              ),
              Text(
                'Base Price: \$${_selectedTurf!.basePricePerHour}/hour',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildCustomerSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _customerNameController,
              label: 'Customer Name',
              prefixIcon: Icons.person,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter customer name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _customerPhoneController,
              label: 'Customer Phone',
              prefixIcon: Icons.phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter customer phone';
                }
                if (value.length < 10) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBookingDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Booking Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _bookingDateController,
              label: 'Booking Date',
              prefixIcon: Icons.calendar_today,
              readOnly: true,
              onTap: () => _selectDate(context),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select booking date';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _startTimeController,
                    label: 'Start Time',
                    prefixIcon: Icons.access_time,
                    readOnly: true,
                    onTap: () => _selectTime(context, _startTimeController),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select start time';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _endTimeController,
                    label: 'End Time',
                    prefixIcon: Icons.access_time,
                    readOnly: true,
                    onTap: () {
                      // Use start time as initial time if set
                      TimeOfDay? initialTime;
                      if (_startTimeController.text.isNotEmpty) {
                        final parts = _startTimeController.text.split(':');
                        initialTime = TimeOfDay(
                          hour: int.parse(parts[0]),
                          minute: int.parse(parts[1]),
                        );
                      }
                      _selectTime(context, _endTimeController, initialTime: initialTime);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select end time';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _totalPriceController,
              label: 'Total Price (\$)',
              prefixIcon: Icons.attach_money,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter total price';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid price';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _notesController,
              label: 'Notes (Optional)',
              prefixIcon: Icons.note,
              maxLines: 3,
              minLines: 1,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPaymentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            RadioListTile<String>(
              title: const Text('Pay on Arrival'),
              value: 'pay_on_arrival',
              groupValue: _paymentMethod,
              onChanged: (value) {
                setState(() {
                  _paymentMethod = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('Already Paid (Cash/Transfer)'),
              value: 'paid_offline',
              groupValue: _paymentMethod,
              onChanged: (value) {
                setState(() {
                  _paymentMethod = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}