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
    late MavlinkService mavlinkService;
    late MockRawDatagramSocketService mockRawDatagramSocketService;
    late StreamController<RawSocketEvent> socketEventController;

    setUp(() {
      mockRawDatagramSocketService = MockRawDatagramSocketService();
      socketEventController = StreamController<RawSocketEvent>();

      when(
        () => mockRawDatagramSocketService.bind(any(), any()),
      ).thenAnswer((_) async => mockRawDatagramSocketService);
      when(() => mockRawDatagramSocketService.port).thenReturn(14551);
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
      await mavlinkService.connect('127.0.0.1', 14550);
      expect(mavlinkService.isConnected, isTrue);
      verify(
        () => mockRawDatagramSocketService.bind(
          InternetAddress.anyIPv4,
          14551,
        ),
      ).called(1);
    });

    test('disconnect sets isConnected to false', () async {
      await mavlinkService.connect('127.0.0.1', 14550);
      mavlinkService.disconnect();
      expect(mavlinkService.isConnected, isFalse);
    });

    test('sendHeartbeat sends a heartbeat message', () async {
      await mavlinkService.connect('127.0.0.1', 14550);
      mavlinkService.sendHeartbeat();

      verify(
        () => mockRawDatagramSocketService.send(any(), any(), any()),
      ).called(6); // Initial handshake + explicit call
    });

    test('connect sends initial heartbeat to configured endpoint', () async {
      await mavlinkService.connect('127.0.0.1', 14550);

      verify(
        () => mockRawDatagramSocketService.send(
          any(),
          any(),
          14550,
        ),
      ).called(5);
    });

    test('inputStream emits received MAVLink frames', () async {
      final mavlinkService = MavlinkService(
        socketServiceFactory: () => mockRawDatagramSocketService,
      );
      await mavlinkService.connect('127.0.0.1', 14550);

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
      ).thenReturn(Datagram(bytes, MockInternetAddress(), 14550));

      expectLater(
        mavlinkService.inputStream.map(
          (frame) => frame.message.runtimeType.toString(),
        ),
        emits('Heartbeat'),
      );

      socketEventController.add(RawSocketEvent.read);
    });
  });
}
