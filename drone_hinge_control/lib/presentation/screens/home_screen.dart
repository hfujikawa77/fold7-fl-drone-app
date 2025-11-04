import 'dart:async';

import 'package:drone_hinge_control/data/services/hinge_angle_service.dart';
import 'package:drone_hinge_control/data/services/mavlink_service.dart';
import 'package:drone_hinge_control/domain/controllers/drone_controller.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HingeAngleService _hingeAngleService = HingeAngleService();
  final MavlinkService _mavlinkService = MavlinkService();
  late final DroneController _droneController;
  final List<String> _receivedMessages = [];
  StreamSubscription? _mavlinkSubscription;
  bool _isMonitoring = false;

  @override
  void initState() {
    super.initState();
    _droneController = DroneController(
      hingeAngleService: _hingeAngleService,
      mavlinkService: _mavlinkService,
    );
    _mavlinkSubscription = _mavlinkService.inputStream.listen((frame) {
      setState(() {
        _receivedMessages.add('Received: ${frame.message.runtimeType}');
        if (_receivedMessages.length > 10) {
          _receivedMessages.removeAt(0);
        }
      });
    });
  }

  @override
  void dispose() {
    _droneController.dispose();
    _mavlinkSubscription?.cancel();
    _mavlinkService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Drone Hinge Control')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // MAVLink Connection
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await _mavlinkService.connect('127.0.0.1', 14550);
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
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              // Hinge Angle Monitoring
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
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              // Hinge Angle and Drone State Display
              StreamBuilder<double>(
                stream: _hingeAngleService.hingeAngleStream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hinge Angle: ${snapshot.data!.toStringAsFixed(2)}°',
                        ),
                        Text(
                          'Drone State: ${_droneController.currentState.name}',
                        ),
                      ],
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    return const Text('Waiting for hinge angle data...');
                  }
                },
              ),
              const SizedBox(height: 16.0),

              // Manual Control Buttons
              const Text(
                'Manual Controls:',
                style: TextStyle(fontWeight: FontWeight.bold),
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
              const SizedBox(height: 16.0),

              // Received Messages
              const Text(
                'Received MAVLink Messages:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: _receivedMessages.length,
                  itemBuilder: (context, index) {
                    return Text(_receivedMessages[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
