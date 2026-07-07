import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/client_history.dart';

/// Smart-alert banner: warns the barber when a phone number being entered
/// has a history of cancellations, per spec.
class CancellationWarningBanner extends StatelessWidget {
  final ClientHistory history;

  const CancellationWarningBanner({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final times = history.totalCancellations;
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.dangerDim.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ogohlantirish: bu mijoz oldin $times marta bekor qilgan',
                  style: AppTextStyles.body.copyWith(color: AppColors.danger, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Jami ${history.totalVisits} ta tashrif qayd etilgan',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
