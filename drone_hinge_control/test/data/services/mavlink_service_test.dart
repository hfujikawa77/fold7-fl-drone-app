import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_mavlink/mavlink.dart';
import 'package:dart_mavlink/dialects/ardupilotmega.dart'
    as mavlink_ardupilotmega;
import 'package:drone_hinge_control/data/services/mavlink_service.dart';
import 'package:drone_hinge_control/data/services/raw_datagram_socket_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRawDatagramSocketService extends Mock
    implements RawDatagramSocketService {}

class MockInternetAddress extends Mock implements InternetAddress {}

void main() {
  setUpAll(() {
    registerFallbackValue(MockInternetAddress());
    registerFallbackValue(Uint8List(0));
  });

  group('MavlinkService', () {
    const testRemotePort = 14550;
    const testLocalPort = 14551;

    late MavlinkService mavlinkService;
    late MockRawDatagramSocketService mockRawDatagramSocketService;
    late StreamController<RawSocketEvent> socketEventController;

    setUp(() {
      mockRawDatagramSocketService = MockRawDatagramSocketService();
      socketEventController = StreamController<RawSocketEvent>();

      when(
        () => mockRawDatagramSocketService.bind(any(), any()),
      ).thenAnswer((_) async => mockRawDatagramSocketService);
      when(() => mockRawDatagramSocketService.port).thenReturn(testLocalPort);
      when(() => mockRawDatagramSocketService.listen(any())).thenAnswer((
        invocation,
      ) {
        final onData =
            invocation.positionalArguments[0] as void Function(RawSocketEvent);
        return socketEventController.stream.listen(onData);
      });
      when(() => mockRawDatagramSocketService.receive()).thenReturn(null);
      when(
        () => mockRawDatagramSocketService.send(any(), any(), any()),
      ).thenReturn(0);
      when(() => mockRawDatagramSocketService.close()).thenAnswer((_) {});

      mavlinkService = MavlinkService(
        socketServiceFactory: () => mockRawDatagramSocketService,
      );
    });

    tearDown(() {
      socketEventController.close();
    });

    test('connect sets isConnected to true on success', () async {
      await mavlinkService.connect(
        '127.0.0.1',
        remotePort: testRemotePort,
        localPort: testLocalPort,
      );
      expect(mavlinkService.isConnected, isTrue);
      expect(mavlinkService.targetSystemId, 1);
      expect(mavlinkService.targetComponentId, 1);
      verify(
        () => mockRawDatagramSocketService.bind(
          InternetAddress.anyIPv4,
          testLocalPort,
        ),
      ).called(1);
    });

    test('updateIdentity changes outbound system/component ids', () {
      mavlinkService.updateIdentity(systemId: 1, componentId: 2);
      expect(mavlinkService.systemId, 1);
      expect(mavlinkService.componentId, 2);
    });

    test('disconnect sets isConnected to false', () async {
      await mavlinkService.connect(
        '127.0.0.1',
        remotePort: testRemotePort,
        localPort: testLocalPort,
      );
      mavlinkService.disconnect();
      expect(mavlinkService.isConnected, isFalse);
    });

    test('sendHeartbeat sends a heartbeat message', () async {
      await mavlinkService.connect(
        '127.0.0.1',
        remotePort: testRemotePort,
        localPort: testLocalPort,
      );
      mavlinkService.sendHeartbeat();

      verify(
        () => mockRawDatagramSocketService.send(any(), any(), any()),
      ).called(6); // Initial handshake + explicit call
    });

    test('connect sends initial heartbeat to configured endpoint', () async {
      await mavlinkService.connect(
        '127.0.0.1',
        remotePort: testRemotePort,
        localPort: testLocalPort,
      );

      verify(
        () => mockRawDatagramSocketService.send(
          any(),
          any(),
          testRemotePort,
        ),
      ).called(5);
    });

    test('inputStream emits received MAVLink frames', () async {
      final mavlinkService = MavlinkService(
        socketServiceFactory: () => mockRawDatagramSocketService,
      );
      await mavlinkService.connect(
        '127.0.0.1',
        remotePort: testRemotePort,
        localPort: testLocalPort,
      );

      final heartbeat = mavlink_ardupilotmega.Heartbeat(
        type: 2, // MAV_TYPE_QUADROTOR
        autopilot: 4, // MAV_AUTOPILOT_ARDUPILOTMEGA
        baseMode: 16, // MAV_MODE_FLAG_STABILIZE_ENABLED
        customMode: 0,
        systemStatus: 4, // MAV_STATE_ACTIVE
        mavlinkVersion: 3,
      );
      final frame = MavlinkFrame.v2(0, 255, 1, heartbeat);
      final bytes = frame.serialize();

      when(
        () => mockRawDatagramSocketService.receive(),
      ).thenReturn(Datagram(bytes, MockInternetAddress(), testRemotePort));

      expectLater(
        mavlinkService.inputStream.map(
          (frame) => frame.message.runtimeType.toString(),
        ),
        emits('Heartbeat'),
      );

      socketEventController.add(RawSocketEvent.read);
    });

    test('updates target system/component ids from incoming frames', () async {
      final mavlinkService = MavlinkService(
        socketServiceFactory: () => mockRawDatagramSocketService,
      );
      await mavlinkService.connect(
        '127.0.0.1',
        remotePort: testRemotePort,
        localPort: testLocalPort,
      );

      final heartbeat = mavlink_ardupilotmega.Heartbeat(
        type: 2,
        autopilot: 4,
        baseMode: 16,
        customMode: 0,
        systemStatus: 4,
        mavlinkVersion: 3,
      );
      final frame = MavlinkFrame.v2(0, 99, 42, heartbeat);
      final bytes = frame.serialize();

      when(
        () => mockRawDatagramSocketService.receive(),
      ).thenReturn(Datagram(bytes, MockInternetAddress(), testRemotePort));

      socketEventController.add(RawSocketEvent.read);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(mavlinkService.targetSystemId, 99);
      expect(mavlinkService.targetComponentId, 42);
    });

    test('commandAckStream emits parsed acknowledgements', () async {
      final mavlinkService = MavlinkService(
        socketServiceFactory: () => mockRawDatagramSocketService,
      );
      await mavlinkService.connect(
        '127.0.0.1',
        remotePort: testRemotePort,
        localPort: testLocalPort,
      );

      final ack = mavlink_ardupilotmega.CommandAck(
        command: mavlink_ardupilotmega.mavCmdComponentArmDisarm,
        result: mavlink_ardupilotmega.mavResultDenied,
        progress: 0,
        resultParam2: 0,
        targetSystem: 201,
        targetComponent: 191,
      );
      final frame = MavlinkFrame.v2(0, 1, 1, ack);
      final bytes = frame.serialize();

      when(
        () => mockRawDatagramSocketService.receive(),
      ).thenReturn(Datagram(bytes, MockInternetAddress(), testRemotePort));

      expectLater(
        mavlinkService.commandAckStream.map((ack) => ack.result),
        emits(mavlink_ardupilotmega.mavResultDenied),
      );
      socketEventController.add(RawSocketEvent.read);
    });
  });
}
