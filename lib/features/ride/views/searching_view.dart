import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/woosh_brand_header.dart';
import '../../../shared/widgets/woosh_gradient_button.dart';
import '../../ride/view_models/ride_view_model.dart';
import '../../../data/services/socket_service.dart';

/// Finding Your Rider screen — matches mockup exactly
class SearchingRiderView extends ConsumerStatefulWidget {
  final String rideId;
  const SearchingRiderView({super.key, required this.rideId});

  @override
  ConsumerState<SearchingRiderView> createState() => _SearchingRiderViewState();
}

class _SearchingRiderViewState extends ConsumerState<SearchingRiderView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _startListening();
  }

  void _startListening() {
    // Primary: Listen via Socket for instant update
    SocketService().onRideAccepted((data) {
      if (data['rideId'] == widget.rideId && mounted) {
        _pollTimer?.cancel();
        context.go('/rider-found/${widget.rideId}');
      }
    });

    // Fallback: Poll every 5 seconds in case socket misses it
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final ride = await ref.read(rideViewModelProvider.notifier).getRideDetails(widget.rideId);
      if (ride != null && ride.status == 'accepted' && mounted) {
        _pollTimer?.cancel();
        context.go('/rider-found/${widget.rideId}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rideViewModelProvider);
    final pickup = state.pickup;
    final drop = state.drop;

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
            const Text('Finding Your Rider', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkText)),
            const SizedBox(height: 4),
            const Text('Looking for a nearby verified women rider for you...', style: TextStyle(fontSize: 13, color: AppColors.lightGray)),
            const SizedBox(height: 16),

            // ── Map Preview with badges ──
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
                    zoomControlsEnabled: false,
                    scrollGesturesEnabled: false,
                    mapToolbarEnabled: false,
                  ),
                  // Bottom badges
                  Positioned(
                    bottom: 12, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_user, color: AppColors.primaryPink, size: 14),
                          const SizedBox(width: 4),
                          const Text('Only verified\nwomen riders', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time, color: AppColors.lightGray, size: 14),
                          const SizedBox(width: 4),
                          const Text('Usually takes\n30-60 sec', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Animated search icon ──
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (_, __) {
                return SizedBox(
                  width: 120, height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.scale(
                        scale: _pulseAnimation.value * 1.1,
                        child: Container(width: 110, height: 110, decoration: BoxDecoration(
                          shape: BoxShape.circle, color: AppColors.primaryPink.withValues(alpha: 0.06))),
                      ),
                      Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(width: 80, height: 80, decoration: BoxDecoration(
                          shape: BoxShape.circle, color: AppColors.primaryPink.withValues(alpha: 0.12))),
                      ),
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: AppColors.primaryPink, width: 2),
                        ),
                        child: const Icon(Icons.search, color: AppColors.primaryPink, size: 28),
                      ),
                      Positioned(
                        bottom: 16, right: 16,
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.brandGradient,
                          ),
                          child: const Icon(Icons.two_wheeler, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
            const Text("We're finding the best rider for you", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkText)),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Please wait while we match you with a nearby verified women rider.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.lightGray),
              ),
            ),

            const SizedBox(height: 28),

            // ── 4 Feature chips ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  _FeatureChip(icon: Icons.verified_user, label: 'Verified Riders', sub: '100% verified\nwomen riders', color: AppColors.primaryPink),
                  _FeatureChip(icon: Icons.location_on, label: 'Live Tracking', sub: 'Share your ride\nin real-time', color: AppColors.primaryPink),
                  _FeatureChip(icon: Icons.sos, label: 'Emergency Help', sub: 'One tap SOS\nfor your safety', color: AppColors.errorRed),
                  _FeatureChip(icon: Icons.headset_mic, label: '24x7 Support', sub: "We're here\nfor you", color: AppColors.primaryPink),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Safety priority text ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.lightPink,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24, height: 24,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.verified_user, color: AppColors.primaryPink, size: 14),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Your safety is our priority. We never compromise.',
                      style: TextStyle(fontSize: 12, color: AppColors.primaryPink, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Cancel Ride button ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.verifyButtonGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    _pollTimer?.cancel();
                    await ref.read(rideViewModelProvider.notifier).cancelRide(widget.rideId);
                    if (context.mounted) context.go('/home');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Cancel Ride', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('You can cancel anytime', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pollTimer?.cancel();
    SocketService().offRideAccepted();
    super.dispose();
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  const _FeatureChip({required this.icon, required this.label, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(sub, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: AppColors.lightGray)),
      ],
    );
  }
}
