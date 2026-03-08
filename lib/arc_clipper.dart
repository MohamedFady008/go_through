import 'dart:math';

import 'package:flutter/material.dart';

class ArcClipper extends CustomClipper<Path> {
  final double innerRadius;
  final double outerRadius;
  final double startAngle;
  final double sweepAngle;

  const ArcClipper({
    required this.innerRadius,
    required this.outerRadius,
    required this.startAngle,
    required this.sweepAngle,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);

    // Move to the start of the outer arc
    path.moveTo(
      center.dx + outerRadius * cos(startAngle),
      center.dy + outerRadius * sin(startAngle),
    );

    path.arcTo(
      Rect.fromCircle(center: center, radius: outerRadius),
      startAngle,
      sweepAngle,
      false,
    );

    path.lineTo(
      center.dx + innerRadius * cos(startAngle + sweepAngle),
      center.dy + innerRadius * sin(startAngle + sweepAngle),
    );

    path.arcTo(
      Rect.fromCircle(center: center, radius: innerRadius),
      startAngle + sweepAngle,
      -sweepAngle,
      false,
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant ArcClipper oldClipper) {
    return oldClipper.innerRadius != innerRadius ||
        oldClipper.outerRadius != outerRadius ||
        oldClipper.startAngle != startAngle ||
        oldClipper.sweepAngle != sweepAngle;
  }
}
