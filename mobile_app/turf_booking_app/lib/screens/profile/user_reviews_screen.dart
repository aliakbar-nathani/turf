import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/review_model.dart';
import '../../services/review_service.dart';
import '../../widgets/review_list_item.dart';
import '../turf/add_review_screen.dart';

class UserReviewsScreen extends StatefulWidget {
  const UserReviewsScreen({Key? key}) : super(key: key);

  @override
  State<UserReviewsScreen> createState() => _UserReviewsScreenState();
}

class _UserReviewsScreenState extends State<UserReviewsScreen> {
  bool _isLoading = true;
  List<Review> _reviews = [];
  String? _errorMessage;
  String? _authToken;
  
  @override
  void initState() {
    super.initState();
    _loadAuthTokenAndFetchReviews();
  }
  
  Future<void> _loadAuthTokenAndFetchReviews() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    setState(() {
      _authToken = token;
    });
    
    await _fetchUserReviews();
  }
  
  Future<void> _fetchUserReviews() async {
    if (_authToken == null) {
      setState(() {
        _errorMessage = 'You must be logged in to view your reviews';
        _isLoading = false;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final reviewService = ReviewService(authToken: _authToken);
      final result = await reviewService.getUserReviews();
      
      if (result['success']) {
        setState(() {
          _reviews = result['reviews'];
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
      _fetchUserReviews();
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
          turfId: review.turfId,
          turfName: 'Turf', // We don't have the turf name here, just using placeholder
          existingReview: review,
          onReviewUpdated: () {
            _fetchUserReviews();
          },
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reviews'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _reviews.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _reviews.length,
                      itemBuilder: (context, index) {
                        final review = _reviews[index];
                        return ReviewListItem(
                          review: review,
                          onEditPressed: _editReview,
                          onDeletePressed: _deleteReview,
                        );
                      },
                    ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
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
              'You haven\'t posted any reviews yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your reviews will appear here after you rate turfs you\'ve booked',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Go back to profile
              },
              child: const Text('Back to Profile'),
            ),
          ],
        ),
      ),
    );
  }
}