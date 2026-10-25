import '../models/location_update_model.dart';
import '../services/tracking_service.dart';

class TrackingRepository {
  final TrackingService _service;

  TrackingRepository(this._service);

  /// Sends live GPS location data (latitude, longitude, heading, speed)
  Future<LocationUpdateResponse> updateLocation({
    required double latitude,
    required double longitude,
    double heading = 0.0,
    double speed = 0.0,
  }) async {
    final request = LocationUpdateRequest(
      latitude: latitude,
      longitude: longitude,
      heading: heading,
      speed: speed,
    );
    return await _service.updateLocation(request);
  }
}
