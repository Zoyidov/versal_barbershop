import '../repositories/admin_repository.dart';

class UpdateBarberScheduleUseCase {
  final AdminRepository _repository;

  UpdateBarberScheduleUseCase(this._repository);

  Future<void> call({required String uid, required int startHour, required int endHour}) =>
      _repository.updateScheduleHours(uid: uid, startHour: startHour, endHour: endHour);
}
