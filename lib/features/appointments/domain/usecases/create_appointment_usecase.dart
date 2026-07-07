import '../entities/appointment.dart';
import '../repositories/appointment_repository.dart';

class CreateAppointmentUseCase {
  final AppointmentRepository _repository;

  CreateAppointmentUseCase(this._repository);

  Future<Appointment> call(Appointment appointment) => _repository.createAppointment(appointment);
}
