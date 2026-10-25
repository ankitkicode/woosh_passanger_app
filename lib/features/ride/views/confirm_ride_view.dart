import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/di_providers.dart';
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
  final Map<String, Marker> _riderMarkers = {};

  @override
  void initState() {
    super.initState();
    _loadMarkerIcons();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rideViewModelProvider.notifier).estimateFare();
      final pickup = ref.read(rideViewModelProvider).pickup;
      if (pickup != null) {
        _fetchNearbyRiders(pickup.latitude, pickup.longitude);
      } else {
        _fetchNearbyRiders(23.2599, 77.4126);
      }
    });
  }

  Future<void> _fetchNearbyRiders(double lat, double lng) async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get(
        '/ride/nearby-riders',
        queryParameters: {'latitude': lat, 'longitude': lng},
      );

      if (response.data['success'] == true) {
        final List<dynamic> riders = response.data['data'] ?? [];
        if (mounted) {
          setState(() {
            _riderMarkers.clear();
            for (var rider in riders) {
              final String riderId = rider['_id'] ?? '';
              final coords =
                  rider['currentLocation']?['coordinates'] as List<dynamic>?;
              final user = rider['user'] as Map<String, dynamic>?;
              final String riderName = user?['name'] ?? 'Woosh Rider';

              if (riderId.isNotEmpty && coords != null && coords.length == 2) {
                final double rLng = (coords[0] as num).toDouble();
                final double rLat = (coords[1] as num).toDouble();

                _riderMarkers[riderId] = Marker(
                  markerId: MarkerId(riderId),
                  position: LatLng(rLat, rLng),
                  icon:
                      _bikeMarkerIcon ??
                      BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueOrange,
                      ),
                  anchor: const Offset(0.5, 0.5),
                  infoWindow: InfoWindow(title: riderName),
                );
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Nearby riders fetch error: $e');
    }
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
      color: const Color(0xFF4CAF50), // Green for current location
    );
    final dropIcon = await _createTargetMarkerIcon(
      color: AppColors.primaryPink, // Pink for drop
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

    // Pickup
    if (pickup != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(pickup.latitude, pickup.longitude),
          icon:
              _pickupIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          anchor: const Offset(0.5, 1.0),
          infoWindow: InfoWindow(title: pickup.address ?? 'Pickup'),
        ),
      );
    }

    // Dropoff
    if (drop != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('drop'),
          position: LatLng(drop.latitude, drop.longitude),
          icon:
              _dropIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          anchor: const Offset(0.5, 1.0),
          infoWindow: InfoWindow(title: drop.address ?? 'Dropoff'),
        ),
      );
    }

    // Real active bike markers (or fallback mock if none returned)
    if (_riderMarkers.isNotEmpty) {
      markers.addAll(_riderMarkers.values);
    } else if (drop != null) {
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
        markers.add(
          Marker(
            markerId: MarkerId('rider_$i'),
            position: LatLng(baseLat + offsets[i].dx, baseLng + offsets[i].dy),
            icon:
                _bikeMarkerIcon ??
                BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange,
                ),
            anchor: const Offset(0.5, 0.5),
            rotation: rotations[i],
          ),
        );
      }
    }

    // Blue current location GPS dot
    if (pickup != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(pickup.latitude - 0.0005, pickup.longitude - 0.0005),
          icon:
              _blueDotIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          anchor: const Offset(0.5, 0.5),
        ),
      );
    } else if (drop != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(drop.latitude - 0.0019, drop.longitude - 0.0019),
          icon:
              _blueDotIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }

    String dropTimeStr = '';
    String awayText = '0 min away';
    if (state.fareEstimate != null) {
      final now = DateTime.now();
      final dropTime = now.add(Duration(minutes: state.fareEstimate!.durationMinutes.toInt()));
      final hour = dropTime.hour > 12 ? dropTime.hour - 12 : (dropTime.hour == 0 ? 12 : dropTime.hour);
      final min = dropTime.minute.toString().padLeft(2, '0');
      final ampm = dropTime.hour >= 12 ? 'pm' : 'am';
      dropTimeStr = '$hour:$min $ampm';

      final eta = state.fareEstimate!.formattedEta;
      if (eta != null && eta.isNotEmpty) {
        awayText = eta.toLowerCase().contains('away') ? eta : '$eta away';
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Full Screen Map ──
          GoogleMap(
            padding: const EdgeInsets.only(bottom: 340, top: 40),
            initialCameraPosition: CameraPosition(
              target: pickup != null
                  ? LatLng(pickup.latitude, pickup.longitude)
                  : const LatLng(23.2599, 77.4126),
              zoom: 13,
            ),
            markers: markers,
            polylines: pickup != null && drop != null
                ? {
                    Polyline(
                      polylineId: const PolylineId('route'),
                      color: AppColors.primaryPink,
                      width: 4,
                      points: [
                        LatLng(pickup.latitude, pickup.longitude),
                        LatLng(drop.latitude, drop.longitude),
                      ],
                    ),
                  }
                : {},
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

          // ── Top Left: Floating Back Button ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
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

          // ── Dropoff Chip (Top Right) ──
          if (drop != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16 + 50,
              right: 20,
              child: _MapChip(
                isDark: true,
                label: () {
                  String label = drop.address != null && drop.address!.length > 15
                      ? '${drop.address!.substring(0, 15)}...'
                      : (drop.address ?? 'Dropoff');
                  if (state.fareEstimate != null) {
                    label += ' · ${state.fareEstimate!.durationMinutes.toInt()} min';
                  }
                  return label;
                }(),
                onEdit: () => context.push(
                  '/search-destination?focus=drop&fromConfirm=true',
                ),
              ),
            ),

          // ── Pickup Chip (Middle Left, above bottom sheet) ──
          if (pickup != null)
            Positioned(
              bottom: 360,
              left: 20,
              child: _MapChip(
                isDark: false,
                label: pickup.address != null && pickup.address!.length > 18
                    ? '${pickup.address!.substring(0, 15)}...'
                    : (pickup.address ?? 'Current location'),
                onEdit: () => context.push(
                  '/search-destination?focus=pickup&fromConfirm=true',
                ),
              ),
            ),

          // ── Bottom Sheet UI ──
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Choose your ride + distance/time
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Choose your ride',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkText,
                            ),
                          ),
                          if (state.fareEstimate != null)
                            Text(
                              '${state.fareEstimate!.distanceKm.toStringAsFixed(1)} km · ${state.fareEstimate!.durationMinutes.toInt()} min',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.lightGray,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Single Woosh Bike card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPink.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primaryPink, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            // Bike icon box
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Icon(Icons.two_wheeler, color: AppColors.primaryPink),
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // Bike details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Woosh Bike',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.darkText,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    state.fareEstimate != null 
                                      ? '$awayText · Drop $dropTimeStr'
                                      : 'Calculating...',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.lightGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Price
                            if (state.fareEstimate != null)
                              Text(
                                '₹${state.fareEstimate!.fare.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkText,
                                ),
                              )
                            else if (state.isLoading)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryPink),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Payment Method row - Old Style
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.dividerColor),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.account_balance_wallet_outlined,
                              color: AppColors.darkText,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Payment Method',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.lightGray,
                                  ),
                                ),
                                Text(
                                  state.paymentMethod == 'cash' ? 'Cash' : 'Online',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            OutlinedButton(
                              onPressed: () => notifier.setPaymentMethod(
                                state.paymentMethod == 'cash' ? 'online' : 'cash',
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primaryPink),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 4,
                                ),
                                minimumSize: Size.zero,
                              ),
                              child: const Text(
                                'Change',
                                style: TextStyle(
                                  color: AppColors.primaryPink,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Error
                    if (state.error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.errorRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppColors.errorRed,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  state.error!,
                                  style: const TextStyle(
                                    color: AppColors.errorRed,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                    // Request a Ride Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: WooshGradientButton(
                        text: 'Book Woosh Bike',
                        isLoading: state.isLoading,
                        onPressed: state.fareEstimate != null
                            ? () async {
                                final rideId = await notifier.requestRide();
                                if (rideId != null && context.mounted) {
                                  context.go('/searching/$rideId');
                                }
                              }
                            : null,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
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

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

class _MapChip extends StatelessWidget {
  final String label;
  final VoidCallback? onEdit;
  final bool isDark;

  const _MapChip({super.key, required this.label, this.onEdit, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
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
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFF0F0F5),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.edit, size: 13, color: isDark ? Colors.white : const Color(0xFF666666)),
            ),
          ),
        ],
      ),
    );
  }
}

