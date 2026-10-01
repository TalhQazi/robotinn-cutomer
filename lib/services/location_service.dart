import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../utils/area_helper.dart';

class LocationResult {
  final double lat;
  final double lng;
  final String address;

  LocationResult({
    required this.lat,
    required this.lng,
    required this.address,
  });
}

class LocationService {
  /// Fetches current GPS location with high reliability and fallback
  static Future<LocationResult> getCurrentLocationWithAddress({String? fallbackArea}) async {
    final cleanFallback = AreaHelper.cleanSectorName(fallbackArea ?? 'F-7');
    final defaultCoords = AreaHelper.resolveAreaCoords(cleanFallback) ?? {'lat': 33.7215, 'lng': 73.0565};

    try {
      bool serviceEnabled = false;
      try {
        serviceEnabled = await Geolocator.isLocationServiceEnabled().timeout(const Duration(seconds: 2));
      } catch (_) {}

      if (!serviceEnabled) {
        return LocationResult(
          lat: defaultCoords['lat']!,
          lng: defaultCoords['lng']!,
          address: '$cleanFallback, Islamabad',
        );
      }

      LocationPermission permission = LocationPermission.denied;
      try {
        permission = await Geolocator.checkPermission().timeout(const Duration(seconds: 2));
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission().timeout(const Duration(seconds: 4));
        }
      } catch (_) {}

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return LocationResult(
          lat: defaultCoords['lat']!,
          lng: defaultCoords['lng']!,
          address: '$cleanFallback, Islamabad',
        );
      }

      // 1. Try to get cached position first (returns instantly in < 50ms)
      Position? position;
      try {
        position = await Geolocator.getLastKnownPosition().timeout(const Duration(seconds: 2));
      } catch (_) {}

      // 2. If no cached position, get fresh GPS fix with tight timeout
      if (position == null) {
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 4),
            ),
          ).timeout(const Duration(seconds: 5));
        } catch (_) {}
      }

      if (position != null) {
        final addressStr = await getAddressFromCoordinates(
          position.latitude,
          position.longitude,
          fallbackArea: cleanFallback,
        );

        return LocationResult(
          lat: position.latitude,
          lng: position.longitude,
          address: addressStr,
        );
      }
    } catch (_) {}

    return LocationResult(
      lat: defaultCoords['lat']!,
      lng: defaultCoords['lng']!,
      address: '$cleanFallback, Islamabad',
    );
  }

  /// Reverse geocodes coordinates to street address using OpenStreetMap / Nominatim
  static Future<String> getAddressFromCoordinates(
    double lat,
    double lng, {
    String? fallbackArea,
  }) async {
    // 1. OpenStreetMap / Nominatim (Free, reliable, no key needed)
    try {
      final url = 'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json&addressdetails=1';
      final response = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'RobotInn-CustomerApp/1.0'})
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final addr = data['address'] as Map<String, dynamic>?;
        if (addr != null) {
          final road = addr['road'] ?? addr['street'] ?? addr['neighbourhood'];
          final sub = addr['suburb'] ?? addr['residential'] ?? addr['commercial'] ?? addr['city_district'];
          final city = addr['city'] ?? addr['town'] ?? 'Islamabad';

          final parts = [road, sub, city].where((e) => e != null && e.toString().trim().isNotEmpty).toList();
          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
        }
        final displayName = data['display_name']?.toString();
        if (displayName != null && displayName.isNotEmpty) {
          final tokens = displayName.split(',');
          if (tokens.length >= 3) {
            return '${tokens[0].trim()}, ${tokens[1].trim()}, ${tokens[2].trim()}';
          }
          return displayName;
        }
      }
    } catch (_) {}

    // 2. Match nearest Islamabad sector from coordinates
    final sector = resolveNearestSector(lat, lng);
    return '$sector, Islamabad';
  }

  /// Matches the nearest Islamabad sector for coordinates
  static String resolveNearestSector(double lat, double lng) {
    String best = 'F-7';
    double minD = double.infinity;
    for (final entry in AreaHelper.areaCoordinates.entries) {
      final dist = AreaHelper.haversineKm(lat, lng, entry.value['lat']!, entry.value['lng']!);
      if (dist < minD) {
        minD = dist;
        best = entry.key;
      }
    }
    return best;
  }
}
