import 'package:flutter/material.dart';
import '../models/review_model.dart';

class ReviewFormWidget extends StatefulWidget {
  final Function(int rating, String comment) onSubmit;
  final String submitButtonLabel;
  final Review? initialReview;
  
  const ReviewFormWidget({
    Key? key,
    required this.onSubmit,
    this.submitButtonLabel = 'Submit Review',
    this.initialReview,
  }) : super(key: key);

  @override
  State<ReviewFormWidget> createState() => _ReviewFormWidgetState();
}

class _ReviewFormWidgetState extends State<ReviewFormWidget> {
  late int _rating;
  late TextEditingController _commentController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialReview?.rating ?? 5;
    _commentController = TextEditingController(
      text: widget.initialReview?.comment ?? '',
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rate your experience',
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildRatingSelector(),
        const SizedBox(height: 24),
        TextField(
          controller: _commentController,
          maxLines: 4,
          maxLength: 500,
          decoration: const InputDecoration(
            labelText: 'Your Review (Optional)',
            hintText: 'Share your experience about this turf...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitReview,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSubmitting
                ? const CircularProgressIndicator()
                : Text(widget.submitButtonLabel),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final selected = starValue <= _rating;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _rating = starValue;
            });
          },
          child: Column(
            children: [
              Icon(
                selected ? Icons.star : Icons.star_border,
                color: selected ? Colors.amber : Colors.grey,
                size: 40,
              ),
              const SizedBox(height: 4),
              Text(
                _getRatingLabel(starValue),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? Colors.amber.shade800 : Colors.grey,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  void _submitReview() {
    if (_rating < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Call the onSubmit callback with the review data
    widget.onSubmit(_rating, _commentController.text.trim());

    // Note: We don't reset the form or set _isSubmitting = false here
    // because this widget will likely be disposed or refreshed after submission
  }
}