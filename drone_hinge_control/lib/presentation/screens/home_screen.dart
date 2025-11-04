import 'dart:async';

import 'package:dart_mavlink/dialects/ardupilotmega.dart' as mavlink;
import 'package:drone_hinge_control/data/services/hinge_angle_service.dart';
import 'package:drone_hinge_control/data/services/location_service.dart';
import 'package:drone_hinge_control/data/services/mavlink_service.dart';
import 'package:drone_hinge_control/domain/controllers/drone_controller.dart';
import 'package:drone_hinge_control/presentation/widgets/map_view.dart';
import 'package:drone_hinge_control/presentation/widgets/telemetry_view.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:latlong2/latlong.dart' as latlng2 show Distance;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HingeAngleService _hingeAngleService = HingeAngleService();
  final MavlinkService _mavlinkService = MavlinkService();
  final LocationService _locationService = LocationService();
  final latlng2.Distance _distance = latlng2.Distance();
  late final DroneController _droneController;
  final List<String> _receivedMessages = [];
  final List<LatLng> _dronePath = [];
  StreamSubscription? _mavlinkSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _attitudeSubscription;
  StreamSubscription? _locationSubscription;
  bool _isMonitoring = false;
  bool _autoCenter = true;

  // Telemetry data
  mavlink.GlobalPositionInt? _dronePosition;
  mavlink.Attitude? _droneAttitude;
  LatLng? _devicePosition;

  @override
  void initState() {
    super.initState();
    _droneController = DroneController(
      hingeAngleService: _hingeAngleService,
      mavlinkService: _mavlinkService,
    );

    // Listen to all MAVLink messages for debug
    _mavlinkSubscription = _mavlinkService.inputStream.listen((frame) {
      setState(() {
        _receivedMessages.add('Received: ${frame.message.runtimeType}');
        if (_receivedMessages.length > 10) {
          _receivedMessages.removeAt(0);
        }
      });
    });

    // Listen to drone position updates
    _positionSubscription = _mavlinkService.positionStream.listen((position) {
      setState(() {
        _dronePosition = position;
        final newPoint = LatLng(position.lat / 1e7, position.lon / 1e7);
        if (_dronePath.isEmpty) {
          _dronePath.add(newPoint);
        } else {
          final last = _dronePath.last;
          if (_distance(last, newPoint) > 1) {
            // Add point when moved more than 1 meter to keep path manageable
            _dronePath.add(newPoint);
          }
        }
      });
    });

    // Listen to drone attitude updates
    _attitudeSubscription = _mavlinkService.attitudeStream.listen((attitude) {
      setState(() {
        _droneAttitude = attitude;
      });
    });

    // Start device location tracking
    _startLocationTracking();
  }

  Future<void> _startLocationTracking() async {
    try {
      await _locationService.startLocationUpdates();
      _locationSubscription = _locationService.locationStream.listen((
        location,
      ) {
        setState(() {
          _devicePosition = location;
        });
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Location error: $e')));
      }
    }
  }

  @override
  void dispose() {
    _droneController.dispose();
    _mavlinkSubscription?.cancel();
    _positionSubscription?.cancel();
    _attitudeSubscription?.cancel();
    _locationSubscription?.cancel();
    _mavlinkService.dispose();
    _locationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Drone Hinge Control')),
      body: Column(
        children: [
          // Map View - takes 60% of the screen
          Expanded(
            flex: 3,
            child: MapView(
              dronePosition: _dronePosition,
              dronePath: _dronePath,
              devicePosition: _devicePosition,
              autoCenter: _autoCenter,
            ),
          ),

          // Telemetry and Controls - scrollable bottom section (40%)
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Telemetry View
                  TelemetryView(
                    attitude: _droneAttitude,
                    position: _dronePosition,
                  ),

                  // Control Panel
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildConnectionSection(),
                        const SizedBox(height: 16.0),
                        _buildMapControls(),
                        const SizedBox(height: 16.0),
                        _buildMonitoringSection(),
                        const SizedBox(height: 16.0),
                        _buildHingeAngleDisplay(),
                        const SizedBox(height: 16.0),
                        _buildManualControls(),
                        const SizedBox(height: 16.0),
                        _buildReceivedMessages(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Connection',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8.0),
        Row(
          children: [
            ElevatedButton(
              onPressed: () async {
                // await _mavlinkService.connect('127.0.0.1', 14550);
                await _mavlinkService.connect('192.168.3.38', 14550);
                setState(() {});
              },
              child: const Text('Connect MAVLink'),
            ),
            const SizedBox(width: 8.0),
            ElevatedButton(
              onPressed: () {
                _mavlinkService.disconnect();
                setState(() {});
              },
              child: const Text('Disconnect'),
            ),
            const SizedBox(width: 8.0),
            Text(
              _mavlinkService.isConnected ? 'Connected' : 'Disconnected',
              style: TextStyle(
                color: _mavlinkService.isConnected ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonitoringSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hinge Angle Monitoring',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8.0),
        Row(
          children: [
            ElevatedButton(
              onPressed: () {
                if (_isMonitoring) {
                  _droneController.stopMonitoring();
                } else {
                  _droneController.startMonitoring();
                }
                setState(() {
                  _isMonitoring = !_isMonitoring;
                });
              },
              child: Text(
                _isMonitoring ? 'Stop Monitoring' : 'Start Monitoring',
              ),
            ),
            const SizedBox(width: 8.0),
            Text(
              _isMonitoring ? 'Monitoring Active' : 'Monitoring Inactive',
              style: TextStyle(
                color: _isMonitoring ? Colors.green : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHingeAngleDisplay() {
    return StreamBuilder<double>(
      stream: _hingeAngleService.hingeAngleStream,
      builder: (context, snapshot) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            if (snapshot.hasData) ...[
              Text(
                'Hinge Angle: ${snapshot.data!.toStringAsFixed(2)}°',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                'Drone State: ${_droneController.currentState.name}',
                style: const TextStyle(fontSize: 16),
              ),
            ] else if (snapshot.hasError) ...[
              Text('Error: ${snapshot.error}'),
            ] else ...[
              const Text('Waiting for hinge angle data...'),
            ],
          ],
        );
      },
    );
  }

  Widget _buildManualControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Manual Controls',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8.0),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            ElevatedButton(
              onPressed: () {
                _droneController.takeoff();
              },
              child: const Text('Takeoff'),
            ),
            ElevatedButton(
              onPressed: () {
                _droneController.land();
              },
              child: const Text('Land'),
            ),
            ElevatedButton(
              onPressed: () {
                _droneController.setMode('GUIDED');
              },
              child: const Text('GUIDED Mode'),
            ),
            ElevatedButton(
              onPressed: () {
                _droneController.setMode('STABILIZE');
              },
              child: const Text('STABILIZE Mode'),
            ),
            ElevatedButton(
              onPressed: () {
                _droneController.setMode('AUTO');
              },
              child: const Text('AUTO Mode'),
            ),
            ElevatedButton(
              onPressed: () {
                _droneController.setMode('RTL');
              },
              child: const Text('RTL Mode'),
            ),
            ElevatedButton(
              onPressed: () {
                _mavlinkService.sendHeartbeat();
              },
              child: const Text('Send Heartbeat'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReceivedMessages() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Received MAVLink Messages',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8.0),
        Container(
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: _receivedMessages.isEmpty
              ? const Center(child: Text('No messages received'))
              : ListView.builder(
                  itemCount: _receivedMessages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: Text(
                        _receivedMessages[index],
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMapControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Checkbox(
          value: _autoCenter,
          onChanged: (value) {
            setState(() {
              _autoCenter = value ?? true;
            });
          },
        ),
        const SizedBox(width: 4),
        const Text(
          'Auto-pan to drone',
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}
