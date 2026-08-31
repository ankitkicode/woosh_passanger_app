import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/config/app_config.dart';

/// Configures and provides the Dio HTTP client instance.
/// Includes auth interceptor, token refresh, and logging.
class ApiClient {
  late final Dio dio;

  /// Callback to get the current access token
  final Future<String?> Function() getAccessToken;

  /// Callback to get the current refresh token
  final Future<String?> Function() getRefreshToken;

  /// Callback to save new tokens after a refresh
  final Future<void> Function(String accessToken, String refreshToken) onTokenRefreshed;

  /// Callback when token refresh fails (force logout)
  final Future<void> Function() onForceLogout;

  ApiClient({
    required this.getAccessToken,
    required this.getRefreshToken,
    required this.onTokenRefreshed,
    required this.onForceLogout,
  }) {
    dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(milliseconds: AppConfig.connectTimeout),
      receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeout),
      sendTimeout: const Duration(milliseconds: AppConfig.sendTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Auth interceptor — attach Bearer token
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Skip auth for public routes
        final publicPaths = ['/auth/send-otp', '/auth/verify-otp', '/auth/verify-gender', '/auth/refresh-token'];
        final isPublic = publicPaths.any((p) => options.path.contains(p));

        if (!isPublic) {
          final token = await getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Auto-refresh on 401
        if (error.response?.statusCode == 401 && !error.requestOptions.extra.containsKey('isRetry')) {
          try {
            final refreshTokenValue = await getRefreshToken();
            if (refreshTokenValue == null) {
              await onForceLogout();
              return handler.next(error);
            }

            // Call refresh endpoint
            final refreshResponse = await Dio(BaseOptions(
              baseUrl: AppConfig.baseUrl,
            )).post('/auth/refresh-token', data: {
              'refreshToken': refreshTokenValue,
            });

            final newAccessToken = refreshResponse.data['data']['accessToken'] as String;
            final newRefreshToken = refreshResponse.data['data']['refreshToken'] as String;

            await onTokenRefreshed(newAccessToken, newRefreshToken);

            // Retry the original request
            final retryOptions = error.requestOptions;
            retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
            retryOptions.extra['isRetry'] = true;

            final retryResponse = await dio.fetch(retryOptions);
            return handler.resolve(retryResponse);
          } catch (_) {
            await onForceLogout();
            return handler.next(error);
          }
        }
        handler.next(error);
      },
    ));

    // Logging interceptor (debug only)
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        requestHeader: false,
        responseHeader: false,
      ));
    }
  }

  // ──── Convenience methods ─────────────────────────────────────────────────

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) {
    return dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) {
    return dio.put(path, data: data);
  }

  Future<Response> delete(String path) {
    return dio.delete(path);
  }

  Future<Response> postFormData(String path, FormData formData) {
    return dio.post(path, data: formData);
  }
}
