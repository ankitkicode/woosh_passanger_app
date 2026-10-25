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
    final doc = json['_doc'] as Map<String, dynamic>? ?? json;
    final coords = doc['coordinates'] as List?;
    return RideLocation(
      latitude: coords != null
          ? (coords[1] as num).toDouble()
          : (doc['latitude'] as num? ?? 0.0).toDouble(),
      longitude: coords != null
          ? (coords[0] as num).toDouble()
          : (doc['longitude'] as num? ?? 0.0).toDouble(),
      address: doc['address'] as String?,
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
      name: (user['fullName'] ?? json['name'] ?? json['fullName'] ?? 'Rider')
          .toString(),
      photo: (user['photo'] ?? profile['profileImage'] ?? json['photo'])
          ?.toString(),
      rating: (profile['rating'] ?? json['rating'] ?? 4.5).toDouble(),
      totalRides:
          (profile['totalRidesCompleted'] ??
                  profile['totalRatings'] ??
                  json['totalRides'] ??
                  0)
              as int,
      vehicleNumber: (profile['vehicleNumber'] ?? json['vehicleNumber'] ?? '')
          .toString(),
      vehicleModel:
          (profile['vehicleModel'] ?? json['vehicleModel'] ?? 'Activa')
              .toString(),
      phoneNumber:
          (user['whatsappNumber'] ??
                  json['phoneNumber'] ??
                  json['whatsappNumber'] ??
                  '')
              .toString(),
    );
  }
}

class RiderPickupEstimate {
  final double distanceKm;
  final int etaMinutes;
  final String formattedDistance;
  final String formattedEta;

  const RiderPickupEstimate({
    required this.distanceKm,
    required this.etaMinutes,
    required this.formattedDistance,
    required this.formattedEta,
  });

  factory RiderPickupEstimate.fromJson(Map<String, dynamic> json) {
    return RiderPickupEstimate(
      distanceKm: (json['distanceKm'] as num? ?? 0.0).toDouble(),
      etaMinutes: (json['etaMinutes'] as num? ?? 0).toInt(),
      formattedDistance: (json['formattedDistance'] as String? ?? '').toString(),
      formattedEta: (json['formattedEta'] as String? ?? '').toString(),
    );
  }
}

class FareEstimate {
  final double distanceKm;
  final int durationMinutes;
  final double fare;
  final RiderPickupEstimate? riderPickup;

  const FareEstimate({
    required this.distanceKm,
    required this.durationMinutes,
    required this.fare,
    this.riderPickup,
  });

  String? get formattedEta => riderPickup?.formattedEta.isNotEmpty == true
      ? riderPickup!.formattedEta
      : (riderPickup?.etaMinutes != null && riderPickup!.etaMinutes > 0
          ? '${riderPickup!.etaMinutes} mins'
          : null);

  factory FareEstimate.fromJson(Map<String, dynamic> json) {
    // Handle both cases: if backend returns fare as a number directly, or as a FareOutput object
    final fareData = json['fare'];
    final double parsedFare = fareData is Map
        ? (fareData['totalFare'] as num? ?? 0.0).toDouble()
        : (fareData as num? ?? 0.0).toDouble();

    final riderPickupData = json['riderPickup'];

    return FareEstimate(
      distanceKm: (json['distanceKm'] as num? ?? 0.0).toDouble(),
      durationMinutes: (json['durationMinutes'] as num? ?? 0).toInt(),
      fare: parsedFare,
      riderPickup: riderPickupData is Map
          ? RiderPickupEstimate.fromJson(
              Map<String, dynamic>.from(riderPickupData),
            )
          : null,
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
  final String paymentStatus;
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
    required this.paymentStatus,
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
      fare:
          (json['finalFare'] as num? ??
                  json['fare'] as num? ??
                  json['estimatedFare'] as num? ??
                  0)
              .toDouble(),
      distanceKm: (json['distanceKm'] as num? ?? 0).toDouble(),
      durationMinutes: (json['durationMinutes'] as num? ?? 0).toInt(),
      paymentMethod: (json['paymentMethod'] ?? 'cash').toString(),
      paymentStatus: (json['paymentStatus'] ?? 'pending').toString(),
      rider: (json['rider'] is Map)
          ? RiderInfo.fromJson({
              ...(json['rider'] as Map<String, dynamic>),
              if (json['riderProfile'] is Map)
                'riderProfile': json['riderProfile'],
            })
          : null,
      rideOtp: json['otp']?.toString() ?? json['rideOtp']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
