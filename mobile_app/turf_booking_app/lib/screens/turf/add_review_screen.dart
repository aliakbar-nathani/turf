import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/review_model.dart';
import '../../services/review_service.dart';
import '../../widgets/review_form_widget.dart';

class AddReviewScreen extends StatefulWidget {
  final int turfId;
  final String turfName;
  final Function onReviewUpdated;
  final Review? existingReview;
  
  const AddReviewScreen({
    Key? key,
    required this.turfId,
    required this.turfName,
    required this.onReviewUpdated,
    this.existingReview,
  }) : super(key: key);

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  String? _authToken;
  bool _isSubmitting = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadAuthToken();
  }
  
  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    setState(() {
      _authToken = token;
    });
  }
  
  void _submitReview(int rating, String comment) async {
    if (_authToken == null) {
      setState(() {
        _errorMessage = 'You must be logged in to submit a review';
      });
      return;
    }
    
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    
    try {
      final reviewService = ReviewService(authToken: _authToken);
      Map<String, dynamic> result;
      
      if (widget.existingReview != null) {
        // Update existing review
        result = await reviewService.updateReview(
          reviewId: widget.existingReview!.id,
          rating: rating,
          comment: comment,
        );
      } else {
        // Submit new review
        result = await reviewService.submitReview(
          turfId: widget.turfId,
          rating: rating,
          comment: comment,
        );
      }
      
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
        
        // Call the callback to update the parent screen
        widget.onReviewUpdated();
        
        // Pop the screen after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.of(context).pop();
        });
      } else {
        setState(() {
          _errorMessage = result['message'];
          _isSubmitting = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to submit review: $e';
        _isSubmitting = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingReview != null ? 'Edit Review' : 'Add Review'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.turfName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            ReviewFormWidget(
              onSubmit: _submitReview,
              submitButtonLabel: widget.existingReview != null 
                  ? 'Update Review' 
                  : 'Submit Review',
              initialReview: widget.existingReview,
            ),
          ],
        ),
      ),
    );
  }
}