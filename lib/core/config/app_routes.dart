import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/views/splash_view.dart';
import '../../features/onboarding/views/verification_view.dart';
import '../../features/auth/views/login_view.dart';
import '../../features/auth/views/signup_view.dart';
import '../../features/auth/views/otp_view.dart';
import '../../features/home/views/home_map_view.dart';
import '../../features/home/views/search_destination_view.dart';
import '../../features/ride/views/confirm_ride_view.dart';
import '../../features/ride/views/searching_view.dart';
import '../../features/ride/views/rider_found_view.dart';
import '../../features/ride/views/active_ride_view.dart';
import '../../features/ride/views/ride_complete_view.dart';
import '../../features/profile/views/profile_view.dart';
import '../../features/profile/views/ride_history_view.dart';
import '../../features/profile/views/wallet_view.dart';
import '../../features/profile/views/edit_profile_view.dart';

class AppRoutes {
  AppRoutes._();

  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      // ── Auth & Onboarding ─────────────────────────────
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashView(),
      ),
      GoRoute(
        path: '/verification',
        builder: (context, state) => const VerificationView(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupView(),
      ),
      GoRoute(
        path: '/otp/:phone',
        builder: (context, state) {
          final phone = state.pathParameters['phone']!;
          return OtpView(phoneNumber: phone);
        },
      ),

      // ── Home ──────────────────────────────────────────
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeMapView(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchDestinationView(),
      ),

      // ── Ride Flow ─────────────────────────────────────
      GoRoute(
        path: '/confirm-ride',
        builder: (context, state) => const ConfirmRideView(),
      ),
      GoRoute(
        path: '/searching/:rideId',
        builder: (context, state) {
          final rideId = state.pathParameters['rideId']!;
          return SearchingRiderView(rideId: rideId);
        },
      ),
      GoRoute(
        path: '/rider-found/:rideId',
        builder: (context, state) {
          final rideId = state.pathParameters['rideId']!;
          return RiderFoundView(rideId: rideId);
        },
      ),
      GoRoute(
        path: '/ride-active/:rideId',
        builder: (context, state) {
          final rideId = state.pathParameters['rideId']!;
          return ActiveRideView(rideId: rideId);
        },
      ),
      GoRoute(
        path: '/ride-complete/:rideId',
        builder: (context, state) {
          final rideId = state.pathParameters['rideId']!;
          return RideCompleteView(rideId: rideId);
        },
      ),

      // ── Profile & More ────────────────────────────────
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileView(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileView(),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const RideHistoryView(),
      ),
      GoRoute(
        path: '/wallet',
        builder: (context, state) => const WalletView(),
      ),
    ],
  );
}
