class Review {
  final int id;
  final int userId;
  final String username;
  final int turfId;
  final int rating;
  final String comment;
  final String createdAt;
  final String? ownerResponse;
  final String? ownerResponseDate;

  Review({
    required this.id,
    required this.userId,
    required this.username,
    required this.turfId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.ownerResponse,
    this.ownerResponseDate,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      userId: json['user_id'],
      username: json['username'] ?? 'Anonymous',
      turfId: json['turf_id'],
      rating: json['rating'],
      comment: json['comment'] ?? '',
      createdAt: json['created_at'],
      ownerResponse: json['owner_response'],
      ownerResponseDate: json['owner_response_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'turf_id': turfId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt,
      'owner_response': ownerResponse,
      'owner_response_date': ownerResponseDate,
    };
  }

  String get formattedCreatedAt {
    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()} year(s) ago';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()} month(s) ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} day(s) ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour(s) ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute(s) ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return createdAt;
    }
  }

  String get formattedOwnerResponseDate {
    if (ownerResponseDate == null) return '';
    
    try {
      final date = DateTime.parse(ownerResponseDate!);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()} year(s) ago';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()} month(s) ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} day(s) ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour(s) ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute(s) ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return ownerResponseDate!;
    }
  }
}