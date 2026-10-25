import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../ride/view_models/ride_view_model.dart';
import '../../../data/services/socket_service.dart';
import '../../../providers/emergency_contact_provider.dart';

class RiderFoundView extends ConsumerStatefulWidget {
  final String rideId;
  const RiderFoundView({super.key, required this.rideId});

  @override
  ConsumerState<RiderFoundView> createState() => _RiderFoundViewState();
}

class _RiderFoundViewState extends ConsumerState<RiderFoundView> {
  GoogleMapController? _mapController;
  BitmapDescriptor? _bikeMarkerIcon;
  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _dropIcon;

  Timer? _pollTimer;
  Timer? _countdownTimer;
  int _remainingSeconds = 180; // Starts at 3 minutes (180 seconds)

  @override
  void initState() {
    super.initState();
    _loadMarkerIcons();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rideViewModelProvider.notifier).getRideDetails(widget.rideId);

      SocketService().onRiderArrived((data) {
        if (data['rideId'] == widget.rideId && mounted) {
          ref.read(rideViewModelProvider.notifier).getRideDetails(widget.rideId);
        }
      });

      SocketService().onRideStarted((data) {
        if (data['rideId'] == widget.rideId && mounted) {
          _pollTimer?.cancel();
          _countdownTimer?.cancel();
          context.go('/ride-active/${widget.rideId}');
        }
      });

      _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        final ride = await ref
            .read(rideViewModelProvider.notifier)
            .getRideDetails(widget.rideId);
        if (ride != null && ride.status == 'started' && mounted) {
          _pollTimer?.cancel();
          _countdownTimer?.cancel();
          context.go('/ride-active/${widget.rideId}');
        }
      });
      
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && _remainingSeconds > 0) {
          setState(() {
            _remainingSeconds--;
          });
        }
      });
    });
  }

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    if (minutes > 0) {
      return '$minutes min';
    } else {
      return '$seconds sec';
    }
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

  void _showCancelBottomSheet(BuildContext context) {
    String selectedReason = 'My plans changed';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final state = ref.watch(rideViewModelProvider);
            final rider = state.activeRide?.rider;

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.all(20),
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
                  const Text(
                    'Cancel this ride?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${rider?.name ?? 'Rider'} is $_formattedTime away. A small fee of ₹10 may apply after 2 min of booking.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.lightGray,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'TELL US WHY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.lightGray,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...[
                    'Rider is taking too long',
                    'My plans changed',
                    'Booked by mistake',
                    'Rider asked me to cancel',
                    'Something felt unsafe',
                    'Other'
                  ].map((reason) {
                    return RadioListTile<String>(
                      value: reason,
                      groupValue: selectedReason,
                      activeColor: AppColors.primaryPink,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        reason,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.darkText,
                        ),
                      ),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedReason = val);
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Keep my ride',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await ref
                            .read(rideViewModelProvider.notifier)
                            .cancelRide(widget.rideId);
                        if (context.mounted) context.go('/home');
                      },
                      child: const Text(
                        'Cancel ride',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC62828),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showShareBottomSheet(BuildContext context) {
    final shortRideId = widget.rideId.length >= 5 
        ? widget.rideId.substring(widget.rideId.length - 5) 
        : widget.rideId;
    final shareLink = 'woosh.app/t/$shortRideId';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final contactsAsyncValue = ref.watch(emergencyContactsProvider);
            
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.all(20),
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
                  const Text(
                    'Share live location',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "They'll see your rider, vehicle and live route until you're dropped off. The link stops working after the ride.",
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.lightGray,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.link, color: AppColors.primaryPink),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            shareLink,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkText,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: shareLink));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Link copied to clipboard')),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                            ),
                            child: const Text(
                              'Copy',
                              style: TextStyle(
                                color: AppColors.primaryPink,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ShareOption(
                        icon: Icons.chat, 
                        label: 'WhatsApp', 
                        color: const Color(0xFF25D366),
                        onTap: () => _shareToApp('whatsapp', shareLink),
                      ),
                      _ShareOption(
                        icon: Icons.message, 
                        label: 'SMS', 
                        color: const Color(0xFF1976D2),
                        onTap: () => _shareToApp('sms', shareLink),
                      ),
                      _ShareOption(
                        icon: Icons.copy, 
                        label: 'Copy link', 
                        color: const Color(0xFFE91E63),
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: shareLink));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Link copied to clipboard')),
                          );
                        },
                      ),
                      _ShareOption(
                        icon: Icons.more_horiz, 
                        label: 'More', 
                        color: Colors.grey[700]!,
                        onTap: () => Share.share('Track my ride live on Woosh: $shareLink'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'YOUR TRUSTED CONTACTS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.lightGray,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Dynamic Contacts List
                  contactsAsyncValue.when(
                    data: (contacts) {
                      if (contacts.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Text(
                            'No trusted contacts found. Add some to share your ride easily.',
                            style: TextStyle(color: AppColors.lightGray, fontSize: 13),
                          ),
                        );
                      }
                      
                      return Column(
                        children: contacts.take(3).map((contact) {
                          final initial = contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?';
                          
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: AppColors.lightPink,
                              child: Text(
                                initial, 
                                style: const TextStyle(
                                  color: AppColors.primaryPink, 
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                            title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              contact.relationship, 
                              style: const TextStyle(color: AppColors.lightGray, fontSize: 12)
                            ),
                            trailing: GestureDetector(
                              onTap: () {
                                Share.share('Track my ride live on Woosh: $shareLink');
                              },
                              child: const Icon(Icons.share, color: AppColors.primaryPink, size: 20),
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(color: AppColors.primaryPink),
                      )
                    ),
                    error: (e, _) => const Text(
                      'Failed to load contacts', 
                      style: TextStyle(color: Colors.red, fontSize: 12)
                    ),
                  ),

                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push('/emergency-contacts');
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primaryPink, style: BorderStyle.solid),
                          ),
                          child: const Icon(Icons.add, color: AppColors.primaryPink),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Add a trusted contact',
                          style: TextStyle(
                            color: AppColors.primaryPink,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Future<void> _shareToApp(String app, String link) async {
    final message = 'Track my ride live on Woosh: $link';
    Uri? url;
    
    if (app == 'whatsapp') {
      url = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(message)}');
    } else if (app == 'sms') {
      url = Uri.parse('sms:?body=${Uri.encodeComponent(message)}');
    }
    
    if (url != null && await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      Share.share(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rideViewModelProvider);
    final ride = state.activeRide;
    final rider = ride?.rider;
    final pickup = state.pickup;

    final String otp = ride?.rideOtp ?? '4821';
    final List<String> otpDigits = otp.length == 4 ? otp.split('') : ['4', '8', '2', '1'];

    final markers = <Marker>{};
    final polylines = <Polyline>{};

    if (pickup != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(pickup.latitude, pickup.longitude),
          icon: _pickupIcon ?? BitmapDescriptor.defaultMarker,
        ),
      );

      final arrivingLat = pickup.latitude + 0.0018;
      final arrivingLng = pickup.longitude + 0.0015;

      markers.add(
        Marker(
          markerId: const MarkerId('arriving_rider'),
          position: LatLng(arrivingLat, arrivingLng),
          icon: _bikeMarkerIcon ?? BitmapDescriptor.defaultMarker,
          anchor: const Offset(0.5, 0.5),
        ),
      );

      // Add a route line (polygone/polyline) from rider to pickup
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route_to_pickup'),
          points: [
            LatLng(arrivingLat, arrivingLng),
            LatLng(pickup.latitude, pickup.longitude),
          ],
          color: const Color(0xFF1976D2),
          width: 5,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
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
            polylines: polylines,
            zoomControlsEnabled: false,
            onMapCreated: (c) {
              _mapController = c;
              Future.delayed(const Duration(milliseconds: 500), () {
                _fitMapToBounds();
              });
            },
          ),

          // Top Floating Action Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => _showShareBottomSheet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.share_outlined, color: AppColors.primaryPink, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Share live location',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_filled, color: AppColors.primaryPink, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              _formattedTime,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          if (ride != null) {
                            await ref.read(rideViewModelProvider.notifier).triggerSOS(ride.id);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD32F2F),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Arriving in $_formattedTime',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkText,
                        ),
                      ),
                      Text(
                        'On the way',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your ride PIN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Share with your rider to start',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: otpDigits.map((digit) {
                            return Container(
                              margin: const EdgeInsets.only(left: 6),
                              width: 34,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                digit,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primaryPink, width: 2),
                              color: AppColors.lightPink,
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              color: AppColors.primaryPink,
                              size: 28,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                color: Color(0xFF00C853),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, color: Colors.white, size: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rider?.name ?? 'Rider name',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Color(0xFFFF7043), size: 14),
                                const SizedBox(width: 2),
                                Text(
                                  '${rider?.rating ?? 4.9} · ${rider?.totalRides ?? 1240} rides · Verified',
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

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black, width: 1.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              rider?.vehicleNumber ?? 'MP 04 AB 1234',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Activa · Pink',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ActionButton(
                        icon: Icons.call,
                        label: 'Call',
                        bgColor: const Color(0xFFE8F5E9),
                        iconColor: const Color(0xFF2E7D32),
                        onTap: () async {
                          if (rider?.phoneNumber != null && rider!.phoneNumber.isNotEmpty) {
                            await launchUrl(Uri.parse('tel:${rider.phoneNumber}'));
                          }
                        },
                      ),
                      _ActionButton(
                        icon: Icons.chat_bubble_outline,
                        label: 'Chat',
                        bgColor: const Color(0xFFF5F5F5),
                        iconColor: AppColors.darkText,
                        onTap: () {},
                      ),
                      _ActionButton(
                        icon: Icons.share_outlined,
                        label: 'Share trip',
                        bgColor: AppColors.lightPink,
                        iconColor: AppColors.primaryPink,
                        onTap: () => _showShareBottomSheet(context),
                      ),
                      _ActionButton(
                        icon: Icons.close,
                        label: 'Cancel',
                        bgColor: const Color(0xFFF5F5F5),
                        iconColor: AppColors.darkText,
                        onTap: () => _showCancelBottomSheet(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.lightPink,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.shield_outlined, color: AppColors.primaryPink, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Safety toolkit',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryPink,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Trip shared with 2',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondaryPurple,
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
    _pollTimer?.cancel();
    super.dispose();
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.darkText,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ShareOption({
    required this.icon, 
    required this.label, 
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.darkText,
          ),
        ),
      ],
      ),
    );
  }
}
