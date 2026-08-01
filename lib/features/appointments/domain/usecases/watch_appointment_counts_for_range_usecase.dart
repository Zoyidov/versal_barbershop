import '../repositories/appointment_repository.dart';

class WatchAppointmentCountsForRangeUseCase {
  final AppointmentRepository _repository;

  WatchAppointmentCountsForRangeUseCase(this._repository);

  Stream<Map<DateTime, int>> call(DateTime start, DateTime end, {String? barberId}) =>
      _repository.watchAppointmentCountsForRange(start, end, barberId: barberId);
}
