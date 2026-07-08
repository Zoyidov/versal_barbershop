import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/date_formatter.dart';

/// Horizontal scrolling day strip. Defaults to today being selected, and
/// the strip only ever scrolls forward from today - past days are never
/// shown, since appointments can't be booked or reviewed before today.
class WeekCalendarStrip extends StatefulWidget {
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  const WeekCalendarStrip({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  State<WeekCalendarStrip> createState() => _WeekCalendarStripState();
}

class _WeekCalendarStripState extends State<WeekCalendarStrip> {
  static const int _rangeInDays = 120;
  late final ScrollController _controller;
  late final DateTime _anchor;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    // Anchor is today itself - the minimum selectable/visible day. The
    // strip only extends forward from here, never into the past.
    _anchor = DateTime(today.year, today.month, today.day);
    _controller = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected(animate: false));
  }

  @override
  void didUpdateWidget(covariant WeekCalendarStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!DateFormatter.isSameDay(oldWidget.selectedDay, widget.selectedDay)) {
      _scrollToSelected(animate: true);
    }
  }

  void _scrollToSelected({required bool animate}) {
    if (!_controller.hasClients) return;
    const itemExtent = 68.0;
    final index = widget.selectedDay.difference(_anchor).inDays.clamp(0, _rangeInDays - 1);
    final target = (index * itemExtent) - (MediaQuery.of(context).size.width / 2) + (itemExtent / 2);
    final clamped = target.clamp(0.0, _controller.position.maxScrollExtent);
    if (animate) {
      _controller.animateTo(clamped, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    } else {
      _controller.jumpTo(clamped);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: ListView.builder(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _rangeInDays,
        itemBuilder: (context, index) {
          final day = _anchor.add(Duration(days: index));
          final isSelected = DateFormatter.isSameDay(day, widget.selectedDay);
          final isToday = DateFormatter.isSameDay(day, DateTime.now());

          return GestureDetector(
            onTap: () => widget.onDaySelected(day),
            child: Container(
              width: 56,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: isSelected
                    ? const LinearGradient(colors: AppColors.goldGradient)
                    : null,
                color: isSelected ? null : AppColors.surfaceGlass,
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (isToday ? AppColors.gold.withValues(alpha: 0.5) : AppColors.surfaceGlassBorder),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormatter.weekdayShort(day).toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.background : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormatter.dayNumber(day),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.background : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
