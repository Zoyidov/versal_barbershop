import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/date_formatter.dart';

/// Horizontal scrolling day strip. Defaults to today being selected and
/// centered, and scrolls both backward (to review past days' appointments)
/// and forward from there.
class WeekCalendarStrip extends StatefulWidget {
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  /// Appointment count per day (midnight-keyed, local time), used to render
  /// a small badge on each tile. Days missing from the map (or mapped to 0)
  /// show no badge.
  final Map<DateTime, int> appointmentCounts;

  const WeekCalendarStrip({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
    this.appointmentCounts = const {},
  });

  @override
  State<WeekCalendarStrip> createState() => _WeekCalendarStripState();
}

class _WeekCalendarStripState extends State<WeekCalendarStrip> {
  static const int _pastRangeInDays = 365;
  static const int _futureRangeInDays = 120;
  static const int _rangeInDays = _pastRangeInDays + _futureRangeInDays;
  late final ScrollController _controller;
  late final DateTime _anchor;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    // Anchor is today itself; item index `_pastRangeInDays` is today, so
    // indices below it walk backward into the past and indices above it
    // walk forward, per `_dayForIndex`.
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

  DateTime _dayForIndex(int index) => _anchor.add(Duration(days: index - _pastRangeInDays));

  void _scrollToSelected({required bool animate}) {
    if (!_controller.hasClients) return;
    const itemExtent = 68.0;
    final index =
        (widget.selectedDay.difference(_anchor).inDays + _pastRangeInDays).clamp(0, _rangeInDays - 1);
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
        // Badges are deliberately positioned a few pixels outside each
        // tile's own bounds (see the Positioned badge below) - without
        // this, the viewport's default hard clip would cut them off.
        clipBehavior: Clip.none,
        itemCount: _rangeInDays,
        itemBuilder: (context, index) {
          final day = _dayForIndex(index);
          final isSelected = DateFormatter.isSameDay(day, widget.selectedDay);
          final isToday = DateFormatter.isSameDay(day, DateTime.now());
          final count = widget.appointmentCounts[day] ?? 0;

          return GestureDetector(
            onTap: () => widget.onDaySelected(day),
            child: Container(
              width: 56,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              clipBehavior: Clip.none,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: isSelected
                    ? const LinearGradient(colors: AppColors.goldGradient)
                    : null,
                color: isSelected ? null : AppColors.surfaceGlass,
                border: Border.all(
                  // Today always gets a gold border, on top of the
                  // selected-tile gold fill, so it's never confused for
                  // just another day even while selected.
                  color: isToday ? AppColors.gold : (isSelected ? Colors.transparent : AppColors.surfaceGlassBorder),
                  width: isToday ? 1.5 : 1,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
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
                  if (count > 0)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: AppColors.background, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            count > 99 ? '99+' : '$count',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                        ),
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
