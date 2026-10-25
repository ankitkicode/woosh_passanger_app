class SavedPlace {
  final String id;
  final String user;
  final String type; // home, work, other
  final String title;
  final String address;
  final double latitude;
  final double longitude;
  final String? landmark;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SavedPlace({
    required this.id,
    required this.user,
    required this.type,
    required this.title,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.landmark,
    this.createdAt,
    this.updatedAt,
  });

  factory SavedPlace.fromJson(Map<String, dynamic> json) {
    return SavedPlace(
      id: json['_id'] ?? '',
      user: json['user'] ?? '',
      type: json['type'] ?? 'other',
      title: json['title'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      landmark: json['landmark'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      if (user.isNotEmpty) 'user': user,
      'type': type,
      'title': title,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      if (landmark != null) 'landmark': landmark,
    };
  }
}
