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
    // Handle both direct and nested turf data structure
    var turfId = 0;
    var turfName = '';
    var turfImageUrl = '';
    
    if (json['turf'] != null && json['turf'] is Map<String, dynamic>) {
      // If turf data is nested
      var turfData = json['turf'] as Map<String, dynamic>;
      turfId = turfData['id'] ?? 0;
      turfName = turfData['name'] ?? '';
      turfImageUrl = turfData['image_url'] ?? '';
    } else {
      // If turf data is flat
      turfId = json['turf_id'] ?? 0;
      turfName = json['turf_name'] ?? '';
      turfImageUrl = json['turf_image_url'] ?? '';
    }

    // Handle time slots that might be combined
    var startTime = '';
    var endTime = '';
    
    if (json['time_slot'] != null && json['time_slot'] is String) {
      // Split time slot like "14:00 - 15:00" into start and end times
      var parts = json['time_slot'].toString().split(' - ');
      if (parts.length == 2) {
        startTime = parts[0];
        endTime = parts[1];
      } else {
        startTime = json['time_slot'];
      }
    } else {
      startTime = json['start_time'] ?? '';
      endTime = json['end_time'] ?? '';
    }

    // Handle price data
    var price = 0.0;
    if (json['total_price'] != null) {
      price = json['total_price'] is int 
          ? json['total_price'].toDouble() 
          : double.tryParse(json['total_price'].toString()) ?? 0.0;
    } else if (json['price'] != null) {
      price = json['price'] is int 
          ? json['price'].toDouble() 
          : double.tryParse(json['price'].toString()) ?? 0.0;
    }

    // Get user data
    var userId = 0;
    if (json['user'] != null && json['user'] is Map<String, dynamic>) {
      userId = json['user']['id'] ?? 0;
    } else {
      userId = json['user_id'] ?? 0;
    }

    // Handle negotiation data
    var isNegotiable = false;
    var proposedPrice;
    var message;
    var ownerResponse;

    if (json['negotiation'] != null && json['negotiation'] is Map<String, dynamic>) {
      var negotiation = json['negotiation'] as Map<String, dynamic>;
      isNegotiable = true;
      proposedPrice = negotiation['proposed_price'] != null 
          ? (negotiation['proposed_price'] is int 
              ? negotiation['proposed_price'].toDouble() 
              : double.tryParse(negotiation['proposed_price'].toString()))
          : null;
      message = negotiation['message'];
      ownerResponse = negotiation['is_accepted'] != null 
          ? (negotiation['is_accepted'] ? 'accepted' : 'rejected') 
          : null;
    } else {
      isNegotiable = json['is_negotiable'] ?? false;
      proposedPrice = json['proposed_price'] != null 
          ? (json['proposed_price'] is int 
              ? json['proposed_price'].toDouble() 
              : double.tryParse(json['proposed_price'].toString()))
          : null;
      message = json['message'];
      ownerResponse = json['owner_response'];
    }

    return Booking(
      id: json['id'],
      userId: userId,
      turfId: turfId,
      turfName: turfName,
      turfImageUrl: turfImageUrl,
      bookingDate: json['booking_date'] ?? '',
      startTime: startTime,
      endTime: endTime,
      price: price,
      status: json['status'] ?? '',
      paymentMethod: json['payment_method'],
      isPaid: json['is_paid'] ?? false,
      isNegotiable: isNegotiable,
      proposedPrice: proposedPrice,
      message: message,
      createdAt: json['created_at'] ?? '',
      ownerResponse: ownerResponse,
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
  
  bool get userCanRespond {
    if (status != 'negotiating') return false;
    // User can respond if the latest negotiation is from the owner
    return proposedPrice != null && ownerResponse != null;
  }
  
  bool get ownerCanRespond {
    if (status != 'negotiating') return false;
    // Owner can respond if the latest negotiation is from the user
    return proposedPrice != null && ownerResponse == null;
  }

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
  
  // Formatted time slot getter for display purposes
  String get formattedTimeSlot => timeRange;
}