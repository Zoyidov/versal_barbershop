import '../entities/client_stat.dart';
import '../entities/client_visit.dart';
import '../entities/monthly_stat.dart';

abstract class StatisticsRepository {
  /// Real-time stream of one barber's clients (their own booking history
  /// only), ordered by total visits descending (busiest clients first).
  /// [barberId] null means "every barber" - only meaningful for an admin.
  Stream<List<ClientStat>> watchClientStats({String? barberId});

  /// Computes the month-by-month visit/cancellation breakdown for one
  /// phone number by querying that client's appointment history (scoped to
  /// [barberId], same rule as above) and bucketing client-side.
  Future<List<MonthlyStat>> getClientMonthlyBreakdown(String phoneNumber, {String? barberId});

  /// The same client's appointment history as individual dated entries
  /// (newest first), for the client detail screen's visit-history list.
  Future<List<ClientVisit>> getClientVisits(String phoneNumber, {String? barberId});

  /// One-shot lookup by phone-number prefix and/or name prefix, for the
  /// nav bar's client search.
  Future<List<ClientStat>> searchClients(String query, {String? barberId});
}
