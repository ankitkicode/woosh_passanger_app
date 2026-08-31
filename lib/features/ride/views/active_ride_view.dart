import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/woosh_gradient_button.dart';
import '../../ride/view_models/ride_view_model.dart';
import '../../../data/services/socket_service.dart';

/// Active Ride View — live tracking + SOS + ride info
class ActiveRideView extends ConsumerStatefulWidget {
  final String rideId;
  const ActiveRideView({super.key, required this.rideId});

  @override
  ConsumerState<ActiveRideView> createState() => _ActiveRideViewState();
}

class _ActiveRideViewState extends ConsumerState<ActiveRideView> {
  GoogleMapController? _mapController;
  LatLng? _liveRiderPosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rideViewModelProvider.notifier).startPolling(widget.rideId);
    });

    _initSocket();
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
      // Optionally animate camera to rider position
      if (_mapController != null && _liveRiderPosition != null) {
        // _mapController!.animateCamera(CameraUpdate.newLatLng(_liveRiderPosition!));
      }
    };
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
    if (_liveRiderPosition != null) {
      markers.add(Marker(
        markerId: const MarkerId('live_rider'),
        position: _liveRiderPosition!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange), // Represent rider as orange marker
        infoWindow: const InfoWindow(title: 'Rider is here'),
      ));
    }

    // Check if ride is completed
    if (ride?.status == 'completed') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/ride-complete/${widget.rideId}');
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          // Full map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: pickup != null ? LatLng(pickup.latitude, pickup.longitude) : const LatLng(23.2599, 77.4126),
              zoom: 13,
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
            mapToolbarEnabled: false,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            onMapCreated: (c) => _mapController = c,
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                    ),
                    child: ShaderMask(
                      shaderCallback: (r) => AppColors.brandGradient.createShader(r),
                      child: const Text('Woosh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const Spacer(),
                  // Ride status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.successGreen, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(
                          ride?.status == 'in_progress' ? 'Ride Active' : 'Rider Arriving',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // SOS Floating Button
          Positioned(
            top: 100,
            right: 16,
            child: GestureDetector(
              onTap: () async {
                _showSOSConfirm(context);
              },
              child: Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: AppColors.errorRed,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.errorRed.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 2)],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sos, color: Colors.white, size: 20),
                    Text('SOS', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Info Card
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, -4))],
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),

                  // Rider Info Row
                  Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.lightPink,
                          border: Border.all(color: AppColors.primaryPink, width: 2),
                        ),
                        child: const Icon(Icons.person, color: AppColors.primaryPink),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(rider?.name ?? 'Your Rider', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(
                              '${rider?.vehicleModel ?? 'Activa'}  •  ${rider?.vehicleNumber ?? '—'}',
                              style: const TextStyle(fontSize: 12, color: AppColors.lightGray),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '₹${ride?.fare.toStringAsFixed(0) ?? '—'}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Route mini info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.circle, size: 10, color: AppColors.secondaryPurple),
                            const SizedBox(width: 8),
                            Expanded(child: Text(pickup?.address ?? 'Pickup', style: const TextStyle(fontSize: 12, color: AppColors.lightGray))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(margin: const EdgeInsets.only(left: 4), width: 1, height: 12, color: AppColors.dividerColor),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 12, color: AppColors.primaryPink),
                            const SizedBox(width: 8),
                            Expanded(child: Text(drop?.address ?? 'Drop', style: const TextStyle(fontSize: 12, color: AppColors.lightGray))),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Share live location
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.share_location, color: AppColors.primaryPink, size: 18),
                    label: const Text('Share Live Location', style: TextStyle(color: AppColors.primaryPink)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                      side: const BorderSide(color: AppColors.primaryPink),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSOSConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.sos, color: AppColors.errorRed),
            SizedBox(width: 8),
            Text('Emergency SOS', style: TextStyle(color: AppColors.errorRed)),
          ],
        ),
        content: const Text('This will immediately notify your emergency contacts and our safety team. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ride = ref.read(rideViewModelProvider).activeRide;
              if (ride != null) {
                await ref.read(rideViewModelProvider.notifier).triggerSOS(ride.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🚨 SOS Triggered! Help is on the way.'),
                      backgroundColor: AppColors.errorRed,
                      duration: Duration(seconds: 5),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
            child: const Text('SEND SOS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    ref.read(rideViewModelProvider.notifier).stopPolling();
    super.dispose();
  }
}
