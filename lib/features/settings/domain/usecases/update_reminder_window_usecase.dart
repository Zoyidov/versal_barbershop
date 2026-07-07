import '../repositories/settings_repository.dart';

class UpdateReminderWindowUseCase {
  final SettingsRepository _repository;

  UpdateReminderWindowUseCase(this._repository);

  Future<void> call(int minutes) => _repository.updateReminderWindow(minutes);
}
