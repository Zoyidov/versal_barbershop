import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/appointment.dart';
import 'appointment_card.dart';

/// Hourly day timetable shown on the dashboard, below the week strip.
/// Renders one row per hour between [startHour] and [endHour] (bounds
/// configurable from Settings), with any appointments booked in that hour
/// listed inside the row and a ghost "add" tile so a new client can be
/// booked straight into that slot without leaving the screen. Each hour
/// only takes one client: once it holds an active (non-cancelled)
/// appointment the "add" tile is hidden, freeing up again only if that
/// appointment is cancelled. On today's date, any hour slot that has
/// already started is shown but disabled — the barber can't book a walk-in
/// into a time that's already passed.
class ScheduleTimetable extends StatelessWidget {
  final List<Appointment> appointments;
  final int startHour;
  final int endHour;
  final DateTime day;
  final ValueChanged<Appointment> onTapAppointment;
  final ValueChanged<Appointment> onQuickCancel;
  final ValueChanged<int> onAddForHour;

  const ScheduleTimetable({
    super.key,
    required this.appointments,
    required this.startHour,
    required this.endHour,
    required this.day,
    required this.onTapAppointment,
    required this.onQuickCancel,
    required this.onAddForHour,
  });

  @override
  Widget build(BuildContext context) {
    final safeEndHour = endHour > startHour ? endHour : startHour + 1;
    final hourCount = safeEndHour - startHour;
    final now = DateTime.now();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: hourCount,
      itemBuilder: (context, index) {
        final hour = startHour + index;
        final slotAppointments = appointments.where((a) => a.appointmentTime.hour == hour).toList()
          ..sort((a, b) => a.appointmentTime.compareTo(b.appointmentTime));
        final slotStart = DateTime(day.year, day.month, day.day, hour);
        final isPast = slotStart.isBefore(now);
        return _HourRow(
          hour: hour,
          appointments: slotAppointments,
          isPast: isPast,
          onTapAppointment: onTapAppointment,
          onQuickCancel: onQuickCancel,
          onAdd: () => onAddForHour(hour),
        );
      },
    );
  }
}

class _HourRow extends StatelessWidget {
  final int hour;
  final List<Appointment> appointments;
  final bool isPast;
  final ValueChanged<Appointment> onTapAppointment;
  final ValueChanged<Appointment> onQuickCancel;
  final VoidCallback onAdd;

  const _HourRow({
    required this.hour,
    required this.appointments,
    required this.isPast,
    required this.onTapAppointment,
    required this.onQuickCancel,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 48,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  '${hour.toString().padLeft(2, '0')}:00',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            VerticalDivider(color: AppColors.surfaceGlassBorder, width: 1, thickness: 1),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final appointment in appointments)
                    AppointmentCard(
                      appointment: appointment,
                      onTap: () => onTapAppointment(appointment),
                      onQuickCancel: () => onQuickCancel(appointment),
                    ),
                  if (!appointments.any((a) => !a.isCancelled)) _AddSlotTile(onTap: isPast ? null : onAdd),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddSlotTile extends StatelessWidget {
  final VoidCallback? onTap;

  const _AddSlotTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final color = disabled ? AppColors.textMuted.withValues(alpha: 0.4) : AppColors.textMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: disabled ?  AppColors.surfaceGlassBorder : AppColors.surfaceGlassBorder.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          child: Row(
            children: [
              Icon(Icons.add_circle_outline, color: color, size: 16),
              const SizedBox(width: 8),
              Text('Mijoz qo\'shish', style: AppTextStyles.caption.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
