import 'package:flutter/material.dart';
import 'package:drone_hinge_control/data/services/hinge_angle_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final HingeAngleService hingeAngleService = HingeAngleService();

    return Scaffold(
      appBar: AppBar(title: const Text('Drone Hinge Control')),
      body: Center(
        child: StreamBuilder<double>(
          stream: hingeAngleService.hingeAngleStream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text('Hinge Angle: ${snapshot.data!.toStringAsFixed(2)}');
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              return const Text('Waiting for hinge angle data...');
            }
          },
        ),
      ),
    );
  }
}
