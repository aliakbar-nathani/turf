import 'package:flutter/material.dart';

class RatingBarWidget extends StatelessWidget {
  final double rating;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const RatingBarWidget({
    super.key,
    required this.rating,
    this.size = 24.0,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final double i = index + 1;
        final bool isHalf = i - rating > 0 && i - rating < 1;
        final bool isFilled = i <= rating;

        return Icon(
          isHalf
              ? Icons.star_half
              : isFilled
                  ? Icons.star
                  : Icons.star_border,
          size: size,
          color: isFilled || isHalf
              ? activeColor ?? Colors.amber
              : inactiveColor ?? Colors.grey,
        );
      }),
    );
  }
}