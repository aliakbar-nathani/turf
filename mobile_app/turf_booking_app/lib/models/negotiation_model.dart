class Negotiation {
  final int id;
  final int bookingId;
  final String turfName;
  final String userName;
  final double originalAmount;
  final double currentAmount;
  final String status;
  final String? message;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Negotiation({
    required this.id,
    required this.bookingId,
    required this.turfName,
    required this.userName,
    required this.originalAmount,
    required this.currentAmount,
    required this.status,
    this.message,
    required this.createdAt,
    this.updatedAt,
  });

  factory Negotiation.fromJson(Map<String, dynamic> json) {
    return Negotiation(
      id: json['id'],
      bookingId: json['booking_id'],
      turfName: json['turf_name'],
      userName: json['user_name'],
      originalAmount: json['original_amount'].toDouble(),
      currentAmount: json['current_amount'].toDouble(),
      status: json['status'],
      message: json['message'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'turf_name': turfName,
      'user_name': userName,
      'original_amount': originalAmount,
      'current_amount': currentAmount,
      'status': status,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}