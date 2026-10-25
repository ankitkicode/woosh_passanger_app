import 'package:dio/dio.dart';

class SafetyService {
  final Dio dio;

  SafetyService(this.dio);

  Future<Response> triggerSos({
    required double latitude,
    required double longitude,
    required String address,
    String? rideId,
  }) {
    return dio.post(
      '/tracking/sos',
      data: {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        if (rideId != null) 'rideId': rideId,
      },
    );
  }
}
