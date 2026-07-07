import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// The core "shisha UI" glassmorphic panel: a blurred, translucent surface
/// with a soft border and gradient tint. Every card, sheet, and dialog in
/// the app is built from this one primitive so the glass effect stays
/// visually consistent.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Color tint;
  final Color borderColor;
  final double blurSigma;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.tint = AppColors.surfaceGlass,
    this.borderColor = AppColors.surfaceGlassBorder,
    this.blurSigma = 18,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                tint,
                tint.withValues(alpha: tint.a * 0.5),
              ],
            ),
            border: Border.all(color: borderColor, width: 1.1),
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        splashColor: AppColors.gold.withValues(alpha: 0.08),
        highlightColor: AppColors.gold.withValues(alpha: 0.04),
        child: content,
      ),
    );
  }
}
