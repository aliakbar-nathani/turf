import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/turf_service.dart';
import '../../widgets/custom_textfield.dart';
import '../../models/turf_model.dart';

class OwnerAddTurfScreen extends StatefulWidget {
  final Turf? turf; // Optional turf for editing mode
  
  const OwnerAddTurfScreen({super.key, this.turf});

  @override
  State<OwnerAddTurfScreen> createState() => _OwnerAddTurfScreenState();
}

class _OwnerAddTurfScreenState extends State<OwnerAddTurfScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _basePriceController = TextEditingController();
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
  String _surfaceType = 'grass';
  
  bool _isLoading = false;
  bool _isEditMode = false;
  
  // Surface type options
  final List<Map<String, dynamic>> _surfaceTypes = [
    {'value': 'grass', 'label': 'Grass'},
    {'value': 'artificial', 'label': 'Artificial Turf'},
    {'value': 'indoor', 'label': 'Indoor'},
    {'value': 'clay', 'label': 'Clay'},
    {'value': 'concrete', 'label': 'Concrete'},
    {'value': 'other', 'label': 'Other'},
  ];
  
  @override
  void initState() {
    super.initState();
    _isEditMode = widget.turf != null;
    if (_isEditMode) {
      _populateFormWithTurfData();
    }
  }
  
  void _populateFormWithTurfData() {
    final turf = widget.turf!;
    _nameController.text = turf.name;
    _descriptionController.text = turf.description ?? '';
    _addressController.text = turf.address;
    _cityController.text = turf.city;
    _stateController.text = turf.state;
    _countryController.text = turf.country;
    _postalCodeController.text = turf.postalCode;
    _basePriceController.text = turf.basePricePerHour.toString();
    _featuresController.text = turf.features?.join(', ') ?? '';
    _sizeController.text = turf.size ?? '';
    _imageUrlController.text = turf.imageUrl ?? '';
    _additionalImagesController.text = turf.additionalImages?.join(', ') ?? '';
    
    setState(() {
      _indoor = turf.indoor ?? false;
      _hasParking = turf.hasParking ?? false;
      _hasChangingRoom = turf.hasChangingRoom ?? false;
      _hasShower = turf.hasShower ?? false;
      _hasFloodlights = turf.hasFloodlights ?? false;
      _hasEquipment = turf.hasEquipment ?? false;
      _surfaceType = turf.surfaceType ?? 'grass';
    });
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
    _basePriceController.dispose();
    _featuresController.dispose();
    _sizeController.dispose();
    _imageUrlController.dispose();
    _additionalImagesController.dispose();
    super.dispose();
  }
  
  Future<void> _saveTurf() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final turfService = TurfService();
      final turfData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'address': _addressController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'country': _countryController.text,
        'postal_code': _postalCodeController.text,
        'base_price_per_hour': double.parse(_basePriceController.text),
        'features': _featuresController.text,
        'size': _sizeController.text,
        'indoor': _indoor,
        'has_parking': _hasParking,
        'has_changing_room': _hasChangingRoom,
        'has_shower': _hasShower,
        'has_floodlights': _hasFloodlights,
        'has_equipment': _hasEquipment,
        'surface_type': _surfaceType,
        'image_url': _imageUrlController.text,
        'additional_images': _additionalImagesController.text,
      };
      
      final result = _isEditMode
          ? await turfService.updateTurf(widget.turf!.id, turfData)
          : await turfService.createTurf(turfData);
      
      setState(() {
        _isLoading = false;
      });
      
      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
          Navigator.pop(context, result['turf']);
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Turf' : 'Add New Turf'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Basic Information Section
                    const Text(
                      'Basic Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _nameController,
                      label: 'Turf Name',
                      hint: 'Enter turf name',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a turf name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      hint: 'Enter turf description',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _basePriceController,
                      label: 'Base Price per Hour',
                      hint: 'Enter base price per hour',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a base price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _sizeController,
                      label: 'Size (e.g., 5-a-side)',
                      hint: 'Enter turf size',
                    ),
                    
                    const SizedBox(height: 24),
                    // Location Section
                    const Text(
                      'Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _addressController,
                      label: 'Address',
                      hint: 'Enter turf address',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _cityController,
                      label: 'City',
                      hint: 'Enter city',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a city';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _stateController,
                      label: 'State/Province',
                      hint: 'Enter state or province',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a state or province';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _countryController,
                      label: 'Country',
                      hint: 'Enter country',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a country';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _postalCodeController,
                      label: 'Postal Code',
                      hint: 'Enter postal code',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a postal code';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    // Features Section
                    const Text(
                      'Features',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Indoor/Outdoor Switch
                    SwitchListTile(
                      title: const Text('Indoor Turf'),
                      value: _indoor,
                      onChanged: (value) {
                        setState(() {
                          _indoor = value;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                    
                    // Surface Type Dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Surface Type',
                        border: OutlineInputBorder(),
                      ),
                      value: _surfaceType,
                      items: _surfaceTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type['value'],
                          child: Text(type['label']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _surfaceType = value!;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    // Feature checkboxes
                    CheckboxListTile(
                      title: const Text('Parking Available'),
                      value: _hasParking,
                      onChanged: (value) {
                        setState(() {
                          _hasParking = value!;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                    CheckboxListTile(
                      title: const Text('Changing Rooms'),
                      value: _hasChangingRoom,
                      onChanged: (value) {
                        setState(() {
                          _hasChangingRoom = value!;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                    CheckboxListTile(
                      title: const Text('Showers'),
                      value: _hasShower,
                      onChanged: (value) {
                        setState(() {
                          _hasShower = value!;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                    CheckboxListTile(
                      title: const Text('Floodlights'),
                      value: _hasFloodlights,
                      onChanged: (value) {
                        setState(() {
                          _hasFloodlights = value!;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                    CheckboxListTile(
                      title: const Text('Equipment Available'),
                      value: _hasEquipment,
                      onChanged: (value) {
                        setState(() {
                          _hasEquipment = value!;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                    
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _featuresController,
                      label: 'Additional Features (comma-separated)',
                      hint: 'E.g., Cafe, Pro shop, Fan zone',
                    ),
                    
                    const SizedBox(height: 24),
                    // Images Section
                    const Text(
                      'Images',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _imageUrlController,
                      label: 'Primary Image URL',
                      hint: 'Enter primary image URL',
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _additionalImagesController,
                      label: 'Additional Image URLs (comma-separated)',
                      hint: 'Enter additional image URLs separated by commas',
                      maxLines: 3,
                    ),
                    
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saveTurf,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_isEditMode ? 'Update Turf' : 'Add Turf'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}