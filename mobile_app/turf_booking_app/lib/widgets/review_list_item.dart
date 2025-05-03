import 'package:flutter/material.dart';
import '../models/review_model.dart';
import 'rating_bar_widget.dart';

class ReviewListItem extends StatelessWidget {
  final Review review;
  final bool isOwner;
  final Function(Review)? onReplyPressed;
  final Function(Review)? onEditPressed;
  final Function(Review)? onDeletePressed;
  
  const ReviewListItem({
    Key? key,
    required this.review,
    this.isOwner = false,
    this.onReplyPressed,
    this.onEditPressed,
    this.onDeletePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(review.username[0].toUpperCase(), 
                      style: const TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                            review.formattedCreatedAt,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      RatingBarWidget(
                        rating: review.rating.toDouble(),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                review.comment,
                style: const TextStyle(fontSize: 15),
              ),
            ],
            
            // Owner response section
            if (review.ownerResponse != null && review.ownerResponse!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.business, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Owner Response · ${review.formattedOwnerResponseDate}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      review.ownerResponse!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
            
            // Action buttons
            if (isOwner && (review.ownerResponse == null || review.ownerResponse!.isEmpty)) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.reply),
                  label: const Text('Reply'),
                  onPressed: () {
                    if (onReplyPressed != null) {
                      onReplyPressed!(review);
                    }
                  },
                ),
              ),
            ] else if (!isOwner && onEditPressed != null && onDeletePressed != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    onPressed: () => onEditPressed!(review),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () => onDeletePressed!(review),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}