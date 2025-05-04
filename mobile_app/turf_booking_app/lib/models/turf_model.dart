class Turf {
  final int id;
  final String name;
  final String? description;
  final String address;
  final String city;
  final String state;
  final String country;
  final String postalCode;
  final double basePricePerHour;
  final List<String>? features;
  final String? size;
  final bool? indoor;
  final bool? hasParking;
  final bool? hasChangingRoom;
  final bool? hasShower;
  final bool? hasFloodlights;
  final bool? hasEquipment;
  final String? surfaceType;
  final String? imageUrl;
  final List<String>? additionalImages;
  final double? rating;
  final int? reviewsCount;
  final int? ownerId;
  final String createdAt;
  final String? updatedAt;

  Turf({
    required this.id,
    required this.name,
    this.description,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
    required this.basePricePerHour,
    this.features,
    this.size,
    this.indoor,
    this.hasParking,
    this.hasChangingRoom,
    this.hasShower,
    this.hasFloodlights,
    this.hasEquipment,
    this.surfaceType,
    this.imageUrl,
    this.additionalImages,
    this.rating,
    this.reviewsCount,
    this.ownerId,
    required this.createdAt,
    this.updatedAt,
  });

  factory Turf.fromJson(Map<String, dynamic> json) {
    List<String>? features;
    if (json['features'] != null) {
      if (json['features'] is String) {
        features = (json['features'] as String).split(',').map((e) => e.trim()).toList();
      } else if (json['features'] is List) {
        features = (json['features'] as List).map((e) => e.toString()).toList();
      }
    }

    List<String>? additionalImages;
    if (json['additional_images'] != null) {
      if (json['additional_images'] is String) {
        additionalImages = (json['additional_images'] as String).split(',').map((e) => e.trim()).toList();
      } else if (json['additional_images'] is List) {
        additionalImages = (json['additional_images'] as List).map((e) => e.toString()).toList();
      }
    }

    return Turf(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      postalCode: json['postal_code'],
      basePricePerHour: json['base_price_per_hour'].toDouble(),
      features: features,
      size: json['size'],
      indoor: json['indoor'],
      hasParking: json['has_parking'],
      hasChangingRoom: json['has_changing_room'],
      hasShower: json['has_shower'],
      hasFloodlights: json['has_floodlights'],
      hasEquipment: json['has_equipment'],
      surfaceType: json['surface_type'],
      imageUrl: json['image_url'],
      additionalImages: additionalImages,
      rating: json['rating']?.toDouble(),
      reviewsCount: json['reviews_count'],
      ownerId: json['owner_id'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'postal_code': postalCode,
      'base_price_per_hour': basePricePerHour,
      'features': features?.join(', '),
      'size': size,
      'indoor': indoor,
      'has_parking': hasParking,
      'has_changing_room': hasChangingRoom,
      'has_shower': hasShower,
      'has_floodlights': hasFloodlights,
      'has_equipment': hasEquipment,
      'surface_type': surfaceType,
      'image_url': imageUrl,
      'additional_images': additionalImages?.join(', '),
      'rating': rating,
      'reviews_count': reviewsCount,
      'owner_id': ownerId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}