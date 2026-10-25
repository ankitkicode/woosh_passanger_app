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
import '../../features/profile/views/settings_view.dart';
import '../../features/profile/views/help_support_view.dart';
import '../../features/saved_places/views/saved_places_view.dart';
import '../../features/safety/views/safety_view.dart';
import '../../features/safety/views/emergency_contacts_view.dart';
import '../../features/safety/views/add_emergency_contact_view.dart';
import '../../features/safety/views/sos_active_view.dart';
import '../../features/support/views/support_tickets_view.dart';
import '../../features/support/views/create_ticket_view.dart';
import '../../features/support/views/ticket_chat_view.dart';
import '../../data/models/emergency_contact.dart';

import '../../features/auth/views/mpin/set_mpin_view.dart';
import '../../features/auth/views/mpin/verify_mpin_view.dart';
import '../../features/auth/views/mpin/change_mpin_view.dart';
import '../../features/auth/views/mpin/forgot_mpin_view.dart';

class AppRoutes {
  AppRoutes._();

  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      // ── Auth & Onboarding ─────────────────────────────
      GoRoute(path: '/splash', builder: (context, state) => const SplashView()),
      GoRoute(
        path: '/verification',
        builder: (context, state) => const VerificationView(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginView()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupView()),
      GoRoute(
        path: '/otp/:phone',
        builder: (context, state) {
          final phone = state.pathParameters['phone']!;
          return OtpView(phoneNumber: phone);
        },
      ),
      GoRoute(
        path: '/set-mpin',
        builder: (context, state) => const SetMpinView(),
      ),
      GoRoute(
        path: '/verify-mpin',
        builder: (context, state) {
          final phone = state.uri.queryParameters['phone'] ?? '';
          return VerifyMpinView(phoneNumber: phone);
        },
      ),
      GoRoute(
        path: '/change-mpin',
        builder: (context, state) => const ChangeMpinView(),
      ),
      GoRoute(
        path: '/forgot-mpin',
        builder: (context, state) {
          final phone = state.uri.queryParameters['phone'] ?? '';
          return ForgotMpinView(phoneNumber: phone);
        },
      ),

      // ── Home ──────────────────────────────────────────
      GoRoute(path: '/home', builder: (context, state) => const HomeMapView()),
      GoRoute(
        path: '/search',
        builder: (context, state) {
          final focus = state.uri.queryParameters['focus'] ?? 'drop';
          final fromConfirm =
              state.uri.queryParameters['fromConfirm'] == 'true';
          return SearchDestinationView(
            initialFocus: focus,
            fromConfirm: fromConfirm,
          );
        },
      ),
      GoRoute(
        path: '/search-destination',
        builder: (context, state) {
          final focus = state.uri.queryParameters['focus'] ?? 'drop';
          final fromConfirm =
              state.uri.queryParameters['fromConfirm'] == 'true';
          return SearchDestinationView(
            initialFocus: focus,
            fromConfirm: fromConfirm,
          );
        },
      ),
      GoRoute(path: '/safety', builder: (context, state) => const SafetyView()),
      GoRoute(
        path: '/emergency-contacts',
        builder: (context, state) => const EmergencyContactsView(),
      ),
      GoRoute(
        path: '/add-emergency-contact',
        builder: (context, state) {
          final contactToEdit = state.extra as EmergencyContact?;
          return AddEmergencyContactView(contactToEdit: contactToEdit);
        },
      ),

      GoRoute(
        path: '/sos-active',
        builder: (context, state) => const SosActiveView(),
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
        path: '/settings',
        builder: (context, state) => const SettingsView(),
      ),
      GoRoute(
        path: '/help-support',
        builder: (context, state) => const HelpSupportView(),
      ),
      GoRoute(
        path: '/saved-places',
        builder: (context, state) => const SavedPlacesView(),
      ),
      GoRoute(
        path: '/ride-history',
        builder: (context, state) => const RideHistoryView(),
      ),
      GoRoute(path: '/wallet', builder: (context, state) => const WalletView()),
      GoRoute(
        path: '/support/tickets',
        builder: (context, state) => const SupportTicketsView(),
      ),
      GoRoute(
        path: '/support/tickets/create',
        builder: (context, state) => CreateTicketView(rideId: state.uri.queryParameters['rideId']),
      ),
      GoRoute(
        path: '/support/tickets/:ticketId',
        builder: (context, state) {
          final ticketId = state.pathParameters['ticketId']!;
          return TicketChatView(ticketId: ticketId);
        },
      ),
    ],
  );
}
