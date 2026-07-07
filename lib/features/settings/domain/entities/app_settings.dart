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

  const AppSettings({
    required this.reminderWindowMinutes,
    required this.shopName,
  });

  static const AppSettings fallback = AppSettings(reminderWindowMinutes: 40, shopName: 'Versal Barbershop');

  AppSettings copyWith({int? reminderWindowMinutes, String? shopName}) {
    return AppSettings(
      reminderWindowMinutes: reminderWindowMinutes ?? this.reminderWindowMinutes,
      shopName: shopName ?? this.shopName,
    );
  }

  @override
  List<Object?> get props => [reminderWindowMinutes, shopName];
}
