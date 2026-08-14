import 'package:flutter/material.dart';

/// Ultra-modern glassmorphic dark theme colors and styles for the Visual Test Runner dashboard.
class RunnerTheme {
  static const Color background = Color(0xFF0B0F19);
  static const Color surface = Color(0xFF111827);
  static const Color surfaceElevated = Color(0xFF1A2234);
  static const Color cardGlass = Color(0xCC161F30);

  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color electricViolet = Color(0xFF7C4DFF);
  static const Color emeraldGreen = Color(0xFF00E676);
  static const Color crimsonRed = Color(0xFFFF5252);
  static const Color amberWarning = Color(0xFFFFB300);

  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [neonCyan, electricViolet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x331E293B), Color(0x1A0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static BoxDecoration glassDecoration({
    double radius = 16.0,
    Color borderColor = const Color(0x3338BDF8),
    Color fillColor = const Color(0xCC111827),
  }) {
    return BoxDecoration(
      color: fillColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: 1.2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.5),
          blurRadius: 20.0,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
