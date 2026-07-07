import '../entities/appointment.dart';
import '../entities/client_history.dart';

abstract class AppointmentRepository {
  /// Real-time stream of every appointment (any status) scheduled on the
  /// given calendar day, ordered by time of day.
  Stream<List<Appointment>> watchAppointmentsForDay(DateTime day);

  Future<Appointment> createAppointment(Appointment appointment);

  Future<void> updateAppointment(Appointment appointment);

  /// Soft-cancel: sets status to `cancelled`. The document is never
  /// deleted so appointment/statistics history stays intact.
  Future<void> cancelAppointment(String appointmentId);

  /// One-shot lookup of a phone number's lifetime history, used by the
  /// smart-alert banner. Returns null if this phone has no prior history.
  Future<ClientHistory?> getClientHistory(String phoneNumber);
}
