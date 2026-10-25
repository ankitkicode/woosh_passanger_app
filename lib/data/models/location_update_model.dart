/// Request model for updating live GPS location (/tracking/update-location)
class LocationUpdateRequest {
  final double latitude;
  final double longitude;
  final double heading;
  final double speed;

  const LocationUpdateRequest({
    required this.latitude,
    required this.longitude,
    this.heading = 0.0,
    this.speed = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'heading': heading,
        'speed': speed,
      };
}

/// Data payload in location update response
class TrackingLocationData {
  final List<double> coordinates;
  final double latitude;
  final double longitude;
  final double heading;
  final double speed;
  final bool isOnline;

  const TrackingLocationData({
    required this.coordinates,
    required this.latitude,
    required this.longitude,
    required this.heading,
    required this.speed,
    required this.isOnline,
  });

  factory TrackingLocationData.fromJson(Map<String, dynamic> json) {
    final rawCoords = json['coordinates'] as List?;
    final coordsList = rawCoords != null
        ? rawCoords.map((e) => (e as num).toDouble()).toList()
        : <double>[];

    return TrackingLocationData(
      coordinates: coordsList,
      latitude: (json['latitude'] as num? ??
              (coordsList.length >= 2 ? coordsList[1] : 0.0))
          .toDouble(),
      longitude: (json['longitude'] as num? ??
              (coordsList.isNotEmpty ? coordsList[0] : 0.0))
          .toDouble(),
      heading: (json['heading'] as num? ?? 0.0).toDouble(),
      speed: (json['speed'] as num? ?? 0.0).toDouble(),
      isOnline: json['isOnline'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'coordinates': coordinates,
        'latitude': latitude,
        'longitude': longitude,
        'heading': heading,
        'speed': speed,
        'isOnline': isOnline,
      };
}

/// Full response object for /tracking/update-location
class LocationUpdateResponse {
  final bool success;
  final int statusCode;
  final String message;
  final TrackingLocationData? data;

  const LocationUpdateResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory LocationUpdateResponse.fromJson(Map<String, dynamic> json) {
    return LocationUpdateResponse(
      success: json['success'] as bool? ?? false,
      statusCode: (json['statusCode'] as num? ?? 200).toInt(),
      message: json['message'] as String? ?? '',
      data: json['data'] != null
          ? TrackingLocationData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'statusCode': statusCode,
        'message': message,
        'data': data?.toJson(),
      };
}
