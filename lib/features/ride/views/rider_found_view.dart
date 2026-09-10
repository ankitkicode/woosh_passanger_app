import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/woosh_brand_header.dart';
import '../../../shared/widgets/woosh_gradient_button.dart';
import '../../ride/view_models/ride_view_model.dart';
import '../../../data/services/socket_service.dart';

/// Rider Found Screen — matches mockup exactly
class RiderFoundView extends ConsumerStatefulWidget {
  final String rideId;
  const RiderFoundView({super.key, required this.rideId});

  @override
  ConsumerState<RiderFoundView> createState() => _RiderFoundViewState();
}

class _RiderFoundViewState extends ConsumerState<RiderFoundView> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rideViewModelProvider.notifier).getRideDetails(widget.rideId);
      
      // Listen via Socket for instant update
      SocketService().onRiderArrived((data) {
        if (data['rideId'] == widget.rideId && mounted) {
          ref.read(rideViewModelProvider.notifier).getRideDetails(widget.rideId);
        }
      });

      SocketService().onRideStarted((data) {
        if (data['rideId'] == widget.rideId && mounted) {
          _pollTimer?.cancel();
          context.go('/ride-active/${widget.rideId}');
        }
      });

      // Fallback: Poll every 5 seconds in case socket misses it
      _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        final ride = await ref.read(rideViewModelProvider.notifier).getRideDetails(widget.rideId);
        if (ride != null && ride.status == 'started' && mounted) {
          _pollTimer?.cancel();
          context.go('/ride-active/${widget.rideId}');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rideViewModelProvider);
    final ride = state.activeRide;
    final rider = ride?.rider;
    final pickup = state.pickup;
    final drop = state.drop;

    final markers = <Marker>{};
    if (pickup != null) {
      markers.add(Marker(markerId: const MarkerId('pickup'), position: LatLng(pickup.latitude, pickup.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet)));
    }
    if (drop != null) {
      markers.add(Marker(markerId: const MarkerId('drop'), position: LatLng(drop.latitude, drop.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose)));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header ──
            WooshBrandHeader(
              onBack: () { if (context.canPop()) context.pop(); },
            ),

            // ── Title ──
            const Text('Rider Found!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkText)),
            const SizedBox(height: 4),
            const Text("We've matched you with a verified women rider.", style: TextStyle(fontSize: 13, color: AppColors.lightGray)),
            const SizedBox(height: 16),

            // ── Map with route + arriving badge ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: pickup != null ? LatLng(pickup.latitude, pickup.longitude) : const LatLng(23.2599, 77.4126),
                      zoom: 12,
                    ),
                    markers: markers,
                    polylines: pickup != null && drop != null ? {
                      Polyline(
                        polylineId: const PolylineId('route'),
                        color: AppColors.primaryPink,
                        width: 4,
                        points: [LatLng(pickup.latitude, pickup.longitude), LatLng(drop.latitude, drop.longitude)],
                      ),
                    } : {},
                    zoomControlsEnabled: false,
                    scrollGesturesEnabled: false,
                    mapToolbarEnabled: false,
                  ),
                  // Arriving badge or OTP
                  if (ride?.status == 'rider_arrived')
                    Positioned(
                      bottom: 12, right: 12, left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPink,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10)],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔒 Share this OTP with rider', style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                ride?.rideOtp ?? '----', 
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 8, color: AppColors.darkText)
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text('Rider will enter this to start', style: TextStyle(fontSize: 11, color: Colors.white70)),
                          ],
                        ),
                      ),
                    )
                  else
                    Positioned(
                      bottom: 12, right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6)],
                        ),
                        child: Column(
                          children: [
                            Text(ride?.status == 'accepted' ? 'Arriving in' : 'Status', style: const TextStyle(fontSize: 11, color: AppColors.primaryPink, fontWeight: FontWeight.w500)),
                            Text(ride?.status == 'accepted' ? '2 min' : 'Waiting...', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Rider Card ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.dividerColor),
                  boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)],
                ),
                child: Row(
                  children: [
                    // Photo
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.lightPink,
                        border: Border.all(color: AppColors.primaryPink, width: 2),
                      ),
                      child: rider?.photo != null
                          ? ClipOval(child: Image.network(rider!.photo!, fit: BoxFit.cover, width: 56, height: 56))
                          : const Icon(Icons.person, color: AppColors.primaryPink, size: 28),
                    ),
                    const SizedBox(width: 12),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(rider?.name ?? 'Neha Sharma', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 4),
                              Container(
                                width: 18, height: 18,
                                decoration: const BoxDecoration(color: AppColors.primaryPink, shape: BoxShape.circle),
                                child: const Icon(Icons.check, color: Colors.white, size: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 14),
                              const SizedBox(width: 2),
                              Text('${rider?.rating ?? 4.9} (${rider?.totalRides ?? 128} rides)',
                                style: const TextStyle(fontSize: 12, color: AppColors.lightGray)),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                width: 14, height: 14,
                                decoration: BoxDecoration(color: AppColors.lightPink, shape: BoxShape.circle),
                                child: const Icon(Icons.verified_user, color: AppColors.primaryPink, size: 10),
                              ),
                              const SizedBox(width: 4),
                              Text('${rider?.vehicleModel ?? 'Activa 6G'}  •  ${rider?.vehicleNumber ?? 'MP 04 ZY 1234'}',
                                style: const TextStyle(fontSize: 12, color: AppColors.lightGray)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Vehicle image placeholder
                    const Icon(Icons.two_wheeler, size: 44, color: AppColors.borderPink),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Action Buttons: Call, Chat, Share Trip, Emergency ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _ActionBtn(icon: Icons.phone, label: 'Call', color: AppColors.successGreen,
                    onTap: () async {
                      if (rider?.phoneNumber != null && rider!.phoneNumber.isNotEmpty) {
                        await launchUrl(Uri.parse('tel:${rider.phoneNumber}'));
                      }
                    }),
                  const SizedBox(width: 8),
                  _ActionBtn(icon: Icons.chat_bubble_outline, label: 'Chat', color: AppColors.secondaryPurple, onTap: () {}),
                  const SizedBox(width: 8),
                  _ActionBtn(icon: Icons.share, label: 'Share Trip', color: AppColors.primaryPink, onTap: () {}),
                  const SizedBox(width: 8),
                  _ActionBtn(icon: Icons.sos, label: 'Emergency', color: AppColors.errorRed,
                    onTap: () async {
                      if (ride != null) {
                        await ref.read(rideViewModelProvider.notifier).triggerSOS(ride.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('🚨 SOS Triggered! Emergency contacts notified.'),
                            backgroundColor: AppColors.errorRed,
                          ));
                        }
                      }
                    }),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Verified women rider notice ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.lightPink,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.verified_user, color: AppColors.primaryPink, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${rider?.name ?? 'Neha'} is a verified women rider.',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkText)),
                          const Text('You can view full details after the ride.',
                            style: TextStyle(fontSize: 11, color: AppColors.lightGray)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.lightGray, size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ── Your Safety Matters ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FFF4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.check_circle, color: AppColors.successGreen, size: 16),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your Safety Matters', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.successGreen)),
                          Text('Share your trip and live location with your loved ones.',
                            style: TextStyle(fontSize: 11, color: AppColors.lightGray)),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: null,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.successGreen),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('Share Now', style: TextStyle(color: AppColors.successGreen, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ── Thank you note ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.lightPink,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.female, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Thank you for choosing Woosh.',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryPink)),
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: AppColors.successGreen, size: 12),
                              SizedBox(width: 4),
                              Expanded(child: Text('We are here to make every ride safe and comfortable for you.',
                                style: TextStyle(fontSize: 11, color: AppColors.lightGray))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Ride Details Button ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: WooshGradientButton(
                text: 'Ride Details',
                onPressed: () => context.push('/ride-active/${widget.rideId}'),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    ref.read(rideViewModelProvider.notifier).stopPolling();
    super.dispose();
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.dividerColor),
          ),
          child: Column(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 6),
              Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
