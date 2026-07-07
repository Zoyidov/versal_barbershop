import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/monthly_stat.dart';

class MonthlyBarRow extends StatelessWidget {
  final MonthlyStat stat;
  final int maxValue;

  const MonthlyBarRow({super.key, required this.stat, required this.maxValue});

  String get _label {
    final parts = stat.monthKey.split('-');
    final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    return DateFormat('MMMM yyyy', 'uz').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final total = maxValue == 0 ? 1 : maxValue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_label, style: AppTextStyles.title.copyWith(fontSize: 14)),
            const SizedBox(height: 10),
            _bar('Tashriflar', stat.visits, total, AppColors.success),
            const SizedBox(height: 8),
            _bar('Bekor qilingan', stat.cancellations, total, AppColors.danger),
          ],
        ),
      ),
    );
  }

  Widget _bar(String label, int value, int total, Color color) {
    final ratio = (value / total).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(width: 66, child: Text(label, style: AppTextStyles.caption)),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: AppColors.surface,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 20,
          child: Text('$value', style: AppTextStyles.body.copyWith(fontSize: 12)),
        ),
      ],
    );
  }
}
