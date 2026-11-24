import 'package:flutter/material.dart';

class MouthShapePainter extends CustomPainter {
  final String lipOpening; // "medium", "wide-slit", "relaxed-neutral", "medium-wide", "round-small", "bilabial-blow", "bilabial-open", "closed-nasal"

  MouthShapePainter({required this.lipOpening});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final lipPaint = Paint()
      ..color = const Color(0xFFE57373)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = const Color(0xFFFFCDD2)
      ..style = PaintingStyle.fill;

    final teethPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final cavityPaint = Paint()
      ..color = const Color(0xFF4A148C).withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    if (lipOpening == "wide-slit") {
      // Smile / Wide slit for "i"
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: size.width * 0.8, height: size.height * 0.28),
        const Radius.circular(15),
      );
      canvas.drawRRect(rect, cavityPaint);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(center.dx, center.dy - 4), width: size.width * 0.65, height: 10),
          const Radius.circular(3),
        ),
        teethPaint,
      );
      canvas.drawRRect(rect, lipPaint);
    } else if (lipOpening == "round-small") {
      // Small round for "o"
      final ovalRect = Rect.fromCenter(center: center, width: size.width * 0.42, height: size.height * 0.55);
      canvas.drawOval(ovalRect, cavityPaint);
      canvas.drawOval(ovalRect, lipPaint);
    } else if (lipOpening == "relaxed-neutral") {
      // Neutral flat unrounded for "u"
      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: size.width * 0.65, height: size.height * 0.22),
        const Radius.circular(12),
      );
      canvas.drawRRect(rrect, cavityPaint);
      canvas.drawRRect(rrect, lipPaint);
    } else if (lipOpening == "bilabial-blow") {
      // Blowing candle for "fu"
      final rect = Rect.fromCenter(center: center, width: size.width * 0.35, height: size.height * 0.3);
      canvas.drawOval(rect, cavityPaint);
      canvas.drawOval(rect, lipPaint);

      // Draw little wind streaks
      final windPaint = Paint()
        ..color = Colors.lightBlue
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(center.dx + 30, center.dy - 10), Offset(center.dx + 48, center.dy - 12), windPaint);
      canvas.drawLine(Offset(center.dx + 32, center.dy), Offset(center.dx + 52, center.dy), windPaint);
      canvas.drawLine(Offset(center.dx + 30, center.dy + 10), Offset(center.dx + 48, center.dy + 12), windPaint);
    } else if (lipOpening == "closed-nasal") {
      // Closed lips for "n" / "m"
      canvas.drawLine(
        Offset(center.dx - size.width * 0.35, center.dy),
        Offset(center.dx + size.width * 0.35, center.dy),
        lipPaint..strokeWidth = 7,
      );
    } else {
      // Default open medium for "a" or "e"
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: size.width * 0.7, height: size.height * 0.45),
        const Radius.circular(25),
      );
      canvas.drawRRect(rect, fillPaint);
      canvas.drawRRect(rect, cavityPaint);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(center.dx, center.dy - 10), width: size.width * 0.45, height: 12),
          const Radius.circular(4),
        ),
        teethPaint,
      );
      canvas.drawRRect(rect, lipPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class MouthShapeWidget extends StatelessWidget {
  final String lipOpening;
  final double size;

  const MouthShapeWidget({
    super.key,
    required this.lipOpening,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: CustomPaint(
        painter: MouthShapePainter(lipOpening: lipOpening),
      ),
    );
  }
}
