import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Full-screen dark radial/linear gradient backdrop used behind every
/// screen so the glassmorphic panels have something rich to blur against.
class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.backgroundGradientStart,
            AppColors.backgroundGradientEnd,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: _glow(AppColors.gold.withValues(alpha: 0.10), 280),
          ),
          Positioned(
            bottom: -140,
            left: -100,
            child: _glow(AppColors.gold.withValues(alpha: 0.06), 320),
          ),
          child,
        ],
      ),
    );
  }

  Widget _glow(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
