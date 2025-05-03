class User {
  final int id;
  final String username;
  final String email;
  final String phoneNumber;
  final String role;
  final String? profileImage;
  final int? favoriteCount;
  final int? bookingCount;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.profileImage,
    this.favoriteCount,
    this.bookingCount,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      role: json['role'],
      profileImage: json['profile_image'],
      favoriteCount: json['favorite_count'],
      bookingCount: json['booking_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone_number': phoneNumber,
      'role': role,
      'profile_image': profileImage,
      'favorite_count': favoriteCount,
      'booking_count': bookingCount,
    };
  }

  User copyWith({
    int? id,
    String? username,
    String? email,
    String? phoneNumber,
    String? role,
    String? profileImage,
    int? favoriteCount,
    int? bookingCount,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      profileImage: profileImage ?? this.profileImage,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      bookingCount: bookingCount ?? this.bookingCount,
    );
  }
}