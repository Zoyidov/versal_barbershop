import '../entities/app_settings.dart';
import '../entities/sms_balance.dart';

abstract class SettingsRepository {
  Stream<AppSettings> watchSettings();
  Future<void> updateReminderWindow(int minutes);
  Future<void> updateScheduleHours(int startHour, int endHour);
  Future<SmsBalance> getSmsBalance();
}
