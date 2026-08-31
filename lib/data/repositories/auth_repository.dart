import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/config/app_config.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Auth Repository — orchestrates AuthService + SecureStorage.
/// Single source of truth for auth state persistence.
class AuthRepository {
  final AuthService _authService;
  final FlutterSecureStorage _secureStorage;

  AuthRepository(this._authService, this._secureStorage);

  // ──── Token Management ────

  Future<String?> getAccessToken() async {
    return _secureStorage.read(key: AppConfig.accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return _secureStorage.read(key: AppConfig.refreshTokenKey);
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await Future.wait([
      _secureStorage.write(key: AppConfig.accessTokenKey, value: accessToken),
      _secureStorage.write(key: AppConfig.refreshTokenKey, value: refreshToken),
    ]);
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _secureStorage.delete(key: AppConfig.accessTokenKey),
      _secureStorage.delete(key: AppConfig.refreshTokenKey),
      _secureStorage.delete(key: AppConfig.userDataKey),
    ]);
  }

  // ──── User Data ────

  Future<void> saveUser(UserModel user) async {
    await _secureStorage.write(
      key: AppConfig.userDataKey,
      value: jsonEncode(user.toJson()),
    );
  }

  Future<UserModel?> getSavedUser() async {
    final raw = await _secureStorage.read(key: AppConfig.userDataKey);
    if (raw == null) return null;
    return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  // ──── Auth Operations ────

  Future<bool> verifyGender(String imagePath) async {
    return _authService.verifyGender(imagePath);
  }

  /// Send OTP to phone number. Returns OTP in dev mode.
  Future<Map<String, dynamic>> sendOTP(String phoneNumber) async {
    return _authService.sendOTP(phoneNumber);
  }

  /// Verify OTP, store tokens + user, return AuthResponse.
  Future<AuthResponse> verifyOTP({
    required String phoneNumber,
    required String otp,
    String? deviceId,
  }) async {
    final response = await _authService.verifyOTP(
      phoneNumber: phoneNumber,
      otp: otp,
      role: 'passenger',
      deviceId: deviceId,
    );

    // Persist tokens and user
    await saveTokens(response.accessToken, response.refreshToken);
    await saveUser(response.user);

    return response;
  }

  /// Logout — clear tokens from storage and server.
  Future<void> logout({String? deviceId}) async {
    try {
      await _authService.logout(deviceId: deviceId);
    } catch (_) {
      // Silently fail if network error on logout
    }
    await clearTokens();
  }

  /// Check if user has a stored session (for auto-login on splash).
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
