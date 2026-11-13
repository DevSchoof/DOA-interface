import 'enums/user_role.dart';

class User {
  final String id;
  final String email;
  final UserRole role;
  final bool isActive; // suspensão pelo administrador
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.role,
    this.isActive = true,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'].toString(),
    email: json['email'] as String,
    role: UserRole.fromString(json['role'] as String?),
    isActive: json['isActive'] as bool? ?? true,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'role': role.apiValue,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
  };
}
