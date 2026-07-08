import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_remote_data_source.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsRemoteDataSource _remoteDataSource;

  SettingsRepositoryImpl({required SettingsRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Stream<AppSettings> watchSettings() => _remoteDataSource.watchSettings();

  @override
  Future<void> updateReminderWindow(int minutes) => _remoteDataSource.updateReminderWindow(minutes);

  @override
  Future<void> updateScheduleHours(int startHour, int endHour) =>
      _remoteDataSource.updateScheduleHours(startHour, endHour);
}
