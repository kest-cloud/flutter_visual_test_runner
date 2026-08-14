import 'package:flutter/material.dart';

/// High-tech animated neon bounding box and target ring painter.
class TargetHighlightPainter extends CustomPainter {
  final Rect? targetRect;
  final Offset? targetPoint;
  final double animationProgress; // 0.0 to 1.0
  final Color primaryColor;
  final Color secondaryColor;

  TargetHighlightPainter({
    required this.targetRect,
    required this.targetPoint,
    required this.animationProgress,
    this.primaryColor = const Color(0xFF00E5FF), // Neon Cyan
    this.secondaryColor = const Color(0xFF7C4DFF), // Electric Violet
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (targetRect == null && targetPoint == null) return;

    final glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.25 + 0.15 * animationProgress)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final borderPaint = Paint()
      ..shader = LinearGradient(
        colors: [primaryColor, secondaryColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(targetRect ?? Rect.fromCenter(center: targetPoint!, width: 40, height: 40))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    if (targetRect != null) {
      final rrect = RRect.fromRectAndRadius(
        targetRect!.inflate(4.0),
        const Radius.circular(8.0),
      );

      // 1. Soft glowing outer halo
      canvas.drawRRect(rrect, glowPaint);

      // 2. Neon bounding border
      canvas.drawRRect(rrect, borderPaint);

      // 3. Technical Corner Brackets
      _drawCornerBrackets(canvas, targetRect!.inflate(6.0), primaryColor);
    }

    // 4. Center Target Crosshair / Ring
    final center = targetPoint ?? targetRect?.center;
    if (center != null) {
      _drawCenterTarget(canvas, center, primaryColor, secondaryColor, animationProgress);
    }
  }

  void _drawCornerBrackets(Canvas canvas, Rect rect, Color color) {
    final bracketPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.square;

    const cornerLength = 12.0;

    // Top-Left
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(cornerLength, 0), bracketPaint);
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(0, cornerLength), bracketPaint);

    // Top-Right
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(-cornerLength, 0), bracketPaint);
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(0, cornerLength), bracketPaint);

    // Bottom-Left
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(cornerLength, 0), bracketPaint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(0, -cornerLength), bracketPaint);

    // Bottom-Right
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(-cornerLength, 0), bracketPaint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(0, -cornerLength), bracketPaint);
  }

  void _drawCenterTarget(
    Canvas canvas,
    Offset center,
    Color primary,
    Color secondary,
    double progress,
  ) {
    final ringRadius = 14.0 + (3.0 * progress);
    final ringPaint = Paint()
      ..color = primary.withValues(alpha: 0.8 - 0.4 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final dotPaint = Paint()
      ..color = secondary
      ..style = PaintingStyle.fill;

    // Center point
    canvas.drawCircle(center, 3.5, dotPaint);

    // Expanding pulsing ring
    canvas.drawCircle(center, ringRadius, ringPaint);

    // Crosshair ticks
    final tickPaint = Paint()
      ..color = primary.withValues(alpha: 0.6)
      ..strokeWidth = 1.2;

    const tickLen = 6.0;
    canvas.drawLine(center - Offset(ringRadius + tickLen, 0), center - Offset(ringRadius, 0), tickPaint);
    canvas.drawLine(center + Offset(ringRadius, 0), center + Offset(ringRadius + tickLen, 0), tickPaint);
    canvas.drawLine(center - Offset(0, ringRadius + tickLen), center - Offset(0, ringRadius), tickPaint);
    canvas.drawLine(center + Offset(0, ringRadius), center + Offset(0, ringRadius + tickLen), tickPaint);
  }

  @override
  bool shouldRepaint(covariant TargetHighlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.targetPoint != targetPoint ||
        oldDelegate.animationProgress != animationProgress;
  }
}
