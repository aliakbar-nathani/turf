import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_theme.dart';
import '../../models/turf_model.dart';
import '../../services/turf_service.dart';
import '../../services/auth_service.dart';
import 'owner_turf_edit_screen.dart';
import 'owner_add_turf_screen.dart';

class OwnerTurfListScreen extends StatefulWidget {
  const OwnerTurfListScreen({super.key});

  @override
  State<OwnerTurfListScreen> createState() => _OwnerTurfListScreenState();
}

class _OwnerTurfListScreenState extends State<OwnerTurfListScreen> {
  final AuthService _authService = AuthService();
  late TurfService _turfService;
  
  bool _isLoading = true;
  String? _errorMessage;
  List<Turf> _myTurfs = [];
  
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
      // Get owner's turfs
      final result = await _turfService.getOwnerTurfs();
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        
        if (result['success']) {
          _myTurfs = result['turfs'];
        } else {
          _errorMessage = result['message'] ?? 'Failed to load turfs';
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
  
  void _navigateToTurfEdit(Turf turf) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OwnerTurfEditScreen(turf: turf),
      ),
    ).then((_) {
      // Refresh turfs when returning from edit
      _loadTurfs();
    });
  }
  
  void _navigateToAddTurf() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OwnerAddTurfScreen(),
      ),
    ).then((_) {
      // Refresh turfs when returning from add
      _loadTurfs();
    });
  }
  
  void _showDeleteConfirmation(Turf turf) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Turf'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${turf.name}"?',
              style: const TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 8.0),
            const Text(
              'This action cannot be undone and will cancel all future bookings.',
              style: TextStyle(color: Colors.red, fontSize: 14.0),
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
              Navigator.pop(context);
              _deleteTurf(turf.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _deleteTurf(int turfId) async {
    // Show loading indicator
    final loadingSnackBar = SnackBar(
      content: Row(
        children: [
          SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          const Text('Deleting turf...'),
        ],
      ),
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(loadingSnackBar);
    
    try {
      final result = await _turfService.deleteTurf(turfId);
      
      if (result['success']) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Turf deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh the list
        _loadTurfs();
      } else {
        throw Exception(result['message'] ?? 'Failed to delete turf');
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Turfs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTurfs,
            tooltip: 'Refresh',
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
              : _myTurfs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.landscape,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'You haven\'t added any turfs yet',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _navigateToAddTurf,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Your First Turf'),
                            style: AppTheme.primaryButtonStyle,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTurfs,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _myTurfs.length,
                        itemBuilder: (context, index) {
                          final turf = _myTurfs[index];
                          return _buildTurfCard(turf);
                        },
                      ),
                    ),
      floatingActionButton: _myTurfs.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: _navigateToAddTurf,
              backgroundColor: AppTheme.secondaryColor,
              child: const Icon(Icons.add),
            ),
    );
  }
  
  Widget _buildTurfCard(Turf turf) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Turf image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
            child: SizedBox(
              height: 160,
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
          
          // Turf details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Turf name
                Text(
                  turf.name,
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                
                // Location and price
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16.0,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4.0),
                    Expanded(
                      child: Text(
                        '${turf.address}, ${turf.city}',
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
                
                // Price
                Row(
                  children: [
                    Icon(
                      Icons.attach_money,
                      size: 16.0,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      '\$${turf.basePricePerHour.toStringAsFixed(2)} per hour',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showDeleteConfirmation(turf),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    ElevatedButton.icon(
                      onPressed: () => _navigateToTurfEdit(turf),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}