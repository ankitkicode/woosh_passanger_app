import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/di_providers.dart';

/// OTP state
class OtpState {
  final List<String> otpDigits;
  final int timerSeconds;
  final bool isVerifying;
  final bool canResend;
  final String? error;

  final String? devOtp;

  OtpState({
    List<String>? otpDigits,
    this.timerSeconds = AppConfig.otpResendSeconds,
    this.isVerifying = false,
    this.canResend = false,
    this.error,
    this.devOtp,
  }) : otpDigits = otpDigits ?? List.generate(AppConfig.otpLength, (_) => '');

  OtpState copyWith({
    List<String>? otpDigits,
    int? timerSeconds,
    bool? isVerifying,
    bool? canResend,
    String? error,
    String? devOtp,
  }) {
    return OtpState(
      otpDigits: otpDigits ?? this.otpDigits,
      timerSeconds: timerSeconds ?? this.timerSeconds,
      isVerifying: isVerifying ?? this.isVerifying,
      canResend: canResend ?? this.canResend,
      error: error,
      devOtp: devOtp ?? this.devOtp,
    );
  }

  String get otpString => otpDigits.join();
  bool get isComplete => otpString.length == AppConfig.otpLength;
}

/// OTP ViewModel — verifies OTP via backend, stores tokens.
class OtpViewModel extends StateNotifier<OtpState> {
  final Ref _ref;
  final String phoneNumber;
  Timer? _timer;

  OtpViewModel(this._ref, this.phoneNumber) : super(OtpState()) {
    startTimer();
  }

  void startTimer() {
    _timer?.cancel();
    state = state.copyWith(timerSeconds: AppConfig.otpResendSeconds, canResend: false);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timerSeconds > 0) {
        state = state.copyWith(timerSeconds: state.timerSeconds - 1);
      } else {
        state = state.copyWith(canResend: true);
        _timer?.cancel();
      }
    });
  }

  void setDevOtp(String? otp) {
    if (otp != null && otp.isNotEmpty) {
      final digits = List.generate(AppConfig.otpLength, (i) => i < otp.length ? otp[i] : '');
      state = state.copyWith(devOtp: otp, otpDigits: digits);
    }
  }

  void updateDigit(int index, String value) {
    if (value.length > 1) value = value.substring(value.length - 1);
    final newDigits = List<String>.from(state.otpDigits);
    newDigits[index] = value;
    state = state.copyWith(otpDigits: newDigits, error: null);
  }

  /// Resend OTP
  Future<void> resendOTP() async {
    if (!state.canResend) return;
    try {
      final authRepo = _ref.read(authRepositoryProvider);
      final result = await authRepo.sendOTP(phoneNumber);
      final devOtp = result['data']?['otp']?.toString();
      if (devOtp != null && devOtp.isNotEmpty) {
        final digits = List.generate(AppConfig.otpLength, (i) => i < devOtp.length ? devOtp[i] : '');
        state = state.copyWith(devOtp: devOtp, otpDigits: digits);
      }
      startTimer();
    } catch (_) {
      state = state.copyWith(error: 'Failed to resend OTP');
    }
  }

  /// Verify OTP via backend → store tokens → update auth state.
  Future<bool> verify() async {
    final otp = state.otpString;
    if (otp.length < AppConfig.otpLength) {
      state = state.copyWith(error: 'Please enter the complete OTP');
      return false;
    }

    state = state.copyWith(isVerifying: true, error: null);
    try {
      final authRepo = _ref.read(authRepositoryProvider);
      final response = await authRepo.verifyOTP(
        phoneNumber: phoneNumber,
        otp: otp,
      );

      // Update global auth state
      _ref.read(authStateProvider.notifier).setAuthenticated(response.user);

      state = state.copyWith(isVerifying: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isVerifying: false,
        error: _extractError(e),
      );
      return false;
    }
  }

  String _extractError(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      final message = e.response?.data['message']?.toString();
      if (message != null && message.isNotEmpty) return message;
    }
    final msg = e.toString();
    if (msg.contains('Invalid OTP')) return 'Invalid OTP. Please try again.';
    if (msg.contains('expired')) return 'OTP has expired. Please resend.';
    
    // Fallback for long stack traces or unexpected errors
    if (msg.length > 100) return 'An unexpected error occurred. Please try again.';
    
    return msg.replaceAll('Exception: ', '');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Family provider — requires phone number to create.
final otpViewModelProvider =
    StateNotifierProvider.autoDispose.family<OtpViewModel, OtpState, String>((ref, phoneNumber) {
  return OtpViewModel(ref, phoneNumber);
});
