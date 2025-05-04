import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_theme.dart';
import '../../services/turf_service.dart';
import '../../services/auth_service.dart';
import '../../models/turf_model.dart';

class OwnerAddTurfScreen extends StatefulWidget {
  const OwnerAddTurfScreen({super.key});

  @override
  State<OwnerAddTurfScreen> createState() => _OwnerAddTurfScreenState();
}

class _OwnerAddTurfScreenState extends State<OwnerAddTurfScreen> {
  final AuthService _authService = AuthService();
  late TurfService _turfService;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Text controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _priceController = TextEditingController();
  final _featuresController = TextEditingController();
  final _sizeController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _additionalImagesController = TextEditingController();
  
  // Form values
  bool _indoor = false;
  bool _hasParking = false;
  bool _hasChangingRoom = false;
  bool _hasShower = false;
  bool _hasFloodlights = false;
  bool _hasEquipment = false;
  String _surfaceType = 'artificial';
  
  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _postalCodeController.dispose();
    _priceController.dispose();
    _featuresController.dispose();
    _sizeController.dispose();
    _imageUrlController.dispose();
    _additionalImagesController.dispose();
    super.dispose();
  }
  
  Future<void> _initialize() async {
    final token = await _authService.getToken();
    setState(() {
      _turfService = TurfService(authToken: token);
    });
  }
  
  Future<void> _saveTurf() async {
    if (!_formKey.currentState!.validate()) {
      // Show error if validation fails
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the errors in the form'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Prepare the turf data
      final turfData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'country': _countryController.text.trim(),
        'postal_code': _postalCodeController.text.trim(),
        'base_price_per_hour': double.parse(_priceController.text.trim()),
        'features': _featuresController.text.trim(),
        'size': _sizeController.text.trim(),
        'indoor': _indoor,
        'has_parking': _hasParking,
        'has_changing_room': _hasChangingRoom,
        'has_shower': _hasShower,
        'has_floodlights': _hasFloodlights,
        'has_equipment': _hasEquipment,
        'surface_type': _surfaceType,
        'image_url': _imageUrlController.text.trim(),
        'additional_images': _additionalImagesController.text.trim(),
      };
      
      // Save the turf
      final result = await _turfService.createTurf(turfData);
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      if (result['success']) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Turf added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back to previous screen
        Navigator.pop(context);
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to add turf'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Turf'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Basic Information',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    
                    // Name field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Turf Name *',
                        hintText: 'Enter turf name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Turf name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    
                    // Description field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter turf description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16.0),
                    
                    // Price field
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Base Price per Hour ($) *',
                        hintText: 'Example: 50.00',
                        border: OutlineInputBorder(),
                        prefixText: '\$ ',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Price is required';
                        }
                        try {
                          final price = double.parse(value);
                          if (price <= 0) {
                            return 'Price must be greater than zero';
                          }
                        } catch (e) {
                          return 'Please enter a valid price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24.0),
                    
                    const Text(
                      'Location Details',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    
                    // Address field
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address *',
                        hintText: 'Enter turf address',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Address is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    
                    // City field
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City *',
                        hintText: 'Enter city',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'City is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    
                    // Two column layout for state and postal code
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _stateController,
                            decoration: const InputDecoration(
                              labelText: 'State/Province *',
                              hintText: 'Enter state',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'State is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: TextFormField(
                            controller: _postalCodeController,
                            decoration: const InputDecoration(
                              labelText: 'Postal Code *',
                              hintText: 'Enter postal code',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Postal code is required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    
                    // Country field
                    TextFormField(
                      controller: _countryController,
                      decoration: const InputDecoration(
                        labelText: 'Country *',
                        hintText: 'Enter country',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Country is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24.0),
                    
                    const Text(
                      'Turf Specifications',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    
                    // Size field
                    TextFormField(
                      controller: _sizeController,
                      decoration: const InputDecoration(
                        labelText: 'Size (e.g., 5-a-side, 11-a-side)',
                        hintText: 'Enter turf size',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    
                    // Features field
                    TextFormField(
                      controller: _featuresController,
                      decoration: const InputDecoration(
                        labelText: 'Features (comma-separated)',
                        hintText: 'Example: WiFi, Scoreboards, Seating',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    
                    // Surface type dropdown
                    DropdownButtonFormField<String>(
                      value: _surfaceType,
                      decoration: const InputDecoration(
                        labelText: 'Surface Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'grass',
                          child: Text('Grass'),
                        ),
                        DropdownMenuItem(
                          value: 'artificial',
                          child: Text('Artificial Turf'),
                        ),
                        DropdownMenuItem(
                          value: 'indoor',
                          child: Text('Indoor'),
                        ),
                        DropdownMenuItem(
                          value: 'clay',
                          child: Text('Clay'),
                        ),
                        DropdownMenuItem(
                          value: 'concrete',
                          child: Text('Concrete'),
                        ),
                        DropdownMenuItem(
                          value: 'other',
                          child: Text('Other'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _surfaceType = value ?? 'artificial';
                        });
                      },
                    ),
                    const SizedBox(height: 16.0),
                    
                    // Amenities checkboxes
                    const Text(
                      'Amenities',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    CheckboxListTile(
                      title: const Text('Indoor Turf'),
                      value: _indoor,
                      onChanged: (value) {
                        setState(() {
                          _indoor = value ?? false;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      title: const Text('Parking Available'),
                      value: _hasParking,
                      onChanged: (value) {
                        setState(() {
                          _hasParking = value ?? false;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      title: const Text('Changing Rooms'),
                      value: _hasChangingRoom,
                      onChanged: (value) {
                        setState(() {
                          _hasChangingRoom = value ?? false;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      title: const Text('Showers'),
                      value: _hasShower,
                      onChanged: (value) {
                        setState(() {
                          _hasShower = value ?? false;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      title: const Text('Floodlights'),
                      value: _hasFloodlights,
                      onChanged: (value) {
                        setState(() {
                          _hasFloodlights = value ?? false;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      title: const Text('Equipment Available'),
                      value: _hasEquipment,
                      onChanged: (value) {
                        setState(() {
                          _hasEquipment = value ?? false;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 24.0),
                    
                    const Text(
                      'Images',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    
                    // Image URL field
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Primary Image URL',
                        hintText: 'Enter URL for main turf image',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    
                    // Additional images field
                    TextFormField(
                      controller: _additionalImagesController,
                      decoration: const InputDecoration(
                        labelText: 'Additional Image URLs (comma-separated)',
                        hintText: 'Enter URLs for additional images',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 32.0),
                    
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveTurf,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                        ),
                        child: const Text(
                          'Add Turf',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24.0),
                  ],
                ),
              ),
            ),
    );
  }
}