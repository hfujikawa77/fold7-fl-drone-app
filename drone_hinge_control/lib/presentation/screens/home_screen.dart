import 'dart:async';

import 'package:dart_mavlink/dialects/ardupilotmega.dart' as mavlink;
import 'package:drone_hinge_control/data/services/device_orientation_service.dart';
import 'package:drone_hinge_control/data/services/hinge_angle_service.dart';
import 'package:drone_hinge_control/data/services/location_service.dart';
import 'package:drone_hinge_control/data/services/mavlink_service.dart';
import 'package:drone_hinge_control/domain/controllers/drone_controller.dart';
import 'package:drone_hinge_control/presentation/widgets/attitude_hud.dart';
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
  static const Map<int, String> _flightModeById = {
    0: 'STABILIZE',
    1: 'ACRO',
    2: 'ALT HOLD',
    3: 'AUTO',
    4: 'GUIDED',
    5: 'LOITER',
    6: 'RTL',
    7: 'CIRCLE',
    9: 'LAND',
    11: 'DRIFT',
    13: 'SPORT',
    14: 'FLIP',
    15: 'AUTOTUNE',
    16: 'POSHOLD',
    17: 'BRAKE',
    18: 'THROW',
    19: 'AVOID_ADSB',
    20: 'GUIDED_NOGPS',
    21: 'SMART_RTL',
    22: 'FLOWHOLD',
    23: 'FOLLOW',
    24: 'ZIGZAG',
    25: 'SYSTEMID',
    26: 'AUTOROTATE',
  };
  static const int _mavModeFlagSafetyArmed = 1 << 7;

  final HingeAngleService _hingeAngleService = HingeAngleService();
  final DeviceOrientationService _orientationService =
      DeviceOrientationService();
  final MavlinkService _mavlinkService = MavlinkService();
  final LocationService _locationService = LocationService();
  final latlng2.Distance _distance = latlng2.Distance();
  final TextEditingController _ipController = TextEditingController(
    text: '192.168.4.1',
  );
  final TextEditingController _portController = TextEditingController(
    text: '14555',
  );
  final TextEditingController _localPortController = TextEditingController(
    text: '14550',
  );
  final TextEditingController _systemIdController = TextEditingController(
    text: '201',
  );
  final TextEditingController _componentIdController = TextEditingController(
    text: '191',
  );
  late final DroneController _droneController;
  final List<String> _receivedMessages = [];
  final List<LatLng> _dronePath = [];
  StreamSubscription? _mavlinkSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _attitudeSubscription;
  StreamSubscription? _locationSubscription;
  StreamSubscription? _heartbeatSubscription;
  StreamSubscription? _batterySubscription;
  StreamSubscription? _commandAckSubscription;
  StreamSubscription<DeviceOrientationReading>? _tiltSubscription;
  bool _isMonitoring = false;
  bool _autoCenter = true;
  bool _tiltControlEnabled = false;
  bool _armCommandPending = false;
  bool? _pendingArmState;

  // Telemetry data
  mavlink.GlobalPositionInt? _dronePosition;
  mavlink.Attitude? _droneAttitude;
  LatLng? _devicePosition;
  mavlink.Heartbeat? _heartbeat;
  mavlink.BatteryStatus? _batteryStatus;
  bool _isArmed = false;
  String _flightModeLabel = 'UNKNOWN';
  DateTime? _lastTiltCommandSent;

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

    _heartbeatSubscription = _mavlinkService.heartbeatStream.listen((hb) {
      setState(() {
        _heartbeat = hb;
        _isArmed = (hb.baseMode & _mavModeFlagSafetyArmed) != 0;
        _flightModeLabel = _flightModeById[hb.customMode] ??
            'MODE ${hb.customMode}';
      });
    });

    _batterySubscription = _mavlinkService.batteryStream.listen((battery) {
      setState(() {
        _batteryStatus = battery;
      });
    });
    _commandAckSubscription =
        _mavlinkService.commandAckStream.listen(_handleCommandAck);

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
    _heartbeatSubscription?.cancel();
    _batterySubscription?.cancel();
    _commandAckSubscription?.cancel();
    _tiltSubscription?.cancel();
    _mavlinkService.dispose();
    _locationService.dispose();
    _orientationService.dispose();
    _ipController.dispose();
    _portController.dispose();
    _localPortController.dispose();
    _systemIdController.dispose();
    _componentIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Drone Hinge Control')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _buildStatusHeader(),
          ),
          // Map View - takes 60% of the screen
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Positioned.fill(
                  child: MapView(
                    dronePosition: _dronePosition,
                    dronePath: _dronePath,
                    devicePosition: _devicePosition,
                    autoCenter: _autoCenter,
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: AttitudeHud(attitude: _droneAttitude),
                ),
              ],
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
                        _buildTiltControlSection(),
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
            Expanded(
              child: TextField(
                controller: _ipController,
                decoration: const InputDecoration(
                  labelText: 'MAVLink IP address',
                  hintText: 'e.g. 192.168.3.38',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            SizedBox(
              width: 110,
              child: TextField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: 'Remote port',
                  hintText: '14555',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 110,
            child: TextField(
              controller: _localPortController,
              decoration: const InputDecoration(
                labelText: 'Local port',
                hintText: '14550',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
        ),
        const SizedBox(height: 8.0),
        Row(
          children: [
            SizedBox(
              width: 110,
              child: TextField(
                controller: _systemIdController,
                decoration: const InputDecoration(
                  labelText: 'System ID',
                  hintText: '255',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8.0),
            SizedBox(
              width: 140,
              child: TextField(
                controller: _componentIdController,
                decoration: const InputDecoration(
                  labelText: 'Component ID',
                  hintText: '190',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        Row(
          children: [
            ElevatedButton(
              onPressed: () async {
                final ip = _ipController.text.trim();
                final portText = _portController.text.trim();
                final localPortText = _localPortController.text.trim();
                final systemIdText = _systemIdController.text.trim();
                final componentIdText = _componentIdController.text.trim();
                if (ip.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter an IP address before connecting.',
                      ),
                    ),
                  );
                  return;
                }
                final port = int.tryParse(portText);
                if (port == null || port <= 0 || port > 65535) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter a valid port number (1-65535).',
                      ),
                    ),
                  );
                  return;
                }
                final localPort = int.tryParse(localPortText);
                if (localPort == null || localPort <= 0 || localPort > 65535) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter a valid local port number (1-65535).',
                      ),
                    ),
                  );
                  return;
                }
                final systemId = int.tryParse(systemIdText);
                if (systemId == null || systemId < 1 || systemId > 255) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter a valid system ID (1-255).',
                      ),
                    ),
                  );
                  return;
                }
                final componentId = int.tryParse(componentIdText);
                if (componentId == null || componentId < 1 || componentId > 255) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter a valid component ID (1-255).',
                      ),
                    ),
                  );
                  return;
                }
                _mavlinkService.updateIdentity(
                  systemId: systemId,
                  componentId: componentId,
                );
                await _mavlinkService.connect(
                  ip,
                  remotePort: port,
                  localPort: localPort,
                );
                if (!mounted) {
                  return;
                }
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
            ElevatedButton.icon(
              onPressed: _armCommandPending ? null : _handleArmToggle,
              icon: Icon(_isArmed ? Icons.lock_open : Icons.lock),
              label: Text(
                _armCommandPending
                    ? 'Waiting for ACK...'
                    : _isArmed
                        ? 'Disarm Drone'
                        : 'Arm Drone',
              ),
            ),
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

  void _handleArmToggle() {
    if (!_mavlinkService.isConnected) {
      _showSnack('Connect to MAVLink before sending arm/disarm commands.');
      return;
    }
    if (_armCommandPending) {
      _showSnack('Arm/disarm command already pending acknowledgement.');
      return;
    }
    final targetState = !_isArmed;
    setState(() {
      _armCommandPending = true;
      _pendingArmState = targetState;
    });
    if (targetState) {
      _droneController.arm();
      _showSnack('Arm command sent, waiting for ACK...');
    } else {
      _droneController.disarm();
      _showSnack('Disarm command sent, waiting for ACK...');
    }
  }

  void _handleCommandAck(mavlink.CommandAck ack) {
    final resultLabel = _describeCommandResult(ack.result);
    if (ack.command == mavlink.mavCmdComponentArmDisarm) {
      final accepted = ack.result == mavlink.mavResultAccepted;
      setState(() {
        if (accepted && _pendingArmState != null) {
          _isArmed = _pendingArmState!;
        }
        _armCommandPending = false;
        _pendingArmState = null;
      });
      _showSnack(
        accepted
            ? 'Arm/disarm acknowledged.'
            : 'Arm/disarm rejected: $resultLabel (code ${ack.result}).',
      );
    }
    setState(() {
      _receivedMessages.add(
        'ACK cmd=${ack.command} result=$resultLabel (${ack.result})',
      );
      if (_receivedMessages.length > 10) {
        _receivedMessages.removeAt(0);
      }
    });
  }

  String _describeCommandResult(int result) {
    switch (result) {
      case mavlink.mavResultAccepted:
        return 'ACCEPTED';
      case mavlink.mavResultTemporarilyRejected:
        return 'TEMP_REJECTED';
      case mavlink.mavResultDenied:
        return 'DENIED';
      case mavlink.mavResultUnsupported:
        return 'UNSUPPORTED';
      case mavlink.mavResultFailed:
        return 'FAILED';
      case mavlink.mavResultInProgress:
        return 'IN_PROGRESS';
      case mavlink.mavResultCancelled:
        return 'CANCELLED';
      default:
        return 'RESULT_$result';
    }
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
        const Text('Auto-pan to drone', style: TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildTiltControlSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tilt Control',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8.0),
        Row(
          children: [
            ElevatedButton(
              onPressed: () async {
                if (_tiltControlEnabled) {
                  await _stopTiltControl();
                } else {
                  await _startTiltControl();
                }
              },
              child: Text(_tiltControlEnabled ? 'Disable Tilt Control' : 'Enable Tilt Control'),
            ),
            const SizedBox(width: 12),
            Text(
              _tiltControlEnabled ? 'Active' : 'Inactive',
              style: TextStyle(
                color: _tiltControlEnabled ? Colors.green : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Device roll/pitch steer the drone (RC override).',
          style: TextStyle(color: Colors.black54),
        ),
      ],
    );
  }

  Future<void> _startTiltControl() async {
    if (!_mavlinkService.isConnected) {
      _showSnack('Connect to MAVLink before enabling tilt control.');
      return;
    }
    await _orientationService.start();
    _tiltSubscription = _orientationService.orientationStream.listen((reading) {
      final now = DateTime.now();
      if (_lastTiltCommandSent != null &&
          now.difference(_lastTiltCommandSent!).inMilliseconds < 50) {
        return;
      }
      _lastTiltCommandSent = now;
      _droneController.sendTiltControlCommand(
        rollDegrees: reading.rollDegrees,
        pitchDegrees: reading.pitchDegrees,
      );
    });
    if (!mounted) {
      return;
    }
    setState(() {
      _tiltControlEnabled = true;
    });
  }

  Future<void> _stopTiltControl() async {
    await _tiltSubscription?.cancel();
    _tiltSubscription = null;
    await _orientationService.stop();
    if (!mounted) {
      return;
    }
    setState(() {
      _tiltControlEnabled = false;
    });
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildStatusHeader() {
    final batteryPercent = _batteryStatus?.batteryRemaining ?? -1;
    final hasBattery = batteryPercent >= 0;
    final batteryColor = !hasBattery
        ? Colors.grey
        : batteryPercent > 50
            ? Colors.greenAccent
            : batteryPercent > 20
                ? Colors.orangeAccent
                : Colors.redAccent;
    final batteryLabel =
        hasBattery ? 'Battery $batteryPercent%' : 'Battery --%';

    final readinessLabel = _isArmed ? 'Armed' : 'Disarmed';
    final readinessColor = _isArmed ? Colors.greenAccent : Colors.redAccent;

    final connectionLabel =
        _mavlinkService.isConnected ? 'Connected' : 'Disconnected';
    final connectionColor =
        _mavlinkService.isConnected ? Colors.greenAccent : Colors.redAccent;
    final connectionIcon =
        _mavlinkService.isConnected ? Icons.wifi : Icons.wifi_off;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildStatusChip(
              context,
              Icons.power_settings_new,
              readinessLabel,
              readinessColor,
            ),
            _buildStatusChip(
              context,
              Icons.flight_takeoff,
              _flightModeLabel,
              Colors.blueAccent,
            ),
            _buildStatusChip(
              context,
              Icons.battery_full,
              batteryLabel,
              batteryColor,
            ),
            _buildStatusChip(
              context,
              connectionIcon,
              connectionLabel,
              connectionColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(
    BuildContext context,
    IconData icon,
    String label,
    Color accentColor,
  ) {
    final theme = Theme.of(context);
    final backgroundColor = theme.colorScheme.surfaceVariant;
    final textColor = theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: accentColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
