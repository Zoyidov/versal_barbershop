import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/client_visit.dart';
import '../../domain/entities/monthly_stat.dart';
import '../models/client_stat_model.dart';

abstract class StatisticsRemoteDataSource {
  /// [barberId] null means "every barber" - only meaningful for an admin
  /// caller (firestore.rules restrict a non-admin's `appointments` read to
  /// their own `barberId`), so every barber-scoped caller must pass their
  /// own uid to keep each barber's client list separate from every other's.
  Stream<List<ClientStatModel>> watchClientStats({String? barberId});
  Future<List<MonthlyStat>> getClientMonthlyBreakdown(String phoneNumber, {String? barberId});
  Future<List<ClientVisit>> getClientVisits(String phoneNumber, {String? barberId});
  Future<List<ClientStatModel>> searchClients(String query, {String? barberId});
}

/// Derives all client statistics directly from `appointments` (each barber's
/// own bookings), instead of the shop-wide `clients/{phone}` aggregate that
/// backs the smart-alert lookup - that collection is intentionally shared
/// across every barber (a cross-shop no-show warning), which is exactly the
/// mixing this feature must NOT do. Every query below filters by `barberId`
/// alone (no Firestore-level `orderBy`), so it stays a pure-equality query
/// that Firestore can serve without a new composite index; sorting happens
/// client-side instead.
class StatisticsRemoteDataSourceImpl implements StatisticsRemoteDataSource {
  final FirebaseFirestore _firestore;

  StatisticsRemoteDataSourceImpl({required FirebaseFirestore firestore}) : _firestore = firestore;

  Query<Map<String, dynamic>> _appointmentsFor(String? barberId) {
    Query<Map<String, dynamic>> query = _firestore.collection(FirestorePaths.appointments);
    if (barberId != null) {
      query = query.where(AppointmentFields.barberId, isEqualTo: barberId);
    }
    return query;
  }

  @override
  Stream<List<ClientStatModel>> watchClientStats({String? barberId}) {
    return _appointmentsFor(barberId).snapshots().map((snapshot) => _aggregateClients(snapshot.docs)).handleError(
      (error) {
        throw AppException('Mijozlar statistikasini yuklab bo\'lmadi: $error');
      },
    );
  }

  @override
  Future<List<MonthlyStat>> getClientMonthlyBreakdown(String phoneNumber, {String? barberId}) async {
    try {
      final snapshot = await _appointmentsFor(barberId)
          .where(AppointmentFields.clientPhone, isEqualTo: phoneNumber)
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
  Future<List<ClientVisit>> getClientVisits(String phoneNumber, {String? barberId}) async {
    try {
      final snapshot = await _appointmentsFor(barberId)
          .where(AppointmentFields.clientPhone, isEqualTo: phoneNumber)
          .get();

      final visits = snapshot.docs.map((doc) {
        final data = doc.data();
        final timestamp = data[AppointmentFields.appointmentTime] as Timestamp;
        return ClientVisit(
          appointmentTime: timestamp.toDate(),
          status: data[AppointmentFields.status] as String? ?? 'scheduled',
          serviceType: data[AppointmentFields.serviceType] as String?,
          smsSentAt: (data[AppointmentFields.smsSentAt] as Timestamp?)?.toDate(),
          smsStatus: data[AppointmentFields.smsStatus] as String?,
        );
      }).toList()
        ..sort((a, b) => b.appointmentTime.compareTo(a.appointmentTime));

      return visits;
    } catch (e) {
      throw AppException('Mijoz tashriflar tarixini yuklab bo\'lmadi: $e');
    }
  }

  @override
  Future<List<ClientStatModel>> searchClients(String query, {String? barberId}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    try {
      // Firestore can only do prefix range queries, not "contains", and the
      // barber wants a match on *any* part of the phone number or name -
      // e.g. typing the middle digits of a number should still find it. At
      // this app's scale (one barber's client list) it's simpler and more
      // correct to pull their appointment history once and filter in Dart
      // than to fake substring search with several prefix queries.
      final snapshot = await _appointmentsFor(barberId).get();
      final clients = _aggregateClients(snapshot.docs);

      final queryDigits = trimmed.replaceAll(RegExp(r'\D'), '');
      final queryLower = trimmed.toLowerCase();

      final matches = clients.where((client) {
        final phoneDigits = client.phoneNumber.replaceAll(RegExp(r'\D'), '');
        final name = (client.lastName ?? '').toLowerCase();

        final phoneMatches = queryDigits.isNotEmpty && phoneDigits.contains(queryDigits);
        final nameMatches = queryLower.isNotEmpty && name.contains(queryLower);
        return phoneMatches || nameMatches;
      });

      return matches.take(30).toList();
    } catch (e) {
      throw AppException('Qidiruvda xatolik: $e');
    }
  }

  /// Groups a barber's raw appointment docs into one aggregate per client
  /// phone number, mirroring the shape (and visit/cancellation counting
  /// rules) of the old shop-wide `clients/{phone}` doc, but scoped to
  /// whichever `barberId` filter produced [docs].
  List<ClientStatModel> _aggregateClients(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final aggregates = <String, _ClientAggregate>{};

    for (final doc in docs) {
      final data = doc.data();
      final phone = data[AppointmentFields.clientPhone] as String?;
      if (phone == null || phone.isEmpty) continue;

      final aggregate = aggregates.putIfAbsent(phone, () => _ClientAggregate(phoneNumber: phone));
      final status = data[AppointmentFields.status] as String? ?? 'scheduled';
      if (status == 'cancelled') {
        aggregate.totalCancellations++;
      } else {
        aggregate.totalVisits++;
      }

      final name = data[AppointmentFields.clientName] as String?;
      final timestamp = data[AppointmentFields.appointmentTime] as Timestamp?;
      if (name != null &&
          name.isNotEmpty &&
          (aggregate.lastNameAt == null ||
              (timestamp != null && timestamp.toDate().isAfter(aggregate.lastNameAt!)))) {
        aggregate.lastName = name;
        aggregate.lastNameAt = timestamp?.toDate();
      }
    }

    final result = aggregates.values
        .map((a) => ClientStatModel(
              phoneNumber: a.phoneNumber,
              lastName: a.lastName,
              totalVisits: a.totalVisits,
              totalCancellations: a.totalCancellations,
            ))
        .toList()
      ..sort((a, b) => b.totalVisits.compareTo(a.totalVisits));

    return result;
  }
}

class _MonthBucket {
  int visits = 0;
  int cancellations = 0;
}

class _ClientAggregate {
  final String phoneNumber;
  String? lastName;
  DateTime? lastNameAt;
  int totalVisits = 0;
  int totalCancellations = 0;

  _ClientAggregate({required this.phoneNumber});
}
