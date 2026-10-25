class EmergencyContact {
  final String id;
  final String name;
  final String phoneNumber;
  final String relationship;
  final bool isPrimary;
  final bool sendSosAlerts;
  final bool autoShareRides;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    required this.isPrimary,
    required this.sendSosAlerts,
    required this.autoShareRides,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      relationship: json['relationship'] ?? 'other',
      isPrimary: json['isPrimary'] ?? false,
      sendSosAlerts: json['sendSosAlerts'] ?? false,
      autoShareRides: json['autoShareRides'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'relationship': relationship,
      'isPrimary': isPrimary,
      'sendSosAlerts': sendSosAlerts,
      'autoShareRides': autoShareRides,
    };
  }
}
