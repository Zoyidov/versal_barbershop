import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/monthly_stat.dart';
import '../models/client_stat_model.dart';

abstract class StatisticsRemoteDataSource {
  Stream<List<ClientStatModel>> watchClientStats();
  Future<List<MonthlyStat>> getClientMonthlyBreakdown(String phoneNumber);
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
}

class _MonthBucket {
  int visits = 0;
  int cancellations = 0;
}
