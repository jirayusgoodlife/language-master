import 'package:flutter/material.dart';

class MouthShapePainter extends CustomPainter {
  final String lipOpening; // "medium", "wide-slit", "relaxed-neutral", "medium-wide", "round-small", "bilabial-blow", "bilabial-open", "closed-nasal"
  final double animationProgress; // 0.0 (rest/neutral) to 1.0 (fully pronounced)

  MouthShapePainter({
    required this.lipOpening,
    this.animationProgress = 1.0,
  });

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

    final t = animationProgress.clamp(0.0, 1.0);

    if (lipOpening == "wide-slit") {
      // Smile / Wide slit for "i" (expands horizontally)
      final targetW = size.width * (0.55 + 0.3 * t);
      final targetH = size.height * (0.16 + 0.12 * t);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: targetW, height: targetH),
        const Radius.circular(15),
      );
      canvas.drawRRect(rect, cavityPaint);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(center.dx, center.dy - 3), width: targetW * 0.8, height: 8),
          const Radius.circular(3),
        ),
        teethPaint,
      );
      canvas.drawRRect(rect, lipPaint);
    } else if (lipOpening == "round-small") {
      // Small round for "o" (morphs from neutral slit to round circle)
      final targetW = size.width * (0.6 - 0.18 * t);
      final targetH = size.height * (0.15 + 0.4 * t);
      final ovalRect = Rect.fromCenter(center: center, width: targetW, height: targetH);
      canvas.drawOval(ovalRect, cavityPaint);
      canvas.drawOval(ovalRect, lipPaint);
    } else if (lipOpening == "relaxed-neutral") {
      // Neutral flat unrounded for "u"
      final targetW = size.width * (0.55 + 0.1 * t);
      final targetH = size.height * (0.12 + 0.10 * t);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: targetW, height: targetH),
        const Radius.circular(12),
      );
      canvas.drawRRect(rrect, cavityPaint);
      canvas.drawRRect(rrect, lipPaint);
    } else if (lipOpening == "bilabial-blow") {
      // Blowing candle for "fu"
      final targetW = size.width * (0.45 - 0.1 * t);
      final targetH = size.height * (0.15 + 0.18 * t);
      final rect = Rect.fromCenter(center: center, width: targetW, height: targetH);
      canvas.drawOval(rect, cavityPaint);
      canvas.drawOval(rect, lipPaint);

      // Draw little wind streaks animated with progress
      if (t > 0.3) {
        final windPaint = Paint()
          ..color = Colors.lightBlue.withValues(alpha: t)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        final len = 15.0 * t;
        canvas.drawLine(Offset(center.dx + 26, center.dy - 8), Offset(center.dx + 26 + len, center.dy - 10), windPaint);
        canvas.drawLine(Offset(center.dx + 28, center.dy), Offset(center.dx + 28 + len * 1.2, center.dy), windPaint);
        canvas.drawLine(Offset(center.dx + 26, center.dy + 8), Offset(center.dx + 26 + len, center.dy + 10), windPaint);
      }
    } else if (lipOpening == "closed-nasal") {
      // Closed lips for "n" / "m"
      final lineW = size.width * (0.4 + 0.2 * t);
      canvas.drawLine(
        Offset(center.dx - lineW / 2, center.dy),
        Offset(center.dx + lineW / 2, center.dy),
        lipPaint..strokeWidth = 6 + 2 * t,
      );
    } else {
      // Default open medium for "a" or "e"
      final targetW = size.width * (0.55 + 0.2 * t);
      final targetH = size.height * (0.15 + 0.32 * t);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: targetW, height: targetH),
        Radius.circular(18 + 7 * t),
      );
      canvas.drawRRect(rect, fillPaint);
      canvas.drawRRect(rect, cavityPaint);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(center.dx, center.dy - 8), width: targetW * 0.6, height: 10),
          const Radius.circular(4),
        ),
        teethPaint,
      );
      canvas.drawRRect(rect, lipPaint);
    }
  }

  @override
  bool shouldRepaint(covariant MouthShapePainter oldDelegate) =>
      oldDelegate.lipOpening != lipOpening ||
      oldDelegate.animationProgress != animationProgress;
}

class MouthShapeWidget extends StatefulWidget {
  final String lipOpening;
  final double size;
  final bool animateOnTap;

  const MouthShapeWidget({
    super.key,
    required this.lipOpening,
    this.size = 120,
    this.animateOnTap = true,
  });

  @override
  State<MouthShapeWidget> createState() => _MouthShapeWidgetState();
}

class _MouthShapeWidgetState extends State<MouthShapeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Natural talking rhythm: rest -> open -> hold -> close
    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.15, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.85).chain(CurveTween(curve: Curves.easeInOut)), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 0.85, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.95).chain(CurveTween(curve: Curves.easeIn)), weight: 20),
    ]).animate(_controller);

    // Auto play once when opened
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant MouthShapeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lipOpening != widget.lipOpening) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void playAnimation() {
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.animateOnTap ? playAnimation : null,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            width: widget.size,
            height: widget.size,
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
              painter: MouthShapePainter(
                lipOpening: widget.lipOpening,
                animationProgress: _animation.value,
              ),
            ),
          );
        },
      ),
    );
  }
}
