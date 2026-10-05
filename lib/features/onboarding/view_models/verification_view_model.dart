import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../providers/di_providers.dart';

class VerificationState {
  final String? selfiePath;
  final bool isVerifying;
  final bool isSuccess;
  final String? error;

  const VerificationState({
    this.selfiePath,
    this.isVerifying = false,
    this.isSuccess = false,
    this.error,
  });

  bool get isSelfieTaken => selfiePath != null;

  VerificationState copyWith({
    String? selfiePath,
    bool? isVerifying,
    bool? isSuccess,
    String? error,
  }) {
    return VerificationState(
      selfiePath: selfiePath ?? this.selfiePath,
      isVerifying: isVerifying ?? this.isVerifying,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error, // Can be null to clear error
    );
  }
}

class VerificationViewModel extends StateNotifier<VerificationState> {
  final Ref _ref;
  final ImagePicker _picker = ImagePicker();

  VerificationViewModel(this._ref) : super(const VerificationState());

  Future<void> takeSelfie() async {
    try {
      // Simulators have no camera — fall back to gallery so devs can still test the flow.
      final bool isSimulator = !kIsWeb && Platform.isIOS && !_hasRealCamera();

      final XFile? photo = await _picker.pickImage(
        source: isSimulator ? ImageSource.gallery : ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 50,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (photo != null) {
        state = state.copyWith(selfiePath: photo.path, error: null);
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Camera is not available on this device.',
      );
    }
  }

  /// Returns false when running on an iOS simulator (no real camera hardware).
  bool _hasRealCamera() {
    // On a real device the SIMULATOR_DEVICE_NAME env var is absent.
    // image_picker throws a PlatformException with code 'camera_access_denied'
    // or simply returns null on simulators; we use the env var as a lightweight check.
    return !Platform.environment.containsKey('SIMULATOR_DEVICE_NAME');
  }

  Future<void> verify() async {
    if (state.selfiePath == null) return;
    
    state = state.copyWith(isVerifying: true, error: null);
    
    try {
      final authRepo = _ref.read(authRepositoryProvider);
      final isFemale = await authRepo.verifyGender(state.selfiePath!);

      if (isFemale) {
        state = state.copyWith(isVerifying: false, isSuccess: true);
      } else {
        state = const VerificationState(
          error: 'Verification failed. This app is strictly for female passengers.',
        );
      }
    } catch (e) {
      final msg = e.toString();
      state = state.copyWith(
        isVerifying: false,
        error: msg.length > 100 
            ? 'An unexpected error occurred. Please try again.'
            : msg.replaceAll('Exception: ', ''),
      );
    }
  }
}

final verificationViewModelProvider =
    StateNotifierProvider.autoDispose<VerificationViewModel, VerificationState>((ref) {
  return VerificationViewModel(ref);
});
