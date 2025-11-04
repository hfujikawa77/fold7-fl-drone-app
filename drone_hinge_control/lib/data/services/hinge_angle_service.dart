import 'package:drone_hinge_control/data/services/dual_screen_service.dart';

/// A service that provides the hinge angle of a foldable device.
///
/// This service uses the `dual_screen` package to listen to the hinge angle
/// and provides a stream of hinge angle data.
class HingeAngleService {
  final DualScreenService _dualScreenService;

  HingeAngleService({DualScreenService? dualScreenService})
    : _dualScreenService = dualScreenService ?? DualScreenService();

  Stream<double> get hingeAngleStream =>
      _dualScreenService.hingeAngleEvents.map((angle) => angle);
}
