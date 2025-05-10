class User {
  final int id;
  final String username;
  final String email;
  final String? phoneNumber;
  final String role;
  final String? profileImageUrl;
  final String createdAt;
  final String? updatedAt;
  final bool isActive;
  final Map<String, dynamic>? notificationSettings;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.phoneNumber,
    required this.role,
    this.profileImageUrl,
    required this.createdAt,
    this.updatedAt,
    required this.isActive,
    this.notificationSettings,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      role: json['role'],
      profileImageUrl: json['profile_image_url'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      isActive: json['is_active'] ?? true,
      notificationSettings: json['notification_settings'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone_number': phoneNumber,
      'role': role,
      'profile_image_url': profileImageUrl,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_active': isActive,
      'notification_settings': notificationSettings,
    };
  }

  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin';
  bool get isRegularUser => role == 'user';
}