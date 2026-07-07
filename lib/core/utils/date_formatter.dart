import 'package:intl/intl.dart';

/// Date/time formatting helpers centralized so every screen renders
/// appointment times identically.
class DateFormatter {
  DateFormatter._();

  static final DateFormat _time = DateFormat('HH:mm', 'uz');
  static final DateFormat _dayLabel = DateFormat('EEE', 'uz');
  static final DateFormat _dayNumber = DateFormat('d', 'uz');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy', 'uz');
  static final DateFormat _fullDate = DateFormat('d MMMM, EEEE', 'uz');
  static final DateFormat _monthKey = DateFormat('yyyy-MM', 'uz');

  static String time(DateTime dateTime) => _time.format(dateTime);

  static String weekdayShort(DateTime dateTime) => _dayLabel.format(dateTime);

  static String dayNumber(DateTime dateTime) => _dayNumber.format(dateTime);

  static String monthYear(DateTime dateTime) => _monthYear.format(dateTime);

  static String fullDate(DateTime dateTime) => _fullDate.format(dateTime);

  /// Stable `yyyy-MM` key used to bucket appointments into months for the
  /// statistics breakdown.
  static String monthKey(DateTime dateTime) => _monthKey.format(dateTime);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime startOfDay(DateTime day) =>
      DateTime(day.year, day.month, day.day);

  static DateTime endOfDay(DateTime day) =>
      DateTime(day.year, day.month, day.day, 23, 59, 59, 999);
}
