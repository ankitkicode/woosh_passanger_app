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

/// Search Destination View — real Google Places Autocomplete
class SearchDestinationView extends ConsumerStatefulWidget {
  const SearchDestinationView({super.key});

  @override
  ConsumerState<SearchDestinationView> createState() => _SearchDestinationViewState();
}

class _SearchDestinationViewState extends ConsumerState<SearchDestinationView> {
  final TextEditingController _controller = TextEditingController();
  late final PlacesService _placesService;

  List<PlacePrediction> _predictions = [];
  List<PlaceDetails> _recentPlaces = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _placesService = PlacesService(_kGoogleApiKey);
    _loadNearbyPlaces();
  }

  /// Load nearby places as default suggestions
  Future<void> _loadNearbyPlaces() async {
    final rideState = ref.read(rideViewModelProvider);
    if (rideState.pickup != null) {
      final places = await _placesService.getNearbyPlaces(
        rideState.pickup!.latitude,
        rideState.pickup!.longitude,
      );
      if (mounted) {
        setState(() {
          _recentPlaces = places;
        });
      }
    }
  }

  /// Debounced search — waits 400ms after user stops typing
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

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final rideState = ref.read(rideViewModelProvider);
      final predictions = await _placesService.searchPlaces(
        query,
        lat: rideState.pickup?.latitude,
        lng: rideState.pickup?.longitude,
      );

      if (mounted) {
        setState(() {
          _predictions = predictions;
          _isSearching = false;
        });
      }
    });
  }

  /// When user taps a prediction, fetch its coordinates and navigate
  Future<void> _selectPrediction(PlacePrediction prediction) async {
    // Show a loading indicator
    setState(() => _isSearching = true);

    final details = await _placesService.getPlaceDetails(prediction.placeId);

    if (details != null && mounted) {
      ref.read(rideViewModelProvider.notifier).setDrop(
        RideLocation(
          latitude: details.latitude,
          longitude: details.longitude,
          address: '${details.name}, ${details.address}',
        ),
      );
      context.push('/confirm-ride');
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

  /// When user taps a nearby place (already has lat/lng)
  void _selectNearbyPlace(PlaceDetails place) {
    ref.read(rideViewModelProvider.notifier).setDrop(
      RideLocation(
        latitude: place.latitude,
        longitude: place.longitude,
        address: '${place.name}, ${place.address}',
      ),
    );
    context.push('/confirm-ride');
  }

  @override
  Widget build(BuildContext context) {
    final rideState = ref.watch(rideViewModelProvider);
    final pickupAddress = rideState.pickup?.address ?? 'Current Location';
    final hasQuery = _controller.text.trim().isNotEmpty;

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
                    onTap: () { if (context.canPop()) context.pop(); },
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.lightPink,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: AppColors.primaryPink, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Set Destination', style: AppTextStyles.actionTitle),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Location Input Fields ──
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
                child: Column(
                  children: [
                    // Pickup (read-only)
                    Row(
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
                              const Text('Pickup', style: TextStyle(fontSize: 10, color: AppColors.lightGray, fontWeight: FontWeight.w500)),
                              Text(pickupAddress, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.darkText), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Dotted line
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
                          const Expanded(child: Divider(height: 18, indent: 16, color: Color(0xFFEEEEEE))),
                        ],
                      ),
                    ),

                    // Drop search field
                    Row(
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
                          child: TextField(
                            controller: _controller,
                            autofocus: true,
                            onChanged: _onSearchChanged,
                            style: const TextStyle(fontSize: 15, color: AppColors.darkText, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              hintText: 'Search for a place...',
                              hintStyle: const TextStyle(color: AppColors.lightGray, fontWeight: FontWeight.w400),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              suffixIcon: hasQuery
                                  ? GestureDetector(
                                      onTap: () {
                                        _controller.clear();
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

            // ── Results ──
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
            Icon(Icons.search_off, size: 52, color: AppColors.borderPink),
            const SizedBox(height: 12),
            const Text('No places found', style: TextStyle(color: AppColors.lightGray, fontSize: 15)),
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
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: AppColors.lightPink,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.location_on, color: AppColors.primaryPink, size: 22),
          ),
          title: Text(
            prediction.mainText,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkText),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            prediction.secondaryText,
            style: const TextStyle(fontSize: 12, color: AppColors.lightGray),
            maxLines: 1, overflow: TextOverflow.ellipsis,
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
            Icon(Icons.near_me, size: 52, color: AppColors.borderPink),
            const SizedBox(height: 12),
            const Text('Type to search for your destination', style: TextStyle(color: AppColors.lightGray, fontSize: 14)),
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
            children: [
              Icon(Icons.near_me, color: AppColors.primaryPink, size: 16),
              const SizedBox(width: 6),
              const Text('Nearby suggestions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.darkText)),
            ],
          ),
        ),
        ..._recentPlaces.map((place) => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          leading: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: AppColors.lightPink,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.place_outlined, color: AppColors.primaryPink, size: 22),
          ),
          title: Text(
            place.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkText),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            place.address,
            style: const TextStyle(fontSize: 12, color: AppColors.lightGray),
            maxLines: 1, overflow: TextOverflow.ellipsis,
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
    _controller.dispose();
    super.dispose();
  }
}
