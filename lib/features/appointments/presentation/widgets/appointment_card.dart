import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/appointment.dart';

/// A single appointment row on the dashboard.
///
/// Compact, iOS-style list-cell footprint (small time chip, tight
/// padding, single-line subtitle) rather than a large card. Cancelled
/// appointments are never removed from the list — they render with a
/// distinctly dimmed red/grey glass tint (per spec) so the barber can see
/// cancellation history for the day at a glance.
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
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        tint: isCancelled ? AppColors.cancelledGlassTint : AppColors.scheduledGlassTint,
        borderColor: isCancelled ? AppColors.cancelledBorder : AppColors.scheduledBorder,
        child: Row(
          children: [
            _TimeChip(appointment: appointment, isCancelled: isCancelled),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          appointment.clientName?.trim().isNotEmpty == true
                              ? appointment.clientName!
                              : appointment.clientPhone,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.title.copyWith(
                            fontSize: 14.5,
                            decoration: isCancelled ? TextDecoration.lineThrough : null,
                            color: isCancelled ? AppColors.textSecondary : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isCancelled) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'BEKOR',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w700,
                              fontSize: 9.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          appointment.clientPhone,
                          style: AppTextStyles.caption.copyWith(fontSize: 11.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (appointment.serviceType != null) ...[
                        Text(' · ', style: AppTextStyles.caption.copyWith(fontSize: 11.5)),
                        Flexible(
                          child: Text(
                            appointment.serviceType!,
                            style: AppTextStyles.caption.copyWith(fontSize: 11.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            if (!isCancelled)
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onQuickCancel,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
                ),
              )
            else
              Icon(
                appointment.sendSms ? Icons.sms_outlined : Icons.sms_failed_outlined,
                color: AppColors.textMuted,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final Appointment appointment;
  final bool isCancelled;

  const _TimeChip({required this.appointment, required this.isCancelled});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        color: isCancelled ? AppColors.danger.withValues(alpha: 0.12) : AppColors.gold.withValues(alpha: 0.14),
      ),
      child: Text(
        DateFormatter.time(appointment.appointmentTime),
        style: AppTextStyles.title.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isCancelled ? AppColors.textMuted : AppColors.gold,
        ),
      ),
    );
  }
}
