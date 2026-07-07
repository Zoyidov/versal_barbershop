import '../repositories/appointment_repository.dart';

class CancelAppointmentUseCase {
  final AppointmentRepository _repository;

  CancelAppointmentUseCase(this._repository);

  Future<void> call(String appointmentId) => _repository.cancelAppointment(appointmentId);
}
