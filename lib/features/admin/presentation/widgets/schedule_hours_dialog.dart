import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../settings/widgets/app_hour_field.dart';

/// Admin-only: sets a specific barber's own working hours, separate from
/// every other barber's and from the shop-wide default in Settings.
class ScheduleHoursDialog extends StatefulWidget {
  final String title;
  final int? initialStartHour;
  final int? initialEndHour;

  const ScheduleHoursDialog({
    super.key,
    required this.title,
    this.initialStartHour,
    this.initialEndHour,
  });

  static Future<(int, int)?> show(
    BuildContext context, {
    required String title,
    int? initialStartHour,
    int? initialEndHour,
  }) {
    return showDialog<(int, int)>(
      context: context,
      builder: (_) => ScheduleHoursDialog(
        title: title,
        initialStartHour: initialStartHour,
        initialEndHour: initialEndHour,
      ),
    );
  }

  @override
  State<ScheduleHoursDialog> createState() => _ScheduleHoursDialogState();
}

class _ScheduleHoursDialogState extends State<ScheduleHoursDialog> {
  late int? _startHour = widget.initialStartHour;
  late int? _endHour = widget.initialEndHour;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppHourField(
                    label: 'Boshlanish soati',
                    value: _startHour,
                    onChanged: (val) => setState(() {
                      _startHour = val;
                      _error = null;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppHourField(
                    label: 'Tugash soati',
                    value: _endHour,
                    onChanged: (val) => setState(() {
                      _endHour = val;
                      _error = null;
                    }),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Bekor qilish', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppPrimaryButton(
                    label: 'Saqlash',
                    onPressed: () {
                      final start = _startHour;
                      final end = _endHour;
                      if (start == null || end == null) {
                        setState(() => _error = 'Boshlanish va tugash soatini tanlang');
                        return;
                      }
                      if (start >= end) {
                        setState(() => _error = 'Boshlanish vaqti tugash vaqtidan oldin bo\'lishi kerak');
                        return;
                      }
                      Navigator.of(context).pop((start, end));
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
