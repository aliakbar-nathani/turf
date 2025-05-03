class Booking {
  final int id;
  final int userId;
  final int turfId;
  final String turfName;
  final String turfImageUrl;
  final String bookingDate;
  final String startTime;
  final String endTime;
  final double price;
  final String status;
  final String? paymentMethod;
  final bool isPaid;
  final bool isNegotiable;
  final double? proposedPrice;
  final String? message;
  final String createdAt;
  final String? ownerResponse;

  Booking({
    required this.id,
    required this.userId,
    required this.turfId,
    required this.turfName,
    required this.turfImageUrl,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.price,
    required this.status,
    this.paymentMethod,
    required this.isPaid,
    required this.isNegotiable,
    this.proposedPrice,
    this.message,
    required this.createdAt,
    this.ownerResponse,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      userId: json['user_id'],
      turfId: json['turf_id'],
      turfName: json['turf_name'],
      turfImageUrl: json['turf_image_url'] ?? '',
      bookingDate: json['booking_date'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      price: json['price'].toDouble(),
      status: json['status'],
      paymentMethod: json['payment_method'],
      isPaid: json['is_paid'] ?? false,
      isNegotiable: json['is_negotiable'] ?? false,
      proposedPrice: json['proposed_price']?.toDouble(),
      message: json['message'],
      createdAt: json['created_at'],
      ownerResponse: json['owner_response'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'turf_id': turfId,
      'turf_name': turfName,
      'turf_image_url': turfImageUrl,
      'booking_date': bookingDate,
      'start_time': startTime,
      'end_time': endTime,
      'price': price,
      'status': status,
      'payment_method': paymentMethod,
      'is_paid': isPaid,
      'is_negotiable': isNegotiable,
      'proposed_price': proposedPrice,
      'message': message,
      'created_at': createdAt,
      'owner_response': ownerResponse,
    };
  }

  bool get canCancel => 
    status == 'pending' || 
    status == 'negotiating' || 
    status == 'payment_pending';

  bool get canPay => status == 'payment_pending';

  bool get canNegotiate => status == 'negotiating';

  bool get isCompleted => status == 'completed';

  bool get isConfirmed => status == 'confirmed';

  bool get isPending => status == 'pending';

  String get formattedDate {
    // Convert YYYY-MM-DD to more readable format like "May 10, 2025"
    final parts = bookingDate.split('-');
    if (parts.length != 3) return bookingDate;
    
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June', 
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return '${months[month-1]} $day, $year';
  }

  String get timeRange => '$startTime - $endTime';
}