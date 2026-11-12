import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:milemaid/core/config/app_config.dart';
import 'package:milemaid/core/constants/app_colors.dart';
import 'package:milemaid/core/constants/design_tokens.dart';

/// Small, non-interactive route map shown at the top of a drive card.
///
/// The live map renders once behind a placeholder, then is replaced by a
/// still snapshot so swiping stays smooth. Snapshots are cached per drive.
class RoutePreview extends StatefulWidget {
  const RoutePreview({
    super.key,
    required this.cacheKey,
    required this.points,
    this.height = 130,
  });

  /// Unique per drive (and per route), e.g. `<tripId>:<pointCount>`.
  final String cacheKey;
  final List<LatLng> points;
  final double height;

  @override
  State<RoutePreview> createState() => _RoutePreviewState();
}

class _RoutePreviewState extends State<RoutePreview> {
  static final Map<String, Uint8List> _snapshots = {};
  static BitmapDescriptor? _startDot;
  static BitmapDescriptor? _endDot;

  /// Desaturated so the indigo route reads as the subject.
  static const _mutedStyle = '''
[
  {"featureType": "all", "stylers": [{"saturation": -80}, {"lightness": 8}]},
  {"featureType": "poi", "stylers": [{"visibility": "off"}]},
  {"featureType": "transit", "stylers": [{"visibility": "off"}]},
  {"featureType": "road", "elementType": "labels.icon", "stylers": [{"visibility": "off"}]}
]
''';

  Uint8List? _image;

  @override
  void initState() {
    super.initState();
    _image = _snapshots[widget.cacheKey];
    _ensureDots();
  }

  @override
  void didUpdateWidget(covariant RoutePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cacheKey != widget.cacheKey) {
      _image = _snapshots[widget.cacheKey];
    }
  }

  Future<void> _ensureDots() async {
    if (_startDot != null && _endDot != null) return;
    _startDot = await _dot(const Color(0xFF1FA85A));
    _endDot = await _dot(AppColors.primary);
    if (mounted) setState(() {});
  }

  Future<BitmapDescriptor> _dot(Color color) async {
    const size = 48.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      12,
      Paint()..color = color,
    );
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      12,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(data!.buffer.asUint8List(), width: 16, height: 16);
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
    // A single point (or a route with no span) can't form a bounds.
    if (maxLat - minLat < 0.0008) {
      minLat -= 0.002;
      maxLat += 0.002;
    }
    if (maxLng - minLng < 0.0008) {
      minLng -= 0.002;
      maxLng += 0.002;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  double _zoomFor(LatLngBounds bounds) {
    final span = [
      (bounds.northeast.latitude - bounds.southwest.latitude).abs(),
      (bounds.northeast.longitude - bounds.southwest.longitude).abs(),
    ].reduce((a, b) => a > b ? a : b);
    if (span < 0.01) return 15;
    if (span < 0.05) return 13;
    if (span < 0.2) return 11;
    if (span < 0.8) return 9;
    return 7;
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    try {
      await controller.moveCamera(CameraUpdate.newLatLngBounds(_bounds(), 44));
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      final bytes = await controller.takeSnapshot();
      if (bytes != null && mounted) {
        _snapshots[widget.cacheKey] = bytes;
        setState(() => _image = bytes);
      }
    } catch (_) {
      // Keep the covered live map if the snapshot fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.googleMapsEnabled || widget.points.length < 2) {
      return _placeholder(widget.points.length < 2 ? 'No route recorded' : null);
    }

    if (_image != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.l)),
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: Image.memory(_image!, fit: BoxFit.cover, gaplessPlayback: true),
        ),
      );
    }

    final bounds = _bounds();
    final center = LatLng(
      (bounds.southwest.latitude + bounds.northeast.latitude) / 2,
      (bounds.southwest.longitude + bounds.northeast.longitude) / 2,
    );
    final dotsReady = _startDot != null && _endDot != null;

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: center, zoom: _zoomFor(bounds)),
              style: _mutedStyle,
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
              markers: dotsReady
                  ? {
                      Marker(
                        markerId: const MarkerId('start'),
                        position: widget.points.first,
                        icon: _startDot!,
                        anchor: const Offset(0.5, 0.5),
                      ),
                      Marker(
                        markerId: const MarkerId('end'),
                        position: widget.points.last,
                        icon: _endDot!,
                        anchor: const Offset(0.5, 0.5),
                      ),
                    }
                  : const {},
              liteModeEnabled: true,
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
          _placeholder(null),
        ],
      ),
    );
  }

  Widget _placeholder(String? label) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.route, color: muted, size: 28),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: muted, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}
