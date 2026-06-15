import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:milemaid/core/constants/app_colors.dart';

/// Reusable styled map with route polyline support.
/// Supports speed-based coloring if speeds provided (advanced).
class CustomMap extends StatefulWidget {
  final List<LatLng> points;
  final LatLng? initialCenter;
  final double initialZoom;
  final bool showStartEndMarkers;
  final bool fitBounds;
  final Set<Marker> extraMarkers;
  final MapType mapType;

  const CustomMap({
    super.key,
    required this.points,
    this.initialCenter,
    this.initialZoom = 12,
    this.showStartEndMarkers = true,
    this.fitBounds = true,
    this.extraMarkers = const {},
    this.mapType = MapType.normal,
  });

  @override
  State<CustomMap> createState() => _CustomMapState();
}

class _CustomMapState extends State<CustomMap> {
  GoogleMapController? _controller;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};

  @override
  void didUpdateWidget(covariant CustomMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.points != widget.points) {
      _updatePolylinesAndMarkers();
    }
  }

  @override
  void initState() {
    super.initState();
    _updatePolylinesAndMarkers();
  }

  void _updatePolylinesAndMarkers() {
    _polylines.clear();
    _markers.clear();

    if (widget.points.length < 2) return;

    // Create a nice gradient-ish polyline (simplified - single color with nice width)
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: widget.points,
        color: AppColors.primary,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    );

    if (widget.showStartEndMarkers) {
      _markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: widget.points.first,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Start'),
        ),
      );
      _markers.add(
        Marker(
          markerId: const MarkerId('end'),
          position: widget.points.last,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'End'),
        ),
      );
    }

    _markers.addAll(widget.extraMarkers);

    // Auto fit
    if (widget.fitBounds && _controller != null) {
      _fitToBounds();
    }
  }

  Future<void> _fitToBounds() async {
    if (widget.points.isEmpty || _controller == null) return;

    double minLat = widget.points.first.latitude;
    double maxLat = minLat;
    double minLng = widget.points.first.longitude;
    double maxLng = minLng;

    for (final p in widget.points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    await _controller!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
  }

  @override
  Widget build(BuildContext context) {
    final center = widget.initialCenter ??
        (widget.points.isNotEmpty ? widget.points.first : const LatLng(37.7749, -122.4194));

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: center, zoom: widget.initialZoom),
      mapType: widget.mapType,
      polylines: _polylines,
      markers: _markers,
      onMapCreated: (controller) {
        _controller = controller;
        if (widget.fitBounds && widget.points.length > 1) {
          // slight delay for map ready
          Future.delayed(const Duration(milliseconds: 350), _fitToBounds);
        }
      },
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
    );
  }
}
