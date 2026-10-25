import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/places_service.dart';
import '../../ride/view_models/ride_view_model.dart';
import '../../ride/models/ride_model.dart';

// Same API key as home_map_view — keep in sync
const String _kGoogleApiKey = 'AIzaSyCfmd3W3DPh3jYOeYx41Bva9GIxCmpo7UY';

/// Search Destination / Pickup View — Rapido-style location editor
class SearchDestinationView extends ConsumerStatefulWidget {
  final String initialFocus; // 'pickup' or 'drop'
  final bool fromConfirm;

  const SearchDestinationView({
    super.key,
    this.initialFocus = 'drop',
    this.fromConfirm = false,
  });

  @override
  ConsumerState<SearchDestinationView> createState() =>
      _SearchDestinationViewState();
}

class _SearchDestinationViewState extends ConsumerState<SearchDestinationView> {
  late final TextEditingController _pickupController;
  late final TextEditingController _dropController;
  late final FocusNode _pickupFocusNode;
  late final FocusNode _dropFocusNode;

  late final PlacesService _placesService;

  List<PlacePrediction> _predictions = [];
  List<PlaceDetails> _recentPlaces = [];
  bool _isSearching = false;
  String _activeField = 'drop'; // 'pickup' or 'drop'
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _activeField = widget.initialFocus;

    final rideState = ref.read(rideViewModelProvider);
    _pickupController = TextEditingController(
      text: rideState.pickup?.address ?? '',
    );
    _dropController = TextEditingController(
      text: rideState.drop?.address ?? '',
    );

    _pickupFocusNode = FocusNode();
    _dropFocusNode = FocusNode();

    _placesService = PlacesService(_kGoogleApiKey);
    _loadNearbyPlaces();

    _pickupFocusNode.addListener(() {
      if (_pickupFocusNode.hasFocus) {
        setState(() => _activeField = 'pickup');
        _onSearchChanged(_pickupController.text);
      }
    });

    _dropFocusNode.addListener(() {
      if (_dropFocusNode.hasFocus) {
        setState(() => _activeField = 'drop');
        _onSearchChanged(_dropController.text);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_activeField == 'pickup') {
        _pickupFocusNode.requestFocus();
      } else {
        _dropFocusNode.requestFocus();
      }
    });
  }

  /// Load nearby places as default suggestions
  Future<void> _loadNearbyPlaces() async {
    final rideState = ref.read(rideViewModelProvider);
    final refLocation = rideState.pickup ?? rideState.drop;
    if (refLocation != null) {
      final places = await _placesService.getNearbyPlaces(
        refLocation.latitude,
        refLocation.longitude,
      );
      if (mounted) {
        setState(() {
          _recentPlaces = places;
        });
      }
    }
  }

  /// Debounced search — waits 350ms after user stops typing
  void _onSearchChanged(String query) {
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _predictions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final rideState = ref.read(rideViewModelProvider);
      final refLocation = rideState.pickup ?? rideState.drop;
      final predictions = await _placesService.searchPlaces(
        query,
        lat: refLocation?.latitude,
        lng: refLocation?.longitude,
      );

      if (mounted) {
        setState(() {
          _predictions = predictions;
          _isSearching = false;
        });
      }
    });
  }

  /// When user taps a prediction, fetch details and update pickup or dropoff
  Future<void> _selectPrediction(PlacePrediction prediction) async {
    setState(() => _isSearching = true);

    final details = await _placesService.getPlaceDetails(prediction.placeId);

    if (details != null && mounted) {
      final newLocation = RideLocation(
        latitude: details.latitude,
        longitude: details.longitude,
        address: '${details.name}, ${details.address}',
      );

      final notifier = ref.read(rideViewModelProvider.notifier);
      if (_activeField == 'pickup') {
        notifier.setPickup(newLocation);
        _pickupController.text = newLocation.address ?? '';
      } else {
        notifier.setDrop(newLocation);
        _dropController.text = newLocation.address ?? '';
      }

      // Re-estimate fare
      notifier.estimateFare();

      // Navigate appropriately
      if (widget.fromConfirm && context.canPop()) {
        context.pop();
      } else {
        context.push('/confirm-ride');
      }
    } else if (mounted) {
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not fetch place details. Try again.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  /// When user taps a nearby place
  void _selectNearbyPlace(PlaceDetails place) {
    final newLocation = RideLocation(
      latitude: place.latitude,
      longitude: place.longitude,
      address: '${place.name}, ${place.address}',
    );

    final notifier = ref.read(rideViewModelProvider.notifier);
    if (_activeField == 'pickup') {
      notifier.setPickup(newLocation);
      _pickupController.text = newLocation.address ?? '';
    } else {
      notifier.setDrop(newLocation);
      _dropController.text = newLocation.address ?? '';
    }

    // Re-estimate fare
    notifier.estimateFare();

    if (widget.fromConfirm && context.canPop()) {
      context.pop();
    } else {
      context.push('/confirm-ride');
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeController = _activeField == 'pickup'
        ? _pickupController
        : _dropController;
    final hasQuery = activeController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (context.canPop()) context.pop();
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF4F4F4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Plan your ride',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            // ── Location Input Fields ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEAEAEA)),
                ),
                child: Row(
                  children: [
                    // Indicator
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00C853), // Green
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 36,
                          width: 2,
                          child: CustomPaint(painter: _DottedLinePainter()),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE91E63), // Pink
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Text Fields
                    Expanded(
                      child: Column(
                        children: [
                          // Pickup Field
                          TextField(
                            controller: _pickupController,
                            focusNode: _pickupFocusNode,
                            onChanged: _onSearchChanged,
                            textAlignVertical: TextAlignVertical.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Current location',
                              hintStyle: const TextStyle(
                                color: Colors.black54,
                                fontSize: 16,
                              ),
                              filled: true,
                              fillColor: _activeField == 'pickup'
                                  ? Colors.white
                                  : const Color(0xFFF4F4F4),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              isDense: true,

                              // Single outline border
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: _activeField == 'pickup'
                                      ? const Color(0xFFE91E63)
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE91E63),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Dropoff Field
                          TextField(
                            controller: _dropController,
                            focusNode: _dropFocusNode,
                            onChanged: _onSearchChanged,
                            textAlignVertical: TextAlignVertical.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Where to?',
                              hintStyle: const TextStyle(
                                color: Colors.black54,
                                fontSize: 16,
                              ),
                              isDense: true,
                              filled: true,
                              fillColor: _activeField == 'drop'
                                  ? Colors.white
                                  : const Color(0xFFF4F4F4),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: _activeField == 'drop'
                                      ? const Color(0xFFE91E63)
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE91E63),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Chips ──
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  _buildChip(Icons.home_outlined, 'Home'),
                  const SizedBox(width: 8),
                  _buildChip(Icons.work_outline, 'Work'),
                  const SizedBox(width: 8),
                  _buildChip(Icons.location_on_outlined, 'Choose on map'),
                ],
              ),
            ),

            // ── Loading indicator ──
            if (_isSearching)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryPink,
                    strokeWidth: 2,
                  ),
                ),
              ),

            // ── Results List ──
            Expanded(
              child: hasQuery ? _buildSearchResults() : _buildNearbyResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFE91E63), size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// Search results from Google Places Autocomplete
  Widget _buildSearchResults() {
    if (_predictions.isEmpty && !_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: AppColors.borderPink),
            const SizedBox(height: 12),
            const Text(
              'No places found',
              style: TextStyle(color: AppColors.lightGray, fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try a different search term',
              style: TextStyle(color: AppColors.lightGray, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('RESULTS'),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _predictions.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFF5F5F5)),
            itemBuilder: (_, i) {
              final prediction = _predictions[i];
              final isFirst = i == 0;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isFirst
                        ? const Color(0xFFFCE4EC)
                        : const Color(0xFFF4F4F4),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on_outlined,
                    color: isFirst ? const Color(0xFFE91E63) : Colors.black87,
                    size: 24,
                  ),
                ),
                title: Text(
                  prediction.mainText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  prediction.secondaryText,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF757575),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Text(
                  '2.4 km',
                  style: TextStyle(fontSize: 14, color: Color(0xFF757575)),
                ),
                onTap: () => _selectPrediction(prediction),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Nearby place suggestions when no search query
  Widget _buildNearbyResults() {
    if (_recentPlaces.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.near_me, size: 48, color: AppColors.borderPink),
            const SizedBox(height: 12),
            Text(
              _activeField == 'pickup'
                  ? 'Type to search for pickup location'
                  : 'Type to search for drop location',
              style: const TextStyle(color: AppColors.lightGray, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('RECENT'),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _recentPlaces.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFF5F5F5)),
            itemBuilder: (_, i) {
              final place = _recentPlaces[i];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4F4F4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.access_time,
                    color: Colors.black87,
                    size: 24,
                  ),
                ),
                title: Text(
                  place.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  place.address,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF757575),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _selectNearbyPlace(place),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF757575),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _pickupFocusNode.dispose();
    _dropFocusNode.dispose();
    _pickupController.dispose();
    _dropController.dispose();
    super.dispose();
  }
}

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFBDBDBD)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const double dashHeight = 3;
    const double dashSpace = 3;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
