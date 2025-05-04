class Turf {
  final int id;
  final String name;
  final String description;
  final String address;
  final String city;
  final String state;
  final String country;
  final String? postalCode;
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
  final String? surfaceType;
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
    this.postalCode,
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
    this.surfaceType,
    required this.imageUrl,
    required this.additionalImages,
    this.averageRating,
    this.reviewCount,
    required this.ownerId,
    required this.ownerName,
    this.isFavorite = false,
  });

  factory Turf.fromJson(Map<String, dynamic> json) {
    // Handle the owner data which might be in different formats
    int ownerId = 0;
    String ownerName = 'Unknown';
    
    if (json['owner'] != null) {
      // Handle when owner is an object with id and username
      ownerId = json['owner']['id'] ?? 0;
      ownerName = json['owner']['username'] ?? 'Unknown';
    } else {
      // Handle when owner_id and owner_name are separate fields
      ownerId = json['owner_id'] ?? 0;
      ownerName = json['owner_name'] ?? 'Unknown';
    }
    
    // Handle images in different formats
    String imageUrl = '';
    List<String> additionalImagesList = [];
    
    if (json['image'] != null) {
      // Single image field
      imageUrl = json['image'];
    } else if (json['image_url'] != null) {
      // image_url field
      imageUrl = json['image_url'];
    } else if (json['primary_image'] != null) {
      // primary_image field
      imageUrl = json['primary_image'];
    }
    
    // Handle additional images
    if (json['images'] != null) {
      additionalImagesList = List<String>.from(json['images']);
    } else if (json['additional_images'] != null) {
      additionalImagesList = List<String>.from(json['additional_images']);
    }
    
    return Turf(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      address: json['address'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      postalCode: json['postal_code'] ?? '',
      basePricePerHour: json['base_price_per_hour']?.toDouble() ?? 0.0,
      features: List<String>.from(json['features'] ?? []),
      size: json['size'],
      indoor: json['indoor'] ?? false,
      hasParking: json['has_parking'] ?? false,
      hasChangingRoom: json['has_changing_room'] ?? false,
      hasShower: json['has_shower'] ?? false,
      hasFloodlights: json['has_floodlights'] ?? false,
      hasEquipment: json['has_equipment'] ?? false,
      hasRefreshments: json['has_refreshments'] ?? false,
      surfaceType: json['surface_type'],
      imageUrl: imageUrl,
      additionalImages: additionalImagesList,
      averageRating: json['avg_rating']?.toDouble() ?? json['average_rating']?.toDouble(),
      reviewCount: json['rating_count'] ?? json['review_count'] ?? 0,
      ownerId: ownerId,
      ownerName: ownerName,
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