class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final bool isEmailVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? token; // 🔹 tambahin token

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    required this.isEmailVerified,
    required this.createdAt,
    required this.updatedAt,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      phone: json['phone'],
      isEmailVerified: json['email_verified_at'] != null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      token: json['token'], // 🔹 kalau API kasih token di level ini
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'is_email_verified': isEmailVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'token': token,
    };
  }
}
