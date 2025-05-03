import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../config/app_theme.dart';
import '../../models/turf_model.dart';
import '../../services/turf_service.dart';
import '../../services/auth_service.dart';
import '../booking/create_booking_screen.dart';
import '../auth/login_screen.dart';

class TurfDetailScreen extends StatefulWidget {
  final int turfId;

  const TurfDetailScreen({super.key, required this.turfId});

  @override
  State<TurfDetailScreen> createState() => _TurfDetailScreenState();
}

class _TurfDetailScreenState extends State<TurfDetailScreen> {
  final AuthService _authService = AuthService();
  late TurfService _turfService;
  
  bool _isLoading = true;
  bool _isLoggedIn = false;
  Turf? _turf;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  Future<void> _initialize() async {
    final isLoggedIn = await _authService.isLoggedIn();
    final token = await _authService.getToken();
    
    setState(() {
      _isLoggedIn = isLoggedIn;
      _turfService = TurfService(authToken: token);
    });
    
    _loadTurfDetails();
  }
  
  Future<void> _loadTurfDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    final result = await _turfService.getTurfDetails(widget.turfId);
    
    setState(() {
      _isLoading = false;
      
      if (result['success']) {
        _turf = result['turf'];
      } else {
        _errorMessage = result['message'];
      }
    });
  }
  
  Future<void> _toggleFavorite() async {
    if (!_isLoggedIn) {
      _showLoginPrompt();
      return;
    }
    
    final result = await _turfService.toggleFavorite(widget.turfId);
    
    if (result['success']) {
      setState(() {
        if (_turf != null) {
          _turf = Turf(
            id: _turf!.id,
            name: _turf!.name,
            description: _turf!.description,
            address: _turf!.address,
            city: _turf!.city,
            state: _turf!.state,
            country: _turf!.country,
            postalCode: _turf!.postalCode,
            basePricePerHour: _turf!.basePricePerHour,
            features: _turf!.features,
            size: _turf!.size,
            indoor: _turf!.indoor,
            hasParking: _turf!.hasParking,
            hasChangingRoom: _turf!.hasChangingRoom,
            hasShower: _turf!.hasShower,
            hasFloodlights: _turf!.hasFloodlights,
            hasEquipment: _turf!.hasEquipment,
            hasRefreshments: _turf!.hasRefreshments,
            surfaceType: _turf!.surfaceType,
            imageUrl: _turf!.imageUrl,
            additionalImages: _turf!.additionalImages,
            averageRating: _turf!.averageRating,
            reviewCount: _turf!.reviewCount,
            ownerId: _turf!.ownerId,
            ownerName: _turf!.ownerName,
            isFavorite: result['isFavorite'],
          );
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
  
  void _bookTurf() {
    if (!_isLoggedIn) {
      _showLoginPrompt();
      return;
    }
    
    if (_turf == null) return;
    
    // Navigate to booking screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateBookingScreen(turf: _turf!),
      ),
    );
  }
  
  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('You need to login to perform this action.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            },
            style: AppTheme.primaryButtonStyle,
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        onPressed: _loadTurfDetails,
                        style: AppTheme.primaryButtonStyle,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : _turf == null
                  ? const Center(child: Text('Turf not found'))
                  : _buildTurfDetails(),
    );
  }
  
  Widget _buildTurfDetails() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 250.0,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(
                _turf!.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                _turf!.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: _turf!.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: SpinKitFadingCircle(
                            color: AppTheme.primaryColor,
                            size: 30.0,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.sports_soccer,
                            size: 80,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.sports_soccer,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
                // Gradient for better text readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.7, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _turf!.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _turf!.isFavorite ? Colors.red : Colors.white,
              ),
              onPressed: _toggleFavorite,
            ),
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: () {
                // Share functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sharing not implemented yet')),
                );
              },
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price and rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 6.0,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        '\$${_turf!.basePricePerHour.toStringAsFixed(2)}/hr',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                    if (_turf!.averageRating != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 20.0,
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            '${_turf!.averageRating!.toStringAsFixed(1)} (${_turf!.reviewCount} ${_turf!.reviewCount == 1 ? 'review' : 'reviews'})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                
                const SizedBox(height: 16.0),
                
                // Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.grey,
                      size: 20.0,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        '${_turf!.address}, ${_turf!.city}, ${_turf!.state}, ${_turf!.country}, ${_turf!.postalCode}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16.0),
                
                // Features section
                const Text(
                  'Features',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8.0),
                
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    _buildFeatureCard('Type', _turf!.indoor ? 'Indoor' : 'Outdoor', Icons.home_work),
                    _buildFeatureCard('Surface', _turf!.surfaceType, Icons.grass),
                    if (_turf!.size != null && _turf!.size!.isNotEmpty)
                      _buildFeatureCard('Size', _turf!.size!, Icons.aspect_ratio),
                    if (_turf!.hasParking)
                      _buildFeatureCard('Parking', 'Available', Icons.local_parking),
                    if (_turf!.hasChangingRoom)
                      _buildFeatureCard('Changing Room', 'Available', Icons.meeting_room),
                    if (_turf!.hasShower)
                      _buildFeatureCard('Shower', 'Available', Icons.shower),
                    if (_turf!.hasFloodlights)
                      _buildFeatureCard('Floodlights', 'Available', Icons.lightbulb),
                    if (_turf!.hasEquipment)
                      _buildFeatureCard('Equipment', 'Available', Icons.sports_soccer),
                    if (_turf!.hasRefreshments)
                      _buildFeatureCard('Refreshments', 'Available', Icons.restaurant),
                  ],
                ),
                
                const SizedBox(height: 16.0),
                
                // Description
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8.0),
                
                Text(
                  _turf!.description.isNotEmpty
                      ? _turf!.description
                      : 'No description available.',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16.0,
                  ),
                ),
                
                const SizedBox(height: 24.0),
                
                // Book Now button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _bookTurf,
                    style: AppTheme.primaryButtonStyle.copyWith(
                      padding: MaterialStateProperty.all(
                        const EdgeInsets.symmetric(vertical: 16.0),
                      ),
                    ),
                    child: const Text(
                      'Book Now',
                      style: TextStyle(
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
      ],
    );
  }
  
  Widget _buildFeatureCard(String title, String value, IconData icon) {
    return Container(
      width: MediaQuery.of(context).size.width / 2 - 24,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 24.0,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12.0,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}