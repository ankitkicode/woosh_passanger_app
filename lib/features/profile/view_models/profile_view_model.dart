import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/di_providers.dart';

class ProfileState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? data;

  ProfileState({this.isLoading = false, this.error, this.data});

  ProfileState copyWith({bool? isLoading, String? error, Map<String, dynamic>? data}) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      data: data ?? this.data,
    );
  }
}

class ProfileViewModel extends StateNotifier<ProfileState> {
  final Ref _ref;

  ProfileViewModel(this._ref) : super(ProfileState()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = _ref.read(apiClientProvider);
      final response = await api.get('/passenger/profile');
      state = state.copyWith(isLoading: false, data: response.data['data'] as Map<String, dynamic>?);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final profileViewModelProvider = StateNotifierProvider<ProfileViewModel, ProfileState>((ref) {
  return ProfileViewModel(ref);
});
