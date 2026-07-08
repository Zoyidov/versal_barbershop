import '../entities/client_visit.dart';
import '../repositories/statistics_repository.dart';

class GetClientVisitsUseCase {
  final StatisticsRepository _repository;

  GetClientVisitsUseCase(this._repository);

  Future<List<ClientVisit>> call(String phoneNumber) => _repository.getClientVisits(phoneNumber);
}
