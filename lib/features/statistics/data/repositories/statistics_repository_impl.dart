import '../../domain/entities/client_stat.dart';
import '../../domain/entities/client_visit.dart';
import '../../domain/entities/monthly_stat.dart';
import '../../domain/repositories/statistics_repository.dart';
import '../datasources/statistics_remote_data_source.dart';

class StatisticsRepositoryImpl implements StatisticsRepository {
  final StatisticsRemoteDataSource _remoteDataSource;

  StatisticsRepositoryImpl({required StatisticsRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Stream<List<ClientStat>> watchClientStats() => _remoteDataSource.watchClientStats();

  @override
  Future<List<MonthlyStat>> getClientMonthlyBreakdown(String phoneNumber) {
    return _remoteDataSource.getClientMonthlyBreakdown(phoneNumber);
  }

  @override
  Future<List<ClientVisit>> getClientVisits(String phoneNumber) {
    return _remoteDataSource.getClientVisits(phoneNumber);
  }

  @override
  Future<List<ClientStat>> searchClients(String query) => _remoteDataSource.searchClients(query);
}
