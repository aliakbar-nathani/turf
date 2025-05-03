class Negotiation {
  final int id;
  final int bookingId;
  final double originalPrice;
  final double proposedPrice;
  final String status;  // 'pending', 'accepted', 'rejected', 'countered'
  final String? message;
  final String? ownerResponse;
  final double? counterOfferPrice;
  final String createdAt;
  final String? updatedAt;

  Negotiation({
    required this.id,
    required this.bookingId,
    required this.originalPrice,
    required this.proposedPrice,
    required this.status,
    this.message,
    this.ownerResponse,
    this.counterOfferPrice,
    required this.createdAt,
    this.updatedAt,
  });

  factory Negotiation.fromJson(Map<String, dynamic> json) {
    return Negotiation(
      id: json['id'],
      bookingId: json['booking_id'],
      originalPrice: json['original_price'].toDouble(),
      proposedPrice: json['proposed_price'].toDouble(),
      status: json['status'],
      message: json['message'],
      ownerResponse: json['owner_response'],
      counterOfferPrice: json['counter_offer_price']?.toDouble(),
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'original_price': originalPrice,
      'proposed_price': proposedPrice,
      'status': status,
      'message': message,
      'owner_response': ownerResponse,
      'counter_offer_price': counterOfferPrice,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isCountered => status == 'countered';
  bool get isPending => status == 'pending';

  double get discount => originalPrice - proposedPrice;
  double get discountPercentage => (discount / originalPrice) * 100;

  String get formattedDiscount => '${discountPercentage.toStringAsFixed(1)}%';
}