import 'package:equatable/equatable.dart';

/// Global shop configuration, mirrored from `settings/global` in
/// Firestore. [reminderWindowMinutes] is read dynamically by the Cloud
/// Functions backend every time it schedules an SMS reminder, so changing
/// it here takes effect for every appointment created afterwards (and, per
/// the backend's settings trigger, is also applied retroactively to any
/// already-scheduled future reminders).
class AppSettings extends Equatable {
  final int reminderWindowMinutes;
  final String shopName;
  final int scheduleStartHour;
  final int scheduleEndHour;

  const AppSettings({
    required this.reminderWindowMinutes,
    required this.shopName,
    this.scheduleStartHour = 6,
    this.scheduleEndHour = 20,
  });

  static const AppSettings fallback = AppSettings(reminderWindowMinutes: 40, shopName: 'Versal Barbershop');

  AppSettings copyWith({
    int? reminderWindowMinutes,
    String? shopName,
    int? scheduleStartHour,
    int? scheduleEndHour,
  }) {
    return AppSettings(
      reminderWindowMinutes: reminderWindowMinutes ?? this.reminderWindowMinutes,
      shopName: shopName ?? this.shopName,
      scheduleStartHour: scheduleStartHour ?? this.scheduleStartHour,
      scheduleEndHour: scheduleEndHour ?? this.scheduleEndHour,
    );
  }

  @override
  List<Object?> get props => [reminderWindowMinutes, shopName, scheduleStartHour, scheduleEndHour];
}
