import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:reminder/config/maps_config.dart';

/// Google Places Nearby Search — market / süpermarket yakını (isteğe bağlı anahtar).
class NearbyPlaceResult {
  final String name;
  final LatLng location;
  final String? vicinity;

  const NearbyPlaceResult({
    required this.name,
    required this.location,
    this.vicinity,
  });
}

class PlacesNearbyService {
  const PlacesNearbyService();

  /// [types] örn. supermarket, grocery_or_supermarket (virgülle ayrılmış tek type önerilir).
  Future<List<NearbyPlaceResult>> searchNearby({
    required LatLng center,
    int radiusMeters = 600,
    String type = 'supermarket',
  }) async {
    if (!mapsConfigured) return [];

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/nearbysearch/json',
      {
        'location': '${center.latitude},${center.longitude}',
        'radius': '$radiusMeters',
        'type': type,
        'key': kGoogleMapsKey,
      },
    );

    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return [];
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      if (map['status'] != 'OK' && map['status'] != 'ZERO_RESULTS') {
        return [];
      }
      final results = map['results'] as List<dynamic>? ?? [];
      final out = <NearbyPlaceResult>[];
      for (final raw in results) {
        final m = raw as Map<String, dynamic>;
        final geom = m['geometry'] as Map<String, dynamic>?;
        final loc = geom?['location'] as Map<String, dynamic>?;
        if (loc == null) continue;
        final lat = (loc['lat'] as num).toDouble();
        final lng = (loc['lng'] as num).toDouble();
        out.add(
          NearbyPlaceResult(
            // Empty when unnamed; the picker shows a localized fallback.
            name: m['name'] as String? ?? '',
            location: LatLng(lat, lng),
            vicinity: m['vicinity'] as String?,
          ),
        );
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  /// Market kategorisi için sırayla dene.
  Future<List<NearbyPlaceResult>> searchNearbyMarkets(LatLng center) async {
    final a = await searchNearby(center: center, type: 'supermarket');
    if (a.isNotEmpty) return a;
    return searchNearby(center: center, type: 'grocery_or_supermarket');
  }
}
