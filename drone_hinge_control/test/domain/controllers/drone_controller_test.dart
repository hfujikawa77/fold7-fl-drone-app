import 'dart:async';

import 'package:drone_hinge_control/data/services/hinge_angle_service.dart';
import 'package:drone_hinge_control/data/services/mavlink_service.dart';
import 'package:drone_hinge_control/domain/controllers/drone_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockHingeAngleService extends Mock implements HingeAngleService {}

class MockMavlinkService extends Mock implements MavlinkService {}

void main() {
  group('DroneController', () {
    late DroneController droneController;
    late MockHingeAngleService mockHingeAngleService;
    late MockMavlinkService mockMavlinkService;
    late StreamController<double> hingeAngleController;

    setUp(() {
      mockHingeAngleService = MockHingeAngleService();
      mockMavlinkService = MockMavlinkService();
      hingeAngleController = StreamController<double>.broadcast();

      when(
        () => mockHingeAngleService.hingeAngleStream,
      ).thenAnswer((_) => hingeAngleController.stream);
      when(() => mockMavlinkService.sendCommand(any())).thenAnswer((_) {});

      droneController = DroneController(
        hingeAngleService: mockHingeAngleService,
        mavlinkService: mockMavlinkService,
      );
    });

    tearDown(() {
      droneController.dispose();
      hingeAngleController.close();
    });

    test('initial state is unknown', () {
      expect(droneController.currentState, DroneState.unknown);
      expect(droneController.currentHingeAngle, 0.0);
    });

    test('startMonitoring subscribes to hinge angle stream', () {
      droneController.startMonitoring();
      verify(() => mockHingeAngleService.hingeAngleStream).called(1);
    });

    test('stopMonitoring cancels subscription', () {
      droneController.startMonitoring();
      droneController.stopMonitoring();
      // Subscription should be cancelled, no exception should be thrown
    });

    test('hinge angle 0-30 degrees triggers disarm command', () async {
      droneController.startMonitoring();

      hingeAngleController.add(15.0);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(droneController.currentState, DroneState.disarmed);
      expect(droneController.currentHingeAngle, 15.0);
      verify(() => mockMavlinkService.sendCommand(any())).called(1);
    });

    test('hinge angle 60-120 degrees triggers arm command', () async {
      droneController.startMonitoring();

      hingeAngleController.add(90.0);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(droneController.currentState, DroneState.armed);
      expect(droneController.currentHingeAngle, 90.0);
      verify(() => mockMavlinkService.sendCommand(any())).called(1);
    });

    test('hinge angle 150-180 degrees triggers RC override', () async {
      droneController.startMonitoring();

      hingeAngleController.add(170.0);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(droneController.currentState, DroneState.rcOverride);
      expect(droneController.currentHingeAngle, 170.0);
      verify(() => mockMavlinkService.sendCommand(any())).called(1);
    });

    test('state transitions do not trigger repeated commands', () async {
      droneController.startMonitoring();

      // First angle in armed range
      hingeAngleController.add(90.0);
      await Future.delayed(const Duration(milliseconds: 100));

      // Second angle in same range
      hingeAngleController.add(95.0);
      await Future.delayed(const Duration(milliseconds: 100));

      // Should only send one arm command
      verify(() => mockMavlinkService.sendCommand(any())).called(1);
    });

    test('state changes from armed to disarmed', () async {
      droneController.startMonitoring();

      // First arm
      hingeAngleController.add(90.0);
      await Future.delayed(const Duration(milliseconds: 100));

      // Then disarm
      hingeAngleController.add(10.0);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(droneController.currentState, DroneState.disarmed);
      // Should send both arm and disarm commands
      verify(() => mockMavlinkService.sendCommand(any())).called(2);
    });

    test('takeoff sends takeoff command', () {
      droneController.takeoff(altitude: 15.0);
      verify(() => mockMavlinkService.sendCommand(any())).called(1);
    });

    test('land sends land command', () {
      droneController.land();
      verify(() => mockMavlinkService.sendCommand(any())).called(1);
    });

    test('setMode sends mode change command for valid mode', () {
      droneController.setMode('GUIDED');
      verify(() => mockMavlinkService.sendCommand(any())).called(1);
    });

    test('setMode does not send command for invalid mode', () {
      droneController.setMode('INVALID_MODE');
      verifyNever(() => mockMavlinkService.sendCommand(any()));
    });

    test('dispose stops monitoring', () {
      droneController.startMonitoring();
      droneController.dispose();
      // Should not throw exception
    });
  });
}
