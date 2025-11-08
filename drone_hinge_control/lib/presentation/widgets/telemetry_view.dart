import 'package:dart_mavlink/dialects/ardupilotmega.dart' as mavlink;
import 'package:flutter/material.dart';

/// Widget to display essential telemetry data (position only).
class TelemetryView extends StatelessWidget {
  final mavlink.GlobalPositionInt? position;

  const TelemetryView({super.key, this.position});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Telemetry',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Position',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            if (position != null) ...[
              _buildDataRow(
                'Latitude',
                '${(position!.lat / 1e7).toStringAsFixed(6)}°',
                Icons.place,
              ),
              _buildDataRow(
                'Longitude',
                '${(position!.lon / 1e7).toStringAsFixed(6)}°',
                Icons.place,
              ),
              _buildDataRow(
                'Altitude (Rel)',
                '${(position!.relativeAlt / 1000.0).toStringAsFixed(2)} m',
                Icons.height,
              ),
              _buildDataRow(
                'Altitude (MSL)',
                '${(position!.alt / 1000.0).toStringAsFixed(2)} m',
                Icons.terrain,
              ),
              _buildDataRow(
                'Heading',
                '${(position!.hdg / 100.0).toStringAsFixed(1)}°',
                Icons.navigation,
              ),
            ] else ...[
              const Text(
                'No position data',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

