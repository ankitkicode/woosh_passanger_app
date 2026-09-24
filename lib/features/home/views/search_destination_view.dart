import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
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
  ConsumerState<SearchDestinationView> createState() => _SearchDestinationViewState();
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
    _pickupController = TextEditingController(text: rideState.pickup?.address ?? '');
    _dropController = TextEditingController(text: rideState.drop?.address ?? '');

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

  /// Swap pickup and dropoff locations
  void _swapLocations() {
    final rideState = ref.read(rideViewModelProvider);
    final currentPickup = rideState.pickup;
    final currentDrop = rideState.drop;

    if (currentPickup != null && currentDrop != null) {
      final notifier = ref.read(rideViewModelProvider.notifier);
      notifier.setPickup(currentDrop);
      notifier.setDrop(currentPickup);

      setState(() {
        _pickupController.text = currentDrop.address ?? '';
        _dropController.text = currentPickup.address ?? '';
      });

      notifier.estimateFare();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeController = _activeField == 'pickup' ? _pickupController : _dropController;
    final hasQuery = activeController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (context.canPop()) context.pop();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.lightPink,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: AppColors.primaryPink, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _activeField == 'pickup' ? 'Set Pickup Location' : 'Set Drop Location',
                    style: AppTextStyles.actionTitle,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Location Input Fields (Rapido Style) ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.dividerColor),
                  boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)],
                ),
                child: Row(
                  children: [
                    // Column with dots & connector line
                    Column(
                      children: [
                        // Pickup dot (Green)
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.green.shade200, width: 2),
                          ),
                        ),
                        // Connector line
                        Container(
                          width: 2,
                          height: 24,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: AppColors.lightGray.withValues(alpha: 0.3),
                        ),
                        // Dropoff dot (Red/Pink)
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.red.shade200, width: 2),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 12),

                    // Inputs Column
                    Expanded(
                      child: Column(
                        children: [
                          // Pickup Field
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: _activeField == 'pickup' ? AppColors.lightPink : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TextField(
                              controller: _pickupController,
                              focusNode: _pickupFocusNode,
                              onChanged: _onSearchChanged,
                              style: const TextStyle(fontSize: 14, color: AppColors.darkText, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                hintText: 'Search pickup location...',
                                hintStyle: const TextStyle(color: AppColors.lightGray, fontSize: 13, fontWeight: FontWeight.w400),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                suffixIcon: _activeField == 'pickup' && _pickupController.text.isNotEmpty
                                    ? GestureDetector(
                                        onTap: () {
                                          _pickupController.clear();
                                          _onSearchChanged('');
                                        },
                                        child: const Icon(Icons.close, color: AppColors.lightGray, size: 18),
                                      )
                                    : null,
                              ),
                            ),
                          ),

                          const Divider(height: 12, color: Color(0xFFEEEEEE)),

                          // Dropoff Field
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: _activeField == 'drop' ? AppColors.lightPink : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TextField(
                              controller: _dropController,
                              focusNode: _dropFocusNode,
                              onChanged: _onSearchChanged,
                              style: const TextStyle(fontSize: 14, color: AppColors.darkText, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                hintText: 'Search drop location...',
                                hintStyle: const TextStyle(color: AppColors.lightGray, fontSize: 13, fontWeight: FontWeight.w400),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                suffixIcon: _activeField == 'drop' && _dropController.text.isNotEmpty
                                    ? GestureDetector(
                                        onTap: () {
                                          _dropController.clear();
                                          _onSearchChanged('');
                                        },
                                        child: const Icon(Icons.close, color: AppColors.lightGray, size: 18),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Swap Button
                    GestureDetector(
                      onTap: _swapLocations,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF0F0F5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.swap_vert,
                          color: AppColors.primaryPink,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Loading indicator ──
            if (_isSearching)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator(color: AppColors.primaryPink, strokeWidth: 2)),
              ),

            // ── Results List ──
            Expanded(
              child: hasQuery
                  ? _buildSearchResults()
                  : _buildNearbyResults(),
            ),
          ],
        ),
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
            const Text('No places found', style: TextStyle(color: AppColors.lightGray, fontSize: 14)),
            const SizedBox(height: 4),
            const Text('Try a different search term', style: TextStyle(color: AppColors.lightGray, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _predictions.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF5F5F5)),
      itemBuilder: (_, i) {
        final prediction = _predictions[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.lightPink,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _activeField == 'pickup' ? Icons.my_location : Icons.location_on,
              color: AppColors.primaryPink,
              size: 20,
            ),
          ),
          title: Text(
            prediction.mainText,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkText),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            prediction.secondaryText,
            style: const TextStyle(fontSize: 12, color: AppColors.lightGray),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.north_west, color: AppColors.lightGray, size: 16),
          onTap: () => _selectPrediction(prediction),
        );
      },
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
              _activeField == 'pickup' ? 'Type to search for pickup location' : 'Type to search for drop location',
              style: const TextStyle(color: AppColors.lightGray, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: const [
              Icon(Icons.near_me, color: AppColors.primaryPink, size: 16),
              SizedBox(width: 6),
              Text('Nearby suggestions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.darkText)),
            ],
          ),
        ),
        ..._recentPlaces.map((place) => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.lightPink,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.place_outlined, color: AppColors.primaryPink, size: 20),
          ),
          title: Text(
            place.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkText),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            place.address,
            style: const TextStyle(fontSize: 12, color: AppColors.lightGray),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.lightGray, size: 14),
          onTap: () => _selectNearbyPlace(place),
        )),
      ],
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
