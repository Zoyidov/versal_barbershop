import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../models/appointment_model.dart';
import '../models/client_history_model.dart';

abstract class AppointmentRemoteDataSource {
  /// [barberId] null means "every barber" (only actually returns results
  /// for an admin caller - firestore.rules restrict a non-admin's read to
  /// their own `barberId`).
  Stream<List<AppointmentModel>> watchAppointmentsForDay(DateTime day, {String? barberId});
  Future<AppointmentModel> createAppointment(AppointmentModel appointment);
  Future<void> updateAppointment(AppointmentModel appointment);
  Future<void> cancelAppointment(String appointmentId);
  Future<ClientHistoryModel?> getClientHistory(String phoneNumber);
}

class AppointmentRemoteDataSourceImpl implements AppointmentRemoteDataSource {
  final FirebaseFirestore _firestore;

  AppointmentRemoteDataSourceImpl({required FirebaseFirestore firestore}) : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _appointments =>
      _firestore.collection(FirestorePaths.appointments);

  CollectionReference<Map<String, dynamic>> get _clients =>
      _firestore.collection(FirestorePaths.clients);

  @override
  Stream<List<AppointmentModel>> watchAppointmentsForDay(DateTime day, {String? barberId}) {
    final start = DateFormatter.startOfDay(day);
    final end = DateFormatter.endOfDay(day);

    Query<Map<String, dynamic>> query = _appointments.where(
      AppointmentFields.appointmentTime,
      isGreaterThanOrEqualTo: Timestamp.fromDate(start),
      isLessThanOrEqualTo: Timestamp.fromDate(end),
    );
    if (barberId != null) {
      query = query.where(AppointmentFields.barberId, isEqualTo: barberId);
    }

    return query
        .orderBy(AppointmentFields.appointmentTime)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(AppointmentModel.fromSnapshot).toList())
        .handleError((error) {
      throw AppException('Uchrashuvlarni yuklab bo\'lmadi: $error');
    });
  }

  @override
  Future<AppointmentModel> createAppointment(AppointmentModel appointment) async {
    try {
      final docRef = await _appointments.add(appointment.toCreateJson());
      final snapshot = await docRef.get();
      return AppointmentModel.fromSnapshot(snapshot);
    } catch (e) {
      throw AppException('Uchrashuv yaratib bo\'lmadi: $e');
    }
  }

  @override
  Future<void> updateAppointment(AppointmentModel appointment) async {
    if (appointment.id == null) {
      throw const AppException('ID siz uchrashuvni yangilab bo\'lmaydi.');
    }
    try {
      await _appointments.doc(appointment.id).update(appointment.toUpdateJson());
    } catch (e) {
      throw AppException('Uchrashuvni yangilab bo\'lmadi: $e');
    }
  }

  @override
  Future<void> cancelAppointment(String appointmentId) async {
    try {
      // Soft-cancel only: the document (and its full history) is never
      // deleted. The Cloud Functions backend reacts to this status change
      // to cancel any pending SMS reminder task and update client stats.
      await _appointments.doc(appointmentId).update({
        AppointmentFields.status: 'cancelled',
        AppointmentFields.updatedAt: FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw AppException('Uchrashuvni bekor qilib bo\'lmadi: $e');
    }
  }

  @override
  Future<ClientHistoryModel?> getClientHistory(String phoneNumber) async {
    try {
      final doc = await _clients.doc(phoneNumber).get();
      if (!doc.exists) return null;
      return ClientHistoryModel.fromSnapshot(doc);
    } catch (e) {
      throw AppException('Mijoz tarixini yuklab bo\'lmadi: $e');
    }
  }
}
