import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/di_providers.dart';

/// Login state
class LoginState {
  final String phoneNumber;
  final String? devOtp; // OTP returned from backend in dev mode
  final String? error;
  final bool isSubmitting;

  const LoginState({
    this.phoneNumber = '',
    this.devOtp,
    this.error,
    this.isSubmitting = false,
  });

  LoginState copyWith({
    String? phoneNumber,
    String? devOtp,
    String? error,
    bool? isSubmitting,
  }) {
    return LoginState(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      devOtp: devOtp ?? this.devOtp,
      error: error,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

/// Login ViewModel — sends OTP via real backend API.
class LoginViewModel extends StateNotifier<LoginState> {
  final Ref _ref;

  LoginViewModel(this._ref) : super(const LoginState());

  void updatePhoneNumber(String value) {
    state = state.copyWith(phoneNumber: value, error: null);
  }

  bool validate() {
    if (state.phoneNumber.length < 10) {
      state = state.copyWith(error: 'Enter a valid 10-digit WhatsApp number');
      return false;
    }
    return true;
  }

  /// Sends OTP to the phone number via backend.
  Future<String?> sendOTP() async {
    if (!validate()) return null;

    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final authRepo = _ref.read(authRepositoryProvider);
      final result = await authRepo.sendOTP(state.phoneNumber);

      // In dev mode, backend returns OTP in the response
      final devOtp = result['otp']?.toString();
      state = state.copyWith(isSubmitting: false, devOtp: devOtp);
      return devOtp ?? 'sent';
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: _extractError(e),
      );
      return null;
    }
  }

  String _extractError(dynamic e) {
    final msg = e.toString();
    if (msg.length > 100) return 'An unexpected error occurred. Please try again.';
    return msg.replaceAll('Exception: ', '');
  }
}

final loginViewModelProvider =
    StateNotifierProvider.autoDispose<LoginViewModel, LoginState>((ref) {
  return LoginViewModel(ref);
});
