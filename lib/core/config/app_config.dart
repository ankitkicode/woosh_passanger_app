/// Woosh App Configuration
/// Single source of truth for API endpoints and app-wide config.
class AppConfig {
  AppConfig._();

  /// Base URL for the backend API.
  // /// 192.168.1.31 is your Mac's local IP, which works for both Emulator and Physical Device testing.
  // /// (10.0.2.2 only works for Android Emulator)
  // static const String baseUrl = 'http://192.168.1.31:5001/api/v1';

  static const String baseUrl = 'https://wooshride.in/api/v1'; 

  /// Connection timeout in milliseconds
  static const int connectTimeout = 15000;

  /// Receive timeout in milliseconds
  static const int receiveTimeout = 15000;

  /// Send timeout in milliseconds
  static const int sendTimeout = 10000;

  /// Secure storage keys
  static const String accessTokenKey = 'woosh_access_token';
  static const String refreshTokenKey = 'woosh_refresh_token';
  static const String deviceIdKey = 'woosh_device_id';
  static const String userDataKey = 'woosh_user_data';

  /// OTP length
  static const int otpLength = 6;

  /// OTP resend timer in seconds
  static const int otpResendSeconds = 45;

  /// Phone number length (India)
  static const int phoneNumberLength = 10;
}    
