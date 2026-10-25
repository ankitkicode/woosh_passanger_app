import 'package:dio/dio.dart';
import '../models/user_model.dart';

/// Auth API service — raw HTTP calls to the backend.
class AuthService {
  final Dio _dio;

  AuthService(this._dio);

  /// POST /auth/verify-gender
  /// Uploads selfie and returns true if female
  Future<bool> verifyGender(String imagePath) async {
    final formData = FormData.fromMap({
      'selfie': await MultipartFile.fromFile(imagePath),
    });

    try {
      final response = await _dio.post('/auth/verify-gender', data: formData);
      return response.data['data']['isFemale'] == true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        return false; // Not a female
      }
      throw Exception(e.response?.data?['message'] ?? 'Verification failed');
    }
  }

  /// POST /auth/send-otp
  /// Returns the OTP in dev mode (backend exposes it in non-production).
  Future<Map<String, dynamic>> sendOTP(
    String phoneNumber, {
    String action = 'login',
  }) async {
    final response = await _dio.post(
      '/auth/send-otp',
      data: {'phoneNumber': phoneNumber, 'role': 'passenger', 'action': action},
    );
    return response.data as Map<String, dynamic>;
  }

  /// POST /auth/verify-otp
  /// Returns user, accessToken, refreshToken, isNewUser.
  Future<AuthResponse> verifyOTP({
    required String phoneNumber,
    required String otp,
    String role = 'passenger',
    String? deviceId,
    String? fcmToken,
    String? os,
    String? deviceModel,
  }) async {
    final response = await _dio.post(
      '/auth/verify-otp',
      data: {
        'phoneNumber': phoneNumber,
        'otp': otp,
        'role': role,
        if (deviceId != null) 'deviceId': deviceId,
        if (fcmToken != null) 'fcmToken': fcmToken,
        if (os != null) 'os': os,
        if (deviceModel != null) 'deviceModel': deviceModel,
      },
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return AuthResponse(
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      isNewUser: data['isNewUser'] as bool? ?? false,
    );
  }

  /// POST /auth/refresh-token
  Future<Map<String, dynamic>> refreshToken(
    String refreshToken, {
    String? deviceId,
  }) async {
    final response = await _dio.post(
      '/auth/refresh-token',
      data: {
        'refreshToken': refreshToken,
        if (deviceId != null) 'deviceId': deviceId,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  /// POST /auth/logout
  Future<void> logout({String? deviceId}) async {
    await _dio.post(
      '/auth/logout',
      data: {if (deviceId != null) 'deviceId': deviceId},
    );
  }

  /// POST /auth/set-mpin
  Future<Map<String, dynamic>> setMpin(String mpin, String confirmMpin) async {
    final response = await _dio.post(
      '/auth/set-mpin',
      data: {
        'mpin': mpin,
        'confirmMpin': confirmMpin,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// POST /auth/verify-mpin
  Future<AuthResponse> verifyMpin({
    required String mpin,
    required String phoneNumber,
  }) async {
    final response = await _dio.post(
      '/auth/verify-mpin',
      data: {
        'mpin': mpin,
        'phoneNumber': phoneNumber,
      },
    );
    
    final data = response.data['data'] as Map<String, dynamic>;
    return AuthResponse(
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      isNewUser: false, // verification means user exists
    );
  }

  /// POST /auth/change-mpin
  Future<Map<String, dynamic>> changeMpin(
      String oldMpin, String newMpin, String confirmNewMpin) async {
    final response = await _dio.post(
      '/auth/change-mpin',
      data: {
        'oldMpin': oldMpin,
        'newMpin': newMpin,
        'confirmNewMpin': confirmNewMpin,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// POST /auth/forgot-mpin
  Future<Map<String, dynamic>> forgotMpin(
      String phoneNumber, String otp, String newMpin, String confirmNewMpin) async {
    final response = await _dio.post(
      '/auth/forgot-mpin',
      data: {
        'phoneNumber': phoneNumber,
        'otp': otp,
        'newMpin': newMpin,
        'confirmNewMpin': confirmNewMpin,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}

/// Response model for verify-otp
class AuthResponse {
  final UserModel user;
  final String accessToken;
  final String refreshToken;
  final bool isNewUser;

  const AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.isNewUser,
  });
}
