import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../config/app_theme.dart';
import '../../models/review_model.dart';
import '../../services/review_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/rating_bar_widget.dart';
import '../auth/login_screen.dart';
import '../turf/turf_detail_screen.dart';

class UserReviewsScreen extends StatefulWidget {
  const UserReviewsScreen({super.key});

  @override
  State<UserReviewsScreen> createState() => _UserReviewsScreenState();
}

class _UserReviewsScreenState extends State<UserReviewsScreen> {
  final AuthService _authService = AuthService();
  late ReviewService _reviewService;
  
  bool _isLoading = true;
  List<Review> _reviews = [];
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  Future<void> _initialize() async {
    final token = await _authService.getToken();
    
    if (token == null) {
      _navigateToLogin();
      return;
    }
    
    _reviewService = ReviewService(authToken: token);
    _loadUserReviews();
  }
  
  Future<void> _loadUserReviews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final result = await _reviewService.getUserReviews();
      
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _reviews = List<Review>.from(result['reviews']);
        } else {
          _errorMessage = result['message'] ?? 'Failed to load reviews';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }
  
  void _navigateToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }
  
  void _navigateToTurfDetails(int turfId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TurfDetailScreen(turfId: turfId)),
    ).then((_) => _loadUserReviews());
  }
  
  Future<void> _deleteReview(int reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete this review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final result = await _reviewService.deleteReview(reviewId);
      
      setState(() {
        _isLoading = false;
        
        if (result['success']) {
          // Remove from local list
          _reviews.removeWhere((review) => review.id == reviewId);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Review deleted successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to delete review'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
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
        title: const Text('My Reviews'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserReviews,
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
          : _buildContent(),
    );
  }
  
  Widget _buildContent() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: TextStyle(color: AppTheme.errorColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserReviews,
              style: AppTheme.primaryButtonStyle,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }
    
    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.rate_review_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Reviews Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You haven\'t written any reviews yet',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Go back to home screen
                Navigator.pop(context);
              },
              icon: const Icon(Icons.search),
              label: const Text('Find Turfs to Review'),
              style: AppTheme.primaryButtonStyle,
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadUserReviews,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _reviews.length,
        itemBuilder: (context, index) {
          final review = _reviews[index];
          
          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Turf name
                  GestureDetector(
                    onTap: () => _navigateToTurfDetails(review.turfId),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            review.turfName,
                            style: const TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16.0,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8.0),
                  
                  // Rating and date
                  Row(
                    children: [
                      RatingBarWidget(
                        rating: review.rating.toDouble(),
                        size: 20.0,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        review.createdAt,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14.0,
                        ),
                      ),
                    ],
                  ),
                  
                  if (review.comment != null && review.comment!.isNotEmpty) ...[
                    const SizedBox(height: 12.0),
                    
                    // Comment
                    Text(
                      review.comment!,
                      style: const TextStyle(fontSize: 16.0),
                    ),
                  ],
                  
                  if (review.ownerResponse != null && review.ownerResponse!.isNotEmpty) ...[
                    const SizedBox(height: 12.0),
                    
                    // Owner response
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Response from owner:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.0,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            review.ownerResponse!,
                            style: const TextStyle(fontSize: 14.0),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 16.0),
                  
                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _deleteReview(review.id),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                          side: BorderSide(color: AppTheme.errorColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}