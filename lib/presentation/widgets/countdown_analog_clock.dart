import 'dart:math' as math;

import 'package:flutter/material.dart';

class CountdownAnalogClock extends StatelessWidget {
  const CountdownAnalogClock({
    super.key,
    required this.totalDuration,
    required this.remainingDuration,
    required this.colorScheme,
  });

  final Duration totalDuration;
  final Duration remainingDuration;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AspectRatio(
        aspectRatio: 1,
        child: CustomPaint(
          painter: _CountdownClockPainter(
            totalDuration: totalDuration,
            remainingDuration: remainingDuration,
            colorScheme: colorScheme,
          ),
        ),
      ),
    );
  }
}

class _CountdownClockPainter extends CustomPainter {
  _CountdownClockPainter({
    required this.totalDuration,
    required this.remainingDuration,
    required this.colorScheme,
  }) : progress = totalDuration.inMilliseconds <= 0
            ? 0
            : (remainingDuration.inMilliseconds.clamp(0, totalDuration.inMilliseconds) /
                totalDuration.inMilliseconds);

  final Duration totalDuration;
  final Duration remainingDuration;
  final ColorScheme colorScheme;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.shortestSide / 2;

    final Paint dialBackgroundPaint = Paint()
      ..color = colorScheme.surface
      ..style = PaintingStyle.fill;

    final Paint dialBorderPaint = Paint()
      ..color = colorScheme.outlineVariant.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.04;

    canvas.drawCircle(center, radius, dialBackgroundPaint);
    canvas.drawCircle(center, radius - dialBorderPaint.strokeWidth / 2, dialBorderPaint);

    final Paint tickPaint = Paint()
      ..color = colorScheme.onSurface.withOpacity(0.1)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = radius * 0.015;

    for (int i = 0; i < 60; i++) {
      final double tickLength = i % 5 == 0 ? radius * 0.12 : radius * 0.07;
      final double angle = (2 * math.pi / 60) * i;
      final Offset start = center + Offset(math.sin(angle), -math.cos(angle)) * (radius - tickLength);
      final Offset end = center + Offset(math.sin(angle), -math.cos(angle)) * radius;
      canvas.drawLine(start, end, tickPaint);
    }

    final Rect progressRect = Rect.fromCircle(center: center, radius: radius - radius * 0.08);
    final Paint backgroundArcPaint = Paint()
      ..color = colorScheme.surfaceVariant.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = radius * 0.08;

    canvas.drawArc(progressRect, -math.pi / 2, 2 * math.pi, false, backgroundArcPaint);

    final Paint progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [colorScheme.primary, colorScheme.secondary],
      ).createShader(progressRect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = radius * 0.08;

    canvas.drawArc(progressRect, -math.pi / 2, -2 * math.pi * progress, false, progressPaint);

    final int seconds = remainingDuration.inSeconds.remainder(60);
    final double minutesTotal = remainingDuration.inMinutes.remainder(60) + (seconds / 60);
    final double hoursTotal = (remainingDuration.inHours.remainder(12)) + (minutesTotal / 60);

    final double secondsAngle = 2 * math.pi * (seconds / 60);
    final double minutesAngle = 2 * math.pi * (minutesTotal / 60);
    final double hoursAngle = 2 * math.pi * (hoursTotal / 12);

    _drawHand(
      canvas,
      center,
      radius * 0.55,
      secondsAngle,
      Paint()
        ..color = colorScheme.primary
        ..strokeWidth = radius * 0.015
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    _drawHand(
      canvas,
      center,
      radius * 0.7,
      minutesAngle,
      Paint()
        ..color = colorScheme.secondary
        ..strokeWidth = radius * 0.025
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    _drawHand(
      canvas,
      center,
      radius * 0.45,
      hoursAngle,
      Paint()
        ..color = colorScheme.onSurface.withOpacity(0.8)
        ..strokeWidth = radius * 0.04
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    final Paint centerDot = Paint()
      ..color = colorScheme.surface
      ..style = PaintingStyle.fill;

    final Paint centerBorder = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.05;

    canvas.drawCircle(center, radius * 0.06, centerDot);
    canvas.drawCircle(center, radius * 0.06, centerBorder);
  }

  void _drawHand(Canvas canvas, Offset center, double length, double angle, Paint paint) {
    final Offset handEnd = center + Offset(math.sin(angle), -math.cos(angle)) * length;
    canvas.drawLine(center, handEnd, paint);
  }

  @override
  bool shouldRepaint(covariant _CountdownClockPainter oldDelegate) {
    return oldDelegate.remainingDuration != remainingDuration ||
        oldDelegate.totalDuration != totalDuration ||
        oldDelegate.colorScheme != colorScheme;
  }
}
