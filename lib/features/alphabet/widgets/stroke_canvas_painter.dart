import 'package:flutter/material.dart';

class StrokeLine {
  final List<Offset> points;
  StrokeLine({required this.points});
}

class StrokeCanvasPainter extends CustomPainter {
  final List<StrokeLine> userStrokes;
  final StrokeLine? currentStroke;
  final String guideChar;
  final bool showGuide;
  final bool isOverlay;

  StrokeCanvasPainter({
    required this.userStrokes,
    required this.currentStroke,
    required this.guideChar,
    this.showGuide = true,
    this.isOverlay = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isOverlay) {
      // 1. Draw Grid lines (traditional Japanese Kanji/Kana practice sheet layout)
      final gridPaint = Paint()
        ..color = Colors.grey.shade300
        ..strokeWidth = 1.0;

      final dashPaint = Paint()
        ..color = Colors.grey.shade300
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      // Background sheet
      final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(16),
      );
      canvas.drawRRect(bgRect, Paint()..color = const Color(0xFFFAFAFA));

      // Outer border
      canvas.drawRRect(
        bgRect,
        Paint()
          ..color = Colors.grey.shade400
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      // Cross grid lines
      canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), dashPaint);
      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), dashPaint);

      // Diagonal guidelines
      canvas.drawLine(Offset.zero, Offset(size.width, size.height), gridPaint..color = Colors.grey.shade200);
      canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), gridPaint..color = Colors.grey.shade200);

      // 2. Draw Faint Guide Character
      if (showGuide) {
        final textSpan = TextSpan(
          text: guideChar,
          style: TextStyle(
            fontSize: size.width * 0.72,
            fontWeight: FontWeight.w400,
            color: Colors.grey.shade300,
            fontFamily: 'sans-serif',
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            (size.width - textPainter.width) / 2,
            (size.height - textPainter.height) / 2,
          ),
        );
      }
    }

    // 3. Draw User Strokes (Brush style)
    final userStrokePaint = Paint()
      ..color = const Color(0xFFD32F2F).withValues(alpha: 0.85) // Reddish brush on top of black guide
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 12.0
      ..style = PaintingStyle.stroke;

    void drawStroke(StrokeLine stroke) {
      if (stroke.points.isEmpty) return;
      if (stroke.points.length == 1) {
        canvas.drawCircle(stroke.points.first, 6.0, Paint()..color = const Color(0xFFD32F2F));
        return;
      }
      final path = Path();
      path.moveTo(stroke.points[0].dx, stroke.points[0].dy);
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      canvas.drawPath(path, userStrokePaint);
    }

    for (final stroke in userStrokes) {
      drawStroke(stroke);
    }

    if (currentStroke != null) {
      drawStroke(currentStroke!);
    }
  }

  @override
  bool shouldRepaint(covariant StrokeCanvasPainter oldDelegate) => true;
}
