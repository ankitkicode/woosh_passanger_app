import '../models/location_update_model.dart';
import 'api_client.dart';

class TrackingService {
  final ApiClient _apiClient;

  TrackingService(this._apiClient);

  /// Updates live GPS location on backend via POST /tracking/update-location
  Future<LocationUpdateResponse> updateLocation(
      LocationUpdateRequest request) async {
    final response = await _apiClient.post(
      '/tracking/update-location',
      data: request.toJson(),
    );
    return LocationUpdateResponse.fromJson(
        response.data as Map<String, dynamic>);
  }
}
