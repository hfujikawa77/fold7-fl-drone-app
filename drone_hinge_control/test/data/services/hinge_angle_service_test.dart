import 'dart:async';

import 'package:drone_hinge_control/data/services/dual_screen_service.dart';
import 'package:drone_hinge_control/data/services/hinge_angle_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDualScreenService extends Mock implements DualScreenService {}

void main() {
  group('HingeAngleService', () {
    late HingeAngleService hingeAngleService;
    late MockDualScreenService mockDualScreenService;
    late StreamController<double> hingeAngleController;

    setUp(() {
      mockDualScreenService = MockDualScreenService();
      hingeAngleController = StreamController<double>();
      when(
        () => mockDualScreenService.hingeAngleEvents,
      ).thenAnswer((_) => hingeAngleController.stream);
      hingeAngleService = HingeAngleService(
        dualScreenService: mockDualScreenService,
      );
    });

    tearDown(() {
      hingeAngleController.close();
    });

    test('hingeAngleStream emits hinge angle updates', () {
      final expectedAngles = [0.0, 45.0, 90.0, 180.0];

      expectLater(
        hingeAngleService.hingeAngleStream,
        emitsInOrder(expectedAngles),
      );

      for (final angle in expectedAngles) {
        hingeAngleController.add(angle);
      }
    });
  });
}
