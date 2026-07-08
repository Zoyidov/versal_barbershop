import '../entities/client_stat.dart';
import '../entities/client_visit.dart';
import '../entities/monthly_stat.dart';

abstract class StatisticsRepository {
  /// Real-time stream of every client's lifetime aggregate, ordered by
  /// total visits descending (busiest clients first).
  Stream<List<ClientStat>> watchClientStats();

  /// Computes the month-by-month visit/cancellation breakdown for one
  /// phone number by querying that client's appointment history and
  /// bucketing client-side (cheap: bounded by one client's volume).
  Future<List<MonthlyStat>> getClientMonthlyBreakdown(String phoneNumber);

  /// The same client's appointment history as individual dated entries
  /// (newest first), for the client detail screen's visit-history list.
  Future<List<ClientVisit>> getClientVisits(String phoneNumber);

  /// One-shot lookup by phone-number prefix and/or name prefix, for the
  /// nav bar's client search.
  Future<List<ClientStat>> searchClients(String query);
}
