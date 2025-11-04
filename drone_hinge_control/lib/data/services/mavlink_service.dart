import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_mavlink/mavlink.dart';
import 'package:dart_mavlink/dialects/ardupilotmega.dart' as mavlink_ardupilotmega;
import 'package:drone_hinge_control/data/services/raw_datagram_socket_service.dart';

class MavlinkService {
  RawDatagramSocketService? _socketService;
  StreamController<MavlinkFrame> _inputStreamController = StreamController.broadcast();
  Stream<MavlinkFrame> get inputStream => _inputStreamController.stream;

  final MavlinkParser _parser = MavlinkParser(mavlink_ardupilotmega.MavlinkDialectArdupilotmega());

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  final RawDatagramSocketService Function()? _socketServiceFactory;

  MavlinkService({RawDatagramSocketService Function()? socketServiceFactory})
      : _socketServiceFactory = socketServiceFactory;

  Future<void> connect(String address, int port) async {
    if (_isConnected) {
      disconnect();
    }
    try {
      _socketService = await (_socketServiceFactory ?? () => RawDatagramSocketService())().bind(InternetAddress.anyIPv4, 0);
      _socketService!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          Datagram? datagram = _socketService!.receive();
          if (datagram != null) {
            _parser.parse(Uint8List.view(datagram.data.buffer));
          }
        }
      });
      _parser.stream.listen((MavlinkFrame frame) {
        _inputStreamController.add(frame);
      });
      _isConnected = true;
      print('Connected to MAVLink simulator at $address:$port');
    } catch (e) {
      print('Error connecting to MAVLink simulator: $e');
      _isConnected = false;
    }
  }

  void disconnect() {
    _socketService?.close();
    _isConnected = false;
    print('Disconnected from MAVLink simulator');
  }

  void sendMessage(MavlinkFrame frame) {
    if (_isConnected) {
      final bytes = frame.serialize();
      _socketService?.send(bytes, InternetAddress.loopbackIPv4, 14550); // Assuming simulator listens on 14550
    }
  }

  void sendHeartbeat() {
    final heartbeat = mavlink_ardupilotmega.Heartbeat(
      type: 2, // MAV_TYPE_QUADROTOR
      autopilot: 4, // MAV_AUTOPILOT_ARDUPILOTMEGA
      baseMode: 16, // MAV_MODE_FLAG_STABILIZE_ENABLED
      customMode: 0,
      systemStatus: 4, // MAV_STATE_ACTIVE
      mavlinkVersion: 3,
    );
    final frame = MavlinkFrame.v2(0, 255, 1, heartbeat);
    sendMessage(frame);
  }
}