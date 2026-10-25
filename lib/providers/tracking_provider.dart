import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/location_update_model.dart';
import '../data/repositories/tracking_repository.dart';
import '../data/services/tracking_service.dart';
import 'di_providers.dart';

final trackingServiceProvider = Provider<TrackingService>((ref) {
  return TrackingService(ref.read(apiClientProvider));
});

final trackingRepositoryProvider = Provider<TrackingRepository>((ref) {
  return TrackingRepository(ref.read(trackingServiceProvider));
});

class TrackingNotifier
    extends StateNotifier<AsyncValue<TrackingLocationData?>> {
  final TrackingRepository _repository;

  TrackingNotifier(this._repository) : super(const AsyncValue.data(null));

  /// Sends updated location coordinates to backend
  Future<LocationUpdateResponse?> updateLocation({
    required double latitude,
    required double longitude,
    double heading = 0.0,
    double speed = 0.0,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _repository.updateLocation(
        latitude: latitude,
        longitude: longitude,
        heading: heading,
        speed: speed,
      );
      state = AsyncValue.data(response.data);
      return response;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final trackingProvider = StateNotifierProvider<TrackingNotifier,
    AsyncValue<TrackingLocationData?>>((ref) {
  return TrackingNotifier(ref.read(trackingRepositoryProvider));
});
