/// User model matching the backend User schema.
class UserModel {
  final String id;
  final String phoneNumber;
  final String role;
  final String? name;
  final String? fullName;
  final String? whatsappNumber;
  final String? email;
  final String? gender;
  final bool isAadhaarVerified;
  final bool isFaceVerified;
  final bool isActive;
  final List<EmergencyContactModel> emergencyContacts;

  const UserModel({
    required this.id,
    required this.phoneNumber,
    required this.role,
    this.name,
    this.fullName,
    this.whatsappNumber,
    this.email,
    this.gender,
    this.isAadhaarVerified = false,
    this.isFaceVerified = false,
    this.isActive = true,
    this.emergencyContacts = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      phoneNumber: (json['phoneNumber'] ?? json['whatsappNumber'] ?? '').toString(),
      role: json['role'] as String? ?? 'passenger',
      name: json['name'] as String?,
      fullName: (json['fullName'] ?? json['name'] ?? json['phoneNumber'] ?? '').toString(),
      whatsappNumber: (json['whatsappNumber'] ?? json['phoneNumber'] ?? '').toString(),
      email: json['email'] as String?,
      gender: json['gender'] as String?,
      isAadhaarVerified: json['isAadhaarVerified'] as bool? ?? false,
      isFaceVerified: json['isFaceVerified'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      emergencyContacts: (json['emergencyContacts'] as List<dynamic>?)
              ?.map((e) => EmergencyContactModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'phoneNumber': phoneNumber,
      'role': role,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (gender != null) 'gender': gender,
      'isAadhaarVerified': isAadhaarVerified,
      'isFaceVerified': isFaceVerified,
      'isActive': isActive,
      'emergencyContacts': emergencyContacts.map((e) => e.toJson()).toList(),
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? gender,
    List<EmergencyContactModel>? emergencyContacts,
  }) {
    return UserModel(
      id: id,
      phoneNumber: phoneNumber,
      role: role,
      name: name ?? this.name,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      isAadhaarVerified: isAadhaarVerified,
      isFaceVerified: isFaceVerified,
      isActive: isActive,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
    );
  }
}

class EmergencyContactModel {
  final String name;
  final String phoneNumber;

  const EmergencyContactModel({
    required this.name,
    required this.phoneNumber,
  });

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      name: json['name'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
    };
  }
}
