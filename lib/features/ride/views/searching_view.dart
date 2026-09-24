import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../ride/view_models/ride_view_model.dart';
import '../../../data/services/socket_service.dart';

/// Finding Your Rider screen — Rapido-style map with target pin markers & chips
class SearchingRiderView extends ConsumerStatefulWidget {
  final String rideId;
  const SearchingRiderView({super.key, required this.rideId});

  @override
  ConsumerState<SearchingRiderView> createState() => _SearchingRiderViewState();
}

class _SearchingRiderViewState extends ConsumerState<SearchingRiderView>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  BitmapDescriptor? _bikeMarkerIcon;
  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _dropIcon;
  BitmapDescriptor? _blueDotIcon;

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
    _loadMarkerIcons();
    _startListening();
  }

  /// Generates target pin marker with vertical line stem (matches ConfirmRideView)
  Future<BitmapDescriptor> _createTargetMarkerIcon({
    required Color color,
    double radius = 16,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    const size = Size(40, 56);

    final center = Offset(size.width / 2, radius + 2);

    final linePaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, Offset(size.width / 2, size.height - 2), linePaint);

    final outerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, outerPaint);

    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.55, whitePaint);

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

    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 12, whitePaint);

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
      color: const Color(0xFFE53935),
    );
    final dropIcon = await _createTargetMarkerIcon(
      color: const Color(0xFF2E7D32),
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
  Widget build(BuildContext context) {
    final state = ref.watch(rideViewModelProvider);
    final pickup = state.pickup;
    final drop = state.drop;

    final markers = <Marker>{};

    // Pickup — red target pin
    if (pickup != null) {
      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(pickup.latitude, pickup.longitude),
        icon: _pickupIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        anchor: const Offset(0.5, 1.0),
        infoWindow: InfoWindow(title: pickup.address ?? 'Pickup'),
      ));
    }

    // Dropoff — green target pin
    if (drop != null) {
      markers.add(Marker(
        markerId: const MarkerId('drop'),
        position: LatLng(drop.latitude, drop.longitude),
        icon: _dropIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        anchor: const Offset(0.5, 1.0),
        infoWindow: InfoWindow(title: drop.address ?? 'Dropoff'),
      ));
    }

    // Cluster of riders / bikes near dropoff
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

            // ── Full Map Card View (Same as ConfirmRideView) ──
            Container(
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

                  // ── Bottom Right: My Location Button ──
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: GestureDetector(
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
                    const Expanded(
                      child: Text(
                        'Your safety is our priority. We never compromise.',
                        style: TextStyle(fontSize: 12, color: AppColors.primaryPink, fontWeight: FontWeight.w500),
                      ),
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
    _mapController?.dispose();
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

/// Address chip overlaid on the map
class _MapChip extends StatelessWidget {
  final String label;

  const _MapChip({
    required this.label,
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
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
        ),
      ),
    );
  }
}
