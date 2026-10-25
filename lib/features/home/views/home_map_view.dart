import 'dart:async';
import 'dart:ui' as ui;
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
import '../../../providers/di_providers.dart';
import '../../saved_places/view_models/saved_places_view_model.dart';

// Google Maps API Key — same as AndroidManifest.xml
const String _kGoogleApiKey = 'AIzaSyCfmd3W3DPh3jYOeYx41Bva9GIxCmpo7UY';

class HomeMapView extends ConsumerStatefulWidget {
  const HomeMapView({super.key});

  @override
  ConsumerState<HomeMapView> createState() => _HomeMapViewState();
}

class _HomeMapViewState extends ConsumerState<HomeMapView>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(23.2599, 77.4126); // Bhopal default
  bool _locationLoaded = false;
  String _currentAddress = 'Fetching location...';
  bool _fetchingAddress = true;
  bool _isLoadingRiders = true;
  final Map<String, String> _userIdToRiderId = {};

  bool _isServiceAvailable = true;
  bool _citiesLoaded = false;
  List<dynamic> _cities = [];

  late final PlacesService _placesService;
  List<PlaceDetails> _nearbyPlaces = [];
  Map<String, Marker> _riderMarkers = {};
  BitmapDescriptor? _bikeMarkerIcon;
  BitmapDescriptor? _pickupPinIcon;

  @override
  void initState() {
    super.initState();
    _placesService = PlacesService(_kGoogleApiKey);
    _fetchCities();
    _getCurrentLocation();
    _initSocket();
    _loadMarkerIcons();
    _checkActiveRideOnStart();
  }

  Future<void> _checkActiveRideOnStart() async {
    try {
      final rideViewModel = ref.read(rideViewModelProvider.notifier);
      final activeRide = await rideViewModel.checkActiveRide();

      if (!mounted) return;

      if (activeRide != null) {
        final status = activeRide.status.toLowerCase();
        if (status == 'pending') {
          context.go('/searching/${activeRide.id}');
        } else if (status == 'accepted' ||
            status == 'rider_arrived' ||
            status == 'arrived') {
          context.go('/rider-found/${activeRide.id}');
        } else if (status == 'started' || status == 'in_progress') {
          context.go('/ride-active/${activeRide.id}');
        } else if (status == 'completed' &&
            activeRide.paymentStatus.toLowerCase() == 'pending') {
          context.go('/ride-complete/${activeRide.id}');
        }
      }
    } catch (_) {}
  }

  Future<void> _loadMarkerIcons() async {
    final bikeIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(44, 44)),
      'assets/bike_marker.png',
    );
    final pickupIcon = await _createTargetMarkerIcon(
      color: const Color(0xFF4CAF50), // Green for pickup point
    );
    if (mounted) {
      setState(() {
        _bikeMarkerIcon = bikeIcon;
        _pickupPinIcon = pickupIcon;
      });
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

  Future<void> _fetchCities() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/cities');
      if (response.data['success'] == true) {
        _cities = response.data['data'];
        _citiesLoaded = true;
        if (mounted && _locationLoaded) {
          _checkServiceAvailability(
            _currentPosition.latitude,
            _currentPosition.longitude,
          );
        }
      }
    } catch (e) {
      debugPrint('Cities fetch error: $e');
    }
  }



  void _checkServiceAvailability(double lat, double lng) {
    if (!_citiesLoaded || _cities.isEmpty) {
      if (mounted) {
        setState(() {
          _isServiceAvailable = false;
        });
      }
      return;
    }

    bool available = false;
    for (var city in _cities) {
      if (city['isActive'] == true) {
        double cLat = (city['latitude'] ?? 0.0).toDouble();
        double cLng = (city['longitude'] ?? 0.0).toDouble();
        double cRad = (city['serviceRadius'] ?? 0.0).toDouble();

        double distanceToCity = Geolocator.distanceBetween(
          lat,
          lng,
          cLat,
          cLng,
        );
        if (distanceToCity <= cRad * 1000) {
          available = true;
          break;
        }

        if (city['areas'] != null) {
          for (var area in city['areas']) {
            if (area['isActive'] == true) {
              double aLat = (area['latitude'] ?? 0.0).toDouble();
              double aLng = (area['longitude'] ?? 0.0).toDouble();
              double aRad = (area['serviceRadius'] ?? 0.0).toDouble();

              double distanceToArea = Geolocator.distanceBetween(
                lat,
                lng,
                aLat,
                aLng,
              );
              if (distanceToArea <= aRad * 1000) {
                available = true;
                break;
              }
            }
          }
        }
        if (available) break;
      }
    }

    if (mounted) {
      setState(() {
        _isServiceAvailable = available;
      });

      if (!available) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'In this area service is not available. Coming soon.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _initSocket() {
    final socketService = SocketService();
    socketService.onLocationUpdate = (data) {
      if (!mounted) return;
      final rawRiderId = data['riderId'] ?? data['userId'] ?? '';
      final riderId = _userIdToRiderId[rawRiderId] ?? rawRiderId;
      if (riderId.isEmpty) return;

      final lat = data['latitude'];
      final lng = data['longitude'];

      setState(() {
        _riderMarkers[riderId] = Marker(
          markerId: MarkerId(riderId),
          position: LatLng(lat, lng),
          icon:
              _bikeMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
          infoWindow: const InfoWindow(title: 'Woosh Rider'),
        );
      });
    };

    socketService.onRiderStatusChanged = (data) {
      if (!mounted) return;
      final rawRiderId = data['riderId'] ?? data['userId'] ?? '';
      final riderId = _userIdToRiderId[rawRiderId] ?? rawRiderId;
      if (riderId.isEmpty) return;

      final isOnline = data['isOnline'];

      setState(() {
        if (!isOnline) {
          _riderMarkers.remove(riderId);
        } else if (data['latitude'] != null && data['longitude'] != null) {
          _riderMarkers[riderId] = Marker(
            markerId: MarkerId(riderId),
            position: LatLng(data['latitude'], data['longitude']),
            icon:
                _bikeMarkerIcon ??
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _locationLoaded = true;
      });

      if (_citiesLoaded) {
        _checkServiceAvailability(position.latitude, position.longitude);
      }

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, 16),
      );

      // Set pickup in ride state
      ref
          .read(rideViewModelProvider.notifier)
          .setPickup(
            RideLocation(
              latitude: position.latitude,
              longitude: position.longitude,
              address: 'Current Location',
            ),
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
        ref
            .read(rideViewModelProvider.notifier)
            .setPickup(
              RideLocation(
                latitude: position.latitude,
                longitude: position.longitude,
                address: address,
              ),
            );
      }

      // Load nearby places for suggestions
      _loadNearbyPlaces(position.latitude, position.longitude);

      // Fetch nearby riders
      _fetchNearbyRiders(position.latitude, position.longitude);
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

  Future<void> _fetchNearbyRiders(double lat, double lng) async {
    if (mounted) {
      setState(() {
        _isLoadingRiders = true;
      });
    }
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get(
        '/ride/nearby-riders',
        queryParameters: {'latitude': lat, 'longitude': lng},
      );

      if (response.data['success'] == true) {
        final List<dynamic> riders = response.data['data'] ?? [];
        final String message =
            response.data['message'] ?? 'No riders available at the moment';

        if (riders.isEmpty && mounted) {
          showDialog(
            context: context,
            builder: (ctx) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.lightPink,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryPink.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.two_wheeler_rounded,
                          color: AppColors.primaryPink,
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No Riders Nearby',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message.isNotEmpty ? message : 'No riders available at the moment. Hang tight, we are expanding super fast! 💖',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPink,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Got it, Bestie!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (mounted) {
          setState(() {
            _riderMarkers.clear();
            _userIdToRiderId.clear();
            for (var rider in riders) {
              final String riderId = rider['_id'] ?? '';
              final user = rider['user'] as Map<String, dynamic>?;
              final String userId = user?['_id'] ?? '';
              final String riderName = user?['name'] ?? 'Woosh Rider';

              if (riderId.isNotEmpty) {
                _userIdToRiderId[riderId] = riderId;
                if (userId.isNotEmpty) {
                  _userIdToRiderId[userId] = riderId;
                }
              }

              final coords =
                  rider['currentLocation']?['coordinates'] as List<dynamic>?;

              if (riderId.isNotEmpty && coords != null && coords.length == 2) {
                // GeoJSON coordinates are [longitude, latitude]
                final double rLng = (coords[0] as num).toDouble();
                final double rLat = (coords[1] as num).toDouble();

                _riderMarkers[riderId] = Marker(
                  markerId: MarkerId(riderId),
                  position: LatLng(rLat, rLng),
                  icon:
                      _bikeMarkerIcon ??
                      BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRose,
                      ),
                  infoWindow: InfoWindow(title: riderName),
                );
              }
            }
            _isLoadingRiders = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingRiders = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Nearby riders fetch error: $e');
      if (mounted) {
        setState(() {
          _isLoadingRiders = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    final rideState = ref.watch(rideViewModelProvider);

    final homePlace = ref
        .read(savedPlacesProvider.notifier)
        .getPlaceByType('home');
    final workPlace = ref
        .read(savedPlacesProvider.notifier)
        .getPlaceByType('work');

    final markers = Set<Marker>.from(_riderMarkers.values);

    final LatLng pickupLatLng = rideState.pickup != null
        ? LatLng(rideState.pickup!.latitude, rideState.pickup!.longitude)
        : _currentPosition;

    if (_locationLoaded && _pickupPinIcon != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickupLatLng,
          icon: _pickupPinIcon!,
          anchor: const Offset(0.6, 1.7),
          infoWindow: const InfoWindow(title: 'Pickup Point'),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,

      body: Stack(
        children: [
          // ── Full-screen Google Map ──
          GoogleMap(
            padding: EdgeInsets.only(
              top: screenHeight * 0.12,
              bottom: screenHeight * 0.30,
            ),
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 16,
            ),
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            markers: markers,
            onMapCreated: (c) {
              _mapController = c;
              if (_locationLoaded) {
                c.animateCamera(
                  CameraUpdate.newLatLngZoom(_currentPosition, 16),
                );
              }
            },
          ),

          // ── Top: Logo + Search + SOS ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Logo
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.brandGradient,
                    ),
                    padding: const EdgeInsets.all(2.5),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/logo_icon.png',
                          fit: BoxFit.contain,
                          height: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Search Bar / Current Area
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.primaryPink,
                            size: 20,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              _fetchingAddress
                                  ? 'Fetching...'
                                  : _currentAddress,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.darkText,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // SOS Button
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.errorRed,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'SOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── My Location FAB & Women Riders Badge ──
          Positioned(
            bottom: screenHeight * 0.43,
            left: 16,
            right: 16,

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Women riders nearby badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isLoadingRiders
                            ? 'Finding riders...'
                            : '${_riderMarkers.length} women riders nearby',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkText,
                        ),
                      ),
                    ],
                  ),
                ),
                // My location FAB
                GestureDetector(
                  onTap: _getCurrentLocation,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.my_location,
                      color: AppColors.darkText,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom Sheet ──
          DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.45,
            maxChildSize: 0.90,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 20,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        children: [
                          // Handle
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

                          // Where to? + Now Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Where to?',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkText,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: AppColors.darkText,
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Now',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Pickup + Drop input card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAFAFA), // very light gray
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                // Left column with dots and line
                                Column(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: Colors.green, // #00B14F
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    // Dotted line
                                    Column(
                                      children: List.generate(
                                        6,
                                        (_) => Container(
                                          width: 1.5,
                                          height: 3,
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 1.5,
                                          ),
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primaryPink,
                                        shape: BoxShape.rectangle,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                // Middle column with texts
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Pickup',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _fetchingAddress
                                            ? 'Fetching...'
                                            : _currentAddress,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.darkText,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 16),
                                      Divider(
                                        height: 1,
                                        color: Colors.grey.shade300,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Drop',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      GestureDetector(
                                        onTap: () {
                                          if (!_isServiceAvailable) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'In this area service is not available. Coming soon.',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                            return;
                                          }
                                          context.push('/search');
                                        },
                                        child: const Text(
                                          'Where are you going?',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Right column Swap button
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightPink,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.swap_vert,
                                    color: AppColors.primaryPink,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Quick options
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _QuickOption(
                                  icon: Icons.home_outlined,
                                  label: homePlace != null
                                      ? homePlace.title
                                      : 'Home',
                                  isPink: true,
                                  onTap: () {
                                    if (homePlace != null) {
                                      ref
                                          .read(rideViewModelProvider.notifier)
                                          .setDrop(
                                            RideLocation(
                                              latitude: homePlace.latitude,
                                              longitude: homePlace.longitude,
                                              address: homePlace.address,
                                            ),
                                          );
                                      context.push('/search');
                                    } else {
                                      // TODO: Navigate to add Home place screen
                                      context.push('/search');
                                    }
                                  },
                                ),
                                const SizedBox(width: 8),
                                _QuickOption(
                                  icon: Icons.work_outline,
                                  label: workPlace != null
                                      ? workPlace.title
                                      : 'Work',
                                  isPink: true,
                                  onTap: () {
                                    if (workPlace != null) {
                                      ref
                                          .read(rideViewModelProvider.notifier)
                                          .setDrop(
                                            RideLocation(
                                              latitude: workPlace.latitude,
                                              longitude: workPlace.longitude,
                                              address: workPlace.address,
                                            ),
                                          );
                                      context.push('/search');
                                    } else {
                                      // TODO: Navigate to add Work place screen
                                      context.push('/search');
                                    }
                                  },
                                ),
                                const SizedBox(width: 8),
                                _QuickOption(
                                  icon: Icons.add,
                                  label: 'Add place',
                                  isPink: false,
                                  onTap: () {
                                    // TODO: Navigate to saved places list / add place screen
                                    context.push('/search');
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Nearby places
                          if (_nearbyPlaces.isNotEmpty)
                            ..._nearbyPlaces
                                .take(3)
                                .map(
                                  (place) => Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: GestureDetector(
                                      onTap: () {
                                        ref
                                            .read(
                                              rideViewModelProvider.notifier,
                                            )
                                            .setDrop(
                                              RideLocation(
                                                latitude: place.latitude,
                                                longitude: place.longitude,
                                                address: place.address,
                                              ),
                                            );
                                        context.push('/search');
                                      },
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFF5F5F5),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.location_on_outlined,
                                              color: Colors.black87,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  place.name,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.darkText,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  place.address,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                          if (_nearbyPlaces.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryPink,
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),

                    // Safety Banner at bottom
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.lightPink,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.verified_user_outlined,
                            color: AppColors.primaryPink,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Every rider is a verified woman · Live trip sharing · 24×7 SOS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryPink,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
  final bool isPink;
  final VoidCallback onTap;
  const _QuickOption({
    required this.icon,
    required this.label,
    required this.isPink,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isPink ? AppColors.primaryPink : Colors.grey,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
