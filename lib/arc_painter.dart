import 'package:flutter/material.dart';
import 'dart:math';

class ArcPainter extends CustomPainter {
  final double innerRadius;
  final double outerRadius;
  final double startAngle;
  final double sweepAngle;
  final Color color;
  final Color iconColor;
  final IconData icon;
  final double strokeWidth;

  const ArcPainter({
    required this.innerRadius,
    required this.outerRadius,
    required this.startAngle,
    required this.sweepAngle,
    required this.color,
    this.iconColor = Colors.white,
    required this.icon,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final path = Path();

    final center = Offset(size.width / 2, size.height / 2);

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

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);

    final midAngle = startAngle + sweepAngle / 2;

    final midRadius = (innerRadius + outerRadius) / 2;

    final midPoint = Offset(
      center.dx + midRadius * cos(midAngle),
      center.dy + midRadius * sin(midAngle),
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: (outerRadius - innerRadius) / 2,
          fontFamily: icon.fontFamily,
          color: iconColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(midPoint.dx - textPainter.width / 2,
          midPoint.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant ArcPainter oldDelegate) {
    return oldDelegate.innerRadius != innerRadius ||
        oldDelegate.outerRadius != outerRadius ||
        oldDelegate.startAngle != startAngle ||
        oldDelegate.sweepAngle != sweepAngle ||
        oldDelegate.color != color ||
        oldDelegate.iconColor != iconColor ||
        oldDelegate.icon != icon ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
