import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../config/app_theme.dart';
import '../../models/turf_model.dart';
import '../../services/booking_service.dart';
import '../../services/turf_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_indicator.dart';

class OwnerCreateBookingScreen extends StatefulWidget {
  final int? initialTurfId;

  const OwnerCreateBookingScreen({Key? key, this.initialTurfId}) : super(key: key);

  @override
  _OwnerCreateBookingScreenState createState() => _OwnerCreateBookingScreenState();
}

class _OwnerCreateBookingScreenState extends State<OwnerCreateBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TurfService _turfService = TurfService();
  final BookingService _bookingService = BookingService();
  
  List<Turf> _turfs = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  
  // Form fields
  int? _selectedTurfId;
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _paymentMethod = 'pay_on_arrival';
  
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    _loadOwnerTurfs();
    if (widget.initialTurfId != null) {
      _selectedTurfId = widget.initialTurfId;
    }
    
    // Initialize date to today
    _selectedDate = DateTime.now();
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _dateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _priceController.dispose();
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
          _turfs = result['turfs'];
          if (_turfs.isNotEmpty && _selectedTurfId == null) {
            _selectedTurfId = _turfs.first.id;
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load turfs';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime 
          ? _startTime ?? TimeOfDay(hour: 9, minute: 0)
          : _endTime ?? TimeOfDay(hour: 10, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          _startTimeController.text = _formatTimeOfDay(picked);
          
          // If end time is not set or is before start time, set it to start time + 1 hour
          if (_endTime == null || 
              (_endTime!.hour < picked.hour || 
              (_endTime!.hour == picked.hour && _endTime!.minute <= picked.minute))) {
            final endHour = (picked.hour + 1) % 24;
            _endTime = TimeOfDay(hour: endHour, minute: picked.minute);
            _endTimeController.text = _formatTimeOfDay(_endTime!);
          }
        } else {
          _endTime = picked;
          _endTimeController.text = _formatTimeOfDay(picked);
        }
        
        // Calculate price if both times are set
        if (_startTime != null && _endTime != null && _selectedTurfId != null) {
          _calculatePrice();
        }
      });
    }
  }
  
  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final hours = timeOfDay.hour.toString().padLeft(2, '0');
    final minutes = timeOfDay.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
  
  void _calculatePrice() {
    // Find the selected turf
    final selectedTurf = _turfs.firstWhere(
      (turf) => turf.id == _selectedTurfId,
      orElse: () => Turf(
        id: 0, 
        name: '', 
        basePricePerHour: 0,
        city: '',
        address: '',
      ),
    );
    
    if (selectedTurf.id == 0 || _startTime == null || _endTime == null) {
      return;
    }
    
    // Calculate duration in hours
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    
    // Handle cases where end time is on the next day
    final durationMinutes = endMinutes > startMinutes 
        ? endMinutes - startMinutes
        : (24 * 60 - startMinutes) + endMinutes;
    
    final durationHours = durationMinutes / 60;
    
    // Calculate price
    final price = selectedTurf.basePricePerHour * durationHours;
    
    setState(() {
      _priceController.text = price.toStringAsFixed(2);
    });
  }
  
  Future<void> _createBooking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    
    try {
      final bookingData = {
        'turf_id': _selectedTurfId,
        'customer_name': _customerNameController.text,
        'customer_phone': _customerPhoneController.text,
        'booking_date': _dateController.text,
        'start_time': _startTimeController.text,
        'end_time': _endTimeController.text,
        'total_price': double.parse(_priceController.text),
        'payment_method': _paymentMethod,
        'notes': _notesController.text,
      };
      
      final result = await _bookingService.createOwnerBooking(bookingData);
      
      setState(() {
        _isSubmitting = false;
      });
      
      if (result['success']) {
        // Show success message and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking created successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context, true);
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to create booking';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Direct Booking'),
        elevation: 0,
      ),
      body: _isLoading 
          ? Center(child: LoadingIndicator())
          : _buildForm(),
    );
  }
  
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null)
              Container(
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),
              
            // Turf selection dropdown
            DropdownButtonFormField<int>(
              decoration: InputDecoration(
                labelText: 'Select Turf',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sports_soccer),
              ),
              value: _selectedTurfId,
              validator: (value) => value == null ? 'Please select a turf' : null,
              items: _turfs.map((turf) {
                return DropdownMenuItem(
                  value: turf.id,
                  child: Text(turf.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTurfId = value;
                  // Recalculate price if times are set
                  if (_startTime != null && _endTime != null) {
                    _calculatePrice();
                  }
                });
              },
            ),
            SizedBox(height: 16),
            
            // Customer information
            CustomTextField(
              controller: _customerNameController,
              label: 'Customer Name',
              prefixIcon: Icons.person,
              validator: (value) => value!.isEmpty ? 'Please enter customer name' : null,
            ),
            SizedBox(height: 16),
            
            CustomTextField(
              controller: _customerPhoneController,
              label: 'Customer Phone',
              prefixIcon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (value) => value!.isEmpty ? 'Please enter customer phone' : null,
            ),
            SizedBox(height: 16),
            
            // Date and time
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: CustomTextField(
                  controller: _dateController,
                  label: 'Booking Date',
                  prefixIcon: Icons.calendar_today,
                  validator: (value) => value!.isEmpty ? 'Please select a date' : null,
                ),
              ),
            ),
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectTime(context, true),
                    child: AbsorbPointer(
                      child: CustomTextField(
                        controller: _startTimeController,
                        label: 'Start Time',
                        prefixIcon: Icons.access_time,
                        validator: (value) => value!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectTime(context, false),
                    child: AbsorbPointer(
                      child: CustomTextField(
                        controller: _endTimeController,
                        label: 'End Time',
                        prefixIcon: Icons.access_time,
                        validator: (value) => value!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Price
            CustomTextField(
              controller: _priceController,
              label: 'Total Price',
              prefixIcon: Icons.attach_money,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter a price';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                if (double.parse(value) <= 0) {
                  return 'Price must be greater than zero';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            
            // Payment method
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Method',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: Text('Pay on Arrival'),
                          value: 'pay_on_arrival',
                          groupValue: _paymentMethod,
                          onChanged: (value) {
                            setState(() {
                              _paymentMethod = value!;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: Text('Already Paid'),
                          value: 'already_paid',
                          groupValue: _paymentMethod,
                          onChanged: (value) {
                            setState(() {
                              _paymentMethod = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            
            // Notes
            CustomTextField(
              controller: _notesController,
              label: 'Notes (Optional)',
              prefixIcon: Icons.note,
              maxLines: 3,
            ),
            SizedBox(height: 24),
            
            // Submit button
            CustomButton(
              text: 'Create Booking',
              isLoading: _isSubmitting,
              onPressed: _createBooking,
            ),
          ],
        ),
      ),
    );
  }
}