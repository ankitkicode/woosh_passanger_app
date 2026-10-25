import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/di_providers.dart';
import '../models/saved_place_model.dart';
import '../services/saved_places_service.dart';

final savedPlacesServiceProvider = Provider<SavedPlacesService>((ref) {
  return SavedPlacesService(ref.read(apiClientProvider));
});

final savedPlacesProvider =
    StateNotifierProvider<SavedPlacesViewModel, AsyncValue<List<SavedPlace>>>((
      ref,
    ) {
      return SavedPlacesViewModel(ref.read(savedPlacesServiceProvider));
    });

class SavedPlacesViewModel extends StateNotifier<AsyncValue<List<SavedPlace>>> {
  final SavedPlacesService _service;

  SavedPlacesViewModel(this._service) : super(const AsyncValue.loading()) {
    fetchSavedPlaces();
  }

  Future<void> fetchSavedPlaces() async {
    state = const AsyncValue.loading();
    try {
      final places = await _service.getSavedPlaces();
      state = AsyncValue.data(places);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<bool> addSavedPlace(SavedPlace place) async {
    try {
      final newPlace = await _service.createSavedPlace(place);
      if (state.hasValue) {
        state = AsyncValue.data([...state.value!, newPlace]);
      } else {
        state = AsyncValue.data([newPlace]);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateSavedPlace(
    String placeId,
    Map<String, dynamic> data,
  ) async {
    try {
      final updatedPlace = await _service.updateSavedPlace(placeId, data);
      if (state.hasValue) {
        final currentPlaces = state.value!;
        final index = currentPlaces.indexWhere((p) => p.id == placeId);
        if (index != -1) {
          final newPlaces = List<SavedPlace>.from(currentPlaces);
          newPlaces[index] = updatedPlace;
          state = AsyncValue.data(newPlaces);
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteSavedPlace(String placeId) async {
    try {
      final success = await _service.deleteSavedPlace(placeId);
      if (success && state.hasValue) {
        state = AsyncValue.data(
          state.value!.where((p) => p.id != placeId).toList(),
        );
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  SavedPlace? getPlaceByType(String type) {
    if (state.hasValue) {
      final places = state.value!;
      try {
        return places.firstWhere((p) => p.type == type);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
