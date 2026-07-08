import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/client_visit.dart';

/// One row in a client's visit history: which day and what time they were
/// booked in, plus whether that booking was kept or cancelled.
class VisitHistoryRow extends StatelessWidget {
  final ClientVisit visit;

  const VisitHistoryRow({super.key, required this.visit});

  @override
  Widget build(BuildContext context) {
    final isCancelled = visit.isCancelled;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        tint: isCancelled ? AppColors.cancelledGlassTint : AppColors.scheduledGlassTint,
        borderColor: isCancelled ? AppColors.cancelledBorder : AppColors.scheduledBorder,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  isCancelled ? Icons.close_rounded : Icons.check_rounded,
                  color: isCancelled ? AppColors.danger : AppColors.success,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    DateFormatter.fullDate(visit.appointmentTime),
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 13,
                      decoration: isCancelled ? TextDecoration.lineThrough : null,
                      color: isCancelled ? AppColors.textSecondary : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (visit.serviceType?.trim().isNotEmpty == true) ...[
                  Flexible(
                    child: Text(
                      visit.serviceType!,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(fontSize: 11.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  DateFormatter.time(visit.appointmentTime),
                  style: AppTextStyles.title.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isCancelled ? AppColors.textMuted : AppColors.gold,
                  ),
                ),
              ],
            ),
            if (visit.smsSentAt != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Row(
                  children: [
                    Icon(Icons.mark_email_read_outlined, color: AppColors.textMuted, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'SMS ${DateFormatter.time(visit.smsSentAt!)} da yuborildi',
                      style: AppTextStyles.caption.copyWith(fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
