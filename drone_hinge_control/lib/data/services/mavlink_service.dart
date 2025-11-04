import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_mavlink/mavlink.dart';
import 'package:dart_mavlink/dialects/ardupilotmega.dart'
    as mavlink_ardupilotmega;
import 'package:drone_hinge_control/data/services/raw_datagram_socket_service.dart';

class MavlinkService {
  static const int _localPort = 14551;
  static const int _globalPositionMessageId = 33; // GLOBAL_POSITION_INT
  static const int _attitudeMessageId = 30; // ATTITUDE
  static const int _streamExtra1 = 1; // RAW_SENSORS
  static const int _streamExtra3 = 3; // POSITION

  RawDatagramSocketService? _socketService;
  final StreamController<MavlinkFrame> _inputStreamController =
      StreamController.broadcast();
  Stream<MavlinkFrame> get inputStream => _inputStreamController.stream;

  InternetAddress? _remoteAddress;
  int? _remotePort;
  Timer? _heartbeatTimer;
  int _sequence = 0;
  final int _systemId;
  final int _componentId;

  final StreamController<mavlink_ardupilotmega.GlobalPositionInt>
  _positionStreamController = StreamController.broadcast();
  Stream<mavlink_ardupilotmega.GlobalPositionInt> get positionStream =>
      _positionStreamController.stream;

  final StreamController<mavlink_ardupilotmega.Attitude>
  _attitudeStreamController = StreamController.broadcast();
  Stream<mavlink_ardupilotmega.Attitude> get attitudeStream =>
      _attitudeStreamController.stream;

  final MavlinkParser _parser = MavlinkParser(
    mavlink_ardupilotmega.MavlinkDialectArdupilotmega(),
  );

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  final RawDatagramSocketService Function()? _socketServiceFactory;

  MavlinkService({
    RawDatagramSocketService Function()? socketServiceFactory,
    int systemId = 201,
    int componentId = 191,
  })  : _socketServiceFactory = socketServiceFactory,
        _systemId = systemId,
        _componentId = componentId;

  Future<void> connect(String address, int port) async {
    if (_isConnected) {
      disconnect();
    }
    try {
      _socketService =
          await (_socketServiceFactory ?? () => RawDatagramSocketService())()
              .bind(InternetAddress.anyIPv4, _localPort);
      final remoteAddress = InternetAddress.tryParse(address) ??
          (await InternetAddress.lookup(address)).first;
      _remoteAddress = remoteAddress;
      _remotePort = port;
      _sequence = 0;
      print(
        'MAVLink GCS identity: systemId=$_systemId componentId=$_componentId',
      );
      final localPort = _socketService?.port;
      if (localPort != null) {
        print('Listening for MAVLink on 0.0.0.0:$localPort');
      }
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

        // Parse specific message types
        if (frame.message is mavlink_ardupilotmega.GlobalPositionInt) {
          _positionStreamController.add(
            frame.message as mavlink_ardupilotmega.GlobalPositionInt,
          );
        } else if (frame.message is mavlink_ardupilotmega.Attitude) {
          _attitudeStreamController.add(
            frame.message as mavlink_ardupilotmega.Attitude,
          );
        }
      });
      _isConnected = true;
      print('Connected to MAVLink simulator at $address:$port');
      // Proactively announce ourselves so the simulator learns our UDP port.
      sendHeartbeat();
      _startHeartbeatTimer();
      _requestTelemetryStreams();
    } catch (e) {
      print('Error connecting to MAVLink simulator: $e');
      _isConnected = false;
      _remoteAddress = null;
      _remotePort = null;
      _heartbeatTimer?.cancel();
      _heartbeatTimer = null;
    }
  }

  void disconnect() {
    _socketService?.close();
    _isConnected = false;
    _remoteAddress = null;
    _remotePort = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _sequence = 0;
    print('Disconnected from MAVLink simulator');
  }

  void dispose() {
    disconnect();
    _inputStreamController.close();
    _positionStreamController.close();
    _attitudeStreamController.close();
  }

  void sendMessage(MavlinkFrame frame) {
    if (_isConnected && _remoteAddress != null && _remotePort != null) {
      final bytes = frame.serialize();
      final sent = _socketService?.send(
        bytes,
        _remoteAddress!,
        _remotePort!,
      );
      if (sent != null && sent > 0) {
        print(
          'Sent ${frame.message.runtimeType} (${bytes.length} bytes) to '
          '${_remoteAddress!.address}:$_remotePort',
        );
      }
    }
  }

  void sendCommand(dynamic message) {
    sendMessage(_buildFrame(message));
  }

  static const int _heartbeatType = 6; // MAV_TYPE_GCS
  static const int _heartbeatAutopilot = 8; // MAV_AUTOPILOT_INVALID
  static const int _heartbeatSystemStatus = 4; // MAV_STATE_ACTIVE

  void sendHeartbeat() {
    final heartbeat = mavlink_ardupilotmega.Heartbeat(
      type: _heartbeatType,
      autopilot: _heartbeatAutopilot,
      baseMode: 0,
      customMode: 0,
      systemStatus: _heartbeatSystemStatus,
      mavlinkVersion: 3,
    );
    sendMessage(_buildFrame(heartbeat));
  }

  void _startHeartbeatTimer() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => sendHeartbeat(),
    );
  }

  void _requestTelemetryStreams() {
    if (!_isConnected) {
      return;
    }

    // Request GLOBAL_POSITION_INT at 5 Hz
    _setMessageInterval(_globalPositionMessageId, frequencyHz: 5);
    // Request ATTITUDE at 10 Hz
    _setMessageInterval(_attitudeMessageId, frequencyHz: 10);
    // Legacy stream requests for ArduPilot/Mission Planner compatibility
    _requestLegacyDataStream(_streamExtra1, rateHz: 10);
    _requestLegacyDataStream(_streamExtra3, rateHz: 5);
  }

  void _setMessageInterval(int messageId, {required int frequencyHz}) {
    if (frequencyHz <= 0) {
      return;
    }
    final intervalUs = (1000000 / frequencyHz).round();
    final request = mavlink_ardupilotmega.CommandLong(
      targetSystem: 1,
      targetComponent: 1,
      command: 511, // MAV_CMD_SET_MESSAGE_INTERVAL
      confirmation: 0,
      param1: messageId.toDouble(),
      param2: intervalUs.toDouble(),
      param3: 0,
      param4: 0,
      param5: 0,
      param6: 0,
      param7: 0,
    );
    sendMessage(_buildFrame(request));
  }

  void _requestLegacyDataStream(int streamId, {required int rateHz}) {
    if (rateHz <= 0) {
      return;
    }
    final request = mavlink_ardupilotmega.RequestDataStream(
      targetSystem: 1,
      targetComponent: 1,
      reqStreamId: streamId,
      reqMessageRate: rateHz,
      startStop: 1,
    );
    sendMessage(_buildFrame(request));
  }

  MavlinkFrame _buildFrame(dynamic message) {
    return MavlinkFrame.v2(
      _systemId,
      _componentId,
      _nextSequence(),
      message,
    );
  }

  int _nextSequence() {
    final current = _sequence;
    _sequence = (_sequence + 1) & 0xFF;
    return current;
  }
}
