import 'package:flutter/material.dart';

/// Dark / luxury barbershop palette.
///
/// Everything reads as near-black charcoal with a warm gold accent,
/// which is what carries the "liquid glass" panels — the glass only
/// looks premium when the base background is dark enough to show
/// the blur and gradient sheen clearly.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0A0A0C);
  static const Color backgroundGradientStart = Color(0xFF141116);
  static const Color backgroundGradientEnd = Color(0xFF07070A);

  static const Color surface = Color(0xFF1B1A1F);
  static const Color surfaceGlass = Color(0x1AFFFFFF);
  static const Color surfaceGlassBorder = Color(0x33FFFFFF);

  static const Color gold = Color(0xFFD4AF6A);
  static const Color goldBright = Color(0xFFF1CD8A);
  static const Color goldDim = Color(0xFF8A6E3F);

  static const Color textPrimary = Color(0xFFF5F2ED);
  static const Color textSecondary = Color(0xFFAFA9A0);
  static const Color textMuted = Color(0xFF6E6A64);

  static const Color success = Color(0xFF5FCE8E);
  static const Color danger = Color(0xFFE6685F);
  static const Color dangerDim = Color(0xFF5A3B39);
  static const Color warning = Color(0xFFE6B85F);

  /// Distinct dimmed glass tint for a cancelled appointment card.
  static const Color cancelledGlassTint = Color(0x33E6685F);
  static const Color cancelledBorder = Color(0x66E6685F);

  static const Color scheduledGlassTint = Color(0x14D4AF6A);
  static const Color scheduledBorder = Color(0x40D4AF6A);

  static const List<Color> goldGradient = [goldBright, gold, goldDim];
}
