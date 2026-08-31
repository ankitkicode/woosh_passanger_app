import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/woosh_brand_header.dart';
import '../../../shared/widgets/woosh_gradient_button.dart';
import '../../ride/view_models/ride_view_model.dart';

/// Confirm Ride Screen — exactly matches mockup design
class ConfirmRideView extends ConsumerStatefulWidget {
  const ConfirmRideView({super.key});

  @override
  ConsumerState<ConfirmRideView> createState() => _ConfirmRideViewState();
}

class _ConfirmRideViewState extends ConsumerState<ConfirmRideView> {
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rideViewModelProvider.notifier).estimateFare();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rideViewModelProvider);
    final notifier = ref.read(rideViewModelProvider.notifier);
    final pickup = state.pickup;
    final drop = state.drop;

    final markers = <Marker>{};
    if (pickup != null) {
      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(pickup.latitude, pickup.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Pickup'),
      ));
    }
    if (drop != null) {
      markers.add(Marker(
        markerId: const MarkerId('drop'),
        position: LatLng(drop.latitude, drop.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
        infoWindow: const InfoWindow(title: 'Drop'),
      ));
    }
    // Scooter icon near pickup
    if (pickup != null) {
      markers.add(Marker(
        markerId: const MarkerId('scooter'),
        position: LatLng(pickup.latitude + 0.002, pickup.longitude + 0.001),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: 'Nearby Rider'),
      ));
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
            const Text('Confirm Your Ride', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkText)),
            const SizedBox(height: 4),
            const Text('Almost there! Review your trip before booking.', style: TextStyle(fontSize: 13, color: AppColors.lightGray)),
            const SizedBox(height: 16),

            // ── Map Preview ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10)],
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
                    rotateGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                    mapToolbarEnabled: false,
                    onMapCreated: (c) {
                      _mapController = c;
                      // Delay to ensure map is ready before animating
                      Future.delayed(const Duration(milliseconds: 500), () {
                        _fitMapToBounds();
                      });
                    },
                  ),
                  // Duration chip on map
                  if (state.fareEstimate != null)
                    Positioned(
                      bottom: 12, left: 0, right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6)],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time, size: 14, color: AppColors.lightGray),
                              const SizedBox(width: 4),
                              Text(
                                '${state.fareEstimate!.durationMinutes} mins (${state.fareEstimate!.distanceKm.toStringAsFixed(1)} km)',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Pickup / Destination / Distance / Time / Fare ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.dividerColor),
                  boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)],
                ),
                child: Column(
                  children: [
                    // Pickup
                    _RideDetailRow(icon: Icons.circle, iconColor: AppColors.secondaryPurple, iconSize: 10,
                      label: 'Pickup', value: pickup?.address ?? 'Current Location', hasChevron: true),
                    const Padding(padding: EdgeInsets.only(left: 4), child: Divider(height: 20, indent: 16)),

                    // Destination
                    _RideDetailRow(icon: Icons.location_on, iconColor: AppColors.primaryPink, iconSize: 14,
                      label: 'Destination', value: drop?.address ?? '—', hasChevron: true),

                    if (state.fareEstimate != null) ...[
                      const Divider(height: 24),

                      // Distance
                      _FareInfoRow(icon: Icons.directions_walk, label: 'Distance',
                        value: '${state.fareEstimate!.distanceKm.toStringAsFixed(1)} km'),

                      const SizedBox(height: 8),

                      // Estimated Time
                      _FareInfoRow(icon: Icons.access_time, label: 'Estimated Time',
                        value: '${state.fareEstimate!.durationMinutes} mins'),

                      const SizedBox(height: 8),

                      // Estimated Fare — highlighted
                      Row(
                        children: [
                          const Icon(Icons.two_wheeler, size: 18, color: AppColors.primaryPink),
                          const SizedBox(width: 10),
                          const Text('Estimated Fare', style: TextStyle(fontSize: 14, color: AppColors.lightGray)),
                          const Spacer(),
                          Text(
                            '₹${state.fareEstimate!.fare.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryPink),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.info_outline, size: 14, color: AppColors.lightGray),
                        ],
                      ),
                    ] else if (state.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator(color: AppColors.primaryPink, strokeWidth: 2)),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Your Safety Comes First ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.lightPink,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28, height: 28,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.verified_user, color: AppColors.primaryPink, size: 16),
                        ),
                        const SizedBox(width: 8),
                        const Text('Your Safety Comes First', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryPink)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: const [
                        _SafetyFeature(icon: Icons.female, label: 'Verified\nWomen Rider'),
                        _SafetyFeature(icon: Icons.location_on, label: 'Live Ride\nTracking'),
                        _SafetyFeature(icon: Icons.sos, label: 'SOS\nEmergency'),
                        _SafetyFeature(icon: Icons.people, label: 'Share Trip\nwith Family'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Payment Method ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.dividerColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined, color: AppColors.darkText, size: 22),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Payment Method', style: TextStyle(fontSize: 11, color: AppColors.lightGray)),
                        Text(
                          state.paymentMethod == 'cash' ? 'Cash' : 'Wallet',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: () => notifier.setPaymentMethod(state.paymentMethod == 'cash' ? 'wallet' : 'cash'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primaryPink),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('Change', style: TextStyle(color: AppColors.primaryPink, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Error ──
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: AppColors.errorRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.errorRed, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(state.error!, style: const TextStyle(color: AppColors.errorRed, fontSize: 13))),
                    ],
                  ),
                ),
              ),

            // ── Request a Ride ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: WooshGradientButton(
                text: 'Request a Ride',
                isLoading: state.isLoading,
                onPressed: state.fareEstimate != null
                    ? () async {
                        final rideId = await notifier.requestRide();
                        if (rideId != null && context.mounted) context.go('/searching/$rideId');
                      }
                    : null,
              ),
            ),

            const SizedBox(height: 10),
            // Safety guidelines
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 11, color: AppColors.lightGray),
                children: [
                  TextSpan(text: 'By booking this ride, you agree to Woosh\'s '),
                  TextSpan(text: 'Safety Guidelines', style: TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.bold)),
                  TextSpan(text: '.'),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _fitMapToBounds() {
    final state = ref.read(rideViewModelProvider);
    final pickup = state.pickup;
    final drop = state.drop;

    if (_mapController == null || pickup == null || drop == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        pickup.latitude < drop.latitude ? pickup.latitude : drop.latitude,
        pickup.longitude < drop.longitude ? pickup.longitude : drop.longitude,
      ),
      northeast: LatLng(
        pickup.latitude > drop.latitude ? pickup.latitude : drop.latitude,
        pickup.longitude > drop.longitude ? pickup.longitude : drop.longitude,
      ),
    );

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

class _RideDetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final double iconSize;
  final String label;
  final String value;
  final bool hasChevron;
  const _RideDetailRow({required this.icon, required this.iconColor, required this.iconSize, required this.label, required this.value, this.hasChevron = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: iconSize),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.lightGray)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkText)),
            ],
          ),
        ),
        if (hasChevron) const Icon(Icons.chevron_right, color: AppColors.lightGray, size: 20),
      ],
    );
  }
}

class _FareInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _FareInfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.lightGray),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.lightGray)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkText)),
      ],
    );
  }
}

class _SafetyFeature extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SafetyFeature({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppColors.primaryPink.withValues(alpha: 0.1), blurRadius: 4)],
          ),
          child: Icon(icon, color: AppColors.primaryPink, size: 20),
        ),
        const SizedBox(height: 6),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.darkText, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
