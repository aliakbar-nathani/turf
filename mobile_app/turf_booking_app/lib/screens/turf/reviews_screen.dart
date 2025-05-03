import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../config/app_theme.dart';
import '../../models/review_model.dart';
import '../../services/review_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/rating_bar_widget.dart';
import 'add_review_screen.dart';

class ReviewsScreen extends StatefulWidget {
  final int turfId;
  final String turfName;
  
  const ReviewsScreen({
    super.key, 
    required this.turfId, 
    required this.turfName,
  });

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final AuthService _authService = AuthService();
  late ReviewService _reviewService;
  
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _canReview = false;
  bool _isCheckingEligibility = false;
  
  List<Review> _reviews = [];
  double? _averageRating;
  int? _reviewCount;
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
      _isLoading = true;
      _isLoggedIn = isLoggedIn;
      _errorMessage = null;
    });
    
    // Initialize review service with or without token
    _reviewService = ReviewService(authToken: token);
    
    // Load reviews
    await _loadReviews();
    
    // Check if user can review
    if (_isLoggedIn) {
      await _checkReviewEligibility();
    }
  }
  
  Future<void> _loadReviews() async {
    try {
      final result = await _reviewService.getTurfReviews(widget.turfId);
      
      setState(() {
        _isLoading = false;
        
        if (result['success']) {
          _reviews = List<Review>.from(result['reviews']);
          _averageRating = result['averageRating'];
          _reviewCount = result['reviewCount'];
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
  
  Future<void> _checkReviewEligibility() async {
    if (!_isLoggedIn) return;
    
    setState(() {
      _isCheckingEligibility = true;
    });
    
    try {
      final result = await _reviewService.canReviewTurf(widget.turfId);
      
      setState(() {
        _isCheckingEligibility = false;
        _canReview = result['canReview'] ?? false;
      });
    } catch (e) {
      setState(() {
        _isCheckingEligibility = false;
        _canReview = false;
      });
    }
  }
  
  void _navigateToAddReview() async {
    if (!_isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to write a review'),
        ),
      );
      return;
    }
    
    if (!_canReview) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only review turfs you have booked and played on'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddReviewScreen(
          turfId: widget.turfId,
          turfName: widget.turfName,
        ),
      ),
    );
    
    // Reload reviews if a new review was added
    if (result == true) {
      _loadReviews();
      _checkReviewEligibility();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reviews for ${widget.turfName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReviews,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: _isLoggedIn && _canReview
          ? FloatingActionButton(
              onPressed: _navigateToAddReview,
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.rate_review),
            )
          : null,
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
              onPressed: _loadReviews,
              style: AppTheme.primaryButtonStyle,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        // Rating summary
        if (_averageRating != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      _averageRating!.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RatingBarWidget(
                            rating: _averageRating!,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Based on $_reviewCount ${_reviewCount == 1 ? 'review' : 'reviews'}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                if (_isLoggedIn && !_canReview && !_isCheckingEligibility) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'You can review this turf after you have completed a booking.',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                
                if (_isLoggedIn && _canReview) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _navigateToAddReview,
                      icon: const Icon(Icons.rate_review),
                      label: const Text('Write a Review'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: BorderSide(color: AppTheme.primaryColor),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        
        // Reviews list
        Expanded(
          child: _reviews.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(0),
                  itemCount: _reviews.length,
                  itemBuilder: (context, index) {
                    final review = _reviews[index];
                    return _buildReviewItem(review);
                  },
                ),
        ),
      ],
    );
  }
  
  Widget _buildEmptyState() {
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
          Text(
            'Be the first to review ${widget.turfName}',
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          if (_isLoggedIn && _canReview) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToAddReview,
              icon: const Icon(Icons.rate_review),
              label: const Text('Write a Review'),
              style: AppTheme.primaryButtonStyle,
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildReviewItem(Review review) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info and date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                review.username,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                review.createdAt,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Rating
          RatingBarWidget(
            rating: review.rating.toDouble(),
            size: 18,
          ),
          
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            
            // Comment
            Text(
              review.comment!,
              style: const TextStyle(
                fontSize: 15,
              ),
            ),
          ],
          
          if (review.ownerResponse != null && review.ownerResponse!.isNotEmpty) ...[
            const SizedBox(height: 16),
            
            // Owner response
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.store,
                        size: 16,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Response from owner',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    review.ownerResponse!,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}