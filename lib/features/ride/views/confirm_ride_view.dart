import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/woosh_gradient_button.dart';
import '../../ride/view_models/ride_view_model.dart';

/// Confirm Ride Screen — Rapido-style map with target pin markers, address chips & add stop button
class ConfirmRideView extends ConsumerStatefulWidget {
  const ConfirmRideView({super.key});

  @override
  ConsumerState<ConfirmRideView> createState() => _ConfirmRideViewState();
}

class _ConfirmRideViewState extends ConsumerState<ConfirmRideView> {
  GoogleMapController? _mapController;
  BitmapDescriptor? _bikeMarkerIcon;
  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _dropIcon;
  BitmapDescriptor? _blueDotIcon;

  @override
  void initState() {
    super.initState();
    _loadMarkerIcons();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rideViewModelProvider.notifier).estimateFare();
    });
  }

  /// Generates target pin marker with vertical line stem (matches screenshot)
  Future<BitmapDescriptor> _createTargetMarkerIcon({
    required Color color,
    double radius = 16,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    const size = Size(40, 56);

    final center = Offset(size.width / 2, radius + 2);

    // Black vertical pin line
    final linePaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, Offset(size.width / 2, size.height - 2), linePaint);

    // Outer colored ring
    final outerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, outerPaint);

    // Middle white ring
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.55, whitePaint);

    // Inner colored dot
    canvas.drawCircle(center, radius * 0.32, outerPaint);

    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  /// Generates blue GPS location dot marker
  Future<BitmapDescriptor> _createBlueDotIcon() async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    const size = Size(32, 32);
    final center = Offset(size.width / 2, size.height / 2);

    // Outer white border
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 12, whitePaint);

    // Inner blue dot
    final bluePaint = Paint()
      ..color = const Color(0xFF1976D2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 9, bluePaint);

    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  Future<void> _loadMarkerIcons() async {
    final bikeIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(44, 44)),
      'assets/bike_marker.png',
    );
    final pickupIcon = await _createTargetMarkerIcon(
      color: const Color(0xFFE53935), // Target Red pin
    );
    final dropIcon = await _createTargetMarkerIcon(
      color: const Color(0xFF2E7D32), // Target Green pin
    );
    final blueDotIcon = await _createBlueDotIcon();

    if (mounted) {
      setState(() {
        _bikeMarkerIcon = bikeIcon;
        _pickupIcon = pickupIcon;
        _dropIcon = dropIcon;
        _blueDotIcon = blueDotIcon;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rideViewModelProvider);
    final notifier = ref.read(rideViewModelProvider.notifier);
    final pickup = state.pickup;
    final drop = state.drop;

    final markers = <Marker>{};

    // Pickup — red target pin with vertical stem line
    if (pickup != null) {
      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(pickup.latitude, pickup.longitude),
        icon: _pickupIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        anchor: const Offset(0.5, 1.0),
        infoWindow: InfoWindow(title: pickup.address ?? 'Pickup'),
      ));
    }

    // Dropoff — green target pin with vertical stem line
    if (drop != null) {
      markers.add(Marker(
        markerId: const MarkerId('drop'),
        position: LatLng(drop.latitude, drop.longitude),
        icon: _dropIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        anchor: const Offset(0.5, 1.0),
        infoWindow: InfoWindow(title: drop.address ?? 'Dropoff'),
      ));
    }

    // Cluster of riders / bikes & blue location dot near dropoff (matches screenshot cluster)
    if (drop != null) {
      final baseLat = drop.latitude;
      final baseLng = drop.longitude;

      final offsets = [
        const Offset(-0.0018, -0.0012),
        const Offset(-0.0012, -0.0022),
        const Offset(-0.0022, -0.0018),
        const Offset(-0.0015, -0.0028),
        const Offset(-0.0026, -0.0010),
      ];
      final rotations = [30.0, 75.0, -45.0, 120.0, 15.0];

      for (int i = 0; i < offsets.length; i++) {
        markers.add(Marker(
          markerId: MarkerId('rider_$i'),
          position: LatLng(baseLat + offsets[i].dx, baseLng + offsets[i].dy),
          icon: _bikeMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          anchor: const Offset(0.5, 0.5),
          rotation: rotations[i],
        ));
      }

      // Blue current location GPS dot
      markers.add(Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(baseLat - 0.0019, baseLng - 0.0019),
        icon: _blueDotIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        anchor: const Offset(0.5, 0.5),
      ));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Safe Area top padding
            SizedBox(height: MediaQuery.of(context).padding.top + 8),

            // ── Full Map Card View ──
            Container(
              // margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: pickup != null ? LatLng(pickup.latitude, pickup.longitude) : const LatLng(23.2599, 77.4126),
                      zoom: 13,
                    ),
                    markers: markers,
                    polylines: pickup != null && drop != null ? {
                      Polyline(
                        polylineId: const PolylineId('route'),
                        color: const Color(0xFF1A1A1A), // solid dark black route line
                        width: 5,
                        points: [LatLng(pickup.latitude, pickup.longitude), LatLng(drop.latitude, drop.longitude)],
                      ),
                    } : {},
                    zoomControlsEnabled: false,
                    scrollGesturesEnabled: true,
                    rotateGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                    mapToolbarEnabled: false,
                    onMapCreated: (c) {
                      _mapController = c;
                      Future.delayed(const Duration(milliseconds: 500), () {
                        _fitMapToBounds();
                      });
                    },
                  ),

                  // ── Pickup Chip (Top Left) ──
                  if (pickup != null)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: _MapChip(
                        label: pickup.address != null && pickup.address!.length > 18
                            ? '${pickup.address!.substring(0, 15)}...'
                            : (pickup.address ?? 'Pickup'),
                        onEdit: () => context.push('/search-destination?focus=pickup&fromConfirm=true'),
                      ),
                    ),

                  // ── Dropoff Chip (Center / Middle Right) ──
                  if (drop != null)
                    Positioned(
                      top: 120,
                      right: 20,
                      child: _MapChip(
                        label: drop.address != null && drop.address!.length > 18
                            ? '${drop.address!.substring(0, 15)}...'
                            : (drop.address ?? 'Dropoff'),
                        onEdit: () => context.push('/search-destination?focus=drop&fromConfirm=true'),
                      ),
                    ),

                  // ── Bottom Left: Floating Back Button ──
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: GestureDetector(
                      onTap: () {
                        if (context.canPop()) context.pop();
                      },
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF1A1A1A),
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  // ── Bottom Right: + Add Stop Button & My Location Button ──
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _AddStopChip(
                          onTap: () => context.push('/search-destination?focus=drop&fromConfirm=true'),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _fitMapToBounds,
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.my_location,
                              color: Color(0xFF1976D2),
                              size: 20,
                            ),
                          ),
                        ),
                      ],
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
                    _RideDetailRow(
                      icon: Icons.circle,
                      iconColor: AppColors.secondaryPurple,
                      iconSize: 10,
                      label: 'Pickup',
                      value: pickup?.address ?? 'Current Location',
                      hasChevron: true,
                      onTap: () => context.push('/search-destination?focus=pickup&fromConfirm=true'),
                    ),
                    const Padding(padding: EdgeInsets.only(left: 4), child: Divider(height: 20, indent: 16)),

                    // Destination
                    _RideDetailRow(
                      icon: Icons.location_on,
                      iconColor: AppColors.primaryPink,
                      iconSize: 14,
                      label: 'Destination',
                      value: drop?.address ?? '—',
                      hasChevron: true,
                      onTap: () => context.push('/search-destination?focus=drop&fromConfirm=true'),
                    ),

                    if (state.fareEstimate != null) ...[
                      const Divider(height: 24),

                      // Distance
                      _FareInfoRow(
                        icon: Icons.directions_walk,
                        label: 'Distance',
                        value: '${state.fareEstimate!.distanceKm.toStringAsFixed(1)} km',
                      ),

                      const SizedBox(height: 8),

                      // Estimated Time
                      _FareInfoRow(
                        icon: Icons.access_time,
                        label: 'Estimated Time',
                        value: '${state.fareEstimate!.durationMinutes} mins',
                      ),

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
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryPink),
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
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.verified_user, color: AppColors.primaryPink, size: 16),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Your Safety Comes First',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryPink),
                          ),
                        ),
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
                text: 'Book Ride',
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
  final VoidCallback? onTap;

  const _RideDetailRow({
    required this.icon,
    required this.iconColor,
    required this.iconSize,
    required this.label,
    required this.value,
    this.hasChevron = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: iconSize),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: AppColors.lightGray)),
                  Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal, color: AppColors.darkText)),
                ],
              ),
            ),
            if (hasChevron) const Icon(Icons.chevron_right, color: AppColors.lightGray, size: 20),
          ],
        ),
      ),
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
          width: 44,
          height: 44,
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

/// Address chip with circular edit button overlaid on the map (matches screenshot)
class _MapChip extends StatelessWidget {
  final String label;
  final VoidCallback? onEdit;

  const _MapChip({
    required this.label,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: Color(0xFFF0F0F5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit,
                size: 13,
                color: Color(0xFF666666),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating "+ Add stop" button chip (matches screenshot diamond-plus style)
class _AddStopChip extends StatelessWidget {
  final VoidCallback? onTap;

  const _AddStopChip({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Diamond plus icon like screenshot
            Transform.rotate(
              angle: 0.785398, // 45 degrees
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Transform.rotate(
                  angle: -0.785398,
                  child: const Icon(
                    Icons.add,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Add stop',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
