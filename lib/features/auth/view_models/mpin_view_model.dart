import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/di_providers.dart';

class MpinState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  MpinState({this.isLoading = false, this.error, this.isSuccess = false});

  MpinState copyWith({bool? isLoading, String? error, bool? isSuccess}) {
    return MpinState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class MpinViewModel extends StateNotifier<MpinState> {
  final Ref _ref;

  MpinViewModel(this._ref) : super(MpinState());

  String _extractError(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      final message = e.response?.data['message']?.toString();
      if (message != null && message.isNotEmpty) return message;
    }
    return e.toString().replaceAll('Exception: ', '');
  }

  Future<void> setMpin(String mpin, String confirmMpin) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = _ref.read(authRepositoryProvider);
      await repo.setMpin(mpin, confirmMpin);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  Future<void> verifyMpin(String mpin, String phoneNumber) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = _ref.read(authRepositoryProvider);
      final response = await repo.verifyMpin(mpin: mpin, phoneNumber: phoneNumber);
      _ref.read(authStateProvider.notifier).setAuthenticated(response.user);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  Future<void> changeMpin(String oldMpin, String newMpin, String confirmNewMpin) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = _ref.read(authRepositoryProvider);
      await repo.changeMpin(oldMpin, newMpin, confirmNewMpin);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  Future<void> forgotMpin(String phoneNumber, String otp, String newMpin, String confirmNewMpin) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = _ref.read(authRepositoryProvider);
      await repo.forgotMpin(phoneNumber, otp, newMpin, confirmNewMpin);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }
  
  Future<void> sendOtpForForgotMpin(String phoneNumber) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = _ref.read(authRepositoryProvider);
      await repo.sendOTP(phoneNumber, action: 'forgot-mpin');
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }
}

final mpinViewModelProvider = StateNotifierProvider.autoDispose<MpinViewModel, MpinState>((ref) {
  return MpinViewModel(ref);
});