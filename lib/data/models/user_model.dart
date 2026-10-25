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
  final bool isMpinSet;
  final bool isActive;
  final String? profileImage;
  final String? dateOfBirth;
  final String? city;
  final String? state;
  final Map<String, dynamic>? preferences;
  final Map<String, dynamic>? safetySettings;
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
    this.profileImage,
    this.dateOfBirth,
    this.city,
    this.state,
    this.preferences,
    this.safetySettings,
    this.isAadhaarVerified = false,
    this.isFaceVerified = false,
    this.isMpinSet = false,
    this.isActive = true,
    this.emergencyContacts = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      phoneNumber: (json['phoneNumber'] ?? json['whatsappNumber'] ?? '')
          .toString(),
      role: json['role'] as String? ?? 'passenger',
      name: json['name'] as String?,
      fullName: (json['fullName'] ?? json['name'] ?? json['phoneNumber'] ?? '')
          .toString(),
      whatsappNumber: (json['whatsappNumber'] ?? json['phoneNumber'] ?? '')
          .toString(),
      email: json['email'] as String?,
      gender: json['gender'] as String?,
      profileImage: json['profileImage'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      preferences: json['preferences'] as Map<String, dynamic>?,
      safetySettings: json['safetySettings'] as Map<String, dynamic>?,
      isAadhaarVerified: json['isAadhaarVerified'] as bool? ?? false,
      isFaceVerified: json['isFaceVerified'] as bool? ?? false,
      isMpinSet: json['isMpinSet'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      emergencyContacts:
          (json['emergencyContacts'] as List<dynamic>?)
              ?.map(
                (e) =>
                    EmergencyContactModel.fromJson(e as Map<String, dynamic>),
              )
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
      if (profileImage != null) 'profileImage': profileImage,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (preferences != null) 'preferences': preferences,
      if (safetySettings != null) 'safetySettings': safetySettings,
      'isAadhaarVerified': isAadhaarVerified,
      'isFaceVerified': isFaceVerified,
      'isMpinSet': isMpinSet,
      'isActive': isActive,
      'emergencyContacts': emergencyContacts.map((e) => e.toJson()).toList(),
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? gender,
    String? profileImage,
    String? dateOfBirth,
    String? city,
    String? state,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? safetySettings,
    bool? isMpinSet,
    List<EmergencyContactModel>? emergencyContacts,
  }) {
    return UserModel(
      id: id,
      phoneNumber: phoneNumber,
      role: role,
      name: name ?? this.name,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      profileImage: profileImage ?? this.profileImage,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      city: city ?? this.city,
      state: state ?? this.state,
      preferences: preferences ?? this.preferences,
      safetySettings: safetySettings ?? this.safetySettings,
      isAadhaarVerified: isAadhaarVerified,
      isFaceVerified: isFaceVerified,
      isMpinSet: isMpinSet ?? this.isMpinSet,
      isActive: isActive,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
    );
  }
}

class EmergencyContactModel {
  final String? id;
  final String name;
  final String phoneNumber;
  final String? relationship;
  final bool isPrimary;
  final bool sendSosAlerts;
  final bool autoShareRides;

  const EmergencyContactModel({
    this.id,
    required this.name,
    required this.phoneNumber,
    this.relationship,
    this.isPrimary = false,
    this.sendSosAlerts = false,
    this.autoShareRides = false,
  });

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      id: json['_id'] as String?,
      name: json['name'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      relationship: json['relationship'] as String?,
      isPrimary: json['isPrimary'] as bool? ?? false,
      sendSosAlerts: json['sendSosAlerts'] as bool? ?? false,
      autoShareRides: json['autoShareRides'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      if (relationship != null) 'relationship': relationship,
      'isPrimary': isPrimary,
      'sendSosAlerts': sendSosAlerts,
      'autoShareRides': autoShareRides,
    };
  }
}
