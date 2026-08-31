import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/config/app_config.dart';
import '../data/services/api_client.dart';
import '../data/services/auth_service.dart';
import '../data/repositories/auth_repository.dart';
import 'auth_provider.dart';

// ──── Secure Storage ────
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});

// ──── API Client ────
final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.read(secureStorageProvider);

  return ApiClient(
    getAccessToken: () => storage.read(key: AppConfig.accessTokenKey),
    getRefreshToken: () => storage.read(key: AppConfig.refreshTokenKey),
    onTokenRefreshed: (accessToken, refreshToken) async {
      await storage.write(key: AppConfig.accessTokenKey, value: accessToken);
      await storage.write(key: AppConfig.refreshTokenKey, value: refreshToken);
    },
    onForceLogout: () async {
      await storage.delete(key: AppConfig.accessTokenKey);
      await storage.delete(key: AppConfig.refreshTokenKey);
      await storage.delete(key: AppConfig.userDataKey);
      ref.read(authStateProvider.notifier).logout();
    },
  );
});

// ──── Dio Instance ────
final dioProvider = Provider<Dio>((ref) {
  return ref.read(apiClientProvider).dio;
});

// ──── Auth Service ────
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(dioProvider));
});

// ──── Auth Repository ────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.read(authServiceProvider),
    ref.read(secureStorageProvider),
  );
});
