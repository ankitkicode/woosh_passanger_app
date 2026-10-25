import 'package:geolocator/geolocator.dart';
import '../services/safety_service.dart';
import '../services/places_service.dart';

class SafetyRepository {
  final SafetyService _service;
  static const String _kGoogleApiKey = 'AIzaSyCfmd3W3DPh3jYOeYx41Bva9GIxCmpo7UY';

  SafetyRepository(this._service);

  Future<void> triggerSos({
    double? latitude,
    double? longitude,
    String? address,
    String? rideId,
  }) async {
    try {
      double lat = latitude ?? 28.6139;
      double lng = longitude ?? 77.2090;
      String addr = address ?? 'Connaught Place, New Delhi';

      // Dynamically fetch current position if latitude or longitude are not provided
      if (latitude == null || longitude == null) {
        try {
          bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (serviceEnabled) {
            LocationPermission permission = await Geolocator.checkPermission();
            if (permission == LocationPermission.denied) {
              permission = await Geolocator.requestPermission();
            }
            if (permission == LocationPermission.always ||
                permission == LocationPermission.whileInUse) {
              final position = await Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.high,
                ),
              );
              lat = position.latitude;
              lng = position.longitude;

              // Dynamically fetch address via reverse geocoding if address is not provided
              if (address == null) {
                try {
                  final placesService = PlacesService(_kGoogleApiKey);
                  addr = await placesService.getAddressFromCoordinates(lat, lng);
                } catch (_) {}
              }
            }
          }
        } catch (_) {}
      } else if (address == null) {
        // If latitude and longitude are provided but address is missing, fetch reverse geocoded address
        try {
          final placesService = PlacesService(_kGoogleApiKey);
          addr = await placesService.getAddressFromCoordinates(lat, lng);
        } catch (_) {}
      }

      await _service.triggerSos(
        latitude: lat,
        longitude: lng,
        address: addr,
        rideId: rideId,
      );
    } catch (e) {
      // Re-throw or handle as per app architecture
      rethrow;
    }
  }
}
