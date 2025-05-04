import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_theme.dart';
import '../../models/turf_model.dart';
import '../../services/turf_service.dart';
import '../../services/auth_service.dart';
import '../turf/turf_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  late TurfService _turfService;
  
  bool _isLoading = true;
  String? _errorMessage;
  List<Turf> _featuredTurfs = [];
  List<Turf> _nearbyTurfs = [];
  List<Turf> _popularTurfs = [];
  
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
    
    _loadTurfs();
  }
  
  Future<void> _loadTurfs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Get featured turfs - using basic getTurfs() for now
      final featuredResult = await _turfService.getTurfs(limit: 5);
      
      // Get nearby turfs - in a real app, this would use location
      // Currently using advanced search with city filter
      final nearbyResult = await _turfService.advancedSearch(city: 'New York');
      
      // Get popular turfs - in a real app, this would be sorted by ratings
      // Currently using a second call to getTurfs with different page
      final popularResult = await _turfService.getTurfs(page: 2, limit: 5);
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        
        if (featuredResult['success']) {
          _featuredTurfs = featuredResult['turfs'];
        }
        
        if (nearbyResult['success']) {
          _nearbyTurfs = nearbyResult['turfs'];
        }
        
        if (popularResult['success']) {
          _popularTurfs = popularResult['turfs'];
        }
        
        // Fallback if all requests failed
        if (!featuredResult['success'] && !nearbyResult['success'] && !popularResult['success']) {
          _errorMessage = 'Failed to load turfs. Please try again.';
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
  
  void _navigateToTurfDetails(int turfId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TurfDetailScreen(turfId: turfId),
      ),
    ).then((_) {
      // Refresh turfs when returning from details
      _loadTurfs();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Turf Booking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications feature coming soon')),
              );
            },
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
                        onPressed: _loadTurfs,
                        style: AppTheme.primaryButtonStyle,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTurfs,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      // Search bar
                      _buildSearchBar(),
                      
                      const SizedBox(height: 24.0),
                      
                      // Featured turfs section
                      if (_featuredTurfs.isNotEmpty) ...[
                        _buildSectionTitle('Featured Turfs'),
                        const SizedBox(height: 12.0),
                        _buildFeaturedTurfsList(),
                        const SizedBox(height: 32.0),
                      ],
                      
                      // Nearby turfs section
                      if (_nearbyTurfs.isNotEmpty) ...[
                        _buildSectionTitle('Turfs Near You'),
                        const SizedBox(height: 12.0),
                        _buildTurfGrid(_nearbyTurfs),
                        const SizedBox(height: 32.0),
                      ],
                      
                      // Popular turfs section
                      if (_popularTurfs.isNotEmpty) ...[
                        _buildSectionTitle('Popular Turfs'),
                        const SizedBox(height: 12.0),
                        _buildTurfGrid(_popularTurfs),
                        const SizedBox(height: 24.0),
                      ],
                    ],
                  ),
                ),
    );
  }
  
  Widget _buildSearchBar() {
    return InkWell(
      onTap: () {
        // Navigate to search page
        // Note: In a real app, we would navigate to SearchScreen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Search feature is accessed through the Search tab')),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.grey[600]),
            const SizedBox(width: 12.0),
            Text(
              'Search for turfs...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
      ),
    );
  }
  
  Widget _buildFeaturedTurfsList() {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _featuredTurfs.length,
        itemBuilder: (context, index) {
          final turf = _featuredTurfs[index];
          return GestureDetector(
            onTap: () => _navigateToTurfDetails(turf.id),
            child: Container(
              width: 280,
              margin: const EdgeInsets.only(right: 16.0),
              decoration: BoxDecoration(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
                    child: SizedBox(
                      height: 150,
                      width: double.infinity,
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
                  
                  // Details
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(12.0)),
                    ),
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
                                '\$${turf.basePricePerHour.toStringAsFixed(2)}',
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildTurfGrid(List<Turf> turfs) {
    // Limit the number of turfs to show to avoid rendering issues
    final limitedTurfs = turfs.length > 4 ? turfs.sublist(0, 4) : turfs;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      itemCount: limitedTurfs.length,
      itemBuilder: (context, index) {
        final turf = limitedTurfs[index];
        return GestureDetector(
          onTap: () => _navigateToTurfDetails(turf.id),
          child: Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
                  child: SizedBox(
                    height: 120,
                    width: double.infinity,
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
                
                // Details
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
                            fontSize: 14.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4.0),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 12.0,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4.0),
                            Expanded(
                              child: Text(
                                turf.city,
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
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (turf.averageRating != null)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 14.0,
                                  ),
                                  const SizedBox(width: 2.0),
                                  Text(
                                    turf.averageRating!.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            else
                              const Text(
                                'New',
                                style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6.0,
                                vertical: 2.0,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryColor,
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                '\$${turf.basePricePerHour.toStringAsFixed(0)}',
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
      },
    );
  }
}