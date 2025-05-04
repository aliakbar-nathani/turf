class Booking {
  final int id;
  final int turfId;
  final String turfName;
  final String? turfImageUrl;
  final int userId;
  final String userName;
  final String bookingDate;
  final String startTime;
  final String endTime;
  final String status;
  final double totalAmount;
  final String paymentMethod;
  final bool isPaid;
  final String createdAt;
  final String? updatedAt;
  final String? message;
  final String? cancellationReason;
  final bool? userAttended;
  
  // Additional fields for convenience
  final String? location;
  final String? timeSlot;

  Booking({
    required this.id,
    required this.turfId,
    required this.turfName,
    this.turfImageUrl,
    required this.userId,
    required this.userName,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.totalAmount,
    required this.paymentMethod,
    required this.isPaid,
    required this.createdAt,
    this.updatedAt,
    this.message,
    this.cancellationReason,
    this.userAttended,
    this.location,
    this.timeSlot,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    // Format start_time and end_time if they exist
    String startTime = json['start_time'] ?? '';
    String endTime = json['end_time'] ?? '';
    
    // If we have a time_slot, extract time information
    String? timeSlot;
    if (json['time_slot'] != null) {
      timeSlot = '${json['time_slot']['start_time']} - ${json['time_slot']['end_time']}';
    }
    
    // Extract location information if available
    String? location;
    if (json['turf'] != null) {
      if (json['turf']['city'] != null) {
        location = json['turf']['city'];
        if (json['turf']['address'] != null) {
          location = '$location, ${json['turf']['address']}';
        }
      } else if (json['turf']['address'] != null) {
        location = json['turf']['address'];
      }
    }

    return Booking(
      id: json['id'],
      turfId: json['turf_id'],
      turfName: json['turf_name'] ?? '',
      turfImageUrl: json['turf_image_url'],
      userId: json['user_id'],
      userName: json['user_name'] ?? '',
      bookingDate: json['booking_date'],
      startTime: startTime,
      endTime: endTime,
      status: json['status'],
      totalAmount: json['total_amount']?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] ?? 'unknown',
      isPaid: json['is_paid'] ?? false,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      message: json['message'],
      cancellationReason: json['cancellation_reason'],
      userAttended: json['user_attended'],
      location: location,
      timeSlot: timeSlot ?? '$startTime - $endTime',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'turf_id': turfId,
      'turf_name': turfName,
      'turf_image_url': turfImageUrl,
      'user_id': userId,
      'user_name': userName,
      'booking_date': bookingDate,
      'start_time': startTime,
      'end_time': endTime,
      'status': status,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'is_paid': isPaid,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'message': message,
      'cancellation_reason': cancellationReason,
      'user_attended': userAttended,
    };
  }
}