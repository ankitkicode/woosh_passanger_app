import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';

/// Possible auth states
enum AuthStatus { initial, authenticated, unauthenticated, loading }

/// Auth state
class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
  });

  AuthState copyWith({AuthStatus? status, UserModel? user, String? error}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }
}

/// Auth state notifier — manages the global auth state.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  void setAuthenticated(UserModel user) {
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  void setUnauthenticated() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void setLoading() {
    state = state.copyWith(status: AuthStatus.loading);
  }

  void setError(String message) {
    state = state.copyWith(status: AuthStatus.unauthenticated, error: message);
  }

  void logout() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// Convenience provider for quick auth status checks.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).status == AuthStatus.authenticated;
});

/// Convenience provider for current user.
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authStateProvider).user;
});
