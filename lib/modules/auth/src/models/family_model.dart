// Model untuk response create family
class FamilyModel {
  final bool success;
  final Family family;
  final String message;

  FamilyModel({
    required this.success,
    required this.family,
    required this.message,
  });

  factory FamilyModel.fromJson(Map<String, dynamic> json) {
    return FamilyModel(
      success: json['success'] ?? false,
      family: Family.fromJson(json['family']),
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'family': family.toJson(), 'message': message};
  }
}

// Model untuk Family entity
class Family {
  final int id;
  final String name;
  final String familyCode;
  final int createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Family({
    required this.id,
    required this.name,
    required this.familyCode,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Family.fromJson(Map<String, dynamic> json) {
    return Family(
      id: json['id'],
      name: json['name'],
      familyCode: json['family_code'],
      createdBy: json['created_by'],
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'family_code': familyCode,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Helper methods
  String getDisplayName() {
    return name.isNotEmpty ? name : 'Unnamed Family';
  }

  String getFormattedCode() {
    return familyCode.toUpperCase();
  }

  bool isCreatedBy(int userId) {
    return createdBy == userId;
  }

  // Copy method untuk update data
  Family copyWith({
    int? id,
    String? name,
    String? familyCode,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Family(
      id: id ?? this.id,
      name: name ?? this.name,
      familyCode: familyCode ?? this.familyCode,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Family(id: $id, name: $name, familyCode: $familyCode, createdBy: $createdBy)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Family && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
