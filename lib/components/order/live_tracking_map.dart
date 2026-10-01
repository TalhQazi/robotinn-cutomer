import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_spacing.dart';
import '../../services/maps_service.dart';

class LiveTrackingMap extends StatefulWidget {
  final Map<String, dynamic>? riderCoords;
  final Map<String, dynamic>? destinationCoords;
  final bool isTracking;
  final double height;

  const LiveTrackingMap({
    super.key,
    this.riderCoords,
    this.destinationCoords,
    this.isTracking = false,
    this.height = 240,
  });

  @override
  State<LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends State<LiveTrackingMap> {
  GoogleMapController? _mapController;

  double? get riderLat =>
      (widget.riderCoords?['lat'] as num?)?.toDouble() ??
      (widget.riderCoords?['latitude'] as num?)?.toDouble();

  double? get riderLng =>
      (widget.riderCoords?['lng'] as num?)?.toDouble() ??
      (widget.riderCoords?['longitude'] as num?)?.toDouble();

  double get effectiveDestLat =>
      (widget.destinationCoords?['lat'] as num?)?.toDouble() ??
      (widget.destinationCoords?['latitude'] as num?)?.toDouble() ??
      33.7215; // Islamabad center fallback

  double get effectiveDestLng =>
      (widget.destinationCoords?['lng'] as num?)?.toDouble() ??
      (widget.destinationCoords?['longitude'] as num?)?.toDouble() ??
      73.0565;

  bool get hasRider => riderLat != null && riderLng != null;

  @override
  void didUpdateWidget(covariant LiveTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.riderCoords != oldWidget.riderCoords ||
        widget.destinationCoords != oldWidget.destinationCoords) {
      _updateCamera();
    }
  }

  void _updateCamera() {
    if (_mapController == null) return;
    if (hasRider) {
      final south = min(riderLat!, effectiveDestLat);
      final north = max(riderLat!, effectiveDestLat);
      final west = min(riderLng!, effectiveDestLng);
      final east = max(riderLng!, effectiveDestLng);
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(south - 0.003, west - 0.003),
            northeast: LatLng(north + 0.003, east + 0.003),
          ),
          50.0,
        ),
      );
    } else {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(effectiveDestLat, effectiveDestLng), 14.5),
      );
    }
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    // 1. Destination Marker (Cyan)
    markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(effectiveDestLat, effectiveDestLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        infoWindow: const InfoWindow(
          title: 'Delivery Address',
          snippet: 'Your order delivery location',
        ),
      ),
    );

    // 2. Rider Marker (Orange)
    if (hasRider) {
      markers.add(
        Marker(
          markerId: const MarkerId('rider'),
          position: LatLng(riderLat!, riderLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: const InfoWindow(
            title: 'Rider Location',
            snippet: 'Live Rider GPS Tracking',
          ),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildPolylines() {
    if (hasRider) {
      return {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [
            LatLng(riderLat!, riderLng!),
            LatLng(effectiveDestLat, effectiveDestLng),
          ],
          color: AppColors.primary,
          width: 4,
        ),
      };
    }
    return {};
  }

  LatLng _getCenter() {
    if (hasRider) {
      return LatLng((riderLat! + effectiveDestLat) / 2, (riderLng! + effectiveDestLng) / 2);
    }
    return LatLng(effectiveDestLat, effectiveDestLng);
  }

  double _getDistanceKm() {
    if (hasRider) {
      return MapsService.haversineKm(riderLat!, riderLng!, effectiveDestLat, effectiveDestLng);
    }
    return 0.0;
  }

  Future<void> _openExternalMaps() async {
    if (hasRider) {
      final url = MapsService.getGoogleMapsUrl(
        riderLat: riderLat!,
        riderLng: riderLng!,
        destLat: effectiveDestLat,
        destLng: effectiveDestLng,
      );
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      final url = 'https://www.google.com/maps/search/?api=1&query=$effectiveDestLat,$effectiveDestLng';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dist = _getDistanceKm();
    final etaText = MapsService.formatEtaWindow(dist);

    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _getCenter(),
                zoom: hasRider ? 13.5 : 14.5,
              ),
              markers: _buildMarkers(),
              polylines: _buildPolylines(),
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
                _updateCamera();
              },
            ),

            // Top Status Overlay
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.darkAccent.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasRider ? Icons.delivery_dining_rounded : Icons.location_on_rounded,
                          size: 16,
                          color: hasRider ? AppColors.primary : AppColors.secondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          hasRider ? 'Live Rider Tracking' : 'Delivery Destination',
                          style: AppTypography.caption.copyWith(color: AppColors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (hasRider && dist > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_outlined, size: 14, color: AppColors.white),
                          const SizedBox(width: 4),
                          Text(
                            '$etaText (${dist.toStringAsFixed(1)} km)',
                            style: AppTypography.caption.copyWith(color: AppColors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  else if (!hasRider)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Dispatching soon',
                        style: AppTypography.caption.copyWith(color: AppColors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),

            // External Maps & Re-center Buttons
            Positioned(
              bottom: 12,
              right: 12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'map_center_${DateTime.now().microsecondsSinceEpoch}',
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 4,
                    onPressed: _updateCamera,
                    child: const Icon(Icons.my_location_rounded, size: 18),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    heroTag: 'map_external_${DateTime.now().microsecondsSinceEpoch}',
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.primary,
                    elevation: 4,
                    onPressed: _openExternalMaps,
                    child: const Icon(Icons.directions_rounded, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
