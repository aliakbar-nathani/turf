class Turf {
  final int id;
  final String name;
  final String description;
  final String address;
  final String city;
  final String state;
  final String country;
  final String postalCode;
  final double basePricePerHour;
  final List<String> features;
  final String? size;
  final bool indoor;
  final bool hasParking;
  final bool hasChangingRoom;
  final bool hasShower;
  final bool hasFloodlights;
  final bool hasEquipment;
  final bool hasRefreshments;
  final String surfaceType;
  final String imageUrl;
  final List<String> additionalImages;
  final double? averageRating;
  final int? reviewCount;
  final int ownerId;
  final String ownerName;
  final bool isFavorite;

  Turf({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
    required this.basePricePerHour,
    required this.features,
    this.size,
    required this.indoor,
    required this.hasParking,
    required this.hasChangingRoom,
    required this.hasShower,
    required this.hasFloodlights,
    required this.hasEquipment,
    required this.hasRefreshments,
    required this.surfaceType,
    required this.imageUrl,
    required this.additionalImages,
    this.averageRating,
    this.reviewCount,
    required this.ownerId,
    required this.ownerName,
    this.isFavorite = false,
  });

  factory Turf.fromJson(Map<String, dynamic> json) {
    return Turf(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      address: json['address'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      postalCode: json['postal_code'],
      basePricePerHour: json['base_price_per_hour'].toDouble(),
      features: List<String>.from(json['features'] ?? []),
      size: json['size'],
      indoor: json['indoor'] ?? false,
      hasParking: json['has_parking'] ?? false,
      hasChangingRoom: json['has_changing_room'] ?? false,
      hasShower: json['has_shower'] ?? false,
      hasFloodlights: json['has_floodlights'] ?? false,
      hasEquipment: json['has_equipment'] ?? false,
      hasRefreshments: json['has_refreshments'] ?? false,
      surfaceType: json['surface_type'] ?? 'Other',
      imageUrl: json['image_url'] ?? '',
      additionalImages: List<String>.from(json['additional_images'] ?? []),
      averageRating: json['average_rating']?.toDouble(),
      reviewCount: json['review_count'],
      ownerId: json['owner_id'],
      ownerName: json['owner_name'] ?? 'Unknown',
      isFavorite: json['is_favorite'] ?? false,
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
      'features': features,
      'size': size,
      'indoor': indoor,
      'has_parking': hasParking,
      'has_changing_room': hasChangingRoom,
      'has_shower': hasShower,
      'has_floodlights': hasFloodlights,
      'has_equipment': hasEquipment,
      'has_refreshments': hasRefreshments,
      'surface_type': surfaceType,
      'image_url': imageUrl,
      'additional_images': additionalImages,
      'average_rating': averageRating,
      'review_count': reviewCount,
      'owner_id': ownerId,
      'owner_name': ownerName,
      'is_favorite': isFavorite,
    };
  }
}