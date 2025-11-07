import 'dart:async';

import 'dart:math' as math;

import 'package:dart_mavlink/dialects/ardupilotmega.dart' as mavlink;
import 'package:drone_hinge_control/data/services/hinge_angle_service.dart';
import 'package:drone_hinge_control/data/services/mavlink_service.dart';

/// Controller that connects HingeAngleService and MavlinkService
/// to control the drone based on hinge angle and user commands.
class DroneController {
  final HingeAngleService _hingeAngleService;
  final MavlinkService _mavlinkService;
  StreamSubscription<double>? _hingeSubscription;

  // Hinge angle thresholds
  static const double _disarmReferenceAngle = 0.0;
  static const double _armReferenceAngle = 90.0;
  static const double _angleToleranceDegrees = 15.0;
  static const double _maxTiltDegrees = 35.0;
  static const int _rcMidPwm = 1500;
  static const int _rcDelta = 400;

  // State tracking to prevent repeated commands
  DroneState _currentState = DroneState.unknown;
  double _lastHingeAngle = 0.0;
  int get _targetSystemId => _mavlinkService.targetSystemId;
  int get _targetComponentId => _mavlinkService.targetComponentId;

  DroneController({
    required HingeAngleService hingeAngleService,
    required MavlinkService mavlinkService,
  }) : _hingeAngleService = hingeAngleService,
       _mavlinkService = mavlinkService;

  /// Start monitoring hinge angle and control drone accordingly
  void startMonitoring() {
    _hingeSubscription = _hingeAngleService.hingeAngleStream.listen((angle) {
      _lastHingeAngle = angle;
      _handleHingeAngleChange(angle);
    });
  }

  /// Stop monitoring hinge angle
  void stopMonitoring() {
    _hingeSubscription?.cancel();
    _hingeSubscription = null;
  }

  /// Handle hinge angle changes and send appropriate commands
  void _handleHingeAngleChange(double angle) {
    final newState = _determineStateFromAngle(angle);

    // Only send command if state has changed
    if (newState != _currentState) {
      _currentState = newState;

      switch (newState) {
        case DroneState.disarmed:
          _sendDisarmCommand();
          break;
        case DroneState.armed:
          _sendArmCommand();
          break;
        case DroneState.unknown:
          break;
      }
    }
  }

  /// Determine drone state based on hinge angle
  DroneState _determineStateFromAngle(double angle) {
    if (_isWithinTolerance(angle, _disarmReferenceAngle)) {
      return DroneState.disarmed;
    }
    if (_isWithinTolerance(angle, _armReferenceAngle)) {
      return DroneState.armed;
    }
    return DroneState.unknown;
  }

  bool _isWithinTolerance(double angle, double reference) {
    return (angle - reference).abs() <= _angleToleranceDegrees;
  }

  /// Send arm command to the drone
  void _sendArmCommand() {
    final armCommand = mavlink.CommandLong(
      targetSystem: _targetSystemId,
      targetComponent: _targetComponentId,
      command: 400, // MAV_CMD_COMPONENT_ARM_DISARM
      confirmation: 0,
      param1: 1, // 1 to arm
      param2: 21196, // Magic number for arming confirmation
      param3: 0,
      param4: 0,
      param5: 0,
      param6: 0,
      param7: 0,
    );
    _mavlinkService.sendCommand(armCommand);
    print('Arm command sent (hinge angle: $_lastHingeAngle)');
  }

  /// Send disarm command to the drone
  void _sendDisarmCommand() {
    final disarmCommand = mavlink.CommandLong(
      targetSystem: _targetSystemId,
      targetComponent: _targetComponentId,
      command: 400, // MAV_CMD_COMPONENT_ARM_DISARM
      confirmation: 0,
      param1: 0, // 0 to disarm
      param2: 0,
      param3: 0,
      param4: 0,
      param5: 0,
      param6: 0,
      param7: 0,
    );
    _mavlinkService.sendCommand(disarmCommand);
    print('Disarm command sent (hinge angle: $_lastHingeAngle)');
  }

  /// Manually arm the drone.
  void arm() {
    _sendArmCommand();
  }

  /// Manually disarm the drone.
  void disarm() {
    _sendDisarmCommand();
  }

  void sendTiltControlCommand({
    required double rollDegrees,
    required double pitchDegrees,
  }) {
    final rollPwm = _mapDegreesToPwm(rollDegrees);
    final pitchPwm = _mapDegreesToPwm(pitchDegrees);
    final rcOverride = mavlink.RcChannelsOverride(
      targetSystem: _targetSystemId,
      targetComponent: _targetComponentId,
      chan1Raw: rollPwm,
      chan2Raw: pitchPwm,
      chan3Raw: _rcMidPwm,
      chan4Raw: _rcMidPwm,
      chan5Raw: 65535,
      chan6Raw: 65535,
      chan7Raw: 65535,
      chan8Raw: 65535,
      chan9Raw: 0,
      chan10Raw: 0,
      chan11Raw: 0,
      chan12Raw: 0,
      chan13Raw: 0,
      chan14Raw: 0,
      chan15Raw: 0,
      chan16Raw: 0,
      chan17Raw: 0,
      chan18Raw: 0,
    );
    _mavlinkService.sendCommand(rcOverride);
  }

  int _mapDegreesToPwm(double degrees) {
    final clamped = degrees.clamp(-_maxTiltDegrees, _maxTiltDegrees);
    final normalized = clamped / _maxTiltDegrees;
    final pwm = (_rcMidPwm + normalized * _rcDelta).round();
    return math.max(1000, math.min(2000, pwm));
  }

  /// Send takeoff command to the drone
  void takeoff({double altitude = 10.0}) {
    final takeoffCommand = mavlink.CommandLong(
      targetSystem: _targetSystemId,
      targetComponent: _targetComponentId,
      command: 22, // MAV_CMD_NAV_TAKEOFF
      confirmation: 0,
      param1: 0, // Pitch
      param2: 0, // Empty
      param3: 0, // Empty
      param4: 0, // Yaw angle
      param5: 0, // Latitude
      param6: 0, // Longitude
      param7: altitude, // Altitude
    );
    _mavlinkService.sendCommand(takeoffCommand);
    print('Takeoff command sent (altitude: $altitude)');
  }

  /// Send land command to the drone
  void land() {
    final landCommand = mavlink.CommandLong(
      targetSystem: _targetSystemId,
      targetComponent: _targetComponentId,
      command: 21, // MAV_CMD_NAV_LAND
      confirmation: 0,
      param1: 0, // Abort altitude
      param2: 0, // Land mode
      param3: 0, // Empty
      param4: 0, // Yaw angle
      param5: 0, // Latitude
      param6: 0, // Longitude
      param7: 0, // Altitude
    );
    _mavlinkService.sendCommand(landCommand);
    print('Land command sent');
  }

  /// Change flight mode
  void setMode(String mode) {
    // Convert mode string to mode number
    // ArduCopter mode numbers: https://ardupilot.org/copter/docs/parameters.html#fltmode1
    final modeMap = {
      'STABILIZE': 0,
      'ACRO': 1,
      'ALT_HOLD': 2,
      'AUTO': 3,
      'GUIDED': 4,
      'LOITER': 5,
      'RTL': 6,
      'CIRCLE': 7,
      'LAND': 9,
      'DRIFT': 11,
      'SPORT': 13,
      'FLIP': 14,
      'AUTOTUNE': 15,
      'POSHOLD': 16,
      'BRAKE': 17,
      'THROW': 18,
      'AVOID_ADSB': 19,
      'GUIDED_NOGPS': 20,
      'SMART_RTL': 21,
      'FLOWHOLD': 22,
      'FOLLOW': 23,
      'ZIGZAG': 24,
      'SYSTEMID': 25,
      'AUTOROTATE': 26,
    };

    final modeNumber = modeMap[mode.toUpperCase()];
    if (modeNumber == null) {
      print('Unknown mode: $mode');
      return;
    }

    final setModeMessage = mavlink.SetMode(
      targetSystem: _targetSystemId,
      baseMode: 1, // MAV_MODE_FLAG_CUSTOM_MODE_ENABLED
      customMode: modeNumber,
    );
    _mavlinkService.sendCommand(setModeMessage);
    print('Set mode command sent: $mode ($modeNumber)');
  }

  /// Get current hinge angle
  double get currentHingeAngle => _lastHingeAngle;

  /// Get current drone state
  DroneState get currentState => _currentState;

  /// Dispose resources
  void dispose() {
    stopMonitoring();
  }
}

/// Enum representing drone states based on hinge angle
enum DroneState { unknown, disarmed, armed }
