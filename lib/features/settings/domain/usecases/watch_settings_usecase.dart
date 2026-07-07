import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

class WatchSettingsUseCase {
  final SettingsRepository _repository;

  WatchSettingsUseCase(this._repository);

  Stream<AppSettings> call() => _repository.watchSettings();
}
