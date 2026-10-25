import 'package:dio/dio.dart';
import '../../../data/services/api_client.dart';
import '../models/saved_place_model.dart';

class SavedPlacesService {
  final ApiClient _apiClient;

  SavedPlacesService(this._apiClient);

  Future<List<SavedPlace>> getSavedPlaces() async {
    try {
      final response = await _apiClient.get('/passenger/saved-places');
      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => SavedPlace.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<SavedPlace> createSavedPlace(SavedPlace place) async {
    try {
      final response = await _apiClient.post(
        '/passenger/saved-places',
        data: place.toJson(),
      );
      if (response.data['success'] == true) {
        return SavedPlace.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to save place');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<SavedPlace> updateSavedPlace(
    String placeId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiClient.put(
        '/passenger/saved-places/$placeId',
        data: data,
      );
      if (response.data['success'] == true) {
        return SavedPlace.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to update place');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> deleteSavedPlace(String placeId) async {
    try {
      final response = await _apiClient.delete(
        '/passenger/saved-places/$placeId',
      );
      return response.data['success'] == true;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic e) {
    if (e is DioException) {
      return Exception(e.response?.data['message'] ?? e.message);
    }
    return Exception(e.toString());
  }
}
