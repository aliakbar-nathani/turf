import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/turf_service.dart';
import '../../services/auth_service.dart';
import '../../models/turf_model.dart';
import 'owner_add_turf_screen.dart';

class OwnerTurfListScreen extends StatefulWidget {
  const OwnerTurfListScreen({super.key});

  @override
  State<OwnerTurfListScreen> createState() => _OwnerTurfListScreenState();
}

class _OwnerTurfListScreenState extends State<OwnerTurfListScreen> {
  bool _isLoading = true;
  List<Turf> _turfs = [];
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadTurfs();
  }
  
  Future<void> _loadTurfs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final authService = AuthService();
      final token = await authService.getToken();
      
      final turfService = TurfService(authToken: token);
      final result = await turfService.getOwnerTurfs();
      
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _turfs = result['turfs'];
        } else {
          _errorMessage = result['message'];
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load turfs: $e';
      });
    }
  }
  
  Future<void> _confirmDeleteTurf(Turf turf) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Turf'),
        content: Text('Are you sure you want to delete "${turf.name}"? This action cannot be undone.'),
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
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = AuthService();
      final token = await authService.getToken();
      
      final turfService = TurfService(authToken: token);
      final result = await turfService.deleteTurf(turfId);
      
      setState(() {
        _isLoading = false;
      });
      
      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
          _loadTurfs(); // Reload the list
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
  
  Future<void> _navigateToAddTurf() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OwnerAddTurfScreen()),
    );
    
    if (result != null) {
      _loadTurfs();
    }
  }
  
  Future<void> _navigateToEditTurf(Turf turf) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OwnerAddTurfScreen(turf: turf),
      ),
    );
    
    if (result != null) {
      _loadTurfs();
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
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTurf,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTurfs,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _turfs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.sports_soccer,
                            size: 80,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No turfs yet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add your first turf by tapping the + button',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _navigateToAddTurf,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: const Text('Add New Turf'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _turfs.length,
                      itemBuilder: (context, index) {
                        final turf = _turfs[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          clipBehavior: Clip.antiAlias,
                          elevation: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Turf image
                              if (turf.imageUrl != null && turf.imageUrl!.isNotEmpty)
                                Image.network(
                                  turf.imageUrl!,
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 160,
                                      width: double.infinity,
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                )
                              else
                                Container(
                                  height: 160,
                                  width: double.infinity,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.image,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                              
                              // Turf details
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            turf.name,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: turf.indoor == true
                                                ? Colors.blue[100]
                                                : Colors.green[100],
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            turf.indoor == true ? 'Indoor' : 'Outdoor',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: turf.indoor == true
                                                  ? Colors.blue[800]
                                                  : Colors.green[800],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${turf.address}, ${turf.city}',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Price: \$${turf.basePricePerHour.toStringAsFixed(2)} per hour',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${turf.rating != null ? turf.rating!.toStringAsFixed(1) : 'N/A'} (${turf.reviewsCount ?? 0})',
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit),
                                              onPressed: () => _navigateToEditTurf(turf),
                                              tooltip: 'Edit',
                                              color: Colors.blue,
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete),
                                              onPressed: () => _confirmDeleteTurf(turf),
                                              tooltip: 'Delete',
                                              color: Colors.red,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}