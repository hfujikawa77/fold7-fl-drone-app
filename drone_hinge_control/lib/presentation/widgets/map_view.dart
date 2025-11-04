import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dart_mavlink/dialects/ardupilotmega.dart' as mavlink;

/// Widget to display a map with drone and device positions
class MapView extends StatefulWidget {
  final mavlink.GlobalPositionInt? dronePosition;
  final LatLng? devicePosition;
  final List<LatLng> dronePath;
  final bool autoCenter;

  const MapView({
    super.key,
    this.dronePosition,
    this.devicePosition,
    this.dronePath = const [],
    this.autoCenter = true,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void didUpdateWidget(covariant MapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.autoCenter) {
      return;
    }
    final drone = widget.dronePosition;
    if (drone == null) {
      return;
    }
    final center = LatLng(drone.lat / 1e7, drone.lon / 1e7);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(center, _mapController.camera.zoom);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Default center - if we have drone or device position, use that
    LatLng center = const LatLng(35.6812, 139.7671); // Tokyo as default
    if (widget.dronePosition != null) {
      center = LatLng(
        widget.dronePosition!.lat /
            1e7, // MAVLink stores lat/lon as int32 (degrees * 1e7)
        widget.dronePosition!.lon / 1e7,
      );
    } else if (widget.devicePosition != null) {
      center = widget.devicePosition!;
    }

    // Build markers
    final List<Marker> markers = [];

    // Add drone marker if position is available
    if (widget.dronePosition != null) {
      markers.add(
        Marker(
          point:
              LatLng(widget.dronePosition!.lat / 1e7, widget.dronePosition!.lon / 1e7),
          width: 80,
          height: 80,
          child: const Column(
            children: [
              Icon(Icons.flight, color: Colors.red, size: 40),
              Text(
                'Drone',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  backgroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Add device marker if position is available
    if (widget.devicePosition != null) {
      markers.add(
        Marker(
          point: widget.devicePosition!,
          width: 80,
          height: 80,
          child: const Column(
            children: [
              Icon(Icons.location_pin, color: Colors.blue, size: 40),
              Text(
                'Device',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  backgroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final polylines = <Polyline>[];
    if (widget.dronePath.length >= 2) {
      polylines.add(
        Polyline(
          points: widget.dronePath,
          color: Colors.redAccent.withOpacity(0.7),
          strokeWidth: 4,
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(initialCenter: center, initialZoom: 15.0),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.drone_hinge_control',
        ),
        if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
        MarkerLayer(markers: markers),
      ],
    );
  }
}
