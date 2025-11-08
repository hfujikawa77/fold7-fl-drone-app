import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

class DeviceOrientationReading {
  final double rollDegrees;
  final double pitchDegrees;

  const DeviceOrientationReading({
    required this.rollDegrees,
    required this.pitchDegrees,
  });
}

class DeviceOrientationService {
  final StreamController<DeviceOrientationReading> _controller =
      StreamController.broadcast();
  Stream<DeviceOrientationReading> get orientationStream => _controller.stream;

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  bool get isRunning => _accelerometerSubscription != null;

  Future<void> start() async {
    if (_accelerometerSubscription != null) {
      return;
    }
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      final roll = math.atan2(event.y, event.z);
      final pitch = math.atan2(
        -event.x,
        math.sqrt(event.y * event.y + event.z * event.z),
      );
      _controller.add(
        DeviceOrientationReading(
          rollDegrees: roll * 180 / math.pi,
          pitchDegrees: pitch * 180 / math.pi,
        ),
      );
    });
  }

  Future<void> stop() async {
    await _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}

