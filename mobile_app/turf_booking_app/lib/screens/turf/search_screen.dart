import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_theme.dart';
import '../../models/turf_model.dart';
import '../../services/turf_service.dart';
import '../../services/auth_service.dart';
import 'turf_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _cityController = TextEditingController();
  final _dateController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  
  String? _selectedIndoor;
  
  final AuthService _authService = AuthService();
  late TurfService _turfService;
  
  bool _isLoading = false;
  List<Turf> _searchResults = [];
  String? _errorMessage;
  bool _hasSearched = false;
  
  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  Future<void> _initialize() async {
    final token = await _authService.getToken();
    setState(() {
      _turfService = TurfService(authToken: token);
    });
  }
  
  @override
  void dispose() {
    _cityController.dispose();
    _dateController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }
  
  Future<void> _search() async {
    // Don't search if all fields are empty
    if (_cityController.text.isEmpty &&
        _dateController.text.isEmpty &&
        _minPriceController.text.isEmpty &&
        _maxPriceController.text.isEmpty &&
        _selectedIndoor == null) {
      setState(() {
        _errorMessage = 'Please enter at least one search criteria';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
    });
    
    // Parse min and max prices if provided
    double? minPrice;
    if (_minPriceController.text.isNotEmpty) {
      minPrice = double.tryParse(_minPriceController.text);
    }
    
    double? maxPrice;
    if (_maxPriceController.text.isNotEmpty) {
      maxPrice = double.tryParse(_maxPriceController.text);
    }
    
    final result = await _turfService.searchTurfs(
      city: _cityController.text,
      date: _dateController.text,
      minPrice: minPrice,
      maxPrice: maxPrice,
      indoor: _selectedIndoor,
    );
    
    setState(() {
      _isLoading = false;
      
      if (result['success']) {
        _searchResults = result['turfs'];
        if (_searchResults.isEmpty) {
          _errorMessage = 'No turfs found matching your criteria';
        }
      } else {
        _errorMessage = result['message'];
      }
    });
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
      setState(() {
        // Format date as YYYY-MM-DD
        _dateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }
  
  void _navigateToTurfDetails(Turf turf) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TurfDetailScreen(turfId: turf.id),
      ),
    );
  }
  
  void _clearSearch() {
    setState(() {
      _cityController.clear();
      _dateController.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
      _selectedIndoor = null;
      _searchResults = [];
      _errorMessage = null;
      _hasSearched = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Turfs'),
        actions: [
          if (_hasSearched)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearSearch,
              tooltip: 'Clear Search',
            ),
        ],
      ),
      body: Column(
        children: [
          // Search form
          Card(
            margin: const EdgeInsets.all(16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // City field
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      hintText: 'E.g., New York',
                      prefixIcon: Icon(Icons.location_city),
                    ),
                  ),
                  
                  const SizedBox(height: 12.0),
                  
                  // Date field
                  TextFormField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      hintText: 'YYYY-MM-DD',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context),
                  ),
                  
                  const SizedBox(height: 12.0),
                  
                  // Price range row
                  Row(
                    children: [
                      // Min price
                      Expanded(
                        child: TextFormField(
                          controller: _minPriceController,
                          decoration: const InputDecoration(
                            labelText: 'Min Price',
                            hintText: '\$0',
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      
                      const SizedBox(width: 12.0),
                      
                      // Max price
                      Expanded(
                        child: TextFormField(
                          controller: _maxPriceController,
                          decoration: const InputDecoration(
                            labelText: 'Max Price',
                            hintText: '\$100',
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12.0),
                  
                  // Indoor/Outdoor dropdown
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      prefixIcon: Icon(Icons.home_work),
                    ),
                    value: _selectedIndoor,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedIndoor = newValue;
                      });
                    },
                    items: <String?>[null, 'True', 'False'].map((String? value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value == null 
                              ? 'Any' 
                              : value == 'True' 
                                  ? 'Indoor' 
                                  : 'Outdoor',
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 24.0),
                  
                  // Search button
                  ElevatedButton.icon(
                    onPressed: _search,
                    style: AppTheme.primaryButtonStyle,
                    icon: const Icon(Icons.search),
                    label: const Text('Search Turfs'),
                  ),
                  
                  // Error message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12.0),
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: AppTheme.errorColor),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Search results
          Expanded(
            child: _isLoading
                ? Center(
                    child: SpinKitCircle(
                      color: AppTheme.primaryColor,
                      size: 50.0,
                    ),
                  )
                : !_hasSearched
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Search for turfs using\nthe form above',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _searchResults.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.sports_soccer,
                                  size: 80,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No turfs found matching\nyour search criteria',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final turf = _searchResults[index];
                              return _buildSearchResultCard(turf);
                            },
                          ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchResultCard(Turf turf) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToTurfDetails(turf),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Turf image
            SizedBox(
              width: 100,
              height: 100,
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
            
            // Turf details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
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
                    
                    // Location
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${turf.city}, ${turf.state}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4.0),
                    
                    // Price and type
                    Row(
                      children: [
                        Text(
                          '\$${turf.basePricePerHour.toStringAsFixed(2)}/hr',
                          style: TextStyle(
                            color: AppTheme.secondaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6.0,
                            vertical: 2.0,
                          ),
                          decoration: BoxDecoration(
                            color: turf.indoor 
                                ? AppTheme.primaryColor.withOpacity(0.2)
                                : AppTheme.accentColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            turf.indoor ? 'Indoor' : 'Outdoor',
                            style: TextStyle(
                              fontSize: 12.0,
                              color: turf.indoor 
                                  ? AppTheme.primaryColor
                                  : AppTheme.accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    if (turf.averageRating != null) ...[
                      const SizedBox(height: 4.0),
                      
                      // Rating
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16.0,
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            '${turf.averageRating!.toStringAsFixed(1)} (${turf.reviewCount})',
                            style: const TextStyle(
                              fontSize: 14.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}