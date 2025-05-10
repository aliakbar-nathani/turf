class Negotiation {
  final int id;
  final int bookingId;
  final int? userId;
  final int? turfOwnerId;
  final double originalAmount;
  final double currentAmount;
  final double? counterAmount;
  final String status;
  final String message;
  final String? createdAt;
  final String? updatedAt;
  
  // Related data
  final String? turfName;
  final String? userName;
  final String? ownerName;
  final String? bookingDate;
  final String? timeSlot;
  
  Negotiation({
    required this.id,
    required this.bookingId,
    this.userId,
    this.turfOwnerId,
    required this.originalAmount,
    required this.currentAmount,
    this.counterAmount,
    required this.status,
    required this.message,
    this.createdAt,
    this.updatedAt,
    this.turfName,
    this.userName,
    this.ownerName,
    this.bookingDate,
    this.timeSlot,
  });
  
  factory Negotiation.fromJson(Map<String, dynamic> json) {
    return Negotiation(
      id: json['id'],
      bookingId: json['booking_id'],
      userId: json['user_id'],
      turfOwnerId: json['turf_owner_id'],
      originalAmount: json['original_amount'].toDouble(),
      currentAmount: json['current_amount'].toDouble(),
      counterAmount: json['counter_amount']?.toDouble(),
      status: json['status'],
      message: json['message'] ?? '',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      turfName: json['turf_name'],
      userName: json['user_name'],
      ownerName: json['owner_name'],
      bookingDate: json['booking_date'],
      timeSlot: json['time_slot'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'user_id': userId,
      'turf_owner_id': turfOwnerId,
      'original_amount': originalAmount,
      'current_amount': currentAmount,
      'counter_amount': counterAmount,
      'status': status,
      'message': message,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'turf_name': turfName,
      'user_name': userName,
      'owner_name': ownerName,
      'booking_date': bookingDate,
      'time_slot': timeSlot,
    };
  }
  
  bool isPending() {
    return status.toLowerCase() == 'pending';
  }
  
  bool isAccepted() {
    return status.toLowerCase() == 'accepted';
  }
  
  bool isRejected() {
    return status.toLowerCase() == 'rejected';
  }
  
  bool isCounterOffer() {
    return status.toLowerCase() == 'counter_offer';
  }
  
  bool isFromOwner() {
    return turfOwnerId != null;
  }
  
  String getFormattedStatus() {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      case 'counter_offer':
        return 'Counter Offer';
      default:
        return status;
    }
  }
  
  double getDiscountPercentage() {
    if (originalAmount <= 0) return 0;
    return ((originalAmount - currentAmount) / originalAmount) * 100;
  }
}