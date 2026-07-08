import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/day_slots.dart';

/// Grid of hourly slots for the selected day. Free, bookable hours are
/// gold-tinted and tappable; past or already-taken hours are dimmed and
/// disabled, mirroring the barber-facing `ScheduleTimetable`'s one-active-
/// appointment-per-hour model without exposing any client's name/phone.
class PublicSlotGrid extends StatelessWidget {
  final DaySlots daySlots;
  final ValueChanged<int> onSlotTap;

  const PublicSlotGrid({super.key, required this.daySlots, required this.onSlotTap});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.7,
      ),
      itemCount: daySlots.slots.length,
      itemBuilder: (context, index) {
        final slot = daySlots.slots[index];
        return _SlotTile(slot: slot, onTap: slot.isBookable ? () => onSlotTap(slot.hour) : null);
      },
    );
  }
}

class _SlotTile extends StatelessWidget {
  final TimeSlot slot;
  final VoidCallback? onTap;

  const _SlotTile({required this.slot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bookable = onTap != null;
    final label = '${slot.hour.toString().padLeft(2, '0')}:00';
    final borderColor = bookable ? AppColors.scheduledBorder : AppColors.surfaceGlassBorder;
    final bgColor = bookable ? AppColors.scheduledGlassTint : AppColors.surfaceGlass.withValues(alpha: 0.3);
    final textColor = bookable ? AppColors.gold : AppColors.textMuted;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: AppTextStyles.title.copyWith(fontSize: 15, color: textColor)),
              if (!bookable) ...[
                const SizedBox(height: 2),
                Text(
                  slot.isPast ? 'o\'tgan' : 'band',
                  style: AppTextStyles.caption.copyWith(fontSize: 9.5),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
