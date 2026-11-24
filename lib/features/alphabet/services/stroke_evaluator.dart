import 'package:flutter/material.dart';
import '../widgets/stroke_canvas_painter.dart';

class StrokeEvaluator {
  /// Calculates accuracy percentage (0 - 100%) by analyzing user strokes
  /// and measuring bounding box, center alignment, stroke count and proportion.
  static int evaluateStrokes({
    required List<StrokeLine> userStrokes,
    required String targetChar,
    required double canvasSize,
  }) {
    if (userStrokes.isEmpty) return 0;

    // Collect all points from user strokes
    final List<Offset> userPoints = [];
    for (final stroke in userStrokes) {
      if (stroke.points.isEmpty) continue;
      for (int i = 0; i < stroke.points.length; i++) {
        userPoints.add(stroke.points[i]);
      }
    }

    if (userPoints.length < 5) return 10;

    // Calculate bounding box of user strokes
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;
    for (final p in userPoints) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }

    final userWidth = maxX - minX;
    final userHeight = maxY - minY;
    final userCenter = Offset(minX + userWidth / 2, minY + userHeight / 2);
    final canvasCenter = Offset(canvasSize / 2, canvasSize / 2);

    // Distance of user center from canvas center (crosshair)
    final centerDist = (userCenter - canvasCenter).distance;
    final centerScore = (1.0 - (centerDist / (canvasSize * 0.4))).clamp(0.0, 1.0);

    // Size proportion score
    final expectedDim = canvasSize * 0.65;
    final sizeScoreX = (1.0 - (userWidth - expectedDim).abs() / expectedDim).clamp(0.0, 1.0);
    final sizeScoreY = (1.0 - (userHeight - expectedDim).abs() / expectedDim).clamp(0.0, 1.0);
    final sizeScore = (sizeScoreX + sizeScoreY) / 2;

    // Stroke count score (Hiragana typically has 1 to 4 strokes)
    double strokeCountScore = 1.0;
    if (userStrokes.length > 6) {
      strokeCountScore = 0.5;
    } else if (userStrokes.isNotEmpty && userStrokes.length <= 4) {
      strokeCountScore = 1.0;
    } else {
      strokeCountScore = 0.8;
    }

    // Density and coverage check
    final totalPoints = userPoints.length;
    final densityScore = (totalPoints / 60.0).clamp(0.2, 1.0);

    // Composite accuracy
    final combined = (centerScore * 0.35 + sizeScore * 0.35 + strokeCountScore * 0.15 + densityScore * 0.15);
    final percentage = (combined * 100).round();

    // Scale realistically between 30% and 98% for deliberate attempts
    return percentage.clamp(25, 98);
  }
}
