// lib/features/auth/data/auth_model.dart

class UserModel {
  final int    id;
  final String name;
  final String email;
  final String role;
  final String token;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id:    json['id']    as int,
    name:  json['name']  as String,
    email: json['email'] as String,
    role:  json['role']  ?? 'user',
    token: json['token'] as String,
  );
}
