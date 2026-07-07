import '../entities/app_settings.dart';

abstract class SettingsRepository {
  Stream<AppSettings> watchSettings();
  Future<void> updateReminderWindow(int minutes);
}
