import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/places_service.dart';
import '../../../shared/widgets/woosh_bottom_nav.dart';
import '../../ride/view_models/ride_view_model.dart';
import '../../ride/models/ride_model.dart';
import '../../../data/services/socket_service.dart';
import '../../../providers/auth_provider.dart';

// Google Maps API Key — same as AndroidManifest.xml
const String _kGoogleApiKey = 'AIzaSyCfmd3W3DPh3jYOeYx41Bva9GIxCmpo7UY';

class HomeMapView extends ConsumerStatefulWidget {
  const HomeMapView({super.key});

  @override
  ConsumerState<HomeMapView> createState() => _HomeMapViewState();
}

class _HomeMapViewState extends ConsumerState<HomeMapView> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(23.2599, 77.4126); // Bhopal default
  bool _locationLoaded = false;
  String _currentAddress = 'Fetching location...';
  bool _fetchingAddress = true;

  late final PlacesService _placesService;
  List<PlaceDetails> _nearbyPlaces = [];
  Map<String, Marker> _riderMarkers = {};

  @override
  void initState() {
    super.initState();
    _placesService = PlacesService(_kGoogleApiKey);
    _getCurrentLocation();
    _initSocket();
  }

  void _initSocket() {
    final socketService = SocketService();
    socketService.onLocationUpdate = (data) {
      if (!mounted) return;
      final riderId = data['riderId'];
      final lat = data['latitude'];
      final lng = data['longitude'];

      setState(() {
        _riderMarkers[riderId] = Marker(
          markerId: MarkerId(riderId),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta),
          infoWindow: const InfoWindow(title: 'Woosh Rider'),
        );
      });
    };

    socketService.onRiderStatusChanged = (data) {
      if (!mounted) return;
      final riderId = data['riderId'];
      final isOnline = data['isOnline'];

      setState(() {
        if (!isOnline) {
          _riderMarkers.remove(riderId);
        } else if (data['latitude'] != null && data['longitude'] != null) {
          _riderMarkers[riderId] = Marker(
            markerId: MarkerId(riderId),
            position: LatLng(data['latitude'], data['longitude']),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta),
            infoWindow: const InfoWindow(title: 'Woosh Rider'),
          );
        }
      });
    };

    socketService.connect();

    // Join personal passenger room
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        final user = ref.read(authStateProvider).user;
        if (user != null) {
          socketService.joinPassengerRoom(user.id);
        }
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentAddress = 'Location services disabled';
          _fetchingAddress = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentAddress = 'Location permission denied';
            _fetchingAddress = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentAddress = 'Location permission denied permanently';
          _fetchingAddress = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _locationLoaded = true;
      });

      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_currentPosition, 15));

      // Set pickup in ride state
      ref.read(rideViewModelProvider.notifier).setPickup(
        RideLocation(latitude: position.latitude, longitude: position.longitude, address: 'Current Location'),
      );

      // Reverse geocode to get actual address
      final address = await _placesService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          _currentAddress = address;
          _fetchingAddress = false;
        });

        // Update pickup with real address
        ref.read(rideViewModelProvider.notifier).setPickup(
          RideLocation(latitude: position.latitude, longitude: position.longitude, address: address),
        );
      }

      // Load nearby places for suggestions
      _loadNearbyPlaces(position.latitude, position.longitude);
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentAddress = 'Unable to get location';
          _fetchingAddress = false;
        });
      }
    }
  }

  Future<void> _loadNearbyPlaces(double lat, double lng) async {
    final places = await _placesService.getNearbyPlaces(lat, lng);
    if (mounted) {
      setState(() {
        _nearbyPlaces = places;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    final rideState = ref.watch(rideViewModelProvider);
    final hasActiveRide = rideState.activeRide != null;

    final markers = hasActiveRide ? <Marker>{
      // Original static markers or just current ride logic if needed
    } : _riderMarkers.values.toSet();

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Consumer(builder: (context, ref, child) {
          final user = ref.watch(authStateProvider).user;
          return Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(color: AppColors.primaryPink.withValues(alpha: 0.1)),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: AppColors.primaryPink,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                accountName: Text(user?.name ?? 'Woosh Passenger', style: const TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold)),
                accountEmail: Text(user?.phoneNumber ?? '+91 9876543210', style: const TextStyle(color: AppColors.lightGray)),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline, color: AppColors.darkText),
                title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/profile');
                },
              ),
            ],
          );
        }),
      ),
      body: Stack(
        children: [
          // ── Full-screen Google Map ──
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _currentPosition, zoom: 14),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            markers: markers,
            onMapCreated: (c) {
              _mapController = c;
              if (_locationLoaded) {
                c.animateCamera(CameraUpdate.newLatLngZoom(_currentPosition, 15));
              }
            },
          ),

          // ── Top: Hamburger + Woosh Logo + Notification ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _scaffoldKey.currentState?.openDrawer(),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6)],
                          ),
                          child: const Icon(Icons.menu, color: AppColors.darkText, size: 22),
                        ),
                      ),
                      const Spacer(),
                      Column(
                        children: [
                          ShaderMask(
                            shaderCallback: (r) => AppColors.brandGradient.createShader(r),
                            child: const Text('Woosh', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                          ),
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(fontSize: 11),
                              children: [
                                TextSpan(text: 'Be Safe, ', style: TextStyle(color: AppColors.lightGray)),
                                TextSpan(text: 'Be Fearless', style: TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6)],
                        ),
                        child: Stack(
                          children: [
                            const Center(child: Icon(Icons.notifications_outlined, color: AppColors.darkText, size: 22)),
                            Positioned(
                              top: 8, right: 8,
                              child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primaryPink, shape: BoxShape.circle)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Safety banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(color: AppColors.lightPink, shape: BoxShape.circle),
                          child: const Icon(Icons.verified_user, color: AppColors.primaryPink, size: 16),
                        ),
                        const SizedBox(width: 8),
                        const Text('Ride with\nverified women riders', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.3)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── My Location FAB ──
          Positioned(
            bottom: screenHeight * 0.52 + 16,
            right: 16,
            child: GestureDetector(
              onTap: _getCurrentLocation,
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10)],
                ),
                child: const Icon(Icons.my_location, color: AppColors.primaryPink, size: 24),
              ),
            ),
          ),

          // ── Bottom Sheet ──
          DraggableScrollableSheet(
            initialChildSize: 0.50,
            minChildSize: 0.50,
            maxChildSize: 0.92,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, -4))],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(color: AppColors.primaryPink.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text('Where are you going?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                    const Text('Book your ride in just a few taps', style: TextStyle(fontSize: 13, color: AppColors.lightGray)),
                    const SizedBox(height: 16),

                    // Pickup + Drop input card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.dividerColor),
                        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)],
                      ),
                      child: Column(
                        children: [
                          // Pickup row
                          GestureDetector(
                            onTap: () {
                              // Could navigate to pickup search later
                            },
                            child: Row(
                              children: [
                                Container(
                                  width: 12, height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade600,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.green.shade200, width: 2),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Pickup location', style: TextStyle(fontSize: 10, color: AppColors.lightGray, fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 2),
                                      _fetchingAddress
                                          ? Row(
                                              children: [
                                                SizedBox(
                                                  width: 12, height: 12,
                                                  child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primaryPink),
                                                ),
                                                const SizedBox(width: 8),
                                                const Text('Fetching your location...', style: TextStyle(fontSize: 13, color: AppColors.lightGray)),
                                              ],
                                            )
                                          : Text(
                                              _currentAddress,
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkText),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _getCurrentLocation,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.lightPink,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.my_location, color: AppColors.primaryPink, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Dotted divider
                          Padding(
                            padding: const EdgeInsets.only(left: 5),
                            child: Row(
                              children: [
                                Column(
                                  children: List.generate(3, (_) => Container(
                                    width: 2, height: 4,
                                    margin: const EdgeInsets.symmetric(vertical: 1),
                                    decoration: BoxDecoration(color: AppColors.lightGray.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(1)),
                                  )),
                                ),
                                const Expanded(child: Divider(height: 20, indent: 16, color: Color(0xFFEEEEEE))),
                              ],
                            ),
                          ),

                          // Drop row — navigates to search
                          GestureDetector(
                            onTap: () => context.push('/search'),
                            child: Row(
                              children: [
                                Container(
                                  width: 12, height: 12,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryPink,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.borderPink, width: 2),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text('Drop location', style: TextStyle(fontSize: 10, color: AppColors.lightGray, fontWeight: FontWeight.w500)),
                                      SizedBox(height: 2),
                                      Text('Where are you going?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.lightGray)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightPink,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.search, color: AppColors.primaryPink, size: 18),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Quick options
                    const Text('Quick options', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkText)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _QuickOption(icon: Icons.home_filled, label: 'Home', color: AppColors.primaryPink, onTap: () {}),
                        const SizedBox(width: 10),
                        _QuickOption(icon: Icons.work, label: 'Work', color: AppColors.primaryPink, onTap: () {}),
                        const SizedBox(width: 10),
                        _QuickOption(icon: Icons.school, label: 'College', color: AppColors.primaryPink, onTap: () {}),
                        const SizedBox(width: 10),
                        _QuickOption(icon: Icons.more_horiz, label: 'Other', color: AppColors.primaryPink, onTap: () {}),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Ride preferences
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28, height: 28,
                            decoration: const BoxDecoration(color: AppColors.lightPink, shape: BoxShape.circle),
                            child: const Icon(Icons.verified_user, color: AppColors.primaryPink, size: 16),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Ride preferences', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                Text('Women riders only', style: TextStyle(fontSize: 11, color: AppColors.lightGray)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppColors.lightGray, size: 20),
                        ],
                      ),
                    ),

                    // Nearby suggestions section
                    if (_nearbyPlaces.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text('Nearby places', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkText)),
                      const SizedBox(height: 8),
                      ..._nearbyPlaces.take(5).map((place) => _NearbyPlaceTile(
                        place: place,
                        onTap: () {
                          ref.read(rideViewModelProvider.notifier).setDrop(
                            RideLocation(
                              latitude: place.latitude,
                              longitude: place.longitude,
                              address: '${place.name}, ${place.address}',
                            ),
                          );
                          context.push('/confirm-ride');
                        },
                      )),
                    ],

                    const SizedBox(height: 12),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: const WooshBottomNav(currentIndex: 0),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

// ─── Quick Option Widget ─────────────────────────────────────────────────

class _QuickOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickOption({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.lightPink,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Nearby Place Tile Widget ────────────────────────────────────────────

class _NearbyPlaceTile extends StatelessWidget {
  final PlaceDetails place;
  final VoidCallback onTap;
  const _NearbyPlaceTile({required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.lightPink,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.location_on_outlined, color: AppColors.primaryPink, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkText), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(place.address, style: const TextStyle(fontSize: 12, color: AppColors.lightGray), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.lightGray, size: 14),
          ],
        ),
      ),
    );
  }
}
