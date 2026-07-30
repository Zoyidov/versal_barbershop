import '../../domain/entities/appointment.dart';
import '../../domain/entities/client_history.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../datasources/appointment_remote_data_source.dart';
import '../models/appointment_model.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  final AppointmentRemoteDataSource _remoteDataSource;

  AppointmentRepositoryImpl({required AppointmentRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Stream<List<Appointment>> watchAppointmentsForDay(DateTime day, {String? barberId}) {
    return _remoteDataSource.watchAppointmentsForDay(day, barberId: barberId);
  }

  @override
  Future<Appointment> createAppointment(Appointment appointment) {
    return _remoteDataSource.createAppointment(AppointmentModel.fromEntity(appointment));
  }

  @override
  Future<void> updateAppointment(Appointment appointment) {
    return _remoteDataSource.updateAppointment(AppointmentModel.fromEntity(appointment));
  }

  @override
  Future<void> cancelAppointment(String appointmentId) {
    return _remoteDataSource.cancelAppointment(appointmentId);
  }

  @override
  Future<ClientHistory?> getClientHistory(String phoneNumber) {
    return _remoteDataSource.getClientHistory(phoneNumber);
  }
}
