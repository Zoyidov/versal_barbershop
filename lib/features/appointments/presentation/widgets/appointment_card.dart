import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/appointment.dart';

/// A single appointment row on the dashboard.
///
/// Cancelled appointments are never removed from the list — they render
/// with a distinctly dimmed red/grey glass tint (per spec) so the barber
/// can see cancellation history for the day at a glance.
class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onTap;
  final VoidCallback onQuickCancel;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.onTap,
    required this.onQuickCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isCancelled = appointment.isCancelled;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        onTap: onTap,
        tint: isCancelled ? AppColors.cancelledGlassTint : AppColors.scheduledGlassTint,
        borderColor: isCancelled ? AppColors.cancelledBorder : AppColors.scheduledBorder,
        child: Row(
          children: [
            _TimeBadge(appointment: appointment, isCancelled: isCancelled),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.clientName?.trim().isNotEmpty == true
                        ? appointment.clientName!
                        : appointment.clientPhone,
                    style: AppTextStyles.title.copyWith(
                      decoration: isCancelled ? TextDecoration.lineThrough : null,
                      color: isCancelled ? AppColors.textSecondary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(appointment.clientPhone, style: AppTextStyles.caption),
                      if (appointment.serviceType != null) ...[
                        const SizedBox(width: 10),
                        Icon(Icons.content_cut, size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            appointment.serviceType!,
                            style: AppTextStyles.caption,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (isCancelled) ...[
                    const SizedBox(height: 6),
                    Text(
                      'BEKOR QILINGAN',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isCancelled)
              IconButton(
                onPressed: onQuickCancel,
                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                tooltip: 'Uchrashuvni bekor qilish',
              )
            else
              Icon(
                appointment.sendSms ? Icons.sms_outlined : Icons.sms_failed_outlined,
                color: AppColors.textMuted,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

class _TimeBadge extends StatelessWidget {
  final Appointment appointment;
  final bool isCancelled;

  const _TimeBadge({required this.appointment, required this.isCancelled});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isCancelled ? AppColors.danger.withValues(alpha: 0.12) : AppColors.gold.withValues(alpha: 0.14),
      ),
      child: Text(
        DateFormatter.time(appointment.appointmentTime),
        style: AppTextStyles.title.copyWith(
          fontSize: 14,
          color: isCancelled ? AppColors.textMuted : AppColors.gold,
        ),
      ),
    );
  }
}
