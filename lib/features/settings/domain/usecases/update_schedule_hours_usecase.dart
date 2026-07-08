import '../repositories/settings_repository.dart';

class UpdateScheduleHoursUseCase {
  final SettingsRepository _repository;

  UpdateScheduleHoursUseCase(this._repository);

  Future<void> call(int startHour, int endHour) => _repository.updateScheduleHours(startHour, endHour);
}
