import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/di_providers.dart';
import '../../../providers/auth_provider.dart';
import '../../ride/view_models/ride_view_model.dart';

class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Wait for minimum splash time
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final isLoggedIn = await authRepo.isLoggedIn();

      if (isLoggedIn) {
        final user = await authRepo.getSavedUser();
        if (user != null) {
          ref.read(authStateProvider.notifier).setAuthenticated(user);

          if (!mounted) return;

          // Check for active ride
          final rideViewModel = ref.read(rideViewModelProvider.notifier);
          final activeRide = await rideViewModel.checkActiveRide();

          if (mounted) {
            if (activeRide != null) {
              final status = activeRide.status.toLowerCase();
              if (status == 'pending') {
                context.go('/searching/${activeRide.id}');
              } else if (status == 'accepted' ||
                  status == 'rider_arrived' ||
                  status == 'arrived') {
                context.go('/rider-found/${activeRide.id}');
              } else if (status == 'started' || status == 'in_progress') {
                context.go('/ride-active/${activeRide.id}');
              } else if (status == 'completed' &&
                  activeRide.paymentStatus.toLowerCase() == 'pending') {
                context.go('/ride-complete/${activeRide.id}');
              } else {
                context.go('/home');
              }
            } else {
              context.go('/home');
            }
          }
          return;
        }
      }
    } catch (_) {
      // Ignore errors and fallback to unauthenticated state
    }

    if (mounted) context.go('/verification');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Image.asset('assets/splash.png', fit: BoxFit.cover),
      ),
    );
  }
}
