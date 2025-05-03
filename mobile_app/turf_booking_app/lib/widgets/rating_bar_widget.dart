import 'package:flutter/material.dart';

class RatingBarWidget extends StatelessWidget {
  final double rating;
  final double size;
  final Color? color;
  final bool showLabel;
  final String? label;
  final MainAxisAlignment alignment;

  const RatingBarWidget({
    Key? key,
    required this.rating,
    this.size = 20.0,
    this.color,
    this.showLabel = false,
    this.label,
    this.alignment = MainAxisAlignment.start,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final starColor = color ?? Colors.amber;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final isHalfStar = index + 0.5 == rating.floor() + 0.5 && 
                               index < rating && 
                               rating.floor() != rating;
            final isFullStar = index < rating.floor();
            
            if (isFullStar) {
              return Icon(Icons.star, color: starColor, size: size);
            } else if (isHalfStar) {
              return Icon(Icons.star_half, color: starColor, size: size);
            } else {
              return Icon(Icons.star_border, color: starColor, size: size);
            }
          }),
        ),
        if (showLabel) ...[
          const SizedBox(width: 8),
          Text(
            label ?? rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.8,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ],
      ],
    );
  }
}