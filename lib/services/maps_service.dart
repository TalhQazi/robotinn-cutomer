import 'dart:math';
import '../constants/app_constants.dart';

class MapsService {
  static double haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295; 
    final double a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); 
  }

  static String formatEtaWindow(double distanceKm) {
    if (distanceKm <= 0) return 'Arriving soon';
   
    final minutes = (distanceKm / 25 * 60).round();
    final lower = max(2, minutes - 3);
    final upper = max(5, minutes + 5);
    return '$lower–$upper mins';
  }

  static String getGoogleMapsUrl({
    required double riderLat,
    required double riderLng,
    required double destLat,
    required double destLng,
  }) {
    return 'https://www.google.com/maps/dir/?api=1&origin=$riderLat,$riderLng&destination=$destLat,$destLng&travelmode=driving';
  }

  static String buildStaticMapUrl({
    required double riderLat,
    required double riderLng,
    required double destLat,
    required double destLng,
  }) {
    return 'https://maps.googleapis.com/maps/api/staticmap?'
        'size=600x300'
        '&scale=2'
        '&markers=color:orange%7Clabel:R%7C$riderLat,$riderLng'
        '&markers=color:teal%7Clabel:D%7C$destLat,$destLng'
        '&path=color:0x2EC4B6ff%7Cweight:4%7C$riderLat,$riderLng%7C$destLat,$destLng'
        '&key=${AppConstants.googleMapsApiKey}';
  }
}
