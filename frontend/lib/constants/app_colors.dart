import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Background & Surface ──────────────────────────────────────────
  static const Color background = Color(0xFF0A0E1A);
  static const Color backgroundLight = Color(0xFF0F1428);
  static const Color surface = Color(0xFF141929);
  static const Color surfaceLight = Color(0xFF1A1F35);
  static const Color surfaceBorder = Color(0xFF252B45);

  // ── Primary ───────────────────────────────────────────────────────
  static const Color primary = Color(0xFF00D4FF);
  static const Color primaryDim = Color(0xFF0098B8);
  static const Color primaryGlow = Color(0x3300D4FF);

  // ── Severity ──────────────────────────────────────────────────────
  static const Color severityCritical = Color(0xFFFF3B4A);
  static const Color severityWarning = Color(0xFFFF9500);
  static const Color severitySafe = Color(0xFF00E676);

  // ── Shield ────────────────────────────────────────────────────────
  static const Color shieldSecure = Color(0xFF00E676);
  static const Color shieldThreat = Color(0xFFFF3B4A);
  static const Color shieldSecureGlow = Color(0x3300E676);
  static const Color shieldThreatGlow = Color(0x33FF3B4A);

  // ── Text ──────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFE8ECF4);
  static const Color textSecondary = Color(0xFF8E95A9);
  static const Color textMuted = Color(0xFF5A6178);

  // ── Chart ─────────────────────────────────────────────────────────
  static const Color chartLine = Color(0xFF00D4FF);
  static const Color chartGradientTop = Color(0x4D00D4FF);
  static const Color chartGradientBottom = Color(0x0000D4FF);
  static const Color chartGrid = Color(0xFF1A1F35);
  static const Color chartDot = Color(0xFFFF3B4A);

  // ── Misc ──────────────────────────────────────────────────────────
  static const Color divider = Color(0xFF1E2340);
  static const Color shimmerBase = Color(0xFF141929);
  static const Color shimmerHighlight = Color(0xFF1E2540);

  /// Returns the color corresponding to a severity string.
  static Color severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return severityCritical;
      case 'warning':
        return severityWarning;
      case 'safe':
      case 'normal':
        return severitySafe;
      default:
        return textSecondary;
    }
  }
}
