import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dart_mavlink/dialects/ardupilotmega.dart' as mavlink;

/// Widget to display a map with drone and device positions
class MapView extends StatelessWidget {
  final mavlink.GlobalPositionInt? dronePosition;
  final LatLng? devicePosition;

  const MapView({super.key, this.dronePosition, this.devicePosition});

  @override
  Widget build(BuildContext context) {
    // Default center - if we have drone or device position, use that
    LatLng center = const LatLng(35.6812, 139.7671); // Tokyo as default
    if (dronePosition != null) {
      center = LatLng(
        dronePosition!.lat /
            1e7, // MAVLink stores lat/lon as int32 (degrees * 1e7)
        dronePosition!.lon / 1e7,
      );
    } else if (devicePosition != null) {
      center = devicePosition!;
    }

    // Build markers
    final List<Marker> markers = [];

    // Add drone marker if position is available
    if (dronePosition != null) {
      markers.add(
        Marker(
          point: LatLng(dronePosition!.lat / 1e7, dronePosition!.lon / 1e7),
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
    if (devicePosition != null) {
      markers.add(
        Marker(
          point: devicePosition!,
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

    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: 15.0),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.drone_hinge_control',
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }
}
