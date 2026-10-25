import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../ride/view_models/ride_view_model.dart';
import '../../../data/services/socket_service.dart';

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

  Timer? _pollTimer;
  late AnimationController _animationController;
  late Animation<double> _animation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadMarkerIcons();
    _startListening();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.2, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

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
    SocketService().onRideAccepted((data) {
      if (data['rideId'] == widget.rideId && mounted) {
        _pollTimer?.cancel();
        context.go('/rider-found/${widget.rideId}');
      }
    });

    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final ride = await ref
          .read(rideViewModelProvider.notifier)
          .getRideDetails(widget.rideId);
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
    final ride = state.activeRide;

    final double fare = ride?.fare ?? state.fareEstimate?.fare ?? 0.0;
    final String pickupAddress = pickup?.address ?? 'Current location';
    final String dropAddress = drop?.address ?? 'Drop place';

    final markers = <Marker>{};

    if (pickup != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(pickup.latitude, pickup.longitude),
          icon: _pickupIcon ?? BitmapDescriptor.defaultMarker,
        ),
      );
    }

    if (drop != null) {
      final baseLat = drop.latitude;
      final baseLng = drop.longitude;
      final offsets = [
        const Offset(-0.0018, -0.0012),
        const Offset(-0.0012, -0.0022),
        const Offset(0.0015, 0.0018),
      ];
      for (int i = 0; i < offsets.length; i++) {
        markers.add(
          Marker(
            markerId: MarkerId('rider_$i'),
            position: LatLng(baseLat + offsets[i].dx, baseLng + offsets[i].dy),
            icon: _bikeMarkerIcon ?? BitmapDescriptor.defaultMarker,
          ),
        );
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          // Google Map Background
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: pickup != null
                  ? LatLng(pickup.latitude, pickup.longitude)
                  : const LatLng(23.2599, 77.4126),
              zoom: 14,
            ),
            markers: markers,
            zoomControlsEnabled: false,
            onMapCreated: (c) {
              _mapController = c;
              Future.delayed(const Duration(milliseconds: 500), () {
                _fitMapToBounds();
              });
            },
          ),

          // Central Pulse Effect
          Align(
            alignment: const Alignment(0, -0.5),
            child: ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryPink.withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryPink.withValues(alpha: 0.25),
                    ),
                    child: Center(
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryPink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle indicator
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  const Text(
                    'Finding your rider...',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Progress Bar
                  Stack(
                    children: [
                      Container(
                        height: 4,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E5F5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return FractionallySizedBox(
                            widthFactor: _animation.value,
                            child: child,
                          );
                        },
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF7043),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Subtitle
                  const Text(
                    'Matching you with the nearest verified woman rider',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.lightGray,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Trip Summary Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.dividerColor),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Location Icons Column
                        Column(
                          children: [
                            const Icon(Icons.circle, color: Color(0xFF2E7D32), size: 10),
                            Container(
                              height: 18,
                              width: 1,
                              color: Colors.grey[400],
                            ),
                            Container(
                              width: 10,
                              height: 10,
                              color: AppColors.primaryPink,
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),

                        // Address Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pickupAddress,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                dropAddress,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Fare Column
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${fare.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${state.paymentMethod.toUpperCase()} · Bike',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.lightGray,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Emergency Contact Card
                  GestureDetector(
                    onTap: () {
                      context.push('/add-emergency-contact');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.lightPink,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_add_outlined,
                              color: AppColors.primaryPink,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Add an emergency contact',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkText,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'They can follow your trips and get SOS alerts',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.lightGray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.primaryPink,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Cancel request button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.dividerColor, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      onPressed: () async {
                        _pollTimer?.cancel();
                        await ref
                            .read(rideViewModelProvider.notifier)
                            .cancelRide(widget.rideId);
                        if (context.mounted) context.go('/home');
                      },
                      child: const Text(
                        'Cancel request',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkText,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _mapController?.dispose();
    _pollTimer?.cancel();
    SocketService().offRideAccepted();
    super.dispose();
  }
}
