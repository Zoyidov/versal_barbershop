import 'package:equatable/equatable.dart';

/// One hourly slot on the public booking screen's selected day.
class TimeSlot extends Equatable {
  final int hour;
  final bool isFree;
  final bool isPast;

  const TimeSlot({required this.hour, required this.isFree, required this.isPast});

  bool get isBookable => isFree && !isPast;

  @override
  List<Object?> get props => [hour, isFree, isPast];
}

/// A day's full set of hourly slots, as returned by the `getPublicDaySlots`
/// callable (computed server-side so no client ever needs read access to
/// the `appointments` collection to see availability).
class DaySlots extends Equatable {
  final int startHour;
  final int endHour;
  final List<TimeSlot> slots;

  const DaySlots({required this.startHour, required this.endHour, required this.slots});

  static const empty = DaySlots(startHour: 0, endHour: 0, slots: []);

  @override
  List<Object?> get props => [startHour, endHour, slots];
}
