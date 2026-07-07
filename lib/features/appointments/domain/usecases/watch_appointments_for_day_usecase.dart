import '../entities/appointment.dart';
import '../repositories/appointment_repository.dart';

class WatchAppointmentsForDayUseCase {
  final AppointmentRepository _repository;

  WatchAppointmentsForDayUseCase(this._repository);

  Stream<List<Appointment>> call(DateTime day) => _repository.watchAppointmentsForDay(day);
}
