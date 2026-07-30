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
  Stream<List<ClientStat>> watchClientStats({String? barberId}) =>
      _remoteDataSource.watchClientStats(barberId: barberId);

  @override
  Future<List<MonthlyStat>> getClientMonthlyBreakdown(String phoneNumber, {String? barberId}) {
    return _remoteDataSource.getClientMonthlyBreakdown(phoneNumber, barberId: barberId);
  }

  @override
  Future<List<ClientVisit>> getClientVisits(String phoneNumber, {String? barberId}) {
    return _remoteDataSource.getClientVisits(phoneNumber, barberId: barberId);
  }

  @override
  Future<List<ClientStat>> searchClients(String query, {String? barberId}) =>
      _remoteDataSource.searchClients(query, barberId: barberId);
}
