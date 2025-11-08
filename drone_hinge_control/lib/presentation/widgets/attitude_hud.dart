import 'dart:math' as math;

import 'package:dart_mavlink/dialects/ardupilotmega.dart' as mavlink;
import 'package:flutter/material.dart';

/// Circular HUD that mimics a simple attitude indicator with pinch zoom.
class AttitudeHud extends StatefulWidget {
  final mavlink.Attitude? attitude;
  final double baseSize;

  const AttitudeHud({
    super.key,
    this.attitude,
    this.baseSize = 160,
  });

  @override
  State<AttitudeHud> createState() => _AttitudeHudState();
}

class _AttitudeHudState extends State<AttitudeHud> {
  double _scale = 1.0;
  double _initialScale = 1.0;

  void _handleScaleStart(ScaleStartDetails details) {
    _initialScale = _scale;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = (_initialScale * details.scale).clamp(0.7, 2.2);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.baseSize * _scale;
    return GestureDetector(
      onScaleStart: _handleScaleStart,
      onScaleUpdate: _handleScaleUpdate,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(size),
          border: Border.all(color: Colors.white24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _AttitudeHudPainter(widget.attitude),
            ),
          ),
        ),
      ),
    );
  }
}

class _AttitudeHudPainter extends CustomPainter {
  final mavlink.Attitude? attitude;

  _AttitudeHudPainter(this.attitude);

  static const double _maxPitchDegrees = 45;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 4;

    final circlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, circlePaint);

    final attitudeData = attitude;
    if (attitudeData == null) {
      _drawNoData(canvas, size);
      return;
    }

    final roll = attitudeData.roll;
    final pitch = attitudeData.pitch;
    final yaw = attitudeData.yaw;

    // Draw horizon with roll rotation.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-roll);

    final pitchDegrees = pitch * 180 / math.pi;
    final pitchRatio = (pitchDegrees / _maxPitchDegrees).clamp(-1.0, 1.0);
    final pitchOffset = pitchRatio * radius * 0.8;

    final horizonPaint = Paint()
      ..color = Colors.orangeAccent
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(-radius, pitchOffset),
      Offset(radius, pitchOffset),
      horizonPaint,
    );

    final tickPaint = Paint()
      ..color = Colors.orangeAccent
      ..strokeWidth = 2;
    for (int deg = -30; deg <= 30; deg += 10) {
      final tickOffset = (deg / _maxPitchDegrees).clamp(-1.0, 1.0) *
          radius *
          0.8;
      final tickLength = deg % 20 == 0 ? 16.0 : 10.0;
      canvas.drawLine(
        Offset(-tickLength / 2, tickOffset),
        Offset(tickLength / 2, tickOffset),
        tickPaint,
      );
    }
    canvas.restore();

    // Draw roll indicator (outer arc markers)
    final rollPaint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 2;
    for (int deg = -60; deg <= 60; deg += 30) {
      final angle = (deg - 90) * math.pi / 180;
      final start = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final end = Offset(
        center.dx + (radius - 12) * math.cos(angle),
        center.dy + (radius - 12) * math.sin(angle),
      );
      canvas.drawLine(start, end, rollPaint);
    }

    // Draw airplane/center marker
    final markerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(center.dx - 20, center.dy),
      Offset(center.dx + 20, center.dy),
      markerPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 15),
      Offset(center.dx, center.dy + 15),
      markerPaint,
    );
    canvas.drawCircle(center, 4, markerPaint);

    final textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 12,
    );
    final pitchText = pitchDegrees.toStringAsFixed(0);
    final rollText = (roll * 180 / math.pi).toStringAsFixed(0);
    final yawText =
        ((yaw * 180 / math.pi + 360) % 360).toStringAsFixed(0);
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'P:$pitchText°  R:$rollText°  Y:$yawText°',
        style: textStyle,
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        size.height - textPainter.height,
      ),
    );
  }

  void _drawNoData(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'No attitude data',
        style: TextStyle(color: Colors.white70),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _AttitudeHudPainter oldDelegate) {
    return oldDelegate.attitude != attitude;
  }
}

