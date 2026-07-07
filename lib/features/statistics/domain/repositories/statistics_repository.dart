import '../entities/client_stat.dart';
import '../entities/monthly_stat.dart';

abstract class StatisticsRepository {
  /// Real-time stream of every client's lifetime aggregate, ordered by
  /// total visits descending (busiest clients first).
  Stream<List<ClientStat>> watchClientStats();

  /// Computes the month-by-month visit/cancellation breakdown for one
  /// phone number by querying that client's appointment history and
  /// bucketing client-side (cheap: bounded by one client's volume).
  Future<List<MonthlyStat>> getClientMonthlyBreakdown(String phoneNumber);
}
