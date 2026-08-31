import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Google Places + Geocoding service.
/// Uses Google Maps APIs directly with the API key.
class PlacesService {
  final String _apiKey;

  PlacesService(this._apiKey);

  // ─── Autocomplete Search (Places API New) ────────────────────────────

  /// Search for places using Google Places API (New) — Autocomplete.
  Future<List<PlacePrediction>> searchPlaces(String query, {double? lat, double? lng}) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse('https://places.googleapis.com/v1/places:autocomplete');

    final body = <String, dynamic>{
      'input': query,
      'includedRegionCodes': ['in'],
    };

    // Bias towards user's current location
    if (lat != null && lng != null) {
      body['locationBias'] = {
        'circle': {
          'center': {'latitude': lat, 'longitude': lng},
          'radius': 50000.0,
        },
      };
    }

    try {
      debugPrint('[PlacesService] Autocomplete search: "$query"');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

      debugPrint('[PlacesService] Autocomplete response: ${response.statusCode}');

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        debugPrint('[PlacesService] ⚠️ Autocomplete error: ${errorData['error']?['message'] ?? response.body}');

        // Fallback to Text Search if Autocomplete is not enabled
        debugPrint('[PlacesService] Trying fallback text search...');
        return _fallbackTextSearch(query, lat: lat, lng: lng);
      }

      final data = json.decode(response.body);
      final suggestions = data['suggestions'] as List? ?? [];
      debugPrint('[PlacesService] Found ${suggestions.length} suggestions');

      return suggestions.map((s) {
        final prediction = s['placePrediction'];
        if (prediction == null) return null;
        return PlacePrediction(
          placeId: prediction['placeId'] ?? '',
          mainText: prediction['structuredFormat']?['mainText']?['text'] ?? prediction['text']?['text'] ?? '',
          secondaryText: prediction['structuredFormat']?['secondaryText']?['text'] ?? '',
          description: prediction['text']?['text'] ?? '',
        );
      }).whereType<PlacePrediction>().toList();
    } catch (e) {
      debugPrint('[PlacesService] Autocomplete error: $e');
      return _fallbackTextSearch(query, lat: lat, lng: lng);
    }
  }

  /// Fallback: Use Geocoding API text search when Places API isn't enabled
  Future<List<PlacePrediction>> _fallbackTextSearch(String query, {double? lat, double? lng}) async {
    final params = <String, String>{
      'address': query,
      'key': _apiKey,
      'region': 'in',
    };

    if (lat != null && lng != null) {
      params['bounds'] = '${lat - 0.5},${lng - 0.5}|${lat + 0.5},${lng + 0.5}';
    }

    final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', params);

    try {
      debugPrint('[PlacesService] Fallback geocode search: "$query"');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];

      final data = json.decode(response.body);
      debugPrint('[PlacesService] Fallback status: ${data['status']}');

      if (data['status'] != 'OK') return [];

      final results = data['results'] as List;
      debugPrint('[PlacesService] Fallback found ${results.length} results');

      return results.take(8).map((r) {
        final formatted = r['formatted_address'] as String? ?? '';
        final parts = formatted.split(',');
        final mainText = parts.isNotEmpty ? parts.first.trim() : formatted;
        final secondaryText = parts.length > 1 ? parts.sublist(1).join(',').trim() : '';

        return PlacePrediction(
          placeId: r['place_id'] ?? '',
          mainText: mainText,
          secondaryText: secondaryText,
          description: formatted,
        );
      }).toList();
    } catch (e) {
      debugPrint('[PlacesService] Fallback search error: $e');
      return [];
    }
  }

  // ─── Place Details ───────────────────────────────────────────────────

  /// Get coordinates for a place using its placeId.
  /// Works with both new and legacy place IDs.
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    // Try the new Places API first
    try {
      final uri = Uri.parse('https://places.googleapis.com/v1/places/$placeId');
      final response = await http.get(uri, headers: {
        'X-Goog-Api-Key': _apiKey,
        'X-Goog-FieldMask': 'displayName,formattedAddress,location',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final loc = data['location'];
        if (loc != null) {
          return PlaceDetails(
            name: data['displayName']?['text'] ?? '',
            address: data['formattedAddress'] ?? '',
            latitude: (loc['latitude'] as num).toDouble(),
            longitude: (loc['longitude'] as num).toDouble(),
          );
        }
      }
    } catch (_) {}

    // Fallback: Use Geocoding API with place_id
    try {
      final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
        'place_id': placeId,
        'key': _apiKey,
      });

      debugPrint('[PlacesService] Geocode place details for: $placeId');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);
      if (data['status'] != 'OK') return null;

      final results = data['results'] as List;
      if (results.isEmpty) return null;

      final result = results[0];
      final loc = result['geometry']['location'];

      return PlaceDetails(
        name: _extractName(result),
        address: result['formatted_address'] ?? '',
        latitude: (loc['lat'] as num).toDouble(),
        longitude: (loc['lng'] as num).toDouble(),
      );
    } catch (e) {
      debugPrint('[PlacesService] Place details error: $e');
      return null;
    }
  }

  /// Extract a short name from geocode result
  String _extractName(Map<String, dynamic> result) {
    final components = result['address_components'] as List? ?? [];
    // Try to get sublocality or locality
    for (final comp in components) {
      final types = (comp['types'] as List? ?? []).cast<String>();
      if (types.contains('sublocality_level_1') || types.contains('point_of_interest') || types.contains('establishment')) {
        return comp['long_name'] ?? '';
      }
    }
    // Fallback to first component
    if (components.isNotEmpty) {
      return components[0]['long_name'] ?? '';
    }
    // Fallback to first part of formatted address
    final formatted = result['formatted_address'] as String? ?? '';
    return formatted.split(',').first.trim();
  }

  // ─── Reverse Geocoding ───────────────────────────────────────────────

  /// Get address from coordinates using Google Maps Geocoding API.
  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/geocode/json',
      {
        'latlng': '$lat,$lng',
        'key': _apiKey,
      },
    );

    try {
      debugPrint('[PlacesService] Reverse geocode: $lat, $lng');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('[PlacesService] Reverse geocode HTTP error: ${response.statusCode}');
        return 'Current Location';
      }

      final data = json.decode(response.body);
      debugPrint('[PlacesService] Reverse geocode status: ${data['status']}');

      if (data['status'] == 'OK') {
        final results = data['results'] as List;
        if (results.isNotEmpty) {
          final fullAddress = results[0]['formatted_address'] as String;
          // Take first 2-3 parts for a cleaner display
          final parts = fullAddress.split(',').take(3).map((s) => s.trim()).toList();
          final shortAddress = parts.join(', ');
          debugPrint('[PlacesService] Address: $shortAddress');
          return shortAddress;
        }
      }

      return 'Current Location';
    } catch (e) {
      debugPrint('[PlacesService] Reverse geocode error: $e');
      return 'Current Location';
    }
  }

  // ─── Nearby Places ──────────────────────────────────────────────────

  /// Get nearby popular places — uses Geocoding-based approach as fallback
  Future<List<PlaceDetails>> getNearbyPlaces(double lat, double lng) async {
    // Try Places API (New) nearby search
    try {
      final uri = Uri.parse('https://places.googleapis.com/v1/places:searchNearby');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask': 'places.displayName,places.formattedAddress,places.location',
        },
        body: json.encode({
          'includedTypes': ['restaurant', 'shopping_mall', 'hospital', 'bus_station', 'train_station', 'school'],
          'maxResultCount': 10,
          'locationRestriction': {
            'circle': {
              'center': {'latitude': lat, 'longitude': lng},
              'radius': 5000.0,
            },
          },
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final places = data['places'] as List? ?? [];
        debugPrint('[PlacesService] Nearby found ${places.length} places');

        return places.map((p) {
          final loc = p['location'];
          return PlaceDetails(
            name: p['displayName']?['text'] ?? '',
            address: p['formattedAddress'] ?? '',
            latitude: (loc['latitude'] as num).toDouble(),
            longitude: (loc['longitude'] as num).toDouble(),
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('[PlacesService] Nearby API error (trying fallback): $e');
    }

    // Fallback: use geocode searches for common nearby categories
    debugPrint('[PlacesService] Using fallback nearby search');
    final categories = ['station near me', 'mall near me', 'hospital near me', 'school near me'];
    final List<PlaceDetails> results = [];

    for (final category in categories) {
      final predictions = await _fallbackTextSearch(category, lat: lat, lng: lng);
      for (final p in predictions.take(2)) {
        final details = await getPlaceDetails(p.placeId);
        if (details != null) {
          results.add(details);
        }
      }
      if (results.length >= 6) break;
    }

    return results;
  }
}

// ─── Data Classes ────────────────────────────────────────────────────────

class PlacePrediction {
  final String placeId;
  final String mainText;
  final String secondaryText;
  final String description;

  const PlacePrediction({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.description,
  });
}

class PlaceDetails {
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  const PlaceDetails({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}
