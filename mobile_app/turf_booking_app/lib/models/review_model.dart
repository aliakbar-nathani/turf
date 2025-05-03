class Review {
  final int id;
  final int rating;
  final String? comment;
  final int userId;
  final String username;
  final int turfId;
  final String turfName;
  final String createdAt;
  final String? ownerResponse;
  final String? ownerResponseDate;

  Review({
    required this.id,
    required this.rating,
    this.comment,
    required this.userId,
    required this.username,
    required this.turfId,
    required this.turfName,
    required this.createdAt,
    this.ownerResponse,
    this.ownerResponseDate,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      rating: json['rating'],
      comment: json['comment'],
      userId: json['user_id'],
      username: json['username'],
      turfId: json['turf_id'],
      turfName: json['turfName'],
      createdAt: json['created_at'],
      ownerResponse: json['owner_response'],
      ownerResponseDate: json['owner_response_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rating': rating,
      'comment': comment,
      'user_id': userId,
      'username': username,
      'turf_id': turfId,
      'turfName': turfName,
      'created_at': createdAt,
      'owner_response': ownerResponse,
      'owner_response_date': ownerResponseDate,
    };
  }
}