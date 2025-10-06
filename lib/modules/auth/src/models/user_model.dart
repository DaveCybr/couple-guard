class UserModel {
  final int id;
  final String email;
  final String? familyCode;
  final DateTime? createdAt; // ✅ Ubah menjadi nullable
  final String? token;

  UserModel({
    required this.id,
    required this.email,
    this.familyCode,
    this.createdAt, // ✅ Tidak required lagi
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      familyCode: json['family_code'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null, // ✅ Handle null
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'family_code': familyCode,
      'created_at': createdAt?.toIso8601String(), // ✅ Safe null access
      'token': token,
    };
  }
}
