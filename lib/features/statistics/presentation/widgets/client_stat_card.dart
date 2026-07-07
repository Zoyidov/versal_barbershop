import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/client_stat.dart';

class ClientStatCard extends StatelessWidget {
  final ClientStat stat;
  final VoidCallback onTap;

  const ClientStatCard({super.key, required this.stat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        onTap: onTap,
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.gold.withValues(alpha: 0.14),
              child: Text(
                (stat.lastName?.trim().isNotEmpty == true ? stat.lastName!.trim()[0] : '#').toUpperCase(),
                style: AppTextStyles.title.copyWith(color: AppColors.gold),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat.lastName?.trim().isNotEmpty == true ? stat.lastName! : stat.phoneNumber,
                    style: AppTextStyles.title,
                  ),
                  const SizedBox(height: 3),
                  Text(stat.phoneNumber, style: AppTextStyles.caption),
                ],
              ),
            ),
            _CountPill(label: 'Tashrif', value: stat.totalVisits, color: AppColors.success),
            const SizedBox(width: 8),
            _CountPill(label: 'Bekor', value: stat.totalCancellations, color: AppColors.danger),
          ],
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _CountPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$value', style: AppTextStyles.title.copyWith(color: color, fontSize: 16)),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
