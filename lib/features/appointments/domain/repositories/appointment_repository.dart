import '../entities/appointment.dart';
import '../entities/client_history.dart';

abstract class AppointmentRepository {
  /// Real-time stream of every appointment (any status) scheduled on the
  /// given calendar day, ordered by time of day. [barberId] null means
  /// "every barber" - only an admin's read actually resolves that way,
  /// per firestore.rules.
  Stream<List<Appointment>> watchAppointmentsForDay(DateTime day, {String? barberId});

  /// Live per-day appointment counts (non-cancelled only) for every day in
  /// `[start, end]`, keyed by day (midnight, local time) - powers the
  /// calendar strip's badge. Same `barberId` semantics as
  /// [watchAppointmentsForDay].
  Stream<Map<DateTime, int>> watchAppointmentCountsForRange(DateTime start, DateTime end, {String? barberId});

  Future<Appointment> createAppointment(Appointment appointment);

  Future<void> updateAppointment(Appointment appointment);

  /// Soft-cancel: sets status to `cancelled`. The document is never
  /// deleted so appointment/statistics history stays intact.
  Future<void> cancelAppointment(String appointmentId);

  /// One-shot lookup of a phone number's lifetime history, used by the
  /// smart-alert banner. Returns null if this phone has no prior history.
  Future<ClientHistory?> getClientHistory(String phoneNumber);
}
