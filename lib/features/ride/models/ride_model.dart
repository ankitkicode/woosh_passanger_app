/// Ride data models for the Woosh Passenger App

class RideLocation {
  final double latitude;
  final double longitude;
  final String? address;

  const RideLocation({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  factory RideLocation.fromJson(Map<String, dynamic> json) {
    final coords = json['coordinates'] as List?;
    return RideLocation(
      latitude: coords != null ? (coords[1] as num).toDouble() : (json['latitude'] as num).toDouble(),
      longitude: coords != null ? (coords[0] as num).toDouble() : (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      };
}

class RiderInfo {
  final String id;
  final String name;
  final String? photo;
  final double rating;
  final int totalRides;
  final String vehicleNumber;
  final String vehicleModel;
  final String phoneNumber;

  const RiderInfo({
    required this.id,
    required this.name,
    this.photo,
    required this.rating,
    required this.totalRides,
    required this.vehicleNumber,
    required this.vehicleModel,
    required this.phoneNumber,
  });

  factory RiderInfo.fromJson(Map<String, dynamic> json) {
    final profile = json['riderProfile'] as Map<String, dynamic>? ?? {};
    final user = json['user'] as Map<String, dynamic>? ?? json;
    return RiderInfo(
      id: (user['_id'] ?? json['_id'] ?? '').toString(),
      name: (user['fullName'] ?? json['fullName'] ?? 'Rider').toString(),
      photo: user['photo']?.toString() ?? json['photo']?.toString(),
      rating: (profile['rating'] ?? json['rating'] ?? 4.5).toDouble(),
      totalRides: (profile['totalRidesCompleted'] ?? json['totalRides'] ?? 0) as int,
      vehicleNumber: (profile['vehicleNumber'] ?? json['vehicleNumber'] ?? '').toString(),
      vehicleModel: (profile['vehicleModel'] ?? json['vehicleModel'] ?? 'Activa').toString(),
      phoneNumber: (user['whatsappNumber'] ?? json['whatsappNumber'] ?? '').toString(),
    );
  }
}

class FareEstimate {
  final double distanceKm;
  final int durationMinutes;
  final double fare;

  const FareEstimate({
    required this.distanceKm,
    required this.durationMinutes,
    required this.fare,
  });

  factory FareEstimate.fromJson(Map<String, dynamic> json) {
    // Handle both cases: if backend returns fare as a number directly, or as a FareOutput object
    final fareData = json['fare'];
    final double parsedFare = fareData is Map 
        ? (fareData['totalFare'] as num).toDouble() 
        : (fareData as num).toDouble();

    return FareEstimate(
      distanceKm: (json['distanceKm'] as num).toDouble(),
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      fare: parsedFare,
    );
  }
}

class RideModel {
  final String id;
  final String status;
  final RideLocation pickup;
  final RideLocation drop;
  final double fare;
  final double distanceKm;
  final int durationMinutes;
  final String paymentMethod;
  final RiderInfo? rider;
  final String? rideOtp;
  final DateTime? createdAt;

  const RideModel({
    required this.id,
    required this.status,
    required this.pickup,
    required this.drop,
    required this.fare,
    required this.distanceKm,
    required this.durationMinutes,
    required this.paymentMethod,
    this.rider,
    this.rideOtp,
    this.createdAt,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      pickup: RideLocation.fromJson(json['pickup'] as Map<String, dynamic>),
      drop: RideLocation.fromJson(json['drop'] as Map<String, dynamic>),
      fare: (json['finalFare'] as num? ?? json['fare'] as num? ?? json['estimatedFare'] as num? ?? 0).toDouble(),
      distanceKm: (json['distanceKm'] as num? ?? 0).toDouble(),
      durationMinutes: (json['durationMinutes'] as num? ?? 0).toInt(),
      paymentMethod: (json['paymentMethod'] ?? 'cash').toString(),
      rider: json['rider'] != null ? RiderInfo.fromJson(json['rider'] as Map<String, dynamic>) : null,
      rideOtp: json['otp']?.toString() ?? json['rideOtp']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }
}
