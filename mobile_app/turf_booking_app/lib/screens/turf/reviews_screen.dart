import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_theme.dart';
import '../../models/review_model.dart';
import '../../services/review_service.dart';
import '../../widgets/rating_bar_widget.dart';
import '../../widgets/review_list_item.dart';
import 'add_review_screen.dart';

class ReviewsScreen extends StatefulWidget {
  final int turfId;
  final String turfName;
  
  const ReviewsScreen({
    Key? key, 
    required this.turfId,
    required this.turfName,
  }) : super(key: key);

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  bool _isLoading = true;
  List<Review> _reviews = [];
  double _averageRating = 0.0;
  int _reviewCount = 0;
  String? _errorMessage;
  String? _authToken;
  bool _canReview = false;
  bool _isOwner = false;
  String? _userRole;
  
  @override
  void initState() {
    super.initState();
    _loadAuthToken();
  }
  
  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userRole = prefs.getString('user_role');
    
    setState(() {
      _authToken = token;
      _userRole = userRole;
      _isOwner = userRole == 'OWNER';
    });
    
    await _fetchReviews();
    
    if (!_isOwner && _authToken != null) {
      await _checkCanReview();
    }
  }
  
  Future<void> _fetchReviews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final reviewService = ReviewService(authToken: _authToken);
      final result = await reviewService.getTurfReviews(widget.turfId);
      
      if (result['success']) {
        setState(() {
          _reviews = result['reviews'];
          _averageRating = result['averageRating'] ?? 0.0;
          _reviewCount = result['reviewCount'] ?? 0;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load reviews: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _checkCanReview() async {
    try {
      final reviewService = ReviewService(authToken: _authToken);
      final result = await reviewService.canReviewTurf(widget.turfId);
      
      if (result['success']) {
        setState(() {
          _canReview = result['canReview'];
        });
      }
    } catch (e) {
      // We don't need to show an error if this fails
      print('Failed to check review eligibility: $e');
    }
  }
  
  Future<void> _deleteReview(Review review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete this review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirmed) return;
    
    final reviewService = ReviewService(authToken: _authToken);
    final result = await reviewService.deleteReview(review.id);
    
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
        ),
      );
      _fetchReviews();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _editReview(Review review) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddReviewScreen(
          turfId: widget.turfId,
          turfName: widget.turfName,
          existingReview: review,
          onReviewUpdated: () {
            _fetchReviews();
          },
        ),
      ),
    );
  }
  
  void _replyToReview(Review review) {
    // Show dialog to enter response
    final responseController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reply to Review'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RatingBarWidget(rating: review.rating.toDouble()),
            const SizedBox(height: 8),
            Text(review.comment),
            const SizedBox(height: 16),
            TextField(
              controller: responseController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Your Response',
                hintText: 'Enter your response to this review...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (responseController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a response')),
                );
                return;
              }
              
              Navigator.of(context).pop();
              _submitResponse(review, responseController.text.trim());
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _submitResponse(Review review, String response) async {
    try {
      final reviewService = ReviewService(authToken: _authToken);
      final result = await reviewService.respondToReview(
        reviewId: review.id,
        response: response,
      );
      
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
        _fetchReviews();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit response: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              widget.turfName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            _buildRatingSummary(),
                            const Divider(height: 32),
                          ],
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final review = _reviews[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: ReviewListItem(
                              review: review,
                              isOwner: _isOwner,
                              onReplyPressed: _isOwner ? _replyToReview : null,
                              onEditPressed: !_isOwner && review.userId.toString() == _getUserId() 
                                  ? _editReview : null,
                              onDeletePressed: !_isOwner && review.userId.toString() == _getUserId() 
                                  ? _deleteReview : null,
                            ),
                          );
                        },
                        childCount: _reviews.length,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _reviews.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Center(
                                child: Text(
                                  'No reviews yet. Be the first to review this turf!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : const SizedBox(height: 80),
                    ),
                  ],
                ),
      floatingActionButton: (_canReview && !_isOwner && _authToken != null)
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddReviewScreen(
                      turfId: widget.turfId,
                      turfName: widget.turfName,
                      onReviewUpdated: () {
                        _fetchReviews();
                        _checkCanReview();
                      },
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.rate_review),
              label: const Text('Write a Review'),
              backgroundColor: AppTheme.primaryColor,
            )
          : null,
    );
  }
  
  Widget _buildRatingSummary() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _averageRating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RatingBarWidget(
                  rating: _averageRating,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  '$_reviewCount ${_reviewCount == 1 ? 'review' : 'reviews'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
  
  String? _getUserId() {
    try {
      final prefs = SharedPreferences.getInstance();
      return prefs.then((value) => value.getString('user_id'));
    } catch (e) {
      return null;
    }
  }
}