class Turf {
  final int id;
  final String name;
  final String? description;
  final String address;
  final String city;
  final String? state;
  final String? country;
  final String? postalCode;
  final double? latitude;
  final double? longitude;
  final double basePricePerHour;
  final List<String>? features;
  final String? size;
  final bool indoor;
  final double? avgRating;
  final int? reviewCount;
  final String? surfaceType;
  final bool? hasParking;
  final bool? hasChangingRoom;
  final bool? hasShower;
  final bool? hasFloodlights;
  final bool? hasEquipment;
  final bool? hasRefreshments;
  final String? primaryImage;
  final List<String>? images;
  final Map<String, dynamic>? owner;
  
  // Owner-specific properties
  final int? totalBookings;
  final int? pendingBookings;
  final int? activeNegotiations;
  final String? createdAt;

  Turf({
    required this.id,
    required this.name,
    this.description,
    required this.address,
    required this.city,
    this.state,
    this.country,
    this.postalCode,
    this.latitude,
    this.longitude,
    required this.basePricePerHour,
    this.features,
    this.size,
    required this.indoor,
    this.avgRating,
    this.reviewCount,
    this.surfaceType,
    this.hasParking,
    this.hasChangingRoom,
    this.hasShower,
    this.hasFloodlights,
    this.hasEquipment,
    this.hasRefreshments,
    this.primaryImage,
    this.images,
    this.owner,
    this.totalBookings,
    this.pendingBookings,
    this.activeNegotiations,
    this.createdAt,
  });

  // Factory method for general turf listings
  factory Turf.fromJson(Map<String, dynamic> json) {
    return Turf(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      city: json['city'],
      basePricePerHour: json['base_price_per_hour']?.toDouble() ?? 0.0,
      features: json['features'] != null 
          ? List<String>.from(json['features']) 
          : null,
      size: json['size'],
      indoor: json['indoor'] ?? false,
      avgRating: json['avg_rating']?.toDouble(),
      reviewCount: json['rating_count'],
      surfaceType: json['surface_type'],
      hasParking: json['has_parking'],
      hasChangingRoom: json['has_changing_room'],
      hasShower: json['has_shower'],
      hasFloodlights: json['has_floodlights'],
      hasEquipment: json['has_equipment'],
      primaryImage: json['image'],
    );
  }

  // Factory method for detailed turf information
  factory Turf.fromDetailJson(Map<String, dynamic> json) {
    return Turf(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      postalCode: json['postal_code'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      basePricePerHour: json['base_price_per_hour']?.toDouble() ?? 0.0,
      features: json['features'] != null 
          ? List<String>.from(json['features']) 
          : null,
      size: json['size'],
      indoor: json['indoor'] ?? false,
      avgRating: json['avg_rating']?.toDouble(),
      reviewCount: json['rating_count'],
      surfaceType: json['surface_type'],
      hasParking: json['has_parking'],
      hasChangingRoom: json['has_changing_room'],
      hasShower: json['has_shower'],
      hasFloodlights: json['has_floodlights'],
      hasEquipment: json['has_equipment'],
      hasRefreshments: json['has_refreshments'],
      primaryImage: json['primary_image'],
      images: json['images'] != null 
          ? List<String>.from(json['images']) 
          : null,
      owner: json['owner'],
    );
  }

  // Factory method for owner turfs
  factory Turf.fromOwnerJson(Map<String, dynamic> json) {
    return Turf(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      city: json['city'],
      basePricePerHour: json['base_price_per_hour']?.toDouble() ?? 0.0,
      indoor: json['indoor'] ?? false,
      avgRating: json['rating']?.toDouble(),
      reviewCount: json['review_count'],
      primaryImage: json['image'],
      totalBookings: json['total_bookings'],
      pendingBookings: json['pending_bookings'],
      activeNegotiations: json['active_negotiations'],
      createdAt: json['created_at'],
    );
  }

  // Convert turf to a map for JSON serialization
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
      'latitude': latitude,
      'longitude': longitude,
      'base_price_per_hour': basePricePerHour,
      'features': features,
      'size': size,
      'indoor': indoor,
      'avg_rating': avgRating,
      'review_count': reviewCount,
      'surface_type': surfaceType,
      'has_parking': hasParking,
      'has_changing_room': hasChangingRoom,
      'has_shower': hasShower,
      'has_floodlights': hasFloodlights,
      'has_equipment': hasEquipment,
      'has_refreshments': hasRefreshments,
      'primary_image': primaryImage,
      'images': images,
    };
  }
}