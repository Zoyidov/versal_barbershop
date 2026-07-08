import '../entities/app_settings.dart';

abstract class SettingsRepository {
  Stream<AppSettings> watchSettings();
  Future<void> updateReminderWindow(int minutes);
  Future<void> updateScheduleHours(int startHour, int endHour);
}
