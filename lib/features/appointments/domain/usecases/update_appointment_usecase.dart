import '../entities/appointment.dart';
import '../repositories/appointment_repository.dart';

class UpdateAppointmentUseCase {
  final AppointmentRepository _repository;

  UpdateAppointmentUseCase(this._repository);

  Future<void> call(Appointment appointment) => _repository.updateAppointment(appointment);
}
