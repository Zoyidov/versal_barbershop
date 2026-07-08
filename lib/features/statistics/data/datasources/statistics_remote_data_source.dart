import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/client_visit.dart';
import '../../domain/entities/monthly_stat.dart';
import '../models/client_stat_model.dart';

abstract class StatisticsRemoteDataSource {
  Stream<List<ClientStatModel>> watchClientStats();
  Future<List<MonthlyStat>> getClientMonthlyBreakdown(String phoneNumber);
  Future<List<ClientVisit>> getClientVisits(String phoneNumber);
  Future<List<ClientStatModel>> searchClients(String query);
}

class StatisticsRemoteDataSourceImpl implements StatisticsRemoteDataSource {
  final FirebaseFirestore _firestore;

  StatisticsRemoteDataSourceImpl({required FirebaseFirestore firestore}) : _firestore = firestore;

  @override
  Stream<List<ClientStatModel>> watchClientStats() {
    return _firestore
        .collection(FirestorePaths.clients)
        .orderBy(ClientFields.totalVisits, descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(ClientStatModel.fromSnapshot).toList())
        .handleError((error) {
      throw AppException('Mijozlar statistikasini yuklab bo\'lmadi: $error');
    });
  }

  @override
  Future<List<MonthlyStat>> getClientMonthlyBreakdown(String phoneNumber) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.appointments)
          .where(AppointmentFields.clientPhone, isEqualTo: phoneNumber)
          .orderBy(AppointmentFields.appointmentTime, descending: true)
          .get();

      final buckets = <String, _MonthBucket>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = data[AppointmentFields.appointmentTime] as Timestamp?;
        if (timestamp == null) continue;
        final monthKey = DateFormatter.monthKey(timestamp.toDate());
        final status = data[AppointmentFields.status] as String? ?? 'scheduled';

        final bucket = buckets.putIfAbsent(monthKey, () => _MonthBucket());
        if (status == 'cancelled') {
          bucket.cancellations++;
        } else {
          bucket.visits++;
        }
      }

      final result = buckets.entries
          .map((e) => MonthlyStat(monthKey: e.key, visits: e.value.visits, cancellations: e.value.cancellations))
          .toList()
        ..sort((a, b) => b.monthKey.compareTo(a.monthKey));

      return result;
    } catch (e) {
      throw AppException('Mijoz tarixini yuklab bo\'lmadi: $e');
    }
  }

  @override
  Future<List<ClientVisit>> getClientVisits(String phoneNumber) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.appointments)
          .where(AppointmentFields.clientPhone, isEqualTo: phoneNumber)
          .orderBy(AppointmentFields.appointmentTime, descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final timestamp = data[AppointmentFields.appointmentTime] as Timestamp;
        return ClientVisit(
          appointmentTime: timestamp.toDate(),
          status: data[AppointmentFields.status] as String? ?? 'scheduled',
          serviceType: data[AppointmentFields.serviceType] as String?,
          smsSentAt: (data[AppointmentFields.smsSentAt] as Timestamp?)?.toDate(),
          smsStatus: data[AppointmentFields.smsStatus] as String?,
        );
      }).toList();
    } catch (e) {
      throw AppException('Mijoz tashriflar tarixini yuklab bo\'lmadi: $e');
    }
  }

  @override
  Future<List<ClientStatModel>> searchClients(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    try {
      // Firestore can only do prefix range queries, not "contains", and the
      // barber wants a match on *any* part of the phone number or name -
      // e.g. typing the middle digits of a number should still find it. At
      // this app's scale (one shop's client list) it's simpler and more
      // correct to pull the client list once and filter in Dart than to
      // fake substring search with several prefix queries.
      final snapshot = await _firestore
          .collection(FirestorePaths.clients)
          .orderBy(ClientFields.totalVisits, descending: true)
          .limit(1000)
          .get();

      final queryDigits = trimmed.replaceAll(RegExp(r'\D'), '');
      final queryLower = trimmed.toLowerCase();

      final matches = snapshot.docs.where((doc) {
        final data = doc.data();
        final phoneDigits = (data[ClientFields.phoneNumber] as String? ?? '').replaceAll(RegExp(r'\D'), '');
        final name = (data[ClientFields.lastName] as String? ?? '').toLowerCase();

        final phoneMatches = queryDigits.isNotEmpty && phoneDigits.contains(queryDigits);
        final nameMatches = queryLower.isNotEmpty && name.contains(queryLower);
        return phoneMatches || nameMatches;
      }).map(ClientStatModel.fromSnapshot);

      return matches.take(30).toList();
    } catch (e) {
      throw AppException('Qidiruvda xatolik: $e');
    }
  }
}

class _MonthBucket {
  int visits = 0;
  int cancellations = 0;
}
