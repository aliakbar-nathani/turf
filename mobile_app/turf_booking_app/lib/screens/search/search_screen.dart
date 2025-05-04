import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_theme.dart';
import '../../models/turf_model.dart';
import '../../services/turf_service.dart';
import '../../services/auth_service.dart';
import '../turf/turf_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final AuthService _authService = AuthService();
  late TurfService _turfService;
  
  final TextEditingController _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  
  bool _isLoading = false;
  String? _errorMessage;
  List<Turf> _searchResults = [];
  
  // Filter options
  String? _selectedCity;
  String? _selectedSurfaceType;
  bool? _isIndoor;
  double? _minPrice;
  double? _maxPrice;
  bool _hasParking = false;
  bool _hasChangingRoom = false;
  bool _hasShower = false;
  
  final List<String> _cities = [
    'All Cities',
    'New York',
    'Los Angeles',
    'Chicago',
    'Houston',
    'Phoenix',
    'Philadelphia',
    'San Antonio',
    'San Diego',
    'Dallas',
    'San Jose'
  ];
  
  final List<String> _surfaceTypes = [
    'All Types',
    'Grass',
    'Artificial Turf',
    'Indoor',
    'Clay',
    'Concrete',
    'Other'
  ];
  
  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
  
  Future<void> _initialize() async {
    final token = await _authService.getToken();
    setState(() {
      _turfService = TurfService(authToken: token);
    });
    
    // Initial search to populate with results
    _performSearch();
  }
  
  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Prepare search parameters
      final Map<String, dynamic> searchParams = {};
      
      if (_searchController.text.isNotEmpty) {
        searchParams['query'] = _searchController.text;
      }
      
      if (_selectedCity != null && _selectedCity != 'All Cities') {
        searchParams['city'] = _selectedCity;
      }
      
      if (_selectedSurfaceType != null && _selectedSurfaceType != 'All Types') {
        searchParams['surface_type'] = _selectedSurfaceType!.toLowerCase();
      }
      
      if (_isIndoor != null) {
        searchParams['indoor'] = _isIndoor;
      }
      
      if (_minPrice != null) {
        searchParams['min_price'] = _minPrice;
      }
      
      if (_maxPrice != null) {
        searchParams['max_price'] = _maxPrice;
      }
      
      if (_hasParking) {
        searchParams['has_parking'] = true;
      }
      
      if (_hasChangingRoom) {
        searchParams['has_changing_room'] = true;
      }
      
      if (_hasShower) {
        searchParams['has_shower'] = true;
      }
      
      final result = await _turfService.searchTurfs(searchParams);
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        
        if (result['success']) {
          _searchResults = result['turfs'];
          
          if (_searchResults.isEmpty) {
            _errorMessage = 'No turfs found matching your criteria';
          }
        } else {
          _errorMessage = result['message'] ?? 'Search failed. Please try again.';
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
  
  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              // Use 90% of the available height
              height: MediaQuery.of(context).size.height * 0.9,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Turfs',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedCity = 'All Cities';
                            _selectedSurfaceType = 'All Types';
                            _isIndoor = null;
                            _minPrice = null;
                            _maxPrice = null;
                            _hasParking = false;
                            _hasChangingRoom = false;
                            _hasShower = false;
                          });
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Expanded(
                    child: ListView(
                      children: [
                        // City Filter
                        _buildSectionTitle('City'),
                        _buildDropdownButton<String>(
                          value: _selectedCity ?? 'All Cities',
                          items: _cities,
                          onChanged: (value) {
                            setModalState(() {
                              _selectedCity = value;
                            });
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Surface Type Filter
                        _buildSectionTitle('Surface Type'),
                        _buildDropdownButton<String>(
                          value: _selectedSurfaceType ?? 'All Types',
                          items: _surfaceTypes,
                          onChanged: (value) {
                            setModalState(() {
                              _selectedSurfaceType = value;
                            });
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Indoor/Outdoor Filter
                        _buildSectionTitle('Turf Type'),
                        _buildRadioTile<bool?>(
                          title: 'All Types',
                          value: null,
                          groupValue: _isIndoor,
                          onChanged: (value) {
                            setModalState(() {
                              _isIndoor = value;
                            });
                          },
                        ),
                        _buildRadioTile<bool?>(
                          title: 'Indoor Only',
                          value: true,
                          groupValue: _isIndoor,
                          onChanged: (value) {
                            setModalState(() {
                              _isIndoor = value;
                            });
                          },
                        ),
                        _buildRadioTile<bool?>(
                          title: 'Outdoor Only',
                          value: false,
                          groupValue: _isIndoor,
                          onChanged: (value) {
                            setModalState(() {
                              _isIndoor = value;
                            });
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Price Range Filter
                        _buildSectionTitle('Price Range (per hour)'),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Min Price',
                                  prefixText: '\$',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  if (value.isNotEmpty) {
                                    setModalState(() {
                                      _minPrice = double.tryParse(value);
                                    });
                                  } else {
                                    setModalState(() {
                                      _minPrice = null;
                                    });
                                  }
                                },
                                controller: TextEditingController(
                                  text: _minPrice?.toString() ?? '',
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Max Price',
                                  prefixText: '\$',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  if (value.isNotEmpty) {
                                    setModalState(() {
                                      _maxPrice = double.tryParse(value);
                                    });
                                  } else {
                                    setModalState(() {
                                      _maxPrice = null;
                                    });
                                  }
                                },
                                controller: TextEditingController(
                                  text: _maxPrice?.toString() ?? '',
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Amenities Filter
                        _buildSectionTitle('Amenities'),
                        _buildCheckboxTile(
                          title: 'Parking Available',
                          value: _hasParking,
                          onChanged: (value) {
                            setModalState(() {
                              _hasParking = value!;
                            });
                          },
                        ),
                        _buildCheckboxTile(
                          title: 'Changing Rooms',
                          value: _hasChangingRoom,
                          onChanged: (value) {
                            setModalState(() {
                              _hasChangingRoom = value!;
                            });
                          },
                        ),
                        _buildCheckboxTile(
                          title: 'Showers',
                          value: _hasShower,
                          onChanged: (value) {
                            setModalState(() {
                              _hasShower = value!;
                            });
                          },
                        ),
                        
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _performSearch();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildDropdownButton<T>({
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        underline: Container(),
        items: items.map((T item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(item.toString()),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
  
  Widget _buildRadioTile<T>({
    required String title,
    required T value,
    required T groupValue,
    required void Function(T?) onChanged,
  }) {
    return RadioListTile<T>(
      title: Text(title),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: AppTheme.primaryColor,
      contentPadding: EdgeInsets.zero,
    );
  }
  
  Widget _buildCheckboxTile({
    required String title,
    required bool value,
    required void Function(bool?) onChanged,
  }) {
    return CheckboxListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primaryColor,
      contentPadding: EdgeInsets.zero,
    );
  }
  
  void _navigateToTurfDetails(int turfId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TurfDetailScreen(turfId: turfId),
      ),
    ).then((_) {
      // Refresh results when returning from details
      _performSearch();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Turfs'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Search for turfs...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                        horizontal: 16.0,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                });
                                _performSearch();
                              },
                            )
                          : null,
                    ),
                    onSubmitted: (_) => _performSearch(),
                    textInputAction: TextInputAction.search,
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  onPressed: _showFilterModal,
                  icon: const Icon(Icons.filter_list),
                  tooltip: 'Filter',
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Results
          Expanded(
            child: _isLoading
                ? Center(
                    child: SpinKitCircle(
                      color: AppTheme.primaryColor,
                      size: 50.0,
                    ),
                  )
                : _errorMessage != null && _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.search_off,
                              size: 80,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 16.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _selectedCity = 'All Cities';
                                  _selectedSurfaceType = 'All Types';
                                  _isIndoor = null;
                                  _minPrice = null;
                                  _maxPrice = null;
                                  _hasParking = false;
                                  _hasChangingRoom = false;
                                  _hasShower = false;
                                });
                                _performSearch();
                              },
                              style: AppTheme.primaryButtonStyle,
                              child: const Text('Clear Filters'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _performSearch,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final turf = _searchResults[index];
                            return _buildTurfListItem(turf);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTurfListItem(Turf turf) {
    return GestureDetector(
      onTap: () => _navigateToTurfDetails(turf.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Turf image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12.0)),
              child: SizedBox(
                width: 120,
                height: 120,
                child: turf.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: turf.imageUrl,
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
            
            // Turf details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      turf.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4.0),
                    
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14.0,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4.0),
                        Expanded(
                          child: Text(
                            '${turf.city}, ${turf.state}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8.0),
                    
                    Row(
                      children: [
                        _buildFeatureTag(
                          turf.indoor ? 'Indoor' : 'Outdoor',
                          Colors.blue,
                        ),
                        const SizedBox(width: 8.0),
                        if (turf.surfaceType != null && turf.surfaceType!.isNotEmpty)
                          _buildFeatureTag(
                            turf.surfaceType!,
                            Colors.green,
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 8.0),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Rating
                        if (turf.averageRating != null)
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16.0,
                              ),
                              const SizedBox(width: 4.0),
                              Text(
                                turf.averageRating!.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.0,
                                ),
                              ),
                              Text(
                                ' (${turf.reviewCount})',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12.0,
                                ),
                              ),
                            ],
                          ),
                        
                        // Price
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
                            '\$${turf.basePricePerHour.toStringAsFixed(2)}/hr',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8.0,
        vertical: 2.0,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}