import 'package:flutter/material.dart';

class DashedLinePainter extends CustomPainter {
  final bool showGrid;

  DashedLinePainter({this.showGrid = true});

  @override
  void paint(Canvas canvas, Size size) {
    // Outer border
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(16),
    );
    canvas.drawRRect(bgRect, Paint()..color = Colors.white);
    canvas.drawRRect(
      bgRect,
      Paint()
        ..color = Colors.grey.shade300
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    if (!showGrid) return;

    final dashPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const dashWidth = 5.0;
    const dashSpace = 4.0;

    // Horizontal center dashed line
    final double midY = size.height / 2;
    double startX = 10;
    while (startX < size.width - 10) {
      canvas.drawLine(
        Offset(startX, midY),
        Offset((startX + dashWidth).clamp(0, size.width - 10), midY),
        dashPaint,
      );
      startX += dashWidth + dashSpace;
    }

    // Vertical center dashed line
    final double midX = size.width / 2;
    double startY = 10;
    while (startY < size.height - 10) {
      canvas.drawLine(
        Offset(midX, startY),
        Offset(midX, (startY + dashWidth).clamp(0, size.height - 10)),
        dashPaint,
      );
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant DashedLinePainter oldDelegate) =>
      oldDelegate.showGrid != showGrid;
}
