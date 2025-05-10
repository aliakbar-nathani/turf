class Booking {
  final int id;
  final int turfId;
  final int userId;
  final String bookingDate;
  final String startTime;
  final String endTime;
  final double totalPrice;
  final double? originalPrice;
  final String status;
  final String? paymentStatus;
  final String? paymentMethod;
  final String? createdAt;
  final String? updatedAt;
  
  // Related data
  final String? turfName;
  final String? turfAddress;
  final String? turfCity;
  final String? userName;
  final String? userPhone;
  final bool? hasNegotiation;
  final bool? hasReview;
  
  Booking({
    required this.id,
    required this.turfId,
    required this.userId,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    this.originalPrice,
    required this.status,
    this.paymentStatus,
    this.paymentMethod,
    this.createdAt,
    this.updatedAt,
    this.turfName,
    this.turfAddress,
    this.turfCity,
    this.userName,
    this.userPhone,
    this.hasNegotiation = false,
    this.hasReview = false,
  });
  
  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      turfId: json['turf_id'],
      userId: json['user_id'],
      bookingDate: json['booking_date'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      totalPrice: json['total_price'].toDouble(),
      originalPrice: json['original_price']?.toDouble(),
      status: json['status'],
      paymentStatus: json['payment_status'],
      paymentMethod: json['payment_method'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      turfName: json['turf_name'],
      turfAddress: json['turf_address'],
      turfCity: json['turf_city'],
      userName: json['user_name'],
      userPhone: json['user_phone'],
      hasNegotiation: json['has_negotiation'] ?? false,
      hasReview: json['has_review'] ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'turf_id': turfId,
      'user_id': userId,
      'booking_date': bookingDate,
      'start_time': startTime,
      'end_time': endTime,
      'total_price': totalPrice,
      'original_price': originalPrice,
      'status': status,
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'turf_name': turfName,
      'turf_address': turfAddress,
      'turf_city': turfCity,
      'user_name': userName,
      'user_phone': userPhone,
      'has_negotiation': hasNegotiation,
      'has_review': hasReview,
    };
  }
  
  bool isPending() {
    return status.toLowerCase() == 'pending';
  }
  
  bool isNegotiating() {
    return status.toLowerCase() == 'negotiating';
  }
  
  bool isPaymentPending() {
    return status.toLowerCase() == 'payment_pending';
  }
  
  bool isConfirmed() {
    return status.toLowerCase() == 'confirmed';
  }
  
  bool isCompleted() {
    return status.toLowerCase() == 'completed';
  }
  
  bool isCancelled() {
    return status.toLowerCase() == 'cancelled';
  }
  
  bool isExpired() {
    return status.toLowerCase() == 'expired';
  }
  
  String getFormattedStatus() {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'negotiating':
        return 'Negotiating';
      case 'payment_pending':
        return 'Payment Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'expired':
        return 'Expired';
      default:
        return status;
    }
  }
  
  String getFormattedTimeSlot() {
    return '$startTime - $endTime';
  }
}