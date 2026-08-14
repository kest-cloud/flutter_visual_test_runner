import 'package:flutter/material.dart';
import '../models/test_enums.dart';

/// Dynamic touch ripple shockwave and simulated pointer cursor painter.
class RippleEffectPainter extends CustomPainter {
  final Offset? touchPoint;
  final TestStepType? actionType;
  final double animationProgress; // 0.0 to 1.0
  final Color rippleColor;

  RippleEffectPainter({
    required this.touchPoint,
    required this.actionType,
    required this.animationProgress,
    this.rippleColor = const Color(0xFF00E5FF),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (touchPoint == null || actionType == null) return;

    // We draw action ripples for tap, doubleTap, longPress, and enterText
    final isTapAction = actionType == TestStepType.tap ||
        actionType == TestStepType.doubleTap ||
        actionType == TestStepType.longPress ||
        actionType == TestStepType.enterText;

    if (!isTapAction) return;

    final progress = animationProgress.clamp(0.0, 1.0);
    final maxRadius = actionType == TestStepType.longPress ? 60.0 : 42.0;

    // 1. Primary Shockwave Ring
    final currentRadius = maxRadius * Curves.easeOutCubic.transform(progress);
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    final shockwavePaint = Paint()
      ..color = rippleColor.withValues(alpha: opacity * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * (1.0 - progress);

    canvas.drawCircle(touchPoint!, currentRadius, shockwavePaint);

    // 2. Secondary Inner Ripple Ring
    if (progress > 0.15) {
      final innerProgress = ((progress - 0.15) / 0.85).clamp(0.0, 1.0);
      final innerRadius = (maxRadius * 0.7) * Curves.easeOutQuad.transform(innerProgress);
      final innerOpacity = (1.0 - innerProgress).clamp(0.0, 1.0);

      final innerPaint = Paint()
        ..color = const Color(0xFFFF4081).withValues(alpha: innerOpacity * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8 * (1.0 - innerProgress);

      canvas.drawCircle(touchPoint!, innerRadius, innerPaint);
    }

    // 3. Central Ripple Flash Fill
    final flashPaint = Paint()
      ..color = Colors.white.withValues(alpha: (1.0 - progress * 1.5).clamp(0.0, 0.8))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(touchPoint!, 8.0 * (1.0 - progress), flashPaint);
  }

  @override
  bool shouldRepaint(covariant RippleEffectPainter oldDelegate) {
    return oldDelegate.touchPoint != touchPoint ||
        oldDelegate.actionType != actionType ||
        oldDelegate.animationProgress != animationProgress;
  }
}
