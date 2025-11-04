import 'dart:async';

import 'package:drone_hinge_control/data/services/hinge_angle_service.dart';
import 'package:drone_hinge_control/data/services/mavlink_service.dart';
import 'package:flutter/material.dart';
import 'package:dart_mavlink/mavlink.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HingeAngleService _hingeAngleService = HingeAngleService();
  final MavlinkService _mavlinkService = MavlinkService();
  final List<String> _receivedMessages = [];
  StreamSubscription? _mavlinkSubscription;

  @override
  void initState() {
    super.initState();
    _mavlinkSubscription = _mavlinkService.inputStream.listen((frame) {
      setState(() {
        _receivedMessages.add('Received: ${frame.message.name}');
        if (_receivedMessages.length > 10) {
          _receivedMessages.removeAt(0);
        }
      });
    });
  }

  @override
  void dispose() {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await _mavlinkService.connect('127.0.0.1', 14550);
                    setState(() {});
                  },
                  child: const Text('Connect MAVLink'),
                ),
                const SizedBox(width: 16.0),
                ElevatedButton(
                  onPressed: () {
                    _mavlinkService.disconnect();
                    setState(() {});
                  },
                  child: const Text('Disconnect MAVLink'),
                ),
                const SizedBox(width: 16.0),
                Text(
                  _mavlinkService.isConnected
                      ? 'MAVLink Connected'
                      : 'MAVLink Disconnected',
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                _mavlinkService.sendHeartbeat();
              },
              child: const Text('Send Heartbeat'),
            ),
            const SizedBox(height: 16.0),
            StreamBuilder<double>(
              stream: _hingeAngleService.hingeAngleStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(
                      'Hinge Angle: ${snapshot.data!.toStringAsFixed(2)}');
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return const Text('Waiting for hinge angle data...');
                }
              },
            ),
            const SizedBox(height: 16.0),
            const Text('Received MAVLink Messages:'),
            Expanded(
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
    );
  }
}