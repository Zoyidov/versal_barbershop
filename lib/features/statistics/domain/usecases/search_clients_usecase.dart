import '../entities/client_stat.dart';
import '../repositories/statistics_repository.dart';

class SearchClientsUseCase {
  final StatisticsRepository _repository;

  SearchClientsUseCase(this._repository);

  Future<List<ClientStat>> call(String query, {String? barberId}) =>
      _repository.searchClients(query, barberId: barberId);
}
