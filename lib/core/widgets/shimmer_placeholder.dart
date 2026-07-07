import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

/// Standard shimmer skeleton block, used everywhere we're waiting on a
/// Firestore snapshot (appointment lists, statistics cards).
class ShimmerBlock extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius borderRadius;

  const ShimmerBlock({
    super.key,
    this.height = 16,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: const Color(0xFF2A2830),
      period: const Duration(milliseconds: 1400),
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

/// Shimmer skeleton shaped like an [AppointmentCard], shown while the
/// day's Firestore stream is loading its first snapshot.
class AppointmentCardShimmer extends StatelessWidget {
  const AppointmentCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceGlassBorder),
      ),
      child: Row(
        children: [
          const ShimmerBlock(height: 40, width: 44, borderRadius: BorderRadius.all(Radius.circular(11))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBlock(height: 13, width: 120),
                SizedBox(height: 6),
                ShimmerBlock(height: 11, width: 80),
              ],
            ),
          ),
          const ShimmerBlock(height: 16, width: 40),
        ],
      ),
    );
  }
}
