import '../services/auth_service.dart';

class User {
  final int id;
  final String username;
  final String email;
  final String? phoneNumber;
  final String role;
  final String? profileImage;
  final bool? emailVerified;
  final String? createdAt;
  final Map<String, dynamic>? preferences;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.phoneNumber,
    required this.role,
    this.profileImage,
    this.emailVerified,
    this.createdAt,
    this.preferences,
  });

  UserRole get userRole {
    switch (role.toLowerCase()) {
      case 'owner':
        return UserRole.owner;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.user;
    }
  }

  bool isOwner() {
    return userRole == UserRole.owner;
  }

  bool isAdmin() {
    return userRole == UserRole.admin;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      role: json['role'] ?? 'user',
      profileImage: json['profile_image'],
      emailVerified: json['email_verified'],
      createdAt: json['created_at'],
      preferences: json['preferences'],
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
      'email_verified': emailVerified,
      'created_at': createdAt,
      'preferences': preferences,
    };
  }
}