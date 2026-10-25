import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../ride/view_models/ride_view_model.dart';
import '../../../data/services/socket_service.dart';

class ActiveRideView extends ConsumerStatefulWidget {
  final String rideId;
  const ActiveRideView({super.key, required this.rideId});

  @override
  ConsumerState<ActiveRideView> createState() => _ActiveRideViewState();
}

class _ActiveRideViewState extends ConsumerState<ActiveRideView> {
  GoogleMapController? _mapController;
  LatLng? _liveRiderPosition;
  late final RideViewModel _viewModel;

  BitmapDescriptor? _bikeMarkerIcon;
  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _dropIcon;

  @override
  void initState() {
    super.initState();
    _loadMarkerIcons();
    _viewModel = ref.read(rideViewModelProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.startPolling(widget.rideId);
    });

    _initSocket();
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

    if (mounted) {
      setState(() {
        _bikeMarkerIcon = bikeIcon;
        _pickupIcon = pickupIcon;
        _dropIcon = dropIcon;
      });
    }
  }

  void _initSocket() {
    final socketService = SocketService();
    socketService.connect();
    socketService.joinRideRoom(widget.rideId);

    socketService.onLocationUpdate = (data) {
      if (!mounted) return;
      setState(() {
        _liveRiderPosition = LatLng(data['latitude'], data['longitude']);
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_liveRiderPosition!),
      );
    };

    socketService.onRideCompleted((data) {
      if (!mounted) return;
      _viewModel.stopPolling();
      context.go('/ride-complete/${widget.rideId}');
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

  void _shareRide() {
    final state = ref.read(rideViewModelProvider);
    final ride = state.activeRide;
    final riderName = ride?.rider?.name ?? 'Woosh Rider';
    final vehicle = ride?.rider?.vehicleNumber ?? '';
    final link = 'https://woosh.com/track/${widget.rideId}';
    // ignore: deprecated_member_use
    Share.share('Track my Woosh ride with $riderName ($vehicle) live at: $link');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RideState>(rideViewModelProvider, (previous, next) {
      final ride = next.activeRide;
      if (ride != null) {
        final status = ride.status.toLowerCase();
        final paymentStatus = ride.paymentStatus.toLowerCase();
        if (status == 'completed' || status == 'ended' || paymentStatus == 'completed' || paymentStatus == 'paid') {
          _viewModel.stopPolling();
          if (mounted) {
            context.go('/ride-complete/${widget.rideId}');
          }
        }
      }
    });

    final state = ref.watch(rideViewModelProvider);
    final ride = state.activeRide;
    
    if (ride != null) {
      final status = ride.status.toLowerCase();
      final paymentStatus = ride.paymentStatus.toLowerCase();
      if (status == 'completed' || status == 'ended' || paymentStatus == 'completed' || paymentStatus == 'paid') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _viewModel.stopPolling();
          if (mounted) {
            context.go('/ride-complete/${widget.rideId}');
          }
        });
      }
    }

    final rider = ride?.rider;
    final pickup = state.pickup;
    final drop = state.drop;

    final String dropAddress = drop?.address ?? 'Drop place';
    final double distanceLeft = ride?.distanceKm ?? 2.1;
    final int minutesLeft = ride?.durationMinutes ?? 8;
    final DateTime dropTime = DateTime.now().add(Duration(minutes: minutesLeft));
    final String dropTimeStr = DateFormat('h:mm a').format(dropTime).toLowerCase();

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
      markers.add(
        Marker(
          markerId: const MarkerId('drop'),
          position: LatLng(drop.latitude, drop.longitude),
          icon: _dropIcon ?? BitmapDescriptor.defaultMarker,
        ),
      );
    }

    if (_liveRiderPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('rider'),
          position: _liveRiderPosition!,
          icon: _bikeMarkerIcon ?? BitmapDescriptor.defaultMarker,
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: pickup != null
                  ? LatLng(pickup.latitude, pickup.longitude)
                  : const LatLng(23.2599, 77.4126),
              zoom: 14,
            ),
            markers: markers,
            polylines: pickup != null && drop != null
                ? {
                    Polyline(
                      polylineId: const PolylineId('route'),
                      color: AppColors.primaryPink,
                      width: 5,
                      points: [
                        LatLng(pickup.latitude, pickup.longitude),
                        LatLng(drop.latitude, drop.longitude),
                      ],
                    ),
                  }
                : {},
            zoomControlsEnabled: false,
            onMapCreated: (c) {
              _mapController = c;
              Future.delayed(const Duration(milliseconds: 500), () {
                _fitMapToBounds();
              });
            },
          ),

          // Top Banner: Live - Trip shared with Mom, [Name]
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE53935),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ride?.status == 'accepted'
                            ? 'Live · Driver is arriving'
                            : 'Live · Ride in progress',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: _shareRide,
                      child: const Text(
                        'Manage',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryPink,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
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

                  // Heading to [Drop place]
                  Text(
                    'Heading to $dropAddress',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Drop at [10:42 am] · [8] min · [2.1] km left
                  Text(
                    'Drop at $dropTimeStr · $minutesLeft min · ${distanceLeft.toStringAsFixed(1)} km left',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.lightGray,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Progress Bar
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        height: 4,
                        width: constraints.maxWidth,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E5F5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Container(
                          height: 4,
                          width: constraints.maxWidth * 0.6,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primaryPink, Color(0xFFFF7043)],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Rider Details Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.dividerColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.lightPink,
                            border: Border.all(color: AppColors.primaryPink),
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: AppColors.primaryPink,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rider?.name ?? 'Rider name',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${rider?.vehicleNumber ?? 'MP 04 AB 1234'} · ★ ${rider?.rating ?? 4.9}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.lightGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Call button
                        GestureDetector(
                          onTap: () async {
                            if (rider?.phoneNumber != null && rider!.phoneNumber.isNotEmpty) {
                              await launchUrl(Uri.parse('tel:${rider.phoneNumber}'));
                            }
                          },
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8F5E9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.call,
                              color: Color(0xFF2E7D32),
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Chat button
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF5F5F5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline,
                              color: AppColors.darkText,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Ride check notice
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF2E7D32),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          "Ride check is on. We'll check in if the route changes or the ride stops too long.",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.lightGray,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Bottom Buttons Row: Share Live | Support | SOS
                  SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        // Share Live
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primaryPink, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed: _shareRide,
                            icon: const Icon(
                              Icons.share_outlined,
                              color: AppColors.primaryPink,
                              size: 18,
                            ),
                            label: const Text(
                              'Share live',
                              style: TextStyle(
                                color: AppColors.primaryPink,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Help button
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF5F5F5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.help_outline,
                            color: AppColors.darkText,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // SOS button
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD32F2F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: EdgeInsets.zero,
                              elevation: 0,
                            ),
                            onPressed: () async {
                              final rideId = ride?.id ?? widget.rideId;
                              if (rideId.isNotEmpty) {
                                try {
                                  await _viewModel.triggerSOS(rideId);
                                  if (mounted) {
                                    context.push('/sos-active');
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to trigger SOS: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            icon: const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: const Text(
                              'SOS',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
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
    _mapController?.dispose();
    _viewModel.stopPolling();
    super.dispose();
  }
}
