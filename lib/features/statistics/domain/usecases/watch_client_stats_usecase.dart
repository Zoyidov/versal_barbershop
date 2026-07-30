import '../entities/client_stat.dart';
import '../repositories/statistics_repository.dart';

class WatchClientStatsUseCase {
  final StatisticsRepository _repository;

  WatchClientStatsUseCase(this._repository);

  Stream<List<ClientStat>> call({String? barberId}) => _repository.watchClientStats(barberId: barberId);
}
