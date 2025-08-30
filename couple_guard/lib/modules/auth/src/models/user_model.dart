class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final bool isEmailVerified;
  final int? partnerId;
  final String? partnerName;
  final String? parentCode; // 🔹 Tambahkan ini
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    required this.isEmailVerified,
    this.partnerId,
    this.partnerName,
    this.parentCode, // 🔹 tambahkan di constructor
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      avatar: json['avatar'],
      isEmailVerified: json['is_email_verified'] ?? false,
      partnerId: json['partner_id'],
      partnerName: json['partner_name'],
      parentCode: json['parentCode'], // 🔹 ambil dari json
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'is_email_verified': isEmailVerified,
      'partner_id': partnerId,
      'partner_name': partnerName,
      'parentCode': parentCode, // 🔹 simpan ke json
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
