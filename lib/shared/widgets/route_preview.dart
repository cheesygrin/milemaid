import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:milemaid/core/config/app_config.dart';
import 'package:milemaid/core/constants/app_colors.dart';

/// Small, non-interactive route map shown at the top of a drive card.
///
/// The live map renders once, then is replaced by a still snapshot so that
/// swiping the card stays smooth and a list of cards doesn't keep several
/// native map views alive. Snapshots are cached per drive for the session.
class RoutePreview extends StatefulWidget {
  const RoutePreview({
    super.key,
    required this.cacheKey,
    required this.points,
    this.height = 130,
  });

  /// Unique per drive (and per route), e.g. "<tripId>:<pointCount>".
  final String cacheKey;
  final List<LatLng> points;
  final double height;

  @override
  State<RoutePreview> createState() => _RoutePreviewState();
}

class _RoutePreviewState extends State<RoutePreview> {
  static final Map<String, Uint8List> _snapshots = {};

  Uint8List? _image;

  @override
  void initState() {
    super.initState();
    _image = _snapshots[widget.cacheKey];
  }

  @override
  void didUpdateWidget(covariant RoutePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cacheKey != widget.cacheKey) {
      _image = _snapshots[widget.cacheKey];
    }
  }

  LatLngBounds _bounds() {
    double minLat = widget.points.first.latitude, maxLat = minLat;
    double minLng = widget.points.first.longitude, maxLng = minLng;
    for (final p in widget.points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    try {
      await controller.moveCamera(CameraUpdate.newLatLngBounds(_bounds(), 28));
      // Give the tiles a moment to draw before taking the still image.
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      final bytes = await controller.takeSnapshot();
      if (bytes != null && mounted) {
        _snapshots[widget.cacheKey] = bytes;
        setState(() => _image = bytes);
      }
    } catch (_) {
      // Keep showing the live map if the snapshot fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.googleMapsEnabled || widget.points.length < 2) {
      return _placeholder(widget.points.length < 2 ? 'No route recorded' : null);
    }

    if (_image != null) {
      return SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Image.memory(_image!, fit: BoxFit.cover, gaplessPlayback: true),
      );
    }

    final bounds = _bounds();
    final center = LatLng(
      (bounds.southwest.latitude + bounds.northeast.latitude) / 2,
      (bounds.southwest.longitude + bounds.northeast.longitude) / 2,
    );

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: IgnorePointer(
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: center, zoom: 11),
          polylines: {
            Polyline(
              polylineId: const PolylineId('route'),
              points: widget.points,
              color: AppColors.primary,
              width: 4,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              jointType: JointType.round,
            ),
          },
          markers: {
            Marker(
              markerId: const MarkerId('start'),
              position: widget.points.first,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            ),
            Marker(
              markerId: const MarkerId('end'),
              position: widget.points.last,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            ),
          },
          liteModeEnabled: true, // Android: static lite map
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          rotateGesturesEnabled: false,
          scrollGesturesEnabled: false,
          tiltGesturesEnabled: false,
          zoomGesturesEnabled: false,
          onMapCreated: _onMapCreated,
        ),
      ),
    );
  }

  Widget _placeholder(String? label) {
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.10),
            AppColors.accent.withValues(alpha: 0.10),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.route, color: AppColors.textTertiary, size: 28),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}
